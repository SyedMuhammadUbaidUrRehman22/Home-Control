import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('devices').snapshots(),
        builder: (context, snapshot) {
          double totalCost = 0;
          double totalKwh = 0;
          int activeDevices = 0;

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              totalCost += (data['estimatedCost'] ?? 0).toDouble();
              totalKwh += (data['totalKwh'] ?? 0).toDouble();

              if (data['isOn'] == true) {
                activeDevices++;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Energy Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Real-time usage from device cycles',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _StatCard(
                title: 'Total Cost',
                value: totalCost.toStringAsFixed(2),
              ),
              _StatCard(
                title: 'Total Energy',
                value: '${totalKwh.toStringAsFixed(2)} kWh',
              ),
              _StatCard(title: 'Active Devices', value: '$activeDevices'),

              const SizedBox(height: 20),

              const Text(
                'Note: cost increases only after a device is turned ON and then OFF.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
