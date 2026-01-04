// lib/screens/more_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/emergency_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/guidlines_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/my_account_screen.dart';

/// Modern, attractive “More” screen (matches your palette & rounded style).
/// No external packages required.
// class MoreScreen extends StatelessWidget {
//   const MoreScreen({super.key});

//   static const _p = _AppColors.primary;

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(
//         children: [
//           // Header
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(22),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(.06),
//                     blurRadius: 18,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   // IconButton(
//                   //   icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _p),
//                   //   onPressed: () => Navigator.of(context).maybePop(),
//                   // ),
//                   const SizedBox(width: 6),
//                   const Text(
//                     'More',
//                     style: TextStyle(
//                       color: _p,
//                       fontSize: 26,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // List
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//               children: [
//                 _MoreTile(
//                   icon: Icons.person_rounded,
//                   label: 'My account',
//                   onTap: () {
//                     Navigator.push(context, MaterialPageRoute(builder: (context)=> MyAccountScreen()));
//                   },
//                 ),
//                 const SizedBox(height: 14),
//                 _MoreTile(
//                   icon: Icons.menu_book_rounded,
//                   label: 'Guidelines',
//                   onTap: () {
//                                         Navigator.push(context, MaterialPageRoute(builder: (context)=> GuidelinesScreen()));

//                   },
//                 ),
//                 const SizedBox(height: 14),
//                 _MoreTile(
//                   icon: Icons.notifications_active_rounded,
//                   label: 'Emergency',
//                   onTap: () {
//                                         Navigator.push(context, MaterialPageRoute(builder: (context)=> EmergencyScreen()));

//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                                   TILE                                     */
// /* -------------------------------------------------------------------------- */

// class _MoreTile extends StatelessWidget {
//   const _MoreTile({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Material(
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//             side: const BorderSide(color: Color(0xFFE9E5F2)),
//           ),
//           child: InkWell(
//             onTap: onTap,
//             highlightColor: const Color(0xFF5C2E91).withOpacity(.06),
//             splashColor: const Color(0xFF5C2E91).withOpacity(.12),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//               child: Row(
//                 children: [
//                   _LeadingIcon(icon: icon),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Text(
//                       label,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         color: _AppColors.primary,
//                         fontWeight: FontWeight.w800,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   _TrailingArrow(onTap: onTap),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LeadingIcon extends StatelessWidget {
//   const _LeadingIcon({required this.icon});
//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 56,
//       height: 56,
//       decoration: BoxDecoration(
//         color: _AppColors.primary,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: _AppColors.primary.withOpacity(.28),
//             blurRadius: 16,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Icon(icon, color: Colors.white, size: 28),
//     );
//   }
// }

// class _TrailingArrow extends StatelessWidget {
//   const _TrailingArrow({this.onTap});
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 36,
//       height: 36,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE9E5F2)),
//       ),
//       child: IconButton(
//         onPressed: onTap,
//         padding: EdgeInsets.zero,
//         icon: const Icon(Icons.arrow_forward_rounded,
//             color: _AppColors.primary, size: 20),
//         splashRadius: 18,
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                                    THEME                                   */
// /* -------------------------------------------------------------------------- */

// class _AppColors {
//   static const primary = Color(0xFF5C2E91);
// }
// ✅ Redesigned MoreScreen (matches your UserBookingHome + new Tasks theme)
// - Poppins everywhere
// - Same navigation functionality
// - Modern header card + clean list tiles (no overflow issues)
// - Keeps your _AppColors.primary

import 'dart:ui';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _p = _AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ✅ Header (same style as TasksScreen)
            const _MoreHeader(title: 'More'),

            const SizedBox(height: 12),

            // ✅ List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _SectionLabel('Account'),
                  const SizedBox(height: 10),
                  _MoreTileModern(
                    icon: Icons.person_rounded,
                    label: 'My account',
                    subtitle: 'Profile, preferences & security',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MyAccountScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _SectionLabel('Help'),
                  const SizedBox(height: 10),
                  _MoreTileModern(
                    icon: Icons.menu_book_rounded,
                    label: 'Guidelines',
                    subtitle: 'How to use the app safely',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GuidelinesScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _SectionLabel('Safety'),
                  const SizedBox(height: 10),
                  _MoreTileModern(
                    icon: Icons.notifications_active_rounded,
                    label: 'Emergency',
                    subtitle: 'Quick actions & contacts',
                    iconBg: const Color(0xFFFFECEC),
                    iconFg: const Color(0xFFC62828),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmergencyScreen()),
                      );
                    },
                  ),

              
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================ HEADER ============================ */

class _MoreHeader extends StatelessWidget {
  const _MoreHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AppColors.primary.withOpacity(.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: _AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: _AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF3E1E69),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================ SECTION LABEL ============================ */

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: Color(0xFF75748A),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/* ============================ TILE ============================ */

class _MoreTileModern extends StatelessWidget {
  const _MoreTileModern({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.iconBg,
    this.iconFg,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  final Color? iconBg;
  final Color? iconFg;

  @override
  Widget build(BuildContext context) {
    final bg = iconBg ?? _AppColors.primary.withOpacity(.12);
    final fg = iconFg ?? _AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: _AppColors.primary.withOpacity(.10),
        highlightColor: _AppColors.primary.withOpacity(.05),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AppColors.primary.withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.02),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // icon box
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

              // text
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
                        color: Color(0xFF3E1E69),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF75748A),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // arrow
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.primary.withOpacity(.12)),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: _AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================ THEME ============================ */

class _AppColors {
  static const primary = Color(0xFF5C2E91);
}

