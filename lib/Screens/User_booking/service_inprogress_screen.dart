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
                    Navigator.of(_, rootNavigator: true).pop(minutes),
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



/*

/// Call like:
/// Navigator.push(
///  context,
///  MaterialPageRoute(
///    builder: (_) => const ServiceProgressScreen(
///      totalMinutes: 60, // 1 hour
///    ),
///  ),
/// );
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
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _stage = 2;
        });
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
                    Navigator.of(_, rootNavigator: true).pop(minutes),
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
                    begin: const Offset(0, .05), end: Offset.zero)
                .animate(anim),
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
        _endDialogShown = false; // allow again for new window
        _stage = 1; // go back to in-progress
      });
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
          padding:
              const EdgeInsets.only(top: 22, left: 18, right: 18, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // top spacing + title + illustration
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
              // Illustration
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
              // step indicator
              _StepDots(
                activeColor: _stage == 2 ? _purple : _purple,
                data: steps,
              ),
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
              // chat item
              _InfoRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat',
                subtitle: 'Chat with your tasker',
              ),
              const SizedBox(height: 12),
              // divider
              Container(
                height: 1,
                width: double.infinity,
                color: _greyLine,
              ),
              const SizedBox(height: 12),
              _InfoRow(
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
                        borderRadius: BorderRadius.circular(16)),
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
          child: Icon(icon, color: const Color(0xFF4A2C73)),
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


// class ServiceInProgressScreen extends StatefulWidget {
//   const ServiceInProgressScreen({
//     super.key,
//     this.serviceDuration = const Duration(minutes: 6), // demo: 6 mins
//     this.taskerName = 'Micheal Stance',
//     this.taskerRole = 'Pro, cleaner',
//     this.distance = '3,1 mi',
//     this.rating = 4.8,
//   });

//   /// set to Duration(hours: 1) in real app
//   final Duration serviceDuration;
//   final String taskerName;
//   final String taskerRole;
//   final String distance;
//   final double rating;

//   @override
//   State<ServiceInProgressScreen> createState() =>
//       _ServiceInProgressScreenState();
// }

// class _ServiceInProgressScreenState extends State<ServiceInProgressScreen> {
//   late Duration _remaining;
//   Timer? _ticker;

//   @override
//   void initState() {
//     super.initState();
//     _remaining = widget.serviceDuration;
//     _startTimer();
//   }

//   void _startTimer() {
//     _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) return;
//       setState(() {
//         if (_remaining.inSeconds > 0) {
//           _remaining = _remaining - const Duration(seconds: 1);
//         } else {
//           t.cancel();
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _ticker?.cancel();
//     super.dispose();
//   }

//   double get _progress {
//     final total = widget.serviceDuration.inSeconds;
//     final left = _remaining.inSeconds;
//     return 1 - (left / total);
//   }

//   /// 0 → first pill, 1 → second pill, 2 → third pill
//   int get _currentStage {
//     if (_progress < 0.33) return 0;
//     if (_progress < 0.66) return 1;
//     return 2;
//   }

//   bool get _isAfter33 => _progress >= 0.33;

//   String get _timeText {
//     final m = _remaining.inMinutes;
//     final s = _remaining.inSeconds % 60;
//     return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     const purple = Color(0xFF4A2C73);
//     const bg = Colors.white;

//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // top spacing
//             const SizedBox(height: 24),
//             // title + hero
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 350),
//               child: Column(
//                 key: ValueKey(_isAfter33),
//                 children: [
//                   Text(
//                     _isAfter33 ? 'Service in Progress' : 'Service has begun!',
//                     style: const TextStyle(
//                       fontFamily: 'Poppins',
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                       color: purple,
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   // illustration
//                   Container(
//                     width: 225,
//                     height: 180,
//                     decoration: const BoxDecoration(
//                       // you can replace with Image.asset(...)
//                       // to match your exact SVG / PNG
//                     ),
//                     child: _isAfter33
//                         ? Image.asset(
//                             'assets/service_in_progress.png',
//                             fit: BoxFit.contain,
//                           )
//                         : Image.asset(
//                             'assets/service_has_begun.png',
//                             fit: BoxFit.contain,
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             // 3-step indicator
//             _ProgressPills(activeIndex: _currentStage),
//             const SizedBox(height: 20),
//             const Text(
//               'Remaining time of service',
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 15,
//                 color: Color(0xFF4B5563),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               _timeText,
//               style: const TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 48,
//                 fontWeight: FontWeight.w600,
//                 color: purple,
//               ),
//             ),
//             const SizedBox(height: 26),
//             // info list
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 children: [
//                   _InfoRow(
//                     icon: Icons.chat_bubble_outline_rounded,
//                     title: 'Chat',
//                     subtitle: 'Chat with your tasker',
//                   ),
//                   const SizedBox(height: 12),
//                   const Divider(height: 1),
//                   const SizedBox(height: 12),
//                   _InfoRow(
//                     icon: Icons.person_outline_rounded,
//                     title: 'Tasker details',
//                     subtitle:
//                         '${widget.taskerName}\n${widget.taskerRole}\n${widget.distance}\n(${widget.rating})',
//                   ),
//                 ],
//               ),
//             ),

//             // bottom button
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: TextButton(
//                   style: TextButton.styleFrom(
//                     backgroundColor: const Color(0xFFE5E7EB),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   onPressed: () {
//                     // cancel booking
//                   },
//                   child: const Text(
//                     'CANCEL BOOKING',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       fontWeight: FontWeight.w500,
//                       color: Color(0xFF111827),
//                       letterSpacing: .3,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ---------------- small widgets ---------------- */

// class _ProgressPills extends StatelessWidget {
//   const _ProgressPills({required this.activeIndex});
//   final int activeIndex;

//   @override
//   Widget build(BuildContext context) {
//     const active = Color(0xFF4A2C73);
//     const inactive = Color(0xFFD1D5DB);
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _pill(activeIndex == 0 ? active : inactive),
//         const SizedBox(width: 12),
//         _pill(activeIndex == 1 ? active : inactive),
//         const SizedBox(width: 12),
//         _pill(activeIndex == 2 ? active : inactive),
//       ],
//     );
//   }

//   Widget _pill(Color c) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       width: 56,
//       height: 7,
//       decoration: BoxDecoration(
//         color: c,
//         borderRadius: BorderRadius.circular(999),
//       ),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   const _InfoRow({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;

//   @override
//   Widget build(BuildContext context) {
//     const purple = Color(0xFF4A2C73);
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 42,
//           height: 42,
//           decoration: BoxDecoration(
//             border: Border.all(color: purple, width: 1.4),
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Icon(icon, color: purple, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 14.5,
//                   fontWeight: FontWeight.w600,
//                   color: purple,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13,
//                   color: Color(0xFF4B5563),
//                   height: 1.35,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


*/