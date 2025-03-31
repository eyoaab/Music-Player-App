// /// Spotify configuration constants for the app
// class SpotifyConfig {
//   // Spotify Developer API credentials
//   // Replace these with your own credentials from Spotify Developer Dashboard
//   static String clientId = '693d181743ca4c26ab10ba9fd2733571';
//   static String clientSecret = '0e8ef1cab45242f18d11365a7d7b2a5a';

//   // Redirect URI for OAuth authentication
//   // Must match the URI registered in your Spotify Developer Dashboard
//   static const String redirectUri = 'musicplayer://callback';

//   // Authorization scopes required for the app
//   static const List<String> scopes = [
//     'user-read-private',
//     'user-read-email',
//     'user-library-read',
//     'user-top-read',
//     'playlist-read-private',
//     'playlist-read-collaborative',
//     'streaming',
//   ];

//   // API endpoints
//   static const String apiBaseUrl = 'https://api.spotify.com/v1';
//   static const String accountsBaseUrl = 'https://accounts.spotify.com/api';
//   static const String authUrl = 'https://accounts.spotify.com/authorize';
//   static const String tokenUrl = 'https://accounts.spotify.com/api/token';

//   // Spotify API market parameter (defaults to US)
//   // This affects which tracks are available based on region restrictions
//   static const String defaultMarket = 'US';

//   // Misc configuration
//   static const int defaultLimit = 20; // Default item limit for API requests
//   static const Duration tokenRefreshBuffer =
//       Duration(minutes: 5); // Refresh token if less than 5 mins left
// }
