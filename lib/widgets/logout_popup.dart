import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Routes/routes.dart';



class GlobalSignOut {
  static Future<void> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _SignOutDialog(),
    );

    if (ok != true) return;

    final box = GetStorage();
    await box.erase();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login,
      (_) => false,
    );
  }
}

/* ===================== THEMED SIGNOUT DIALOG ===================== Testing@123 */

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  static const _p = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE9E5F2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _p.withOpacity(.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.logout_rounded, color: _p, size: 28),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Sign out?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _p,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  'You will be logged out and all local data will be cleared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: Colors.black.withOpacity(.60),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _DialogBtn(
                        label: 'Cancel',
                        filled: false,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogBtn(
                        label: 'Sign out',
                        filled: true,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  const _DialogBtn({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  static const _p = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: filled ? _p : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _p.withOpacity(.20)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                color: filled ? Colors.white : _p,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
