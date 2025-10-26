import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeaderBar(title: 'Earnings')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: const [
                    _TodayEarningCard(amount: 200),
                    SizedBox(height: 14),
                    _WeeklyEarningCard(amount: 200),
                    SizedBox(height: 22),
                    _CompletedSection(),
                  ],
                ),
              ),
            ),
            // Tasks list
            SliverList.separated(
              itemCount: 12,
              separatorBuilder: (_, __) =>
                  const Divider(indent: 16, endIndent: 16, height: 1),
              itemBuilder: (context, i) => const _TaskRow(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- Header Bar ------------------------------ */

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container
      (
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
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Constants.primaryDark),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Constants.primaryDark,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Cards & Sections --------------------------- */

class _TodayEarningCard extends StatelessWidget {
  const _TodayEarningCard({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color:Constants.primaryDark,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryDark.withOpacity(.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Todays earnings',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('\$$amount',
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 34)),
        ],
      ),
    );
  }
}

class _WeeklyEarningCard extends StatelessWidget {
  const _WeeklyEarningCard({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly earnings',
                style: TextStyle(
                    color:Constants.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text('Sun 00:00 Sat 23:59',
                style: TextStyle(color: Colors.black.withOpacity(.55), fontSize: 12)),
            const SizedBox(height: 10),
            Text('\$$amount',
                style: TextStyle(
                  color: Constants.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                )),
          ],
        ),
      ),
    );
  }
}

class _CompletedSection extends StatelessWidget {
  const _CompletedSection();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 36,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('12 tasks completed',
                style: TextStyle(
                    color: Constants.primaryDark, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 6),
            Text('Last task ended 5 mins ago',
                style: TextStyle(color: Colors.black.withOpacity(.55))),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ List Row ------------------------------- */

class _TaskRow extends StatelessWidget {
  const _TaskRow();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      title: Text('John S.',
          style: TextStyle(
              color:Constants.primaryDark, fontWeight: FontWeight.w800, fontSize: 18)),
      subtitle: const Text('Cleaning, Pro\n11:20 pm'),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$20',
              style: TextStyle(
                  color: Constants.primaryDark, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FBE8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('Complete',
                style: TextStyle(
                    color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Glass Card ----------------------------- */

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.radius = 22, this.margin});
  final Widget child;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
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
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(.90),
                  Colors.white.withOpacity(.76),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.75)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/* ======================== PLACEHOLDER OTHER TABS ======================== */

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderCenter(text: 'Home');
  }
}

class _PlaceholderTasks extends StatelessWidget {
  const _PlaceholderTasks();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderCenter(text: 'Tasks');
  }
}

class _PlaceholderMore extends StatelessWidget {
  const _PlaceholderMore();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderCenter(text: 'More');
  }
}

class _PlaceholderCenter extends StatelessWidget {
  const _PlaceholderCenter({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$text Screen',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}