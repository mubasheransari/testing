import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taskoon/Screens/Authentication/change_password_screen.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/personal_info.dart';
import 'package:taskoon/widgets/toast_widget.dart';

import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../Tasker_Onboarding/capture_selfie_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'oto_verification_screen_phone.dart';

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
  // Brand colors
  static const Color purple = Color(0xFF7841BA);
  static const Color gold = Color(0xFFD4AF37);
  static const Color lavender = Color(0xFFF3ECFF);

  String? _otpCode; // 4 chars
  bool get _isComplete => (_otpCode?.length ?? 0) == 6;

  @override
  void initState() {
    super.initState();
    print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
    print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
    print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
    print('BOOLEAN CHECK ${widget.isForgetFunctionality}');
    listenForCode(); // Start SMS retriever (Android)
  }

  @override
  void dispose() {
    cancel(); // Stop listening
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
        const SnackBar(content: Text("Please enter the 4-digit OTP")),
      );
      return;
    }

    final bloc = context.read<AuthenticationBloc>();
    bloc.add(
      VerifyOtpRequested(
          userId: widget.userId, email: widget.email, code: _otpCode!),
    );
  }

  void _onResendPressed() {
    final bloc = context.read<AuthenticationBloc>();
    bloc.add(SendOtpThroughEmail(userId: widget.userId, email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loading) {
          toastWidget(
              "Please wait! While we're verifying your account!", Colors.green);
        } else if (state.status == AuthStatus.success) {
          if (state.response?.message == "Verified") {
            if (widget.isForgetFunctionality == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(
                          email: widget.email, userId: widget.userId)));
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInfo()),
              );
            }

            // Navigator.pushReplacement( Testing@1122
            //   context,
            //   MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()),
            // );
          } else {}
        } else if (state.status == AuthStatus.failure) {
          toastWidget(
              "Wrong OTP! Wr're unable to access your account.", Colors.red);
        }
      },
      builder: (context, state) {
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

                // OTP input Testing@123
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
                      onPressed: _onVerifyPressed,
                      child: const Text(
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
                          fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: _onResendPressed,
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                const Center(
                  child: Text(
                    "OR ",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: 19),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

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
                      onPressed: () {
                        //Testing@123
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PhoneOtpVerificationScreen(
                                      email: widget.email,
                                      userId: widget.userId,
                                      phone: widget.phone,
                                    )));

                        context.read<AuthenticationBloc>().add(
                            SendOtpThroughPhone(
                                userId: widget.userId, phone: widget.phone));
                        toastWidget('${widget.phone}', Colors.green);
                      },
                      child: const Text(
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
