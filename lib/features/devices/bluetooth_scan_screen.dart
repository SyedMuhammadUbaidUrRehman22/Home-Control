import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final List<ScanResult> devices = [];

  StreamSubscription<List<ScanResult>>? scanSubscription;

  bool isScanning = false;

  final rooms = ['Living Room', 'Bedroom', 'Kitchen', 'Garden'];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> startScan() async {
    devices.clear();

    setState(() => isScanning = true);

    scanSubscription?.cancel();

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        devices.clear();
        devices.addAll(results);
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    await Future.delayed(const Duration(seconds: 8));

    if (mounted) {
      setState(() => isScanning = false);
    }
  }

  Future<void> saveBluetoothDevice(ScanResult result) async {
    final nameController = TextEditingController(
      text: result.device.platformName.isEmpty
          ? 'Bluetooth Device'
          : result.device.platformName,
    );

    final wattsController = TextEditingController(text: '60');
    final rateController = TextEditingController(text: '50');

    String selectedRoom = 'Living Room';
    String selectedType = 'Light';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register Bluetooth Device'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Device Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Light', child: Text('Light')),
                        DropdownMenuItem(value: 'AC', child: Text('AC')),
                        DropdownMenuItem(value: 'TV', child: Text('TV')),
                        DropdownMenuItem(value: 'Plug', child: Text('Plug')),
                        DropdownMenuItem(
                          value: 'Blinds',
                          child: Text('Blinds'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        border: OutlineInputBorder(),
                      ),
                      items: rooms.map((room) {
                        return DropdownMenuItem(value: room, child: Text(room));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRoom = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: wattsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Power Rating Watts',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rate per kWh',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final watts =
                        int.tryParse(wattsController.text.trim()) ?? 60;
                    final rate =
                        double.tryParse(rateController.text.trim()) ?? 50;

                    if (name.isEmpty) return;

                    await FirebaseFirestore.instance.collection('devices').add({
                      'name': name,
                      'count': 1,
                      'type': selectedType,
                      'room': selectedRoom,
                      'isOn': false,

                      'connectionType': 'Bluetooth',
                      'connectionStatus': 'Connected',
                      'bluetoothId': result.device.remoteId.toString(),
                      'bluetoothName': result.device.platformName,
                      'rssi': result.rssi,

                      'watts': watts,
                      'ratePerKwh': rate,
                      'totalKwh': 0.0,
                      'estimatedCost': 0.0,
                      'totalUsageMinutes': 0,
                      'lastTurnedOnAt': null,

                      'userId': FirebaseAuth.instance.currentUser?.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('device_logs')
                        .add({
                          'deviceName': name,
                          'room': selectedRoom,
                          'connectionType': 'Bluetooth',
                          'bluetoothId': result.device.remoteId.toString(),
                          'action': 'bluetooth_device_added',
                          'userId': FirebaseAuth.instance.currentUser?.uid,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    wattsController.dispose();
    rateController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth device registered')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Bluetooth Pairing')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scan nearby Bluetooth devices and register one as a smart home device.',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: isScanning
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(
                  isScanning ? 'Scanning...' : 'Scan Bluetooth Devices',
                ),
                onPressed: isScanning ? null : startScan,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text('No Bluetooth devices found yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final result = devices[index];
                      final name = result.device.platformName.isEmpty
                          ? 'Unnamed Device'
                          : result.device.platformName;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text(
                            '${result.device.remoteId} • RSSI ${result.rssi}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => saveBluetoothDevice(result),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
