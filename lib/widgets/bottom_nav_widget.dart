import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  BottomNavBarWidget({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favourites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Mitt konto',
        ),
      ],
    );
  }
}
