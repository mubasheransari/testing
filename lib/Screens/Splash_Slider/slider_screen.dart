import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../Authentication/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const primary = Color(0xFF7841BA);
  static const bgLavender = Color(0xFFF3ECFF);
  static const midLavender = Color(0xFFDCCBFF);
  static const lightLavender = Color(0xFFE9DEFF);

  final controller = PageController();
  int index = 0;

  final slides = const [
    _SlideData(
      title: 'Trained Cleaners',
      subtitle:
          'Verified cleaning pros delivering\nspotless results you can trust',
      image: 'assets/trained_cleaners.png',
    ),
    _SlideData(
      title: 'Background Checked',
      subtitle:
          'Every tasker is identity verified\nand vetted for your peace of mind',
      image: 'assets/bg_check.png',
    ),
    _SlideData(
      title: 'On-time & Reliable',
      subtitle: 'Real-time updates and punctual\narrivals—every time',
      image: 'assets/ontimeupdates.png',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _next() {
    if (index < slides.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _skip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = index == slides.length - 1;

    return Scaffold(
      backgroundColor: bgLavender,
      body: SafeArea(
        child: Stack(
          children: [
            // Pages
            PageView.builder(
              controller: controller,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) => _OnboardPage(
                data: slides[i],
                primary: primary,
                light: lightLavender,
                mid: midLavender,
              ),
            ),

            // Skip
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Bottom: title, dots, CTA
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        slides[index].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                          decoration: TextDecoration.none,
                          decorationColor: primary,
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        slides[index].subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1F1F1F),
                          decoration: TextDecoration.none,
                          decorationColor: primary,
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),

                    // Pager dots (two gray dots + long purple dash active)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(slides.length, (i) {
                        final active = i == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: EdgeInsets.only(
                              right: i == slides.length - 1 ? 0 : 8),
                          height: 6,
                          width: active ? 36 : 8,
                          decoration: BoxDecoration(
                            color: active ? primary : Colors.black26,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: primary.withOpacity(.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                       Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.90,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 6,
                            shadowColor: primary.withOpacity(.35),
                          ),
                          onPressed: _next,
                          child: Center(
                            child: Text(
                            isLast ? 'Get Started' : 'Next',
                            textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // CTA Button
                /*    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                          shadowColor: primary.withOpacity(.35),
                        ),
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ),*/
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title, subtitle, image;
  const _SlideData(
      {required this.title, required this.subtitle, required this.image});
}

// class _OnbData {
//   final String title;
//   final String asset;
//   final bool underline;
//   const _OnbData({
//     required this.title,
//     required this.asset,
//     this.underline = false,
//   });
// }

class _OnboardPage extends StatelessWidget {
  final _SlideData data;
  final Color primary;
  final Color light;
  final Color mid;

  const _OnboardPage({
    required this.data,
    required this.primary,
    required this.light,
    required this.mid,
  });

  @override
  Widget build(BuildContext context) {
    // Stack with tilted rectangles + model image centered
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative tilted blocks (behind model) — now in purple tones
                  Positioned(
                    top: h * 0.16,
                    left: 36,
                    right: 36,
                    child: _TiltedBar(
                      width: c.maxWidth * .72,
                      height: 80,
                      color: mid,
                      angle: -0.18,
                    ),
                  ),
                  Positioned(
                    top: h * 0.24,
                    left: 56,
                    right: 56,
                    child: _TiltedBar(
                      width: c.maxWidth * .68,
                      height: 82,
                      color: primary.withOpacity(.92),
                      angle: -0.18,
                    ),
                  ),
                  Positioned(
                    top: h * 0.34,
                    left: 44,
                    right: 44,
                    child: _TiltedBar(
                      width: c.maxWidth * .70,
                      height: 84,
                      color: light,
                      angle: -0.18,
                    ),
                  ),

                  // Model image (transparent PNG)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 170, left: 10),
                      child: Center(
                        child: Image.asset(
                          height: 290,
                          data.image,
                          width: c.maxWidth * .52,
                          //fit: BoxFit.co,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 160), // reserved space for bottom overlay
          ],
        );
      },
    );
  }
}

class _TiltedBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double angle; // radians

  const _TiltedBar({
    required this.width,
    required this.height,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

