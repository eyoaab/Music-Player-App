import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import '../constants/deezer_config.dart';

class DeezerAuthService with ChangeNotifier {
  static const String _tokenKey = 'deezer_token';
  static const String _expiryKey = 'deezer_token_expiry';

  final Dio _dio = Dio();
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

  Future<String?> getAccessToken() async {
    if (!isAuthenticated) {
      await login();
    }
    return _accessToken;
  }

  Future<void> login() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    notifyListeners();

    try {
      // Build authorization URL
      final authUrl = Uri.parse(DeezerConfig.authUrl).replace(
        queryParameters: {
          'app_id': DeezerConfig.appId,
          'redirect_uri': DeezerConfig.redirectUri,
          'perms': DeezerConfig.permissions,
        },
      ).toString();

      // Open auth URL and wait for redirect with code
      final result = await _performAuthorizationRequest(authUrl);

      // Parse the code from the result
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        throw Exception('No authorization code received');
      }

      // Exchange code for token
      await _exchangeCodeForToken(code);

      debugPrint('Successfully authenticated with Deezer');
    } catch (e) {
      debugPrint('Error during Deezer authentication: $e');
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<String> _performAuthorizationRequest(String authUrl) async {
    if (kIsWeb) {
      // For web demo, simulate auth without actually opening a popup
      debugPrint('Web platform detected - using mock authentication for demo');

      // Simulate a delay as if the user was authenticating
      await Future.delayed(const Duration(seconds: 1));

      // Return a fake "code" that will simulate successful auth
      return 'musicplayer://callback?code=mock_auth_code_for_web_demo&state=demo';
    } else {
      // For mobile/desktop, use flutter_web_auth
      return await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: 'musicplayer',
      );
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
