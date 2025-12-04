import 'package:flutter/material.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});
  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const kPurple = Color(0xFF5C2E91);
  static const kPurpleText = Color(0xFF3E1E69);
  static const kMuted = Color(0xFF75748A);
  static const kCardBorder = Color(0xFFE9ECF2);
  static const kShadow = Color(0x14000000);
  static const kGreen = Color(0xFF2F7D32);
  static const kAmber = Color(0xFFE2B43C);
  static const kRed = Color(0xFFD84343);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Segmented tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _SegmentTabs(controller: _tabs),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _BookingsList(
                    items: _demoHistory,
                    builder: (b) => _HistoryCard(booking: b),
                  ),
                  _BookingsList(
                    items: _demoOngoing,
                    builder: (b) => _OngoingCard(booking: b),
                  ),
                  const _ScheduledEmpty(), // empty like your UI
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      leadingWidth: 52,

      title: const Text(
        'My Bookings',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          color: kPurple,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        _supportButton(
          onTap: () {
            // TODO: open support
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  static Widget _supportButton({VoidCallback? onTap}) {
    return Material(
      color: kPurple,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            'Support',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== DATA MODELS & DEMO DATA ===================== */

enum BookingStatus { processed, disputed, cancelled, ongoing }

class Booking {
  final String name;
  final String code; // AU737
  final String subtitle; // Cleaner, pro
  final String date; // June 6, 2025
  final String time; // 10:00
  final BookingStatus status;
  final String amount; // $ 40.00
  final bool showWarning; // amber icon
  final String? remaining; // for ongoing
  final bool showChat; // for ongoing

  const Booking({
    required this.name,
    required this.code,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.status,
    required this.amount,
    this.showWarning = false,
    this.remaining,
    this.showChat = false,
  });
}

const _demoHistory = <Booking>[
  Booking(
    name: 'Stephan Micheal',
    code: 'AU737',
    subtitle: 'Cleaner, pro',
    date: 'June 6, 2025',
    time: '10:00',
    status: BookingStatus.processed,
    amount: '\$ 40.00',
    showWarning: true,
  ),
  Booking(
    name: 'Stephan Micheal',
    code: 'AU737',
    subtitle: 'Cleaner, pro',
    date: 'June 6, 2025',
    time: '10:00',
    status: BookingStatus.disputed,
    amount: '\$ 40.00',
    showWarning: true,
  ),
  Booking(
    name: 'Stephan Micheal',
    code: 'AU737',
    subtitle: 'Cleaner, pro',
    date: 'June 6, 2025',
    time: '10:00',
    status: BookingStatus.cancelled,
    amount: '\$ 40.00',
    showWarning: true,
  ),
];

const _demoOngoing = <Booking>[
  Booking(
    name: 'Stephan Micheal',
    code: 'AU737',
    subtitle: 'Cleaner, pro',
    date: '—',
    time: '—',
    status: BookingStatus.ongoing,
    amount: '\$ 40.00',
    showWarning: true,
    remaining: '45:07',
    showChat: true,
  ),
  Booking(
    name: 'Stephan Micheal',
    code: 'AU737',
    subtitle: 'Cleaner, pro',
    date: '—',
    time: '—',
    status: BookingStatus.ongoing,
    amount: '\$ 40.00',
    showWarning: true,
    remaining: '45:07',
    showChat: true,
  ),
];

/* ===================== TABS (theme-aligned) ===================== */

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.controller});
  final TabController controller;

  static const kPurple = _MyBookingsState.kPurple;
  static const kMuted = _MyBookingsState.kMuted;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: kPurple,
      unselectedLabelColor: kMuted,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),

      tabs: const [
        Tab(text: 'History'),
        Tab(text: 'Ongoing'),
        Tab(text: 'Scheduled'),
      ],
    );
  }
}

/* ===================== LIST WRAPPER ===================== */

class _BookingsList extends StatelessWidget {
  const _BookingsList({required this.items, required this.builder});
  final List<Booking> items;
  final Widget Function(Booking) builder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _ScheduledEmpty();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (_, i) => builder(items[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

/* ===================== CARDS (theme-aligned) ===================== */

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.booking});
  final Booking booking;

  static const kPurple = _MyBookingsState.kPurple;
  static const kPurpleText = _MyBookingsState.kPurpleText;
  static const kMuted = _MyBookingsState.kMuted;
  static const kCardBorder = _MyBookingsState.kCardBorder;
  static const kShadow = _MyBookingsState.kShadow;
  static const kGreen = _MyBookingsState.kGreen;
  static const kAmber = _MyBookingsState.kAmber;
  static const kRed = _MyBookingsState.kRed;

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.processed:
        return kGreen;
      case BookingStatus.disputed:
        return kAmber;
      case BookingStatus.cancelled:
        return kRed;
      default:
        return kMuted;
    }
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.processed:
        return 'Processed';
      case BookingStatus.disputed:
        return 'Disputed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kPurpleText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                    ),
                  ),
                ),
                Text(
                  booking.code,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: kPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                if (booking.showWarning) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.warning_amber_rounded, color: kAmber, size: 20),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: kMuted,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.date,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kMuted,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Text(
                  booking.time,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: kMuted,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusLabel(booking.status),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _statusColor(booking.status),
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                Text(
                  booking.amount,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: kPurpleText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
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

class _OngoingCard extends StatelessWidget {
  const _OngoingCard({required this.booking});
  final Booking booking;

  static const kPurple = _MyBookingsState.kPurple;
  static const kPurpleText = _MyBookingsState.kPurpleText;
  static const kMuted = _MyBookingsState.kMuted;
  static const kCardBorder = _MyBookingsState.kCardBorder;
  static const kShadow = _MyBookingsState.kShadow;
  static const kRed = _MyBookingsState.kRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kPurpleText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                    ),
                  ),
                ),
                Text(
                  booking.code,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: kPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.cancel_rounded, color: kRed, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: kMuted,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (booking.showChat)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: const [
                    Icon(Icons.chat_bubble_outline_rounded, color: kMuted, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: kMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Remaining time',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: kPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                Text(
                  booking.remaining ?? '--:--',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: kPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
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

/* ===================== SCHEDULED EMPTY ===================== */

class _ScheduledEmpty extends StatelessWidget {
  const _ScheduledEmpty();

  @override
  Widget build(BuildContext context) {
    // Intentionally empty like your screenshot
    return const SizedBox.shrink();
  }
}
