import 'dart:async';
import 'package:flutter/material.dart';

class GreetingText extends StatefulWidget {
  GreetingText({
    super.key,
    this.name,
  });

  final String? name;

  @override
  State<GreetingText> createState() => _GreetingTextState();
}

class _GreetingTextState extends State<GreetingText> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Good night";
  }

  IconData _timeIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_rounded; // morning
    if (hour >= 12 && hour < 17) return Icons.light_mode_rounded; // afternoon
    if (hour >= 17 && hour < 21) return Icons.nights_stay_rounded; // evening
    return Icons.bedtime_rounded; // night
  }

  Color _timeIconColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return const Color(0xFFF4C847); // yellow
    if (hour >= 12 && hour < 17) return const Color(0xFFEE8A41); // orange
    if (hour >= 17 && hour < 21) return const Color(0xFF7841BA); // purple
    return const Color(0xFF5C2E91); // dark purple
  }

  @override
  Widget build(BuildContext context) {
    final g = _greeting();
    final hasName = widget.name != null && widget.name!.trim().isNotEmpty;

    final line1 = hasName ? "$g 👋," : g;
    final line2 = hasName ? widget.name!.trim() : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ time based icon
        Padding(
          padding: const EdgeInsets.only(top:8.0),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _timeIconColor().withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _timeIconColor().withOpacity(.18)),
            ),
            child: Icon(
              _timeIcon(),
              size: 18,
              color: _timeIconColor(),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ✅ greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3E1E69),
                ),
              ),
              if (line2 != null) ...[
                const SizedBox(height: 2),
                Text(
                  line2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7841BA),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}



// import 'dart:async';
// import 'package:flutter/material.dart';

// class GreetingText extends StatefulWidget {
//    GreetingText({
//     this.name, //
//   });

//   final String? name;
 

//   @override
//   State<GreetingText> createState() => _GreetingTextState();
// }

// class _GreetingTextState extends State<GreetingText> {
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(minutes: 1), (_) {
//       if (mounted) setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   String _greeting() {
//     final hour = DateTime.now().hour;
//     if (hour >= 5 && hour < 12) return "Good morning";
//     if (hour >= 12 && hour < 17) return "Good afternoon";
//     if (hour >= 17 && hour < 21) return "Good evening";
//     return "Good night";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final g = _greeting();
//     final text = (widget.name == null || widget.name!.trim().isEmpty)
//         ? g
//         : "$g 👋, \n${widget.name}";

//     return Text(
//       text,
//       style: 
//           const TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 17,
//             fontWeight: FontWeight.w700,
//           ),
//     );
//   }
// }
