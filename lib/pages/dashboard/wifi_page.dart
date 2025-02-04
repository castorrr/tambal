import 'package:flutter/material.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:logger/logger.dart';
import 'dart:async'; // Import for Timer

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({super.key});

  @override
  WifiConfigPageState createState() => WifiConfigPageState();
}

class WifiConfigPageState extends State<WifiConfigPage> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isConfiguring = false;
  String statusMessage = "Enter Wi-Fi credentials and configure ESP32";

  Provisioner? provisioner;
  final Logger logger = Logger();
  Timer? timeoutTimer; // Declare Timer here

  @override
  void dispose() {
    provisioner?.stop();
    timeoutTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void startSmartConfig() async {
    if (ssidController.text.isEmpty || passwordController.text.isEmpty) {
      updateStatus("SSID and Password cannot be empty.");
      return;
    }

    updateStatus("Configuring ESP32... Please wait", isConfiguring: true);

    try {
      provisioner = Provisioner.espTouch();

      // Handle provisioning response
      provisioner?.listen((response) {
        timeoutTimer?.cancel(); // Cancel the timer on success
        if (!mounted) return;

        updateStatus("ESP32 Connected!", isConfiguring: false);
        provisioner?.stop();
      });

      // Set timeout mechanism
      timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!mounted || !isConfiguring) return;
        updateStatus("SmartConfig timed out. Try again.", isConfiguring: false);
        provisioner?.stop();
      });

      await provisioner?.start(ProvisioningRequest.fromStrings(
        ssid: ssidController.text,
        password: passwordController.text,
      ));
    } catch (e) {
      logger.e("SmartConfig failed: $e");
      if (mounted) updateStatus("Error: ${e.toString()}", isConfiguring: false);
      provisioner?.stop();
    }
  }

  void updateStatus(String message, {bool isConfiguring = false}) {
    if (mounted) {
      setState(() {
        this.isConfiguring = isConfiguring;
        statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wi-Fi Setup"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi SSID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isConfiguring ? null : startSmartConfig,
              child: isConfiguring
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Wi-Fi Credentials"),
            ),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
