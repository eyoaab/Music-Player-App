# Flutter Music Player - Quick Start Guide

## Getting Started

This guide will help you quickly set up and start using the Flutter Music Player app.

## Great News! No API Key Required!

One of the best features of this app is that **most functionality works without any API key or authentication**. The Deezer API allows public access to:

- Search for songs and artists
- Browse trending songs
- Get music details and previews
- Play 30-second audio samples

All without requiring you to register for API credentials!

### Prerequisites

- Flutter SDK installed on your machine
- Android Studio or VS Code with Flutter plugins
- Emulator or physical device for testing

### Installation Steps

1. **Clone the Repository**

```bash
git clone https://github.com/yourusername/music_player.git
cd music_player
```

2. **Install Dependencies**

```bash
flutter pub get
```

3. **Run the App**

```bash
flutter run
```

That's it! The app works with public Deezer API endpoints that don't require authentication.

### Optional: Set Up User-Specific Features

If you want to access user-specific features (like personal playlists and favorites):

1. **Get Deezer API Credentials**

   - Create an account at [Deezer Developers](https://developers.deezer.com/)
   - Register a new application
   - Note your app ID and secret

2. **Configure the App**
   - Create a `.env` file in the project root with:
   ```
   DEEZER_APP_ID=your_deezer_app_id
   DEEZER_APP_SECRET=your_deezer_app_secret
   ```

## App Navigation

### Home Screen

- The landing page shows trending songs
- Tap on a song to play it
- Use the more options (⋮) to view additional song actions

### Search Screen

- Search for songs and artists using the search bar
- Browse public playlists
- Tap on a song to play it

### Library Screen

- **Downloads**: Shows songs you've downloaded for offline listening
- **Favorites**: Displays songs you've marked as favorites (stored locally)
- **Playlists**: Manage your custom playlists (stored locally)

### Player Interface

- A mini player appears at the bottom when playing music
- Tap on the mini player to expand to the full-screen player
- Control playback with play/pause, previous, next, shuffle, and repeat options

## Quick Tips

1. **Downloading Songs for Offline Use**

   - Tap the more options (⋮) on any song
   - Select "Download"
   - Find downloaded songs in the Library > Downloads tab

2. **Creating Playlists**

   - Navigate to Library > Playlists tab
   - Tap the "+" button to create a new playlist
   - Add songs to a playlist from the song options menu

3. **Theme Toggling**

   - Tap the sun/moon icon in the app bar to toggle between light and dark modes

4. **Favorite Songs**
   - Tap the heart icon on any song to add it to your favorites
   - Access your favorites in the Library > Favorites tab

## Troubleshooting

- **No Music Playing**: Ensure your device has an active internet connection for streaming
- **Downloads Not Working**: Check that your app has proper storage permissions
- **Authentication Issues**: If using user-specific features, verify your Deezer credentials are correct

## Need Help?

If you encounter any issues or have questions, please:

- Check the README.md file for more detailed information
- Open an issue on the GitHub repository
- Contact the developer at your@email.com

Enjoy your music experience!
