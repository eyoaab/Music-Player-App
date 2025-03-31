import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
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

        // Library provider - depends on API and download services
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),

        // Player provider - connected to library provider
        ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
      ],
      child: DevicePreview(
        enabled: true, // Device preview enabled for testing
        builder: (context) => Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'Music Player',
              theme: themeProvider.currentTheme,
              home: const MainScreen(),
              debugShowCheckedModeBanner: false,
              locale: DevicePreview.locale(context),
              builder: DevicePreview.appBuilder,
              onGenerateRoute: AppRoutes.generateRoute,
              initialRoute: '/',
            );
          },
        ),
      ),
    );
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
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: 'Search',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_music),
            label: 'Library',
            backgroundColor: primaryColor,
          ),
        ],
        elevation: 8,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        backgroundColor: primaryColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
