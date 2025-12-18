import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Screens/Authentication/login_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../widgets/toast_widget.dart';

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
  static const Color primary = Color(0xFF7841BA);
  static const Color hintBg = Color(0xFFF4F5F7);

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

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _filledField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: hintBg,
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        suffixIcon: IconButton(
          onPressed: onVisibilityToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
        enabledBorder: _border(),
        focusedBorder: _border(primary.withOpacity(.35)),
      ),
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

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

    // granular validation + toasts
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
    // Testing@123

    // Dispatch the bloc event (no URLs here) Testing@1234
    context.read<AuthenticationBloc>().add(
          ChangePassword(
            userId: widget.userId, // keep if your API needs it
            password: p1,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      //  listenWhen: (p, c) => p.resetPasswordStatus != c.resetPasswordStatus,
      listener: (context, state) {
        if (state.changePasswordStatus == ChangePasswordStatus.loading) {
          //toastWidget('Updating password…', Colors.black87);
        } else if (state.changePasswordStatus == ChangePasswordStatus.success) {
          toastWidget('Password updated successfully', Colors.green);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else if (state.changePasswordStatus == ChangePasswordStatus.failure) {
          toastWidget(
              state.error ?? 'Failed to update password', Colors.redAccent);
        }
      },
      child: Builder(builder: (context) {
        final isLoading = context.select((AuthenticationBloc b) =>
            b.state.changePasswordStatus == ChangePasswordStatus.loading);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Testing@11223344
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHANGE PASSWORD',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        height: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Intro + purple shapes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Enter your new password and confirm to continue.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const _DecorShapesPurple(),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _label('New Password'),
                  _filledField(
                    controller: newPassCtrl,
                    hint: 'New Password',
                    obscure: obscureNew,
                    onVisibilityToggle: () =>
                        setState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 14),

                  _label('Confirm New Password'),
                  _filledField(
                    controller: confirmPassCtrl,
                    hint: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onVisibilityToggle: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
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
                        onPressed: _valid ? _submit : null,
                        child: Text(
                          isLoading ? 'Please wait…' : 'SUMBIT',
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

                  /* SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _valid ? primary : const Color(0xFFECEFF3),
                        foregroundColor: _valid ? Colors.white : Colors.black54,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: _valid ? 6 : 0,
                        shadowColor: primary.withOpacity(.35),
                      ),
                      onPressed: _valid ? _submit : null,
                      child: const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Reuse your existing decorative widget to keep the theme identical
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
