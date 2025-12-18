import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/documents_screen.dart';
import '../../Models/services_group_model.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';

class ChooseServicesScreen extends StatefulWidget {
   ChooseServicesScreen({
    super.key,
    required this.groups,
    this.initialSelectedIds = const <int>{},
    this.onContinue,
    required this.selectedCertificatesCount
  });

  final List<ServiceGroup> groups;
  final Set<int> initialSelectedIds;
  final void Function(List<int> ids, List<String> labels)? onContinue;

  int selectedCertificatesCount;

  @override
  State<ChooseServicesScreen> createState() => _ChooseServicesScreenState();
}

class _ChooseServicesScreenState extends State<ChooseServicesScreen> {
  static const purple = Color(0xFF7841BA);

  late final List<ServiceGroup> groups = widget.groups;
  late final Set<int> selectedIds = {...widget.initialSelectedIds};

  late final Map<int, String> _idToLabel = {
    for (final g in groups) for (final it in g.items) it.id: it.name,
  };

  int get _totalEligibleServices {
    int sum = 0;
    for (final g in groups) {
      sum += g.items.length;
    }
    return sum;
  }

  void _pushSummaryToBloc() {
    context.read<AuthenticationBloc>().add(
          UpdateChooseServicesSummaryRequested(
            servicesSelected: selectedIds.length,
            totalEligibleServices: _totalEligibleServices,
certificationsSelected: widget.selectedCertificatesCount
            // certificationsSelected: you can pass a number here if you have it locally;
            // otherwise the bloc will use its own state fallback.
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    // Fire once after the first frame so the summary is available immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushSummaryToBloc());
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabels =
        selectedIds.map((id) => _idToLabel[id]!).toList(growable: false);

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
                      for (final it in g.items)
                        _ServiceRow(
                          label: it.name,
                          selected: selectedIds.contains(it.id),
                          onTap: () {
                            setState(() {
                              if (!selectedIds.add(it.id)) {
                                selectedIds.remove(it.id);
                              }
                            });
                            // 🔔 Update summary in bloc on each toggle
                            _pushSummaryToBloc();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),

          // —— Bottom Continue Bar ——
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: purple.withOpacity(.16), width: 1),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedIds.isNotEmpty) ...[
                      _SelectedSummary(
                        title: 'Selected Services (${selectedIds.length}):',
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
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () {
                                // Optionally push the latest summary once more before leaving
                                _pushSummaryToBloc();

                                final ids = selectedIds.toList(growable: false);
                                final labels = selectedLabels;

                                // Build selected ServiceItem list
                                final selectedItems = <ServiceItem>[];
                                for (final g in groups) {
                                  for (final it in g.items) {
                                    if (selectedIds.contains(it.id)) {
                                      selectedItems.add(it);
                                    }
                                  }
                                }

                                // Read docs from global bloc
                                final st = context.read<AuthenticationBloc>().state;
                                if (st.documentsStatus != DocumentsStatus.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(st.documentsError ?? 'Documents not ready')),
                                  );
                                  return;
                                }

                                // Filter docs for selected services
                                final selectedServiceIds = selectedIds.toSet();
                                final docsForSelected = st.documents
                                    .where((d) => selectedServiceIds.contains(d.serviceId))
                                    .toList();

                                debugPrint('✅ Docs loaded: ${st.documents.length}');
                                debugPrint('📄 Docs for selected: ${docsForSelected.length}');

                                if (widget.onContinue != null) {
                                  widget.onContinue!(ids, labels);
                                } else {

                                    final box = GetStorage();
      final savedUserId = box.read<String>('userId');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocumentsScreen(
                                        userId: savedUserId.toString(),
                                        selectedServices: selectedItems,
                                        selectedDocs: docsForSelected,
                                      ),
                                    ),
                                  );
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

/* ---------- Small widgets (unchanged) ---------- */

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
                Text(message, style: TextStyle(color: Colors.black.withOpacity(.70))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.count, required this.child});

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
                style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
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
  const _ServiceRow({required this.label, required this.selected, required this.onTap});

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
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
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
        border: Border.all(color: selected ? purple : const Color(0xFFE3DEF6), width: 2),
        color: selected ? purple : Colors.transparent,
      ),
      child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
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
      decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.items, required this.title});
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                        child: Text(items[i],
                            softWrap: true,
                            maxLines: null,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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

