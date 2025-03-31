import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Deezer configuration constants for the app
class DeezerConfig {
  // Deezer Authentication
  // Note: Authentication is OPTIONAL for public endpoints
  // Most features in this app work without authentication
  static String? _appId;
  static String? _appSecret;

  /// The Deezer App ID (only needed for user-specific features)
  static String get appId => _appId ?? '';

  /// The Deezer App Secret (only needed for user-specific features)
  static String get appSecret => _appSecret ?? '';

  // Redirect URI for OAuth authentication (only needed for user-specific features)
  static String get redirectUri =>
      kIsWeb ? 'http://localhost:8080/callback' : 'musicplayer://callback';

  // API endpoints
  static const String apiBaseUrl = 'https://api.deezer.com';
  static const String authUrl = 'https://connect.deezer.com/oauth/auth.php';
  static const String tokenUrl =
      'https://connect.deezer.com/oauth/access_token.php';

  // Permissions needed for the app (only needed for user-specific features)
  static const String permissions =
      'basic_access,email,offline_access,manage_library,listening_history';

  // Misc configuration
  static const int defaultLimit = 20; // Default item limit for API requests

  /// Initialize the Deezer configuration with credentials from env variables
  /// Note: These credentials are OPTIONAL for most functionality
  static void initialize() {
    try {
      _appId = dotenv.env['DEEZER_APP_ID'];
      _appSecret = dotenv.env['DEEZER_APP_SECRET'];

      if (_appId == null || _appSecret == null) {
        debugPrint(
            'NOTE: Deezer credentials not found in environment variables. '
            'This is OK for most features as public API endpoints do not require authentication.');
      } else {
        debugPrint(
            'Deezer credentials loaded successfully for user-specific features.');
      }
    } catch (e) {
      debugPrint('Error initializing Deezer config: $e');
    }
  }
}
