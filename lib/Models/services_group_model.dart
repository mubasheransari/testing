import 'package:flutter/foundation.dart';

/// A single selectable service returned by your API.
@immutable
class ServiceItem {
  final int id;
  final String name;
  const ServiceItem({required this.id, required this.name});
}

/// A group (certification) with services inside.
@immutable
class ServiceGroup {
  final int id;            // certification/group id
  final String title;      // certification/group name
  final List<ServiceItem> items;
  const ServiceGroup({
    required this.id,
    required this.title,
    required this.items,
  });
}



// class ServiceItem {
//   final int id;
//   final String name;
//   const ServiceItem({required this.id, required this.name});
// }

// class ServiceGroup {
//   final int id;                 // certification / group id
//   final String title;           // certification / group title
//   final List<ServiceItem> items;

//   const ServiceGroup({
//     required this.id,
//     required this.title,
//     required this.items,
//   });
// }
