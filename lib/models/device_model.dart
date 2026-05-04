import 'package:flutter/material.dart';

class DeviceModel {
  final String name;
  final int count;
  bool isOn;
  final IconData icon;

  final int watts;
  final double ratePerKwh;

  DeviceModel({
    required this.name,
    required this.count,
    required this.isOn,
    required this.icon,
    required this.watts,
    required this.ratePerKwh,
  });
}
