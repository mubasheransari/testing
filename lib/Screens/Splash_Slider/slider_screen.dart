import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../Login_Signup/login_screen.dart';

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

                    // CTA Button
                    SizedBox(
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
                    ),
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


/*class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});
  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _ctrl = PageController();
  int _pageIndex = 0;

  static const purple = Color(0xFF7841BA);
  static const gold = Color(0xFFD4AF37);

  final slides = const [
    _SlideData(
      title: 'Trained Cleaners',
      subtitle:
          'Verified cleaning pros delivering\nspotless results you can trust',
      image: 'assets/01_slider.png',
    ),
    _SlideData(
      title: 'Background Checked',
      subtitle:
          'Every tasker is identity verified\nand vetted for your peace of mind',
      image: 'assets/02_slider.png',
    ),
    _SlideData(
      title: 'On-time & Reliable',
      subtitle: 'Real-time updates and punctual\narrivals—every time',
      image: 'assets/03_slider.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _ctrl.page;
    if (p != null) {
      final i = p.round();
      if (i != _pageIndex && i >= 0 && i < slides.length) {
        setState(() => _pageIndex = i);
      }
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskoonLandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _pageIndex == slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient header + curved gold accent
          const _HeaderDecor(),
          SafeArea(
            child: Column(
              children: [
                // Top bar: logo left, Skip right
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      _BrandLockup(),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: slides.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) => _SlideCard(
                      data: slides[i],
                      pageController: _ctrl,
                      index: i,
                    ),
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                  ),
                ),
                const SizedBox(height: 8),
                _FancyDots(
                  controller: _ctrl,
                  count: slides.length,
                  activeColor: purple,
                  inactiveColor: Colors.black12,
                ),
                const SizedBox(height: 18),
                // Bottom CTA
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    20 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: purple.withOpacity(.35),
                      ),
                      onPressed: isLast
                          ? _finish
                          : () => _ctrl.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          fontSize: 18,
                        ),
                      ),
                    ),
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

/* --------------------------- Visual Components --------------------------- */

class _HeaderDecor extends StatelessWidget {
  const _HeaderDecor();

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7841BA);
    const gold = Color(0xFFD4AF37);
    return SizedBox.expand(
      child: CustomPaint(
        painter: _HeaderPainter(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B59C6), purple],
          ),
          gold: gold,
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  _HeaderPainter({required this.gradient, required this.gold});
  final LinearGradient gradient;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient backdrop on top half
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * .52);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        bottomLeft: const Radius.circular(48),
        bottomRight: const Radius.circular(48),
      ),
      paint,
    );

    // Gold accent curve
    final accent = Path()
      ..moveTo(0, size.height * .40)
      ..cubicTo(
        size.width * .25,
        size.height * .48,
        size.width * .55,
        size.height * .34,
        size.width,
        size.height * .44,
      )
      ..lineTo(size.width, size.height * .48)
      ..cubicTo(
        size.width * .55,
        size.height * .38,
        size.width * .25,
        size.height * .52,
        0,
        size.height * .44,
      )
      ..close();
    canvas.drawPath(accent, Paint()..color = gold.withOpacity(.12));
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter old) => false;
}

class _BrandLockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Circle crest with T
        // Container(
        //   width: 40,
        //   height: 40,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: const Color(0xFF7841BA),
        //     border: Border.all(color: const Color(0xFFD4AF37), width: 3),
        //     boxShadow: const [
        //       BoxShadow(
        //         color: Color(0x22000000),
        //         blurRadius: 12,
        //         offset: Offset(0, 4),
        //       )
        //     ],
        //   ),
        //   child: const Center(
        //     child: Text(
        //       'T',
        //       style: TextStyle(
        //         color: Colors.white,
        //         fontSize: 20,
        //         fontWeight: FontWeight.w800,
        //         fontStyle: FontStyle.italic,
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 10),
        Image.asset(
          "assets/taskoon_logo.png",
          height: 70,
          width: 68,
          fit: BoxFit.contain,
          semanticLabel: 'Taskoon',
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.data,
    required this.pageController,
    required this.index,
  });

  final _SlideData data;
  final PageController pageController;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (ctx, cns) {
        // Parallax factor
        double page = 0;
        if (pageController.hasClients &&
            pageController.position.haveDimensions) {
          page =
              (pageController.page ?? pageController.initialPage.toDouble()) -
                  index;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              // Illustration card with soft shadow & parallax
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(20, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Subtle background pattern
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF8F5FF), Colors.white],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      // Parallax image
                      Transform.translate(
                        offset: Offset(page * -16, page * 8),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              data.image,
                              fit: BoxFit.contain,
                              height: cns.maxHeight * .85,
                              semanticLabel: data.title,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 78.0),
                        child: Column(
                          children: [
                            Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                              ),
                            ),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: t.titleMedium?.copyWith(
                                color: Colors.black.withOpacity(.70),
                                height: 1.35,
                              ),
                            ),
                            SizedBox(
                              height: 70,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FancyDots extends StatefulWidget {
  const _FancyDots({
    required this.controller,
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
  });

  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<_FancyDots> createState() => _FancyDotsState();
}

class _FancyDotsState extends State<_FancyDots> {
  double _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  void _listen() => setState(() => _page = widget.controller.page ?? 0);

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(widget.count, (i) {
        final delta = (i - _page).abs();
        final active = delta < 0.5;
        final width = active ? 26.0 : 10.0;
        final height = 10.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: active ? widget.activeColor : widget.inactiveColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: widget.activeColor.withOpacity(.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/* ------------------------------ Data Model ------------------------------ */

class _SlideData {
  final String title, subtitle, image;
  const _SlideData(
      {required this.title, required this.subtitle, required this.image});
}*/


// class OnboardingCarousel extends StatefulWidget {
//   const OnboardingCarousel({super.key});
//   @override
//   State<OnboardingCarousel> createState() => _OnboardingCarouselState();
// }

// class _OnboardingCarouselState extends State<OnboardingCarousel> {
//   final _ctrl = PageController();

//   static const purple = Color(0xFF7841BA);
//   static const gold = Color(0xFFD4AF37);

//   final slides = const [
//     _SlideData(
//       title: 'Trained Cleaners',
//       subtitle:
//           'Verified cleaning pros delivering\nspotless results you can trust',
//       image: 'assets/01_slider.png',
//     ),
//     _SlideData(
//       title: 'Background Checked',
//       subtitle:
//           'Every tasker is identity verified\nand vetted for your peace of mind',
//       image: 'assets/02_slider.png',
//     ),
//     _SlideData(
//       title: 'On-time & Reliable',
//       subtitle: 'Real-time updates and punctual\narrivals—every time',
//       image: 'assets/03_slider.png',
//     ),
//   ];
//   int _pageIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     final dots = ValueNotifier(0);
//     _ctrl.addListener(() => dots.value = _ctrl.page?.round() ?? 0);

//     return Scaffold(
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: AnimatedSwitcher(
//           duration: const Duration(milliseconds: 220),
//           child: (_pageIndex == slides.length - 1)
//               ? Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                   child: SizedBox(
//                     height: 56,
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: purple,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => TaskoonLandingScreen()));
//                         // Navigator.pushReplacementNamed(
//                         //     context, '/personal-info');
//                       },
//                       child: const Text('Continue',
//                           style: TextStyle(
//                               fontWeight: FontWeight.w400,
//                               letterSpacing: 0.1,
//                               fontSize: 18)),
//                     ),
//                   ),
//                 )
//               : const SizedBox.shrink(),
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 152),
//             Image.asset(
//               "assets/taskoon_logo.png",
//               height: 130,
//               width: 130,
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: PageView.builder(
//                 onPageChanged: (i) => setState(() => _pageIndex = i),
//                 controller: _ctrl,
//                 itemCount: slides.length,
//                 itemBuilder: (_, i) => _Slide(slides[i]),
//               ),
//             ),
//             const SizedBox(height: 8),
//             _Dots(controller: _ctrl, count: slides.length, activeColor: purple),
//             const SizedBox(height: 18),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Slide extends StatelessWidget {
//   _Slide(this.data);
//   final _SlideData data;

//   static const Color purple = Color(0xFF7841BA);

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return LayoutBuilder(builder: (ctx, cns) {
//       final arcHeight = cns.maxHeight * 0.28; // band box height
//       return Stack(
//         children: [
//           // Title + subtitle
//           Align(
//             alignment: Alignment.topCenter,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 28.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 12),
//                   Text(
//                     data.title,
//                     textAlign: TextAlign.center,
//                     style: t.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: 0.2,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     data.subtitle,
//                     textAlign: TextAlign.center,
//                     style: t.titleMedium?.copyWith(
//                         color: Colors.black.withOpacity(.70), height: 1.35),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Curved band + two images riding the curve
//           Padding(
//             padding: const EdgeInsets.only(top: 60.0),
//             child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Image.asset(data.image)
//                 /*   SizedBox(
//                 width: cns.maxWidth,
//                 height: arcHeight,
//                 child: _ArcBandWithItems(
//                   bandColor: purple,
//                   stroke: 18,
//                   // Where along the curve to place each image (0..1)
//                   leftT: 0.18,
//                   rightT: 0.82,

//                   left: Image.asset(data.leftAsset, height: arcHeight * 0.55),
//                   right: Image.asset(data.rightAsset, height: arcHeight * 0.70),
//                 ),
//               ),*/
//                 ),
//           ),
//         ],
//       );
//     });
//   }
// }

// class _SlideData {
//   final String title, subtitle, image;
//   const _SlideData(
//       {required this.title, required this.subtitle, required this.image
//       // required this.leftAsset,
//       // required this.rightAsset,
//       });
// }

// class _CrestLogo extends StatelessWidget {
//   const _CrestLogo();

//   static const purple = Color(0xFF7841BA);
//   static const gold = Color(0xFFD4AF37);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 64,
//       height: 64,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: purple,
//         border: Border.all(color: gold, width: 5),
//         boxShadow: const [
//           BoxShadow(
//               color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))
//         ],
//       ),
//       child: const Center(
//         child: Text(
//           'T',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 34,
//             fontWeight: FontWeight.w800,
//             fontStyle: FontStyle.italic,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------- Arc band and positioned items ----------

// class _ArcBandWithItems extends StatelessWidget {
//   const _ArcBandWithItems({
//     required this.bandColor,
//     required this.stroke,
//     required this.leftT,
//     required this.rightT,
//     required this.left,
//     required this.right,
//   });

//   final Color bandColor;
//   final double stroke;
//   final double leftT, rightT; // normalized positions on the curve
//   final Widget left, right;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(builder: (ctx, cns) {
//       final size = Size(cns.maxWidth, cns.maxHeight);
//       final qp = _QuadraticPath(size);

//       // Points ON the curve (so assets sit on the band)
//       final pL = qp.pointAt(leftT);
//       final pR = qp.pointAt(rightT);

//       return Stack(
//         clipBehavior: Clip.none,
//         children: [
//           CustomPaint(
//               size: size,
//               painter: _ArcBandPainter(color: bandColor, stroke: stroke)),
//           // Left image (slight rotation)
//           Positioned(
//             left: pL.dx - (size.height * .25) / 2,
//             top: pL.dy - (size.height * .25) / 2 - 8,
//             child: Transform.rotate(angle: -8 * math.pi / 180, child: left),
//           ),
//           // Right image
//           Positioned(
//             left: pR.dx - (size.height * .32) / 2,
//             top: pR.dy - (size.height * .32) / 2 - 6,
//             child: Transform.rotate(angle: 6 * math.pi / 180, child: right),
//           ),
//         ],
//       );
//     });
//   }
// }

// class _ArcBandPainter extends CustomPainter {
//   _ArcBandPainter({required this.color, required this.stroke});
//   final Color color;
//   final double stroke;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final path = _QuadraticPath(size).path;

//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = stroke
//       ..strokeCap = StrokeCap.round;

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _ArcBandPainter old) =>
//       old.color != color || old.stroke != stroke;
// }

// // Helper to build a big quadratic curve like the mock
// class _QuadraticPath {
//   _QuadraticPath(this.size) {
//     final w = size.width;
//     final h = size.height;

//     // Start/end offscreen for that wide swoop
//     start = Offset(-w * 0.15, h * 0.45);
//     end = Offset(w * 1.15, h * 0.45);
//     // Control point pulls the curve downward
//     ctrl = Offset(w * 0.50, h * 0.90);

//     final p = Path()
//       ..moveTo(start.dx, start.dy)
//       ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
//     path = p;
//   }

//   final Size size;
//   late final Offset start, ctrl, end;
//   late final Path path;

//   /// Point on the quadratic curve (t in [0,1])
//   Offset pointAt(double t) {
//     final x = math.pow(1 - t, 2) * start.dx +
//         2 * (1 - t) * t * ctrl.dx +
//         math.pow(t, 2) * end.dx;
//     final y = math.pow(1 - t, 2) * start.dy +
//         2 * (1 - t) * t * ctrl.dy +
//         math.pow(t, 2) * end.dy;
//     return Offset(x.toDouble(), y.toDouble());
//   }
// }

// // ---------- Simple dots ----------

// class _Dots extends StatefulWidget {
//   const _Dots(
//       {required this.controller,
//       required this.count,
//       required this.activeColor});
//   final PageController controller;
//   final int count;
//   final Color activeColor;

//   @override
//   State<_Dots> createState() => _DotsState();
// }

// class _DotsState extends State<_Dots> {
//   double _page = 0;
//   @override
//   void initState() {
//     super.initState();
//     widget.controller.addListener(() {
//       setState(() => _page = widget.controller.page ?? 0);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(widget.count, (i) {
//         final active = (i - _page).abs() < 0.5;
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 220),
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           width: active ? 22 : 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: active ? widget.activeColor : Colors.black12,
//             borderRadius: BorderRadius.circular(999),
//           ),
//         );
//       }),
//     );
//   }
// }
