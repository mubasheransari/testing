import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

import '../../Constants/constants.dart';
import '../../widgets/labeled_icon_widget.dart';
import '../../widgets/textfield_widget.dart';


// class PersonalInfo extends StatefulWidget {
//   const PersonalInfo({super.key});

//   @override
//   State<PersonalInfo> createState() => _PersonalInfoState();
// }

// class _PersonalInfoState extends State<PersonalInfo> {
//   final _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     const currentStep = 1;
//     const totalSteps = 7;
//     final progress = currentStep / totalSteps;

//     return BlocListener<AuthenticationBloc, AuthenticationState>(
//       listenWhen: (prev, curr) =>
//           prev.servicesError != curr.servicesError ||
//           prev.documentsError != curr.documentsError,
//       listener: (context, state) {
//         final err = state.servicesError ?? state.documentsError;
//         if (err != null && err.trim().isNotEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
//         }
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           toolbarHeight: 80,
//           automaticallyImplyLeading: false,
//           elevation: 0,
//           centerTitle: false,
//           titleSpacing: 20,
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Personal Info', style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 2),
//               Text(
//                 'Tasker Onboarding',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
//               ),
//             ],
//           ),
//           actions: [
//             Padding(
//               padding: const EdgeInsets.only(right: 20),
//               child: Text(
//                 '$currentStep/$totalSteps',
//                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
//               ),
//             ),
//           ],
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(36),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
//               child: Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(999),
//                     child: LinearProgressIndicator(
//                       value: progress,
//                       minHeight: 6,
//                       backgroundColor: Colors.grey,
//                       valueColor: const AlwaysStoppedAnimation(Constants.purple),
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Text(
//                         'Progress',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${(progress * 100).round()}% complete',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: SafeArea(
//           child: GestureDetector(
//             onTap: () => FocusScope.of(context).unfocus(),
//             child: LayoutBuilder(
//               builder: (context, cns) => SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     minHeight: (cns.maxHeight - 120).clamp(0, double.infinity),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Text(
//                         "Let's start by getting to know you better. We'll need some basic information to set up your profile.",
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.black54),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
//                         child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
//                           // You can drop buildWhen to be extra sure it rebuilds
//                           builder: (context, state) {
//                             final u = state.userDetails;
//                             final fullName = u?.fullName ?? '';
//                             final email = u?.email ?? '';
//                             final phone = u?.phone ?? '';

//                             return Form(
//                               key: _formKey,
//                               child: Column(
//                                 children: [
                             
//                                   const LabeledIcon(
//                                     label: 'Full Name',
//                                     icon: Icons.person_2_outlined,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Field(
//                                     key: ValueKey('fullName:$fullName'),
//                                     initialText: fullName,   // from state
//                                     hint: 'Enter your full name',
//                                     textInputAction: TextInputAction.next,
//                                     validator: _required,
//                                   ),

//                                   const SizedBox(height: 16),
//                                   const LabeledIcon(
//                                     label: 'Email Address',
//                                     icon: Icons.mail_outline,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Field(
//                                     key: ValueKey('email:$email'),
//                                     initialText: email,      // from state
//                                     hint: 'Enter your email address',
//                                     keyboardType: TextInputType.emailAddress,
//                                     textInputAction: TextInputAction.next,
//                                   ),

//                                   const SizedBox(height: 16),
//                                   const LabeledIcon(
//                                     label: 'Phone Number',
//                                     icon: Icons.call_outlined,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Field(
//                                     key: ValueKey('phone:$phone'),
//                                     initialText: phone,      // from state
//                                     hint: 'Enter your phone number',
//                                     keyboardType: TextInputType.phone,
//                                     textInputAction: TextInputAction.done,
//                                     validator: _required,
//                                     onSubmitted: (_) => _submit(),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         bottomNavigationBar: SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 color: Constants.purple,
//                 borderRadius: BorderRadius.circular(999),
//               ),
//               child: SizedBox(
//                 height: 56,
//                 child: TextButton(
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
//                   ),
//                   onPressed: _submit,
//                   child: const Text(
//                     'Continue',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w400,
//                       letterSpacing: 0.1,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

//   void _submit() {
//     if (!_formKey.currentState!.validate()) return;
//     Navigator.pushNamed(context, '/Certifications-screen');
//   }
// }



class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    const currentStep = 1;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (prev, curr) =>
          prev.servicesError != curr.servicesError ||
          prev.documentsError != curr.documentsError,
      listener: (context, state) {
        final err = state.servicesError ?? state.documentsError;
        if (err != null && err.trim().isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FB), // ✅ soft background (like home)
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F6FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Info',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3E1E69),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tasker Onboarding',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Poppins',
                      color: const Color(0xFF75748A),
                      fontSize: 12.5,
                    ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF5C2E91).withOpacity(.15),
                  ),
                ),
                child: Text(
                  '$currentStep/$totalSteps',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5C2E91),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  _ProgressCard(
                    progress: progress,
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, cns) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (cns.maxHeight - 120).clamp(0, double.infinity),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ Intro card (modern)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF5C2E91).withOpacity(.07),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.03),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C2E91)
                                    .withOpacity(.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF5C2E91),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Let's start by getting to know you better. We'll need some basic information to set up your profile.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.8,
                                  color: Color(0xFF75748A),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Form card (modern / home theme)
                      BlocBuilder<AuthenticationBloc, AuthenticationState>(
                        builder: (context, state) {
                          final u = state.userDetails;
                          final fullName = u?.fullName ?? '';
                          final email = u?.email ?? '';
                          final phone = u?.phone ?? '';

                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your details',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF3E1E69),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Make sure this matches your identity info.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Color(0xFF75748A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // ✅ Full Name
                                  const _ModernLabel(
                                    label: 'Full Name',
                                    icon: Icons.person_2_outlined,
                                  ),
                                  const SizedBox(height: 8),
                                  Field(
                                    key: ValueKey('fullName:$fullName'),
                                    initialText: fullName,
                                    hint: 'Enter your full name',
                                    textInputAction: TextInputAction.next,
                                    validator: _required,
                                  ),

                                  const SizedBox(height: 14),

                                  // ✅ Email
                                  const _ModernLabel(
                                    label: 'Email Address',
                                    icon: Icons.mail_outline,
                                  ),
                                  const SizedBox(height: 8),
                                  Field(
                                    key: ValueKey('email:$email'),
                                    initialText: email,
                                    hint: 'Enter your email address',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                  ),

                                  const SizedBox(height: 14),

                                  // ✅ Phone
                                  const _ModernLabel(
                                    label: 'Phone Number',
                                    icon: Icons.call_outlined,
                                  ),
                                  const SizedBox(height: 8),
                                  Field(
                                    key: ValueKey('phone:$phone'),
                                    initialText: phone,
                                    hint: 'Enter your phone number',
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    validator: _required,
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ✅ Bottom CTA (same action)
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C2E91).withOpacity(.20),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C2E91),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(context, '/Certifications-screen');
  }
}

/// ✅ Progress card like the home screen style
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  final double progress;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5C2E91).withOpacity(.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.02),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF75748A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}% complete',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF75748A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0EEF7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5C2E91)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StepPill(text: 'Step $currentStep'),
              const Spacer(),
              _StepPill(text: '$totalSteps steps'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5C2E91).withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF5C2E91).withOpacity(.15),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF5C2E91),
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// ✅ Label that matches your home theme (replaces LabeledIcon UI only)
class _ModernLabel extends StatelessWidget {
  const _ModernLabel({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF5C2E91).withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF5C2E91), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E1E69),
          ),
        ),
      ],
    );
  }
}
