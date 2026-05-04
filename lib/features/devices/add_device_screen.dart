import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final nameController = TextEditingController();
  final countController = TextEditingController(text: '1');
  final wattsController = TextEditingController(text: '60');
  final rateController = TextEditingController(text: '50');

  final rooms = ['Living Room', 'Bedroom', 'Kitchen', 'Garden'];

  String selectedRoom = 'Living Room';
  String selectedType = 'Light';
  String connectionType = 'Manual Demo';
  bool isOn = false;
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    countController.dispose();
    wattsController.dispose();
    rateController.dispose();
    super.dispose();
  }

  Future<void> saveDevice() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device name is required')));
      return;
    }

    setState(() => isSaving = true);

    final count = int.tryParse(countController.text.trim()) ?? 1;
    final watts = int.tryParse(wattsController.text.trim()) ?? 60;
    final rate = double.tryParse(rateController.text.trim()) ?? 50;

    await FirebaseFirestore.instance.collection('devices').add({
      'name': name,
      'count': count,
      'type': selectedType,
      'room': selectedRoom,
      'isOn': isOn,
      'connectionType': connectionType,
      'connectionStatus': 'Connected',
      'watts': watts,
      'ratePerKwh': rate,
      'totalUsageMinutes': 0,
      'estimatedCost': 0,
      'lastTurnedOnAt': null,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('device_logs').add({
      'deviceName': name,
      'room': selectedRoom,
      'newStatus': isOn,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'action': 'device_added',
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add IoT Device')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Device Count',
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
              DropdownMenuItem(value: 'Blinds', child: Text('Blinds')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => selectedType = value);
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
              if (value != null) setState(() => selectedRoom = value);
            },
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: connectionType,
            decoration: const InputDecoration(
              labelText: 'Connection Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'WiFi', child: Text('WiFi')),
              DropdownMenuItem(value: 'Bluetooth', child: Text('Bluetooth')),
              DropdownMenuItem(value: 'QR Scan', child: Text('QR Scan')),
              DropdownMenuItem(
                value: 'Manual Demo',
                child: Text('Manual Demo'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => connectionType = value);
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
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Device is ON'),
            value: isOn,
            onChanged: (value) => setState(() => isOn = value),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveDevice,
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Device'),
            ),
          ),
        ],
      ),
    );
  }
}
