// import 'package:flutter/material.dart';

// class CustomButton extends StatelessWidget {
//   final VoidCallback onTap;
//   final String buttonText;
//   final String iconName;
//   final Color bgcolor;
//   final Color textColor;
//   final Color borderColor;
//   final double height;
//   final double width;

//   const CustomButton({
//     Key? key,
//     required this.onTap,
//     required this.buttonText,
//     required this.iconName,
//     this.bgcolor = const Color(0xFF3B82F6), // Default to Constants().themeColor
//     this.textColor = Colors.white,
//     this.borderColor = Colors.transparent,
//     this.height = 60,
//     this.width = 376,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width,
//       height: height,
//       child: Center(
//         child: ElevatedButton(
//           onPressed: onTap,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: bgcolor,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30),
//               side: BorderSide(color: borderColor, width: 2),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 buttonText,
//                 style: TextStyle(
//                   color: textColor,
//                   fontFamily: 'Satoshi',
//                   fontSize: 20,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Image.asset(
//                 iconName,
//                 width: 20,
//                 height: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../Constants/constants.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final String buttonText;
  final String iconName;

  // final bool isIconRequiredDefault;

  CustomButton({
    Key? key,
    required this.onTap,
    required this.buttonText,
    required this.iconName,

    // required this.isIconRequiredDefault = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 376,
      height: 60,
      child: Center(
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            surfaceTintColor: Colors.black,

            // minimumSize: const Size(200, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Satoshi',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              // isIconRequired == true?
              Image.asset(
                iconName,
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
