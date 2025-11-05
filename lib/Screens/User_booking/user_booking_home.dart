import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Screens/User_booking/select_service.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';


class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome> {
  String _selectedChip = 'All';
  CertificationGroup? _selectedGroup; // to show its services

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
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearch(),
              const SizedBox(height: 14),
              _buildInfoCard(),
              const SizedBox(height: 18),
              const Text(
                'What do you need today?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Color(0xFF3E1E69),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              // ⬇️ chips + below selected certificate services
BlocBuilder<AuthenticationBloc, AuthenticationState>(
  buildWhen: (p, c) =>
      p.serviceGroups != c.serviceGroups ||
      p.servicesStatus != c.servicesStatus,
  builder: (context, state) {
    final groups = state.serviceGroups;
    final List<String> chipLabels = ['All'];
    if (groups.isNotEmpty) {
      chipLabels.addAll(groups.map((e) => e.name));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: (state.servicesStatus == ServicesStatus.loading &&
                  groups.isEmpty)
              ? _buildLoadingChips()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chipLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final label = chipLabels[i];
                    final sel = label == _selectedChip;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChip = label;
                          _selectedGroup = label == 'All'
                              ? null
                              : groups.firstWhere(
                                  (g) => g.name == label,
                                  orElse: () => groups.first,
                                );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF5C2E91)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: sel
                              ? null
                              : Border.all(
                                  color: const Color(0xFF5C2E91)
                                      .withOpacity(.3),
                                ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: sel
                                ? Colors.white
                                : const Color(0xFF5C2E91),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // ⬇️ when "All" is selected, show ALL services from ALL groups
        if (_selectedGroup == null && groups.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'All services',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                for (final svc in g.services)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceBookingFormScreen(
                            group: g,
                            initialService: svc,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C2E91).withOpacity(.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5C2E91).withOpacity(.25),
                        ),
                      ),
                      child: Text(
                        svc.name, // uses each service name
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF3E1E69),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],

        // ⬇️ when a specific group is selected, show only that group's services
        if (_selectedGroup != null && _selectedGroup!.services.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Services in "${_selectedGroup!.name}"',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedGroup!.services.map((svc) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceBookingFormScreen(
                        group: _selectedGroup!,
                        initialService: svc,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C2E91).withOpacity(.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5C2E91).withOpacity(.25),
                    ),
                  ),
                  child: Text(
                    svc.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF3E1E69),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  },
),


              // ⬇️ chips + below selected certificate services
            /*  BlocBuilder<AuthenticationBloc, AuthenticationState>(
                buildWhen: (p, c) =>
                    p.serviceGroups != c.serviceGroups ||
                    p.servicesStatus != c.servicesStatus,
                builder: (context, state) {
                  final groups = state.serviceGroups;
                  final List<String> chipLabels = ['All'];
                  if (groups.isNotEmpty) {
                    chipLabels.addAll(groups.map((e) => e.name));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: (state.servicesStatus == ServicesStatus.loading &&
                                groups.isEmpty)
                            ? _buildLoadingChips()
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: chipLabels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final label = chipLabels[i];
                                  final sel = label == _selectedChip;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChip = label;
                                        _selectedGroup = label == 'All'
                                            ? null
                                            : groups.firstWhere(
                                                (g) => g.name == label,
                                                orElse: () => groups.first,
                                              );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF5C2E91)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: const Color(0xFF5C2E91)
                                                    .withOpacity(.3),
                                              ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: sel
                                              ? Colors.white
                                              : const Color(0xFF5C2E91),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // ⬇️ show services of selected certificate
                      if (_selectedGroup != null &&
                          _selectedGroup!.services.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Services in "${_selectedGroup!.name}"',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF75748A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedGroup!.services.map((svc) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceBookingFormScreen(
                                      group: _selectedGroup!,
                                      initialService: svc,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C2E91)
                                      .withOpacity(.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF5C2E91)
                                        .withOpacity(.25),
                                  ),
                                ),
                                child: Text(
                                  svc.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF3E1E69),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),*/

              const SizedBox(height: 16),
              _buildActionRow(context),
              const SizedBox(height: 20),
              _buildPopular(context),
              const SizedBox(height: 20),
              _buildRecent(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Good morning 👋',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Color(0xFF5C2E91),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 15, color: Color(0xFF5C2E91)),
              SizedBox(width: 4),
              Text(
                'Melbourne, AU',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded,
              color: Color(0xFF5C2E91)),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/avatar.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Material(
      elevation: 0,
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        style: const TextStyle(fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: 'Search for services...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey.shade500,
            fontSize: 13.5,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C2E91).withOpacity(.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5C2E91).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flash_on_rounded,
                color: Color(0xFF5C2E91)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '1 active booking today. Tap to view or reschedule.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: Color(0xFF5C2E91),
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF5C2E91)),
        ],
      ),
    );
  }

  Widget _buildLoadingChips() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Container(
        width: 80,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: 4,
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Book a service',
            subtitle: 'Schedule instantly',
            icon: Icons.event_available_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceCertificatesGridScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Track booking',
            subtitle: 'See status',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF3DB38D),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildPopular(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular near you',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3E1E69),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceCertificatesGridScreen(),
                  ),
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF5C2E91),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ServiceHorizontalCard(
                title: 'House cleaning',
                price: 'From \$45',
                icon: Icons.cleaning_services_rounded,
              ),
              _ServiceHorizontalCard(
                title: 'AC repair',
                price: 'From \$60',
                icon: Icons.ac_unit_rounded,
                color: Color(0xFF3DB38D),
              ),
              _ServiceHorizontalCard(
                title: 'Furniture assemble',
                price: 'From \$35',
                icon: Icons.chair_alt_rounded,
                color: Color(0xFFEE8A41),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent activity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3E1E69),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.02),
                blurRadius: 18,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child:const Column(
            children: const [
              Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF75748A)),
              SizedBox(height: 8),
              Text(
                'No bookings yet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Book a task to see it here.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}




class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? const Color(0xFF5C2E91)),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3E1E69),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Color(0xFF75748A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceHorizontalCard extends StatelessWidget {
  const _ServiceHorizontalCard({
    required this.title,
    required this.price,
    required this.icon,
    this.color,
  });

  final String title;
  final String price;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? const Color(0xFF5C2E91), size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF75748A),
            ),
          ),
        ],
      ),
    );
  }
}

