import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

import '../../Constants/constants.dart';
import '../../widgets/labeled_icon_widget.dart';
import '../../widgets/textfield_widget.dart';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefetch for next screens: services + service documents.
    // Do it after first frame so context.read is safe and we don’t double-fire on hot reloads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AuthenticationBloc>();
      final state = bloc.state;

      if (state.servicesStatus == ServicesStatus.initial) {
        bloc.add(LoadServicesRequested());
      }
      if (state.documentsStatus == DocumentsStatus.initial) {
        bloc.add(LoadServiceDocumentsRequested());
      }
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Info',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('Tasker Onboarding',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text('$currentStep/$totalSteps',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.black54)),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey,
                      valueColor:
                          const AlwaysStoppedAnimation(Constants.purple),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Progress',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54)),
                      const Spacer(),
                      Text('${(progress * 100).round()}% complete',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54)),
                    ],
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cns.maxHeight - 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Let's start by getting to know you better. We'll need some basic information to set up your profile.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 10, right: 10, top: 30),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const LabeledIcon(
                                  label: 'Full Name',
                                  icon: Icons.person_2_outlined),
                              const SizedBox(height: 8),
                              Field(
                                controller: _fullName,
                                hint: 'Enter your full name',
                                textInputAction: TextInputAction.next,
                                validator: _required,
                              ),
                              const SizedBox(height: 16),
                              const LabeledIcon(
                                  label: 'Email Address',
                                  icon: Icons.mail_outline),
                              const SizedBox(height: 8),
                              Field(
                                controller: _email,
                                hint: 'Enter your email address',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : (RegExp(r'.+@.+').hasMatch(v)
                                        ? null
                                        : 'Invalid email'),
                              ),
                              const SizedBox(height: 16),
                              const LabeledIcon(
                                  label: 'Phone Number',
                                  icon: Icons.call_outlined),
                              const SizedBox(height: 8),
                              Field(
                                controller: _phone,
                                hint: 'Enter your phone number',
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                validator: _required,
                                onSubmitted: (_) => _submit(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Constants.purple,
                borderRadius: BorderRadius.circular(999),
              ),
              child: SizedBox(
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                      fontSize: 20,
                    ),
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


// class PersonalInfo extends StatefulWidget {
//   const PersonalInfo({super.key});

//   @override
//   State<PersonalInfo> createState() => _PersonalInfoState();
// }

// class _PersonalInfoState extends State<PersonalInfo> {
//   final _formKey = GlobalKey<FormState>();
//   final _fullName = TextEditingController();
//   final _email = TextEditingController();
//   final _phone = TextEditingController();

//   @override
//   void dispose() {
//     _fullName.dispose();
//     _email.dispose();
//     _phone.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     const currentStep = 1;
//     const totalSteps = 7;
//     final progress = currentStep / totalSteps;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         toolbarHeight: 80,
//         automaticallyImplyLeading: false,
//         elevation: 0,
//         // surfaceTintColor: Colors.transparent,
//         centerTitle: false,
//         titleSpacing: 20,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Personal Info',
//                 style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 2),
//             Text('Tasker Onboarding',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(color: Colors.black54)),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: Text('$currentStep/$totalSteps',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyLarge
//                     ?.copyWith(color: Colors.black54)),
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(36),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
//             child: Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(999),
//                   child: LinearProgressIndicator(
//                     value: progress,
//                     minHeight: 6,
//                     backgroundColor: Colors.grey,
//                     valueColor: const AlwaysStoppedAnimation(Constants.purple),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Text('Progress',
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.black54)),
//                     const Spacer(),
//                     Text('${(progress * 100).round()}% complete',
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.black54)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: GestureDetector(
//           onTap: () => FocusScope.of(context).unfocus(),
//           child: LayoutBuilder(
//             builder: (context, cns) => SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: cns.maxHeight - 120),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       "Let's start by getting to know you better. We'll need some basic information to set up your profile.",
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodyMedium
//                           ?.copyWith(color: Colors.black54),
//                     ),
//                     //const SizedBox(height: 20),
//                     Padding(
//                       padding: EdgeInsets.only(left: 10, right: 10, top: 30),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           children: [
//                             const LabeledIcon(
//                                 label: 'Full Name',
//                                 icon: Icons.person_2_outlined),
//                             const SizedBox(height: 8),
//                             Field(
//                               controller: _fullName,
//                               hint: 'Enter your full name',
//                               textInputAction: TextInputAction.next,
//                               validator: _required,
//                             ),
//                             const SizedBox(height: 16),
//                             const LabeledIcon(
//                                 label: 'Email Address',
//                                 icon: Icons.mail_outline),
//                             const SizedBox(height: 8),
//                             Field(
//                               controller: _email,
//                               hint: 'Enter your email address',
//                               keyboardType: TextInputType.emailAddress,
//                               textInputAction: TextInputAction.next,
//                               validator: (v) => (v == null || v.isEmpty)
//                                   ? 'Required'
//                                   : (RegExp(r'.+@.+').hasMatch(v)
//                                       ? null
//                                       : 'Invalid email'),
//                             ),
//                             const SizedBox(height: 16),
//                             const LabeledIcon(
//                                 label: 'Phone Number',
//                                 icon: Icons.call_outlined),
//                             const SizedBox(height: 8),
//                             Field(
//                               controller: _phone,
//                               hint: 'Enter your phone number',
//                               keyboardType: TextInputType.phone,
//                               textInputAction: TextInputAction.done,
//                               validator: _required,
//                               onSubmitted: (_) => _submit(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       // Sticky gradient CTA that matches the design vibe
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//           child: DecoratedBox(
//             decoration: BoxDecoration(
//               color: Constants.purple,
//               // gradient: LinearGradient(
//               //     colors: [Constants.primary, Constants.primaryDark]),
//               borderRadius: BorderRadius.circular(999),
//               // boxShadow: const [
//               //   BoxShadow(
//               //       color: Color(0x338E7CFF),
//               //       offset: Offset(0, 8),
//               //       blurRadius: 24),
//               // ],
//             ),
//             child: SizedBox(
//               height: 56,
//               child: TextButton(
//                 style: TextButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(999)),
//                 ),
//                 onPressed: _submit,
//                 child: const Text('Continue',
//                     style: TextStyle(
//                         fontWeight: FontWeight.w400,
//                         letterSpacing: 0.1,
//                         fontSize: 20)),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? _required(String? v) =>
//       (v == null || v.trim().isEmpty) ? 'Required' : null;

//   void _submit() {
//     if (!_formKey.currentState!.validate()) return;
//     Navigator.pushNamed(context, '/Certifications-screen');
//   }
// }
