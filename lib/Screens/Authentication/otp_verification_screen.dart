import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taskoon/Screens/Authentication/change_password_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/personal_info.dart';
import 'package:taskoon/Screens/User_booking/user_booking_home.dart';
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

  var storage = GetStorage();


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

    var isActive=   storage.read("isActive");
    var isOnboardingRequired = storage.read("isOnboardingRequired");

    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loading) {
          // toastWidget(
          //     "Please wait! While we're verifying your account!", Colors.green);
        } else if (state.status == AuthStatus.success) {
          if (state.response?.message == "Verified") {
            if (widget.isForgetFunctionality == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(
                          email: widget.email, userId: widget.userId)));
            } 
            
            else {
            print("ELSE CONDITION");
            print("ELSE CONDITION");
            print("ELSE CONDITION");
            storage.write("role", state.userDetails!.userRole);

/*if(isActive == false){

  context.read<AuthenticationBloc>().add(GetUserStatusRequested(
    userId: state.userDetails!.userId.toString(),
    email: state.userDetails!.email.toString(),
    phone: state.userDetails!.phone.toString(),
  ));
}
else if(isActive == true){
  */
 if(state.userDetails!.userRole == "Customer"){
         print("Customer");
            print("Customer");
            print("Customer");
  //   context.read<AuthenticationBloc>().add(GetUserStatusRequested(
  //   userId: state.userDetails!.userId.toString(),
  //   email: state.userDetails!.email.toString(),
  //   phone: state.userDetails!.phone.toString(),
  // ));
   Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserBookingHome()),
              );

 }
 else  if(state.userDetails!.userRole == "Tasker"){
     print("Tasker");
            print("Tasker");
            print("Tasker");
  //   context.read<AuthenticationBloc>().add(GetUserStatusRequested(
  //   userId: state.userDetails!.userId.toString(),
  //   email: state.userDetails!.email.toString(),
  //   phone: state.userDetails!.phone.toString(),
  // ));//Testing@123
 //if(isOnboardingRequired == true){
   Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TaskoonApp() //PersonalInfo() //TaskoonApp()
                ),
              );
 //}
//  else{
//      Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const TaskoonApp()),
//               );
//  }
 }
}

          //  }

          } else {}
        }
        if (state.status == AuthStatus.failure &&
            (state.error?.isNotEmpty ?? false)) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(state.error!)),
          // );
          toastWidget(state.error!, Colors.red);
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

                    BlocConsumer<AuthenticationBloc, AuthenticationState>(
                      listenWhen: (prev, curr) =>
                          prev.error != curr.error ||
                          prev.response !=
                              curr.response || 
                          prev.status !=
                              curr.status,
                      listener: (context, state) {
                        final err = state.error?.trim();
                        if (err != null && err.isNotEmpty) {
                          toastWidget(err, Colors.red);
                          // ScaffoldMessenger.of(context)
                          //   ..hideCurrentSnackBar()
                          //   ..showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }

                        // Show server message on success payload, even if it's the same text each time
                        final res = state.response;
                        final bodyMsg = res?.message?.trim(); //Testing@1234
                        if (res?.isSuccess == true &&
                            bodyMsg != null &&
                            bodyMsg.isNotEmpty) {
                          toastWidget(bodyMsg, Colors.green);
                          // ScaffoldMessenger.of(context)
                          //   ..hideCurrentSnackBar()
                          //   ..showSnackBar(SnackBar(content: Text(bodyMsg)));
                        }
                      },
                      builder: (context, state) {
                        final isBusy =
                            state.status == AuthStatus.loading; // optional
                        return GestureDetector(
                          onTap: isBusy ? null : _onResendPressed,
                          child: Opacity(
                            opacity: isBusy ? 0.6 : 1,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    /*    BlocConsumer<AuthenticationBloc, AuthenticationState>(
                      // Fire listener when either error changes OR the response.message changes
                      listenWhen: (prev, curr) {
                        final prevMsg = prev.response?.message?.trim();
                        final currMsg = curr.response?.message?.trim();
                        return prev.error != curr.error || prevMsg != currMsg;
                      },
                      listener: (context, state) {
                        final err = state.error?.trim();
                        if (err != null && err.isNotEmpty) {
                          // show error
                          // ScaffoldMessenger.of(context)
                          //   ..hideCurrentSnackBar()
                          //   ..showSnackBar(SnackBar(content: Text(err)));//Testing@1234
                          toastWidget(err, Colors.red);
                          return;
                        }
                        print(state.response?.message?.trim());

                        final bodyMsg = state.response?.message?.trim();
                        final ok = state.response?.isSuccess == true;

                        // Show server message when API payload is success (covers:
                        // {"isSuccess":true,"message":"OTP code request already sent.",...})
                        if (ok && bodyMsg != null && bodyMsg.isNotEmpty) {
                          // ScaffoldMessenger.of(context)
                          //   ..hideCurrentSnackBar()
                          //   ..showSnackBar(SnackBar(content: Text(bodyMsg)));
                          toastWidget(bodyMsg, Colors.orange);
                        }
                      },
                      builder: (context, state) {
                        final isBusy =
                            state.status == AuthStatus.loading; // optional
                        return GestureDetector(
                          onTap: isBusy ? null : _onResendPressed,
                          child: Opacity(
                            opacity: isBusy ? 0.6 : 1,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),*/

                    // GestureDetector(
                    //   onTap: _onResendPressed,
                    //   child: const Text(
                    //     'Resend',
                    //     style: TextStyle(
                    //         color: Colors.deepPurple,
                    //         fontWeight: FontWeight.w500,
                    //         fontSize: 16),
                    //   ),
                    // ),
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
