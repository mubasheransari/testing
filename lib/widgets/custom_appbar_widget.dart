// import 'package:flutter/material.dart';

// import '../Features/notification_screen.dart';
// final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
// class CustomAppBarWidget extends StatelessWidget {
//   const CustomAppBarWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       //mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         //   SizedBox(width: ,),
//         InkWell(
//           onTap: () {
//                _scaffoldKey.currentState?.openDrawer();
//           },
//           child: CircleAvatar(
//               radius: 22,
//               backgroundColor: Colors.white,
//               child: Image.asset("assets/menu-02.png")),
//         ),
//         SizedBox(
//           width: 10,
//         ),
//         const Text(
//           'Find Providers',
//           style: TextStyle(
//             fontSize: 24,
//             color: Color(0xff323747),
//             fontWeight: FontWeight.w900,
//             fontFamily: 'Satoshi',
//           ),
//         ),
//         SizedBox(
//           width: 10,
//         ),
//         // SizedBox(
//         //   width: 4,
//         // ),
//         InkWell(
//           onTap: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => NotificationScreen()));
//           },
//           child: CircleAvatar(
//               radius: 22,
//               backgroundColor: Colors.white,
//               child: Image.asset("assets/notification.png")),
//         ),
//       ],
//     );
//   }
// }
