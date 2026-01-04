import 'package:flutter/material.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  // Theme
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kBg = Color(0xFFF7F6FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeaderCard(
                title: 'Guidelines',
                left: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimary),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WhiteCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 34,
                                  width: 34,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.info_outline_rounded,
                                      color: kPrimary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Read this to avoid issues',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.5,
                                      color: Color(0xFF3E1E69),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Welcome to Taskoon! To keep the platform safe and trustworthy for everyone, "
                              "please follow these guidelines.\n",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.8,
                                height: 1.45,
                                color: const Color(0xFF75748A).withOpacity(.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const _GuidelineItem(
                              title: 'Booking & Communication',
                              body:
                                  'Provide clear task details before confirming. Communicate promptly and respectfully inside Taskoon.',
                              icon: Icons.chat_bubble_outline_rounded,
                            ),
                            const SizedBox(height: 10),
                            const _GuidelineItem(
                              title: 'Service Execution',
                              body:
                                  'Taskers should arrive on time and complete work as agreed. Users should approve check-in/check-out on time.',
                              icon: Icons.handyman_rounded,
                            ),
                            const SizedBox(height: 10),
                            const _GuidelineItem(
                              title: 'Safety & Support',
                              body:
                                  'Report any safety concerns or misconduct immediately through the help center.',
                              icon: Icons.shield_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.table_chart_rounded,
                              color: kPrimary, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Activity overview',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E1E69),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Modern responsive table card
                    _WhiteCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _RoundedTable(
                          headers: const ['ACTIVITY', 'TIME', 'NUMBER OF TASKERS'],
                          rows: const [
                            ['—', '—', '—'],
                            ['—', '—', '—'],
                            ['—', '—', '—'],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ Small hint pill
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kPrimary.withOpacity(.14)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: kPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Tip: Use Support if any issue happens.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: kPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),


    );
  }
}


class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.left, this.right});

  final String title;
  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GuidelinesScreen.kPrimary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          left,
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF3E1E69),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (right != null) right!,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GuidelinesScreen.kPrimary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ============================ CONTENT WIDGETS ============================ */

class _GuidelineItem extends StatelessWidget {
  const _GuidelineItem({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuidelinesScreen.kPrimary.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GuidelinesScreen.kPrimary.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: GuidelinesScreen.kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: GuidelinesScreen.kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: Color(0xFF3E1E69),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.3,
                    height: 1.35,
                    color: const Color(0xFF75748A).withOpacity(.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================ RESPONSIVE TABLE ============================ */

class _RoundedTable extends StatelessWidget {
  const _RoundedTable({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;

        // ✅ Prevent overflow on small widths
        // Use tighter padding if the card is narrow
        final cellHPad = w < 340 ? 8.0 : 12.0;
        final headStyle = TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w900,
          fontSize: w < 340 ? 11.0 : 12.0,
          color: GuidelinesScreen.kPrimary,
        );

        final cellStyle = TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: w < 340 ? 12.0 : 13.0,
          color: const Color(0xFF3E1E69),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GuidelinesScreen.kPrimary.withOpacity(.10)),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.25),
                1: FlexColumnWidth(0.85),
                2: FlexColumnWidth(1.15),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: GuidelinesScreen.kPrimary.withOpacity(.10)),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: GuidelinesScreen.kPrimary.withOpacity(.06),
                  ),
                  children: headers
                      .map(
                        (h) => Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: cellHPad,
                            vertical: 12,
                          ),
                          child: Text(
                            h,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: headStyle,
                          ),
                        ),
                      )
                      .toList(),
                ),
                for (final row in rows)
                  TableRow(
                    children: row
                        .map(
                          (cell) => Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: cellHPad,
                              vertical: 16,
                            ),
                            child: Text(
                              cell,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: cellStyle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
