import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';



class ServiceCertificatesGridScreen extends StatefulWidget {
  const ServiceCertificatesGridScreen({super.key});

  @override
  State<ServiceCertificatesGridScreen> createState() =>
      _ServiceCertificatesGridScreenState();
}

class _ServiceCertificatesGridScreenState
    extends State<ServiceCertificatesGridScreen> {
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPage = Color(0xFFF4F3FA);

  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AuthenticationBloc>();
      final s = bloc.state;
      final hasData =
          s.serviceGroups.isNotEmpty && s.servicesStatus == ServicesStatus.success;
      if (!hasData && s.servicesStatus == ServicesStatus.initial) {
        bloc.add(LoadServicesRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select service',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: kPurple,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        buildWhen: (p, c) =>
            p.serviceGroups != c.serviceGroups ||
            p.servicesStatus != c.servicesStatus,
        builder: (context, state) {
          final groups = state.serviceGroups;

          if (state.servicesStatus == ServicesStatus.failure && groups.isEmpty) {
            return const Center(
              child: Text(
                'Unable to load services',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
              ),
            );
          }

          if (groups.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kPurple),
            );
          }

          // filter by search
          final filtered = groups
              .where((g) =>
                  _search.trim().isEmpty ||
                  g.name.toLowerCase().contains(_search.toLowerCase()))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                // info card (same tone as home)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPurple.withOpacity(.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.025),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: kPurple.withOpacity(.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.widgets_rounded, color: kPurple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pick a category to see its booking form.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: Color(0xFF5C2E91),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // search
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.025),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Search service…',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey.shade500,
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF8C819F)),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // grid like home (white cards)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (_, i) {
                    final g = filtered[i];
                    final meta = _iconForService(g.name);
                    return _HomeLikeServiceCard(
                      title: g.name,
                      icon: meta.icon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceBookingFormScreen(group: g,subCategoryId: g.id.toString(),),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _ServiceIconMeta _iconForService(String name) {
    final n = name.toLowerCase();
    if (n.contains('clean')) {
      return _ServiceIconMeta(Icons.cleaning_services_rounded);
    } else if (n.contains('driv')) {
      return _ServiceIconMeta(Icons.directions_car_filled_rounded);
    } else if (n.contains('garden')) {
      return _ServiceIconMeta(Icons.grass_rounded);
    } else if (n.contains('furniture')) {
      return _ServiceIconMeta(Icons.chair_alt_rounded);
    } else if (n.contains('baby')) {
      return _ServiceIconMeta(Icons.child_friendly_rounded);
    } else if (n.contains('pet')) {
      return _ServiceIconMeta(Icons.pets_rounded);
    } else if (n.contains('electric')) {
      return _ServiceIconMeta(Icons.electric_bolt_rounded);
    }
    return _ServiceIconMeta(Icons.home_repair_service_rounded);
  }
}

class _ServiceIconMeta {
  final IconData icon;
  const _ServiceIconMeta(this.icon);
}

class _HomeLikeServiceCard extends StatelessWidget {
  const _HomeLikeServiceCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const kPurple = Color(0xFF5C2E91);
    const kMuted = Color(0xFF75748A);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kPurple),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3E1E69),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to book',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

