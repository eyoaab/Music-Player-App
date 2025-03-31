# Flutter Music Player

A modern music player app built with Flutter that supports online streaming and offline playback using Deezer API.

## Features

- **Online/Offline Playback**

  - Stream music via Deezer API
  - Play offline files from local storage
  - Background playback with notifications

- **Download & Storage Management**

  - Download songs to local storage for offline listening
  - View storage usage and manage downloads

- **Search & Discovery**

  - Search for tracks and artists online
  - Browse music by genre
  - View trending songs and new releases

- **Deezer Integration**

  - Browse Deezer tracks and playlists
  - Play 30-second previews
  - **No API key required for most features!**
  - Optional authentication for personal favorites and playlists

- **Theme Support**

  - Toggle between light and dark mode
  - Smooth theme transitions
  - Yellow theme for light mode, amber for dark mode

- **Playlist & Favorites**
  - Create and manage custom playlists
  - Save favorite songs
  - Mix online and offline content in playlists

## Screenshots

(Add screenshots of the app here)

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or Visual Studio Code
- Android or iOS device/emulator
- Deezer account (optional - only for user-specific features)

### Installation

1. Clone this repository

```bash
git clone https://github.com/yourusername/music_player.git
```

2. Navigate to the project directory

```bash
cd music_player
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the app

```bash
flutter run
```

5. (Optional) Set up Deezer API credentials for user-specific features

   If you want to access user-specific features like personal favorites:

   - Create a Deezer Developer account at https://developers.deezer.com/
   - Register a new application
   - Configure redirect URIs (use `musicplayer://callback` for mobile)
   - Create a `.env` file based on `.env.example` and add your credentials:
     ```
     DEEZER_APP_ID=your_actual_app_id
     DEEZER_APP_SECRET=your_actual_app_secret
     ```
   - **Never commit your `.env` file to version control**

## Technical Implementation

- **State Management:** Provider
- **Audio Playback:** just_audio, audio_service
- **Theme Management:** ThemeData and Provider
- **API Integration:** dio for HTTP requests, Deezer API (no auth required for most features)
- **Authentication:** OAuth for Deezer (optional)
- **Storage:** path_provider, permission_handler
- **Data Persistence:** shared_preferences, sqflite

## Architecture

The app follows a clean architecture approach:

- **Models:** Data objects (Song, Album, Artist, Playlist)
- **Services:** Business logic and API communication
- **Providers:** State management
- **Screens:** UI components
- **Widgets:** Reusable UI elements

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Deezer API](https://developers.deezer.com/) for providing music access
- [Flutter](https://flutter.dev) and its amazing community

## Implementation Details

### Project Structure

```
lib/
  ├── constants/
  │   ├── app_theme.dart         # Theme constants for light and dark mode
  │   └── deezer_config.dart     # Deezer API configuration
  ├── models/
  │   ├── song.dart              # Song data model
  │   ├── album.dart             # Album data model
  │   ├── artist.dart            # Artist data model
  │   └── playlist.dart          # Playlist data model
  ├── providers/
  │   ├── theme_provider.dart    # Manages app theme state
  │   ├── player_provider.dart   # Manages audio playback state
  │   └── library_provider.dart  # Manages songs, playlists, and downloads
  ├── screens/
  │   ├── home_screen.dart       # Home screen with trending and recent songs
  │   ├── search_screen.dart     # Search and genre exploration
  │   └── library_screen.dart    # Downloads, favorites, and playlists
  ├── services/
  │   ├── deezer_api_service.dart    # Handles API requests to Deezer
  │   ├── deezer_auth_service.dart   # Manages Deezer authentication (optional)
  │   └── download_service.dart      # Manages song downloads
  ├── widgets/
  │   ├── song_list_item.dart    # Reusable song list item widget
  │   └── player/
  │       ├── mini_player.dart   # Compact player at bottom of screen
  │       └── full_player.dart   # Full-screen player with controls
  └── main.dart                  # App entry point with providers setup
```

### Key Features Implementation

1. **Theme Management**

   - Light and dark themes defined in `app_theme.dart`
   - `ThemeProvider` manages theme state and persistence
   - Smooth transitions between themes

2. **Music API Integration**

   - Deezer API integration via `DeezerApiService`
   - No API key required for public endpoints!
   - Search, trending songs, and artist-based browsing
   - Error handling and loading states

3. **Download Management**

   - Download songs for offline playback with `DownloadService`
   - Storage usage monitoring
   - Local file management

4. **Audio Playback**

   - Background audio with `just_audio` package
   - Queue management for playlists
   - Seeking, skipping, shuffle, and repeat modes

5. **State Management**

   - Provider pattern for app-wide state
   - Separate providers for theme, player, and library
   - Reactive UI updates

6. **User Library**

   - Playlist creation and management
   - Favorites system with persistence
   - Downloaded songs management

7. **UI Components**
   - Mini player always visible when music is playing
   - Full-screen player with waveform visualization
   - Artist and album exploration

### Usage Instructions

1. **Home Screen**: Displays trending songs and recently played tracks.

2. **Search Screen**: Search for songs by keyword or browse by artist.

3. **Library**: Manage your downloads, favorites, and playlists:

   - **Downloads**: View and manage downloaded songs
   - **Favorites**: Access your liked songs
   - **Playlists**: Create and manage custom playlists

4. **Player**:
   - Mini player appears at the bottom when a song is playing
   - Tap the mini player to open the full-screen player
   - Control playback with play/pause, skip, shuffle, and repeat buttons

### Authentication (Optional)

This app uses the Deezer API, which is unique in that **most features don't require authentication**. You can:

- Search for music
- Browse trending songs
- Access albums and artists
- Play 30-second previews

All without setting up any API keys!

If you want to access user-specific features (like personal favorites), you'll need to:

1. Create a Deezer Developer account
2. Register an application
3. Set up the credentials in `.env`

The app will automatically detect your credentials and enable the additional features.

### Testing Instructions

To thoroughly test the app:

1. **Online Functionality**:

   - Browse trending songs on the home screen
   - Search for songs by artist or title
   - Test playback of online songs

2. **Download Functionality**:

   - Download songs for offline use
   - Verify they appear in the Downloads tab
   - Test playback of downloaded songs with internet off

3. **Library Management**:

   - Create several playlists
   - Add songs to favorites
   - Add/remove songs from playlists
   - Test playlist deletion

4. **Player Functionality**:
   - Test mini and full player controls
   - Verify shuffle and repeat modes work correctly
   - Test seeking through songs with the progress bar

### Next Steps for Improvement

1. **User Authentication**: Enhanced login/signup functionality
2. **Cloud Sync**: Sync playlists and favorites across devices
3. **Equalizer**: Add audio equalization controls
4. **Improved Search**: Add voice search and search history
5. **Social Features**: Share songs and playlists with friends
6. **Analytics**: Track user listening habits and provide recommendations
