import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Screens/Login_Signup/login_screen.dart';
import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Blocs/auth_bloc/auth_state.dart';
import '../../Models/auth_model.dart';
import '../../Repository/auth_repository.dart';
import '../../widgets/toast_widget.dart';

class CreateAccountScreen extends StatefulWidget {
  final String role;
  const CreateAccountScreen({super.key, required this.role});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  static const Color primary = Color(0xFF7841BA);
  static const Color hintBg = Color(0xFFF4F5F7);

  final nameCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final abanCtrl = TextEditingController();
  final repNameCtrl = TextEditingController();
  final repPhoneCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final serviceCtrl = TextEditingController();

  bool obscure = true;
  bool agreed = false;

  late final AuthRepositoryHttp _repo;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepositoryHttp(
      baseUrl: 'http://192.3.3.187:83',
      endpoint: '/api/auth/signup',
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    companyCtrl.dispose();
    abanCtrl.dispose();
    repNameCtrl.dispose();
    repPhoneCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    addrCtrl.dispose();
    serviceCtrl.dispose();
    super.dispose();
  }

  bool get _isBusiness => widget.role.toLowerCase() == 'business';
  bool get _isTasker => widget.role.toLowerCase() == 'tasker';
  bool get _isUser => widget.role.toLowerCase() == 'user';

  // ---- helpers ----------------------------------------------------

  final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Simple password policy (adjust as needed)
  bool _isStrongPassword(String p) {
    if (p.length < 8) return false;
    final hasUpper = p.contains(RegExp(r'[A-Z]'));
    final hasLower = p.contains(RegExp(r'[a-z]'));
    final hasDigit = p.contains(RegExp(r'\d'));
    // final hasSpecial = p.contains(RegExp(r'[!@#\$%\^&\*\(\)\-\_\+=\.\,]'));
    return hasUpper && hasLower && hasDigit; // relax/tighten as desired
  }

  // Convert local AU number to +61… (keeps digits only, drops leading 0s)
  String _composeAuPhone(String local) {
    final digits = local.replaceAll(RegExp(r'[^0-9]'), '');
    final withoutLeadingZero = digits.replaceFirst(RegExp(r'^0+'), '');
    return '+61$withoutLeadingZero';
  }

  String _normalizeAbn(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), ''); // only digits

  // ---- validation + toasts ---------------------------------------

  /// Returns true if all checks pass; otherwise shows the **first** error with a toast and returns false.
  bool _validateAndToast() {
    // Common required
    if (!agreed) {
      toastWidget(
          'Please agree to the Terms & Privacy to continue.', Colors.redAccent);
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      toastWidget('Phone number is required.', Colors.redAccent);
      return false;
    }
    if (emailCtrl.text.trim().isEmpty) {
      toastWidget('Email address is required.', Colors.redAccent);
      return false;
    }
    if (!_emailRe.hasMatch(emailCtrl.text.trim())) {
      toastWidget('Please enter a valid email address.', Colors.redAccent);
      return false;
    }
    if (passCtrl.text.trim().isEmpty) {
      toastWidget('Password is required.', Colors.redAccent);
      return false;
    }
    if (!_isStrongPassword(passCtrl.text)) {
      toastWidget(
          'Password must be at least 8 chars with upper, lower, and number.',
          Colors.redAccent);
      return false;
    }

    // Phone quick sanity (after compose we expect at least +61 + 8–9 digits)
    final composed = _composeAuPhone(phoneCtrl.text);
    if (!composed.startsWith('+61') || composed.length < 10) {
      toastWidget(
          'Please enter a valid Australian phone number.', Colors.redAccent);
      return false;
    }

    // Role-specific
    if (_isUser) {
      if (nameCtrl.text.trim().isEmpty) {
        toastWidget('Full Name is required.', Colors.redAccent);
        return false;
      }
    } else if (_isTasker) {
      if (nameCtrl.text.trim().isEmpty) {
        toastWidget('Full Name is required.', Colors.redAccent);
        return false;
      }
      if (addrCtrl.text.trim().isEmpty) {
        toastWidget('Address is required for Tasker.', Colors.redAccent);
        return false;
      }
    } else if (_isBusiness) {
      if (companyCtrl.text.trim().isEmpty) {
        toastWidget('Company Name is required.', Colors.redAccent);
        return false;
      }
      if (abanCtrl.text.trim().isEmpty) {
        toastWidget('ABN is required.', Colors.redAccent);
        return false;
      }
      final abnOnlyDigits = _normalizeAbn(abanCtrl.text);
      if (abnOnlyDigits.length < 11) {
        // adjust length rule as per your backend (AU ABN is 11 digits typically)
        toastWidget('Please enter a valid ABN.', Colors.redAccent);
        return false;
      }
      if (repNameCtrl.text.trim().isEmpty) {
        toastWidget("Representative Name is required.", Colors.redAccent);
        return false;
      }
      if (repPhoneCtrl.text.trim().isEmpty) {
        toastWidget("Representative Phone is required.", Colors.redAccent);
        return false;
      }
      final repComposed = _composeAuPhone(repPhoneCtrl.text);
      if (!repComposed.startsWith('+61') || repComposed.length < 10) {
        toastWidget("Please enter a valid representative phone number.",
            Colors.redAccent);
        return false;
      }
    }

    return true;
  }

  // The old computed `valid` is kept only for button enable/disable
  bool get valid {
    final base = phoneCtrl.text.trim().isNotEmpty &&
        emailCtrl.text.trim().isNotEmpty &&
        passCtrl.text.trim().isNotEmpty &&
        agreed;

    if (_isUser) {
      return base && nameCtrl.text.trim().isNotEmpty;
    } else if (_isTasker) {
      return base &&
          nameCtrl.text.trim().isNotEmpty &&
          addrCtrl.text.trim().isNotEmpty;
    } else if (_isBusiness) {
      return base &&
          companyCtrl.text.trim().isNotEmpty &&
          abanCtrl.text.trim().isNotEmpty &&
          repNameCtrl.text.trim().isNotEmpty &&
          repPhoneCtrl.text.trim().isNotEmpty;
    }
    return base;
  }

  // ---- UI bits ---------------------------------------------------

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
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: hintBg,
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        suffixIcon: suffixIcon,
        enabledBorder: _border(),
        focusedBorder: _border(primary.withOpacity(.35)),
      ),
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  void _submit(BuildContext context) {
    // Validate with toast feedback
    if (!_validateAndToast()) return;

    final phone = _composeAuPhone(phoneCtrl.text);
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    final bloc = context.read<AuthenticationBloc>();

    if (_isUser) {
      bloc.add(RegisterUserRequested(
        fullName: nameCtrl.text.trim(),
        phoneNumber: phone,
        email: email,
        password: password,
        desiredService: const [],
        companyCategory: const [],
        companySubCategory: const [],
        abn: null,
      ));
    } else if (_isTasker) {
      bloc.add(RegisterTaskerRequested(
        fullName: nameCtrl.text.trim(),
        phoneNumber: phone,
        email: email,
        password: password,
        address: addrCtrl.text.trim(),
        desiredService: const [],
      ));
    } else {
      final repPhone = _composeAuPhone(repPhoneCtrl.text);
      final abn = _normalizeAbn(abanCtrl.text);

      // Replace with real IDs if your backend requires them
      const kCatId = '2';
      const kSubId = '3';

      bloc.add(RegisterCompanyRequested(
        fullName: companyCtrl.text.trim(),
        phoneNumber: phone,
        email: email,
        password: password,
        desiredService: const [],
        companyCategory: const [
          SelectableItem(id: kCatId, name: 'Default', isSelected: true),
        ],
        companySubCategory: const [
          SelectableItem(id: kSubId, name: 'Default', isSelected: true),
        ],
        abn: abn,
        representativeName: repNameCtrl.text.trim(),
        representativeNumber: repPhone,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthenticationBloc(_repo),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            final msg = state.response?.message ?? 'Account created';//Testing@123
            toastWidget(msg, Colors.green);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LoginScreen()));
          } else if (state.status == AuthStatus.failure) {
            toastWidget(state.error ?? 'Registration failed', Colors.redAccent);
          }
        },
        child: Builder(
          builder: (context) {
            final role = widget.role.toUpperCase();
            final status =
                context.select((AuthenticationBloc b) => b.state.status);
            final isLoading = status == AuthStatus.loading;

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CREATE ACCOUNT — $role',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const SizedBox(
                            width: 60,
                            height: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF7841BA),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // intro & shapes
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.role.toLowerCase() == 'business'
                                  ? 'Tell us about your company to get started.'
                                  : widget.role.toLowerCase() == 'tasker'
                                      ? 'Create your account to start earning.'
                                      : 'Create your account to get tasks done.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const _DecorShapesPurple(),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // role-specific fields
                      if (_isUser || _isTasker) ...[
                        _label('Full Name'),
                        _filledField(
                            controller: nameCtrl,
                            hint: 'Full Name',
                            keyboardType: TextInputType.name),
                        const SizedBox(height: 14),
                      ],
                      if (_isBusiness) ...[
                        _label('Company Name'),
                        _filledField(
                            controller: companyCtrl,
                            hint: 'Company Name',
                            keyboardType: TextInputType.name),
                        const SizedBox(height: 14),
                        _label('ABN'),
                        _filledField(
                            controller: abanCtrl,
                            hint: 'ABN',
                            keyboardType: TextInputType.text),
                        const SizedBox(height: 14),
                        _label("Company's Representative Name"),
                        _filledField(
                            controller: repNameCtrl,
                            hint: "Representative Name",
                            keyboardType: TextInputType.name),
                        const SizedBox(height: 14),
                        _label("Company's Representative Phone Number"),
                        _filledField(
                            controller: repPhoneCtrl,
                            hint: "Representative Phone Number",
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                      ],

                      // common fields
                      _label('Phone Number'),
                      Row(
                        children: [
                          Container(
                            width: 76,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: hintBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: const Text('+61',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _filledField(
                                controller: phoneCtrl,
                                hint: 'Phone Number',
                                keyboardType: TextInputType.phone),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _label('Email Address'),
                      _filledField(
                          controller: emailCtrl,
                          hint: 'Email Address',
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),

                      _label('Password'),
                      _filledField(
                        controller: passCtrl,
                        hint: 'Password',
                        obscure: obscure,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_isTasker) ...[
                        _label('Address (Required)'),
                        _filledField(
                            controller: addrCtrl,
                            hint: 'Address',
                            keyboardType: TextInputType.streetAddress),
                        const SizedBox(height: 14),
                        _label('Desired Service (Optional)'),
                        _filledField(
                            controller: serviceCtrl,
                            hint: 'Desired Service',
                            keyboardType: TextInputType.text),
                        const SizedBox(height: 14),
                      ],

                      // agreement
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => agreed = !agreed),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: agreed
                                        ? primary
                                        : const Color(0xFFCBD5E1),
                                    width: 2),
                                color: agreed ? primary : Colors.transparent,
                              ),
                              child: agreed
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text: 'I agree to the ',
                                      style: TextStyle(color: Colors.black87)),
                                  TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w700)),
                                  TextSpan(
                                      text: ' & ',
                                      style: TextStyle(color: Colors.black87)),
                                  TextSpan(
                                      text: 'Privacy',
                                      style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              style: TextStyle(fontSize: 14.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                valid ? primary : const Color(0xFFECEFF3),
                            foregroundColor:
                                valid ? Colors.white : Colors.black54,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: valid ? 6 : 0,
                            shadowColor: primary.withOpacity(.35),
                          ),
                          onPressed: (valid && !isLoading)
                              ? () => _submit(context)
                              : null,
                          child: Text(
                            isLoading ? 'Please wait…' : 'SUBMIT',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
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



// class CreateAccountScreen extends StatefulWidget {
//   final String role; 
//   const CreateAccountScreen({super.key, required this.role});

//   @override
//   State<CreateAccountScreen> createState() => _CreateAccountScreenState();
// }

// class _CreateAccountScreenState extends State<CreateAccountScreen> {
//   static const Color primary = Color(0xFF7841BA);
//   static const Color hintBg = Color(0xFFF4F5F7);

//   final nameCtrl = TextEditingController();
//   final companyCtrl = TextEditingController();
//   final abanCtrl = TextEditingController();
//   final repNameCtrl = TextEditingController();
//   final repPhoneCtrl = TextEditingController();
//   final phoneCtrl = TextEditingController();
//   final emailCtrl = TextEditingController();
//   final passCtrl = TextEditingController();
//   final addrCtrl = TextEditingController();
//   final serviceCtrl = TextEditingController();

//   bool obscure = true;
//   bool agreed = false;

//   late final AuthRepositoryHttp _repo;

//   @override
//   void initState() {
//     super.initState();
//     _repo = AuthRepositoryHttp(
//       baseUrl: 'http://192.3.3.187:83',
//       endpoint: '/api/auth/signup',
//     );
//   }

//   @override
//   void dispose() {
//     nameCtrl.dispose();
//     companyCtrl.dispose();
//     abanCtrl.dispose();
//     repNameCtrl.dispose();
//     repPhoneCtrl.dispose();
//     phoneCtrl.dispose();
//     emailCtrl.dispose();
//     passCtrl.dispose();
//     addrCtrl.dispose();
//     serviceCtrl.dispose();
//     super.dispose();
//   }

//   bool get _isBusiness => widget.role.toLowerCase() == 'business';
//   bool get _isTasker => widget.role.toLowerCase() == 'tasker';
//   bool get _isUser => widget.role.toLowerCase() == 'user';

//   String _composeAuPhone(String local) {
//     final digits = local.replaceAll(RegExp(r'[^0-9]'), '');
//     final withoutLeadingZero = digits.replaceFirst(RegExp(r'^0+'), '');
//     return '+61$withoutLeadingZero';
//   }

//   String _normalizeAbn(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

//   bool get valid {
//     final base = phoneCtrl.text.trim().isNotEmpty &&
//         emailCtrl.text.trim().isNotEmpty &&
//         passCtrl.text.trim().isNotEmpty &&
//         agreed;

//     if (_isUser) {
//       return base && nameCtrl.text.trim().isNotEmpty;
//     } else if (_isTasker) {
//       return base &&
//           nameCtrl.text.trim().isNotEmpty &&
//           addrCtrl.text.trim().isNotEmpty;
//     } else if (_isBusiness) {
//       return base &&
//           companyCtrl.text.trim().isNotEmpty &&
//           abanCtrl.text.trim().isNotEmpty &&
//           repNameCtrl.text.trim().isNotEmpty &&
//           repPhoneCtrl.text.trim().isNotEmpty;
//     }
//     return base;
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
//     TextInputType? keyboardType,
//     bool obscure = false,
//     Widget? suffixIcon,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscure,
//       onChanged: (_) => setState(() {}),
//       decoration: InputDecoration(
//         isDense: true,
//         filled: true,
//         fillColor: hintBg,
//         hintText: hint,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         suffixIcon: suffixIcon,
//         enabledBorder: _border(),
//         focusedBorder: _border(primary.withOpacity(.35)),
//       ),
//       style: const TextStyle(fontWeight: FontWeight.w600),
//     );
//   }

//   void _submit(BuildContext context) {
//     if (!valid) return;

//     final phone = _composeAuPhone(phoneCtrl.text);
//     final email = emailCtrl.text.trim();
//     final password = passCtrl.text;

//     final bloc = context.read<AuthenticationBloc>();

//     if (_isUser) {
//       bloc.add(RegisterUserRequested(
//         fullName: nameCtrl.text.trim(),
//         phoneNumber: phone,
//         email: email,
//         password: password,
//         desiredService: const [],
//         companyCategory: const [],
//         companySubCategory: const [],
//         abn: null,
//       ));
//     } else if (_isTasker) {
//       bloc.add(RegisterTaskerRequested(
//         fullName: nameCtrl.text.trim(),
//         phoneNumber: phone,
//         email: email,
//         password: password,
//         address: addrCtrl.text.trim(),
//         desiredService: const [],
//       ));
//     } else {
//       final repPhone = _composeAuPhone(repPhoneCtrl.text);
//       final abn = _normalizeAbn(abanCtrl.text);

//       const kCatId = '2';
//       const kSubId = '3';

//       bloc.add(RegisterCompanyRequested(
//         fullName: companyCtrl.text.trim(),
//         phoneNumber: phone,
//         email: email,
//         password: password,
//         desiredService: const [],
//         companyCategory: const [
//           SelectableItem(id: kCatId, name: 'Default', isSelected: true),
//         ],
//         companySubCategory: const [
//           SelectableItem(id: kSubId, name: 'Default', isSelected: true),
//         ],
//         abn: abn,
//         representativeName: repNameCtrl.text.trim(),
//         representativeNumber: repPhone,
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => AuthenticationBloc(_repo),
//       child: BlocListener<AuthenticationBloc, AuthenticationState>(
//         listenWhen: (p, c) => p.status != c.status,
//         listener: (context, state) {
//           if (state.status == AuthStatus.success) {
//             final msg = state.response?.message ?? 'Account created';
//             ScaffoldMessenger.of(context)
//                 .showSnackBar(SnackBar(content: Text(msg)));
//           } else if (state.status == AuthStatus.failure) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.error ?? 'Registration failed')),
//             );
//           }
//         },
//         child: Builder(
//           builder: (context) {
//             final role = widget.role.toUpperCase();
//             final status =
//                 context.select((AuthenticationBloc b) => b.state.status);
//             final isLoading = status == AuthStatus.loading;

//             return Scaffold(
//               backgroundColor: Colors.white,
//               body: SafeArea(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('CREATE ACCOUNT — $role',
//                               style: const TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.w700)),
//                           const SizedBox(height: 4),
//                           const SizedBox(
//                             width: 60,
//                             height: 3,
//                             child: DecoratedBox(
//                               decoration: BoxDecoration(
//                                 color: Color(0xFF7841BA),
//                                 borderRadius:
//                                     BorderRadius.all(Radius.circular(2)),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 22),

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               widget.role.toLowerCase() == 'business'
//                                   ? 'Tell us about your company to get started.'
//                                   : widget.role.toLowerCase() == 'tasker'
//                                       ? 'Create your account to start earning.'
//                                       : 'Create your account to get tasks done.',
//                               style: Theme.of(context).textTheme.bodyMedium,
//                             ),
//                           ),
//                           const _DecorShapesPurple(),
//                         ],
//                       ),
//                       const SizedBox(height: 28),

//                       if (_isUser || _isTasker) ...[
//                         _label('Full Name'),
//                         _filledField(
//                             controller: nameCtrl,
//                             hint: 'Full Name',
//                             keyboardType: TextInputType.name),
//                         const SizedBox(height: 14),
//                       ],
//                       if (_isBusiness) ...[
//                         _label('Company Name'),
//                         _filledField(
//                             controller: companyCtrl,
//                             hint: 'Company Name',
//                             keyboardType: TextInputType.name),
//                         const SizedBox(height: 14),
//                         _label('ABN'),
//                         _filledField(
//                             controller: abanCtrl,
//                             hint: 'ABN',
//                             keyboardType: TextInputType.text),
//                         const SizedBox(height: 14),
//                         _label("Company's Representative Name"),
//                         _filledField(
//                             controller: repNameCtrl,
//                             hint: "Representative Name",
//                             keyboardType: TextInputType.name),
//                         const SizedBox(height: 14),
//                         _label("Company's Representative Phone Number"),
//                         _filledField(
//                             controller: repPhoneCtrl,
//                             hint: "Representative Phone Number",
//                             keyboardType: TextInputType.phone),
//                         const SizedBox(height: 14),
//                       ],

//                       _label('Phone Number'),
//                       Row(
//                         children: [
//                           Container(
//                             width: 76,
//                             height: 48,
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               color: hintBg,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(color: Colors.transparent),
//                             ),
//                             child: const Text('+61',
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.w800,
//                                     color: Colors.black87)),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _filledField(
//                                 controller: phoneCtrl,
//                                 hint: 'Phone Number',
//                                 keyboardType: TextInputType.phone),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 14),

//                       _label('Email Address'),
//                       _filledField(
//                           controller: emailCtrl,
//                           hint: 'Email Address',
//                           keyboardType: TextInputType.emailAddress),
//                       const SizedBox(height: 14),

//                       _label('Password'),
//                       _filledField(
//                         controller: passCtrl,
//                         hint: 'Password',
//                         obscure: obscure,
//                         suffixIcon: IconButton(
//                           onPressed: () => setState(() => obscure = !obscure),
//                           icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       if (_isTasker) ...[
//                         _label('Address (Required)'),
//                         _filledField(
//                             controller: addrCtrl,
//                             hint: 'Address',
//                             keyboardType: TextInputType.streetAddress),
//                         const SizedBox(height: 14),
//                         _label('Desired Service (Optional)'),
//                         _filledField(
//                             controller: serviceCtrl,
//                             hint: 'Desired Service',
//                             keyboardType: TextInputType.text),
//                         const SizedBox(height: 14),
//                       ],

//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           GestureDetector(
//                             onTap: () => setState(() => agreed = !agreed),
//                             child: Container(
//                               width: 22,
//                               height: 22,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(4),
//                                 border: Border.all(
//                                     color: agreed ? primary : const Color(0xFFCBD5E1),
//                                     width: 2),
//                                 color: agreed ? primary : Colors.transparent,
//                               ),
//                               child: agreed
//                                   ? const Icon(Icons.check, size: 16, color: Colors.white)
//                                   : null,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           const Expanded(
//                             child: Text.rich(
//                               TextSpan(
//                                 children: [
//                                   TextSpan(text: 'I agree to the ', style: TextStyle(color: Colors.black87)),
//                                   TextSpan(text: 'Terms of Service', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
//                                   TextSpan(text: ' & ', style: TextStyle(color: Colors.black87)),
//                                   TextSpan(text: 'Privacy', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
//                                 ],
//                               ),
//                               style: TextStyle(fontSize: 14.5, height: 1.35),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 22),

//                       SizedBox(
//                         width: double.infinity,
//                         height: 52,
//                         child: FilledButton(
//                           style: FilledButton.styleFrom(
//                             backgroundColor: valid ? primary : const Color(0xFFECEFF3),
//                             foregroundColor: valid ? Colors.white : Colors.black54,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             elevation: valid ? 6 : 0,
//                             shadowColor: primary.withOpacity(.35),
//                           ),
//                           onPressed: (valid && !isLoading) ? () => _submit(context) : null,
//                           child: Text(
//                             isLoading ? 'Please wait…' : 'SUBMIT',
//                             style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: .2),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

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
//           decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
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

