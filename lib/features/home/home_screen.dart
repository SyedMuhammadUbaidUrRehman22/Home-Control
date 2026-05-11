import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../devices/add_device_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../models/device_model.dart';
import '../analytics/analytics_screen.dart';
import '../devices/devices_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/device_card.dart';
import 'widgets/energy_card.dart';
import 'widgets/room_tabs.dart';
import '../devices/bluetooth_scan_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedRoomIndex = 0;
  int _currentIndex = 0;
  bool isTurningOff = false;

  final rooms = ['Living Room', 'Bedroom', 'Kitchen', 'Garden'];

  List<Widget> get _pages => [
    _buildHomeContent(),
    const AnalyticsScreen(),
    const DevicesScreen(),
    const SettingsScreen(),
  ];

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
Future<void> toggleDevice({
    required QueryDocumentSnapshot deviceDoc,
    required bool value,
  }) async {
    final data = deviceDoc.data() as Map<String, dynamic>;
    final oldValue = data['isOn'] ?? false;
    final now = DateTime.now();

    try {
      if (value == true) {
        await deviceDoc.reference.update({
          'isOn': true,
          'lastTurnedOnAt': now.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        double usedKwh = 0;
        double usedCost = 0;
        int usedMinutes = 0;

        final lastTurnedOnAt = data['lastTurnedOnAt'];

        if (lastTurnedOnAt != null) {
          final startedAt = DateTime.parse(lastTurnedOnAt);
          usedMinutes = now.difference(startedAt).inMinutes;

          final watts = (data['watts'] ?? 60).toDouble();
          final rate = (data['ratePerKwh'] ?? 50).toDouble();

          final hours = usedMinutes / 60.0;
          usedKwh = (watts * hours) / 1000.0;
          usedCost = usedKwh * rate;
        }

        await deviceDoc.reference.update({
          'isOn': false,
          'lastTurnedOnAt': null,
          'totalUsageMinutes': (data['totalUsageMinutes'] ?? 0) + usedMinutes,
          'totalKwh': ((data['totalKwh'] ?? 0).toDouble()) + usedKwh,
          'estimatedCost': ((data['estimatedCost'] ?? 0).toDouble()) + usedCost,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance.collection('device_logs').add({
        'deviceId': deviceDoc.id,
        'deviceName': data['name'] ?? 'Unknown Device',
        'room': data['room'] ?? 'Unknown Room',
        'oldStatus': oldValue,
        'newStatus': value,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'manual_toggle',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Energy update failed: $e')));
    }
  }

  Future<void> turnOffAllDevices() async {
    if (isTurningOff) return;

    setState(() => isTurningOff = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('devices')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        batch.update(doc.reference, {
          'isOn': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('device_logs').add({
          'deviceId': doc.id,
          'deviceName': data['name'] ?? 'Unknown Device',
          'room': data['room'] ?? 'Unknown Room',
          'oldStatus': data['isOn'] ?? false,
          'newStatus': false,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'action': 'turn_off_all',
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snapshot.docs.length} devices turned off')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) {
        setState(() => isTurningOff = false);
      }
    }
  }

  Future<void> turnOnAllDevices() async {
    setState(() => isTurningOff = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('devices')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        batch.update(doc.reference, {
          'isOn': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('device_logs').add({
          'deviceId': doc.id,
          'deviceName': data['name'] ?? 'Unknown Device',
          'room': data['room'] ?? 'Unknown Room',
          'oldStatus': data['isOn'] ?? false,
          'newStatus': true,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'action': 'turn_on_all',
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snapshot.docs.length} devices turned on')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to turn on devices.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to turn on devices: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isTurningOff = false);
      }
    }
  }

  Future<void> deleteDevice(QueryDocumentSnapshot deviceDoc) async {
    final data = deviceDoc.data() as Map<String, dynamic>;

    try {
      await FirebaseFirestore.instance.collection('device_logs').add({
        'deviceId': deviceDoc.id,
        'deviceName': data['name'] ?? 'Unknown Device',
        'room': data['room'] ?? 'Unknown Room',
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'device_deleted',
      });

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceDoc.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device removed')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to remove device.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove device: $error')),
      );
    }
  }

  void showDeviceOptions(QueryDocumentSnapshot deviceDoc) {
    final data = deviceDoc.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(data['name'] ?? 'Device Options'),
                  subtitle: Text(data['room'] ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Device'),
                  onTap: () async {
                    Navigator.pop(context);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Remove Device'),
                        content: Text(
                          'Are you sure you want to remove ${data['name'] ?? 'this device'}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await deleteDevice(deviceDoc);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void showQuickMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                const Center(
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 50),
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: const Text('Turn Off All Devices'),
                  onTap: () {
                    Navigator.pop(context);
                    turnOffAllDevices();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Turn On All Devices'),
                  onTap: () {
                    Navigator.pop(context);
                    turnOnAllDevices();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('View Device Logs'),
                  onTap: () {
                    Navigator.pop(context);
                    showLogsScreen();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Go to Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showLogsScreen() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 420,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('device_logs')
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load logs: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No logs yet'));
              }

              final logs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final data = logs[index].data() as Map<String, dynamic>;

                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(data['deviceName'] ?? 'Unknown Device'),
                    subtitle: Text(
                      '${data['room'] ?? 'Unknown Room'} • ${data['action'] ?? 'update'}',
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.38),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BluetoothScanScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF151521), const Color(0xFF25213A)]
              : [AppColors.bg, AppColors.bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: showQuickMenu,
                  ),
                  const Text(
                    'Home',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(icon: const Icon(Icons.logout), onPressed: logout),
                ],
              ),

              const SizedBox(height: 20),

              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;

                  final name = data?['name']?.toString();
                  final displayName = (name == null || name.isEmpty)
                      ? 'Home'
                      : name;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 4),

              const Text(
                'Smart Home Technology',
                style: TextStyle(color: AppColors.textLight),
              ),

              const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('devices')
                    .snapshots(),
                builder: (context, snapshot) {
                  double totalKwh = 0;
                  double totalCost = 0;

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalKwh += (data['totalKwh'] ?? 0).toDouble();
                      totalCost += (data['estimatedCost'] ?? 0).toDouble();
                    }
                  }

                  return EnergyCard(totalKwh: totalKwh, totalCost: totalCost);
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: isTurningOff
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.power_settings_new),
                  label: Text(
                    isTurningOff ? 'Turning Off...' : 'Turn Off All Devices',
                  ),
                  onPressed: isTurningOff ? null : turnOffAllDevices,
                ),
              ),

              const SizedBox(height: 20),

              RoomTabs(
                rooms: rooms,
                selectedIndex: selectedRoomIndex,
                onTap: (index) {
                  setState(() => selectedRoomIndex = index);
                },
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  key: ValueKey(rooms[selectedRoomIndex]),
                  stream: FirebaseFirestore.instance
                      .collection('devices')
                      .where('room', isEqualTo: rooms[selectedRoomIndex])
                      .snapshots(),
                  builder: (context, snapshot) {
                          if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load devices: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No devices in ${rooms[selectedRoomIndex]}',
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return GridView.builder(
                      itemCount: docs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final wattsValue = data['watts'];
                        final rateValue = data['ratePerKwh'];
                        final countValue = data['count'];

                        return GestureDetector(
                          onLongPress: () => showDeviceOptions(doc),
                          child: DeviceCard(
                            device: DeviceModel(
                              name: data['name'] ?? 'Unknown Device',
                              count: countValue is num
                                  ? countValue.toInt()
                                  : int.tryParse(countValue?.toString() ?? '') ?? 1,
                              isOn: data['isOn'] ?? false,
                              icon: _getDeviceIcon(data['type']),
                              watts: wattsValue is num
                                  ? wattsValue.toInt()
                                  : int.tryParse(wattsValue?.toString() ?? '') ?? 60,
                              ratePerKwh: rateValue is num
                                  ? rateValue.toDouble()
                                  : double.tryParse(rateValue?.toString() ?? '') ?? 50.0,
                            ),
                            onToggle: (value) {
                              toggleDevice(deviceDoc: doc, value: value);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
