import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taskoon/widgets/toast_widget.dart';

import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../screens/Tasker_Onboarding/personal_info.dart';
import '../Tasker_Onboarding/capture_selfie_screen.dart';

import 'package:flutter/material.dart';
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
    final loginResp = bloc.state.loginResponse;
    final userId = loginResp?.result?.user?.userId ?? '';
    // final email = loginResp?.result?.user?.userId ??
    //     ''; // ⚠️ Replace with actual email if needed Testing@123

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
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
              print('IS FROM FORGET PASSWORD FUCNTIONALITY');
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()),
              );
            }

            // Navigator.pushReplacement(
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

                // Verify button
                /*  SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isComplete ? purple : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isComplete ? 6 : 0,
                    ),
                    child: const Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),*/

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
                        'Get OTP on Phone', //Testing@123
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

                // Resend
                /*    Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: _onResendPressed,
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),*/
              ],
            ),
          ),
        );
      },
    );
  }
}


/**class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

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
  bool get _isComplete => (_otpCode?.length ?? 0) == 4;

  @override
  void initState() {
    super.initState();
    listenForCode(); // start SMS Retriever (no SMS permission required)
  }

  @override
  void dispose() {
    cancel(); // stop listening
    super.dispose();
  }

  @override
  void codeUpdated() {
    // Called by the mixin when SMS arrives. Defer state updates to after build.
    final newCode = code;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = newCode);
    });
  }

  void _onCodeChanged(String? code) {
    // PinFieldAutoFill may call this during its initState -> defer update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _otpCode = code);
    });
  }

  void _verify() {
    if (!_isComplete) return;
    // TODO: call your verify API with _otpCode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verifying OTP: $_otpCode')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

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

            // Title
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
              'Enter the 4-digit code sent to your phone',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),

            // OTP field card (purple theme) with SMS auto-fill
            Card(
              elevation: 0,
              color: lavender,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: PinFieldAutoFill(
                  codeLength: 4,
                  currentCode: _otpCode,
                  onCodeChanged: _onCodeChanged,
                  onCodeSubmitted: (_) => _verify(),
                  decoration: BoxLooseDecoration(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
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

            // Verify button
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    // _isComplete
                    //     ? _verify
                    //     :
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SelfieCaptureScreen()) //PersonalInfo()),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isComplete ? purple : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isComplete ? 4 : 0,
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Resend link (simple)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive the code? ",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/

/*class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Brand palette
  static const Color purple = Color(0xFF7841BA);
  static const Color gold = Color(0xFFD4AF37);
  static const Color lavender = Color(0xFFF3ECFF);

  final List<TextEditingController> _ctrs =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());

  bool get _isComplete => _ctrs.every((c) => c.text.isNotEmpty);
  String get _otp => _ctrs.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _ctrs) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < _ctrs.length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _verify() {
    if (_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verifying OTP: $_otp")),
      );
      // TODO: Navigate to next screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Image.asset(
              'assets/taskoon_logo.png',
              height: 160,
              width: 160,
            ),

            const SizedBox(height: 28),

            // Title
            Text(
              "OTP Verification",
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: purple,
                letterSpacing: .3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter the 4-digit code sent to your phone",
              style: t.bodyMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 36),

            // OTP fields inside a card
            Card(
              elevation: 0,
              color: lavender,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 28),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_ctrs.length, (i) {
                    return SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _ctrs[i],
                        focusNode: _nodes[i],
                        onChanged: (v) => _onChanged(v, i),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: purple.withOpacity(.2), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: purple, width: 2),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Verify button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isComplete ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isComplete ? purple : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isComplete ? 4 : 0,
                  ),
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Resend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? "),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("OTP resent")),
                    );
                  },
                  child: const Text(
                    "Resend",
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/

// class OtpVerificationScreen extends StatefulWidget {
//   const OtpVerificationScreen({super.key});

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   static const purple = Color(0xFF5B21B6);
//   static const cream = Color(0xFFFFF7E8);
//   static const gold = Color(0xFFB98F22);

//   final List<TextEditingController> controllers =
//       List.generate(4, (_) => TextEditingController());
//   final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

//   bool get isComplete =>
//       controllers.every((ctrl) => ctrl.text.trim().isNotEmpty);

//   @override
//   void dispose() {
//     for (var c in controllers) {
//       c.dispose();
//     }
//     for (var f in focusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   void _onChanged(String value, int index) {
//     if (value.isNotEmpty && index < 3) {
//       FocusScope.of(context).requestFocus(focusNodes[index + 1]);
//     } else if (value.isEmpty && index > 0) {
//       FocusScope.of(context).requestFocus(focusNodes[index - 1]);
//     }
//     setState(() {});
//   }

//   String get otpCode => controllers.map((c) => c.text).join();

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
//             const SizedBox(height: 18),

//             // Title
//             const Text(
//               'OTP Verification',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.deepPurple,
//                 fontSize: 22,
//                 letterSpacing: .5,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Enter the 4-digit code sent to your phone',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.black.withOpacity(.7),
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 28),

//             // OTP Fields
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(4, (i) {
//                 return SizedBox(
//                   width: 65,
//                   child: TextField(
//                     controller: controllers[i],
//                     focusNode: focusNodes[i],
//                     keyboardType: TextInputType.number,
//                     textAlign: TextAlign.center,
//                     maxLength: 1,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: 2,
//                     ),
//                     decoration: InputDecoration(
//                       counterText: '',
//                       filled: true,
//                       fillColor: cream,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: gold.withOpacity(.45)),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: gold, width: 1.6),
//                       ),
//                     ),
//                     onChanged: (val) => _onChanged(val, i),
//                   ),
//                 );
//               }),
//             ),
//             const SizedBox(height: 28),

//             // Continue Button
//             SizedBox(
//               height: 52,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor:
//                       isComplete ? purple : const Color(0xFFECEFF3),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 onPressed: isComplete
//                     ? () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => PersonalInfo()));
//                       }
//                     : null,
//                 child: Text('Verify',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 0.1,
//                         fontSize: 18)),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Resend
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Didn't receive code? ",
//                   style: TextStyle(fontWeight: FontWeight.w300, fontSize: 17),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     // TODO: Resend OTP action
//                   },
//                   child: const Text(
//                     'Resend',
//                     style: TextStyle(
//                         color: gold, fontWeight: FontWeight.w800, fontSize: 17),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
