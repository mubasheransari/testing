import 'package:flutter/material.dart';


class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FB),
        body: SafeArea(
          top: true,
          child: Column(
            children: const [
              SizedBox(height: 8),
              _TasksHeader(title: 'Tasks'),
              SizedBox(height: 10),
              _ChipTabsStrip(tabs: ['History', 'Ongoing', 'Scheduled']),
              SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  physics: BouncingScrollPhysics(),
                  children: [
                    _HistoryTab(),
                    _OngoingTab(),
                    _ScheduledTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================ HEADER & TABS ============================ */

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF5C2E91).withOpacity(.08)),
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
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: _AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: _AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF3E1E69),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                // ✅ keep your support action here
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _AppColors.primary.withOpacity(.18),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded,
                        size: 18, color: _AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Support',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _AppColors.primary,
                      ),
                    ),
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

/// ✅ Chip style TabBar (theme like your chips in UserBookingHome)
class _ChipTabsStrip extends StatelessWidget {
  const _ChipTabsStrip({required this.tabs});
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.primary.withOpacity(.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.02),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(999),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF5C2E91),
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
          indicator: BoxDecoration(
            color: const Color(0xFF5C2E91),
            borderRadius: BorderRadius.circular(999),
          ),
          tabs: [
            for (final t in tabs)
              Tab(
                height: 36,
                text: t,
              ),
          ],
        ),
      ),
    );
  }
}

/* ================================ HISTORY ============================== */

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final items = <_HistoryItem>[
      _HistoryItem(
        name: 'Stephan Micheal',
        code: 'AU737',
        role: 'Cleaner, pro',
        date: 'June 6, 2025',
        time: '10:00',
        amount: 40,
        status: _HStatus.processed,
      ),
      _HistoryItem(
        name: 'Stephan Micheal',
        code: 'AU737',
        role: 'Cleaner, pro',
        date: 'June 6, 2025',
        time: '10:00',
        amount: 40,
        status: _HStatus.disputed,
      ),
      _HistoryItem(
        name: 'Stephan Micheal',
        code: 'AU737',
        role: 'Cleaner, pro',
        date: 'June 6, 2025',
        time: '10:00',
        amount: 40,
        status: _HStatus.cancelled,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemBuilder: (_, i) => _HistoryCard(item: items[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: items.length,
    );
  }
}

enum _HStatus { processed, disputed, cancelled }

class _HistoryItem {
  final String name, code, role, date, time;
  final double amount;
  final _HStatus status;
  _HistoryItem({
    required this.name,
    required this.code,
    required this.role,
    required this.date,
    required this.time,
    required this.amount,
    required this.status,
  });
}

class _StatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _StatusStyle(this.label, this.bg, this.fg, this.icon);

  static _StatusStyle from(_HStatus s) {
    switch (s) {
      case _HStatus.processed:
        return const _StatusStyle(
          'Processed',
          Color(0xFFEFF8F4),
          Color(0xFF1E8E66),
          Icons.check_circle_rounded,
        );
      case _HStatus.disputed:
        return const _StatusStyle(
          'Disputed',
          Color(0xFFFFF4E8),
          Color(0xFFEE8A41),
          Icons.report_rounded,
        );
      case _HStatus.cancelled:
        return const _StatusStyle(
          'Cancelled',
          Color(0xFFFFECEC),
          Color(0xFFC62828),
          Icons.cancel_rounded,
        );
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final style = _StatusStyle.from(item.status);

    return _ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF3E1E69),
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.role,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF75748A),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoDot(icon: Icons.calendar_month_rounded, text: item.date),
                const SizedBox(width: 10),
                _InfoDot(icon: Icons.schedule_rounded, text: item.time),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: style.fg.withOpacity(.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 16, color: style.fg),
                      const SizedBox(width: 6),
                      Text(
                        style.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: style.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.black.withOpacity(.06),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF75748A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$ ${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: style.fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ================================ ONGOING ============================== */

class _OngoingTab extends StatelessWidget {
  const _OngoingTab();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      4,
      (i) => _OngoingItem(
        name: 'Stephan Micheal',
        code: 'AU737',
        role: 'Cleaner, pro',
        remaining: '45:0${7 - (i % 4)}',
      ),
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemBuilder: (_, i) => _OngoingCard(item: items[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: items.length,
    );
  }
}

class _OngoingItem {
  final String name, code, role, remaining;
  _OngoingItem({
    required this.name,
    required this.code,
    required this.role,
    required this.remaining,
  });
}

class _OngoingCard extends StatelessWidget {
  const _OngoingCard({required this.item});
  final _OngoingItem item;

  @override
  Widget build(BuildContext context) {
    return _ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF3E1E69),
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.role,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF75748A),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _AppColors.primary.withOpacity(.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _AppColors.primary.withOpacity(.14)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 18, color: _AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: _AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: _AppColors.primary.withOpacity(.20)),
                    ),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.black.withOpacity(.06)),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  'Remaining time',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF75748A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: _AppColors.primary.withOpacity(.16)),
                  ),
                  child: Text(
                    item.remaining,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================== SCHEDULED ============================= */

class _ScheduledTab extends StatelessWidget {
  const _ScheduledTab();

  @override
  Widget build(BuildContext context) {
    final items = <_ScheduledItem>[
      _ScheduledItem(
        name: 'Stephan Micheal',
        code: 'AU737',
        role: 'Cleaner, pro',
        date: 'June 8, 2025',
        time: '09:30',
      ),
      _ScheduledItem(
        name: 'Anna J.',
        code: 'AU910',
        role: 'Packing, pro',
        date: 'June 10, 2025',
        time: '12:15',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemBuilder: (_, i) => _ScheduledCard(item: items[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: items.length,
    );
  }
}

class _ScheduledItem {
  final String name, code, role, date, time;
  _ScheduledItem({
    required this.name,
    required this.code,
    required this.role,
    required this.date,
    required this.time,
  });
}

class _ScheduledCard extends StatelessWidget {
  const _ScheduledCard({required this.item});
  final _ScheduledItem item;

  @override
  Widget build(BuildContext context) {
    return _ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF3E1E69),
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.role,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF75748A),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _InfoDot(icon: Icons.calendar_month_rounded, text: item.date),
                const SizedBox(width: 10),
                _InfoDot(icon: Icons.schedule_rounded, text: item.time),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: Colors.black.withOpacity(.06)),
            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withOpacity(.06),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: _AppColors.primary.withOpacity(.14)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_rounded,
                          color: _AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Starts soon',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                          color: _AppColors.primary.withOpacity(.20)),
                    ),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== UTIL WIDGETS =========================== */

class _ModernCard extends StatelessWidget {
  const _ModernCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.primary.withOpacity(.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoDot extends StatelessWidget {
  const _InfoDot({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF75748A)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AppColors {
  static const primary = Color(0xFF5C2E91);
  static const primaryDark = Color(0xFF411C6E);
}
