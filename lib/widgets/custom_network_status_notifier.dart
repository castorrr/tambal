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
        _isReconnecting = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isReconnecting = false;
              _showConnectedMessage = true;
            });

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
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (!_isConnected || _isReconnecting || _showConnectedMessage)
            Positioned(
              top:
                  32, // Adjust this value to control how high the message appears
              left: MediaQuery.of(context).size.width * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isReconnecting
                      ? Colors.orange
                      : _isConnected
                          ? Colors.green
                          : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isReconnecting)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    if (_isReconnecting) const SizedBox(width: 8),
                    Text(
                      _isReconnecting
                          ? "Reconnecting..."
                          : _isConnected
                              ? "Connected"
                              : "No Connection",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
