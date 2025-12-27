import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskoon/Service/location_service.dart';


// class GreetingWithLocation extends StatefulWidget {
//   const GreetingWithLocation({super.key});

//   @override
//   State<GreetingWithLocation> createState() => _GreetingWithLocationState();
// }

// class _GreetingWithLocationState extends State<GreetingWithLocation> {
//   String? _location;
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadLocation();
//   }

//   Future<void> _loadLocation() async {
//     if (_loading) return;
//     setState(() => _loading = true);

//     final loc = await LocationService.getReadableLocation();

//     if (!mounted) return;
//     setState(() {
//       _location = loc ?? 'Location unavailable';
//       _loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // "Good morning 👋"
//         Row(
//           children: [
//             Text(
//               'Good morning',
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF5E2DAC), // your Taskoon purple
//               ),
//             ),
//             const SizedBox(width: 6),
//             const Text('👋', style: TextStyle(fontSize: 24)),
//           ],
//         ),
//         const SizedBox(height: 4),

//         // Tappable location line
//         InkWell(
//           onTap: _loading ? null : _loadLocation,
//           borderRadius: BorderRadius.circular(16),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.location_on,
//                 size: 18,
//                 color: Color(0xFF9E9E9E),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 _loading
//                     ? 'Detecting location...'
//                     : (_location ?? 'Tap to detect location'),
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Color(0xFF9E9E9E),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
class GreetingText extends StatefulWidget {
   GreetingText({
    this.name, //
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

    // update every minute so greeting changes when time crosses boundary
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
    final hour = DateTime.now().hour; // local device time
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Good night";
  }

  @override
  Widget build(BuildContext context) {
    final g = _greeting();
    final text = (widget.name == null || widget.name!.trim().isEmpty)
        ? g
        : "$g 👋, ${widget.name}";

    return Text(
      text,
      style: 
          const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
