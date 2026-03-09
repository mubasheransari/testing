import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/earning_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/emergency_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/guidlines_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/my_account_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasks_screen.dart';
import 'package:taskoon/widgets/logout_popup.dart';

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
              BorderSide(color: c.primary.withOpacity(.35), width: 1.2),
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

/* ============================ APP ROOT ============================ */

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

  final List<Widget> _pages = const [
    TaskerHomeRedesign(),
    EarningsScreen(),
    TasksScreen(),
    MyAccountScreen(),
    GuidelinesScreen(),
    EmergencyScreen(),
  ];

  final List<_MoreItem> _moreItems = const [
    _MoreItem(
      index: 3,
      icon: Icons.person_rounded,
      label: 'My account',
      subtitle: 'Profile, preferences & security',
    ),
    _MoreItem(
      index: 4,
      icon: Icons.menu_book_rounded,
      label: 'Guidelines',
      subtitle: 'How to use the app safely',
    ),
    _MoreItem(
      index: 5,
      icon: Icons.notifications_active_rounded,
      label: 'Emergency',
      subtitle: 'Quick actions & contacts',
      iconBg: Color(0xFFFFECEC),
      iconFg: Color(0xFFC62828),
    ),
  ];

  bool get _isMoreSelected => _index >= 3;

  void _onBottomNavTap(int navIndex) {
    if (navIndex == 3) {
      _openMoreSheet();
      return;
    }

    setState(() {
      _index = navIndex;
    });
  }

void _openMoreSheet() {
  final c = TaskoonTheme.colors;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final maxSheetHeight = media.size.height * 0.72;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            18 + media.viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TaskoonTheme.r24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxSheetHeight,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.primary.withOpacity(.96),
                      c.primary.withOpacity(.84),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(TaskoonTheme.r24),
                  border: Border.all(color: Colors.white.withOpacity(.14)),
                  boxShadow: TaskoonTheme.softShadow(.18),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.28),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'More',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Flexible(
                            child: _MoreHeaderPill(
                              label: 'Sign out',
                              icon: Icons.logout_rounded,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                GlobalSignOut.show(context);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const _MoreSectionLabel('Account'),
                      const SizedBox(height: 10),
                      _MoreOptionTile(
                        icon: _moreItems[0].icon,
                        label: _moreItems[0].label,
                        subtitle: _moreItems[0].subtitle,
                        selected: _index == _moreItems[0].index,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() => _index = _moreItems[0].index);
                        },
                      ),

                      const SizedBox(height: 14),

                      const _MoreSectionLabel('Help'),
                      const SizedBox(height: 10),
                      _MoreOptionTile(
                        icon: _moreItems[1].icon,
                        label: _moreItems[1].label,
                        subtitle: _moreItems[1].subtitle,
                        selected: _index == _moreItems[1].index,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() => _index = _moreItems[1].index);
                        },
                      ),

                      const SizedBox(height: 14),

                      const _MoreSectionLabel('Safety'),
                      const SizedBox(height: 10),
                      _MoreOptionTile(
                        icon: _moreItems[2].icon,
                        label: _moreItems[2].label,
                        subtitle: _moreItems[2].subtitle,
                        selected: _index == _moreItems[2].index,
                        iconBg: _moreItems[2].iconBg,
                        iconFg: _moreItems[2].iconFg,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          setState(() => _index = _moreItems[2].index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        isMoreSelected: _isMoreSelected,
        onTap: _onBottomNavTap,
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

/* ============================ BOTTOM NAV ============================ */

class BottomItem {
  final IconData icon;
  final String label;

  const BottomItem({
    required this.icon,
    required this.label,
  });
}

class _MoreItem {
  final int index;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? iconBg;
  final Color? iconFg;

  const _MoreItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.iconBg,
    this.iconFg,
  });
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.isMoreSelected,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final bool isMoreSelected;
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
                      selected: i == 3 ? isMoreSelected : i == currentIndex,
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
              color:
                  selected ? Colors.white.withOpacity(.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(TaskoonTheme.r16),
              border: selected
                  ? Border.all(color: Colors.white.withOpacity(.22))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(.82),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(.82),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
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

/* ============================ MORE HEADER PILL ============================ */

class _MoreHeaderPill extends StatelessWidget {
  const _MoreHeaderPill({
    required this.label,
    required this.icon,
    this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? Colors.white
        : Colors.white.withOpacity(.12);
    final fg = filled
        ? TaskoonTheme.colors.primary
        : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================ MORE SECTION LABEL ============================ */

class _MoreSectionLabel extends StatelessWidget {
  const _MoreSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.white.withOpacity(.78),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/* ============================ MORE TILE ============================ */

class _MoreOptionTile extends StatelessWidget {
  const _MoreOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.onTap,
    this.iconBg,
    this.iconFg,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Color? iconBg;
  final Color? iconFg;

  @override
  Widget build(BuildContext context) {
    final bg = iconBg ?? Colors.white.withOpacity(.12);
    final fg = iconFg ?? Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(.10),
        highlightColor: Colors.white.withOpacity(.05),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                selected ? Colors.white.withOpacity(.16) : Colors.white.withOpacity(.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.10)),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: fg, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(.12)),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class TaskoonTheme {
//   TaskoonTheme._();

//   static const colors = _TaskoonColors();

//   static const double r12 = 12;
//   static const double r16 = 16;
//   static const double r20 = 20;
//   static const double r24 = 24;

//   static const Duration fast = Duration(milliseconds: 160);
//   static const Duration med = Duration(milliseconds: 220);

//   static List<BoxShadow> softShadow([double opacity = .10]) => [
//         BoxShadow(
//           color: Colors.black.withOpacity(opacity),
//           blurRadius: 26,
//           offset: const Offset(0, 12),
//         ),
//       ];

//   static ThemeData light() {
//     final c = colors;

//     final scheme = ColorScheme.fromSeed(
//       seedColor: c.primary,
//       primary: c.primary,
//       secondary: c.gold,
//       surface: c.surface,
//       background: c.bg,
//       onPrimary: Colors.white,
//       onSecondary: Colors.black,
//       onSurface: c.text,
//       brightness: Brightness.light,
//     );

//     return ThemeData(
//       useMaterial3: true,
//       fontFamily: 'Poppins',
//       scaffoldBackgroundColor: c.bg,
//       colorScheme: scheme,

//       // ✅ subtle modern ripple + page transitions stay default
//       splashFactory: InkRipple.splashFactory,

//       appBarTheme: AppBarTheme(
//         backgroundColor: Colors.transparent,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: false,
//         iconTheme: IconThemeData(color: c.primary),
//         titleTextStyle: TextStyle(
//           fontFamily: 'Poppins',
//           fontWeight: FontWeight.w800,
//           fontSize: 18,
//           color: c.text,
//         ),
//       ),

//       textTheme: TextTheme(
//         headlineSmall: TextStyle(
//           fontFamily: 'Poppins',
//           fontWeight: FontWeight.w900,
//           color: c.text,
//         ),
//         titleLarge: TextStyle(
//           fontFamily: 'Poppins',
//           fontWeight: FontWeight.w800,
//           letterSpacing: .2,
//           color: c.text,
//         ),
//         titleMedium: TextStyle(
//           fontFamily: 'Poppins',
//           fontWeight: FontWeight.w800,
//           color: c.text,
//         ),
//         bodyMedium: TextStyle(
//           fontFamily: 'Poppins',
//           color: c.body,
//         ),
//         bodySmall: TextStyle(
//           fontFamily: 'Poppins',
//           color: c.muted,
//         ),
//       ),

//          elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: c.primary,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(r16),
//           ),
//           textStyle: const TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: c.primary,
//           side: BorderSide(color: c.primary.withOpacity(.25)),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(r16),
//           ),
//           textStyle: const TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: c.surface,
//         hintStyle: TextStyle(color: c.muted),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(r16),
//           borderSide: BorderSide(color: c.primary.withOpacity(.12)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(r16),
//           borderSide: BorderSide(color: c.primary.withOpacity(.10)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(r16),
//           borderSide: BorderSide(color: c.primary.withOpacity(.35), width: 1.2),
//         ),
//       ),
//     );
//   }
// }

// class _TaskoonColors {
//   const _TaskoonColors();

//   // ✅ same palette as yours
//   final Color primary = const Color(0xFF5C2E91);
//   final Color text = const Color(0xFF3E1E69);
//   final Color muted = const Color(0xFF75748A);
//   final Color bg = const Color(0xFFF8F7FB);
//   final Color gold = const Color(0xFFF4C847);

//   // ✅ modern extras (safe defaults)
//   final Color surface = Colors.white;
//   final Color body = const Color(0xFF374151);
// }

// /* ============================ APP ROOT (MODERN) ============================ */

// class TaskoonApp extends StatelessWidget {
//   const TaskoonApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Taskoon',
//       debugShowCheckedModeBanner: false,
//       theme: TaskoonTheme.light(),
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

// /* ============================ BOTTOM NAV (MORE MODERN) ============================ */

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
//     final c = TaskoonTheme.colors;

//     return SafeArea(
//       top: false,
//       minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(TaskoonTheme.r24),
//           boxShadow: TaskoonTheme.softShadow(.14),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(TaskoonTheme.r24),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//             child: Container(
//               height: 82,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     c.primary.withOpacity(.92),
//                     c.primary.withOpacity(.78),
//                   ],
//                 ),
//                 border: Border.all(color: Colors.white.withOpacity(.16)),
//               ),
//               child: Row(
//                 children: [
//                   for (int i = 0; i < items.length; i++)
//                     _NavItemTile(
//                       item: items[i],
//                       selected: i == currentIndex,
//                       onTap: () => onTap(i),
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
//   });

//   final BottomItem item;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final c = TaskoonTheme.colors;

//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         splashColor: Colors.white24,
//         highlightColor: Colors.transparent,
//         child: Center(
//           child: AnimatedContainer(
//             duration: TaskoonTheme.med,
//             curve: Curves.easeOutCubic,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               color: selected ? Colors.white.withOpacity(.14) : Colors.transparent,
//               borderRadius: BorderRadius.circular(TaskoonTheme.r16),
//               border: selected ? Border.all(color: Colors.white.withOpacity(.22)) : null,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   item.icon,
//                   color: selected ? Colors.white : Colors.white.withOpacity(.82),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   item.label,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: selected ? Colors.white : Colors.white.withOpacity(.82),
//                     fontWeight: FontWeight.w700,
//                   fontSize: 11.2,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 AnimatedContainer(
//                   duration: TaskoonTheme.fast,
//                   height: 3,
//                   width: selected ? 22 : 8,
//                   decoration: BoxDecoration(
//                     color: selected ? c.gold : Colors.white.withOpacity(.22),
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
