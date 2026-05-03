import 'package:flutter/material.dart';

class DeviceModel {
  final String name;
  final int count;
  bool isOn;
  final IconData icon;

  DeviceModel({
    required this.name,
    required this.count,
    required this.isOn,
    required this.icon,
  });
}
