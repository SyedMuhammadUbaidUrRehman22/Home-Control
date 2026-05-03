import 'package:flutter/material.dart';

class EnergyCard extends StatelessWidget {
  final BoxDecoration? decoration;

  const EnergyCard({super.key, this.decoration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          decoration ??
          BoxDecoration(
            color: const Color.fromARGB(255, 249, 143, 3),
            borderRadius: BorderRadius.circular(24),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Energy Usage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '321.8 kWh',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
