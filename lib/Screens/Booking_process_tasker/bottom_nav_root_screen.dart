import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/earning_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/more_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasks_screen.dart';



class TaskoonTheme {
  TaskoonTheme._();

  static const colors = _TaskoonColors();

  // modern radii + durations
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration med = Duration(milliseconds: 220);

  // unified shadows (soft, modern)
  static List<BoxShadow> softShadow([double opacity = .10]) => [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  static ThemeData light() {
    final c = colors;

    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      primary: c.primary,
      secondary: c.gold,
      surface: c.surface,
      background: c.bg,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: c.text,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: c.bg,
      colorScheme: scheme,

      // ✅ subtle modern ripple + page transitions stay default
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.primary),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: c.text,
        ),
      ),

      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w900,
          color: c.text,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
          color: c.text,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: c.text,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          color: c.body,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          color: c.muted,
        ),
      ),

         elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary.withOpacity(.25)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide(color: c.primary.withOpacity(.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide(color: c.primary.withOpacity(.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r16),
          borderSide: BorderSide(color: c.primary.withOpacity(.35), width: 1.2),
        ),
      ),
    );
  }
}

class _TaskoonColors {
  const _TaskoonColors();

  // ✅ same palette as yours
  final Color primary = const Color(0xFF5C2E91);
  final Color text = const Color(0xFF3E1E69);
  final Color muted = const Color(0xFF75748A);
  final Color bg = const Color(0xFFF8F7FB);
  final Color gold = const Color(0xFFF4C847);

  // ✅ modern extras (safe defaults)
  final Color surface = Colors.white;
  final Color body = const Color(0xFF374151);
}

/* ============================ APP ROOT (MODERN) ============================ */

class TaskoonApp extends StatelessWidget {
  const TaskoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskoon',
      debugShowCheckedModeBanner: false,
      theme: TaskoonTheme.light(),
      home: const _RootNav(),
    );
  }
}

/* ============================ GLOBAL NAV ============================ */

class _RootNav extends StatefulWidget {
  const _RootNav();

  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  final _pages = const [
    TaskerHomeRedesign(),
    EarningsScreen(),
    TasksScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
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

/* ============================ BOTTOM NAV (MORE MODERN) ============================ */

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
    final c = TaskoonTheme.colors;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TaskoonTheme.r24),
          boxShadow: TaskoonTheme.softShadow(.14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TaskoonTheme.r24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.primary.withOpacity(.92),
                    c.primary.withOpacity(.78),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(.16)),
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
    final c = TaskoonTheme.colors;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: TaskoonTheme.med,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(TaskoonTheme.r16),
              border: selected ? Border.all(color: Colors.white.withOpacity(.22)) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: selected ? Colors.white : Colors.white.withOpacity(.82),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: selected ? Colors.white : Colors.white.withOpacity(.82),
                    fontWeight: FontWeight.w700,
                  fontSize: 11.2,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: TaskoonTheme.fast,
                  height: 3,
                  width: selected ? 22 : 8,
                  decoration: BoxDecoration(
                    color: selected ? c.gold : Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





// class _Colors {
//   static const Constants = _ColorConstants();
// }

// class _ColorConstants {
//   const _ColorConstants();

//   // ✅ Taskoon theme tokens (match your screens)
//   final Color primaryDark = const Color(0xFF5C2E91); // main purple
//   final Color primaryText = const Color(0xFF3E1E69); // dark purple text
//   final Color mutedText = const Color(0xFF75748A); // muted gray
//   final Color bg = const Color(0xFFF8F7FB); // scaffold bg
//   final Color gold = const Color(0xFFF4C847); // accent gold
// }

// /* ============================ APP ROOT ============================ */

// class TaskoonApp extends StatelessWidget {
//   const TaskoonApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;
//     return MaterialApp(
//       title: 'Taskoon',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         fontFamily: 'Poppins',
//         scaffoldBackgroundColor: c.bg,

//         // ✅ global color scheme (Taskoon)
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: c.primaryDark,
//           primary: c.primaryDark,
//           secondary: c.gold,
//           surface: Colors.white,
//           background: c.bg,
//           onPrimary: Colors.white,
//           onSurface: c.primaryText,
//         ),

//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.transparent,
//           surfaceTintColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: false,
//           iconTheme: IconThemeData(color: c.primaryDark),
//           titleTextStyle: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w800,
//             fontSize: 18,
//             color: c.primaryText,
//           ),
//         ),

//         textTheme: TextTheme(
//           titleLarge: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w800,
//             letterSpacing: .2,
//             color: c.primaryText,
//           ),
//           titleMedium: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w800,
//             color: c.primaryText,
//           ),
//           bodyMedium: const TextStyle(
//             fontFamily: 'Poppins',
//             color: Color(0xFF374151),
//           ),
//           bodySmall: TextStyle(
//             fontFamily: 'Poppins',
//             color: c.mutedText,
//           ),
//         ),

//         // cardTheme: CardTheme(
//         //   color: Colors.white,
//         //   elevation: 0,
//         //   shape: RoundedRectangleBorder(
//         //     borderRadius: BorderRadius.circular(18),
//         //   ),
//         // ),
//       ),

//       home: const _RootNav(),
//     );
//   }
// }

// /* ============================ GLOBAL NAV ============================ */

// class _RootNav extends StatefulWidget {
//   const _RootNav();

//   @override
//   State<_RootNav> createState() => _RootNavState();
// }

// class _RootNavState extends State<_RootNav> {
//   int _index = 0;

//   // ✅ keep your pages as-is (NO functionality changes)
//   final _pages = const [
//     TaskerHomeRedesign(),
//     EarningsScreen(),
//     TasksScreen(),
//     MoreScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _index, children: _pages),

//       // ✅ Updated UI-only BottomNav (Taskoon theme)
//       bottomNavigationBar: GlassBottomNav(
//         currentIndex: _index,
//         onTap: (i) => setState(() => _index = i),
//         items: const [
//           BottomItem(icon: Icons.home_rounded, label: 'Home'),
//           BottomItem(icon: Icons.calendar_month_rounded, label: 'Earning'),
//           BottomItem(icon: Icons.list_alt_rounded, label: 'Tasks'),
//           BottomItem(icon: Icons.menu_rounded, label: 'More'),
//         ],
//       ),
//     );
//   }
// }

// /* ============================ BOTTOM NAV ============================ */

// class BottomItem {
//   final IconData icon;
//   final String label;
//   const BottomItem({required this.icon, required this.label});
// }

// class GlassBottomNav extends StatelessWidget {
//   const GlassBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     required this.items,
//   });

//   final int currentIndex;
//   final ValueChanged<int> onTap;
//   final List<BottomItem> items;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return SafeArea(
//       top: false,
//       minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           // ✅ real glass
//           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//           child: Container(
//             height: 74,
//             decoration: BoxDecoration(
//               // ✅ Taskoon purple glass gradient
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   c.primaryDark.withOpacity(0.92),
//                   c.primaryDark.withOpacity(0.80),
//                 ],
//               ),
//               border: Border.all(color: Colors.white.withOpacity(.14)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(.16),
//                   blurRadius: 28,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 for (int i = 0; i < items.length; i++)
//                   _NavItemTile(
//                     item: items[i],
//                     selected: i == currentIndex,
//                     onTap: () => onTap(i),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItemTile extends StatelessWidget {
//   const _NavItemTile({
//     required this.item,
//     required this.selected,
//     required this.onTap,
//   });

//   final BottomItem item;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;
//     final Color base = selected ? Colors.white : Colors.white.withOpacity(.85);

//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         splashColor: Colors.white24,
//         highlightColor: Colors.transparent,
//         child: Center(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: selected ? Colors.white.withOpacity(.14) : Colors.transparent,
//               borderRadius: BorderRadius.circular(16),
//               border: selected ? Border.all(color: Colors.white.withOpacity(.22)) : null,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(item.icon, color: base),
//                 const SizedBox(height: 6),
//                 Text(
//                   item.label,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: base,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 12.5,
//                   ),
//                 ),
//                 if (selected) ...[
//                   const SizedBox(height: 5),
//                   Container(
//                     height: 3,
//                     width: 22,
//                     decoration: BoxDecoration(
//                       color: c.gold, // ✅ gold active indicator
//                       borderRadius: BorderRadius.circular(99),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





/*
class TaskoonApp extends StatelessWidget {
  const TaskoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor:  _Colors.Constants.primaryDark,
          primary:        _Colors.Constants.primaryDark,
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
    TaskerHomeRedesign(),
    EarningsScreen(), // the screen you asked to design
    TasksScreen(),
    MoreScreen(),
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
                   _Colors.Constants.primaryDark,
                _Colors.Constants.primaryDark
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
}*/