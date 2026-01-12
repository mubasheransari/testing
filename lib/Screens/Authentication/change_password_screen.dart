import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Screens/Authentication/login_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../widgets/toast_widget.dart';

// class ChangePasswordScreen extends StatefulWidget {
//   const ChangePasswordScreen({
//     super.key,
//     required this.email,
//     required this.userId,
//   });

//   final String email;
//   final String userId;

//   @override
//   State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
// }

// class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
//   static const Color primary = Color(0xFF7841BA);
//   static const Color hintBg = Color(0xFFF4F5F7);

//   final newPassCtrl = TextEditingController();
//   final confirmPassCtrl = TextEditingController();

//   bool obscureNew = true;
//   bool obscureConfirm = true;

//   @override
//   void dispose() {
//     newPassCtrl.dispose();
//     confirmPassCtrl.dispose();
//     super.dispose();
//   }

//   OutlineInputBorder _border([Color c = Colors.transparent]) =>
//       OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: BorderSide(color: c),
//       );

//   Widget _label(String text) => Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Text(text,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//       );

//   Widget _filledField({
//     required TextEditingController controller,
//     required String hint,
//     required bool obscure,
//     required VoidCallback onVisibilityToggle,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscure,
//       onChanged: (_) => setState(() {}),
//       decoration: InputDecoration(
//         isDense: true,
//         filled: true,
//         fillColor: hintBg,
//         hintText: hint,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         suffixIcon: IconButton(
//           onPressed: onVisibilityToggle,
//           icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
//         ),
//         enabledBorder: _border(),
//         focusedBorder: _border(primary.withOpacity(.35)),
//       ),
//       style: const TextStyle(fontWeight: FontWeight.w600),
//     );
//   }

//   bool get _valid {
//     final p1 = newPassCtrl.text;
//     final p2 = confirmPassCtrl.text;

//     if (p1.isEmpty || p2.isEmpty) return false;
//     if (p1.length < 8) return false;
//     if (p1 != p2) return false;
//     return true;
//   }

//   void _submit() {
//     final p1 = newPassCtrl.text.trim();
//     final p2 = confirmPassCtrl.text.trim();

//     // granular validation + toasts
//     if (p1.isEmpty || p2.isEmpty) {
//       toastWidget('Please fill both fields.', Colors.redAccent);
//       return;
//     }
//     if (p1.length < 8) {
//       toastWidget('Password must be at least 8 characters.', Colors.redAccent);
//       return;
//     }
//     if (p1 != p2) {
//       toastWidget('Passwords do not match.', Colors.redAccent);
//       return;
//     }
//     // Testing@123

//     // Dispatch the bloc event (no URLs here) Testing@1234
//     context.read<AuthenticationBloc>().add(
//           ChangePassword(
//             userId: widget.userId, // keep if your API needs it
//             password: p1,
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthenticationBloc, AuthenticationState>(
//       //  listenWhen: (p, c) => p.resetPasswordStatus != c.resetPasswordStatus,
//       listener: (context, state) {
//         if (state.changePasswordStatus == ChangePasswordStatus.loading) {
//           //toastWidget('Updating password…', Colors.black87);
//         } else if (state.changePasswordStatus == ChangePasswordStatus.success) {
//           toastWidget('Password updated successfully', Colors.green);
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => LoginScreen()),
//             (Route<dynamic> route) => false,
//           );
//         } else if (state.changePasswordStatus == ChangePasswordStatus.failure) {
//           toastWidget(
//               state.error ?? 'Failed to update password', Colors.redAccent);
//         }
//       },
//       child: Builder(builder: (context) {
//         final isLoading = context.select((AuthenticationBloc b) =>
//             b.state.changePasswordStatus == ChangePasswordStatus.loading);

//         return Scaffold(
//           backgroundColor: Colors.white,
//           body: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header Testing@11223344
//                   const Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'CHANGE PASSWORD',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       SizedBox(
//                         width: 60,
//                         height: 3,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                             color: primary,
//                             borderRadius: BorderRadius.all(Radius.circular(2)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 22),

//                   // Intro + purple shapes
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Enter your new password and confirm to continue.',
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                       ),
//                       const _DecorShapesPurple(),
//                     ],
//                   ),
//                   const SizedBox(height: 28),

//                   _label('New Password'),
//                   _filledField(
//                     controller: newPassCtrl,
//                     hint: 'New Password',
//                     obscure: obscureNew,
//                     onVisibilityToggle: () =>
//                         setState(() => obscureNew = !obscureNew),
//                   ),
//                   const SizedBox(height: 14),

//                   _label('Confirm New Password'),
//                   _filledField(
//                     controller: confirmPassCtrl,
//                     hint: 'Confirm New Password',
//                     obscure: obscureConfirm,
//                     onVisibilityToggle: () =>
//                         setState(() => obscureConfirm = !obscureConfirm),
//                   ),

//                   const SizedBox(height: 22),

//                   Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.40,
//                       child: FilledButton(
//                         style: FilledButton.styleFrom(
//                           backgroundColor: primary,
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           elevation: 6,
//                           shadowColor: primary.withOpacity(.35),
//                         ),
//                         onPressed: _valid ? _submit : null,
//                         child: Text(
//                           isLoading ? 'Please wait…' : 'SUMBIT',
//                           style: const TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white,
//                             letterSpacing: .2,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   /* SizedBox(
//                     width: double.infinity,
//                     height: 52,
//                     child: FilledButton(
//                       style: FilledButton.styleFrom(
//                         backgroundColor:
//                             _valid ? primary : const Color(0xFFECEFF3),
//                         foregroundColor: _valid ? Colors.white : Colors.black54,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                         elevation: _valid ? 6 : 0,
//                         shadowColor: primary.withOpacity(.35),
//                       ),
//                       onPressed: _valid ? _submit : null,
//                       child: const Text(
//                         'SUBMIT',
//                         style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: .2,
//                         ),
//                       ),
//                     ),
//                   ),*/
//                 ],
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }

// /// Reuse your existing decorative widget to keep the theme identical
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


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  final String email;
  final String userId;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ✅ Theme tokens (match your LoginScreen feel)
  static const Color kPrimary = Color(0xFF7841BA);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBg = Color(0xFFF8F7FB);

  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  // ✅ NO logic change
  bool get _valid {
    final p1 = newPassCtrl.text;
    final p2 = confirmPassCtrl.text;

    if (p1.isEmpty || p2.isEmpty) return false;
    if (p1.length < 8) return false;
    if (p1 != p2) return false;
    return true;
  }

  void _submit() {
    final p1 = newPassCtrl.text.trim();
    final p2 = confirmPassCtrl.text.trim();

    // ✅ same validation behavior
    if (p1.isEmpty || p2.isEmpty) {
      toastWidget('Please fill both fields.', Colors.redAccent);
      return;
    }
    if (p1.length < 8) {
      toastWidget('Password must be at least 8 characters.', Colors.redAccent);
      return;
    }
    if (p1 != p2) {
      toastWidget('Passwords do not match.', Colors.redAccent);
      return;
    }

    // ✅ same bloc event
    context.read<AuthenticationBloc>().add(
          ChangePassword(
            userId: widget.userId,
            password: p1,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        // ✅ same success/failure behavior
        if (state.changePasswordStatus == ChangePasswordStatus.success) {
          toastWidget('Password updated successfully', Colors.green);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else if (state.changePasswordStatus == ChangePasswordStatus.failure) {
          toastWidget(
              state.error ?? 'Failed to update password', Colors.redAccent);
        }
      },
      child: Builder(
        builder: (context) {
          final isLoading = context.select((AuthenticationBloc b) =>
              b.state.changePasswordStatus == ChangePasswordStatus.loading);

          return Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
            ),
            child: Scaffold(
              backgroundColor: kBg,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Hero (same style like Login)
                      _ChangePasswordHero(email: widget.email),

                      const SizedBox(height: 14),

                      // ✅ Main card (same style like Login)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimary.withOpacity(.10)),
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
                            // Title row
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Change Password',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: kTextDark,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Enter and confirm your new password.',
                                        style: TextStyle(
                                          fontSize: 12.8,
                                          color: kMuted,
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
                              label: 'New Password',
                              controller: newPassCtrl,
                              hint: '••••••••',
                              obscure: obscureNew,
                              prefixIcon: Icons.lock_reset_rounded,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => obscureNew = !obscureNew),
                                icon: Icon(
                                  obscureNew
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: kMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            _ModernFieldWhite(
                              label: 'Confirm New Password',
                              controller: confirmPassCtrl,
                              hint: '••••••••',
                              obscure: obscureConfirm,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () => setState(
                                    () => obscureConfirm = !obscureConfirm),
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: kMuted,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed:
                                    (isLoading || !_valid) ? null : _submit,
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
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Updating…',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        'SUBMIT',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .6,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.check_rounded, size: 20),
                                    ],
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
                            color: kPrimary.withOpacity(.55),
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

/// ✅ Hero (matches Login Hero vibe)
class _ChangePasswordHero extends StatelessWidget {
  const _ChangePasswordHero({required this.email});

  final String email;

  static const Color kPrimary = _ChangePasswordScreenState.kPrimary;

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
            kPrimary.withOpacity(.12),
            kPrimary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: kPrimary.withOpacity(.12)),
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
              children: [
                const Text(
                  'Set a new password 🔐',
                  style: TextStyle(
                    color: Color(0xFF3E1E69),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a strong password and confirm it.',
                  style: TextStyle(
                    color: Color(0xFF75748A),
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                // email pill (UI only)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: kPrimary.withOpacity(.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 16, color: kPrimary),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  static const Color kPrimary = _ChangePasswordScreenState.kPrimary;

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
          Positioned(top: 6, right: 0, child: pill(kPrimary.withOpacity(.35))),
          Positioned(
              top: 28,
              right: 10,
              child: pill(kPrimary.withOpacity(.22), w: 58)),
          Positioned(
              top: 48,
              right: 2,
              child: pill(kPrimary.withOpacity(.16), w: 44, h: 16)),
        ],
      ),
    );
  }
}

/// ✅ Same field component style you used in Login (UI only)
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

  static const Color kPrimary = _ChangePasswordScreenState.kPrimary;

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
          onChanged: (_) {
            // ✅ keep same behavior: screen refreshes so _valid updates
            (context as Element).markNeedsBuild();
          },
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9AA0AF),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF75748A)),
            suffixIcon: suffix,
            enabledBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Color(0xFFE6E8F0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
