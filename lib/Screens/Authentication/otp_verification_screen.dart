import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taskoon/Screens/Authentication/change_password_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';
import 'package:taskoon/widgets/toast_widget.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  static const Color primary = Color(0xFF7841BA);

  String? _otpCode;
  bool get _isComplete => (_otpCode?.length ?? 0) == 6;

  final storage = GetStorage();

  bool _navigated = false;
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

  String? _roleFromLogin(AuthenticationState state) {
    // ✅ uses your login model: loginResponse.result.user.type
    final role = state.loginResponse?.result?.user?.type;
    if (role == null) return null;
    final r = role.trim();
    return r.isEmpty ? null : r;
  }

  void _navigateByRoleFromLogin(AuthenticationState state) {
    if (_navigated) return;

    final role = _roleFromLogin(state);
    if (role == null) {
      toastWidget("Role not found. Please login again.", Colors.red);
      setState(() => _verifyPressed = false);
      return;
    }//Testing@123

    _navigated = true;
    storage.write("role", role);

    final normalized = role.toLowerCase();

    if (normalized == "customer" || normalized == "user") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserBottomNavBar()),
      );
      return;
    }

    if (normalized == "tasker") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TaskoonApp()),
      );
      return;
    }

    toastWidget("Unknown role: $role", Colors.red);
    _navigated = false;
    setState(() => _verifyPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listenWhen: (prev, curr) {
        final otpChanged = prev.status != curr.status || prev.response != curr.response;
        final errorChanged = prev.error != curr.error;
        return otpChanged || errorChanged;
      },
      listener: (context, state) {
        // -------------------- Failure --------------------
        if (state.status == AuthStatus.failure &&
            (state.error?.trim().isNotEmpty ?? false)) {
          toastWidget(state.error!, Colors.red);
          if (mounted) {
            setState(() {
              _verifyPressed = false;
              _navigated = false;
            });
          }
          return;
        }

        // -------------------- OTP Verified --------------------
        if (state.status == AuthStatus.success &&
            state.response?.message?.toString() == "Verified") {
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

          // ✅ Navigate using ONLY login model role
          _navigateByRoleFromLogin(state);
          return;
        }
      },
      builder: (context, state) {
        // ✅ loader ONLY for OTP verify flow
        final showLoading = _verifyPressed && state.status == AuthStatus.loading;

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

                          // ✅ OTP UI
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE6E8F0)),
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
                                bgColorBuilder: const FixedColorBuilder(Colors.white),
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
                                            AlwaysStoppedAnimation<Color>(Colors.white),
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
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
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
                              Expanded(child: Divider(color: Color(0xFFE6E8F0), height: 1)),
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
                              Expanded(child: Divider(color: Color(0xFFE6E8F0), height: 1)),
                            ],
                          ),

                          const SizedBox(height: 14),

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

                                      toastWidget(widget.phone, Colors.green);
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
          Positioned(top: 28, right: 10, child: pill(primary.withOpacity(.22), w: 58)),
          Positioned(top: 48, right: 2, child: pill(primary.withOpacity(.16), w: 44, h: 16)),
        ],
      ),
    );
  }
}
