import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'create_account_screen.dart';
import 'package:flutter/services.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  // Brand palette
  static const Color purple = Color(0xFF7841BA);
  static const Color purpleAlt = Color(0xFF8B59C6);
  static const Color gold = Color(0xFFD4AF37);
  static const Color lilac = Color(0xFFF3ECFF);
  static const Color border = Color(0xFFE3DAFF);

  String? selected; // 'user' | 'tasker' | 'business'
  bool triedContinue = false;

  void _pick(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      selected = value;
      if (triedContinue) triedContinue = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final disabled = selected == null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Center(
              child: Image.asset(
                'assets/taskoon_logo.png',
                height: 95,
                width: 95,
              ),
            ),
            // Logo + tiny gold ring
            /* Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: gold, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Image.asset('assets/taskoon_logo.png',
                    height: 64, width: 64),
              ),
            ),*/
            const SizedBox(height: 16),

            // Title & helper
            Text(
              'How do you want to use Taskoon?',
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick one to personalize your experience.',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 22),

            // Cards
            _RoleCard(
              icon: CupertinoIcons.person,
              title: 'User',
              subtitle: 'Get tasks done, hassle-free',
              selected: selected == 'user',
              onTap: () => _pick('user'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: CupertinoIcons.money_dollar_circle,
              title: 'Tasker',
              subtitle: 'Get paid to help others',
              selected: selected == 'tasker',
              onTap: () => _pick('tasker'),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: CupertinoIcons.briefcase,
              title: 'Business',
              subtitle: 'Build your dream team, instantly',
              selected: selected == 'business',
              onTap: () => _pick('business'),
            ),

            // Validation hint
            if (triedContinue && selected == null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Color(0xFFE11D48)),
                  SizedBox(width: 6),
                  Text(
                    'Select an option to continue',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // Continue
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: disabled ? const Color(0xFFECEFF3) : purple,
                  foregroundColor: disabled ? Colors.black54 : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: disabled ? 0 : 6,
                  shadowColor: purple.withOpacity(.35),
                ),
                onPressed: () {
                  if (selected == null) {
                    setState(() => triedContinue = true);
                    return;
                  }

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateAccountScreen(role: selected!)));
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const Color purple = Color(0xFF7841BA);
  static const Color purpleAlt = Color(0xFF8B59C6);
  static const Color lilac = Color(0xFFF3ECFF);
  static const Color border = Color(0xFFE3DAFF);
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? lilac : Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title option',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: purple.withOpacity(.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: selected ? 2 : 1.5,
              color: selected ? purple.withOpacity(.45) : border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: purple.withOpacity(.10),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              // Icon tile with gradient ring
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [purpleAlt, purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    Icon(icon, color: purple, size: 22),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: .2,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black.withOpacity(.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                child: selected
                    ? const Icon(CupertinoIcons.check_mark_circled_solid,
                        key: ValueKey('check'), color: purple, size: 24)
                    : const SizedBox(
                        key: ValueKey('empty'), width: 24, height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

