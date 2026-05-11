import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  final deviceNameController = TextEditingController();

  bool connecting = false;

  Future<void> connectWifiDevice() async {
    if (deviceNameController.text.trim().isEmpty) return;

    setState(() => connecting = true);

    await Future.delayed(const Duration(seconds: 2));

    await FirebaseFirestore.instance.collection('devices').add({
      'name': deviceNameController.text.trim(),
      'type': 'WiFi Device',
      'room': 'Living Room',
      'isOn': false,

      'connectionType': 'WiFi',
      'connectionStatus': 'Connected',

      'wifiSSID': ssidController.text.trim(),

      'watts': 60,
      'ratePerKwh': 50,

      'totalKwh': 0.0,
      'estimatedCost': 0.0,
      'totalUsageMinutes': 0,

      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Device Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Connect Smart Device over WiFi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: deviceNameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: ssidController,
            decoration: const InputDecoration(
              labelText: 'WiFi SSID',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'WiFi Password',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: connecting ? null : connectWifiDevice,
              child: connecting
                  ? const CircularProgressIndicator()
                  : const Text('Connect Device'),
            ),
          ),
        ],
      ),
    );
  }
}
