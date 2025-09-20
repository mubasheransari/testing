// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../widgets/primary_button.dart';
// import '../../widgets/step_indicator.dart';

// class Welcome extends StatelessWidget {
//   static const route = '/';
//   const Welcome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context);
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               const Spacer(),
//               SvgPicture.asset('assets/illustrations/hero.svg', height: 220),
//               const SizedBox(height: 24),
//               Text('Welcome', style: t.textTheme.displaySmall, textAlign: TextAlign.center),
//               const SizedBox(height: 8),
//               Text('Start your certification onboarding', style: t.textTheme.bodyLarge, textAlign: TextAlign.center),
//               const Spacer(),
//               const StepIndicator(index: 0, total: 6),
//               const SizedBox(height: 16),
//               PrimaryButton(label: 'Get started', onPressed: () => Navigator.pushNamed(context, '/login')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
