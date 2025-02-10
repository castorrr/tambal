import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class CustomNetworkStatusNotifier extends StatefulWidget {
  final Widget child;

  const CustomNetworkStatusNotifier({super.key, required this.child});

  @override
  State<CustomNetworkStatusNotifier> createState() =>
      _CustomNetworkStatusNotifierState();
}

class _CustomNetworkStatusNotifierState
    extends State<CustomNetworkStatusNotifier> {
  bool _isConnected = true;
  bool _isReconnecting = false;
  bool _showConnectedMessage = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      ConnectivityResult result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(
        results.isNotEmpty ? results.first : ConnectivityResult.none);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      bool wasDisconnected = !_isConnected;
      _isConnected = result != ConnectivityResult.none;

      if (wasDisconnected && _isConnected) {
        // Step 1: Show "Reconnecting..." first
        _isReconnecting = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isReconnecting = false;
              _showConnectedMessage = true;
            });

            // Step 2: Show "Connected" message briefly
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showConnectedMessage = false;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // ✅ Set default text direction
      child: Stack(
        children: [
          widget.child,

          // ✅ Show "No Connection" when offline
          if (!_isConnected && !_isReconnecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.red,
                child: const Center(
                  child: Text(
                    "No Connection",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // ✅ Show "Reconnecting..." when internet is coming back
          if (_isReconnecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.orange,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Reconnecting...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ✅ Show "Connected" briefly before hiding it
          if (_showConnectedMessage)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.green,
                child: const Center(
                  child: Text(
                    "Connected",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
