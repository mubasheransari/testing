import 'package:flutter/material.dart';

/// TASKOON — Tasker Home (Redesigned)
/// ------------------------------------------------------------
/// • Modern gradient header with curved bottom.
/// • Floating profile + earnings cards (glass-like).
/// • KPI chips row (rating, acceptance, completion).
/// • Upcoming & Current task cards with clean CTAs.
/// • Availability switch baked into header.
///
/// Hook points (replace stubs with real data / BLoC):
///   - onAvailabilityChanged
///   - onDirectionTap
///   - onViewMoreUpcoming / onViewMoreCurrent
///   - replace `_mock...` values with your state
/// ------------------------------------------------------------

class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> {
  bool available = true;
  String period = 'Week'; // Week | Month

  // MOCK DATA — plug your real values here
  final _name = 'Alex';
  final _avatarUrl =
      'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop';
  final _title = 'Handyman, Pro';
  final _badges = const [
    _Badge(label: 'ID', icon: Icons.verified, bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32)),
    _Badge(label: 'Police\nCheck', icon: Icons.shield_moon, bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0)),
  ];

  double rating = 4.9;
  int reviews = 124;
  int acceptanceRate = 91;
  int completionRate = 98;
  int weeklyEarning = 820;
  int monthlyEarning = 3280;

  final List<_Task> upcoming = const [
    _Task(title: 'Furniture assembly', date: 'Apr 24', time: '10:30', location: 'East Perth'),
  ];
  final List<_Task> current = const [
    _Task(title: 'TV wall mount', date: 'Apr 24', time: '09:00', location: 'Perth CBD'),
  ];

  // THEME TOKENS (align with Taskoon palette: purple/gold/white)
  static const Color kPrimary = Color(0xFF5C2E91); // deep purple
  static const Color kPrimaryDark = Color(0xFF411C6E);
  static const Color kAccentGold = Color(0xFFF4C847);
  static const double kRadius = 20;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final expanded = (screenH * 0.28).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F7FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: expanded,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                name: _name,
                available: available,
                onToggle: (v) => setState(() => available = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _GlassCard(
                            child: _ProfileCard(
                              avatarUrl: _avatarUrl,
                              name: 'Mark',
                              title: _title,
                              badges: _badges,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlassCard(
                            child: _EarningCard(
                              amount: period == 'Week' ? weeklyEarning : monthlyEarning,
                              sub: 'Earnings per ${period.toLowerCase()}',
                              period: period,
                              onChangePeriod: (p) => setState(() => period = p),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: _KpiRow(
                        rating: rating,
                        reviews: reviews,
                        acceptance: acceptanceRate,
                        completion: completionRate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Upcoming Tasks',
                      onViewMore: _onViewMoreUpcoming,
                      child: Column(
                        children: [
                          for (final t in upcoming) _TaskTile(task: t),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Current Tasks',
                      onViewMore: _onViewMoreCurrent,
                      child: Column(
                        children: [
                          for (final t in current) _TaskTile(
                            task: t,
                            trailing: _PrimaryButton(
                              label: 'DIRECTION',
                              icon: Icons.arrow_forward_rounded,
                              onTap: _onDirectionTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
   
    );
  }

  void _onViewMoreUpcoming() {}
  void _onViewMoreCurrent() {}
  void _onDirectionTap() {}
}

/* ===================== UI PARTS ===================== */
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.available,
    required this.onToggle,
  });

  final String name;
  final bool available;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient + curve
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _TaskerHomeRedesignState.kPrimaryDark,
                  _TaskerHomeRedesignState.kPrimary,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello $name,',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Gigs are rolling in, let's go!!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: available,
                            onChanged: onToggle,
                            activeColor: _TaskerHomeRedesignState.kAccentGold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final compact = w < 360;
        final wide = w > 720;

        final radius = compact ? 16.0 : (wide ? 24.0 : _TaskerHomeRedesignState.kRadius);
        final padAll = compact ? 12.0 : (wide ? 18.0 : 14.0);
        final marginV = compact ? 4.0 : 6.0;
        final blur = wide ? 22.0 : 18.0;
        final offsetY = wide ? 10.0 : 8.0;

        return Container(
          margin: EdgeInsets.symmetric(vertical: marginV),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1B20) : Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: blur,
                offset: Offset(0, offsetY),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF2A2C33) : const Color(0xFFF0ECF6),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padAll),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.avatarUrl,
    required this.name,
    required this.title,
    required this.badges,
  });

  final String avatarUrl;
  final String name;
  final String title;
  final List<_Badge> badges;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final narrow = w < 340;
        final wide = w > 600;

        final avatarR = narrow ? 24.0 : (wide ? 32.0 : 28.0);
        final gap = narrow ? 10.0 : 12.0;
        final nameStyle = TextStyle(
          fontSize: narrow ? 15 : (wide ? 18 : 16),
          fontWeight: FontWeight.w700,
        );
        final titleStyle = TextStyle(
          color: Colors.grey.shade600,
          fontSize: narrow ? 11 : (wide ? 13 : 12),
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final b in badges) _BadgeChip(badge: b)],
            ),
          ],
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: avatarR, backgroundImage: NetworkImage(avatarUrl)),
            SizedBox(width: gap),
            Expanded(child: info),
          ],
        );
      },
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({
    required this.amount,
    required this.sub,
    required this.period,
    required this.onChangePeriod,
  });

  final int amount;
  final String sub;
  final String period;
  final ValueChanged<String> onChangePeriod;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 340;
        final isMedium = w < 420;

        final titleStyle = TextStyle(
          fontSize: isMedium ? 11 : 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        );

        final switcher = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F1F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegmentPill(
                label: 'Week',
                selected: period == 'Week',
                onTap: () => onChangePeriod('Week'),
              ),
              _SegmentPill(
                label: 'Month',
                selected: period == 'Month',
                onTap: () => onChangePeriod('Month'),
              ),
            ],
          ),
        );

        final header = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earnings', style: titleStyle),
                  const SizedBox(height: 8),
                  switcher,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Earnings', style: titleStyle),
                  switcher,
                ],
              );

        final amountText = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: isMedium ? 24 : 26, fontWeight: FontWeight.w800),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Expanded(child: amountText)],
            ),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: isMedium ? 11 : 12)),
          ],
        );
      },
    );
  }
}


class _SegmentPill extends StatelessWidget {
  const _SegmentPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _TaskerHomeRedesignState.kAccentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.rating, required this.reviews, required this.acceptance, required this.completion});
  final double rating;
  final int reviews;
  final int acceptance;
  final int completion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final isNarrow = maxW < 360;
        final itemW = isNarrow ? (maxW) : ((maxW - 16) / 3);
        final tiles = [
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.star_rate_rounded,
              color: const Color(0xFFFFE082),
              title: rating.toStringAsFixed(1),
              sub: '$reviews reviews',
            ),
          ),
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.bolt,
              color: const Color(0xFFC5E1A5),
              title: '$acceptance%',
              sub: 'acceptance',
            ),
          ),
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFB3E5FC),
              title: '$completion%',
              sub: 'completion',
            ),
          ),
        ];
        return Wrap(spacing: 8, runSpacing: 8, children: tiles);
      },
    );
  }
}

class _KpiTile extends StatelessWidget  {
  const _KpiTile({required this.icon, required this.color, required this.title, required this.sub});
  final IconData icon; final Color color; final String title; final String sub;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202127)
            : const Color(0xFFF8F7FB),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.onViewMore});
  final String title; final Widget child; final VoidCallback? onViewMore;
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (onViewMore != null)
                TextButton(
                  onPressed: onViewMore,
                  child: const Text('View more'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, this.trailing});
  final _Task task; final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 380; // small phones
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(task.date, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(task.time, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(task.location, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
              ],
            )
          ],
        );

        Widget row;
        if (!isNarrow) {
          row = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              if (trailing != null) const SizedBox(width: 12),
              if (trailing != null)
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 160, height: 44),
                      child: trailing!,
                    ),
                  ),
                ),
            ],
          );
        } else {
          row = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (trailing != null) const SizedBox(height: 10),
              if (trailing != null)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: trailing!,
                ),
            ],
          );
        }

        return Column(
          children: [
            row,
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.icon, this.onTap});
  final String label; final IconData? icon; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // FIX: give the button a finite width inside Row to avoid BoxConstraints(w=Infinity)
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 160, height: 44),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _TaskerHomeRedesignState.kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (icon != null) const SizedBox(width: 8),
            if (icon != null) Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}


class _Badge {
  final String label; final IconData icon; final Color bg; final Color fg;
  const _Badge({required this.label, required this.icon, required this.bg, required this.fg});
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final _Badge badge;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.fg),
          const SizedBox(width: 3),
          Text(badge.label, style: TextStyle(fontSize: 11, color: badge.fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Task {
  final String title; final String date; final String time; final String location;
  const _Task({required this.title, required this.date, required this.time, required this.location});
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width * 0.25, size.height - 30,
      size.width * 0.5, size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 50,
      size.width, size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
