// lib/screens/my_account_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({
    super.key,
    this.onBack,
    this.onSignOut,
    this.onEditPersonal,
    this.onEditBank,
    this.bottomBar, // pass your global bottom nav here if needed
  });

  final VoidCallback? onBack;
  final VoidCallback? onSignOut;
  final VoidCallback? onEditPersonal;
  final VoidCallback? onEditBank;
  final Widget? bottomBar;

  static const _p = _AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    //       color: _p),
                    //   onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    // ),
                    const SizedBox(width: 6),
                    const Text(
                      'My account',
                      style: TextStyle(
                        color: _p,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _SignOutPill(onTap: onSignOut),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 76,
                        backgroundColor: const Color(0xFFDADADA),
                        child: Icon(Icons.person_rounded,
                            size: 82, color: Colors.white.withOpacity(.95)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Profile title
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: _p,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // PERSONAL
                    const _SectionLabel('Personal information'),
                    const SizedBox(height: 8),
                    const _InfoRow(label: 'Full name:', value: 'Steaphan Micheal'),
                    const SizedBox(height: 14),
                    const _InfoRow(
                        label: 'Date of birth:', value: '22 January, 1998'),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Address:',
                      value: '41 block, e-street',
                      trailing: _EditButton(onTap: onEditPersonal),
                    ),

                    const SizedBox(height: 28),

                    // BANK
                    const _SectionLabel('Bank details'),
                    const SizedBox(height: 8),
                    const _InfoRow(label: 'Bank name:', value: 'ABC bank'),
                    const SizedBox(height: 14),
                    const _InfoRow(
                        label: 'Account No.:', value: '**** **** 4565'),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'BSB code:',
                      value: '457',
                      trailing: _EditButton(onTap: onEditBank),
                    ),

                    const SizedBox(height: 28),

                    // ABN
                    const _SectionLabel('ABN/ Business information'),
                    const SizedBox(height: 8),
                    const _InfoRow(label: 'ABN No:', value: '36 123 456 789'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Header pill ----------------------------- */

class _SignOutPill extends StatelessWidget {
  const _SignOutPill({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: const Color(0xFFF2F2F7),
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                'Sign out',
                style: TextStyle(
                  color: Color(0xFF5E6272),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------- Sections -------------------------------- */

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.black.withOpacity(.62),
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
    );
    const valueStyle = TextStyle(
      color: Color(0xFF28303D),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: '$label ', style: labelStyle),
                TextSpan(text: value, style: valueStyle),
              ],
            ),
          ),
        ),
        if (trailing != null) const SizedBox(width: 8),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE9E5F2)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(Icons.edit_rounded,
              size: 20, color: _AppColors.primary),
        ),
      ),
    );
  }
}

/* --------------------------------- THEME -------------------------------- */

class _AppColors {
  static const primary = Color(0xFF5C2E91);
}
