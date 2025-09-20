import 'package:flutter/material.dart';
import '../../Constants/constants.dart';
import '../../theme/tokens.dart';

const currentStep = 5;
const totalSteps = 5;
final progress = currentStep / totalSteps;

class ReviewSubmit extends StatelessWidget {
  static const route = '/review-submit';
  const ReviewSubmit({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review & Submit',
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
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(Tokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your details', style: t.textTheme.titleMedium),
                    const SizedBox(height: Tokens.s8),
                    const _RowItem(label: 'Name', value: 'John Doe'),
                    const _RowItem(label: 'DOB', value: '1990-01-01'),
                    const _RowItem(label: 'Phone', value: '+1 555 123 4567'),
                    const Divider(height: 32),
                    Text('Documents', style: t.textTheme.titleMedium),
                    const _RowItem(label: 'ID Front', value: 'Uploaded'),
                    const _RowItem(label: 'ID Back', value: 'Uploaded'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Tokens.s16),
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
                    Navigator.pushNamed(context, '/success');
                  },
                  child: const Text('Sumbit',
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                          fontSize: 20)),
                ),
              ),
            ),
          ),
          // PrimaryButton(
          //     label: 'Submit',
          //     onPressed: () => Navigator.pushNamed(context, '/success')),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.s8),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child:
                  Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () {}, child: const Text('Edit')),
        ],
      ),
    );
  }
}
