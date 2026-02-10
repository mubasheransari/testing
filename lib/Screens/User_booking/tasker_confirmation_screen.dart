import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/payment_method.dart';




class TaskerConfirmationScreen extends StatelessWidget {
  final String name, distance, rating, cost,taskerDetailId;

  TaskerConfirmationScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.cost,
    required this.taskerDetailId
  });

  // Theme taken from UserBookingHome
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPurpleDark = Color(0xFF3E1E69);
  static const Color kBg = Color(0xFFF5F3FB);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kGreen = Color(0xFF3DB38D);
  static const String kFont = 'Poppins';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final int ratingValue = int.tryParse(rating) ?? 0;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // top bar (same theme as UserBookingHome)
         /*   Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back, color: kPurple),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tasker Assigned',
                      style: TextStyle(
                        fontFamily: kFont,
                        fontSize: 18,
                        color: kPurpleDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),*/

            const SizedBox(height: 14),

            // avatar + title (kept same content, updated styling)
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDA57),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/trained_cleaners.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Your tasker will arrive at your\nscheduled time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFont,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: kPurple,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 18),

            // card (theme like UserBookingHome)
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: w * 0.9,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kPurple.withOpacity(.07)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _divider(),

                        _rowLabelValue('Distance', "$distance miles"),
                        _divider(),

                        _rowLabelValue('Role', 'Pro, cleaner'),
                        _divider(),

                        // rating row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    final isFilled = index < ratingValue;
                                    return Icon(
                                      isFilled
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 18,
                                      color: isFilled
                                          ? const Color(0xFFFFB800)
                                          : Colors.grey.shade400,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    ratingValue == 0
                                        ? 'No rating yet'
                                        : ratingValue.toString(),
                                    style: TextStyle(
                                      fontFamily: kFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ratingValue == 0
                                          ? Colors.grey.shade500
                                          : kPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 13,
                                  color: kPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _divider(),
                        const SizedBox(height: 10),

                        // base cost (same content, themed)
                        const Text(
                          'Base cost',
                          style: TextStyle(
                            fontFamily: kFont,
                            fontSize: 12.5,
                            color: kMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AUD $cost',
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // button (theme like home green button style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurpleDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodScreen(),
                      ),
                    );
                  },
                  child:  Text(
                    'PROCEED TO PAYMENT ${taskerDetailId}',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
             Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'CANCEL BOOKING',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.5,
              color: kMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 18,
        color: kPurple.withOpacity(.10),
        thickness: 1,
      );
}



// class TaskerConfirmationScreen extends StatelessWidget {
//   String name, distance,rating,cost;
//    TaskerConfirmationScreen({super.key,required this.name,required this.distance,required this.rating,required this.cost});

//   static const Color kPurple = Color(0xFF5C2D91);
//   static const Color kGreen = Color(0xFF2F7D32);
//   static const String kFont = 'Poppins'; // make sure added in pubspec.yaml

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
// final int ratingValue = int.tryParse(rating) ?? 0;
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F3FB),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // top bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPurple),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 4),
//                 const  Text(
//                     'Tasker assigned',
//                 style: TextStyle(
//                 fontFamily: 'Poppins',
//             fontSize: 22,
//             color: Color(0xFF4A2C73),
//             fontWeight: FontWeight.w500,
//           ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             // avatar + title
//             Container(
//               width: 130,
//               height: 130,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Color(0xFFFFDA57),
//               ),
//               child: ClipOval(
//                 child: Image.asset(
//                   'assets/trained_cleaners.png', // replace with your asset
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//         const    Text(
//               'Your tasker will arrive at your\nscheduled time',
//               textAlign: TextAlign.center,
//               style:  TextStyle(
//                 fontFamily: kFont,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: kPurple,
//                 height: 1.3,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // card
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Center(
//                   child: Container(
//                     width: w * 0.9,
//                     padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(.04),
//                           blurRadius: 16,
//                           offset: const Offset(0, 6),
//                         )
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // name
//                         Text(
//                          name,
//                           style: const TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF1B1B1B),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         _divider(),
//                         _rowLabelValue('Distance', "${distance} miles"),
//                         _divider(),
//                         _rowLabelValue('Role', 'Pro, cleaner'),
//                         _divider(),
//                         Row(
//                           children: [
//                             Row(
//   children: [
//     ...List.generate(5, (index) {
//       final isFilled = index < ratingValue;
//       return Icon(
//         isFilled ? Icons.star_rounded : Icons.star_border_rounded,
//         size: 18,
//         color: isFilled
//             ? const Color(0xFFFFB800)
//             : Colors.grey.shade400,
//       );
//     }),
//     const SizedBox(width: 6),
//     Text(
//       ratingValue == 0 ? 'No rating yet' : ratingValue.toString(),
//       style: TextStyle(
//         fontFamily: 'Poppins',
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//         color: ratingValue == 0
//             ? Colors.grey.shade500
//             : const Color(0xFF5C2D91),
//       ),
//     ),
//   ],
// ),


// // Row(
// //   children: List.generate(5, (index) {
// //     final isFilled = index < ratingValue;

// //     return Icon(
// //       isFilled ? Icons.star_rounded : Icons.star_border_rounded,
// //       color: isFilled ? const Color(0xFFFFB800) : Colors.grey.shade400,
// //       size: 20,
// //     );
// //   }),
// // ),
// //                           //   ...List.generate(
//                           //  int.parse(rating),
//                           //     (i) => const Icon(
//                           //       Icons.star_rounded,
//                           //       color: Color(0xFFFFB800),
//                           //       size: 20,
//                           //     ),
//                           //   ),
//                             const SizedBox(width: 6),
//                              Text(
//                               rating.toString(),
//                               style: const TextStyle(
//                                 fontFamily: kFont,
//                                 fontSize: 13,
//                                 color: kPurple,
//                               ),
//                             )
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         _divider(),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Base cost',
//                           style: TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 12.5,
//                             color: Colors.grey,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                          Text(
//                           'AUD $cost',
//                           style:const TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 17,
//                             fontWeight: FontWeight.w700,
//                             color: kPurple,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // button
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kGreen,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 0,
//                   ),
//                   onPressed: () {
//                      Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => const PaymentMethodScreen(), // <- your real screen
//         ),
//       );
//                   },
//                   child: const Text(
//                     'PROCEED TO PAYMENT',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 15.5,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: .4,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _rowLabelValue(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 13.5,
//               color: Color(0xFF707070),
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF101010),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _divider() => const Divider(
//         height: 18,
//         color: Color(0xFFECE9F5),
//         thickness: 1,
//       );
// }
