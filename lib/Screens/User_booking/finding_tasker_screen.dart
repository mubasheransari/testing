import 'package:flutter/material.dart';

class FindingTaskerScreen extends StatelessWidget {
  const FindingTaskerScreen({super.key});

  static const Color kPurple = Color(0xFF3E0B6F); // base taskoon purple
  static const Color kGold1 = Color(0xFFF2CB6B);
  static const Color kGold2 = Color(0xFFFFE397);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kPurple,
      body: Stack(
        children: [
          // top blob
          Positioned(
            top: -size.height * .18,
            left: -size.width * .2,
            child: _blob(size.width * 1.1, size.width * 1.1,
                const [Color(0xFF5B1A96), kPurple]),
          ),
          // bottom blob
          Positioned(
            bottom: -size.height * .25,
            right: -size.width * .3,
            child: _blob(size.width * 1.2, size.width * 1.1,
                const [kPurple, Color(0xFF5B1A96)]),
          ),

          // center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // concentric gold circle with T
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kGold1, kGold2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPurple,
                        border: Border.all(
                          width: 4,
                          color: Colors.white.withOpacity(.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.25),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk', // if you have it
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Finding your tasker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double w, double h, List<Color> colors) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(.85)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w),
      ),
    );
  }
}
