import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrPairingScreen extends StatefulWidget {
  const QrPairingScreen({super.key});

  @override
  State<QrPairingScreen> createState() => _QrPairingScreenState();
}

class _QrPairingScreenState extends State<QrPairingScreen> {
  bool scanned = false;

  Future<void> registerQrDevice(String code) async {
    await FirebaseFirestore.instance.collection('devices').add({
      'name': 'QR Device $code',
      'type': 'Light',
      'room': 'Living Room',
      'isOn': false,

      'connectionType': 'QR Pairing',
      'connectionStatus': 'Connected',

      'qrCode': code,

      'watts': 40,
      'ratePerKwh': 50,

      'totalKwh': 0.0,
      'estimatedCost': 0.0,
      'totalUsageMinutes': 0,

      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('QR Device Connected: $code')));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('QR Pairing')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (scanned) return;

              final List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isEmpty) return;

              final code = barcodes.first.rawValue;

              if (code == null) return;

              scanned = true;

              await registerQrDevice(code);
            },
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              children: const [
                Text(
                  'Scan Smart Device QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Use any QR code for demo pairing',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
