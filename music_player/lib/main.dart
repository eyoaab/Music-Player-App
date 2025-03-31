import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Configuration
import 'constants/deezer_config.dart';
import 'routes.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/player_provider.dart';
import 'providers/library_provider.dart';

// Services
import 'services/deezer_auth_service.dart';
import 'services/deezer_api_service.dart';
import 'services/download_service.dart';
import 'services/connectivity_service.dart';

// Screens
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/library/library_screen.dart';

// Widgets
import 'widgets/player/mini_player.dart';
import 'widgets/player/full_player.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (OPTIONAL)
  try {
    await dotenv.load();
    print('Environment variables loaded');
  } catch (e) {
    print(
        'Failed to load environment variables: $e - This is OK for most features');
  }

  // Initialize Deezer configuration
  DeezerConfig.initialize();

  // Verify credentials are available (this is NOT required for most features)
  if (DeezerConfig.appId.isEmpty) {
    print(
        'NOTE: Deezer app ID is not set. This is OK for most features as public API endpoints do not require authentication.');
    print(
        'Some user-specific features like viewing personal favorites will not be available.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define whether to use authentication or not
    final bool useAuthentication =
        DeezerConfig.appId.isNotEmpty && DeezerConfig.appSecret.isNotEmpty;

    // Create services
    final authService = useAuthentication ? DeezerAuthService() : null;
    final apiService = DeezerApiService(authService);
    final downloadService = DownloadService();
    final connectivityService = ConnectivityService();
    final libraryProvider = LibraryProvider(
      deezerApiService: apiService,
      downloadService: downloadService,
    );

    // Create player provider and connect it to library provider
    final playerProvider = PlayerProvider();
    playerProvider.setLibraryProvider(libraryProvider);

    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Auth service - only if using authentication
        if (authService != null)
          ChangeNotifierProvider<DeezerAuthService>.value(value: authService),

        // API service - works with or without auth
        Provider<DeezerApiService>.value(value: apiService),

        // Download service - independent
        Provider<DownloadService>.value(value: downloadService),

        // Connectivity service - for monitoring internet connection
        ChangeNotifierProvider<ConnectivityService>.value(
            value: connectivityService),

        // Library provider - depends on API and download services
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),

        // Player provider - connected to library provider
        ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DevicePreview(
            enabled: true, // Enable Device Preview for testing
            builder: (context) => MaterialApp(
              title: 'Eyobifay',
              theme: themeProvider.currentTheme,
              home: const ConnectivityWrapper(child: MainScreen()),
              debugShowCheckedModeBanner: false,
              onGenerateRoute: AppRoutes.generateRoute,
              initialRoute: '/',
              useInheritedMediaQuery:
                  true, // Ensure Device Preview works correctly
              locale: DevicePreview.locale(
                  context), // Use the locale from Device Preview
              builder:
                  DevicePreview.appBuilder, // Wrap the app with Device Preview
            ),
          );
        },
      ),
    );
  }
}

// Wrapper widget to monitor connectivity
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connectivity whenever dependencies change
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: true);
    Future.delayed(Duration.zero, () {
      connectivityService.showConnectivitySnackBar(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _screens[_currentIndex],

          // Mini player at the bottom
          if (playerProvider.currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: kBottomNavigationBarHeight,
              child: GestureDetector(
                onTap: () => playerProvider.showPlayer(),
                child: const MiniPlayer(),
              ),
            ),

          // Full screen player
          if (playerProvider.isPlayerVisible)
            FullPlayer(
              onClose: () => playerProvider.hidePlayer(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: 'Search',
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_music),
            label: 'Library',
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          ),
        ],
        selectedItemColor: primaryColor,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Library';
      default:
        return 'Eyobifay';
    }
  }
}
