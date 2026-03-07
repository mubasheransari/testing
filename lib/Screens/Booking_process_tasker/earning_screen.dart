import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_chart_model.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_tasks_response.dart';


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_chart_model.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_tasks_response.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

enum _Period { today, week, month }

class _EarningsScreenState extends State<EarningsScreen> {
  _Period period = _Period.today;

  final Map<_Period, List<double>> sparkData = {
    _Period.today: [20, 0, 40, 30, 50, 60, 0, 0],
    _Period.week: [120, 40, 80, 140, 60, 220, 160],
    _Period.month: [
      420,
      180,
      220,
      560,
      380,
      760,
      620,
      940,
      860,
      1120,
      980,
      1280,
    ],
  };

  final Map<_Period, ChartData> chartFallback = {
    _Period.today: const ChartData(
      labels: ['9a', '11a', '1p', '3p', '5p', '7p', '9p'],
      values: [15, 20, 40, 35, 55, 28, 7],
    ),
    _Period.week: const ChartData(
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      values: [120, 40, 80, 140, 60, 220, 160],
    ),
    _Period.month: const ChartData(
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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = GetStorage().read('userId')?.toString() ?? '';
      if (userId.isEmpty) return;

      final bloc = context.read<UserBookingBloc>();

      bloc.add(
        FetchTaskerEarningsChartRequested(
          userId: userId,
          period: _apiPeriod(period),
        ),
      );

      bloc.add(
        FetchTaskerEarningsTasksRequested(userId: userId),
      );
    });
  }

  String _apiPeriod(_Period p) {
    switch (p) {
      case _Period.today:
        return 'today';
      case _Period.week:
        return 'week';
      case _Period.month:
        return 'month';
    }
  }

  ChartData _toChartDataFromCache(
    Map<String, TaskerEarningsChartResponse> chartCache,
    _Period p,
  ) {
    final resp = chartCache[_apiPeriod(p)];
    final list = resp?.result?.chartData ?? const <TaskerEarningsChartPoint>[];

    if (list.isEmpty) {
      return chartFallback[p] ?? const ChartData(labels: [], values: []);
    }

    final labels = <String>[];
    final values = <double>[];

    for (final e in list) {
      labels.add(e.label);
      values.add(e.amount);
    }

    return ChartData(labels: labels, values: values);
  }

  double _sum(List<double> v) {
    double t = 0;
    for (final x in v) {
      t += x;
    }
    return t;
  }

  List<_EarningItem> _mapRecentTasks(List<TaskerRecentTask> list) {
  if (list.isEmpty) return [];

  return list.map((e) {
    return _EarningItem(
      name: e.name,
      service: e.service,
      time: e.time,
      amount: e.amount,
      status: _mapStatus(e.status),
    );
  }).toList();
}

  // List<_EarningItem> _mapRecentTasks(List<TaskerRecentTask> list) {
  //   if (list.isEmpty) return recent;

  //   return list.map((e) {
  //     return _EarningItem(
  //       name: e.name,
  //       service: e.service,
  //       time: e.time,
  //       amount: e.amount,
  //       status: _mapStatus(e.status),
  //     );
  //   }).toList();
  // }

  _Status _mapStatus(String value) {
    final v = value.toLowerCase().trim();

    if (v.contains('pending')) return _Status.pending;
    if (v.contains('cancel')) return _Status.cancelled;
    return _Status.complete;
  }

  void _onPeriodChanged(_Period p) {
    setState(() => period = p);

    final userId = GetStorage().read('userId')?.toString() ?? '';
    if (userId.isEmpty) return;

    context.read<UserBookingBloc>().add(
          FetchTaskerEarningsChartRequested(
            userId: userId,
            period: _apiPeriod(p),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return BlocBuilder<UserBookingBloc, UserBookingState>(
      buildWhen: (p, n) =>
          p.taskerEarningsChartByPeriod != n.taskerEarningsChartByPeriod ||
          p.taskerEarningsStatsResponse != n.taskerEarningsStatsResponse ||
          p.taskerEarningsStatsStatus != n.taskerEarningsStatsStatus ||
          p.taskerEarningsTasksResponse != n.taskerEarningsTasksResponse ||
          p.taskerEarningsTasksStatus != n.taskerEarningsTasksStatus,
      builder: (context, state) {
        final stats = state.taskerEarningsStatsResponse?.result;
        final tasksData = state.taskerEarningsTasksResponse?.result;

        final apiChart = _toChartDataFromCache(
          state.taskerEarningsChartByPeriod,
          period,
        );

        final amount = stats?.earnings?.toDouble() ?? _sum(apiChart.values);
        final tasksCompleted =
            tasksData?.totalTasksCompleted ?? stats?.tasksCompleted ?? 0;
        final onlineTime = stats?.onlineTime ?? '0h 0m';
        final rating = (stats?.rating ?? 0).toDouble();
        final availableForPayout = tasksData?.availableForPayout ?? 0;
        final recentItems = _mapRecentTasks(
          tasksData?.recentTasks ?? const <TaskerRecentTask>[],
        );
        print("RECENT TASKS $recentItems");
        print("RECENT TASKS $recentItems");
        print("RECENT TASKS $recentItems");

        return Scaffold(
          backgroundColor: c.bg,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(
                      children: [
                        _SummaryCard(
                          period: period,
                          amount: amount,
                          data: apiChart.values.isNotEmpty
                              ? apiChart.values
                              : (sparkData[period] ?? const []),
                          tasksCompleted: tasksCompleted,
                          onlineTime: onlineTime,
                          rating: rating,
                          onChange: _onPeriodChanged,
                        ),
                        const SizedBox(height: 14),
                        _EarningsGraphCard(
                          period: period,
                          data: apiChart,
                          onChangePeriod: _onPeriodChanged,
                        ),
                        const SizedBox(height: 14),
                        _PayoutCard(available: availableForPayout),
                        const SizedBox(height: 18),
                        _SectionTitle(
  title: '$tasksCompleted tasks completed',
  subtitle: 'Keep going — your stats update live',
),
                        // _SectionTitle(
                        //   title: tasksCompleted > 0
                        //       ? '$tasksCompleted tasks completed'
                        //       : 'Tasks completed',
                        //   subtitle: 'Keep going — your stats update live',
                        // ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (recentItems.isEmpty)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              "No recent tasks",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Your completed jobs will appear here",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  )
else
  SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final itemIndex = index ~/ 2;

          if (index.isOdd) {
            return Divider(
              height: 18,
              thickness: 1,
              color: Colors.black.withOpacity(.06),
            );
          }

          return _EarningRow(item: recentItems[itemIndex]);
        },
        childCount: recentItems.length * 2 - 1,
      ),
    ),
  ),
                // SliverPadding(
                //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                //   sliver: SliverList(
                //     delegate: SliverChildBuilderDelegate(
                //       (context, index) {
                //         final itemIndex = index ~/ 2;
                //         if (index.isOdd) {
                //           return Divider(
                //             height: 18,
                //             thickness: 1,
                //             color: Colors.black.withOpacity(.06),
                //           );
                //         }
                //         return _EarningRow(item: recentItems[itemIndex]);
                //       },
                //       childCount:
                //           recentItems.isEmpty ? 0 : (recentItems.length * 2 - 1),
                //     ),
                //   ),
                // ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ============================== THEME TOKENS ============================== */

class _Colors {
  static const Constants = _ColorConstants();
}

class _ColorConstants {
  const _ColorConstants();

  final Color primaryDark = const Color(0xFF5C2E91);
  final Color primaryText = const Color(0xFF3E1E69);
  final Color mutedText = const Color(0xFF75748A);
  final Color bg = const Color(0xFFF8F7FB);
  final Color gold = const Color(0xFFF4C847);

  final Color card = Colors.white;
  final Color border = const Color(0xFFF0ECF6);
}

/* ============================== SUMMARY CARD ============================== */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.period,
    required this.amount,
    required this.data,
    required this.onChange,
    required this.tasksCompleted,
    required this.onlineTime,
    required this.rating,
  });

  final _Period period;
  final double amount;
  final List<double> data;
  final ValueChanged<_Period> onChange;

  final int tasksCompleted;
  final String onlineTime;
  final double rating;

  String get _subtitle {
    switch (period) {
      case _Period.today:
        return "Today";
      case _Period.week:
        return 'This week';
      case _Period.month:
        return 'This month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return _GlassCard(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: LayoutBuilder(
          builder: (_, cc) {
            final narrow = cc.maxWidth < 360;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: c.primaryText,
                        fontWeight: FontWeight.w900,
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: c.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      width: cc.maxWidth * .36,
                      child: _Sparkline(values: data, color: c.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _KpiChip(
                      icon: Icons.task_alt_rounded,
                      label: '$tasksCompleted tasks',
                    ),
                    _KpiChip(
                      icon: Icons.schedule_rounded,
                      label: 'Online $onlineTime',
                    ),
                    _KpiChip(
                      icon: Icons.star_rounded,
                      label: '${rating.toStringAsFixed(1)} rating',
                    ),
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

/* ========================= EARNINGS GRAPH CARD ========================= */

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

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return _GlassCard(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Earnings chart',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: c.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(width: 2),
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _InteractiveLineChart(
                values: data.values,
                labels: data.labels,
                color: c.primaryDark,
                showGrid: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _LegendDot(color: c.primaryDark),
                const SizedBox(width: 6),
                const Text('Income', style: TextStyle(fontFamily: 'Poppins')),
                const SizedBox(width: 16),
                _LegendDot(color: c.primaryDark.withOpacity(.35)),
                const SizedBox(width: 6),
                const Text(
                  'Target (visual only)',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/* ========================= Interactive Line Chart ========================= */

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
    final i = (dx / step).round().clamp(0, count - 1);
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

    final chartRect = Rect.fromLTWH(8, 6, size.width - 16, size.height - 22);

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    double xAt(int i) =>
        chartRect.left + i * (chartRect.width / (values.length - 1));
    double yAt(double v) =>
        chartRect.bottom - ((v - minV) / range) * chartRect.height;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke;
      const lines = 4;
      for (int g = 0; g <= lines; g++) {
        final y = chartRect.top + g * (chartRect.height / lines);
        canvas.drawLine(
          Offset(chartRect.left, y),
          Offset(chartRect.right, y),
          gridPaint,
        );
      }
    }

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
        colors: [color.withOpacity(.26), color.withOpacity(0)],
      ).createShader(chartRect);
    canvas.drawPath(area, fill);

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

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: Colors.black54,
        ),
      );
      tp.layout();
      final dx = (i == 0)
          ? xAt(i)
          : (i == labels.length - 1)
              ? xAt(i) - tp.width
              : xAt(i) - tp.width / 2;
      tp.paint(canvas, Offset(dx, chartRect.bottom + 2));
    }

    if (hoverIndex != null) {
      final hx = xAt(hoverIndex!);
      final hy = yAt(values[hoverIndex!]);

      final vline = Paint()
        ..color = color.withOpacity(.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(hx, chartRect.top),
        Offset(hx, chartRect.bottom),
        vline,
      );

      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(hx, hy), 4, dotPaint);

      final valueStr = '\$${values[hoverIndex!].toStringAsFixed(0)}';
      final bubble = TextPainter(
        text: TextSpan(
          text: valueStr,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bw = bubble.width + 12;
      final bh = bubble.height + 8;
      final bx = (hx - bw / 2).clamp(chartRect.left, chartRect.right - bw);
      final by = (hy - 26 - bh).clamp(chartRect.top, chartRect.bottom - bh);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(10),
      );
      final bubblePaint = Paint()..color = color.withOpacity(.95);
      canvas.drawRRect(rrect, bubblePaint);
      bubble.paint(canvas, Offset(bx + 6, by + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) {
    return old.values != values ||
        old.labels != labels ||
        old.color != color ||
        old.hoverIndex != hoverIndex ||
        old.showGrid != showGrid;
  }
}

/* ============================== PAYOUT CARD ============================== */

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.available});
  final double available;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primaryDark, c.primaryDark.withOpacity(.86)],
        ),
        boxShadow: [
          BoxShadow(
            color: c.primaryDark.withOpacity(.26),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available for payout',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${available.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: c.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Withdraw',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== SECTION TITLE ============================== */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return _GlassCard(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: c.primaryText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: c.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== EARNING ROW ============================== */

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
    final c = _Colors.Constants;

    return _GlassCard(
      radius: 22,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.primaryDark.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.primaryDark.withOpacity(.12)),
          ),
          child: Icon(Icons.receipt_long_rounded, color: c.primaryDark),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: c.primaryText,
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${item.service}\n${item.time}',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: c.mutedText,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 92),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '\$${item.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: c.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _StatusChip(item.status),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/* ============================== KPI CHIP ============================== */

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = _Colors.Constants;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.primaryDark.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primaryDark.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              color: c.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== SEGMENT SWITCH ============================== */

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
    final c = _Colors.Constants;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.primaryDark.withOpacity(.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.primaryDark.withOpacity(.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in items)
            GestureDetector(
              onTap: () => onChanged(it.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: it.value == value ? c.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  it.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    color: it.value == value ? Colors.black : c.primaryText,
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

/* ============================== SPARKLINE ============================== */

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, this.color = Colors.black});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SparklinePainter(values, color));
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        3,
        dotPaint,
      );
      return;
    }

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
      ..strokeCap = StrokeCap.round
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
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.radius = 22, this.margin});
  final Widget child;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: w * 0.90,
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
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(.92),
                      Colors.white.withOpacity(.78),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(.70)),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// class EarningsScreen extends StatefulWidget {
//   const EarningsScreen({super.key});

//   @override
//   State<EarningsScreen> createState() => _EarningsScreenState();
// }

// enum _Period { today, week, month }

// class _EarningsScreenState extends State<EarningsScreen> {
//   _Period period = _Period.today;

//   final Map<_Period, List<double>> sparkData = {
//     _Period.today: [20, 0, 40, 30, 50, 60, 0, 0],
//     _Period.week: [120, 40, 80, 140, 60, 220, 160],
//     _Period.month: [
//       420,
//       180,
//       220,
//       560,
//       380,
//       760,
//       620,
//       940,
//       860,
//       1120,
//       980,
//       1280,
//     ],
//   };

//   final Map<_Period, ChartData> chartFallback = {
//     _Period.today: ChartData(
//       labels: ['9a', '11a', '1p', '3p', '5p', '7p', '9p'],
//       values: [15, 20, 40, 35, 55, 28, 7],
//     ),
//     _Period.week: ChartData(
//       labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
//       values: [120, 40, 80, 140, 60, 220, 160],
//     ),
//     _Period.month: ChartData(
//       labels: ['W1', 'W2', 'W3', 'W4'],
//       values: [820, 620, 940, 900],
//     ),
//   };

//   final List<_EarningItem> recent = List.generate(
//     12,
//     (i) => _EarningItem(
//       name: 'John S.',
//       service: 'Cleaning, Pro',
//       time: '11:${20 + i % 9} pm',
//       amount: 20,
//       status: i % 4 == 0
//           ? _Status.pending
//           : (i % 3 == 0 ? _Status.cancelled : _Status.complete),
//     ),
//   );

//   String _apiPeriod(_Period p) {
//     switch (p) {
//       case _Period.today:
//         return 'today';
//       case _Period.week:
//         return 'week';
//       case _Period.month:
//         return 'month';
//     }
//   }

//   ChartData _toChartDataFromCache(
//     Map<String, TaskerEarningsChartResponse> chartCache,
//     _Period p,
//   ) {
//     final resp = chartCache[_apiPeriod(p)];
//     final list = resp?.result?.chartData ?? const <TaskerEarningsChartPoint>[];

//     if (list.isEmpty) {
//       return chartFallback[p] ?? const ChartData(labels: [], values: []);
//     }

//     final labels = <String>[];
//     final values = <double>[];

//     for (final e in list) {
//       labels.add(e.label);
//       values.add(e.amount);
//     }

//     return ChartData(labels: labels, values: values);
//   }

//   double _sum(List<double> v) {
//     double t = 0;
//     for (final x in v) {
//       t += x;
//     }
//     return t;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return BlocBuilder<UserBookingBloc, UserBookingState>(
//       buildWhen: (p, n) =>
//           p.taskerEarningsChartByPeriod != n.taskerEarningsChartByPeriod ||
//           p.taskerEarningsStatsResponse != n.taskerEarningsStatsResponse ||
//           p.taskerEarningsStatsStatus != n.taskerEarningsStatsStatus,
//       builder: (context, state) {
//         final stats = state.taskerEarningsStatsResponse?.result;

//         final apiChart = _toChartDataFromCache(
//           state.taskerEarningsChartByPeriod,
//           period,
//         );

//         final amount = stats?.earnings?.toDouble() ?? _sum(apiChart.values);
//         final tasksCompleted = stats?.tasksCompleted ?? 0;
//         final onlineTime = stats?.onlineTime ?? '0h 0m';
//         final rating = (stats?.rating ?? 0).toDouble();

//         return Scaffold(
//           backgroundColor: c.bg,
//           body: SafeArea(
//             child: CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//                     child: Column(
//                       children: [
//                        // Text(""),
//                         _SummaryCard(
//                           period: period,
//                           amount: amount,
//                           data: sparkData[period] ?? const [],
//                           tasksCompleted: tasksCompleted,
//                           onlineTime: onlineTime,
//                           rating: rating,
//                           onChange: (p) {
//                             setState(() => period = p);
//                           },
//                         ),
//                         const SizedBox(height: 14),
//                         _EarningsGraphCard(
//                           period: period,
//                           data: apiChart,
//                           onChangePeriod: (p) {
//                             setState(() => period = p);
//                           },
//                         ),
//                         const SizedBox(height: 14),
//                         const _PayoutCard(available: 540),
//                         const SizedBox(height: 18),
//                         _SectionTitle(
//                           title: tasksCompleted > 0
//                               ? '$tasksCompleted tasks completed'
//                               : 'Tasks completed',
//                           subtitle: 'Keep going — your stats update live',
//                         ),
//                         const SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
//                   sliver: SliverList(
//                     delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                         final itemIndex = index ~/ 2;
//                         if (index.isOdd) {
//                           return Divider(
//                             height: 18,
//                             thickness: 1,
//                             color: Colors.black.withOpacity(.06),
//                           );
//                         }
//                         return _EarningRow(item: recent[itemIndex]);
//                       },
//                       childCount: recent.isEmpty ? 0 : (recent.length * 2 - 1),
//                     ),
//                   ),
//                 ),
//                 const SliverToBoxAdapter(child: SizedBox(height: 110)),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// /* ============================== THEME TOKENS ============================== */

// class _Colors {
//   static const Constants = _ColorConstants();
// }

// class _ColorConstants {
//   const _ColorConstants();

//   final Color primaryDark = const Color(0xFF5C2E91);
//   final Color primaryText = const Color(0xFF3E1E69);
//   final Color mutedText = const Color(0xFF75748A);
//   final Color bg = const Color(0xFFF8F7FB);
//   final Color gold = const Color(0xFFF4C847);

//   final Color card = Colors.white;
//   final Color border = const Color(0xFFF0ECF6);
// }

// /* ============================== SUMMARY CARD ============================== */

// class _SummaryCard extends StatelessWidget {
//   const _SummaryCard({
//     required this.period,
//     required this.amount,
//     required this.data,
//     required this.onChange,
//     required this.tasksCompleted,
//     required this.onlineTime,
//     required this.rating,
//   });

//   final _Period period;
//   final double amount;
//   final List<double> data;
//   final ValueChanged<_Period> onChange;

//   final int tasksCompleted;
//   final String onlineTime;
//   final double rating;

//   String get _subtitle {
//     switch (period) {
//       case _Period.today:
//         return "Today";
//       case _Period.week:
//         return 'This week';
//       case _Period.month:
//         return 'This month';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return _GlassCard(
//       radius: 26,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//         child: LayoutBuilder(
//           builder: (_, cc) {
//             final narrow = cc.maxWidth < 360;

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       _subtitle,
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         color: c.primaryText,
//                         fontWeight: FontWeight.w900,
//                         fontSize: narrow ? 14 : 16,
//                       ),
//                     ),
//                     const Spacer(),
//                     _SegmentSwitch<_Period>(
//                       value: period,
//                       onChanged: onChange,
//                       items: const [
//                         SegmentItem(label: 'Today', value: _Period.today),
//                         SegmentItem(label: 'Week', value: _Period.week),
//                         SegmentItem(label: 'Month', value: _Period.month),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Expanded(
//                       child: FittedBox(
//                         alignment: Alignment.centerLeft,
//                         fit: BoxFit.scaleDown,
//                         child: Text(
//                           '\$${amount.toStringAsFixed(0)}',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontSize: 40,
//                             fontWeight: FontWeight.w900,
//                             color: c.primaryDark,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     SizedBox(
//                       height: 46,
//                       width: cc.maxWidth * .36,
//                       child: _Sparkline(values: data, color: c.primaryDark),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _KpiChip(
//                       icon: Icons.task_alt_rounded,
//                       label: '$tasksCompleted tasks',
//                     ),
//                     _KpiChip(
//                       icon: Icons.schedule_rounded,
//                       label: 'Online $onlineTime',
//                     ),
//                     _KpiChip(
//                       icon: Icons.star_rounded,
//                       label: '${rating.toStringAsFixed(1)} rating',
//                     ),
//                   ],
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// /* ========================= EARNINGS GRAPH CARD ========================= */

// class ChartData {
//   final List<String> labels;
//   final List<double> values;
//   const ChartData({required this.labels, required this.values});
// }

// class _EarningsGraphCard extends StatelessWidget {
//   const _EarningsGraphCard({
//     required this.period,
//     required this.data,
//     required this.onChangePeriod,
//   });

//   final _Period period;
//   final ChartData data;
//   final ValueChanged<_Period> onChangePeriod;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return _GlassCard(
//       radius: 26,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   'Earnings chart',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: c.primaryText,
//                     fontWeight: FontWeight.w900,
//                     fontSize: 14.0,
//                   ),
//                 ),
//                 const SizedBox(width: 2),
//                 _SegmentSwitch<_Period>(
//                   value: period,
//                   onChanged: onChangePeriod,
//                   items: const [
//                     SegmentItem(label: 'Today', value: _Period.today),
//                     SegmentItem(label: 'Week', value: _Period.week),
//                     SegmentItem(label: 'Month', value: _Period.month),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: _InteractiveLineChart(
//                 values: data.values,
//                 labels: data.labels,
//                 color: c.primaryDark,
//                 showGrid: true,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 _LegendDot(color: c.primaryDark),
//                 const SizedBox(width: 6),
//                 const Text('Income', style: TextStyle(fontFamily: 'Poppins')),
//                 const SizedBox(width: 16),
//                 _LegendDot(color: c.primaryDark.withOpacity(.35)),
//                 const SizedBox(width: 6),
//                 const Text(
//                   'Target (visual only)',
//                   style: TextStyle(fontFamily: 'Poppins'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LegendDot extends StatelessWidget {
//   const _LegendDot({required this.color});
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 10,
//       height: 10,
//       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//     );
//   }
// }

// /* ========================= Interactive Line Chart ========================= */

// class _InteractiveLineChart extends StatefulWidget {
//   const _InteractiveLineChart({
//     required this.values,
//     required this.labels,
//     required this.color,
//     this.showGrid = true,
//   });

//   final List<double> values;
//   final List<String> labels;
//   final Color color;
//   final bool showGrid;

//   @override
//   State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
// }

// class _InteractiveLineChartState extends State<_InteractiveLineChart> {
//   int? _hoverIndex;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (_, c) {
//         return GestureDetector(
//           onPanDown: (d) => _updateHover(c, d.localPosition.dx),
//           onPanUpdate: (d) => _updateHover(c, d.localPosition.dx),
//           onTapDown: (d) => _updateHover(c, d.localPosition.dx),
//           onPanEnd: (_) => setState(() => _hoverIndex = null),
//           onTapUp: (_) => setState(() => _hoverIndex = null),
//           child: CustomPaint(
//             painter: _LineChartPainter(
//               values: widget.values,
//               labels: widget.labels,
//               color: widget.color,
//               showGrid: widget.showGrid,
//               hoverIndex: _hoverIndex,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _updateHover(BoxConstraints c, double dx) {
//     final count = widget.values.length;
//     if (count <= 1) return;
//     final chartW = c.maxWidth;
//     final step = chartW / (count - 1);
//     final i = (dx / step).round().clamp(0, count - 1);
//     setState(() => _hoverIndex = i);
//   }
// }

// class _LineChartPainter extends CustomPainter {
//   _LineChartPainter({
//     required this.values,
//     required this.labels,
//     required this.color,
//     required this.showGrid,
//     required this.hoverIndex,
//   });

//   final List<double> values;
//   final List<String> labels;
//   final Color color;
//   final bool showGrid;
//   final int? hoverIndex;

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (values.isEmpty) return;

//     final chartRect = Rect.fromLTWH(8, 6, size.width - 16, size.height - 22);

//     final minV = values.reduce((a, b) => a < b ? a : b);
//     final maxV = values.reduce((a, b) => a > b ? a : b);
//     final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

//     double xAt(int i) =>
//         chartRect.left + i * (chartRect.width / (values.length - 1));
//     double yAt(double v) =>
//         chartRect.bottom - ((v - minV) / range) * chartRect.height;

//     if (showGrid) {
//       final gridPaint = Paint()
//         ..color = Colors.black12
//         ..style = PaintingStyle.stroke;
//       const lines = 4;
//       for (int g = 0; g <= lines; g++) {
//         final y = chartRect.top + g * (chartRect.height / lines);
//         canvas.drawLine(
//           Offset(chartRect.left, y),
//           Offset(chartRect.right, y),
//           gridPaint,
//         );
//       }
//     }

//     final area = Path()..moveTo(xAt(0), yAt(values[0]));
//     for (int i = 1; i < values.length; i++) {
//       area.lineTo(xAt(i), yAt(values[i]));
//     }
//     area
//       ..lineTo(chartRect.right, chartRect.bottom)
//       ..lineTo(chartRect.left, chartRect.bottom)
//       ..close();

//     final fill = Paint()
//       ..style = PaintingStyle.fill
//       ..shader = LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [color.withOpacity(.26), color.withOpacity(0)],
//       ).createShader(chartRect);
//     canvas.drawPath(area, fill);

//     final path = Path()..moveTo(xAt(0), yAt(values[0]));
//     for (int i = 1; i < values.length; i++) {
//       path.lineTo(xAt(i), yAt(values[i]));
//     }

//     final stroke = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round
//       ..shader = LinearGradient(
//         colors: [color, color.withOpacity(.6)],
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//       ).createShader(chartRect);
//     canvas.drawPath(path, stroke);

//     final tp = TextPainter(textDirection: TextDirection.ltr);
//     for (int i = 0; i < labels.length; i++) {
//       tp.text = TextSpan(
//         text: labels[i],
//         style: const TextStyle(
//           fontFamily: 'Poppins',
//           fontSize: 11,
//           color: Colors.black54,
//         ),
//       );
//       tp.layout();
//       final dx = (i == 0)
//           ? xAt(i)
//           : (i == labels.length - 1)
//           ? xAt(i) - tp.width
//           : xAt(i) - tp.width / 2;
//       tp.paint(canvas, Offset(dx, chartRect.bottom + 2));
//     }

//     if (hoverIndex != null) {
//       final hx = xAt(hoverIndex!);
//       final hy = yAt(values[hoverIndex!]);

//       final vline = Paint()
//         ..color = color.withOpacity(.35)
//         ..strokeWidth = 1.5;
//       canvas.drawLine(
//         Offset(hx, chartRect.top),
//         Offset(hx, chartRect.bottom),
//         vline,
//       );

//       final dotPaint = Paint()..color = color;
//       canvas.drawCircle(Offset(hx, hy), 4, dotPaint);

//       final valueStr = '\$${values[hoverIndex!].toStringAsFixed(0)}';
//       final bubble = TextPainter(
//         text: TextSpan(
//           text: valueStr,
//           style: const TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 12,
//             color: Colors.white,
//             fontWeight: FontWeight.w900,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       )..layout();

//       final bw = bubble.width + 12;
//       final bh = bubble.height + 8;
//       final bx = (hx - bw / 2).clamp(chartRect.left, chartRect.right - bw);
//       final by = (hy - 26 - bh).clamp(chartRect.top, chartRect.bottom - bh);

//       final rrect = RRect.fromRectAndRadius(
//         Rect.fromLTWH(bx, by, bw, bh),
//         const Radius.circular(10),
//       );
//       final bubblePaint = Paint()..color = color.withOpacity(.95);
//       canvas.drawRRect(rrect, bubblePaint);
//       bubble.paint(canvas, Offset(bx + 6, by + 4));
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _LineChartPainter old) {
//     return old.values != values ||
//         old.labels != labels ||
//         old.color != color ||
//         old.hoverIndex != hoverIndex ||
//         old.showGrid != showGrid;
//   }
// }

// /* ============================== PAYOUT CARD ============================== */

// class _PayoutCard extends StatelessWidget {
//   const _PayoutCard({required this.available});
//   final double available;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return Container(
//       padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(22),
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [c.primaryDark, c.primaryDark.withOpacity(.86)],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: c.primaryDark.withOpacity(.26),
//             blurRadius: 22,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Available for payout',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: Colors.white70,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 FittedBox(
//                   fit: BoxFit.scaleDown,
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     '\$${available.toStringAsFixed(0)}',
//                     style: const TextStyle(
//                       fontFamily: 'Poppins',
//                       color: Colors.white,
//                       fontWeight: FontWeight.w900,
//                       fontSize: 28,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           ConstrainedBox(
//             constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
//             child: ElevatedButton(
//               onPressed: () {},
//               style: ElevatedButton.styleFrom(
//                 elevation: 0,
//                 backgroundColor: Colors.white,
//                 foregroundColor: c.primaryDark,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//               child: const FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   'Withdraw',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ============================== SECTION TITLE ============================== */

// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle({required this.title, required this.subtitle});
//   final String title;
//   final String subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return _GlassCard(
//       radius: 28,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: c.primaryText,
//                 fontWeight: FontWeight.w900,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: c.mutedText,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== EARNING ROW ============================== */

// enum _Status { complete, pending, cancelled }

// class _EarningItem {
//   final String name;
//   final String service;
//   final String time;
//   final double amount;
//   final _Status status;

//   _EarningItem({
//     required this.name,
//     required this.service,
//     required this.time,
//     required this.amount,
//     required this.status,
//   });
// }

// class _EarningRow extends StatelessWidget {
//   const _EarningRow({required this.item});
//   final _EarningItem item;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return _GlassCard(
//       radius: 22,
//       child: ListTile(
//         contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
//         leading: Container(
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             color: c.primaryDark.withOpacity(.10),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: c.primaryDark.withOpacity(.12)),
//           ),
//           child: Icon(Icons.receipt_long_rounded, color: c.primaryDark),
//         ),
//         title: Text(
//           item.name,
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             color: c.primaryText,
//             fontWeight: FontWeight.w900,
//             fontSize: 15.5,
//           ),
//         ),
//         subtitle: Padding(
//           padding: const EdgeInsets.only(top: 4),
//           child: Text(
//             '${item.service}\n${item.time}',
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               color: c.mutedText,
//               height: 1.35,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         isThreeLine: true,
//         trailing: ConstrainedBox(
//           constraints: const BoxConstraints(minWidth: 92),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   '\$${item.amount.toStringAsFixed(0)}',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: c.primaryDark,
//                     fontWeight: FontWeight.w900,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               _StatusChip(item.status),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatusChip extends StatelessWidget {
//   const _StatusChip(this.status);
//   final _Status status;

//   @override
//   Widget build(BuildContext context) {
//     late final Color bg;
//     late final Color fg;
//     late final String label;

//     switch (status) {
//       case _Status.complete:
//         bg = const Color(0xFFE6FBE8);
//         fg = const Color(0xFF1B5E20);
//         label = 'Complete';
//         break;
//       case _Status.pending:
//         bg = const Color(0xFFFFF5DC);
//         fg = const Color(0xFF8A6D1F);
//         label = 'Pending';
//         break;
//       case _Status.cancelled:
//         bg = const Color(0xFFFFE7E7);
//         fg = const Color(0xFFB71C1C);
//         label = 'Cancelled';
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontFamily: 'Poppins',
//           color: fg,
//           fontWeight: FontWeight.w900,
//           fontSize: 11.5,
//         ),
//       ),
//     );
//   }
// }

// /* ============================== KPI CHIP ============================== */

// class _KpiChip extends StatelessWidget {
//   const _KpiChip({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: c.primaryDark.withOpacity(.06),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: c.primaryDark.withOpacity(.12)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18, color: c.primaryDark),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               fontWeight: FontWeight.w900,
//               color: c.primaryText,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ============================== SEGMENT SWITCH ============================== */

// class SegmentItem<T> {
//   final String label;
//   final T value;
//   const SegmentItem({required this.label, required this.value});
// }

// class _SegmentSwitch<T> extends StatelessWidget {
//   const _SegmentSwitch({
//     required this.value,
//     required this.onChanged,
//     required this.items,
//   });

//   final T value;
//   final ValueChanged<T> onChanged;
//   final List<SegmentItem<T>> items;

//   @override
//   Widget build(BuildContext context) {
//     final c = _Colors.Constants;

//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: c.primaryDark.withOpacity(.06),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: c.primaryDark.withOpacity(.10)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           for (final it in items)
//             GestureDetector(
//               onTap: () => onChanged(it.value),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: it.value == value ? c.gold : Colors.transparent,
//                   borderRadius: BorderRadius.circular(999),
//                 ),
//                 child: Text(
//                   it.label,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w900,
//                     color: it.value == value ? Colors.black : c.primaryText,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// /* ============================== SPARKLINE ============================== */

// class _Sparkline extends StatelessWidget {
//   const _Sparkline({required this.values, this.color = Colors.black});
//   final List<double> values;
//   final Color color;

//   @override
//   Widget build(BuildContext context) =>
//       CustomPaint(painter: _SparklinePainter(values, color));
// }

// class _SparklinePainter extends CustomPainter {
//   _SparklinePainter(this.values, this.color);
//   final List<double> values;
//   final Color color;

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (values.isEmpty) return;

//     final minV = values.reduce((a, b) => a < b ? a : b);
//     final maxV = values.reduce((a, b) => a > b ? a : b);
//     final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

//     final dx = size.width / (values.length - 1);
//     final path = Path();

//     for (int i = 0; i < values.length; i++) {
//       final x = i * dx;
//       final y = size.height - ((values[i] - minV) / range) * size.height;
//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }

//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round
//       ..shader = LinearGradient(
//         colors: [color.withOpacity(.9), color.withOpacity(.5)],
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//       ).createShader(Offset.zero & size);

//     final fillPath = Path.from(path)
//       ..lineTo(size.width, size.height)
//       ..lineTo(0, size.height)
//       ..close();

//     final fillPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..shader = LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [color.withOpacity(.18), color.withOpacity(.0)],
//       ).createShader(Offset.zero & size);

//     canvas.drawPath(fillPath, fillPaint);
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _SparklinePainter old) =>
//       old.values != values || old.color != color;
// }

// class _GlassCard extends StatelessWidget {
//   const _GlassCard({required this.child, this.radius = 22, this.margin});
//   final Widget child;
//   final double radius;
//   final EdgeInsets? margin;

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;

//     return Align(
//       alignment: Alignment.center,
//       child: Container(
//         width: w * 0.90,
//         margin: margin,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(radius),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.06),
//               blurRadius: 22,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(radius),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//             child: Material(
//               color: Colors.transparent,
//               child: Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(radius),
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       Colors.white.withOpacity(.92),
//                       Colors.white.withOpacity(.78),
//                     ],
//                   ),
//                   border: Border.all(color: Colors.white.withOpacity(.70)),
//                 ),
//                 child: child,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
