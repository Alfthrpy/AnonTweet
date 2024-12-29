// navigation/bottom_navigation.dart
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article),
          label: 'Cuitan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Cuitan Anda',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.purple,
      onTap: onItemTapped,
    );
  }
}
