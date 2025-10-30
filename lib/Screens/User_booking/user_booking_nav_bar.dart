import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';
import 'package:taskoon/Screens/Booking_process_tasker/guidlines_screen.dart';
import 'package:taskoon/Screens/User_booking/guidelines_screen.dart';
import 'package:taskoon/Screens/User_booking/user_booking_home.dart';

class UserBottomNavBar extends StatelessWidget {
  const UserBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor:  Constants.primaryDark,
          primary:        Constants.primaryDark,
          onPrimary: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
          titleMedium: TextStyle(fontWeight: FontWeight.w800),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
        ),
      ),
      home: const _RootNav(), // global bottom nav lives here
    );
  }
}

/* ============================ GLOBAL NAV =============================== */

class _RootNav extends StatefulWidget {
  const _RootNav();

  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0; // start on "Earning" tab to show the screen from the mock

  final _pages = const [
    UserBookingHome(),
    GuidelinesScreenn(), // the screen you asked to design
    UserBookingHome(),
    UserBookingHome(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      // GLOBAL, REUSABLE bottom nav (can be used in any Scaffold)
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomItem(icon: Icons.home_rounded, label: 'Home'),
          BottomItem(icon: Icons.calendar_month_rounded, label: 'Earning'),
          BottomItem(icon: Icons.list_alt_rounded, label: 'Tasks'),
          BottomItem(icon: Icons.menu_rounded, label: 'More'),
        ],
      ),
    );
  }
}

/* ------------------------- Glass BottomNav (reusable) ------------------- */

class BottomItem {
  final IconData icon;
  final String label;
  const BottomItem({required this.icon, required this.label});
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              // purple base with subtle glass gradient + border
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                 Constants.primaryDark,
                Constants.primaryDark,
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.18),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavItemTile(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withOpacity(.85);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}