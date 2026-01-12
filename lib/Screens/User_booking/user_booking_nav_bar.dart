import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';
import 'package:taskoon/Screens/Booking_process_tasker/my_account_screen.dart';
import 'package:taskoon/Screens/User_booking/feedback_screen.dart';
import 'package:taskoon/Screens/User_booking/guidelines_screen.dart';
import 'package:taskoon/Screens/User_booking/my_bookings.dart';
import 'package:taskoon/Screens/User_booking/user_booking_home.dart';

// class UserBottomNavBar extends StatelessWidget {
//   const UserBottomNavBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Taskoon',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF8F7FB),
//         colorScheme: ColorScheme.fromSeed(
//           seedColor:  Constants.primaryDark,
//           primary:        Constants.primaryDark,
//           onPrimary: Colors.white,
//         ),
//         textTheme: const TextTheme(
//           titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
//           titleMedium: TextStyle(fontWeight: FontWeight.w800),
//           bodyMedium: TextStyle(color: Color(0xFF374151)),
//         ),
//       ),
//       home: const _RootNav(), // global bottom nav lives here
//     );
//   }
// }

// /* ============================ GLOBAL NAV =============================== */

// class _RootNav extends StatefulWidget {
//   const _RootNav();

//   @override
//   State<_RootNav> createState() => _RootNavState();
// }

// class _RootNavState extends State<_RootNav> {
//   int _index = 0; // start on "Earning" tab to show the screen from the mock

//   final _pages = const [
//     UserBookingHome(),
//  MyBookings(), //  GuidelinesScreenn(), // the screen you asked to design
//     FeedbackScreen(),
//     GuidelinesScreenn(),
//         MyAccountScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _index, children: _pages),
//       // GLOBAL, REUSABLE bottom nav (can be used in any Scaffold)
//       bottomNavigationBar: GlassBottomNav(
//         currentIndex: _index,
//         onTap: (i) => setState(() => _index = i),
//         items: const [
//           BottomItem(icon: Icons.home_rounded, label: 'Home'),
//           BottomItem(icon: Icons.event_note_rounded, label: 'Bookings'),
//           BottomItem(icon: Icons.list_alt_rounded, label: 'Feedback'),
//           BottomItem(icon: Icons.list_alt_rounded, label: 'Guidelines'),
//           BottomItem(icon: Icons.menu_rounded, label: 'Account'),
//         ],
//       ),
//     );
//   }
// }

// /* ------------------------- Glass BottomNav (reusable) ------------------- */

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
//     return SafeArea(
//       top: false,
//       minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: ClipRRect(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//           bottomLeft: Radius.circular(25),
//           bottomRight: Radius.circular(25),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
//           child: Container(
//             height: 70,
//             decoration: BoxDecoration(
//               // purple base with subtle glass gradient + border
//               gradient:const LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                  Constants.primaryDark,
//                 Constants.primaryDark,
//                 ],
//               ),
//               border: Border.all(color: Colors.white.withOpacity(.08)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(.18),
//                   blurRadius: 30,
//                   offset: const Offset(0, 4),
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
//     final color = selected ? Colors.white : Colors.white.withOpacity(.85);
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         splashColor: Colors.white24,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(item.icon, color: color),
//             const SizedBox(height: 6),
//             Text(
//               item.label,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.w700,
//                 fontSize: 12.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




class TaskoonTheme {
  TaskoonTheme._();

  static const colors = _TaskoonColors();

  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration med = Duration(milliseconds: 220);

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
      splashFactory: InkRipple.splashFactory,
      textTheme: TextTheme(
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
    );
  }
}

class _TaskoonColors {
  const _TaskoonColors();

  final Color primary = const Color(0xFF5C2E91);
  final Color text = const Color(0xFF3E1E69);
  final Color muted = const Color(0xFF75748A);
  final Color bg = const Color(0xFFF8F7FB);
  final Color gold = const Color(0xFFF4C847);

  final Color surface = Colors.white;
  final Color body = const Color(0xFF374151);
}

// ============================ APP ROOT ============================
// Keep your existing pages/items exactly the same.
// This widget is like your UserBottomNavBar but with TaskoonTheme applied.

class UserBottomNavBar extends StatelessWidget {
  const UserBottomNavBar({super.key});

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

// ============================ GLOBAL NAV ============================

class _RootNav extends StatefulWidget {
  const _RootNav();

  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  // ✅ keep your pages same
  final _pages = const [
    UserBookingHome(),
    MyBookings(),
    FeedbackScreen(),
    GuidelinesScreenn(),
    MyAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),

      // ✅ modern bottom nav (theme only)
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomItem(icon: Icons.home_rounded, label: 'Home'),
          BottomItem(icon: Icons.event_note_rounded, label: 'Bookings'),
          BottomItem(icon: Icons.list_alt_rounded, label: 'Feedback'),
          BottomItem(icon: Icons.list_alt_rounded, label: 'Guideline'),
          BottomItem(icon: Icons.menu_rounded, label: 'Account'),
        ],
      ),
    );
  }
}

// ============================ BOTTOM NAV (PURPLE DIALOG-STYLE GLASS) ============================

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

  // ✅ Taskoon Purple Gradient
  static const LinearGradient _grad = LinearGradient(
    colors: [Color(0xFF7841BA), Color(0xFF5C2E91)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final s = w / 390.0;

    return SafeArea(
      top: false,
   minimum: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 60 * s),
//   minimum: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 12 * s),
      child: Container(
        height: 76 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22 * s),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22 * s),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: _grad,
                border: Border.all(color: Colors.white.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItemTile(
                        item: items[i],
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                        scale: s,
                      ),
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
    required this.scale,
  });

  final BottomItem item;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  // ✅ Taskoon Purple Gradient (same as nav)
  static const LinearGradient _grad = LinearGradient(
    colors: [Color(0xFF7841BA), Color(0xFF5C2E91)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 9 * scale,
            ),
            decoration: BoxDecoration(
              // ✅ selected looks like your dialog button/pill style
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16 * scale),
              border: selected
                  ? Border.all(
                      color: const Color(0xFF7841BA).withOpacity(.22),
                      width: 1.1,
                    )
                  : Border.all(
                      color: Colors.white.withOpacity(.10),
                      width: 1,
                    ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? ShaderMask(
                          key: const ValueKey('selectedIcon'),
                          shaderCallback: (rect) => _grad.createShader(rect),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 22 * scale,
                          ),
                        )
                      : Icon(
                          item.icon,
                          key: const ValueKey('normalIcon'),
                          color: Colors.white.withOpacity(.88),
                          size: 22 * scale,
                        ),
                ),

                SizedBox(height: 6 * scale),

                // ✅ label
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 10.2 * scale,
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? const Color(0xFF0F172A)
                        : Colors.white.withOpacity(.88),
                    letterSpacing: 0.2,
                  ),
                ),

                SizedBox(height: 6 * scale),

                // ✅ tiny indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3 * scale,
                  width: selected ? 22 * scale : 10 * scale,
                  decoration: BoxDecoration(
                    gradient: selected ? _grad : null,
                    color: selected ? null : Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(59),
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


// ============================ BOTTOM NAV (DIALOG-STYLE GLASS) ============================

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

//   // same as your dialog gradient
//   static const LinearGradient _grad = LinearGradient(
//     colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final s = w / 390.0;

//     return SafeArea(
//       top: false,
//       minimum: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 12 * s),
//       child: Container(
//         height: 76 * s,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22 * s),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x22000000),
//               blurRadius: 18,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(22 * s),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: _grad,
//                 border: Border.all(color: Colors.white.withOpacity(.18)),
//               ),
//               child: Row(
//                 children: [
//                   for (int i = 0; i < items.length; i++)
//                     Expanded(
//                       child: _NavItemTile(
//                         item: items[i],
//                         selected: i == currentIndex,
//                         onTap: () => onTap(i),
//                         scale: s,
//                       ),
//                     ),
//                 ],
//               ),
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
//     required this.scale,
//   });

//   final BottomItem item;
//   final bool selected;
//   final VoidCallback onTap;
//   final double scale;

//   static const LinearGradient _grad = LinearGradient(
//     colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         splashColor: Colors.white24,
//         highlightColor: Colors.transparent,
//         child: Center(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 220),
//             curve: Curves.easeOutCubic,
//             padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 9 * scale),
//             decoration: BoxDecoration(
//               // selected looks like your dialog button/pill style
//               color: selected ? Colors.white : Colors.transparent,
//               borderRadius: BorderRadius.circular(16 * scale),
//               border: selected
//                   ? Border.all(color: const Color(0xFF7F53FD).withOpacity(.22), width: 1.1)
//                   : Border.all(color: Colors.white.withOpacity(.10), width: 1),
//               boxShadow: selected
//                   ? const [
//                       BoxShadow(
//                         color: Color(0x22000000),
//                         blurRadius: 14,
//                         offset: Offset(0, 8),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // icon
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 180),
//                   child: selected
//                       ? ShaderMask(
//                           key: const ValueKey('selectedIcon'),
//                           shaderCallback: (rect) => _grad.createShader(rect),
//                           child: Icon(item.icon, color: Colors.white, size: 22 * scale),
//                         )
//                       : Icon(
//                           item.icon,
//                           key: const ValueKey('normalIcon'),
//                           color: Colors.white.withOpacity(.88),
//                           size: 22 * scale,
//                         ),
//                 ),

//                 SizedBox(height: 6 * scale),

//                 // label
//                 Text(
//                   item.label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontFamily: 'ClashGrotesk', // match dialog typography
//                     fontSize: 11.2 * scale,
//                     fontWeight: FontWeight.w900,
//                     color: selected ? const Color(0xFF0F172A) : Colors.white.withOpacity(.88),
//                     letterSpacing: 0.2,
//                   ),
//                 ),

//                 SizedBox(height: 6 * scale),

//                 // tiny indicator
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 160),
//                   height: 3 * scale,
//                   width: selected ? 22 * scale : 10 * scale,
//                   decoration: BoxDecoration(
//                     gradient: selected ? _grad : null,
//                     color: selected ? null : Colors.white.withOpacity(.22),
//                     borderRadius: BorderRadius.circular(99),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// ============================ BOTTOM NAV (MODERN GLASS) ============================
/*
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
*/
/* ============================ YOUR EXISTING SCREENS ============================
   Keep these imports in your project, I am just referencing them here.
   - UserBookingHome()
   - MyBookings()
   - FeedbackScreen()
   - GuidelinesScreenn()
   - MyAccountScreen()
=============================================================================== */
