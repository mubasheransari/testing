import 'package:flutter/material.dart';


class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final String buttonText;
  final String iconName;


  CustomButton({
    Key? key,
    required this.onTap,
    required this.buttonText,
    required this.iconName,
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
