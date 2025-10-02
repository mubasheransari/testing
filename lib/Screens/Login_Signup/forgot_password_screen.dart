import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Screens/Login_Signup/role_selection_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../Repository/auth_repository.dart';
import '../../widgets/toast_widget.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();

  static const Color primary = Color(0xFF7841BA);
  static const Color hintBg = Color(0xFFF4F5F7);

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  bool _validateAndToast() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      toastWidget('Email is required.', Colors.redAccent);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthenticationBloc(
        AuthRepositoryHttp(
          timeout: const Duration(seconds: 20),
          baseUrl: 'http://192.3.3.187:83',
          endpoint: '/api/auth/forgetpassword',
        ),
      ),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.forgotPasswordStatus != c.forgotPasswordStatus,
        listener: (context, state) {
          if (state.forgotPasswordStatus == ForgotPasswordStatus.success) {
            context.read<AuthenticationBloc>().add(SendOtpThroughEmail(
                userId: state.response!.result!.userId.toString(),
                email: emailController.text.trim()));
            toastWidget(
                'OTP Send to ${emailController.text.trim()}', Colors.green);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => OtpVerificationScreen(
                      isForgetFunctionality: true,
                      email: emailController.text.trim(),
                      userId: state.response!.result!.userId.toString(),
                      phone: '')),
              (Route<dynamic> route) => false,
            );
          }
        },
        child: Builder(builder: (context) {
          final isLoading = context.select((AuthenticationBloc b) =>
              b.state.forgotPasswordStatus == ForgotPasswordStatus.loading);

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Forgot Password,',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 6),
                              Text(
                                  'Hello there, recover your password to continue!',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const _DecorShapesPurple(),
                      ],
                    ),
                    const SizedBox(height: 38),
                    const Text('Email',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: hintBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        suffixIcon: const Icon(Icons.mail_outline),
                        hintText: 'Email',
                        enabledBorder: _border(),
                        focusedBorder: _border(primary.withOpacity(.35)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.40,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 6,
                            shadowColor: primary.withOpacity(.35),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (!_validateAndToast()) return;
                                  context.read<AuthenticationBloc>().add(
                                        ForgotPasswordRequest(
                                          email: emailController.text.trim(),
                                        ),
                                      );
                                },
                          child: Text(
                            isLoading ? 'Please wait…' : 'Sumbit',
                            style: const TextStyle(
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
            ),
          );
        }),
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
