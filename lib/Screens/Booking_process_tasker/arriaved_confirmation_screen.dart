import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskoon/Constants/constants.dart';

class ArrivalConfirmGlassScreen extends StatefulWidget {
  const ArrivalConfirmGlassScreen({super.key});

  @override
  State<ArrivalConfirmGlassScreen> createState() => _ArrivalConfirmGlassScreenState();
}

class _ArrivalConfirmGlassScreenState extends State<ArrivalConfirmGlassScreen> {
  bool arrived = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // NO purple page color — abstract gradient instead
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient + soft blobs (for nice glass refraction)
          const _BackgroundCanvas(),

          // Full-screen frosted sheet (glassmorphism)
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.white.withOpacity(0.08), // translucent frosted film
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: _GlassCard(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title & subtitle
                            Text(
                              'Please confirm\nyour arrival',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                fontSize: size.width < 360 ? 22 : 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You're scheduled to begin shortly",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: size.width < 360 ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Image.asset('assets/arrived_avatar.png',height: 99,width: 199,),

                            // Illustration placeholder (swap with your asset if you want)
                          /*  Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.40),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withOpacity(.45)),
                              ),
                              alignment: Alignment.center,
                              child:  Image.asset('assets/arrived_avatar.png',height: 140,width: 149,)
                              
                              //const Icon(Icons.engineering_rounded, size: 56, color: Color(0xFF1F2937)),
                            ),*/

                            const SizedBox(height: 24),

                            Text(
                              'Task details',
                              style: TextStyle(
                                color: const Color(0xFF1F2937),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),

                            const _DetailRow(label: 'User', value: 'Stephan M James'),
                            const SizedBox(height: 8),
                            const _DetailRow(label: 'Service', value: 'Furniture assembly'),
                            const SizedBox(height: 8),
                            const _DetailRow(label: 'Time', value: 'Apr 24   10:30'),
                            const SizedBox(height: 8),
                            const _DetailRow(label: 'Location', value: 'East Perth'),

                            const SizedBox(height: 18),

                            // Swipe to confirm
                            SwipeToConfirm(
                              label: '\t\t\t\t\t\t\t\t\t\tI Have Arrived',
                              onConfirmed: () async {
                                HapticFeedback.lightImpact();
                                setState(() => arrived = true);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text('Client notified: You have arrived.'),
                                    ),
                                  );
                                }
                              },
                              trackColor: arrived == true ? Constants.primaryDark : Color(0xFF2E7D32), // dark green
                              trackBackground:  Colors.red,
                              knobColor: Colors.white,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              height: 56,
                              radius: 28,
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              'Swipe to notify the client',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Building Blocks ---------------------------- */

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.58),
                Colors.white.withOpacity(0.28),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BackgroundCanvas extends StatelessWidget {
  const _BackgroundCanvas();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Neutral abstract gradient (no purple)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-.8, -.9),
              end: Alignment(.8, .9),
              colors: [Color(0xFF0F172A), Color(0xFF1F2937)], // indigo/gray
            ),
          ),
        ),
        // Soft colorful blobs for depth (looks great under glass)
        const _Blob(color: Color(0xFF60A5FA), size: 280, offset: Offset(-80, -60), opacity: .25),
        const _Blob(color: Color(0xFFF472B6), size: 260, offset: Offset(220, 140), opacity: .23),
        const _Blob(color: Color(0xFF34D399), size: 240, offset: Offset(-40, 420), opacity: .22),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, required this.offset, this.opacity = .22});
  final Color color;
  final double size;
  final Offset offset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(color: color.withOpacity(opacity * .8), blurRadius: 120, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF374151),
              fontSize: 16,
              height: 1.35,
            ),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

/* ---------------------------- Swipe to Confirm ---------------------------- */

class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.height = 56,
    this.radius = 26,
    this.trackColor = const Color(0xFF2E7D32),
    this.trackBackground = const Color(0xFF4CAF50),
    this.knobColor = Colors.white,
    this.textStyle,
    this.knobIcon = const Icon(Icons.arrow_forward_rounded, size: 20),
    this.confirmThreshold = 0.75,
  });

  final String label;
  final VoidCallback onConfirmed;
  final double height;
  final double radius;
  final Color trackColor;
  final Color trackBackground;
  final Color knobColor;
  final TextStyle? textStyle;
  final Widget knobIcon;
  final double confirmThreshold;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _p = 0.0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final tween = Tween(begin: _p, end: target);
    _controller
      ..reset()
      ..addListener(() {
        setState(() {
          _p = tween.evaluate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        });
      })
      ..forward();
  }

  void _handleEnd(BoxConstraints c) {
    if (_p >= widget.confirmThreshold) {
      _confirmed = true;
      _animateTo(1.0);
      HapticFeedback.selectionClick();
      widget.onConfirmed();
    } else {
      _animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final h = widget.height;
        final knobSize = h - 8;
        const pad = 4.0;
        final travel = (w - pad * 2 - knobSize);
        final left = pad + travel * _p;

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            setState(() {
              _p = (_p + d.delta.dx / travel).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) => _handleEnd(c),
          onHorizontalDragCancel: () => _handleEnd(c),
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: widget.trackColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: Colors.white.withOpacity(.18)),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Growing background glow
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: widget.trackBackground.withOpacity(.12 + .20 * _p),
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                  ),
                ),
                // Label
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: knobSize + 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: widget.textStyle ??
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                // Knob
                Positioned(
                  left: left,
                  top: pad,
                  bottom: pad,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: knobSize,
                    decoration: BoxDecoration(
                      color: widget.knobColor,
                      borderRadius: BorderRadius.circular(widget.radius),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: _confirmed
                          ? const Icon(Icons.check_rounded, color: Color(0xFF2E7D32))
                          : widget.knobIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
