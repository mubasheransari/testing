import 'package:flutter/material.dart';

class Success extends StatelessWidget {
  static const route = '/success';
  const Success({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 88, color: Colors.green),
                const SizedBox(height: 16),
                Text('Submitted!', style: t.textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text(
                    'Your certification onboarding has been submitted for review. We\'ll notify you shortly.',
                    textAlign: TextAlign.center),
                //const SizedBox(height: 24),
                //  FilledButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Back to start')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
