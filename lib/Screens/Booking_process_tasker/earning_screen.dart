import 'dart:ui';

import 'package:flutter/material.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

enum _Period { today, week, month }

class _EarningsScreenState extends State<EarningsScreen> {
  _Period period = _Period.today;

  // Mock data (replace with your real data)
  final Map<_Period, double> totals = {
    _Period.today: 200,
    _Period.week: 820,
    _Period.month: 3280,
  };

  final Map<_Period, List<double>> sparkData = {
    _Period.today: [20, 0, 40, 30, 50, 60, 0, 0],
    _Period.week: [120, 40, 80, 140, 60, 220, 160],
    _Period.month: [420, 180, 220, 560, 380, 760, 620, 940, 860, 1120, 980, 1280],
  };

  final List<_EarningItem> recent = List.generate(
    12,
    (i) => _EarningItem(
      name: 'John S.',
      service: 'Cleaning, Pro',
      time: '11:${20 + i % 9} pm',
      amount: 20,
      status: i % 4 == 0
          ? _Status.pending
          : (i % 3 == 0 ? _Status.cancelled : _Status.complete),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final amount = totals[period] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HeaderBar(title: 'Earnings')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: [
                    _SummaryCard(
                      period: period,
                      amount: amount,
                      data: sparkData[period]!,
                      onChange: (p) => setState(() => period = p),
                    ),
                    const SizedBox(height: 14),
                    const _PayoutCard(available: 540),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: '${recent.length} tasks completed',
                      subtitle: 'Last task ended 5 mins ago',
                    ),
                  ],
                ),
              ),
            ),
            // List with manual separators (works across Flutter versions)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final itemIndex = index ~/ 2;
                  if (index.isOdd) {
                    return const Divider(indent: 16, endIndent: 16, height: 1);
                  }
                  return _EarningRow(item: recent[itemIndex]);
                },
                childCount: recent.isEmpty ? 0 : (recent.length * 2 - 1),
              ),
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
            // IconButton(
            //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: _Colors.primary),
            //   onPressed: () => Navigator.of(context).maybePop(),
            // ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: _Colors.primary,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.period,
    required this.amount,
    required this.data,
    required this.onChange,
  });

  final _Period period;
  final double amount;
  final List<double> data;
  final ValueChanged<_Period> onChange;

  String get _subtitle {
    switch (period) {
      case _Period.today:
        return "Today's earnings";
      case _Period.week:
        return 'This week';
      case _Period.month:
        return 'This month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: LayoutBuilder(
          builder: (_, c) {
            final narrow = c.maxWidth < 360;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _subtitle,
                      style: TextStyle(
                        color: _Colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: narrow ? 14 : 16,
                      ),
                    ),
                    const Spacer(),
                    _SegmentSwitch<_Period>(
                      value: period,
                      onChanged: onChange,
                      items: const [
                        SegmentItem(label: 'Today', value: _Period.today),
                        SegmentItem(label: 'Week', value: _Period.week),
                        SegmentItem(label: 'Month', value: _Period.month),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: _Colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      width: c.maxWidth * .36,
                      child: _Sparkline(values: data, color: _Colors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _KpiChip(icon: Icons.task_alt_rounded, label: '12 tasks'),
                    _KpiChip(icon: Icons.schedule_rounded, label: 'Online 5h 12m'),
                    _KpiChip(icon: Icons.star_rounded, label: '4.9 rating'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.available});
  final double available;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: _Colors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _Colors.primaryDark.withOpacity(.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available for payout',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '\$${available.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: _Colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ List Row ------------------------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _Colors.primary, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(.55))),
          ],
        ),
      ),
    );
  }
}

enum _Status { complete, pending, cancelled }

class _EarningItem {
  final String name;
  final String service;
  final String time;
  final double amount;
  final _Status status;
  _EarningItem({
    required this.name,
    required this.service,
    required this.time,
    required this.amount,
    required this.status,
  });
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({required this.item});
  final _EarningItem item;

  @override
  Widget build(BuildContext context) {
    final status = _StatusChip(item.status);
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      title: Text(item.name,
          style: const TextStyle(
              color: _Colors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
      subtitle: Text('${item.service}\n${item.time}'),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$${item.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: _Colors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          status,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final _Status status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (status) {
      case _Status.complete:
        bg = const Color(0xFFE6FBE8);
        fg = const Color(0xFF1B5E20);
        label = 'Complete';
        break;
      case _Status.pending:
        bg = const Color(0xFFFFF5DC);
        fg = const Color(0xFF8A6D1F);
        label = 'Pending';
        break;
      case _Status.cancelled:
        bg = const Color(0xFFFFE7E7);
        fg = const Color(0xFFB71C1C);
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/* ============================ SMALL WIDGETS ============================= */

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _Colors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/* ------------------------- Segment switch (no records) ------------------ */

class SegmentItem<T> {
  final String label;
  final T value;
  const SegmentItem({required this.label, required this.value});
}

class _SegmentSwitch<T> extends StatelessWidget {
  const _SegmentSwitch({
    required this.value,
    required this.onChanged,
    required this.items,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<SegmentItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in items)
            GestureDetector(
              onTap: () => onChanged(it.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      it.value == value ? _Colors.accentGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  it.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: it.value == value ? Colors.black : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ============================== SPARKLINE =============================== */

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, this.color = Colors.black});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklinePainter(values, color));
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = LinearGradient(
        colors: [color.withOpacity(.9), color.withOpacity(.5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset.zero & size);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(.18), color.withOpacity(.0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
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

/* =============================== HELPERS ================================ */

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
                colors: [Colors.white.withOpacity(.90), Colors.white.withOpacity(.76)],
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

class _Colors {
  static const primary = Color(0xFF5C2E91);
  static const primaryDark = Color(0xFF411C6E);
  static const accentGold = Color(0xFFF4C847);
}