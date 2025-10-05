import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Screens/Authentication/forgot_password_screen.dart';
import 'package:taskoon/Screens/Authentication/otp_verification_screen.dart';
import 'package:taskoon/Screens/Authentication/role_selection_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../Repository/auth_repository.dart';
import '../../widgets/toast_widget.dart';
import '../Tasker_Onboarding/capture_selfie_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
    final pass = passwordController.text;

    if (email.isEmpty) {
      toastWidget('Email is required.', Colors.redAccent);
      return false;
    }
    if (!_emailRe.hasMatch(email)) {
      toastWidget('Please enter a valid email.', Colors.redAccent);
      return false;
    }
    if (pass.isEmpty) {
      toastWidget('Password is required.', Colors.redAccent);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthenticationBloc(
        AuthRepositoryHttp(
          timeout: Duration(seconds: 20),
          baseUrl: 'http://192.3.3.187:83',
          endpoint: '/api/auth/signup',
        ),
      ),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == AuthStatus.loading) {
            //  toastWidget('Signing in…', Colors.black87);
          } else if (state.status == AuthStatus.success) {
            final token = state.loginResponse?.result?.accessToken ?? '';
            final msg = state.loginResponse?.message ?? 'Login success';
            // toastWidget(msg, Colors.green);
            context.read<AuthenticationBloc>().add(SendOtpThroughEmail(
                userId: state.loginResponse!.result!.user!.userId.toString(),
                email: emailController.text.trim()));
            toastWidget(
                'OTP Send to ${emailController.text.trim()}', Colors.green);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => OtpVerificationScreen(
                    isForgetFunctionality: false,
                      email: emailController.text.trim(),
                      userId:
                          state.loginResponse!.result!.user!.userId.toString(),
                      phone: state.loginResponse!.result!.user!.phoneNumber
                          .toString())),
              (Route<dynamic> route) =>
                  false, 
            );

            // Save token if needed Testing@123
            // final box = GetStorage();
            // box.write('accessToken', token);

            // Navigate to home/dashboard Testing@123
            // Navigator.pushReplacement(context,
            //     MaterialPageRoute(builder: (_) => const HomeScreen())); Testing@123
          } else if (state.status == AuthStatus.failure) {
            // toastWidget(state.error ?? 'Login failed', Colors.redAccent);
            toastWidget("Invalid email or password!", Colors.red);
          }
        },
        child: Builder(builder: (context) {
          final isLoading = context.select(
              (AuthenticationBloc b) => b.state.status == AuthStatus.loading);

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
                              Text('Welcome Back,',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 6),
                              Text('Hello there, sign in to continue!',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const _DecorShapesPurple(),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Email
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

                    const Text('Password',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        isDense: true,
                        filled: true,
                        fillColor: hintBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        enabledBorder: _border(),
                        focusedBorder: _border(primary.withOpacity(.35)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- Forgot
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ForgotPasswordScreen()));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

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
                                        SignInRequested(
                                          email: emailController.text.trim(),
                                          password: passwordController.text,
                                        ),
                                      );
                                },
                          child: Text(
                            isLoading ? 'Please wait…' : 'LOGIN',
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
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't have an account? ",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RoleSelectScreen()));
                          },
                          child: const Text(
                            'Register now!',
                            style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                                fontSize: 16),
                          ),
                        ),
                      ],
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
