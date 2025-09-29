import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Screens/Login_Signup/role_selection_screen.dart';
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
            toastWidget(msg, Colors.green);
                        Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => SelfieCaptureScreen()));

            // Save token if needed
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
                    // --- Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(
                          width: 60,
                          height: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // --- Welcome
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

                    // --- Password
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
                            // TODO: Navigate to ForgotPasswordScreen
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


/*class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // --- Taskoon purple palette ---
  static const Color primary = Color(0xFF7841BA); // main purple
  static const Color primaryAlt = Color(0xFF8B59C6); // lighter purple
  static const Color hintBg = Color(0xFFF4F5F7);

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + purple underline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOGIN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 3,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Welcome + purple decorative blocks
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back,',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text('Hello there, sign in to continue!',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const _DecorShapesPurple(),
                ],
              ),

              const SizedBox(height: 28),

              // Email
              const Text('Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: hintBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  suffixIcon: const Icon(Icons.mail_outline),
                  hintText: 'Email',
                  enabledBorder: _border(),
                  focusedBorder: _border(primary.withOpacity(.35)),
                ),
              ),

              const SizedBox(height: 18),

              // Password
              const Text('Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  isDense: true,
                  filled: true,
                  fillColor: hintBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon:
                        Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                  enabledBorder: _border(),
                  focusedBorder: _border(primary.withOpacity(.35)),
                ),
              ),

              const SizedBox(height: 14),

              // Forgot
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Login button
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
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OtpVerificationScreen()));
                    },
                    child: Text(
                      'Login'.toUpperCase(),
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
              const SizedBox(
                height: 20,
              ),
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
  }
}

/// Circular icon (kept, neutral)
class _CircleIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _CircleIcon({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 1),
              color: Color(0x11000000),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Top-right decorative angled rectangles — now in purple tones.
class _DecorShapesPurple extends StatelessWidget {
  const _DecorShapesPurple();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFE9DEFF); // light lavender
    const mid = Color(0xFFD4C4FF); // mid lavender
    const dark = Color(0xFF7841BA); // primary purple

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle, // ~34°
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
*/

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   // Brand palette (same as CreateAccountScreen)
//   static const purple = Color(0xFF5B21B6);
//   static const cream = Color(0xFFFFF7E8);
//   static const gold = Color(0xFFB98F22);

//   final idCtrl = TextEditingController(); // email or phone
//   final passCtrl = TextEditingController();

//   bool get valid =>
//       idCtrl.text.trim().isNotEmpty && passCtrl.text.trim().isNotEmpty;

//   @override
//   void dispose() {
//     idCtrl.dispose();
//     passCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(24, 115, 24, 24),
//           children: [
//             // Logo
//             Center(
//               child: Image.asset(
//                 'assets/taskoon_logo.png',
//                 height: 108,
//                 width: 108,
//               ),
//             ),

//             const Text(
//               'LOGIN',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: purple,
//                 fontSize: 22,
//                 letterSpacing: .5,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//             const SizedBox(height: 18),

//             // Email / Phone
//             _filledField(
//               controller: idCtrl,
//               hint: 'Email or Phone',
//               keyboardType: TextInputType.emailAddress,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: 12),

//             // Password
//             _filledField(
//               controller: passCtrl,
//               hint: 'Password',
//               obscure: true,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: 10),

//             // Forgot password
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton(
//                 style: TextButton.styleFrom(
//                   foregroundColor: Colors.black87,
//                   padding: EdgeInsets.zero,
//                 ),
//                 onPressed: () {
//                   // TODO: navigate to forgot password screen
//                 },
//                 child: const Text(
//                   'Forgot Password?',
//                   style: TextStyle(fontWeight: FontWeight.w300, fontSize: 17),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),

//             // Continue
//             SizedBox(
//               height: 52,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: valid ? purple : const Color(0xFFECEFF3),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 onPressed: valid
//                     ? () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => OtpVerificationScreen()));
//                       }
//                     : null,
//                 child: Text('Continue',
//                     style: TextStyle(
//                         color: valid ? Colors.white : Colors.black54,
//                         fontWeight: FontWeight.w500,
//                         // letterSpacing: 0.1,
//                         fontSize: 18)
//                     // style: TextStyle(
//                     //   fontWeight: FontWeight.w800,
//                     //   color: valid ? Colors.white : Colors.black54,
//                     // ),
//                     ),
//               ),
//             ),

//             // (Optional) Divider + create account link to mirror UX
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Don't have an account? ",
//                   style: TextStyle(
//                       fontWeight: FontWeight.w300,
//                       fontSize:
//                           17), // style: TextStyle(color: Colors.black.withOpacity(.75)),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => RoleSelectScreen()));
//                   },
//                   child: const Text(
//                     'Sign up',
//                     style: TextStyle(
//                         color: gold, fontWeight: FontWeight.w600, fontSize: 17),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Same filled-field style as CreateAccountScreen
//   Widget _filledField({
//     required TextEditingController controller,
//     required String hint,
//     TextInputType? keyboardType,
//     bool obscure = false,
//     required ValueChanged<String> onChanged,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscure,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: cream,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: gold.withOpacity(.45)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: gold, width: 1.6),
//         ),
//       ),
//       style: const TextStyle(fontWeight: FontWeight.w700),
//     );
//   }
// }
