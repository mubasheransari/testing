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
              ),

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
          child: Column(
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


/*
class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome> {
  String _selectedChip = 'All';

  @override
  void initState() {
    super.initState();
    // load services once
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
      appBar: AppBar(
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
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // search
              Material(
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
              ),
              const SizedBox(height: 14),

              // info
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF5C2E91).withOpacity(.07)),
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
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF5C2E91)),
                  ],
                ),
              ),
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

              // 👇 dynamic chips from bloc
              BlocBuilder<AuthenticationBloc, AuthenticationState>(
                buildWhen: (p, c) =>
                    p.serviceGroups != c.serviceGroups ||
                    p.servicesStatus != c.servicesStatus,
                builder: (context, state) {
                  // always keep "All" at start
                  final List<String> items = ['All'];
                  if (state.serviceGroups.isNotEmpty) {
                    items.addAll(state.serviceGroups.map((e) => e.name));
                  }

                  if (state.servicesStatus == ServicesStatus.loading &&
                      state.serviceGroups.isEmpty) {
                    return SizedBox(
                      height: 34,
                      child: ListView.separated(
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
                      ),
                    );
                  }

                  return SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final label = items[i];
                        final sel = label == _selectedChip;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedChip = label);
                            // open certificates filtered
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceCertificatesGridScreen(
                                  // initialFilter:
                                  //     label == 'All' ? null : label,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  sel ? const Color(0xFF5C2E91) : Colors.white,
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
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
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
                            builder: (_) =>
                                const ServiceCertificatesGridScreen(),
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
              ),

              const SizedBox(height: 20),
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
                          builder: (_) =>
                              const ServiceCertificatesGridScreen(),
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
              const SizedBox(height: 20),

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
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
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
                child: Column(
                  children: const [
                    Icon(Icons.inbox_rounded,
                        size: 40, color: Color(0xFF75748A)),
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
          ),
        ),
      ),
    );
  }
}
*/

// class UserBookingHome extends StatelessWidget {
//   const UserBookingHome({super.key});

//   @override
//   Widget build(BuildContext context) {


//     return Scaffold(

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: false,
//         titleSpacing: 16,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             Text(
//               'Good morning 👋',
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 16,
//                 color: Color(0xFF5C2E91),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 3),
//             Row(
//               children: [
//                 Icon(Icons.location_on_rounded,
//                     size: 15, color: Color(0xFF5C2E91)),
//                 SizedBox(width: 4),
//                 Text(
//                   'Melbourne, AU',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 12.5,
//                     color: Color(0xFF75748A),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: const Icon(Icons.notifications_none_rounded,
//                 color: Color(0xFF5C2E91)),
//           ),
//           const Padding(
//             padding: EdgeInsets.only(right: 16),
//             child: CircleAvatar(
//               radius: 18,
//               backgroundImage: AssetImage('assets/avatar.png'),
//             ),
//           ),
//         ],
//       ),

//       body: SafeArea(
//         top: false,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // search
//               Material(
//                 elevation: 0,
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 child: TextField(
//                   style: const TextStyle(fontFamily: 'Poppins'),
//                   decoration: InputDecoration(
//                     hintText: 'Search for services...',
//                     hintStyle: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: Colors.grey.shade500,
//                       fontSize: 13.5,
//                     ),
//                     border: InputBorder.none,
//                     prefixIcon: const Icon(Icons.search_rounded),
//                     contentPadding:
//                         const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 14),

//               // info/glass card but on white (no curve)
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                       color: const Color(0xFF5C2E91).withOpacity(.07)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.03),
//                       blurRadius: 14,
//                       offset: const Offset(0, 6),
//                     )
//                   ],
//                 ),
//                 padding: const EdgeInsets.all(14),
//                 child: Row(
//                   children: [
//                     Container(
//                       height: 40,
//                       width: 40,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF5C2E91).withOpacity(.12),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(Icons.flash_on_rounded,
//                           color: Color(0xFF5C2E91)),
//                     ),
//                     const SizedBox(width: 12),
//                     const Expanded(
//                       child: Text(
//                         '1 active booking today. Tap to view or reschedule.',
//                         style: TextStyle(
//                           fontFamily: 'Poppins',
//                           fontSize: 12.5,
//                           color: Color(0xFF5C2E91),
//                         ),
//                       ),
//                     ),
//                     const Icon(Icons.chevron_right_rounded,
//                         color: Color(0xFF5C2E91)),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 18),

//               // filters
//               const Text(
//                 'What do you need today?',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   color: Color(0xFF3E1E69),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: 34,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: const [
//                     _FilterChip(label: 'All', selected: true),
//                     _FilterChip(label: 'Cleaning'),
//                     _FilterChip(label: 'Plumbing'),
//                     _FilterChip(label: 'Electrician'),
//                     _FilterChip(label: 'Moving'),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _ActionCard(
//                       title: 'Book a service',
//                       subtitle: 'Schedule instantly',
//                       icon: Icons.event_available_rounded,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) =>
//                                 const ServiceCertificatesGridScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _ActionCard(
//                       title: 'Track booking',
//                       subtitle: 'See status',
//                       icon: Icons.schedule_rounded,
//                       color: const Color(0xFF3DB38D),
//                       onTap: () {},
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Popular near you',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       fontSize: 15.5,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF3E1E69),
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) =>
//                               const ServiceCertificatesGridScreen(),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                       'View all',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         color: Color(0xFF5C2E91),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               SizedBox(
//                 height: 150,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: const [
//                     _ServiceHorizontalCard(
//                       title: 'House cleaning',
//                       price: 'From \$45',
//                       icon: Icons.cleaning_services_rounded,
//                     ),
//                     _ServiceHorizontalCard(
//                       title: 'AC repair',
//                       price: 'From \$60',
//                       icon: Icons.ac_unit_rounded,
//                       color: Color(0xFF3DB38D),
//                     ),
//                     _ServiceHorizontalCard(
//                       title: 'Furniture assemble',
//                       price: 'From \$35',
//                       icon: Icons.chair_alt_rounded,
//                       color: Color(0xFFEE8A41),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               const Text(
//                 'Recent activity',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 15.5,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFF3E1E69),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.02),
//                       blurRadius: 18,
//                       offset: const Offset(0, 12),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   children: const [
//                     Icon(Icons.inbox_rounded,
//                         size: 40, color: Color(0xFF75748A)),
//                     SizedBox(height: 8),
//                     Text(
//                       'No bookings yet',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Book a task to see it here.',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 12.5,
//                         color: Color(0xFF75748A),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ==== reused small widgets from previous version ==== */

// class _FilterChip extends StatelessWidget {
//   const _FilterChip({required this.label, this.selected = false});
//   final String label;
//   final bool selected;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             color: selected ? Colors.white : const Color(0xFF5C2E91),
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         selected: selected,
//         onSelected: (_) {},
//         selectedColor: const Color(0xFF5C2E91),
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(999),
//           side: BorderSide(
//             color: selected
//                 ? Colors.transparent
//                 : const Color(0xFF5C2E91).withOpacity(.3),
//           ),
//         ),
//       ),
//     );
//   }
// }

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


/*
class UserBooking extends StatelessWidget {
  const UserBooking({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: brand.page,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brand.primary,
          primary: brand.primary,
        ),
      ),
      home: const UserBookingHome(),
    );
  }
}

class _Brand {
  const _Brand();

  final primary = const Color(0xFF5C2E91);
  final primaryDark = const Color(0xFF3E1E69);
  final page = const Color(0xFFF5F3F9);
  final card = Colors.white;
  final muted = const Color(0xFF75748A);
  final accent = const Color(0xFF3DB38D);
}

class UserBookingHome extends StatelessWidget {
  const UserBookingHome({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: brand.page,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brand.primary,
        onPressed: () {
          // open create booking
        },
        label: const Text(
          'New booking',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // top gradient header
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brand.primary, brand.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top bar
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning 👋',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              Icon(Icons.location_pin,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Melbourne, AU',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/avatar.png'),
                      ),
                    ],
                  ),

                  // search (overlapping)
                  const SizedBox(height: 20),
                  Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        style: const TextStyle(fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          hintText: 'Search for cleaning, plumber, movers…',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // small info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.flash_on_rounded,
                              color: brand.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '1 active booking today.\nTap to manage or reschedule.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(.7)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // white section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: brand.page,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'What do you need today?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: brand.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // chips
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(label: 'All', selected: true),
                              _FilterChip(label: 'Cleaning'),
                              _FilterChip(label: 'Moving'),
                              _FilterChip(label: 'Electrician'),
                              _FilterChip(label: 'Plumbing'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // quick actions
                        Row(
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
                                      builder: (_) =>
                                          const ServiceCertificatesGridScreen(),
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
                        ),

                        const SizedBox(height: 22),

                        // popular services list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Popular near you',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: brand.primaryDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ServiceCertificatesGridScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View all',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    color: Color(0xFF5C2E91)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 155,
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

                        const SizedBox(height: 20),

                        Text(
                          'Recent activity',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: brand.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // empty state
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 26, horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withOpacity(.02),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.02),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 42, color: brand.muted),
                              const SizedBox(height: 8),
                              const Text(
                                'No bookings yet',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start by booking your first tasker.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: brand.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===== smaller widgets ===== */

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const brand = _Brand();
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? Colors.white : Colors.white.withOpacity(.3),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selected ? brand.primary : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
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
    const brand = _Brand();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: (color ?? brand.primary).withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? brand.primary, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: brand.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: brand.muted,
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
    const brand = _Brand();
    return Container(
      width: 148,
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
              color: (color ?? brand.primary).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? brand.primary, size: 20),
          ),
          const SizedBox(height: 12),
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
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: brand.muted,
            ),
          ),
        ],
      ),
    );
  }
}

*/



// class UserBooking extends StatelessWidget {
//   const UserBooking({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const brand = _Brand();
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: brand.primary),
//         useMaterial3: true,
//         textTheme: GoogleFonts.poppinsTextTheme(),
//       ),
//       home:  UserBookingHome(),
//     );
//   }
// }

// class _Brand {
//   const _Brand();

//   final primary = const Color(0xFF5C2E91); // deep purple
//   final primaryDark = const Color(0xFF3E1E69);
//   final fieldBg = const Color(0xFFF5F3F9);
//   final page = const Color(0xFFF8F7FB);
//   final outline = const Color(0xFFDCD4EB);
//   final textMuted = const Color(0xFF6C6A7A);
// }

// class UserBookingHome extends StatelessWidget {
//   const UserBookingHome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     const brand = _Brand();
//     final w = MediaQuery.of(context).size.width;

//     return Scaffold(
//       backgroundColor: brand.page,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Greeting + location
//               Text(
//                 'Good Morning',
//                 style: TextStyle(
//                   color: brand.primary,
//                   fontFamily: 'Poppins',
//                   fontSize: 20,
//                   fontWeight: FontWeight.w500,
//                   height: 1.1,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Row(
//                 children: [
//                   Icon(Icons.location_on_rounded,
//                       size: 18, color: brand.primary),
//                   const SizedBox(width: 6),
//                   Text(
//                     'New York, NY',
//                     style: TextStyle(
//                        fontFamily: 'Poppins',
//                       color: brand.textMuted,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               // Search
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: brand.outline),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.05),
//                       blurRadius: 16,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Search for services....',
//                     hintStyle: TextStyle(color: brand.textMuted, fontFamily: 'Poppins',fontWeight: FontWeight.w500,fontSize: 14),
//                     contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                     border: InputBorder.none,
//                     suffixIcon: Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: IconButton(
//                         onPressed: () {},
//                         icon: Icon(Icons.search_rounded, color: brand.primary),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 18),

//               // Promo card
//               _PromoCard(
//                 width: w *0.99,
//                 onTap: () {},
//               ),

//               const SizedBox(height: 16),

//               // Image banner
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: Image.network(
//                     // placeholder stock image
//                     'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1600&auto=format&fit=crop',
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 18),

//               Text(
//                 'Quick Actions',
//                 style: TextStyle(
//                    fontFamily: 'Poppins',
//                   color: brand.primary,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _QuickActionCard(
//                       title: 'Book Service',
//                       subtitle: 'Book\nprofessional services',
//                       icon: Icons.event_available_rounded,
//                       onTap: () {
//                         Navigator.push(context, MaterialPageRoute(builder: (context)=> ServiceCertificatesGridScreen()));
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _QuickActionCard(
//                       title: 'Emergency',
//                       subtitle: '24/7 urgent\nservices',
//                       icon: Icons.emergency_share_rounded,
//                       onTap: () {},
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               Text(
//                 'Recent Activity',
//                 style: TextStyle(
//                    fontFamily: 'Poppins',
//                   color: brand.primary,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 28),

//               // Empty state
//               Center(
//                 child: Column(
//                   children: [
//                     Text(
//                       'No Recent bookings',
//                       style: TextStyle(
//                          fontFamily: 'Poppins',
//                         color: Colors.black.withOpacity(.8),
//                         fontSize: 16.5,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Book your first service to see activity here',
//                       style: TextStyle(
//                          fontFamily: 'Poppins',
//                         color: brand.textMuted,
//                         fontSize: 13.5,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _PromoCard extends StatelessWidget {
//   const _PromoCard({required this.width, required this.onTap});
//   final double width;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     const brand = _Brand();

//     return Container(
//       width: MediaQuery.of(context).size.width *90,
//       padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [brand.primary, brand.primary.withOpacity(.92)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: brand.primary.withOpacity(.25),
//             blurRadius: 22,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Need professional services?',
//             style: const TextStyle(
//                fontFamily: 'Poppins',
//               color: Colors.white,
//               fontSize: 18.5,
//               fontWeight: FontWeight.w800,
//               height: 1.2,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Connect with trusted service providers in\nyour area',
//             style: TextStyle(
//                fontFamily: 'Poppins',
//               color: Colors.white.withOpacity(.9),
//               height: 1.35,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 14),
//           SizedBox(
//             height: 38,
//             child: TextButton(
//               onPressed: onTap,
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: brand.primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//               ),
//               child:  Text(
//                 'BROWSE CATEGORIES',
//                 style: TextStyle( fontFamily: 'Poppins',fontWeight: FontWeight.w600, letterSpacing: .1,fontSize: 13),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuickActionCard extends StatelessWidget {
//   const _QuickActionCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     const brand = _Brand();

//     return Container(
//       height: 97,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Ink(
//           padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: brand.primary, width: 1),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.04),
//                 blurRadius: 14,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: brand.primary.withOpacity(.10),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: brand.primary),
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: TextStyle(
//                            fontFamily: 'Poppins',
//                           color: brand.primary,
//                           fontWeight: FontWeight.w800,
//                           fontSize: 13.5,
//                         )),
//                     const SizedBox(height: 6),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                          fontFamily: 'Poppins',
//                         color: brand.textMuted,
//                         height: 1.05,
//                         fontSize: 11.5,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
