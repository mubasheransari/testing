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

  // Totals
  final Map<_Period, double> totals = {
    _Period.today: 200,
    _Period.week: 820,
    _Period.month: 3280,
  };

  // Small spark data for the summary
  final Map<_Period, List<double>> sparkData = {
    _Period.today: [20, 0, 40, 30, 50, 60, 0, 0],
    _Period.week: [120, 40, 80, 140, 60, 220, 160],
    _Period.month: [420, 180, 220, 560, 380, 760, 620, 940, 860, 1120, 980, 1280],
  };

  // Big chart datasets (labels + values)
  final Map<_Period, ChartData> chart = {
    _Period.today: ChartData(
      labels: ['9a', '11a', '1p', '3p', '5p', '7p', '9p'],
      values: [15, 20, 40, 35, 55, 28, 7],
    ),
    _Period.week: ChartData(
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      values: [120, 40, 80, 140, 60, 220, 160],
    ),
    _Period.month: ChartData(
      labels: ['W1', 'W2', 'W3', 'W4'],
      values: [820, 620, 940, 900],
    ),
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
                    // NEW — Interactive graph card
                    _EarningsGraphCard(
                      period: period,
                      data: chart[period]!,
                      onChangePeriod: (p) => setState(() => period = p),
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
            // manual separators for broad version support
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final itemIndex = index ~/ 2;
                  if (index.isOdd) return const Divider(indent: 16, endIndent: 16, height: 1);
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

/* ========================= NEW: EARNINGS GRAPH CARD ===================== */

class ChartData {
  final List<String> labels;
  final List<double> values;
  const ChartData({required this.labels, required this.values});
}

class _EarningsGraphCard extends StatelessWidget {
  const _EarningsGraphCard({
    required this.period,
    required this.data,
    required this.onChangePeriod,
  });

  final _Period period;
  final ChartData data;
  final ValueChanged<_Period> onChangePeriod;

  String get _title => 'Earnings chart';

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + segment
            Row(
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: _Colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _SegmentSwitch<_Period>(
                  value: period,
                  onChanged: onChangePeriod,
                  items: const [
                    SegmentItem(label: 'Today', value: _Period.today),
                    SegmentItem(label: 'Week', value: _Period.week),
                    SegmentItem(label: 'Month', value: _Period.month),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Big chart
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _InteractiveLineChart(
                values: data.values,
                labels: data.labels,
                color: _Colors.primary,
                showGrid: true,
              ),
            ),
            const SizedBox(height: 10),
            // Little legend
            Row(
              children: const [
                _LegendDot(color: _Colors.primary),
                SizedBox(width: 6),
                Text('Income'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFF9C7CCB)),
                SizedBox(width: 6),
                Text('Target (visual only)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/* ------------------------ Interactive Line Chart ------------------------ */

class _InteractiveLineChart extends StatefulWidget {
  const _InteractiveLineChart({
    required this.values,
    required this.labels,
    required this.color,
    this.showGrid = true,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final bool showGrid;

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        return GestureDetector(
          onPanDown: (d) => _updateHover(c, d.localPosition.dx),
          onPanUpdate: (d) => _updateHover(c, d.localPosition.dx),
          onTapDown: (d) => _updateHover(c, d.localPosition.dx),
          onPanEnd: (_) => setState(() => _hoverIndex = null),
          onTapUp: (_) => setState(() => _hoverIndex = null),
          child: CustomPaint(
            painter: _LineChartPainter(
              values: widget.values,
              labels: widget.labels,
              color: widget.color,
              showGrid: widget.showGrid,
              hoverIndex: _hoverIndex,
            ),
          ),
        );
      },
    );
  }

  void _updateHover(BoxConstraints c, double dx) {
    final count = widget.values.length;
    if (count <= 1) return;
    final chartW = c.maxWidth;
    final step = chartW / (count - 1);
    int i = (dx / step).round().clamp(0, count - 1);
    setState(() => _hoverIndex = i);
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.showGrid,
    required this.hoverIndex,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final bool showGrid;
  final int? hoverIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Padding for axes labels/cursor bubble
    final chartRect = Rect.fromLTWH(8, 6, size.width - 16, size.height - 22);

    // Scale
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    double xAt(int i) =>
        chartRect.left + i * (chartRect.width / (values.length - 1));
    double yAt(double v) =>
        chartRect.bottom - ((v - minV) / range) * chartRect.height;

    // Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke;
      const lines = 4;
      for (int g = 0; g <= lines; g++) {
        final y = chartRect.top + g * (chartRect.height / lines);
        canvas.drawLine(Offset(chartRect.left, y),
            Offset(chartRect.right, y), gridPaint);
      }
    }

    // Area fill under the line
    final area = Path()..moveTo(xAt(0), yAt(values[0]));
    for (int i = 1; i < values.length; i++) {
      area.lineTo(xAt(i), yAt(values[i]));
    }
    area
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(.28), color.withOpacity(0)],
      ).createShader(chartRect);
    canvas.drawPath(area, fill);

    // Line
    final path = Path()..moveTo(xAt(0), yAt(values[0]));
    for (int i = 1; i < values.length; i++) {
      path.lineTo(xAt(i), yAt(values[i]));
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(.6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(chartRect);
    canvas.drawPath(path, stroke);

    // X labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      tp.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      );
      tp.layout();
      final dx = (i == 0)
          ? xAt(i)
          : (i == labels.length - 1)
              ? xAt(i) - tp.width
              : xAt(i) - tp.width / 2;
      tp.paint(canvas, Offset(dx, chartRect.bottom + 2));
    }

    // Hover indicator
    if (hoverIndex != null) {
      final hx = xAt(hoverIndex!);
      final hy = yAt(values[hoverIndex!]);

      final vline = Paint()
        ..color = color.withOpacity(.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(hx, chartRect.top), Offset(hx, chartRect.bottom), vline);

      // Dot
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(hx, hy), 4, dotPaint);

      // Bubble
      final valueStr = '\$${values[hoverIndex!].toStringAsFixed(0)}';
      final bubble = TextPainter(
        text: TextSpan(
          text: valueStr,
          style: const TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bw = bubble.width + 12;
      final bh = bubble.height + 8;
      final bx = (hx - bw / 2).clamp(chartRect.left, chartRect.right - bw);
      final by = (hy - 26 - bh).clamp(chartRect.top, chartRect.bottom - bh);

      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(10));
      final bubblePaint = Paint()..color = color.withOpacity(.95);
      canvas.drawRRect(rrect, bubblePaint);
      bubble.paint(canvas, Offset(bx + 6, by + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.color != color ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.showGrid != showGrid;
  }
}

/* =============================== PAYOUT CARD ============================ */

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
        padding: const EdgeInsets.fromLTRB(19, 16, 16, 14),
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
    return SizedBox(
  
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
           // const SizedBox(width: 9),
            status,
          ],
        ),
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
      width: MediaQuery.of(context).size.width *0.95,
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
