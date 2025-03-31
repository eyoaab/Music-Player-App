# Music Player App

A Flutter music player app with online and offline playback capabilities.

## Project Structure

The project follows a clean, organized architecture with the following structure:

### Core Directories

- `lib/constants/` - Application constants and theme definitions
- `lib/models/` - Data models (Song, Playlist, Album, Artist)
- `lib/providers/` - State management using Provider pattern
- `lib/services/` - External services (API, downloads, authentication)
- `lib/screens/` - UI screens organized by feature
- `lib/widgets/` - Reusable UI components
- `lib/routes.dart` - Centralized routing definitions

### Screen Organization

The screens are organized by feature for better maintainability:

- `lib/screens/home/` - Home screen and related components
- `lib/screens/search/` - Search functionality
- `lib/screens/library/` - Library management (downloads, favorites, playlists)
- `lib/screens/playlist/` - Playlist creation, detail, and management
- `lib/screens/all_songs/` - Song list displays

Each feature folder includes an `index.dart` file that exports all related screens, making imports cleaner throughout the app.

## Features

- Online music playback from Deezer APIs
- Offline playback of downloaded music
- Music library management
- Playlist creation and management
- Search functionality
- Favorites system
- Light and dark themes

## Getting Started

1. Ensure you have Flutter installed
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch the app

## Optional Deezer API Configuration

The app can use the Deezer API for enhanced functionality. To set this up:

1. Copy `.env.example` to `.env`
2. Add your Deezer API credentials to the `.env` file
3. Restart the app

Note: Most features work without Deezer API credentials.

## Technical Details

- State management: Provider
- API client: Dio
- Storage: SharedPreferences and SQLite
- Audio playback: just_audio and audio_service
- HTTP requests: dio
- Storage permissions: permission_handler

## License

This project is licensed under the MIT License - see the LICENSE file for details.
