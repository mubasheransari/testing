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
  static const Color kPurple = Color(0xFF4A2C73);
  static const Color kBg = Color(0xFFF8F6FF);

  @override
  void initState() {
    super.initState();
    // load only if not loaded already
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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2C73)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select your required service',
          style: TextStyle(
            color: Color(0xFF4A2C73),
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
          final groups = state.serviceGroups; // List<CertificationGroup>

          if (state.servicesStatus == ServicesStatus.failure &&
              groups.isEmpty) {
            return const Center(
              child: Text(
                'Unable to load services',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          if (groups.isEmpty) {
            // calm empty
            return const Center(
              child: Text(
                'Fetching services…',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: GridView.builder(
              itemCount: groups.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) {
                final g = groups[i];
                final meta = _iconForService(g.name);

                return _ServiceTile(
                  title: g.name,
                  iconData: meta.icon,
                  purple: kPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceBookingFormScreen(group: g),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // map name → icon
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

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.title,
    required this.iconData,
    required this.purple,
    required this.onTap,
  });

  final String title;
  final IconData iconData;
  final Color purple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: purple,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: Colors.white, size: 44),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
//   static const Color kBg = Colors.white;
//   static const Color kPurple = Color(0xFF7841BA);

//   @override
//   void initState() {
//     super.initState();
//     // fetch only if not already fetched
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
//       backgroundColor: kBg,
//       body: SafeArea(
//         child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
//           buildWhen: (p, c) =>
//               p.serviceGroups != c.serviceGroups ||
//               p.servicesStatus != c.servicesStatus,
//           builder: (context, state) {
//             final groups = state.serviceGroups; // List<CertificationGroup>

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // top bar
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.arrow_back,
//                             color: Color(0xFF4A2C73), size: 26),
//                       ),
//                       const SizedBox(width: 4),
//                     ],
//                   ),
//                 ),

//                 // title
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 16),
//                   child: Text(
//                     'Select your required\nservice',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFF4A2C73),
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                       height: 1.2,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 22),

//                 // body
//                 Expanded(
//                   child: Builder(
//                     builder: (_) {
//                       if (state.servicesStatus == ServicesStatus.failure &&
//                           groups.isEmpty) {
//                         return const Center(
//                           child: Text(
//                             'Failed to load services',
//                             style: TextStyle(color: Colors.black54),
//                           ),
//                         );
//                       }

//                       if (groups.isEmpty) {
//                         return const Center(
//                           child: Text(
//                             'Loading services…',
//                             style: TextStyle(color: Colors.black45),
//                           ),
//                         );
//                       }

//                       return GridView.builder(
//                         padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           crossAxisSpacing: 14,
//                           mainAxisSpacing: 14,
//                           childAspectRatio: 0.95,
//                         ),
//                         itemCount: groups.length,
//                         itemBuilder: (_, i) {
//                           final g = groups[i];
//                           final meta = _iconForName(g.name);

//                           return _ServiceTile(
//                             title: g.name,
//                             iconData: meta.icon,
//                             purple: kPurple,
//                             onTap: () {
//                               // TODO: navigate / return selected
//                               Navigator.pop(context, g);
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   _ServiceIconMeta _iconForName(String name) {
//     final n = name.toLowerCase().trim();
//     if (n.contains('clean')) {
//       return _ServiceIconMeta(Icons.cleaning_services_rounded);
//     } else if (n.contains('drive')) {
//       return _ServiceIconMeta(Icons.directions_car_filled_rounded);
//     } else if (n.contains('furniture')) {
//       return _ServiceIconMeta(Icons.chair_alt_rounded);
//     } else if (n.contains('garden')) {
//       return _ServiceIconMeta(Icons.yard_rounded);
//     } else if (n.contains('baby') || n.contains('nanny')) {
//       return _ServiceIconMeta(Icons.child_friendly_rounded);
//     } else if (n.contains('pet')) {
//       return _ServiceIconMeta(Icons.pets_rounded);
//     }
//     // default
//     return _ServiceIconMeta(Icons.checkroom_rounded);
//   }
// }

// class _ServiceTile extends StatelessWidget {
//   const _ServiceTile({
//     required this.title,
//     required this.iconData,
//     required this.purple,
//     required this.onTap,
//   });

//   final String title;
//   final IconData iconData;
//   final Color purple;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(22),
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: purple,
//           borderRadius: BorderRadius.circular(22),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(iconData, color: Colors.white, size: 46),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w500,
//                 fontSize: 14.6,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ServiceIconMeta {
//   final IconData icon;
//   _ServiceIconMeta(this.icon);
// }
