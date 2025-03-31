import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/deezer_config.dart';

class DeezerAuthService with ChangeNotifier {
  static const String _tokenKey = 'deezer_token';
  static const String _expiryKey = 'deezer_token_expiry';

  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _isAuthenticating = false;

  DeezerAuthService() {
    _loadTokenFromStorage();
  }

  // Getters
  String? get accessToken => _accessToken;
  bool get isAuthenticated =>
      _accessToken != null &&
      _tokenExpiry != null &&
      _tokenExpiry!.isAfter(DateTime.now());
  bool get isAuthenticating => _isAuthenticating;

  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _accessToken = prefs.getString(_tokenKey);

      final expiryMillis = prefs.getInt(_expiryKey);
      if (expiryMillis != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      }

      debugPrint('Loaded Deezer token from storage: ${_accessToken != null}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Deezer token from storage: $e');
    }
  }

  Future<void> _saveTokenToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_accessToken != null) {
        await prefs.setString(_tokenKey, _accessToken!);
      }

      if (_tokenExpiry != null) {
        await prefs.setInt(_expiryKey, _tokenExpiry!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Error saving Deezer token to storage: $e');
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      // If this is our mock code for web demo
      if (code == 'mock_auth_code_for_web_demo') {
        debugPrint('Using mock token for web demo');

        // Create a mock token response
        _accessToken = 'mock_access_token_for_web_demo';
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

        _saveTokenToStorage();
        notifyListeners();
        return;
      }

      // Normal flow for real devices
      // Deezer requires a server for token exchange as it's not secure to do it client-side
      // In a real app, you would send the code to your backend and get back a token
      // For demo purposes, we're simulating this

      // This is a simulation - in a real app, don't store tokens in the app's code
      _accessToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

      _saveTokenToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error exchanging code for token: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _tokenExpiry = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_expiryKey);
    } catch (e) {
      debugPrint('Error clearing tokens from storage: $e');
    }

    notifyListeners();
  }
}
