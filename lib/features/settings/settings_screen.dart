import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import 'edit_profile_field_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;

  String name = '';
  String email = '';
  String phone = '';

  bool notificationsEnabled = true;
  bool deviceAlerts = true;
  bool energyAlerts = true;
  bool securityAlerts = true;

  DocumentReference<Map<String, dynamic>> get userDoc {
    return FirebaseFirestore.instance.collection('users').doc(user!.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    if (user == null) return;

    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set({
        'name': '',
        'email': user!.email ?? '',
        'phone': '',
        'notificationsEnabled': true,
        'deviceAlerts': true,
        'energyAlerts': true,
        'securityAlerts': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final updatedDoc = await userDoc.get();
    final data = updatedDoc.data() ?? {};

    if (!mounted) return;

    setState(() {
      name = data['name'] ?? '';
      email = data['email'] ?? user!.email ?? '';
      phone = data['phone'] ?? '';

      notificationsEnabled = data['notificationsEnabled'] ?? true;
      deviceAlerts = data['deviceAlerts'] ?? true;
      energyAlerts = data['energyAlerts'] ?? true;
      securityAlerts = data['securityAlerts'] ?? true;

      isLoading = false;
    });
  }

  Future<void> _updateField(String field, dynamic value) async {
    if (user == null) return;

    await userDoc.set({
      field: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _loadUserSettings();
  }

  Future<void> _openEditScreen({
    required String title,
    required String field,
    required String initialValue,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileFieldScreen(title: title, initialValue: initialValue),
      ),
    );

    if (result == null) return;

    await _updateField(field, result);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title updated')));
  }

  Future<void> _sendPasswordReset() async {
    if (user?.email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email found')));
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

    await _updateField(
      'lastPasswordResetRequest',
      FieldValue.serverTimestamp(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          const _SectionTitle('Profile'),

          _SettingTile(
            icon: Icons.person,
            title: 'Name',
            subtitle: name.isEmpty ? 'Add your name' : name,
            onTap: () => _openEditScreen(
              title: 'Name',
              field: 'name',
              initialValue: name,
            ),
          ),

          _SettingTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: email,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email is managed by Firebase Auth'),
                ),
              );
            },
          ),

          _SettingTile(
            icon: Icons.phone,
            title: 'Phone Number',
            subtitle: phone.isEmpty ? 'Add phone number' : phone,
            onTap: () => _openEditScreen(
              title: 'Phone Number',
              field: 'phone',
              initialValue: phone,
            ),
          ),

          const SizedBox(height: 20),
          const _SectionTitle('Notifications'),

          _SwitchTile(
            title: 'Enable Notifications',
            subtitle: 'Master notification switch',
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
              _updateField('notificationsEnabled', value);
            },
          ),

          _SwitchTile(
            title: 'Device Alerts',
            subtitle: 'Notify when devices change state',
            value: deviceAlerts,
            onChanged: (value) {
              setState(() => deviceAlerts = value);
              _updateField('deviceAlerts', value);
            },
          ),

          _SwitchTile(
            title: 'Energy Alerts',
            subtitle: 'Notify about high energy usage',
            value: energyAlerts,
            onChanged: (value) {
              setState(() => energyAlerts = value);
              _updateField('energyAlerts', value);
            },
          ),

          const SizedBox(height: 20),
          const _SectionTitle('Security'),

          _SwitchTile(
            title: 'Security Alerts',
            subtitle: 'Login and account activity alerts',
            value: securityAlerts,
            onChanged: (value) {
              setState(() => securityAlerts = value);
              _updateField('securityAlerts', value);
            },
          ),

          Builder(
            builder: (context) {
              final theme = ThemeController.of(context);

              return _SwitchTile(
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark mode',
                value: theme.isDark,
                onChanged: theme.toggleTheme,
              );
            },
          ),

          _SettingTile(
            icon: Icons.lock_reset,
            title: 'Reset Password',
            subtitle: 'Send password reset email',
            onTap: _sendPasswordReset,
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C5CE7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
