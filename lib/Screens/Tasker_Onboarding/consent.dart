import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';

const currentStep = 4;
const totalSteps = 5;
final progress = currentStep / totalSteps;

class Consent extends StatefulWidget {
  static const route = '/consent';
  static const _primary = Color(0xFF8E7CFF);
  static const _primaryDark = Color(0xFF735DF2);
  const Consent({super.key});

  @override
  State<Consent> createState() => _ConsentState();
}

class _ConsentState extends State<Consent> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        // backgroundColor: Color(0xFFF7F6FB),
        // surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms & Consent',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Tasker KYC',
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
                    valueColor: const AlwaysStoppedAnimation(Constants.purple),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'By proceeding you agree to the processing of your data for certification onboarding. ',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),

          Padding(
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/review-submit');
                  },
                  child: const Text('Continue',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                          fontSize: 20)),
                ),
              ),
            ),
          ),
          // PrimaryButton(
          //     label: 'Continue',
          //     onPressed: accepted
          //         ? () => Navigator.pushNamed(context, '/review-submit')
          //         : null),
        ],
      ),
    );
  }
}
