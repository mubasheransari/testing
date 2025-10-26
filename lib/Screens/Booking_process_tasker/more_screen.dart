// lib/screens/more_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/emergency_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/my_account_screen.dart';

/// Modern, attractive “More” screen (matches your palette & rounded style).
/// No external packages required.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _p = _AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _p),
                  //   onPressed: () => Navigator.of(context).maybePop(),
                  // ),
                  const SizedBox(width: 6),
                  const Text(
                    'More',
                    style: TextStyle(
                      color: _p,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _MoreTile(
                  icon: Icons.person_rounded,
                  label: 'My account',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> MyAccountScreen()));
                  },
                ),
                const SizedBox(height: 14),
                _MoreTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Guidelines',
                  onTap: () {/* TODO: open guidelines */},
                ),
                const SizedBox(height: 14),
                _MoreTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Emergency',
                  onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=> EmergencyScreen()));

                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   TILE                                     */
/* -------------------------------------------------------------------------- */

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9E5F2)),
          ),
          child: InkWell(
            onTap: onTap,
            highlightColor: const Color(0xFF5C2E91).withOpacity(.06),
            splashColor: const Color(0xFF5C2E91).withOpacity(.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _LeadingIcon(icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TrailingArrow(onTap: onTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withOpacity(.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _TrailingArrow extends StatelessWidget {
  const _TrailingArrow({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E5F2)),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_forward_rounded,
            color: _AppColors.primary, size: 20),
        splashRadius: 18,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                    THEME                                   */
/* -------------------------------------------------------------------------- */

class _AppColors {
  static const primary = Color(0xFF5C2E91);
}
