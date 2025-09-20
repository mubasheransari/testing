import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  final String role; // 'user' | 'tasker' | 'business'
  const CreateAccountScreen({super.key, required this.role});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // --- Taskoon purple palette (same as LoginScreen) ---
  static const Color primary = Color(0xFF7841BA); // main purple
  static const Color primaryAlt =
      Color(0xFF8B59C6); // lighter purple (kept for future)
  static const Color hintBg = Color(0xFFF4F5F7);

  // Controllers
  final nameCtrl = TextEditingController();
  final companyCtrl = TextEditingController(); // company name (business)
  final abanCtrl = TextEditingController(); // ABAN (business)
  final repNameCtrl = TextEditingController(); // representative name (business)
  final repPhoneCtrl =
      TextEditingController(); // representative phone (business)
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final addrCtrl = TextEditingController(); // optional (tasker)
  final serviceCtrl = TextEditingController(); // desired service (tasker)

  bool obscure = true;
  bool agreed = false;

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
          serviceCtrl.text.trim().isNotEmpty; // address optional
    } else if (_isBusiness) {
      return base &&
          companyCtrl.text.trim().isNotEmpty &&
          abanCtrl.text.trim().isNotEmpty &&
          repNameCtrl.text.trim().isNotEmpty &&
          repPhoneCtrl.text.trim().isNotEmpty;
    }
    return base;
  }

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
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

  @override
  Widget build(BuildContext context) {
    final role = widget.role.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + purple underline (matches LoginScreen)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CREATE ACCOUNT — $role',
                    style: const TextStyle(
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
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Welcome + decorative purple blocks
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _isBusiness
                          ? 'Tell us about your company to get started.'
                          : _isTasker
                              ? 'Create your account to start earning.'
                              : 'Create your account to get tasks done.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const _DecorShapesPurple(),
                ],
              ),

              const SizedBox(height: 28),

              // --- Role-specific fields --------------------------------------------------

              // User/Tasker: Full Name
              if (_isUser || _isTasker) ...[
                _label('Full Name'),
                _filledField(
                  controller: nameCtrl,
                  hint: 'Full Name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 14),
              ],

              // Business: Company Name
              if (_isBusiness) ...[
                _label('Company Name'),
                _filledField(
                  controller: companyCtrl,
                  hint: 'Company Name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 14),
                _label('ABAN'),
                _filledField(
                  controller: abanCtrl,
                  hint: 'ABAN',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 14),
                _label("Company's Representative Name"),
                _filledField(
                  controller: repNameCtrl,
                  hint: "Representative Name",
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 14),
                _label("Company's Representative Phone Number"),
                _filledField(
                  controller: repPhoneCtrl,
                  hint: "Representative Phone Number",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
              ],

              // --- Common fields ---------------------------------------------------------

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
                    child: const Text(
                      '+61',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _filledField(
                      controller: phoneCtrl,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _label('Email Address'),
              _filledField(
                controller: emailCtrl,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              _label('Password'),
              _filledField(
                controller: passCtrl,
                hint: 'Password',
                obscure: obscure,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              const SizedBox(height: 14),

              // Tasker extras
              if (_isTasker) ...[
                _label('Address (Optional)'),
                _filledField(
                  controller: addrCtrl,
                  hint: 'Address (Optional)',
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: 14),
                _label('Desired Service'),
                _filledField(
                  controller: serviceCtrl,
                  hint: 'Desired Service',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 14),
              ],

              // Agreement
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
                          color: agreed ? primary : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
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
                            style: TextStyle(color: Colors.black87),
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' & ',
                            style: TextStyle(color: Colors.black87),
                          ),
                          TextSpan(
                            text: 'Privacy',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 14.5, height: 1.35),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: valid ? primary : const Color(0xFFECEFF3),
                    foregroundColor: valid ? Colors.white : Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: valid ? 6 : 0,
                    shadowColor: primary.withOpacity(.35),
                  ),
                  onPressed: valid
                      ? () {
                          // TODO: Submit payload or navigate next
                          // Example: Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account submitted')),
                          );
                        }
                      : null,
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-right decorative angled rectangles — purple tones (same visual family as LoginScreen).
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


// class CreateAccountScreen extends StatefulWidget {
//   String role;
//   CreateAccountScreen({super.key, required this.role});

//   @override
//   State<CreateAccountScreen> createState() => _CreateAccountScreenState();
// }

// class _CreateAccountScreenState extends State<CreateAccountScreen> {
//   static const purple = Color(0xFF5B21B6);
//   static const cream = Color(0xFFFFF7E8); // soft beige like screenshot
//   static const gold = Color(0xFFB98F22);

//   final nameCtrl = TextEditingController();
//   final phoneCtrl = TextEditingController();
//   final emailCtrl = TextEditingController();
//   final passCtrl = TextEditingController();
//   final addrCtrl = TextEditingController();
//   final serviceCtrl = TextEditingController();
//   bool agreed = false;

//   bool get valid =>
//       nameCtrl.text.trim().isNotEmpty &&
//       phoneCtrl.text.trim().isNotEmpty &&
//       emailCtrl.text.trim().isNotEmpty &&
//       passCtrl.text.trim().isNotEmpty &&
//       serviceCtrl.text.trim().isNotEmpty &&
//       agreed;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
//           children: [
//             // Logo
//             Center(
//               child: Image.asset(
//                 'assets/taskoon_logo.png',
//                 height: 108,
//                 width: 108,
//               ),
//             ),
//             //  const SizedBox(height: 18),

//             // Title
//             const Text(
//               'CREATE YOUR ACCOUNT',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.deepPurple,
//                 fontSize: 22,
//                 letterSpacing: .5,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//             const SizedBox(height: 18),

//             // Full name
//             widget.role == "user" || widget.role == "tasker"
//                 ? _filledField(
//                     controller: nameCtrl,
//                     hint: 'Full Name',
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             const SizedBox(height: 12),

//             widget.role == "business"
//                 ? _filledField(
//                     controller: nameCtrl,
//                     hint: 'Company Name',
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             widget.role == "business" ? const SizedBox(height: 18) : SizedBox(),

//             widget.role == "business"
//                 ? _filledField(
//                     controller: nameCtrl,
//                     hint: 'ABAN',
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             widget.role == "business" ? const SizedBox(height: 18) : SizedBox(),
//             // Phone (country code + input)
//             Row(
//               children: [
//                 Container(
//                   width: 84,
//                   height: 54,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     color: cream,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: gold.withOpacity(.45)),
//                   ),
//                   child: const Text(
//                     '+61',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w800,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _filledField(
//                     controller: phoneCtrl,
//                     hint: 'Phone Number',
//                     keyboardType: TextInputType.phone,
//                     onChanged: (_) => setState(() {}),
//                   ),
//                 ),
//               ],
//             ),
//             widget.role == "business" ? const SizedBox(height: 12) : SizedBox(),

//             widget.role == "business"
//                 ? _filledField(
//                     controller: emailCtrl,
//                     hint: "Company's Representative Name",
//                     keyboardType: TextInputType.emailAddress,
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),

//             const SizedBox(height: 12),
//             widget.role == "business"
//                 ? _filledField(
//                     controller: emailCtrl,
//                     hint: "Company's Representative Phone Number",
//                     keyboardType: TextInputType.emailAddress,
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             const SizedBox(height: 12),
//             _filledField(
//               controller: emailCtrl,
//               hint: 'Email Address',
//               keyboardType: TextInputType.emailAddress,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: 12),

//             _filledField(
//               controller: passCtrl,
//               hint: 'Password',
//               obscure: true,
//               onChanged: (_) => setState(() {}),
//             ),
//             const SizedBox(height: 12),

//             widget.role == "tasker"
//                 ? _filledField(
//                     controller: addrCtrl,
//                     hint: 'Address (Optional)',
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             widget.role == "tasker" ? const SizedBox(height: 12) : SizedBox(),

//             widget.role == "tasker"
//                 ? _filledField(
//                     controller: serviceCtrl,
//                     hint: 'Desired Service',
//                     onChanged: (_) => setState(() {}),
//                   )
//                 : SizedBox(),
//             const SizedBox(height: 16),

//             // Agreement
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 GestureDetector(
//                   onTap: () => setState(() => agreed = !agreed),
//                   child: Container(
//                     width: 22,
//                     height: 22,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(4),
//                       border: Border.all(
//                         color: agreed ? purple : const Color(0xFFCBD5E1),
//                         width: 2,
//                       ),
//                       color: agreed ? purple : Colors.transparent,
//                     ),
//                     child: agreed
//                         ? const Icon(Icons.check, size: 16, color: Colors.white)
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: RichText(
//                     text: TextSpan(
//                       style: const TextStyle(
//                         color: Colors.black87,
//                         fontSize: 14.5,
//                         height: 1.35,
//                       ),
//                       children: const [
//                         TextSpan(text: 'I agree to the '),
//                         TextSpan(
//                           text: 'Terms of Service',
//                           style: TextStyle(
//                             color: Color(0xFFB98F22),
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         TextSpan(text: ' & '),
//                         TextSpan(
//                           text: 'Privacy',
//                           style: TextStyle(
//                             color: Color(0xFFB98F22),
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 18),

//             // Continue
//             SizedBox(
//               height: 52,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: Colors
//                       .deepPurple, //valid ? purple : const Color(0xFFECEFF3),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 onPressed: () {},
//                 // onPressed: valid
//                 //     ? () {
//                 //         // TODO: submit
//                 //       }
//                 //     : null,
//                 child: Text('Sumbit',
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                         letterSpacing: 0.1,
//                         fontSize: 18)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

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
