import 'package:flutter/material.dart';

import '../../Constants/constants.dart';
import 'application_review_screen.dart';

class TrainingMaterialsScreen extends StatefulWidget {
  const TrainingMaterialsScreen({super.key});

  @override
  State<TrainingMaterialsScreen> createState() =>
      _TrainingMaterialsScreenState();
}

class _TrainingMaterialsScreenState extends State<TrainingMaterialsScreen> {
  static const purple = Color(0xFF7841BA);

  late List<TrainingModule> modules = [
    TrainingModule(
      title: 'Safety Guidelines and Best Practices',
      subtitle: 'Learn essential safety protocols and risk management',
      duration: '45 min',
      icon: Icons.play_circle_fill_rounded,
      completed: false,
    ),
    TrainingModule(
      title: 'Customer Service Excellence',
      subtitle: 'Delivering exceptional customer experiences',
      duration: '30 min',
      icon: Icons.play_circle_fill_rounded,
      completed: false,
    ),
    TrainingModule(
      title: 'Legal and Compliance Requirements',
      subtitle: 'Understanding regulations and legal obligations',
      duration: '25 min',
      icon: Icons.description_rounded,
      completed: false,
    ),
  ];

  void _markCompleted(int index) {
    setState(() => modules[index] = modules[index].copyWith(completed: true));
  }

  @override
  Widget build(BuildContext context) {
    final total = modules.length;
    final completed = modules.where((m) => m.completed).length;
    final allDone = completed == total;
    final progress = total == 0 ? 0.0 : completed / total;

    const currentStep = 6;
    const totalSteps = 7;
    final progressss = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
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
            Text('Training Materials',
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
                    Text('${(progressss * 100).round()}% complete',
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
                      "Complete the required training modules to finish your certification process.",
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Progress card
          _ProgressCard(
            completed: completed,
            total: total,
            progress: progress,
            allDone: allDone,
          ),
          const SizedBox(height: 18),

          // Modules
          for (var i = 0; i < modules.length; i++) ...[
            _ModuleCard(
              module: modules[i],
              onStart: () {
                // TODO: launch your player here; call _markCompleted(i) on real completion
                _markCompleted(i);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Success banner when done
          if (allDone) ...[
            const SizedBox(height: 4),
            const _SuccessBanner(
              title: 'Training Complete!',
              message:
                  "Congratulations! You've completed all required training modules.",
            ),
          ],
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
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
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ApplicationReviewScreen()));
                    },
                    child: Text(
                      'Complete Training',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Widgets ---------------- */

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
    required this.allDone,
  });

  final int completed;
  final int total;
  final double progress;
  final bool allDone;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final badgeText = '$completed/$total Completed';
    final message = allDone
        ? 'All training modules completed! You can now proceed to the final step.'
        : '${total - completed} modules remaining';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECEBFA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Training Progress',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFECEBFA),
              valueColor: const AlwaysStoppedAnimation(purple),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: allDone
                  ? const Color(0xFF16A34A)
                  : Colors.black.withOpacity(.65),
              fontWeight: allDone ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onStart});
  final TrainingModule module;
  final VoidCallback onStart;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final leftIcon = module.completed
        ? Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle,
                color: Color(0xFF16A34A), size: 26),
          )
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(module.icon, color: const Color(0xFF6366F1), size: 26),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECEBFA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftIcon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _DurationPill(text: module.duration),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  module.subtitle,
                  style: TextStyle(color: Colors.black.withOpacity(.65)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          module.completed
              ? _CompletedBadge()
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    side: const BorderSide(color: Color(0xFFE1E0F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.open_in_new,
                      size: 16, color: Color(0xFF6D28D9)),
                  label: const Text(
                    'Start',
                    style: TextStyle(
                        color: Color(0xFF6D28D9), fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.text});
  final String text;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 14, color: purple),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF667085)),
          SizedBox(width: 6),
          Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF16A34A), fontWeight: FontWeight.w800)),
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

/* ---------------- Model ---------------- */

class TrainingModule {
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final bool completed;

  TrainingModule({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.completed,
  });

  TrainingModule copyWith({bool? completed}) => TrainingModule(
        title: title,
        subtitle: subtitle,
        duration: duration,
        icon: icon,
        completed: completed ?? this.completed,
      );
}
