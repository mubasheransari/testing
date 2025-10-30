import 'package:flutter/material.dart';

class GuidelinesScreenn extends StatelessWidget {
  const GuidelinesScreenn({super.key});

  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kBorder = Color(0xFFE4E0EE);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  SizedBox(width: 14),
                  Text(
                    'Guidelines',
                    style: TextStyle(
                      color: kPurple,
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    _ImportantCard(),
                    SizedBox(height: 14),
                    _GuidelineCard(
                      icon: Icons.shield_outlined,
                      iconColor: kPurple,
                      title: 'Safety First',
                      bullets: [
                        'All service providers are background checked',
                        'Report any safety concerns immediately',
                        'Always verify provider identity',
                        'Keep communication within the app',
                      ],
                    ),
                    SizedBox(height: 14),
                    _GuidelineCard(
                      icon: Icons.watch_later_outlined,
                      iconColor: Color(0xFF3AA458),
                      title: 'Booking Guidelines',
                      bullets: [
                        'Book services at least 2 hours in advance',
                        'Confirm appointment details with provider',
                        'Be present at the scheduled time',
                        'Cancel at least 1 hour before if needed',
                      ],
                    ),
                    SizedBox(height: 14),
                    _GuidelineCard(
                      icon: Icons.attach_money_rounded,
                      iconColor: kPurple,
                      title: 'Payment & Pricing',
                      bullets: [
                        'Prices shown are estimates',
                        'Final cost confirmed before service',
                        'Payment processed after completion',
                        'Tips are optional but appreciated',
                      ],
                    ),
                    SizedBox(height: 14),
                    _GuidelineCard(
                      icon: Icons.call_rounded,
                      iconColor: Color(0xFFE39E00),
                      title: 'Communication',
                      bullets: [
                        'Provider will contact you within 30 minutes',
                        'Use in-app messaging for coordination',
                        'Keep personal information private',
                        'Be respectful in all interactions',
                      ],
                    ),
                    SizedBox(height: 80),
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

class _ImportantCard extends StatelessWidget {
  const _ImportantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6C77C), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
          ),
          Row(
            children: [
              _IconBadge(
                icon: Icons.warning_amber_rounded,
                bg: Color(0xFFFFE4A2),
                fg: Color(0xFFFFB52E),
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Important',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.5,
                  fontWeight: FontWeight.w700,
                  color: GuidelinesScreenn.kPurple,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please read these guidelines carefully to ensure a safe and smooth service experience.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.2,
                  height: 1.4,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.bullets,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GuidelinesScreenn.kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.015),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon, fg: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: GuidelinesScreenn.kPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in bullets) _BulletText(text: line),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
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
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Image.asset('assets/shield-exclamation.png'));
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: CircleAvatar(
              radius: 3.2,
              backgroundColor: GuidelinesScreenn.kPurple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.3,
                height: 1.3,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
