import 'dart:ui';

import 'package:flutter/material.dart';

class _Colors {
  static const primary = Color(0xFF5C2E91);
  static const primaryDark = Color(0xFF411C6E);
}


class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: const [
            _HeaderWithSupport(title: 'Tasks'),
            SizedBox(height: 8),
            _TabsStrip(tabs: ['History', 'Ongoing', 'Scheduled']),
            SizedBox(height: 6),
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
    );
  }
}

/* ============================ HEADER & TABS ============================ */

class _HeaderWithSupport extends StatelessWidget {
  const _HeaderWithSupport({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
         
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                color: _AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: const Text(
                'Support',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5E6272),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabsStrip extends StatelessWidget {
  const _TabsStrip({required this.tabs});
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _AppColors.primary,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _AppColors.primary, width: 3),
        ),
        tabs: [for (final t in tabs) Tab(text: t)],
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
  final Color color;
  const _StatusStyle(this.label, this.color);

  static _StatusStyle from(_HStatus s) {
    switch (s) {
      case _HStatus.processed:
        return const _StatusStyle('Processed', Color(0xFF2E7D32));
      case _HStatus.disputed:
        return const _StatusStyle('Disputed', Color(0xFFD9A21B));
      case _HStatus.cancelled:
        return const _StatusStyle('Cancelled', Color(0xFFC62828));
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final style = _StatusStyle.from(item.status);

    return _GlassCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.role, style: TextStyle(color: Colors.black.withOpacity(.55))),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(item.date, style: TextStyle(color: Colors.black.withOpacity(.55))),
                const Spacer(),
                Text(item.time,
                    style: TextStyle(color: Colors.black.withOpacity(.55))),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  style.label,
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$ ${item.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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
    return _GlassCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.role, style: TextStyle(color: Colors.black.withOpacity(.55))),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: Colors.black.withOpacity(.55)),
                const SizedBox(width: 8),
                Text('Chat', style: TextStyle(color: Colors.black.withOpacity(.55))),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _AppColors.primary.withOpacity(.25)),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Remaining time',
                  style: TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  item.remaining,
                  style: const TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
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
    return _GlassCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  item.code,
                  style: const TextStyle(
                    color: _AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.role, style: TextStyle(color: Colors.black.withOpacity(.55))),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(item.date, style: TextStyle(color: Colors.black.withOpacity(.55))),
                const Spacer(),
                Text(item.time,
                    style: TextStyle(color: Colors.black.withOpacity(.55))),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.alarm_rounded, color: _AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Starts soon',
                  style: TextStyle(
                    color: Colors.black.withOpacity(.70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Details',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: _AppColors.primary),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.radius = 22});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF0ECF6)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AppColors {
  static const primary = Color(0xFF5C2E91);
  static const primaryDark = Color(0xFF411C6E);
}
