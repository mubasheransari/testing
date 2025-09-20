import 'package:flutter/material.dart';
import '../../Constants/constants.dart';
import '../../theme/tokens.dart';

const currentStep = 3;
const totalSteps = 5;
final progress = currentStep / totalSteps;

class SelfieVerification extends StatelessWidget {
  static const route = '/selfie-verification';
  static const _primary = Color(0xFF8E7CFF); // lavender
  static const _primaryDark = Color(0xFF735DF2);

  const SelfieVerification({super.key});

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
            Text('Selfie Verification',
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
          // const StepIndicator(index: 4, total: 6),
          // const SizedBox(height: Tokens.s24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Tokens.r24),
                border: Border.all(color: Colors.black12),
              ),
              child: const Center(child: Icon(Icons.camera_alt, size: 64)),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Constants.purple),
              child: SizedBox(
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () {},
                  child: const Text('Open Camera',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                          fontSize: 20)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Constants.purple),
              child: SizedBox(
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/consent');
                  },
                  child: const Text('Skip for now',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                          fontSize: 20)),
                ),
              ),
            ),
          ),
          // const SizedBox(height: Tokens.s16),
          // PrimaryButton(label: 'Open camera', onPressed: () {}),
          // const SizedBox(height: Tokens.s8),
          // TextButton(
          //     onPressed: () => Navigator.pushNamed(context, '/consent'),
          //     child: const Text('Skip for now')),
        ],
      ),
    );
  }
}
