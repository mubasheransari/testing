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
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBg = Color(0xFFF8F7FB);

  String? selected;
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
    final disabled = selected == null;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimary.withOpacity(.18),
                    kPrimary.withOpacity(.08),
                    Colors.white,
                  ],
                ),
                border: Border.all(color: kPrimary.withOpacity(.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimary.withOpacity(.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/taskoon_logo.png',
                      height: 62,
                      width: 62,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'How do you want to use Taskoon?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: kTextDark,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick one to personalize your experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ✅ Role cards (same logic)
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

            // ✅ Validation hint (same behavior, themed)
            if (triedContinue && selected == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDA4AF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Color(0xFFE11D48)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select an option to continue',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ✅ Continue button (modern pill)
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: disabled ? const Color(0xFFECEFF3) : kPrimary,
                  foregroundColor: disabled ? Colors.black54 : Colors.white,
                  elevation: disabled ? 0 : 10,
                  shadowColor: kPrimary.withOpacity(.28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  if (selected == null) {
                    setState(() => triedContinue = true);
                    return;
                  }

                  // ✅ unchanged navigation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAccountScreen(role: selected!),
                    ),
                  );
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Tiny helper text (optional UI only)
            const Text(
              'You can change this later from settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                color: kMuted,
                fontWeight: FontWeight.w600,
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

  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);

  @override
  Widget build(BuildContext context) {
    final border = selected ? kPrimary.withOpacity(.35) : kPrimary.withOpacity(.12);
    final bg = Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title option',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: kPrimary.withOpacity(.06),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: selected ? 1.8 : 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? .06 : .04),
                blurRadius: selected ? 18 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // ✅ Icon tile (theme)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimary.withOpacity(.22),
                      kPrimary.withOpacity(.10),
                    ],
                  ),
                  border: Border.all(color: kPrimary.withOpacity(.16)),
                ),
                child: Icon(icon, color: kPrimary, size: 22),
              ),

              const SizedBox(width: 12),

              // ✅ Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: kTextDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: kMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutBack,
                child: selected
                    ? Container(
                        key: const ValueKey('selected'),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kPrimary.withOpacity(.18)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: kPrimary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Selected',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: const ValueKey('not_selected'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary.withOpacity(.06),
                          border: Border.all(color: kPrimary.withOpacity(.14)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
