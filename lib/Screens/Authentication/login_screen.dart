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


// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   bool obscure = true;

//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   static const Color primary = Color(0xFF7841BA);
//   static const Color hintBg = Color(0xFFF4F5F7);

//   final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

//   bool _navigated = false; // ✅ prevent double navigation

//   OutlineInputBorder _border([Color c = Colors.transparent]) =>
//       OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: c),
//       );

//   bool _validateAndToast() {
//     final email = emailController.text.trim();
//     final pass = passwordController.text;

//     if (email.isEmpty) {
//       toastWidget('Email is required.', Colors.redAccent);
//       return false;
//     }
//     if (!_emailRe.hasMatch(email)) {
//       toastWidget('Please enter a valid email.', Colors.redAccent);
//       return false;
//     }
//     if (pass.isEmpty) {
//       toastWidget('Password is required.', Colors.redAccent);
//       return false;
//     }
//     return true;
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthenticationBloc, AuthenticationState>(
//       listenWhen: (p, c) => p.status != c.status,
//       listener: (context, state) async {
//         if (!mounted) return;

//         if (state.status == AuthStatus.success) {
//           final userId =
//               state.loginResponse?.result?.user?.userId?.toString() ?? '';

//           if (userId.isEmpty) {
//             toastWidget('Login success but userId missing!', Colors.red);
//             return;
//           }

//           // ✅ prevent multiple triggers (sometimes state emits twice)
//           if (_navigated) return;
//           _navigated = true;

//           final box = GetStorage();
//           await box.write('userId', userId);

//           final bloc = context.read<AuthenticationBloc>();

//           // Optional preload (fine to keep)
//           bloc
//             ..add(LoadUserDetailsRequested(userId))
//             ..add(LoadServiceDocumentsRequested())
//             ..add(LoadServicesRequested())
//             ..add(LoadTrainingVideosRequested());

//           // Send OTP
//           bloc.add(
//             SendOtpThroughEmail(
//               userId: userId,
//               email: emailController.text.trim(),
//             ),
//           );

//           toastWidget('OTP Send to ${emailController.text.trim()}', Colors.green);

//           // ✅ Since your AuthenticationBloc is GLOBAL in main.dart,
//           // ✅ DO NOT wrap with BlocProvider.value here.
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OtpVerificationScreen(
//                 isForgetFunctionality: false,
//                 email: emailController.text.trim(),
//                 userId: userId,
//                 phone: state.loginResponse?.result?.user?.phoneNumber
//                         ?.toString() ??
//                     '',
//               ),
//             ),
//             (route) => false,
//           );
//         } else if (state.status == AuthStatus.failure) {
//           _navigated = false; // allow retry
//           toastWidget("Invalid email or password!", Colors.red);
//         }
//       },
//       child: Builder(
//         builder: (context) {
//           final isLoading = context.select(
//             (AuthenticationBloc b) => b.state.status == AuthStatus.loading,
//           );

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
//                               Text(
//                                 'Welcome Back,',
//                                 style:
//                                     Theme.of(context).textTheme.headlineMedium,
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 'Hello there, sign in to continue!',
//                                 style: Theme.of(context).textTheme.bodyMedium,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const _DecorShapesPurple(),
//                       ],
//                     ),
//                     const SizedBox(height: 28),

//                     // --- Email
//                     const Text(
//                       'Email',
//                       style:
//                           TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         isDense: true,
//                         filled: true,
//                         fillColor: hintBg,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 16,
//                         ),
//                         suffixIcon: const Icon(Icons.mail_outline),
//                         hintText: 'Email',
//                         enabledBorder: _border(),
//                         focusedBorder: _border(primary.withOpacity(.35)),
//                       ),
//                     ),
//                     const SizedBox(height: 18),

//                     // --- Password
//                     const Text(
//                       'Password',
//                       style:
//                           TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: passwordController,
//                       obscureText: obscure,
//                       decoration: InputDecoration(
//                         hintText: 'Password',
//                         isDense: true,
//                         filled: true,
//                         fillColor: hintBg,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 16,
//                         ),
//                         suffixIcon: IconButton(
//                           onPressed: () => setState(() => obscure = !obscure),
//                           icon: Icon(
//                             obscure ? Icons.visibility_off : Icons.visibility,
//                           ),
//                         ),
//                         enabledBorder: _border(),
//                         focusedBorder: _border(primary.withOpacity(.35)),
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // --- Forgot
//                     Row(
//                       children: [
//                         const Spacer(),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ForgotPasswordScreen(),
//                               ),
//                             );
//                           },
//                           style: TextButton.styleFrom(
//                             foregroundColor: primary,
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: const Text('Forgot Password?'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 22),

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
//                                         SignInRequested(
//                                           email: emailController.text.trim(),
//                                           password: passwordController.text,
//                                         ),
//                                       );
//                                 },
//                           child: Text(
//                             isLoading ? 'Please wait…' : 'LOGIN',
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
//                     const SizedBox(height: 20),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "Didn't have an account? ",
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.w400,
//                             fontSize: 16,
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => RoleSelectScreen(),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             'Register now!',
//                             style: TextStyle(
//                               color: Colors.deepPurple,
//                               fontWeight: FontWeight.w500,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
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
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   bool obscure = true;

//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   static const Color primary = Color(0xFF7841BA);

//   final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
//   bool _navigated = false; // ✅ prevent double navigation

//   bool _validateAndToast() {
//     final email = emailController.text.trim();
//     final pass = passwordController.text;

//     if (email.isEmpty) {
//       toastWidget('Email is required.', Colors.redAccent);
//       return false;
//     }
//     if (!_emailRe.hasMatch(email)) {
//       toastWidget('Please enter a valid email.', Colors.redAccent);
//       return false;
//     }
//     if (pass.isEmpty) {
//       toastWidget('Password is required.', Colors.redAccent);
//       return false;
//     }
//     return true;
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthenticationBloc, AuthenticationState>(
//       listenWhen: (p, c) => p.status != c.status,
//       listener: (context, state) async {
//         if (!mounted) return;

//         if (state.status == AuthStatus.success) {
//           final userId =
//               state.loginResponse?.result?.user?.userId?.toString() ?? '';

//           if (userId.isEmpty) {
//             toastWidget('Login success but userId missing!', Colors.red);
//             return;
//           }

//           if (_navigated) return;
//           _navigated = true;

//           final box = GetStorage();
//           await box.write('userId', userId);

//           final bloc = context.read<AuthenticationBloc>();
//           bloc
//             ..add(LoadUserDetailsRequested(userId))
//             ..add(LoadServiceDocumentsRequested())
//             ..add(LoadServicesRequested())
//             ..add(LoadTrainingVideosRequested());

//           bloc.add(
//             SendOtpThroughEmail(
//               userId: userId,
//               email: emailController.text.trim(),
//             ),
//           );

//           toastWidget(
//             'OTP Send to ${emailController.text.trim()}',
//             Colors.green,
//           );

//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OtpVerificationScreen(
//                 isForgetFunctionality: false,
//                 email: emailController.text.trim(),
//                 userId: userId,
//                 phone: state.loginResponse?.result?.user?.phoneNumber
//                         ?.toString() ??
//                     '',
//               ),
//             ),
//             (route) => false,
//           );
//         } else if (state.status == AuthStatus.failure) {
//           _navigated = false;
//           toastWidget("Invalid email or password!", Colors.red);
//         }
//       },
//       child: Builder(
//         builder: (context) {
//           final isLoading = context.select(
//             (AuthenticationBloc b) => b.state.status == AuthStatus.loading,
//           );

//           return Scaffold(
//             body: Stack(
//               children: [
//                 const _LoginBackground(primary: primary),

//                 SafeArea(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 26),

//                         // Header
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: const [
//                                   Text(
//                                     'Welcome back 👋',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 28,
//                                       fontWeight: FontWeight.w800,
//                                       letterSpacing: .2,
//                                     ),
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'Sign in to continue to your account.',
//                                     style: TextStyle(
//                                       color: Colors.white70,
//                                       fontSize: 14.5,
//                                       height: 1.3,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const _DecorShapesPurpleModern(),
//                           ],
//                         ),

//                         const SizedBox(height: 26),

//                         // Glass card
//                         Container(
//                           padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(.92),
//                             borderRadius: BorderRadius.circular(18),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(.08),
//                                 blurRadius: 24,
//                                 offset: const Offset(0, 12),
//                               ),
//                             ],
//                             border: Border.all(
//                               color: Colors.white.withOpacity(.60),
//                             ),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Login',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               const SizedBox(height: 6),
//                               const Text(
//                                 'Use your email & password to sign in.',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 13.5,
//                                 ),
//                               ),
//                               const SizedBox(height: 18),

//                               // Email
//                               _ModernField(
//                                 label: 'Email',
//                                 controller: emailController,
//                                 hint: 'you@example.com',
//                                 keyboardType: TextInputType.emailAddress,
//                                 prefixIcon: Icons.mail_outline,
//                               ),
//                               const SizedBox(height: 14),

//                               // Password
//                               _ModernField(
//                                 label: 'Password',
//                                 controller: passwordController,
//                                 hint: '••••••••',
//                                 obscure: obscure,
//                                 prefixIcon: Icons.lock_outline,
//                                 suffix: IconButton(
//                                   onPressed: () =>
//                                       setState(() => obscure = !obscure),
//                                   icon: Icon(
//                                     obscure
//                                         ? Icons.visibility_off_outlined
//                                         : Icons.visibility_outlined,
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 10),

//                               Align(
//                                 alignment: Alignment.centerRight,
//                                 child: TextButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             ForgotPasswordScreen(),
//                                       ),
//                                     );
//                                   },
//                                   style: TextButton.styleFrom(
//                                     foregroundColor: primary,
//                                   ),
//                                   child: const Text(
//                                     'Forgot password?',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 6),

//                               // Button
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: primary,
//                                     foregroundColor: Colors.white,
//                                     elevation: 10,
//                                     shadowColor: primary.withOpacity(.35),
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 14,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                     ),
//                                   ),
//                                   onPressed: isLoading
//                                       ? null
//                                       : () {
//                                           if (!_validateAndToast()) return;
//                                           context
//                                               .read<AuthenticationBloc>()
//                                               .add(
//                                                 SignInRequested(
//                                                   email: emailController.text
//                                                       .trim(),
//                                                   password:
//                                                       passwordController.text,
//                                                 ),
//                                               );
//                                         },
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       if (isLoading) ...[
//                                         const SizedBox(
//                                           width: 18,
//                                           height: 18,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2.2,
//                                             valueColor:
//                                                 AlwaysStoppedAnimation<Color>(
//                                               Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         const Text(
//                                           'Signing in…',
//                                           style: TextStyle(
//                                             fontSize: 15.5,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                         ),
//                                       ] else ...[
//                                         const Text(
//                                           'LOGIN',
//                                           style: TextStyle(
//                                             fontSize: 15.5,
//                                             fontWeight: FontWeight.w800,
//                                             letterSpacing: .6,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         const Icon(
//                                           Icons.arrow_forward_rounded,
//                                           size: 20,
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 16),

//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Text(
//                                     "Don't have an account? ",
//                                     style: TextStyle(
//                                       color: Colors.black87,
//                                       fontSize: 14.5,
//                                     ),
//                                   ),
//                                   GestureDetector(
//                                     onTap: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               RoleSelectScreen(),
//                                         ),
//                                       );
//                                     },
//                                     child: const Text(
//                                       'Register now',
//                                       style: TextStyle(
//                                         color: primary,
//                                         fontWeight: FontWeight.w800,
//                                         fontSize: 14.5,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(height: 22),

//                         Center(
//                           child: Text(
//                             'TASKOON',
//                             style: TextStyle(
//                             fontFamily: 'Poppins',
//                               color: Colors.white.withOpacity(.75),
//                               fontWeight: FontWeight.w900,
//                               letterSpacing: 3,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _LoginBackground extends StatelessWidget {
//   const _LoginBackground({required this.primary});

//   final Color primary;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             primary,
//             primary.withOpacity(.85),
//             const Color(0xFF1B1B1F),
//           ],
//         ),
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             right: -90,
//             top: -70,
//             child: _BlurBlob(color: Colors.white.withOpacity(.18), size: 220),
//           ),
//           Positioned(
//             left: -70,
//             bottom: -90,
//             child: _BlurBlob(color: Colors.white.withOpacity(.10), size: 240),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BlurBlob extends StatelessWidget {
//   const _BlurBlob({required this.color, required this.size});

//   final Color color;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }

// class _ModernField extends StatelessWidget {
//   const _ModernField({
//     required this.label,
//     required this.controller,
//     required this.hint,
//     required this.prefixIcon,
//     this.keyboardType,
//     this.obscure = false,
//     this.suffix,
//   });

//   final String label;
//   final TextEditingController controller;
//   final String hint;
//   final IconData prefixIcon;
//   final TextInputType? keyboardType;
//   final bool obscure;
//   final Widget? suffix;

//   @override
//   Widget build(BuildContext context) {
//     const borderRadius = BorderRadius.all(Radius.circular(14));

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 13.5,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           obscureText: obscure,
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: const Color(0xFFF6F7FB),
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//             prefixIcon: Icon(prefixIcon),
//             suffixIcon: suffix,
//             enabledBorder: const OutlineInputBorder(
//               borderRadius: borderRadius,
//               borderSide: BorderSide(color: Color(0xFFE6E8F0)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: borderRadius,
//               borderSide: BorderSide(
//                 color: _LoginScreenState.primary.withOpacity(.55),
//                 width: 1.4,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// /// Modern decorative purple blocks (matches new header)
// class _DecorShapesPurpleModern extends StatelessWidget {
//   const _DecorShapesPurpleModern();

//   @override
//   Widget build(BuildContext context) {
//     const light = Color(0xFFE9DEFF);
//     const mid = Color(0xFFD4C4FF);
//     const dark = Color(0xFF7841BA);

//     Widget block(Color c, {double w = 84, double h = 26, double angle = .55}) {
//       return Transform.rotate(
//         angle: angle,
//         child: Container(
//           width: w,
//           height: h,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [c.withOpacity(.95), c.withOpacity(.65)],
//             ),
//             borderRadius: BorderRadius.circular(10),
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

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool _navigated = false; // ✅ prevent double navigation

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

          if (userId.isEmpty) {
            toastWidget('Login success but userId missing!', Colors.red);
            return;
          }

          if (_navigated) return;
          _navigated = true;

          final box = GetStorage();
          await box.write('userId', userId);

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

          toastWidget(
            'OTP Send to ${emailController.text.trim()}',
            Colors.green,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                isForgetFunctionality: false,
                email: emailController.text.trim(),
                userId: userId,
                phone: state.loginResponse?.result?.user?.phoneNumber
                        ?.toString() ??
                    '',
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
              textTheme:
                  Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                 // const _LoginBackground(primary: primary),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 26),

                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Welcome back 👋',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.black,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue to your account.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.grey,
                                        fontSize: 14.5,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const _DecorShapesPurpleModern(),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // Glass card
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.92),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(.60),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Use your email & password to sign in.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.black54,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Email
                                _ModernField(
                                  label: 'Email',
                                  controller: emailController,
                                  hint: 'you@example.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline,
                                ),
                                const SizedBox(height: 14),

                                // Password
                                _ModernField(
                                  label: 'Password',
                                  controller: passwordController,
                                  hint: '••••••••',
                                  obscure: obscure,
                                  prefixIcon: Icons.lock_outline,
                                  suffix: IconButton(
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
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
                                          builder: (context) =>
                                              ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: primary,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      elevation: 10,
                                      shadowColor: primary.withOpacity(.35),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            if (!_validateAndToast()) return;
                                            context
                                                .read<AuthenticationBloc>()
                                                .add(
                                                  SignInRequested(
                                                    email: emailController.text
                                                        .trim(),
                                                    password:
                                                        passwordController.text,
                                                  ),
                                                );
                                          },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isLoading) ...[
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Signing in…',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ] else ...[
                                          const Text(
                                            'LOGIN',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: .6,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.black87,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RoleSelectScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Register now',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          Center(
                            child: Text(
                              'TASKOON',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(.75),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withOpacity(.85),
            const Color(0xFF1B1B1F),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -70,
            child: _BlurBlob(color: Colors.white.withOpacity(.18), size: 220),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: _BlurBlob(color: Colors.white.withOpacity(.10), size: 240),
          ),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  const _ModernField({
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
            fontFamily: 'Poppins',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: const TextStyle(fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.black54,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffix,
            enabledBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Color(0xFFE6E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: _LoginScreenState.primary.withOpacity(.55),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modern decorative purple blocks (matches new header)
class _DecorShapesPurpleModern extends StatelessWidget {
  const _DecorShapesPurpleModern();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFE9DEFF);
    const mid = Color(0xFFD4C4FF);
    const dark = Color(0xFF7841BA);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .55}) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withOpacity(.95), c.withOpacity(.65)],
            ),
            borderRadius: BorderRadius.circular(10),
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
