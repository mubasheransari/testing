import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/emergency_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/guidlines_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/my_account_screen.dart';
import 'package:taskoon/widgets/logout_popup.dart';



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
            // _MoreHeader(title: 'More'),

                               Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeaderCard(
                title: 'More',
                left:    Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: _AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: _AppColors.primary),
            ),
                             right: _HeaderPill(
  label: 'Sign out',
  icon: Icons.logout_rounded,
  onTap: () => GlobalSignOut.show(context),
),
              ),
            ),

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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.left,
    required this.right,
  });

  final String title;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
          left,
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF3E1E69),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          right,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}


class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
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
    final bg = filled ? _AppColors.primary : _AppColors.primary.withOpacity(.08);
    final fg = filled ? Colors.white : _AppColors.primary;

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


class _AppColors {
  static const primary = Color(0xFF5C2E91);
}

