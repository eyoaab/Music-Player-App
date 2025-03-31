import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  bool _hasShownDisconnectedMessage = false;
  bool _hasShownReconnectedMessage = false;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    return _updateConnectionStatus(result);
  }

  // Update connection status
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    bool wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    // If connection state has changed, notify listeners
    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }

  // Show appropriate snackbar based on connectivity status
  void showConnectivitySnackBar(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (!_isConnected && !_hasShownDisconnectedMessage) {
      _hasShownDisconnectedMessage = true;
      _hasShownReconnectedMessage = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You are offline. Some features may be unavailable.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (_isConnected && !_hasShownReconnectedMessage) {
      _hasShownReconnectedMessage = true;
      _hasShownDisconnectedMessage = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You are back online.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
