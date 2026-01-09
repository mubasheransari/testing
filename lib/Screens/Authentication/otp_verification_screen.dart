import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taskoon/Screens/Authentication/change_password_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/User_booking/user_booking_home.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';
import 'package:taskoon/widgets/toast_widget.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'oto_verification_screen_phone.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   final String email;
//   final String userId;
//   final String phone;
//   final bool isForgetFunctionality;

//   const OtpVerificationScreen({
//     super.key,
//     this.isForgetFunctionality = false,
//     required this.email,
//     required this.userId,
//     required this.phone,
//   });

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen>
//     with CodeAutoFill {
//   // Brand colors
//   static const Color purple = Color(0xFF7841BA);
//   static const Color gold = Color(0xFFD4AF37);
//   static const Color lavender = Color(0xFFF3ECFF);

//   String? _otpCode; // 4 chars
//   bool get _isComplete => (_otpCode?.length ?? 0) == 6;

//   var storage = GetStorage();


//   @override
//   void initState() {
//     super.initState();
//     print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
//     print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
//     print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
//     print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
//     listenForCode(); // Start SMS retriever (Android)
//   }

//   @override
//   void dispose() {
//     cancel(); // Stop listening
//     super.dispose();
//   }

//   @override
//   void codeUpdated() {
//     final newCode = code;
//     if (!mounted) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       setState(() => _otpCode = newCode);
//     });
//   }

//   void _onCodeChanged(String? code) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       setState(() => _otpCode = code);
//     });
//   }

//   void _onVerifyPressed() {
//     if (!_isComplete) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter the 4-digit OTP")),
//       );
//       return;
//     }

//     final bloc = context.read<AuthenticationBloc>();
//     bloc.add(
//       VerifyOtpRequested(
//           userId: widget.userId, email: widget.email, code: _otpCode!),
//     );
//   }

//   void _onResendPressed() {
//     final bloc = context.read<AuthenticationBloc>();
//     bloc.add(SendOtpThroughEmail(userId: widget.userId, email: widget.email));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     var isActive=   storage.read("isActive");
//     var isOnboardingRequired = storage.read("isOnboardingRequired");

//     return BlocConsumer<AuthenticationBloc, AuthenticationState>(
//       listener: (context, state) {
//         if (state.status == AuthStatus.loading) {

//         } else if (state.status == AuthStatus.success) {
//           if (state.response?.message == "Verified") {
//             if (widget.isForgetFunctionality == true) {
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => ChangePasswordScreen(
//                           email: widget.email, userId: widget.userId)));
//             } 
            
//             else {
//             print("ELSE CONDITION");
//             print("ELSE CONDITION");
//             print("ELSE CONDITION");
//             storage.write("role", state.userDetails!.userRole);

// /*if(isActive == false){

//   context.read<AuthenticationBloc>().add(GetUserStatusRequested(
//     userId: state.userDetails!.userId.toString(),
//     email: state.userDetails!.email.toString(),
//     phone: state.userDetails!.phone.toString(),
//   ));
// }
// else if(isActive == true){
//   */
//  if(state.userDetails!.userRole == "Customer"){
//          print("Customer");
//             print("Customer");
//             print("Customer");
//   //   context.read<AuthenticationBloc>().add(GetUserStatusRequested(
//   //   userId: state.userDetails!.userId.toString(),
//   //   email: state.userDetails!.email.toString(),
//   //   phone: state.userDetails!.phone.toString(),
//   // ));
//    Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const UserBookingHome()),
//               );

//  }
//  else  if(state.userDetails!.userRole == "Tasker"){
//      print("Tasker");
//             print("Tasker");
//             print("Tasker");
//   //   context.read<AuthenticationBloc>().add(GetUserStatusRequested(
//   //   userId: state.userDetails!.userId.toString(),
//   //   email: state.userDetails!.email.toString(),
//   //   phone: state.userDetails!.phone.toString(),
//   // ));//Testing@123
//  //if(isOnboardingRequired == true){
//    Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const TaskoonApp() //PersonalInfo() //TaskoonApp()
//                 ),
//               );
//  //}
// //  else{
// //      Navigator.pushReplacement(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => const TaskoonApp()),
// //               );
// //  }
//  }
// }

//           //  }

//           } else {}
//         }
//         if (state.status == AuthStatus.failure &&
//             (state.error?.isNotEmpty ?? false)) {
//           // ScaffoldMessenger.of(context).showSnackBar(
//           //   SnackBar(content: Text(state.error!)),
//           // );
//           toastWidget(state.error!, Colors.red);
//         }
//       },
//       builder: (context, state) {
//         return Scaffold(
//           backgroundColor: Colors.white,
//           body: SafeArea(
//             child: ListView(
//               padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
//               children: [
//                 Center(
//                   child: Image.asset(
//                     'assets/taskoon_logo.png',
//                     height: 95,
//                     width: 95,
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 Text(
//                   'OTP Verification',
//                   textAlign: TextAlign.center,
//                   style: t.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: purple,
//                     letterSpacing: .3,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Enter the 6-digit code sent to your Email!',
//                   textAlign: TextAlign.center,
//                   style: t.bodyMedium?.copyWith(
//                     color: Colors.black54,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 36),

//                 Card(
//                   elevation: 0,
//                   color: lavender,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 28),
//                     child: PinFieldAutoFill(
//                       codeLength: 6,
//                       currentCode: _otpCode,
//                       onCodeChanged: _onCodeChanged,
//                       onCodeSubmitted: (_) => _onVerifyPressed(),
//                       decoration: BoxLooseDecoration(
//                         textStyle: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w500,
//                         ),
//                         bgColorBuilder: const FixedColorBuilder(Colors.white),
//                         strokeColorBuilder: const FixedColorBuilder(purple),
//                         radius: const Radius.circular(12),
//                         gapSpace: 16,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 Center(
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.40,
//                     child: FilledButton(
//                       style: FilledButton.styleFrom(
//                         backgroundColor: purple,
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 6,
//                         shadowColor: purple.withOpacity(.35),
//                       ),
//                       onPressed: _onVerifyPressed,
//                       child: const Text(
//                         'Verify',
//                         style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.white,
//                           letterSpacing: .2,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "Didn't receive the code?  ",
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.w400,
//                           fontSize: 16),
//                     ),

//                     BlocConsumer<AuthenticationBloc, AuthenticationState>(
//                       listenWhen: (prev, curr) =>
//                           prev.error != curr.error ||
//                           prev.response !=
//                               curr.response || 
//                           prev.status !=
//                               curr.status,
//                       listener: (context, state) {
//                         final err = state.error?.trim();
//                         if (err != null && err.isNotEmpty) {
//                           toastWidget(err, Colors.red);
//                           // ScaffoldMessenger.of(context)
//                           //   ..hideCurrentSnackBar()
//                           //   ..showSnackBar(SnackBar(content: Text(err)));
//                           return;
//                         }

//                         // Show server message on success payload, even if it's the same text each time
//                         final res = state.response;
//                         final bodyMsg = res?.message?.trim(); //Testing@1234
//                         if (res?.isSuccess == true &&
//                             bodyMsg != null &&
//                             bodyMsg.isNotEmpty) {
//                           toastWidget(bodyMsg, Colors.green);
//                           // ScaffoldMessenger.of(context)
//                           //   ..hideCurrentSnackBar()
//                           //   ..showSnackBar(SnackBar(content: Text(bodyMsg)));
//                         }
//                       },
//                       builder: (context, state) {
//                         final isBusy =
//                             state.status == AuthStatus.loading; // optional
//                         return GestureDetector(
//                           onTap: isBusy ? null : _onResendPressed,
//                           child: Opacity(
//                             opacity: isBusy ? 0.6 : 1,
//                             child: const Text(
//                               'Resend',
//                               style: TextStyle(
//                                 color: Colors.deepPurple,
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),

                   
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 15,
//                 ),
//                 const Center(
//                   child: Text(
//                     "OR ",
//                     style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w400,
//                         fontSize: 19),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 10,
//                 ),

//                 Center(
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.50,
//                     child: FilledButton(
//                       style: FilledButton.styleFrom(
//                         backgroundColor: purple,
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 6,
//                         shadowColor: purple.withOpacity(.35),
//                       ),
//                       onPressed: () {
//                         //Testing@123
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) =>
//                                     PhoneOtpVerificationScreen(
//                                       email: widget.email,
//                                       userId: widget.userId,
//                                       phone: widget.phone,
//                                     )));

//                         context.read<AuthenticationBloc>().add(
//                             SendOtpThroughPhone(
//                                 userId: widget.userId, phone: widget.phone));
//                         toastWidget('${widget.phone}', Colors.green);
//                       },
//                       child: const Text(
//                         'Get OTP on Phone',
//                         style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.white,
//                           letterSpacing: .2,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


/*
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String phone;
  final bool isForgetFunctionality;

  const OtpVerificationScreen({
    super.key,
    this.isForgetFunctionality = false,
    required this.email,
    required this.userId,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  static const Color purple = Color(0xFF7841BA);
  static const Color gold = Color(0xFFD4AF37);
  static const Color lavender = Color(0xFFF3ECFF);

  String? _otpCode;
  bool get _isComplete => (_otpCode?.length ?? 0) == 6;

  final storage = GetStorage();

  bool _navigated = false; // ✅ prevent double navigation

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final newCode = code;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = newCode);
    });
  }

  void _onCodeChanged(String? code) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = code);
    });
  }

  void _onVerifyPressed() {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit OTP")),
      );
      return;
    }

    context.read<AuthenticationBloc>().add(
          VerifyOtpRequested(
            userId: widget.userId,
            email: widget.email,
            code: _otpCode!,
          ),
        );
  }

  void _onResendPressed() {
    context.read<AuthenticationBloc>().add(
          SendOtpThroughEmail(userId: widget.userId, email: widget.email),
        );
  }

  void _navigateByRole(AuthenticationState state) {
    if (_navigated) return;
    if (state.userDetails == null) return;

    _navigated = true;

    final role = state.userDetails!.userRole;
    storage.write("role", role);

    if (role == "Customer") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserBookingHome()),
      );
    } else if (role == "Tasker") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskoonApp()),
      );
    } else {
      toastWidget("Unknown role: $role", Colors.red);
      _navigated = false; // allow retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      // ✅ We only react to: OTP status/result changes, userDetailsStatus changes, errors
      listenWhen: (prev, curr) {
        final otpChanged =
            prev.status != curr.status || prev.response != curr.response;

        final userDetailsChanged =
            prev.userDetailsStatus != curr.userDetailsStatus ||
                prev.userDetails != curr.userDetails;

        final errorChanged =
            prev.error != curr.error || prev.userDetailsError != curr.userDetailsError;

        return otpChanged || userDetailsChanged || errorChanged;
      },
      listener: (context, state) {
        // -------------------- Failures --------------------
        if (state.status == AuthStatus.failure &&
            (state.error?.trim().isNotEmpty ?? false)) {
          toastWidget(state.error!, Colors.red);
          return;
        }

        if (state.userDetailsStatus == UserDetailsStatus.failure &&
            (state.userDetailsError?.trim().isNotEmpty ?? false)) {
          toastWidget(state.userDetailsError!, Colors.red);
          return;
        }

        // -------------------- OTP Verified --------------------
        // ✅ Do NOT call LoadUserDetailsRequested here (you already called it earlier)
        // ✅ Just wait for userDetailsStatus to become success.
        if (state.status == AuthStatus.success &&
            state.response?.message == "Verified") {
          if (widget.isForgetFunctionality == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordScreen(
                  email: widget.email,
                  userId: widget.userId,
                ),
              ),
            );
          }
          return;
        }

        // -------------------- Navigate ONLY on UserDetails success --------------------
        if (state.userDetailsStatus == UserDetailsStatus.success &&
            state.userDetails != null) {
          _navigateByRole(state);
        }
      },
      builder: (context, state) {
        final busy = state.status == AuthStatus.loading ||
            state.userDetailsStatus == UserDetailsStatus.loading;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              children: [
                Center(
                  child: Image.asset(
                    'assets/taskoon_logo.png',
                    height: 95,
                    width: 95,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'OTP Verification',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: purple,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to your Email!',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                Card(
                  elevation: 0,
                  color: lavender,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 28),
                    child: PinFieldAutoFill(
                      codeLength: 6,
                      currentCode: _otpCode,
                      onCodeChanged: _onCodeChanged,
                      onCodeSubmitted: (_) => _onVerifyPressed(),
                      decoration: BoxLooseDecoration(
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        bgColorBuilder: const FixedColorBuilder(Colors.white),
                        strokeColorBuilder: const FixedColorBuilder(purple),
                        radius: const Radius.circular(12),
                        gapSpace: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 6,
                        shadowColor: purple.withOpacity(.35),
                      ),
                      onPressed: busy ? null : _onVerifyPressed,
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: .2,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the code?  ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: busy ? null : _onResendPressed,
                      child: Opacity(
                        opacity: busy ? 0.6 : 1,
                        child: const Text(
                          'Resend',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                const Center(
                  child: Text(
                    "OR ",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 6,
                        shadowColor: purple.withOpacity(.35),
                      ),
                      onPressed: busy
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PhoneOtpVerificationScreen(
                                    email: widget.email,
                                    userId: widget.userId,
                                    phone: widget.phone,
                                  ),
                                ),
                              );

                              context.read<AuthenticationBloc>().add(
                                    SendOtpThroughPhone(
                                      userId: widget.userId,
                                      phone: widget.phone,
                                    ),
                                  );

                              toastWidget('${widget.phone}', Colors.green);
                            },
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Get OTP on Phone',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: .2,
                              ),
                            ),
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
*/


/*

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String phone;
  final bool isForgetFunctionality;

  const OtpVerificationScreen({
    super.key,
    this.isForgetFunctionality = false,
    required this.email,
    required this.userId,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  static const Color primary = Color(0xFF7841BA);
  static const Color primaryDark = Color(0xFF411C6E);
  static const Color lavender = Color(0xFFF3ECFF);

  String? _otpCode;
  bool get _isComplete => (_otpCode?.length ?? 0) == 6;

  final storage = GetStorage();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final newCode = code;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = newCode);
    });
  }

  void _onCodeChanged(String? code) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = code);
    });
  }

  void _onVerifyPressed() {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit OTP")),
      );
      return;
    }

    context.read<AuthenticationBloc>().add(
          VerifyOtpRequested(
            userId: widget.userId,
            email: widget.email,
            code: _otpCode!,
          ),
        );
  }

  void _onResendPressed() {
    context.read<AuthenticationBloc>().add(
          SendOtpThroughEmail(userId: widget.userId, email: widget.email),
        );
  }

  void _navigateByRole(AuthenticationState state) {
    if (_navigated) return;
    if (state.userDetails == null) return;

    _navigated = true;

    final role = state.userDetails!.userRole;
    storage.write("role", role);

    if (role == "Customer") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserBookingHome()),
      );
    } else if (role == "Tasker") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskoonApp()),
      );
    } else {
      toastWidget("Unknown role: $role", Colors.red);
      _navigated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      // ✅ no functionality changes
      listenWhen: (prev, curr) {
        final otpChanged =
            prev.status != curr.status || prev.response != curr.response;

        final userDetailsChanged =
            prev.userDetailsStatus != curr.userDetailsStatus ||
                prev.userDetails != curr.userDetails;

        final errorChanged = prev.error != curr.error ||
            prev.userDetailsError != curr.userDetailsError;

        return otpChanged || userDetailsChanged || errorChanged;
      },
      listener: (context, state) {
        if (state.status == AuthStatus.failure &&
            (state.error?.trim().isNotEmpty ?? false)) {
          toastWidget(state.error!, Colors.red);
          return;
        }

        if (state.userDetailsStatus == UserDetailsStatus.failure &&
            (state.userDetailsError?.trim().isNotEmpty ?? false)) {
          toastWidget(state.userDetailsError!, Colors.red);
          return;
        }

        // OTP verified (forget flow only)
        if (state.status == AuthStatus.success &&
            state.response?.message == "Verified") {
          if (widget.isForgetFunctionality == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordScreen(
                  email: widget.email,
                  userId: widget.userId,
                ),
              ),
            );
          }
          return;
        }

        // Navigate ONLY when userDetails success
        if (state.userDetailsStatus == UserDetailsStatus.success &&
            state.userDetails != null) {
          _navigateByRole(state);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading ||
            state.userDetailsStatus == UserDetailsStatus.loading;

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F7FB),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ HERO like Login screen
                    const _OtpHero(),

                    const SizedBox(height: 14),

                    // ✅ MAIN CARD like Login screen
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withOpacity(.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title row
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.verified_outlined,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OTP Verification',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF3E1E69),
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Enter the 6-digit code sent to your email.',
                                      style: TextStyle(
                                        fontSize: 12.8,
                                        color: Color(0xFF75748A),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // OTP input container (modern, same family as login)
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6E8F0),
                              ),
                            ),
                            child: PinFieldAutoFill(
                              codeLength: 6,
                              currentCode: _otpCode,
                              onCodeChanged: _onCodeChanged,
                              onCodeSubmitted: (_) => _onVerifyPressed(),
                              decoration: BoxLooseDecoration(
                                textStyle: const TextStyle(
                                  color: Color(0xFF1C1B1F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                bgColorBuilder:
                                    const FixedColorBuilder(Colors.white),
                                strokeColorBuilder:
                                    FixedColorBuilder(primary.withOpacity(.55)),
                                radius: const Radius.circular(12),
                                gapSpace: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Verify button same as login
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isLoading ? null : _onVerifyPressed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isLoading) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Verifying…',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'VERIFY',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .6,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 20),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // resend row (same vibe)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive the code? ",
                                style: TextStyle(
                                  color: Color(0xFF3E1E69),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoading ? null : _onResendPressed,
                                child: Opacity(
                                  opacity: isLoading ? 0.6 : 1,
                                  child: const Text(
                                    'Resend',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // divider OR
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFE6E8F0),
                                  height: 1,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Color(0xFF75748A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: const Color(0xFFE6E8F0),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Get OTP on Phone (same button style but light)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: primary.withOpacity(.35)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PhoneOtpVerificationScreen(
                                            email: widget.email,
                                            userId: widget.userId,
                                            phone: widget.phone,
                                          ),
                                        ),
                                      );

                                      context.read<AuthenticationBloc>().add(
                                            SendOtpThroughPhone(
                                              userId: widget.userId,
                                              phone: widget.phone,
                                            ),
                                          );

                                      toastWidget('${widget.phone}', Colors.green);
                                    },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.phone_iphone_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Get OTP on Phone',
                                    style: TextStyle(
                                      fontSize: 14.8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        'TASKOON',
                        style: TextStyle(
                          color: primary.withOpacity(.55),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ OTP hero matching login hero style
class _OtpHero extends StatelessWidget {
  const _OtpHero();

  static const Color primary = _OtpVerificationScreenState.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(.12),
            primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: primary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Verify your account 🔐',
                  style: TextStyle(
                    color: Color(0xFF3E1E69),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'We sent a 6-digit code to your email.\nEnter it to continue.',
                  style: TextStyle(
                    color: Color(0xFF75748A),
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _HeroMark(),
        ],
      ),
    );
  }
}

// ✅ same hero mark as login for consistent design
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  static const Color primary = _OtpVerificationScreenState.primary;

  @override
  Widget build(BuildContext context) {
    Widget pill(Color c, {double w = 70, double h = 18}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return SizedBox(
      width: 86,
      height: 70,
      child: Stack(
        children: [
          Positioned(top: 6, right: 0, child: pill(primary.withOpacity(.35))),
          Positioned(top: 28, right: 10, child: pill(primary.withOpacity(.22), w: 58)),
          Positioned(top: 48, right: 2, child: pill(primary.withOpacity(.16), w: 44, h: 16)),
        ],
      ),
    );
  }
}
*/




class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String phone;
  final bool isForgetFunctionality;

  const OtpVerificationScreen({
    super.key,
    this.isForgetFunctionality = false,
    required this.email,
    required this.userId,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  static const Color primary = Color(0xFF7841BA);
  static const Color primaryDark = Color(0xFF411C6E);

  String? _otpCode;
  bool get _isComplete => (_otpCode?.length ?? 0) == 6;

  final storage = GetStorage();
  bool _navigated = false;

  // ✅ IMPORTANT: button loading should start ONLY after user presses verify
  bool _verifyPressed = false;

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final newCode = code;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = newCode);
    });
  }

  void _onCodeChanged(String? code) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = code);
    });
  }

  void _onVerifyPressed() {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit OTP")),
      );
      return;
    }

    // ✅ start loading UI only after user initiates verification
    setState(() => _verifyPressed = true);

    context.read<AuthenticationBloc>().add(
          VerifyOtpRequested(
            userId: widget.userId,
            email: widget.email,
            code: _otpCode!,
          ),
        );
  }

  void _onResendPressed() {
    context.read<AuthenticationBloc>().add(
          SendOtpThroughEmail(userId: widget.userId, email: widget.email),
        );
  }

  void _navigateByRole(AuthenticationState state) {
    if (_navigated) return;
    if (state.userDetails == null) return;

    _navigated = true;

    final role = state.userDetails!.userRole;
    storage.write("role", role);

    if (role == "Customer") {
      Navigator.pushReplacement(//Testing@123
        context,
        MaterialPageRoute(builder: (_) => const UserBottomNavBar()),
      );
    } else if (role == "Tasker") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskoonApp()),
      );
    } else {
      toastWidget("Unknown role: $role", Colors.red);
      _navigated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listenWhen: (prev, curr) {
        final otpChanged =
            prev.status != curr.status || prev.response != curr.response;

        final userDetailsChanged =
            prev.userDetailsStatus != curr.userDetailsStatus ||
                prev.userDetails != curr.userDetails;

        final errorChanged = prev.error != curr.error ||
            prev.userDetailsError != curr.userDetailsError;

        return otpChanged || userDetailsChanged || errorChanged;
      },
      listener: (context, state) {
        // -------------------- Failures --------------------
        if (state.status == AuthStatus.failure &&
            (state.error?.trim().isNotEmpty ?? false)) {
          toastWidget(state.error!, Colors.red);
          // ✅ stop button loading on failure
          if (mounted) setState(() => _verifyPressed = false);
          return;
        }

        if (state.userDetailsStatus == UserDetailsStatus.failure &&
            (state.userDetailsError?.trim().isNotEmpty ?? false)) {
          toastWidget(state.userDetailsError!, Colors.red);
          // ✅ stop button loading on failure
          if (mounted) setState(() => _verifyPressed = false);
          return;
        }

        // -------------------- OTP Verified --------------------
        if (state.status == AuthStatus.success &&
            state.response?.message == "Verified") {
          if (widget.isForgetFunctionality == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordScreen(
                  email: widget.email,
                  userId: widget.userId,
                ),
              ),
            );
            return;
          }
          // ✅ DO NOT navigate here, wait for userDetails success
          return;
        }

        // -------------------- Navigate ONLY on UserDetails success --------------------
        // ✅ Only navigate if user actually pressed Verify on this screen
        if (_verifyPressed &&
            state.userDetailsStatus == UserDetailsStatus.success &&
            state.userDetails != null) {
          _navigateByRole(state);
        }
      },
      builder: (context, state) {
        // ✅ loading is ONLY UI-driven after verify press
        final showLoading = _verifyPressed &&
            (state.status == AuthStatus.loading ||
                state.userDetailsStatus == UserDetailsStatus.loading);

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F7FB),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _OtpHero(),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withOpacity(.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.verified_outlined,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OTP Verification',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF3E1E69),
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Enter the 6-digit code sent to your email.',
                                      style: TextStyle(
                                        fontSize: 12.8,
                                        color: Color(0xFF75748A),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6E8F0),
                              ),
                            ),
                            child: PinFieldAutoFill(
                              codeLength: 6,
                              currentCode: _otpCode,
                              onCodeChanged: _onCodeChanged,
                              onCodeSubmitted: (_) => _onVerifyPressed(),
                              decoration: BoxLooseDecoration(
                                textStyle: const TextStyle(
                                  color: Color(0xFF1C1B1F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                bgColorBuilder:
                                    const FixedColorBuilder(Colors.white),
                                strokeColorBuilder:
                                    FixedColorBuilder(primary.withOpacity(.55)),
                                radius: const Radius.circular(12),
                                gapSpace: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: showLoading ? null : _onVerifyPressed,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (showLoading) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Verifying…',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'VERIFY',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .6,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 20),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive the code? ",
                                style: TextStyle(
                                  color: Color(0xFF3E1E69),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: showLoading ? null : _onResendPressed,
                                child: Opacity(
                                  opacity: showLoading ? 0.6 : 1,
                                  child: const Text(
                                    'Resend',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: const [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE6E8F0),
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Color(0xFF75748A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFE6E8F0),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side:
                                    BorderSide(color: primary.withOpacity(.35)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              onPressed: showLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PhoneOtpVerificationScreen(
                                            email: widget.email,
                                            userId: widget.userId,
                                            phone: widget.phone,
                                          ),
                                        ),
                                      );

                                      context.read<AuthenticationBloc>().add(
                                            SendOtpThroughPhone(
                                              userId: widget.userId,
                                              phone: widget.phone,
                                            ),
                                          );

                                      toastWidget('${widget.phone}', Colors.green);
                                    },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.phone_iphone_rounded, size: 18),
                                  SizedBox(width: 10),
                                  Text(
                                    'Get OTP on Phone',
                                    style: TextStyle(
                                      fontSize: 14.8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        'TASKOON',
                        style: TextStyle(
                          color: primary.withOpacity(.55),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtpHero extends StatelessWidget {
  const _OtpHero();

  static const Color primary = _OtpVerificationScreenState.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(.12),
            primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: primary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your account 🔐',
                  style: TextStyle(
                    color: Color(0xFF3E1E69),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'We sent a 6-digit code to your email.\nEnter it to continue.',
                  style: TextStyle(
                    color: Color(0xFF75748A),
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          _HeroMark(),
        ],
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  static const Color primary = _OtpVerificationScreenState.primary;

  @override
  Widget build(BuildContext context) {
    Widget pill(Color c, {double w = 70, double h = 18}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return SizedBox(
      width: 86,
      height: 70,
      child: Stack(
        children: [
          Positioned(top: 6, right: 0, child: pill(primary.withOpacity(.35))),
          Positioned(
              top: 28,
              right: 10,
              child: pill(primary.withOpacity(.22), w: 58)),
          Positioned(
              top: 48,
              right: 2,
              child: pill(primary.withOpacity(.16), w: 44, h: 16)),
        ],
      ),
    );
  }
}
