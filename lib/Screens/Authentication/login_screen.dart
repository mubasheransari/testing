import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Screens/Authentication/forgot_password_screen.dart';
import 'package:taskoon/Screens/Authentication/otp_verification_screen.dart';
import 'package:taskoon/Screens/Authentication/role_selection_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../widgets/toast_widget.dart';

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
  static const Color primaryDark = Color(0xFF411C6E);

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool _navigated = false;

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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) async {
        if (!mounted) return;

        if (state.status == AuthStatus.success) {
          final userId =
              state.loginResponse?.result?.user?.userId?.toString() ?? '';
                     final name =
              state.loginResponse?.result?.user?.fullName?.toString() ?? '';

          if (userId.isEmpty) {
            toastWidget('Login success but userId missing!', Colors.red);
            return;
          }

          if (_navigated) return;
          _navigated = true;

          final box = GetStorage();
          await box.write('userId', userId);
          await box.write("name", name);

          final bloc = context.read<AuthenticationBloc>();
          bloc
            ..add(LoadUserDetailsRequested(userId))
            ..add(LoadServiceDocumentsRequested())
            ..add(LoadServicesRequested())
            ..add(LoadTrainingVideosRequested());

          bloc.add(
            SendOtpThroughEmail(
              userId: userId,
              email: emailController.text.trim(),
            ),
          );

          toastWidget('OTP Send to ${emailController.text.trim()}', Colors.green);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                isForgetFunctionality: false,
                email: emailController.text.trim(),
                userId: userId,
                phone: state.loginResponse?.result?.user?.phoneNumber?.toString() ?? '',
              ),
            ),
            (route) => false,
          );
        } else if (state.status == AuthStatus.failure) {
          _navigated = false;
          toastWidget("Invalid email or password!", Colors.red);
        }
      },
      child: Builder(
        builder: (context) {
          final isLoading = context.select(
            (AuthenticationBloc b) => b.state.status == AuthStatus.loading,
          );

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
                      // ✅ top hero (white + subtle purple)
                      const _LoginHero(),

                      const SizedBox(height: 14),

                      // ✅ main card
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
                                    Icons.lock_outline_rounded,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF3E1E69),
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Use your email & password to sign in.',
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

                            _ModernFieldWhite(
                              label: 'Email',
                              controller: emailController,
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.mail_outline_rounded,
                            ),
                            const SizedBox(height: 12),

                            _ModernFieldWhite(
                              label: 'Password',
                              controller: passwordController,
                              hint: '••••••••',
                              obscure: obscure,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF75748A),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: primary,
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Signing in…',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .6,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Color(0xFF3E1E69),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => RoleSelectScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Register now',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}


class _LoginHero extends StatelessWidget {
  const _LoginHero();

  static const Color primary = _LoginScreenState.primary;

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
                  'Welcome back 👋',
                  style: TextStyle(
                    color: Color(0xFF3E1E69),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Sign in to continue to your account.',
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

  static const Color primary = _LoginScreenState.primary;

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


class _ModernFieldWhite extends StatelessWidget {
  const _ModernFieldWhite({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(14));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E1E69),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9AA0AF),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF75748A)),
            suffixIcon: suffix,
            enabledBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Color(0xFFE6E8F0)),
            ),
            focusedBorder:const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: _LoginScreenState.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
