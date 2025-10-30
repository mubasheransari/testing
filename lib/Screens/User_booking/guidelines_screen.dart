import 'package:flutter/material.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  static const _primary = Color(0xFF5C2E91);
  static const _cardBorder = Color(0xFFE6E0F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const SizedBox(height: 8),
              const Text(
                'Guidelines',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 18),

              // Important banner
              const _ImportantBanner(),

              const SizedBox(height: 16),

              // Safety First
              _GuidelineCard(
                title: 'Safety First',
                icon: Icons.shield_outlined,
                iconColor: _primary,
                bullets: const [
                  'All service providers are background checked',
                  'Report any safety concerns immediately',
                  'Always verify provider identity',
                  'Keep communication within the app',
                ],
              ),

              const SizedBox(height: 14),

              // Booking Guidelines
              _GuidelineCard(
                title: 'Booking Guidelines',
                icon: Icons.schedule_outlined,
                iconColor: Color(0xFF2E7D32),
                bullets: const [
                  'Book services at least 2 hours in advance',
                  'Confirm appointment details with provider',
                  'Be present at the scheduled time',
                  'Cancel at least 1 hour before if needed',
                ],
              ),

              const SizedBox(height: 14),

              // Payment & Pricing
              _GuidelineCard(
                title: 'Payment & Pricing',
                icon: Icons.attach_money_rounded,
                iconColor: _primary,
                bullets: const [
                  'Prices shown are estimates',
                  'Final cost confirmed before service',
                  'Payment processed after completion',
                  'Tips are optional but appreciated',
                ],
              ),

              const SizedBox(height: 14),

              // Communication
              _GuidelineCard(
                title: 'Communication',
                icon: Icons.support_agent_rounded,
                iconColor: Color(0xFFE39E00),
                bullets: const [
                  'Provider will contact you within 30 minutes',
                  'Use in-app messaging for coordination',
                  'Keep personal information private',
                  'Be respectful in all interactions',
                ],
              ),

              const SizedBox(height: 24),
              // Bottom safe spacer (for curved nav bars / iPhone home bar)
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// ====================== WIDGETS ======================

class _ImportantBanner extends StatelessWidget {
  const _ImportantBanner();

  @override
  Widget build(BuildContext context) {
    const primary = GuidelinesScreen._primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D890), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          _IconBubble(
            icon: Icons.priority_high_rounded,
            bg: const Color(0xFFFFEEBD),
            fg: const Color(0xFFE39E00),
          ),
          const SizedBox(width: 12),
          // Texts
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please read these guidelines carefully to ensure a safe and smooth service experience.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bullets,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    const border = GuidelinesScreen._cardBorder;
    const primary = GuidelinesScreen._primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IconBubble(icon: icon, fg: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.2,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bullets
          for (final b in bullets) _Bullet(text: b),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    this.bg,
    this.fg,
  });

  final IconData icon;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFF2ECFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: fg ?? const Color(0xFF5C2E91)),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const bulletColor = Color(0xFF5C2E91);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _Dot(color: bulletColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.5,
                color: Colors.grey.shade900,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.color = Colors.black});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6.5,
      height: 6.5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}