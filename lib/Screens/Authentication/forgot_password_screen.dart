import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Screens/Authentication/role_selection_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../Repository/auth_repository.dart';
import '../../widgets/toast_widget.dart';
import 'otp_verification_screen.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   bool obscure = true;

//   final TextEditingController emailController = TextEditingController();

//   static const Color primary = Color(0xFF7841BA);
//   static const Color hintBg = Color(0xFFF4F5F7);

//   final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

//   OutlineInputBorder _border([Color c = Colors.transparent]) =>
//       OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: c),
//       );

//   bool _validateAndToast() {
//     final email = emailController.text.trim();

//     if (email.isEmpty) {
//       toastWidget('Email is required.', Colors.redAccent);
//       return false;
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => AuthenticationBloc(
//         AuthRepositoryHttp(
//           timeout: const Duration(seconds: 20),
//           baseUrl: 'https://api.taskoon.com',//'http://192.3.3.187:85',
//           endpoint: '/api/auth/forgetpassword',
//         ),
//       ),
//       child: BlocListener<AuthenticationBloc, AuthenticationState>(
//         listenWhen: (p, c) => p.forgotPasswordStatus != c.forgotPasswordStatus,
//         listener: (context, state) {
//           if (state.forgotPasswordStatus == ForgotPasswordStatus.success) {
//             print(
//                 "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");
//             print(
//                 "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");
//             print(
//                 "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");
//             context.read<AuthenticationBloc>().add(SendOtpThroughEmail(
//                 userId: state.response!.result!.userId.toString(),
//                 email: emailController.text.trim()));
//             toastWidget(
//                 'OTP Send to ${emailController.text.trim()}', Colors.green);

//                 Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => BlocProvider.value(
//       value: context.read<AuthenticationBloc>(), // SAME INSTANCE ✅
//       child: OtpVerificationScreen(
//          isForgetFunctionality: true,
//           email: emailController.text.trim(),
//         userId:  state.response!.result!.userId.toString(),
//         phone: '',
//       ),
//     ),
//   ),
// );
//           } else if (state.forgotPasswordStatus ==
//               ForgotPasswordStatus.failure) {}
//         },
//         child: Builder(builder: (context) {
//           final isLoading = context.select((AuthenticationBloc b) =>
//               b.state.forgotPasswordStatus == ForgotPasswordStatus.loading);

//           return Scaffold(
//             backgroundColor: Colors.white,
//             body: SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 22),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Forgot Password,',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .headlineMedium),
//                               const SizedBox(height: 6),
//                               Text(
//                                   'Hello there, recover your password to continue!',
//                                   style:
//                                       Theme.of(context).textTheme.bodyMedium),
//                             ],
//                           ),
//                         ),
//                         const _DecorShapesPurple(),
//                       ],
//                     ),
//                     const SizedBox(height: 38),
//                     const Text('Email',
//                         style: TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         isDense: true,
//                         filled: true,
//                         fillColor: hintBg,
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 14, vertical: 16),
//                         suffixIcon: const Icon(Icons.mail_outline),
//                         hintText: 'Email',
//                         enabledBorder: _border(),
//                         focusedBorder: _border(primary.withOpacity(.35)),
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//                     Center(
//                       child: SizedBox(
//                         width: MediaQuery.of(context).size.width * 0.40,
//                         child: FilledButton(
//                           style: FilledButton.styleFrom(
//                             backgroundColor: primary,
//                             padding: const EdgeInsets.symmetric(vertical: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             elevation: 6,
//                             shadowColor: primary.withOpacity(.35),
//                           ),
//                           onPressed: isLoading
//                               ? null
//                               : () {
//                                   if (!_validateAndToast()) return;
//                                   context.read<AuthenticationBloc>().add(
//                                         ForgotPasswordRequest(
//                                           email: emailController.text.trim(),
//                                         ),
//                                       );
//                                 },
//                           child: Text(
//                             isLoading ? 'Please wait…' : 'Sumbit',
//                             style: const TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.white,
//                               letterSpacing: .2,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// /// Decorative purple blocks (unchanged)
// class _DecorShapesPurple extends StatelessWidget {
//   const _DecorShapesPurple();

//   @override
//   Widget build(BuildContext context) {
//     const light = Color(0xFFE9DEFF);
//     const mid = Color(0xFFD4C4FF);
//     const dark = Color(0xFF7841BA);

//     Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
//       return Transform.rotate(
//         angle: angle,
//         child: Container(
//           width: w,
//           height: h,
//           decoration: BoxDecoration(
//             color: c,
//             borderRadius: BorderRadius.circular(6),
//           ),
//         ),
//       );
//     }

//     return SizedBox(
//       width: 110,
//       height: 90,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(right: -6, top: 0, child: block(light)),
//           Positioned(right: 6, top: 22, child: block(mid, w: 78)),
//           Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
//         ],
//       ),
//     );
//   }
// }





class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();

  // ✅ Theme tokens (UI only)
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBg = Color(0xFFF8F7FB);
  static const Color kFieldBg = Color(0xFFF4F5F7);

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: 1.2),
      );

  bool _validateAndToast() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      toastWidget('Email is required.', Colors.redAccent);
      return false;
    }
    return true;
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kPrimary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ✅ NO functionality changes here
      create: (_) => AuthenticationBloc(
        AuthRepositoryHttp(
          timeout: const Duration(seconds: 20),
          baseUrl: 'https://api.taskoon.com', //'http://192.3.3.187:85',
          endpoint: '/api/auth/forgetpassword',
        ),
      ),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.forgotPasswordStatus != c.forgotPasswordStatus,
        listener: (context, state) {
          // ✅ NO functionality changes here
          if (state.forgotPasswordStatus == ForgotPasswordStatus.success) {
            print(
                "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");
            print(
                "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");
            print(
                "FORGET PASSWORD SUCCESS CHECK ${state.forgotPasswordStatus == ForgotPasswordStatus.success}");

            context.read<AuthenticationBloc>().add(
                  SendOtpThroughEmail(
                    userId: state.response!.result!.userId.toString(),
                    email: emailController.text.trim(),
                  ),
                );

            toastWidget(
                'OTP Send to ${emailController.text.trim()}', Colors.green);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthenticationBloc>(), // SAME INSTANCE ✅
                  child: OtpVerificationScreen(
                    isForgetFunctionality: true,
                    email: emailController.text.trim(),
                    userId: state.response!.result!.userId.toString(),
                    phone: '',
                  ),
                ),
              ),
            );
          } else if (state.forgotPasswordStatus ==
              ForgotPasswordStatus.failure) {}
        },
        child: Builder(
          builder: (context) {
            final isLoading = context.select((AuthenticationBloc b) =>
                b.state.forgotPasswordStatus == ForgotPasswordStatus.loading);

            return Scaffold(
              backgroundColor: kBg,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Modern header card (UI only)
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: kPrimary.withOpacity(.12)),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Forgot Password',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: kTextDark,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Recover your password to continue.',
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
                            const SizedBox(width: 8),
                            const _DecorShapesPurple(), // kept
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Form card (UI only)
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: kFieldBg,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                suffixIcon: const Icon(Icons.mail_outline,
                                    color: kMuted),
                                hintText: 'Email',
                                hintStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF9AA0AE),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.8,
                                ),
                                enabledBorder: _border(),
                                focusedBorder: _border(kPrimary.withOpacity(.35)),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                                fontSize: 13.2,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ✅ Primary button (same onPressed logic)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 10,
                                  shadowColor: kPrimary.withOpacity(.28),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (!_validateAndToast()) return;
                                        context.read<AuthenticationBloc>().add(
                                              ForgotPasswordRequest(
                                                email:
                                                    emailController.text.trim(),
                                              ),
                                            );
                                      },
                                child: Text(
                                  isLoading ? 'Please wait…' : 'Submit',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .25,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ✅ Tiny helper text (UI only)
                            const Text(
                              'We’ll send a one-time password (OTP) to your email.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: kMuted,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Decorative purple blocks (unchanged)
class _DecorShapesPurple extends StatelessWidget {
  const _DecorShapesPurple();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFE9DEFF);
    const mid = Color(0xFFD4C4FF);
    const dark = Color(0xFF7841BA);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -6, top: 0, child: block(light)),
          Positioned(right: 6, top: 22, child: block(mid, w: 78)),
          Positioned(right: -12, top: 48, child: block(dark, w: 64, h: 22)),
        ],
      ),
    );
  }
}
