import 'dart:async';
import 'package:flutter/material.dart';

class ServiceInProgressScreen extends StatefulWidget {
  const ServiceInProgressScreen({
    super.key,
    this.serviceDuration = const Duration(minutes: 6), // demo: 6 mins
    this.taskerName = 'Micheal Stance',
    this.taskerRole = 'Pro, cleaner',
    this.distance = '3,1 mi',
    this.rating = 4.8,
  });

  /// set to Duration(hours: 1) in real app
  final Duration serviceDuration;
  final String taskerName;
  final String taskerRole;
  final String distance;
  final double rating;

  @override
  State<ServiceInProgressScreen> createState() =>
      _ServiceInProgressScreenState();
}

class _ServiceInProgressScreenState extends State<ServiceInProgressScreen> {
  late Duration _remaining;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _remaining = widget.serviceDuration;
    _startTimer();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double get _progress {
    final total = widget.serviceDuration.inSeconds;
    final left = _remaining.inSeconds;
    return 1 - (left / total);
  }

  /// 0 → first pill, 1 → second pill, 2 → third pill
  int get _currentStage {
    if (_progress < 0.33) return 0;
    if (_progress < 0.66) return 1;
    return 2;
  }

  bool get _isAfter33 => _progress >= 0.33;

  String get _timeText {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    const bg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // top spacing
            const SizedBox(height: 24),
            // title + hero
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey(_isAfter33),
                children: [
                  Text(
                    _isAfter33 ? 'Service in Progress' : 'Service has begun!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // illustration
                  Container(
                    width: 225,
                    height: 180,
                    decoration: const BoxDecoration(
                      // you can replace with Image.asset(...)
                      // to match your exact SVG / PNG
                    ),
                    child: _isAfter33
                        ? Image.asset(
                            'assets/service_in_progress.png',
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            'assets/service_has_begun.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 3-step indicator
            _ProgressPills(activeIndex: _currentStage),
            const SizedBox(height: 20),
            const Text(
              'Remaining time of service',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _timeText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: purple,
              ),
            ),
            const SizedBox(height: 26),
            // info list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _InfoRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat',
                    subtitle: 'Chat with your tasker',
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Tasker details',
                    subtitle:
                        '${widget.taskerName}\n${widget.taskerRole}\n${widget.distance}\n(${widget.rating})',
                  ),
                ],
              ),
            ),

            // bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // cancel booking
                  },
                  child: const Text(
                    'CANCEL BOOKING',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                      letterSpacing: .3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- small widgets ---------------- */

class _ProgressPills extends StatelessWidget {
  const _ProgressPills({required this.activeIndex});
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF4A2C73);
    const inactive = Color(0xFFD1D5DB);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill(activeIndex == 0 ? active : inactive),
        const SizedBox(width: 12),
        _pill(activeIndex == 1 ? active : inactive),
        const SizedBox(width: 12),
        _pill(activeIndex == 2 ? active : inactive),
      ],
    );
  }

  Widget _pill(Color c) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56,
      height: 7,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: purple, width: 1.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: purple, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: purple,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
