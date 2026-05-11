import 'package:flutter/material.dart';

import 'bluetooth_scan_screen.dart';
import 'manual_device_screen.dart';
import 'qr_pairing_screen.dart';
import 'wifi_setup_screen.dart';

class AddDeviceOptionsSheet extends StatelessWidget {
  const AddDeviceOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Add Smart Device',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose how you want to connect your IoT device',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _OptionTile(
            icon: Icons.wifi,
            title: 'Wi-Fi Setup',
            subtitle: 'Connect smart devices over Wi-Fi',
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WifiSetupScreen()),
              );
            },
          ),

          _OptionTile(
            icon: Icons.bluetooth,
            title: 'Bluetooth Scan',
            subtitle: 'Scan nearby Bluetooth devices',
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothScanScreen()),
              );
            },
          ),

          _OptionTile(
            icon: Icons.qr_code_scanner,
            title: 'QR Code Pairing',
            subtitle: 'Pair device using QR setup',
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrPairingScreen()),
              );
            },
          ),

          _OptionTile(
            icon: Icons.memory,
            title: 'Manual Demo Device',
            subtitle: 'Add simulated IoT device manually',
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualDeviceScreen()),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(radius: 26, child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
