import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/training_matertial_screen.dart';

import '../../Constants/constants.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    this.certification = 0,
    this.processing = 5,
  });

  final double certification;
  final double processing;

  static const purple = Color(0xFF7841BA);
  static const bg = Color(0xFFF9F7FF);
  static const cardBorder = Color(0xFFEFEFF6);

  @override
  Widget build(BuildContext context) {
    final total = certification + processing;

    const currentStep = 5;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 130,
        automaticallyImplyLeading: false,
        elevation: 0,
        // surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: Theme.of(context).textTheme.titleLarge),
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
                Padding(
                  padding:
                      const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
                  child: Text(
                      "Complete your certification payment to proceed with the onboarding process.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _OrderSummaryCard(
                certification: certification,
                processing: processing,
                total: total,
              ),
              const SizedBox(height: 16),
              const _SuccessBanner(
                title: 'Payment Completed Successfully',
                message:
                    'Your certification payment has been processed. You can now proceed to the next step.',
              ),
            ],
          ),

          // Bottom actions
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    // Previous (ghost)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: Color(0xFFE5E7EB), width: 1),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Previous',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Continue (purple)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TrainingMaterialsScreen()));
                        },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------- Widgets ------------------- */

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.certification,
    required this.processing,
    required this.total,
  });

  final double certification;
  final double processing;
  final double total;

  static const cardBorder = Color(0xFFEFEFF6);

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: Colors.black.withOpacity(.06));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _row(
            'Certification',
            '\$${certification.toStringAsFixed(0)}',
            sub: 'Includes training materials and certification exam',
          ),
          divider,
          _row('Processing Fee', '\$${processing.toStringAsFixed(0)}'),
          divider,
          _row('Total', '\$${total.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? sub, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                    )),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sub,
                      style: TextStyle(
                        color: Colors.black.withOpacity(.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1), // soft green bg
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFB7E4C7)), // subtle green border
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // circular green check
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
