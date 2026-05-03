import 'package:flutter/material.dart';

class RoomTabs extends StatelessWidget {
  final List<String> rooms;
  final int selectedIndex;
  final Function(int) onTap;

  const RoomTabs({
    super.key,
    required this.rooms,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueGrey : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rooms[index],
                style: TextStyle(
                  color: isSelected ? const Color.fromARGB(255, 242, 245, 247) : const Color.fromARGB(255, 165, 213, 243),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}