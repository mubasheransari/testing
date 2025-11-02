import 'package:flutter/material.dart';

class TaskerConfirmationScreen extends StatelessWidget {
  const TaskerConfirmationScreen({super.key});

  static const Color kPurple = Color(0xFF5C2D91);
  static const Color kGreen = Color(0xFF2F7D32);
  static const String kFont = 'Poppins'; // make sure added in pubspec.yaml

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPurple),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                const  Text(
                    'Tasker assigned',
                style: TextStyle(
                fontFamily: 'Poppins',
            fontSize: 22,
            color: Color(0xFF4A2C73),
            fontWeight: FontWeight.w500,
          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // avatar + title
            Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFDA57),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/trained_cleaners.png', // replace with your asset
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your tasker will arrive at your\nscheduled time',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kFont,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: kPurple,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // card
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: w * 0.9,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name
                        Text(
                          'Micheal Stance',
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _divider(),
                        _rowLabelValue('Distance', '3.1 mi'),
                        _divider(),
                        _rowLabelValue('Role', 'Pro, cleaner'),
                        _divider(),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '(5)',
                              style: TextStyle(
                                fontFamily: kFont,
                                fontSize: 13,
                                color: kPurple,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        _divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Base cost',
                          style: TextStyle(
                            fontFamily: kFont,
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AUD 55.00',
                          style: TextStyle(
                            fontFamily: kFont,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // go to payment
                  },
                  child: const Text(
                    'PROCEED TO PAYMENT',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
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
              color: Color(0xFF707070),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 18,
        color: Color(0xFFECE9F5),
        thickness: 1,
      );
}
