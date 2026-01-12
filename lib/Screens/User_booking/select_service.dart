import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';
import 'dart:ui';


class ServiceCertificatesGridScreen extends StatefulWidget {
  const ServiceCertificatesGridScreen({super.key});

  @override
  State<ServiceCertificatesGridScreen> createState() =>
      _ServiceCertificatesGridScreenState();
}

class _ServiceCertificatesGridScreenState
    extends State<ServiceCertificatesGridScreen> {


  final TextEditingController _searchCtrl = TextEditingController();
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _q => _search.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: _ModernAppBar(
          t: t,
          title: 'Select service',
          subtitle: 'Choose a category to continue',
          onBack: () => Navigator.pop(context),
        ),
        body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
          buildWhen: (p, c) =>
              p.serviceGroups != c.serviceGroups ||
              p.servicesStatus != c.servicesStatus,
          builder: (context, state) {
            final groups = state.serviceGroups;

            if (state.servicesStatus == ServicesStatus.failure &&
                groups.isEmpty) {
              return _EmptyState(
                t: t,
                icon: Icons.wifi_off_rounded,
                title: 'Unable to load services',
                subtitle: 'Please check your connection and try again.',
                actionText: 'Retry',
                onAction: () =>
                    context.read<AuthenticationBloc>().add(LoadServicesRequested()),
              );
            }

            if (groups.isEmpty) {
              return Center(
                child: _LoadingPill(t: t, text: "Loading services..."),
              );
            }

            // ✅ filter by search
            final filtered = _q.isEmpty
                ? groups
                : groups
                    .where((g) => g.name.toLowerCase().contains(_q))
                    .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ top hint card (home style)
                  _InfoCardModern(
                    t: t,
                    icon: Icons.widgets_rounded,
                    text:
                        'Pick a category to open its booking form and schedule instantly.',
                  ),
                  const SizedBox(height: 14),

                  // ✅ search (home style)
                  _SearchCardModern(
                    t: t,
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    showClear: _search.trim().isNotEmpty,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(Icons.grid_view_rounded,
                          size: 18, color: t.mutedText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            color: t.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.primary.withOpacity(.12)),
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: t.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    _EmptyState(
                      t: t,
                      icon: Icons.search_off_rounded,
                      title: 'No results',
                      subtitle: 'Try a different keyword.',
                      actionText: 'Clear search',
                      onAction: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.96,
                      ),
                      itemBuilder: (_, i) {
                        final g = filtered[i];
                        final meta = _iconForService(g.name);

                        return _ServiceCardModern(
                          t: t,
                          title: g.name,
                          subtitle: meta.tag,
                          icon: meta.icon,
                          iconBg: meta.bg,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceBookingFormScreen(
                                  group: g,
                                  serviceId: g.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 18),

                  // ✅ small footer help
                  _Glass(
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: t.primary.withOpacity(.10),
                              border:
                                  Border.all(color: t.primary.withOpacity(.12)),
                            ),
                            child: Icon(Icons.support_agent_rounded,
                                color: t.primaryDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Need help choosing? Our support team can guide you.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.6,
                                height: 1.15,
                                color: t.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: t.primaryDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ====================== ICON MAPPING (UPGRADED) ======================

  _ServiceIconMeta _iconForService(String name) {
    final n = name.toLowerCase();

    // Cleaning
    if (n.contains('clean')) {
      return const _ServiceIconMeta(
        icon: Icons.cleaning_services_rounded,
        bg: Color(0xFF7841BA),
        tag: 'Home • Office',
      );
    }

    // Driving / delivery
    if (n.contains('driv') || n.contains('delivery') || n.contains('ride')) {
      return const _ServiceIconMeta(
        icon: Icons.local_taxi_rounded,
        bg: Color(0xFF3DB38D),
        tag: 'Ride • Pickup',
      );
    }

    // Gardening
    if (n.contains('garden') || n.contains('lawn')) {
      return const _ServiceIconMeta(
        icon: Icons.grass_rounded,
        bg: Color(0xFF2E9E64),
        tag: 'Outdoor',
      );
    }

    // Furniture / handyman
    if (n.contains('furniture') || n.contains('assemble') || n.contains('handy')) {
      return const _ServiceIconMeta(
        icon: Icons.handyman_rounded,
        bg: Color(0xFFEE8A41),
        tag: 'Fix • Install',
      );
    }

    // Babysitting
    if (n.contains('baby') || n.contains('child')) {
      return const _ServiceIconMeta(
        icon: Icons.child_friendly_rounded,
        bg: Color(0xFFEE5DA0),
        tag: 'Care',
      );
    }

    // Pets
    if (n.contains('pet') || n.contains('dog') || n.contains('cat')) {
      return const _ServiceIconMeta(
        icon: Icons.pets_rounded,
        bg: Color(0xFF4A78FF),
        tag: 'Walk • Sit',
      );
    }

    // Electrical
    if (n.contains('electric') || n.contains('wire')) {
      return const _ServiceIconMeta(
        icon: Icons.electric_bolt_rounded,
        bg: Color(0xFF9B59FF),
        tag: 'Repair',
      );
    }

    // Plumbing
    if (n.contains('plumb') || n.contains('pipe')) {
      return const _ServiceIconMeta(
        icon: Icons.plumbing_rounded,
        bg: Color(0xFF2D8CFF),
        tag: 'Fix leaks',
      );
    }

    // AC / HVAC
    if (n.contains('ac') || n.contains('air') || n.contains('hvac')) {
      return const _ServiceIconMeta(
        icon: Icons.ac_unit_rounded,
        bg: Color(0xFF00A3FF),
        tag: 'Cooling',
      );
    }

    // Default
    return  _ServiceIconMeta(
      icon: Icons.home_repair_service_rounded,
      bg: Color(0xFF7841BA),
     tag: 'Service',
    );
  }
}

/* ============================== META ============================== */

class _ServiceIconMeta {
  final IconData icon;
  final Color bg;
  final String tag;
  const _ServiceIconMeta({
    required this.icon,
    required this.bg,
    required this.tag,
  });
}

/* ============================== TOKENS ============================== */

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color primaryText;
  final Color mutedText;
  final Color bg;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.primaryText,
    required this.mutedText,
    required this.bg,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF7841BA),
        primaryDark: Color(0xFF5C2E91),
        primaryText: Color(0xFF3E1E69),
        mutedText: Color(0xFF75748A),
        bg: Color(0xFFF8F7FB),
      );
}

/* ============================== APP BAR ============================== */

class _ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ModernAppBar({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(102);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            _Glass(
              radius: 16,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(Icons.arrow_back_rounded, color: t.primaryDark),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Glass(
                radius: 18,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: t.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // const SizedBox(width: 12),
            // _Glass(
            //   radius: 16,
            //   child: SizedBox(
            //     width: 46,
            //     height: 46,
            //     child:
            //         Icon(Icons.grid_view_rounded, color: t.primaryDark),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/* ============================== SEARCH ============================== */

class _SearchCardModern extends StatelessWidget {
  const _SearchCardModern({
    required this.t,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final _UiTokens t;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(Icons.search_rounded, color: t.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (showClear)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: t.mutedText),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.primary, t.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== INFO CARD ============================== */

class _InfoCardModern extends StatelessWidget {
  const _InfoCardModern({
    required this.t,
    required this.icon,
    required this.text,
  });

  final _UiTokens t;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.primary.withOpacity(.20), t.primary.withOpacity(.06)],
                ),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(icon, color: t.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.8,
                  color: t.primaryDark,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== SERVICE CARD ============================== */

class _ServiceCardModern extends StatelessWidget {
  const _ServiceCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _Glass(
        radius: 20,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon + badge
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconBg.withOpacity(.95),
                            iconBg.withOpacity(.65),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: iconBg.withOpacity(.22),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.primary.withOpacity(.14)),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: t.primaryDark,
                        ),
                      ),
                    )
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                    color: t.primaryText,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 16, color: t.mutedText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tap to book',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.8,
                          color: t.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: t.primary.withOpacity(.75)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== EMPTY / LOADING ============================== */

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  final _UiTokens t;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _Glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: t.primary.withOpacity(.10),
                    border: Border.all(color: t.primary.withOpacity(.12)),
                  ),
                  child: Icon(icon, color: t.primaryDark),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    color: t.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.6,
                    color: t.mutedText,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: t.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.t, required this.text});
  final _UiTokens t;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: t.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: t.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== GLASS ============================== */

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // ignore: deprecated_member_use
                Colors.white.withOpacity(.92),
                // ignore: deprecated_member_use
                Colors.white.withOpacity(.78),
              ],
            ),
            // ignore: deprecated_member_use
            border: Border.all(color: t.primary.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}




// class ServiceCertificatesGridScreen extends StatefulWidget {
//   const ServiceCertificatesGridScreen({super.key});

//   @override
//   State<ServiceCertificatesGridScreen> createState() =>
//       _ServiceCertificatesGridScreenState();
// }

// class _ServiceCertificatesGridScreenState
//     extends State<ServiceCertificatesGridScreen> {
//   static const Color kPurple = Color(0xFF5C2E91);
//   static const Color kPage = Color(0xFFF4F3FA);

//   String _search = '';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final bloc = context.read<AuthenticationBloc>();
//       final s = bloc.state;
//       final hasData =
//           s.serviceGroups.isNotEmpty && s.servicesStatus == ServicesStatus.success;
//       if (!hasData && s.servicesStatus == ServicesStatus.initial) {
//         bloc.add(LoadServicesRequested());
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kPage,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: kPurple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Select service',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             color: kPurple,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//           ),
//         ),
//       ),
//       body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
//         buildWhen: (p, c) =>
//             p.serviceGroups != c.serviceGroups ||
//             p.servicesStatus != c.servicesStatus,
//         builder: (context, state) {
//           final groups = state.serviceGroups;

//           if (state.servicesStatus == ServicesStatus.failure && groups.isEmpty) {
//             return const Center(
//               child: Text(
//                 'Unable to load services',
//                 style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
//               ),
//             );
//           }

//           if (groups.isEmpty) {
//             return const Center(
//               child: CircularProgressIndicator(color: kPurple),
//             );
//           }

//           // filter by search
//           final filtered = groups
//               .where((g) =>
//                   _search.trim().isEmpty ||
//                   g.name.toLowerCase().contains(_search.toLowerCase()))
//               .toList();

//           return SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 14),
//                 // info card (same tone as home)
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: kPurple.withOpacity(.05)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(.025),
//                         blurRadius: 14,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.all(14),
//                   child: Row(
//                     children: [
//                       Container(
//                         height: 40,
//                         width: 40,
//                         decoration: BoxDecoration(
//                           color: kPurple.withOpacity(.10),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.widgets_rounded, color: kPurple),
//                       ),
//                       const SizedBox(width: 12),
//                       const Expanded(
//                         child: Text(
//                           'Pick a category to see its booking form.',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontSize: 12.5,
//                             color: Color(0xFF5C2E91),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // search
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(.025),
//                         blurRadius: 10,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: TextField(
//                     onChanged: (v) => setState(() => _search = v),
//                     style: const TextStyle(fontFamily: 'Poppins'),
//                     decoration: InputDecoration(
//                       hintText: 'Search service…',
//                       hintStyle: TextStyle(
//                         fontFamily: 'Poppins',
//                         color: Colors.grey.shade500,
//                         fontSize: 13.5,
//                       ),
//                       border: InputBorder.none,
//                       prefixIcon: const Icon(Icons.search_rounded,
//                           color: Color(0xFF8C819F)),
//                       contentPadding: const EdgeInsets.symmetric(
//                         vertical: 12,
//                         horizontal: 4,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // grid like home (white cards)
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: filtered.length,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 14,
//                     crossAxisSpacing: 14,
//                     childAspectRatio: 1,
//                   ),
//                   itemBuilder: (_, i) {
//                     final g = filtered[i];
//                     final meta = _iconForService(g.name);
//                     return _HomeLikeServiceCard(
//                       title: g.name,
//                       icon: meta.icon,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => ServiceBookingFormScreen(group: g, serviceId: g.id),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   _ServiceIconMeta _iconForService(String name) {
//     final n = name.toLowerCase();
//     if (n.contains('clean')) {
//       return _ServiceIconMeta(Icons.cleaning_services_rounded);
//     } else if (n.contains('driv')) {
//       return _ServiceIconMeta(Icons.directions_car_filled_rounded);
//     } else if (n.contains('garden')) {
//       return _ServiceIconMeta(Icons.grass_rounded);
//     } else if (n.contains('furniture')) {
//       return _ServiceIconMeta(Icons.chair_alt_rounded);
//     } else if (n.contains('baby')) {
//       return _ServiceIconMeta(Icons.child_friendly_rounded);
//     } else if (n.contains('pet')) {
//       return _ServiceIconMeta(Icons.pets_rounded);
//     } else if (n.contains('electric')) {
//       return _ServiceIconMeta(Icons.electric_bolt_rounded);
//     }
//     return _ServiceIconMeta(Icons.home_repair_service_rounded);
//   }
// }

// class _ServiceIconMeta {
//   final IconData icon;
//   const _ServiceIconMeta(this.icon);
// }

// class _HomeLikeServiceCard extends StatelessWidget {
//   const _HomeLikeServiceCard({
//     required this.title,
//     required this.icon,
//     required this.onTap,
//   });

//   final String title;
//   final IconData icon;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     const kPurple = Color(0xFF5C2E91);
//     const kMuted = Color(0xFF75748A);

//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // icon
//               Container(
//                 height: 38,
//                 width: 38,
//                 decoration: BoxDecoration(
//                   color: kPurple.withOpacity(.10),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: kPurple),
//               ),
//               const Spacer(),
//               Text(
//                 title,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF3E1E69),
//                 ),
//               ),
//               const SizedBox(height: 4),
//               const Text(
//                 'Tap to book',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 11.5,
//                   color: kMuted,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

