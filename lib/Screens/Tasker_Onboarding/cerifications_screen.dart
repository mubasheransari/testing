import 'package:flutter/material.dart';

import '../../Blocs/auth_bloc/auth_bloc.dart';
import '../../Blocs/auth_bloc/auth_event.dart';
import '../../Constants/constants.dart';
import '../../Models/services_group_model.dart';
import '../../Models/services_ui_model.dart';
import 'choose_service_cerifications.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});
  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  static const purple = Color(0xFF7841BA);

  /// Track which certificationIds the user toggled on this screen.
  final Set<int> _selectedCertificationIds = {};

  @override
  void initState() {
    super.initState();
    // Kick off loading services → AuthenticationBloc maps API into certification groups.
    context.read<AuthenticationBloc>().add(LoadServicesRequested());
  }

  @override
  Widget build(BuildContext context) {
    const currentStep = 2;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: _buildAppBar(context, progress, currentStep, totalSteps),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        buildWhen: (prev, curr) =>
            prev.servicesStatus != curr.servicesStatus ||
            prev.serviceGroups != curr.serviceGroups ||
            prev.servicesError != curr.servicesError,
        builder: (context, state) {
          if (state.servicesStatus == ServicesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.servicesStatus == ServicesStatus.failure) {
            return Center(
              child: Text(state.servicesError ?? 'Failed to load services'),
            );
          }

          // state.serviceGroups is a List<CertificationGroup> from your Bloc/State.
          final groups = state.serviceGroups;

          // Build UI cards for each certification group
          final uiCategories = groups.map(_vmFromGroup).toList();

          // Selected CertificationGroups (for continue action)
          final selectedGroups = groups
              .where((g) => _selectedCertificationIds.contains(g.id))
              .toList();

          return Stack(
            children: [
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
                itemCount: uiCategories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) {
                  final uiCat = uiCategories[i];
                  final certificationId = groups[i].id;
                  final isSelected =
                      _selectedCertificationIds.contains(certificationId);

                  return _CertCard(
                    category: uiCat,
                    isSelected: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          _selectedCertificationIds.add(certificationId);
                        } else {
                          _selectedCertificationIds.remove(certificationId);
                        }
                      });
                    },
                  );
                },
              ),

              // Bottom sticky bar
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
                    child: SizedBox(
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
                       onPressed: selectedGroups.isEmpty
    ? null
    : () async {
        // Map your selected CertificationGroup -> ServiceGroup with IDs
        final List<ServiceGroup> groupsForNext = selectedGroups.map((g) {
          return ServiceGroup(
            id: g.id,            // certificationId
            title: g.name,       // certificationName
            items: g.services.map((s) {
              // API fields: serviceId, serviceName
              return ServiceItem(id: s.id, name: s.name);
            }).toList(),
          );
        }).toList();

        // Push and get back the IDs
        final result = await Navigator.push<List<int>>(
          context,
          MaterialPageRoute(
            builder: (_) => ChooseServicesScreen(
              groups: groupsForNext,
              initialSelectedIds: const <int>{}, // preselect if you want
            ),
          ),
        );

        if (result != null) {
          final selectedServiceIds = result; // ← 👈 your list of IDs
          // do whatever you need (e.g., save to state or submit)
          // print(selectedServiceIds);
        }
      },
                        child: const Text(
                          'Continue to Service Selection',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, double progress, int currentStep, int totalSteps) {
    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 150,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Certifications',
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
                  "Select all the certifications and licenses you currently hold. This will determine which services you're eligible to offer.",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Mapping helpers ----------
  /// Convert a CertificationGroup (from Bloc) into a UI card model.
  CertCategory _vmFromGroup(CertificationGroup g) {
    final ui = _uiForCertification(g.name);
    final tags = g.services.map((s) => s.name).toList();
    return CertCategory(
      id: g.id.toString(),
      title: g.name,
      subtitle: ui.subtitle,
      icon: ui.icon,
      iconBg: ui.iconBg,
      tags: tags,
    );
    // NOTE: We do NOT create ServiceGroup here to avoid type duplication.
  }

  _CertUI _uiForCertification(String name) {
    switch (name.toLowerCase()) {
      case 'cleaning':
        return _CertUI(
          subtitle:
              'Licensed for cleaning, maintenance, repairs, and home improvement',
          icon: Icons.cleaning_services,
          iconBg: const Color(0xFF5C6FFF),
        );
      case 'driving services(with and without car)':
      case 'drive services (with and without car)':
        return _CertUI(
          subtitle:
              'Certified for medical assistance, elderly care, and wellness services',
          icon: Icons.directions_car,
          iconBg: const Color(0xFFFF3B30),
        );
      case 'furniture assembly':
        return _CertUI(
          subtitle:
              'Qualified for consulting, legal, accounting, and administrative work',
          icon: Icons.build,
          iconBg: const Color(0xFF00C853),
        );
      case 'garden services':
        return _CertUI(
          subtitle:
              'Licensed for delivery, moving, and transportation services',
          icon: Icons.grass,
          iconBg: const Color(0xFFFF6D00),
        );
      case 'babysitting services':
        return _CertUI(
          subtitle:
              'Certified to provide tutoring, training, and educational services',
          icon: Icons.child_friendly,
          iconBg: const Color(0xFF6A00FF),
        );
      case 'pet services':
        return _CertUI(
          subtitle:
              'Certified for event planning, catering, and hospitality services',
          icon: Icons.groups_rounded,
          iconBg: const Color(0xFFFF2D55),
        );
      case 'construction':
        return _CertUI(
          subtitle:
              'Certified for event planning, catering, and hospitality services',
          icon: Icons.construction_rounded,
          iconBg: const Color(0xFF795548),
        );
      case 'corporate':
        return _CertUI(
          subtitle:
              'Certified for event planning, catering, and hospitality services',
          icon: Icons.business_center_rounded,
          iconBg: const Color(0xFF2962FF),
        );
      case 'hospitality & events':
        return _CertUI(
          subtitle:
              'Certified for event planning, catering, and hospitality services',
          icon: Icons.event_rounded,
          iconBg: const Color(0xFFAB47BC),
        );
      default:
        return _CertUI(
          subtitle: 'Eligible services based on your certifications',
          icon: Icons.grade_rounded,
          iconBg: const Color(0xFF9C8CE0),
        );
    }
  }
}

/* ---------- Local VM & widgets (no ServiceGroup here!) ---------- */

class _CertUI {
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  _CertUI({required this.subtitle, required this.icon, required this.iconBg});
}

class CertCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final List<String> tags;

  CertCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.tags,
  });
}

class _CertCard extends StatelessWidget {
  const _CertCard({
    required this.category,
    required this.isSelected,
    required this.onChanged,
  });

  final CertCategory category;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? purple : const Color(0xFFE9E4FF);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? purple.withOpacity(.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(bg: category.iconBg, icon: category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        style: TextStyle(
                          height: 1.25,
                          color: Colors.black.withOpacity(.65),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(!isSelected),
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? purple : const Color(0xFFDBD5FF),
                        width: 2,
                      ),
                      color: isSelected ? purple : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Chips
            _ChipsRow(tags: category.tags),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.bg, required this.icon});
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ChipsRow extends StatefulWidget {
  const _ChipsRow({required this.tags});
  final List<String> tags;

  @override
  State<_ChipsRow> createState() => _ChipsRowState();
}

class _ChipsRowState extends State<_ChipsRow> {
  bool expanded = false;
  static const pillColor = Color(0xFFF1EEFF);
  static const pillText = Color(0xFF3B2A68);

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? widget.tags : widget.tags.take(4).toList();
    final remaining = widget.tags.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(t, style: const TextStyle(color: pillText)),
          ),
        if (remaining > 0)
          GestureDetector(
            onTap: () => setState(() => expanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+$remaining more',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}


/*class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});
  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  static const purple = Color(0xFF7841BA);
  static const gold = Color(0xFFD4AF37);

  final categories = <CertCategory>[
    CertCategory(
      id: 'home',
      title: 'Cleaning',
      subtitle:
          'Licensed for cleaning, maintenance, repairs, and home improvement',
      icon: Icons.handyman_rounded,
      iconBg: const Color(0xFF5C6FFF),
      tags: [
        'Home Cleaning(Standard / Deep)',
        'Ease-of-Lease Cleaning',
        'Carpet & Upholstery Cleaning',
        'Car Cleaning & Detailing (Mobile)',
        'Laundry - Washed & Fold (Pickup & Delivery)',
      ],
    ),
    CertCategory(
      id: 'health',
      title: 'Driving Services(with and without car)',
      subtitle:
          'Certified for medical assistance, elderly care, and wellness services',
      icon: Icons.favorite_rounded,
      iconBg: const Color(0xFFFF3B30),
      tags: [
        'Chauffeur Services (with car)',
        'Chauffeur Services (with Six seater)',
        'Personal Driver (your car)',
        'Grocery & Small-Item Delivery (E-scotter)',
        'Grocery & Small-Item Delivery (Car)',
        'Grocery & Small-Item Delivery (Van)'
      ],
    ),
    CertCategory(
      id: 'business',
      title: 'Furniture Assembly',
      subtitle:
          'Qualified for consulting, legal, accounting, and administrative work',
      icon: Icons.work_rounded,
      iconBg: const Color(0xFF00C853),
      tags: [
        'Home Furniture Assembly',
        'Handyperson (Non-licensed tasks only)',
        'Furniture Moving',
        'Helper (moving)'
      ],
    ),
    CertCategory(
      id: 'transport',
      title: 'Garden services',
      subtitle: 'Licensed for delivery, moving, and transportation services',
      icon: Icons.directions_car_rounded,
      iconBg: const Color(0xFFFF6D00),
      tags: [
        'Lawn Mowing & Edging',
        'Hedge Trimming & Pruning',
        'Garden Cleaning & Waste Removal'
      ],
    ),
    CertCategory(
      id: 'education',
      title: 'Babysitting Services',
      subtitle:
          'Certified to provide tutoring, training, and educational services',
      icon: Icons.school_rounded,
      iconBg: const Color(0xFF6A00FF),
      tags: ['Nanny'],
    ),
    CertCategory(
      id: 'perservices',
      title: 'Pet Services',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: ['Dog Walking', 'Pet Sitting & Home Visits', 'Mobile Pet Grooming'],
    ),
    CertCategory(
      id: 'construction',
      title: 'Construction',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Construction Labour',
        'Forklift Operator',
        'Construction Admin',
        'Construction Coordinator',
        'Traffic Controller',
        'Construction Office cleaner'
      ],
    ),
    CertCategory(
      id: 'corporate',
      title: 'Corporate',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Admin',
        'Coordinator',
        'Social Media Assistants',
        'Tech Support',
        'Office Cleaning',
        'Office Furniture Assembly',
        'Corporate/Office Driver Hire',
        'Carpet, Sofa/Upholstery Cleaning',
        'Chauffeur Services (with car)',
        'Trimming & Plant Care',
        'Small Items delivery (Car)',
        'Small Items delivery (Van)'
      ],
    ),
    CertCategory(
      id: 'Hospitality&Events',
      title: 'Hospitality & Events',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Waitstaff & Baristas',
        'Event Setup Assistants',
        'Kitchen Hands',
        'Security Staff',
        'Commercial Cleaner'
      ],
    ),
  ];

  final selected = <String>{};

  @override
  Widget build(BuildContext context) {
    const currentStep = 2;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;
    final selectedCats =
        categories.where((c) => selected.contains(c.id)).toList();
    final totalEligibleServices =
        selectedCats.fold<int>(0, (s, c) => s + c.tags.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
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
            Text('Your Certifications',
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
                      "Select all the certifications and licenses you currently hold. This will determine which services you're eligible to offer.",
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
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
            itemBuilder: (_, i) {
              final c = categories[i];
              final isSelected = selected.contains(c.id);
              return _CertCard(
                category: c,
                isSelected: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val) {
                      selected.add(c.id);
                    } else {
                      selected.remove(c.id);
                    }
                  });
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemCount: categories.length,
          ),

          // Bottom selection summary + Continue
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
                        onPressed: selectedCats.isEmpty
                            ? null
                            : () {
                                // Build groups from the selected certifications
                                final groups = selectedCats
                                    .map((c) => ServiceGroup(c.title, c.tags))
                                    .toList();

                                // Preselect all services from selected certifications
                                final preselected =
                                    selectedCats.expand((c) => c.tags).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChooseServicesScreen(
                                      groups: groups,
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Continue to Service Selection',
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
}*/



/*class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({super.key});
  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  static const purple = Color(0xFF7841BA);
  static const gold = Color(0xFFD4AF37);

  final categories = <CertCategory>[
    CertCategory(
      id: 'home',
      title: 'Cleaning',
      subtitle:
          'Licensed for cleaning, maintenance, repairs, and home improvement',
      icon: Icons.handyman_rounded,
      iconBg: const Color(0xFF5C6FFF),
      tags: [
        'Home Cleaning(Standard / Deep)',
        'Ease-of-Lease Cleaning',
        'Carpet & Upholstery Cleaning',
        'Car Cleaning & Detailing (Mobile)',
        'Laundry - Washed & Fold (Pickup & Delivery)',
      ],
    ),
    CertCategory(
      id: 'health',
      title: 'Driving Services(with and without car)',
      subtitle:
          'Certified for medical assistance, elderly care, and wellness services',
      icon: Icons.favorite_rounded,
      iconBg: const Color(0xFFFF3B30),
      tags: [
        'Chauffeur Services (with car)',
        'Chauffeur Services (with Six seater)',
        'Personal Driver (your car)',
        'Grocery & Small-Item Delivery (E-scotter)',
        'Grocery & Small-Item Delivery (Car)',
        'Grocery & Small-Item Delivery (Van)'
      ],
    ),
    CertCategory(
      id: 'business',
      title: 'Furniture Assembly',
      subtitle:
          'Qualified for consulting, legal, accounting, and administrative work',
      icon: Icons.work_rounded,
      iconBg: const Color(0xFF00C853),
      tags: [
        'Home Furniture Assembly',
        'Handyperson (Non-licensed tasks only)',
        'Furniture Moving',
        'Helper (moving)'
      ],
    ),
    CertCategory(
      id: 'transport',
      title: 'Garden services',
      subtitle: 'Licensed for delivery, moving, and transportation services',
      icon: Icons.directions_car_rounded,
      iconBg: const Color(0xFFFF6D00),
      tags: [
        'Lawn Mowing & Edging',
        'Hedge Trimming & Pruning',
        'Garden Cleaning & Waste Removal'
      ],
    ),
    CertCategory(
      id: 'education',
      title: 'Babysitting Services',
      subtitle:
          'Certified to provide tutoring, training, and educational services',
      icon: Icons.school_rounded,
      iconBg: const Color(0xFF6A00FF),
      tags: ['Nanny'],
    ),
    CertCategory(
      id: 'perservices',
      title: 'Pet Services',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: ['Dog Walking', 'Pet Sitting & Home Visits', 'Mobile Pet Grooming'],
    ),
    CertCategory(
      id: 'construction',
      title: 'Construction',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Construction Labour',
        'Forklift Operator',
        'Construction Admin',
        'Construction Coordinator',
        'Traffic Controller',
        'Construction Office cleaner'
      ],
    ),
    CertCategory(
      id: 'corporate',
      title: 'Corporate',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Admin',
        'Coordinator',
        'Social Media Assistants',
        'Tech Support',
        'Office Cleaning',
        'Office Furniture Assembly',
        'Corporate/Office Driver Hire',
        'Carpet, Sofa/Upholstery Cleaning',
        'Chauffeur Services (with car)',
        'Trimming & Plant Care',
        'Small Items delivery (Car)',
        'Small Items delivery (Van)'
      ],
    ),
    CertCategory(
      id: 'Hospitality&Events',
      title: 'Hospitality & Events',
      subtitle:
          'Certified for event planning, catering, and hospitality services',
      icon: Icons.groups_rounded,
      iconBg: const Color(0xFFFF2D55),
      tags: [
        'Waitstaff & Baristas',
        'Event Setup Assistants',
        'Kitchen Hands',
        'Security Staff',
        'Commercial Cleaner'
      ],
    ),
  ];

  final selected = <String>{};

  @override
  Widget build(BuildContext context) {
    const currentStep = 2;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;
    final selectedCats =
        categories.where((c) => selected.contains(c.id)).toList();
    final totalEligibleServices =
        selectedCats.fold<int>(0, (s, c) => s + c.tags.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        elevation: 0,
        // surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Certifications',
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
                      "Select all the certifications and licenses you currently hold. This will determine which services you're eligible to offer.",
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
          // Padding(
          //   padding: const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
          //   child: Text(
          //       "Select all the certifications and licenses you currently hold. This will determine which services you're eligible to offer.",
          //       style: Theme.of(context)
          //           .textTheme
          //           .bodyMedium
          //           ?.copyWith(color: Colors.black54)),
          // ),

          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 66, 16, 220),
            itemBuilder: (_, i) {
              final c = categories[i];
              final isSelected = selected.contains(c.id);
              return _CertCard(
                category: c,
                isSelected: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val) {
                      selected.add(c.id);
                    } else {
                      selected.remove(c.id);
                    }
                  });
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemCount: categories.length,
          ),

          // Bottom selection summary
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
                    /*     _SelectedSummary(
                      items: selectedCats.map((e) => e.title).toList(),
                      title:
                          'Selected Certifications (${selectedCats.length}):',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "You'll be eligible for $totalEligibleServices services",
                        style: TextStyle(
                          color: Colors.black.withOpacity(.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),*/
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
                        onPressed: selectedCats.isEmpty ? null : () {},
                        child: const Text('Continue to Service Selection',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                                fontSize: 18)),
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

class _CertCard extends StatelessWidget {
  const _CertCard({
    required this.category,
    required this.isSelected,
    required this.onChanged,
  });

  final CertCategory category;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  static const purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? purple : const Color(0xFFE9E4FF);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? purple.withOpacity(.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(bg: category.iconBg, icon: category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        style: TextStyle(
                          height: 1.25,
                          color: Colors.black.withOpacity(.65),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(!isSelected),
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? purple : const Color(0xFFDBD5FF),
                        width: 2,
                      ),
                      color: isSelected ? purple : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Chips
            _ChipsRow(tags: category.tags),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.bg, required this.icon});
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ChipsRow extends StatefulWidget {
  const _ChipsRow({required this.tags});
  final List<String> tags;

  @override
  State<_ChipsRow> createState() => _ChipsRowState();
}

class _ChipsRowState extends State<_ChipsRow> {
  bool expanded = false;
  static const pillColor = Color(0xFFF1EEFF);
  static const pillText = Color(0xFF3B2A68);

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? widget.tags : widget.tags.take(4).toList();
    final remaining = widget.tags.length - visible.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(t, style: const TextStyle(color: pillText)),
          ),
        if (remaining > 0)
          GestureDetector(
            onTap: () => setState(() => expanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('+$remaining more',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.items, required this.title});
  final List<String> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
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
          if (items.isEmpty)
            Text('No certifications selected yet.',
                style: TextStyle(color: Colors.black.withOpacity(.6)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF7841BA)),
                          const SizedBox(width: 6),
                          Text(e),
                        ],
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/* ---------- Model ---------- */

class CertCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final List<String> tags;

  CertCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.tags,
  });
}
*/