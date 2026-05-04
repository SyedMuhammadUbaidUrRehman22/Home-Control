import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  IconData _getDeviceIcon(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'ac':
        return Icons.ac_unit;
      case 'tv':
        return Icons.tv;
      case 'plug':
        return Icons.power;
      case 'blinds':
        return Icons.window;
      default:
        return Icons.devices;
    }
  }

  Future<void> _toggleDevice(String id, bool value) async {
    await FirebaseFirestore.instance.collection('devices').doc(id).update({
      'isOn': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteDevice(String id) async {
    await FirebaseFirestore.instance.collection('devices').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'All Devices',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${docs.length} connected devices',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              if (docs.isEmpty) const Center(child: Text('No devices found')),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFFFFB86B,
                        ).withOpacity(0.25),
                        child: Icon(
                          _getDeviceIcon(data['type']),
                          color: const Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Unknown Device',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data['room'] ?? 'Unknown Room'} • ${data['type'] ?? 'Device'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: data['isOn'] ?? false,
                        onChanged: (value) => _toggleDevice(doc.id, value),
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteDevice(doc.id),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
