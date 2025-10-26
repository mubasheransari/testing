import 'package:flutter/material.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  // App colors
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kPrimaryDark = Color(0xFF411C6E);
  static const Color kCardBorder = Color(0xFFE8E2F5);
  static const Color kCardShadow = Color(0x1A000000); // ~10% black

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F7FB);

    return Scaffold(
      backgroundColor: bg,
      // Modern rounded app bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: kCardShadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: kCardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: kPrimary),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Guidelines',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlassCard(
              child: Text(
                "Welcome to Taskoon! To ensure a smooth and trustworthy experience for everyone, "
                "we ask all users and taskers to follow these basic guidelines.\n\n"
                "Booking & Communication — Always provide clear and accurate task details before "
                "confirming a booking. Communicate promptly and respectfully through the Taskoon platform.\n\n"
                "Service Execution — Taskers should arrive on time and complete tasks as agreed. "
                "Users should approve check-ins and check-outs on time to avoid billing issues.\n\n"
                "Report any safety concerns, issues, or misconduct immediately through the help center.",
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table title (optional)
            const Text(
              'Activity overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Pretty rounded table card
            _RoundedTable(
              headers: const ['ACTIVITY', 'TIME', 'NUMBER OF\nTASKERS'],
              rows: const [
                ['—', '—', '—'],
                ['—', '—', '—'],
                ['—', '—', '—'],
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // If you already have a global bottom bar, replace with your widget.
      bottomNavigationBar: const _GlassBottomBar(currentIndex: 3),
    );
  }
}

/* ------------------------------ Building blocks ----------------------------- */

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GuidelinesScreen.kCardBorder),
        boxShadow: const [
          BoxShadow(color: GuidelinesScreen.kCardShadow, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _RoundedTable extends StatelessWidget {
  const _RoundedTable({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final borderColor = GuidelinesScreen.kCardBorder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: GuidelinesScreen.kCardShadow, blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.3),
            1: FlexColumnWidth(1.0),
            2: FlexColumnWidth(1.2),
          },
          border: TableBorder.symmetric(
            inside: BorderSide(color: borderColor),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: const Color(0xFFF4EEFB),
              ),
              children: headers
                  .map((h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        alignment: Alignment.center,
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GuidelinesScreen.kPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            for (final row in rows)
              TableRow(
                children: row
                    .map(
                      (cell) => Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
                        child: Text(
                          cell,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- Glassy Bottom Navigation ------------------------- */

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: GuidelinesScreen.kCardBorder),
            boxShadow: const [
              BoxShadow(color: GuidelinesScreen.kCardShadow, blurRadius: 22, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _NavItem(icon: Icons.attach_money_rounded, label: 'Earning', index: 1),
              _NavItem(icon: Icons.article_rounded, label: 'Tasks', index: 2),
              _NavItem(icon: Icons.menu_rounded, label: 'More', index: 3, selected: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GuidelinesScreen.kPrimary : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigate to your tab screens here
        // e.g., context.read<AppNav>().go(index);
      },
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
