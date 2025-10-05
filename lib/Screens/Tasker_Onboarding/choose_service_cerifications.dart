import 'package:flutter/material.dart';
import '../../Constants/constants.dart';
import '../../Models/services_group_model.dart';


/// Same UI as your design. Receives groups from CertificationsScreen.
/// Optionally pass a set of initially-selected keys in the form "Group|Item".
class ChooseServicesScreen extends StatefulWidget {
  const ChooseServicesScreen({
    super.key,
    required this.groups,
    this.initialSelectedKeys = const <String>{},
    this.onContinue, // If null, will Navigator.pop with the selected labels.
  });

  final List<ServiceGroup> groups;
  final Set<String> initialSelectedKeys;
  final void Function(List<String> selectedLabels)? onContinue;

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  static const purple = Color(0xFF7841BA);

  late final List<ServiceGroup> groups = widget.groups;
  late final Set<String> selected = {...widget.initialSelectedKeys};

  @override
  Widget build(BuildContext context) {
    final selectedLabels =
        selected.map((k) => k.split('|')[1]).toList(growable: false);

    const currentStep = 3;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Your Services',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text("Tasker Onboarding",
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
                    valueColor: const AlwaysStoppedAnimation(purple),
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
                const Padding(
                  padding: EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
                  child: Text(
                    "Based on your certifications, you're eligible for these services. Select the ones you want to offer.",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main scroll
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 260),
            children: [
              const _InfoBanner(
                title: 'Certification-Based Eligibility',
                message:
                    'The services shown below are based on your selected certifications. You can only offer services that match your qualifications.',
              ),
              const SizedBox(height: 16),
              for (final g in groups) ...[
                _GroupCard(
                  title: g.title,
                  count: g.items.length,
                  child: Column(
                    children: [
                      for (final s in g.items)
                        _ServiceRow(
                          label: s,
                          selected: selected.contains('${g.title}|$s'),
                          onTap: () {
                            setState(() {
                              final key = '${g.title}|$s';
                              if (!selected.add(key)) selected.remove(key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),

          // Bottom sticky: Selected Services + Continue
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: purple.withOpacity(.16), width: 1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected.isNotEmpty) ...[
                      _SelectedSummary(
                        title: 'Selected Services (${selected.length}):',
                        items: selectedLabels,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: selected.isEmpty
                            ? null
                            : () {
                                if (widget.onContinue != null) {
                                  widget.onContinue!(selectedLabels);
                                } else {
                                  // Return to previous screen with the chosen labels
                                  Navigator.of(context).pop(selectedLabels);
                                }
                              },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            fontSize: 18,
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

/* ---------- UI widgets ---------- */

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4A7BD0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C59A6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: Colors.black.withOpacity(.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grade_rounded, size: 18, color: Color(0xFF9C8CE0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Badge('$count available'),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final border = selected ? purple : const Color(0xFFF1F0F7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SquareCheck(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline, size: 18, color: purple),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareCheck extends StatelessWidget {
  const _SquareCheck({required this.selected});
  final bool selected;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? purple : const Color(0xFFE3DEF6),
          width: 2,
        ),
        color: selected ? purple : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.items,
    required this.title,
  });

  final List<String> items;
  final String title;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DCFF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.separated(
                shrinkWrap: true,
                physics: items.length > 4
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[i],
                          softWrap: true,
                          maxLines: null,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}



/* ---------- Public model ---------- */
/*class ServiceGroup {
  final String title;
  final List<String> items;
  ServiceGroup(this.title, this.items);
}

/* ---------- Screen ---------- */
class ChooseServicesScreen extends StatefulWidget {
  const ChooseServicesScreen({
    super.key,
    required this.groups,
  });

  final List<ServiceGroup> groups;

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  static const purple = Color(0xFF7841BA);

  late final List<ServiceGroup> groups = widget.groups;

  /// store selections as "group|service"
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    final selectedLabels =
        selected.map((k) => k.split('|')[1]).toList(growable: false);

    const currentStep = 3;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Your Services',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text("Tasker Onboarding",
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
                      "Based on your certifications, you're eligible for these services. Select the ones you want to offer.",
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
          // Main scroll
          ListView(
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16, 260), // room for bottom bar
            children: [
              const _InfoBanner(
                title: 'Certification-Based Eligibility',
                message:
                    'The services shown below are based on your selected certifications. You can only offer services that match your qualifications.',
              ),
              const SizedBox(height: 16),
              for (final g in groups) ...[
                _GroupCard(
                  title: g.title,
                  count: g.items.length,
                  child: Column(
                    children: [
                      for (final s in g.items)
                        _ServiceRow(
                          label: s,
                          selected: selected.contains('${g.title}|$s'),
                          onTap: () {
                            setState(() {
                              final key = '${g.title}|$s';
                              if (!selected.add(key)) selected.remove(key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),

          // Bottom sticky: Selected Services + Continue
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: purple.withOpacity(.16), width: 1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                //  top: false,
                //  minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected.isNotEmpty) ...[
                      _SelectedSummary(
                        title: 'Selected Services (${selected.length}):',
                        items: selectedLabels,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: selected.isEmpty
                            ? null
                            : () {
                                final chosen = selectedLabels;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DocumentsScreen()));
                              },
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            fontSize: 18,
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

/* ---------- Widgets ---------- */

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4A7BD0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C59A6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: Colors.black.withOpacity(.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grade_rounded, size: 18, color: Color(0xFF9C8CE0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                maxLines: null, // allow multiple lines
                overflow: TextOverflow.visible, // no ellipsis
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Badge('$count available'),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final border = selected ? purple : const Color(0xFFF1F0F7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // align checkbox top
            children: [
              _SquareCheck(selected: selected),
              const SizedBox(width: 12),
              // 🔑 Constrain the label to available width so it wraps properly
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: null, // allow multiple lines
                  overflow: TextOverflow.visible, // no ellipsis
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline, size: 18, color: purple),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareCheck extends StatelessWidget {
  const _SquareCheck({required this.selected});
  final bool selected;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? purple : const Color(0xFFE3DEF6),
          width: 2,
        ),
        color: selected ? purple : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.items,
    required this.title,
  });

  final List<String> items;
  final String title;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DCFF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 👈 don’t force expand
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),

          // If few items → just show them.
          // If many → limit height with scroll.
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120), // 👈 cap size
              child: ListView.separated(
                shrinkWrap: true,
                physics: items.length > 4
                    ? const BouncingScrollPhysics() // scroll only if many
                    : const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[i],
                          softWrap: true,
                          maxLines: null,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/


/*class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({
    required this.items,
    required this.title,
  });

  final List<String> items;
  final String title;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4DCFF), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final e = items[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e,
                          softWrap: true,
                          maxLines: null,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/


/*class ServiceGroup {
  final String title;
  final List<String> items;
  ServiceGroup(this.title, this.items);
}

class ChooseServicesScreen extends StatefulWidget {
  const ChooseServicesScreen({
    super.key,
    required this.groups,
  });

  final List<ServiceGroup> groups; // groups to render

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  static const purple = Color(0xFF7841BA);

  late final List<ServiceGroup> groups = widget.groups;

  // store selections as "group|service"
  final Set<String> selected = {}; // ← starts EMPTY now

  @override
  Widget build(BuildContext context) {
    final selectedLabels = selected.map((k) => k.split('|')[1]).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: purple.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apps_rounded, color: purple, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Choose Your Services',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
            children: const [
              _InfoBanner(
                title: 'Certification-Based Eligibility',
                message:
                    'The services shown below are based on your selected certifications. You can only offer services that match your qualifications.',
              ),
              SizedBox(height: 16),
            ],
          ),
          // The grouped list below the info banner
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 130, 16, 180),
            children: [
              for (final g in groups) ...[
                _GroupCard(
                  title: g.title,
                  count: g.items.length,
                  child: Column(
                    children: [
                      for (final s in g.items)
                        _ServiceRow(
                          label: s,
                          selected: selected.contains('${g.title}|$s'),
                          onTap: () {
                            setState(() {
                              final key = '${g.title}|$s';
                              if (!selected.add(key)) selected.remove(key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: purple.withOpacity(.16), width: 1),
                ),
                boxShadow: const [
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Keep your design; messaging still computed above if you want to show it later
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            fontSize: 18,
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

/* ---------- Widgets ---------- */

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4A7BD0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF2C59A6))),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: Colors.black.withOpacity(.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard(
      {required this.title, required this.count, required this.child});
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grade_rounded, size: 18, color: Color(0xFF9C8CE0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                maxLines: null, // allow multi-line
                overflow: TextOverflow.visible, // don't ellipsize
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Text(
            //   title,
            //   style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            // ),
            const SizedBox(width: 8),
            _Badge('$count available'),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final border = selected ? purple : const Color(0xFFF1F0F7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // keep checkbox top-aligned
            children: [
              _SquareCheck(selected: selected),
              const SizedBox(width: 12),
              // 🔑 Constrain the label so it wraps and never overflows
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: null, // allow multi-line
                  overflow: TextOverflow.visible, // don't ellipsize
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
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

/*class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final border = selected ? purple : const Color(0xFFF1F0F7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            children: [
              _SquareCheck(selected: selected),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15.0, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}*/

class _SquareCheck extends StatelessWidget {
  const _SquareCheck({required this.selected});
  final bool selected;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? purple : const Color(0xFFE3DEF6),
          width: 2,
        ),
        color: selected ? purple : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(.65),
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.chips,
    required this.enabled,
    required this.onPressed,
  });

  final List<String> chips;
  final bool enabled;
  final VoidCallback onPressed;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final max = 6;
    final visible = chips.take(max).toList();
    final remaining = chips.length - visible.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  enabled ? purple.withOpacity(.20) : const Color(0xFFEDE6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    enabled ? purple.withOpacity(.55) : const Color(0xFFE2D8FF),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (chips.isEmpty)
                          Text('Continue',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(.55),
                                  fontWeight: FontWeight.w600)),
                        for (final c in visible) ...[
                          _chip(context, c),
                          const SizedBox(width: 8),
                        ],
                        if (remaining > 0) _chip(context, '+$remaining more'),
                        // for (final c in visible) ...[
                        //   _chip(c),
                        //   const SizedBox(width: 8),
                        // ],
                        // if (remaining > 0) _chip('+$remaining more'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: enabled ? purple : const Color(0xFFCFC2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label) {
    final maxChipWidth =
        MediaQuery.of(context).size.width * 0.6; // ~60% of screen

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE4DCFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // keep icon top-aligned
          children: [
            const Icon(Icons.check_circle, size: 14, color: purple),
            const SizedBox(width: 6),
            // Let the text wrap onto next line(s)
            Flexible(
              child: Text(
                label,
                softWrap: true,
                maxLines: null, // unlimited lines
                overflow: TextOverflow.visible, // don't ellipsize
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

/*  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4DCFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // 👈 align to top
        children: [
          const Icon(Icons.check_circle, size: 14, color: purple),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              softWrap: true, // 👈 allow wrapping
              overflow: TextOverflow.visible, // 👈 don’t cut off text
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}*/


/*class ServiceGroup {
  final String title;
  final List<String> items;
  ServiceGroup(this.title, this.items);
}

class ChooseServicesScreen extends StatefulWidget {
  const ChooseServicesScreen({
    super.key,
    required this.groups,
    this.preselectedServices = const [],
  });

  final List<ServiceGroup> groups;          // groups to render
  final List<String> preselectedServices;   // labels to preselect

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  static const purple = Color(0xFF7841BA);

  late final List<ServiceGroup> groups = widget.groups;

  // store selections as "group|service"
  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    // Preselect incoming labels across groups
    for (final g in groups) {
      for (final s in g.items) {
        if (widget.preselectedServices.contains(s)) {
          selected.add('${g.title}|$s');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabels = selected.map((k) => k.split('|')[1]).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: purple.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apps_rounded, color: purple, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Choose Your Services',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
            children: const [
              _InfoBanner(
                title: 'Certification-Based Eligibility',
                message:
                    'The services shown below are based on your selected certifications. You can only offer services that match your qualifications.',
              ),
              SizedBox(height: 16),
            ],
          ),
          // The grouped list below the info banner
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 180),
            children: [
              for (final g in groups) ...[
                _GroupCard(
                  title: g.title,
                  count: g.items.length,
                  child: Column(
                    children: [
                      for (final s in g.items)
                        _ServiceRow(
                          label: s,
                          selected: selected.contains('${g.title}|$s'),
                          onTap: () {
                            setState(() {
                              final key = '${g.title}|$s';
                              if (!selected.add(key)) selected.remove(key);
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),

          // Bottom sticky "Continue" with selected chips
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: _ContinueBar(
                  chips: selectedLabels,
                  enabled: selectedLabels.isNotEmpty,
                  onPressed: () {
                    // TODO: submit or navigate using `selectedLabels`
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Widgets ---------- */

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4A7BD0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF2C59A6))),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(color: Colors.black.withOpacity(.70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard(
      {required this.title, required this.count, required this.child});
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.grade_rounded, size: 18, color: Color(0xFF9C8CE0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 8),
            _Badge('$count available'),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final border = selected ? purple : const Color(0xFFF1F0F7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            children: [
              _SquareCheck(selected: selected),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15.0, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareCheck extends StatelessWidget {
  const _SquareCheck({required this.selected});
  final bool selected;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? purple : const Color(0xFFE3DEF6),
          width: 2,
        ),
        color: selected ? purple : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(.65),
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.chips,
    required this.enabled,
    required this.onPressed,
  });

  final List<String> chips;
  final bool enabled;
  final VoidCallback onPressed;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final max = 6;
    final visible = chips.take(max).toList();
    final remaining = chips.length - visible.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? purple.withOpacity(.20) : const Color(0xFFEDE6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled ? purple.withOpacity(.55) : const Color(0xFFE2D8FF),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (chips.isEmpty)
                          Text('Continue',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(.55),
                                  fontWeight: FontWeight.w600)),
                        for (final c in visible) ...[
                          _chip(c),
                          const SizedBox(width: 8),
                        ],
                        if (remaining > 0) _chip('+$remaining more'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: enabled ? purple : const Color(0xFFCFC2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4DCFF)),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, size: 14, color: purple),
          SizedBox(width: 6),
        ],
      ),
    );
  }
}
*/