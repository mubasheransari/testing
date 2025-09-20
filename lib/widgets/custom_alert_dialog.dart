import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
class DialogWidget extends StatelessWidget {
  final VoidCallback onGoBackPressed;
  final VoidCallback onCancelPressed;
  final Widget goBackText;
  final Widget cancelText;
  final String icon;

  const DialogWidget({
    super.key,
    required this.onGoBackPressed,
    required this.onCancelPressed,
    required this.goBackText,
    required this.cancelText,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 24, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Image.asset(
              icon,
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 10),
            const Text(
              "title",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "description",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onGoBackPressed,
                    style: ElevatedButton.styleFrom(
                    //  col :  Color(0xFF407BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: goBackText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancelPressed,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF407BFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: cancelText,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
