import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:taskoon/Screens/User_booking/rateyourTasker.dart';


class ServiceProgressScreen extends StatefulWidget {
  const ServiceProgressScreen({super.key, required this.totalMinutes});

  final int totalMinutes;

  @override
  State<ServiceProgressScreen> createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  static const _purple = Color(0xFF4A2C73);
  static const _greyLine = Color(0xFFE7E7E7);
  static const _red = Color(0xFFE73C3C);

  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;

  /// 0 → “Service has begun!” (start)
  /// 1 → “Service in progress” (after ~33% consumed)
  /// 2 → “Looks like time’s almost up” (when <=20% left)
  int _stage = 0;

  bool _endDialogShown = false;
  bool _navigatedToRating = false; // ⬅️ prevent double navigation

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.totalMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      // ⬇️ time finished → navigate to rating screen
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _stage = 2;
        });
        _goToRating();
        return;
      }

      final next = _remainingSeconds - 1;
      final consumed = _totalSeconds - next;
      final consumedPerc = consumed / _totalSeconds;
      final remainingPerc = next / _totalSeconds;

      int newStage = _stage;
      if (consumedPerc >= 0.33 && _stage == 0) {
        newStage = 1;
      }
      if (remainingPerc <= 0.20) {
        newStage = 2;
      }

      setState(() {
        _remainingSeconds = next;
        _stage = newStage;
      });

      // when 20% left -> show dialog once
      if (remainingPerc <= 0.20 && !_endDialogShown) {
        _endDialogShown = true;
        _showExtendDialog();
      }
    });
  }

  // ⬇️ Centralized navigation
  void _goToRating() {
    if (_navigatedToRating || !mounted) return;
    _navigatedToRating = true;

    // small delay so 00:00 can render before transition (looks nicer)
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RateTaskerScreen(
            taskerName: 'Stephan Micheal', // pass real data if you have it
            jobCode: 'AU737',
          ),
        ),
      );
    });
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showExtendDialog() async {
    final added = await showGeneralDialog<int?>(
      context: context,
      useRootNavigator: true,
      barrierLabel: 'Extend time',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.15),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        final width = MediaQuery.of(context).size.width * 0.82;
        return Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox.expand(),
            ),
            Center(
              child: _ExtendTimeCard(
                width: width,
                onSelect: (minutes) =>
                    Navigator.of(context, rootNavigator: true).pop(minutes),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .05),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
    );

    // if user picked extra time
    if (added != null && added > 0 && mounted) {
      setState(() {
        final extra = added * 60;
        _totalSeconds += extra;
        _remainingSeconds += extra;
        _endDialogShown = false; // allow dialog again for new window
        _stage = 1; // back to in-progress
      });
      // restart the timer if it was cancelled right at boundary
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // stage-based texts & images
    String title;
    String asset;
    List<int> steps;
    Color timeColor = _purple;

    switch (_stage) {
      case 0:
        title = 'Service has begun!';
        asset = 'assets/service_begin_1.png'; // replace with real
        steps = [1, 0, 0];
        break;
      case 1:
        title = 'Service in progress';
        asset = 'assets/service_inprogress.png';
        steps = [1, 1, 0];
        break;
      default:
        title = "Looks like time's almost up";
        asset = 'assets/service_done.png';
        steps = [1, 1, 1];
        timeColor = _red;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 22, left: 18, right: 18, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 160,
                child: Center(
                  child: Image.asset(
                    asset,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _StepDots(activeColor: _purple, data: steps),
              const SizedBox(height: 24),
              const Text(
                'Remaining time of service',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _fmt(_remainingSeconds),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  color: timeColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 28),
              _InfoRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat',
                subtitle: 'Chat with your tasker',
              ),
              const SizedBox(height: 12),
              Container(height: 1, width: double.infinity, color: _greyLine),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.person_outline,
                title: 'Tasker details',
                subtitle: 'Micheal Stance\nPro, cleaner • 3.1 mi • (4.8)',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEDEFF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // cancel booking logic
                  },
                  child: const Text(
                    'CANCEL BOOKING',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
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

/* --------------------------------------------------------- */
/*                       small widgets                       */
/* --------------------------------------------------------- */

class _StepDots extends StatelessWidget {
  const _StepDots({required this.data, required this.activeColor});

  final List<int> data; // e.g. [1,0,0]
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((e) {
        final bool isOn = e == 1;
        return Container(
          width: 38,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isOn ? activeColor : const Color(0xFFD5D5D5),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }).toList(),
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
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4A2C73), width: 1.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4A2C73)),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A2C73),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF5F6673),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB7BBC3)),
      ],
    );
  }
}

/* --------------------------------------------------------- */
/*                    extend-time dialog                      */
/* --------------------------------------------------------- */

class _ExtendTimeCard extends StatelessWidget {
  const _ExtendTimeCard({
    required this.width,
    required this.onSelect,
  });

  final double width;
  final void Function(int minutes) onSelect;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    const red = Color(0xFFE73C3C);
    const lilac = Color(0xFFF1E6FF);

    Widget pill(String text, int mins) {
      return GestureDetector(
        onTap: () => onSelect(mins),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: lilac,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
            
              fontWeight: FontWeight.w600,
              color: purple,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Service time is about to end!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: red,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Still working? Add extra time',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                color: purple,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                pill('15 mins', 15),
                pill('30 mins', 30),
                pill('1 hour', 60),
                pill('2 hours', 120),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text(
                      'NO THANK YOU',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                        fontSize: 12
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => onSelect(30),
                    child: const Text(
                      'YES PLEASE',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                           fontSize: 12
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

