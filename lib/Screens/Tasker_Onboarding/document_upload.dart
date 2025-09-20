import 'package:flutter/material.dart';
import '../../Constants/constants.dart';
import '../../theme/tokens.dart';

const currentStep = 2;
const totalSteps = 5;
final progress = currentStep / totalSteps;

class DocumentUpload extends StatelessWidget {
  const DocumentUpload({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        //surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload ID Card Pictures',
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
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UploadTile(label: 'Front of ID', icon: Icons.credit_card),
           SizedBox(height: Tokens.s12),
          _UploadTile(label: 'Back of ID', icon: Icons.credit_card_rounded),
        ],
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
                onPressed: () {
                  Navigator.pushNamed(context, '/selfie-verification');
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
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  const _UploadTile({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(Tokens.s16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: Tokens.s8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Tokens.s4),
              Text('Tap to upload',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
