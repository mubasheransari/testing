import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'dart:convert';
import 'package:taskoon/Realtime/dispatch_hub_service.dart';



enum PopupCloseReason { autoTimeout, declined, accepted }

class TaskerBookingOffer {
  final String bookingDetailId;
  final double lat;
  final double lng;
  final double estimatedCost;
  final String message;
  final String? type;
  final String? date;

  TaskerBookingOffer({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,
    required this.message,
    this.type,
    this.date,
  });

  static TaskerBookingOffer? tryParse(dynamic payload) {
    try {
      dynamic obj = payload;

      // SignalR sometimes sends [ {..} ] wrapper
      if (obj is List && obj.isNotEmpty) obj = obj.first;

      // Server might send JSON string
      if (obj is String) obj = jsonDecode(obj);

      if (obj is! Map) {
        debugPrint("❌ tryParse: payload is not Map => ${obj.runtimeType}");
        return null;
      }

      final map = Map<String, dynamic>.from(obj);

      // data can be Map or JSON string
      dynamic dataAny = map['data'];
      if (dataAny is String) {
        try {
          dataAny = jsonDecode(dataAny);
        } catch (_) {}
      }

      Map<String, dynamic>? data;
      if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

      // bookingDetailId can live in data or root
      final bookingDetailId = (data?['bookingDetailId'] ??
              data?['BookingDetailId'] ??
              map['bookingDetailId'] ??
              map['BookingDetailId'])
          ?.toString();

      if (bookingDetailId == null || bookingDetailId.isEmpty) {
        debugPrint("❌ tryParse: bookingDetailId missing. keys=${map.keys}");
        return null;
      }

      final lat = _toDouble(
          data?['lat'] ?? data?['Lat'] ?? map['lat'] ?? map['Lat'] ?? 0);
      final lng = _toDouble(
          data?['lng'] ?? data?['Lng'] ?? map['lng'] ?? map['Lng'] ?? 0);

      final estimatedCost = _toDouble(data?['estimatedCost'] ??
          data?['EstimatedCost'] ??
          map['estimatedCost'] ??
          map['EstimatedCost'] ??
          0);

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: lat,
        lng: lng,
        estimatedCost: estimatedCost,
        message: (map['message'] ?? '').toString(),
        type: map['type']?.toString(),
        date: map['date']?.toString(),
      );
    } catch (e) {
      debugPrint("❌ tryParse exception => $e");
      return null;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> {
  // theme tokens
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBg = Color(0xFFF8F7FB);

  // ✅ IMPORTANT: use same baseUrl you use everywhere
  static const String _baseUrl = "http://192.3.3.187:85";

  bool available = false;
  String period = 'Week';
  final box = GetStorage();
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

  // ✅ hub subscription
  StreamSubscription? _hubSub;
  bool _hubConfigured = false;

  // ✅ periodic location updates
  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5);

  // popup guards
  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

  // mock data
  final _avatarUrl =
      'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop';
  final _title = 'Handyman, Pro';

  final _badges = const [
    _Badge(
      label: 'ID',
      icon: Icons.verified,
      bg: Color(0xFFE8F5E9),
      fg: Color(0xFF2E7D32),
    ),
    _Badge(
      label: 'Police\nCheck',
      icon: Icons.shield_moon,
      bg: Color(0xFFE3F2FD),
      fg: Color(0xFF1565C0),
    ),
  ];

  double rating = 4.9;
  int reviews = 124;
  int acceptanceRate = 91;
  int completionRate = 98;
  int weeklyEarning = 820;
  int monthlyEarning = 3280;

  final List<_Task> upcoming = const [
    _Task(
      title: 'Furniture assembly',
      date: 'Apr 24',
      time: '10:30',
      location: 'East Perth',
    ),
  ];

  final List<_Task> current = const [
    _Task(
      title: 'TV wall mount',
      date: 'Apr 24',
      time: '09:00',
      location: 'Perth CBD',
    ),
  ];

  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      debugPrint("🟣 TaskerHome init: restored available=$saved");

      // ✅ configure + connect hub (always), then attach listener
      await _setupSignalR();

      // ✅ if tasker restored as online -> start timer too
      if (saved) {
        _startLocationUpdates();
      }
    });
  }

  /// ✅ FULL SignalR setup inside this screen
  Future<void> _setupSignalR() async {
    final authState = context.read<AuthenticationBloc>().state;
    final userDetails = authState.userDetails;
    final userId = userDetails?.userId?.toString();

    if (userId == null || userId.isEmpty) {
      debugPrint("❌ TASKER HUB: userId missing (userDetails not loaded)");
      return;
    }

    // ✅ configure singleton once (VERY IMPORTANT)
    if (!_hubConfigured) {
      debugPrint("🧩 TASKER HUB: configuring baseUrl=$_baseUrl userId=$userId");
      DispatchHubSingleton.instance.configure(
        baseUrl: _baseUrl,
        userId: userId,
      );
      _hubConfigured = true;
    }

    // ✅ connect
    await _ensureHubConnectedWithLogs();

    // ✅ attach listener AFTER connect
    _attachHubListener();
  }

  Future<void> _ensureHubConnectedWithLogs() async {
    try {
      debugPrint("🔌 TASKER HUB: ensureConnected()...");
      await DispatchHubSingleton.instance.ensureConnected();
      debugPrint("✅ TASKER HUB: connected (or already connected)");
    } catch (e) {
      debugPrint("❌ TASKER HUB: ensureConnected failed => $e");
    }
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 TASKER HUB: attaching notifications listener...");

    _hubSub = DispatchHubSingleton.instance.notifications.listen(
      (payload) {
        if (!mounted) return;

        debugPrint("📩 TASKER HUB payload type=${payload.runtimeType}");
        debugPrint("📩 TASKER HUB payload => $payload");

        // ✅ show popup only when tasker is ONLINE (you can remove this if you want popup always)
        if (!available) {
          debugPrint("⚠️ TASKER HUB: offer received but available=false (no popup)");
          return;
        }

        final offer = TaskerBookingOffer.tryParse(payload);
        if (offer == null) {
          debugPrint("❌ TASKER HUB: offer parse FAILED (popup not shown)");
          return;
        }

        debugPrint("✅ TASKER HUB: offer parsed bookingDetailId=${offer.bookingDetailId}");
        _showBookingPopup(offer);
      },
      onError: (e) => debugPrint("❌ TASKER HUB stream error => $e"),
      onDone: () => debugPrint("⚠️ TASKER HUB stream closed"),
    );
  }

  Future<void> _onAvailabilityToggle(bool value) async {
    debugPrint("🟡 Availability toggle => $value");
    await box.write(_kAvailabilityKey, value);

    if (!value) {
      setState(() => available = false);
      debugPrint("🔴 TASKER OFFLINE: stop location updates");
      _stopLocationUpdates();
      return;
    }

    setState(() => available = true);

    // ✅ ensure hub connected (in case it dropped)
    await _ensureHubConnectedWithLogs();

    debugPrint("🟢 TASKER ONLINE: start location updates (every 5s)");
    _startLocationUpdates();
  }

  void _dispatchLocationUpdateToApi() {
    if (!mounted) return;

    if (!available) {
      debugPrint("⚠️ LOCATION: skipped (available=false)");
      return;
    }

    final authState = context.read<AuthenticationBloc>().state;
    final userDetails = authState.userDetails;

    if (userDetails == null || userDetails.userId == null) {
      debugPrint("❌ LOCATION: userDetails missing (cannot send)");
      return;
    }

    final userId = userDetails.userId.toString();

    // ✅ replace with real GPS later
    const double lat = 67.00;
    const double lng = 70.00;

    debugPrint("📍 LOCATION: sending => userId=$userId lat=$lat lng=$lng");

    // ✅ 1) Update location
    context.read<UserBookingBloc>().add(
          UpdateUserLocationRequested(
            userId: userId,
            latitude: lat,
            longitude: lng,
          ),
        );
    debugPrint("✅ EVENT: UpdateUserLocationRequested dispatched");

    // ✅ 2) Availability status event
    context.read<UserBookingBloc>().add(
          ChangeAvailabilityStatus(userId: userId),
        );
    debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched");
  }

  void _startLocationUpdates() {
    if (!_restored) return;

    debugPrint("⏱️ LOCATION TIMER: start interval=${_locationInterval.inSeconds}s");

    _dispatchLocationUpdateToApi();
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_locationInterval, (_) {
      debugPrint("⏱️ LOCATION TIMER TICK");
      _dispatchLocationUpdateToApi();
    });
  }

  void _stopLocationUpdates() {
    debugPrint("🛑 LOCATION TIMER: stop");
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    if (_dialogOpen) {
      debugPrint("⚠️ POPUP: already open, skipping booking=${offer.bookingDetailId}");
      return;
    }

    if (_lastPopupBookingDetailId == offer.bookingDetailId) {
      debugPrint("⚠️ POPUP: same booking received again, skipping booking=${offer.bookingDetailId}");
      return;
    }

    debugPrint("🟢 POPUP: preparing booking=${offer.bookingDetailId}");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_dialogOpen) return;

      _dialogOpen = true;
      _lastPopupBookingDetailId = offer.bookingDetailId;

      debugPrint("🟢 POPUP: OPEN booking=${offer.bookingDetailId}");

      try {
        await showDialog(
          context: context,
          useRootNavigator: true, // ✅ important
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.55),
          builder: (ctx) {
            const kGold = Color(0xFFF4C847);
            const int totalSeconds = 60;

            int secondsLeft = totalSeconds;
            Timer? timer;
            bool closed = false;

            String mmss(int s) =>
                '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

            void closeDialog() {
              if (closed) return;
              closed = true;

              timer?.cancel();
              timer = null;

              if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                Navigator.of(ctx, rootNavigator: true).pop();
              }
            }

            Widget infoTile({
              required IconData icon,
              required String label,
              required String value,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: kPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              color: kMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              color: kTextDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return StatefulBuilder(
              builder: (context, setState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                  if (closed) return;

                  if (secondsLeft <= 1) {
                    debugPrint("⏳ POPUP: auto-timeout booking=${offer.bookingDetailId}");
                    closeDialog();
                    return;
                  }

                  setState(() => secondsLeft--);
                });

                final progress = (secondsLeft / totalSeconds).clamp(0.0, 1.0);

                return WillPopScope(
                  onWillPop: () async => false,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.of(ctx).size.width * 0.88,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: kGold.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: kPrimary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "New Booking Offer",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: kTextDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.close_rounded, color: Colors.transparent),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: kPrimary.withOpacity(0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  secondsLeft <= 10
                                      ? Colors.redAccent
                                      : (secondsLeft <= 25 ? kGold : kPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kPrimary.withOpacity(0.12)),
                              ),
                              child: Text(
                                offer.message,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: kTextDark,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: infoTile(
                                    icon: Icons.attach_money_rounded,
                                    label: "Estimated",
                                    value: "\$${offer.estimatedCost.toStringAsFixed(0)}",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: infoTile(
                                    icon: Icons.timer_outlined,
                                    label: "Time Left",
                                    value: mmss(secondsLeft),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: infoTile(
                                    icon: Icons.my_location_outlined,
                                    label: "Latitude",
                                    value: offer.lat.toStringAsFixed(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: infoTile(
                                    icon: Icons.my_location_outlined,
                                    label: "Longitude",
                                    value: offer.lng.toStringAsFixed(4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      debugPrint("🟠 POPUP: Decline pressed booking=${offer.bookingDetailId}");
                                      closeDialog();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kPrimary,
                                      side: BorderSide(color: kPrimary.withOpacity(0.35)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      "Decline",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final authState = context.read<AuthenticationBloc>().state;
                                      final uid = authState.userDetails?.userId?.toString() ?? "";

                                      debugPrint("🟢 POPUP: Accept pressed booking=${offer.bookingDetailId} userId=$uid");

                                      context.read<UserBookingBloc>().add(
                                            AcceptBooking(
                                              userId: uid,
                                              bookingDetailId: offer.bookingDetailId,
                                            ),
                                          );

                                      debugPrint("✅ EVENT: AcceptBooking dispatched");
                                      closeDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Accept",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

        debugPrint("🟠 POPUP: closed (showDialog returned)");
      } catch (e) {
        debugPrint("❌ POPUP: showDialog exception => $e");
      } finally {
        debugPrint("🔁 POPUP: reset guards");
        _dialogOpen = false;
        _lastPopupBookingDetailId = null;
      }
    });
  }

  @override
  void dispose() {
    debugPrint("🧹 TaskerHome dispose()");
    _stopLocationUpdates();
    _hubSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final name = authState.userDetails?.fullName?.toString() ?? 'Tasker';

    final earnings = period == 'Week' ? weeklyEarning : monthlyEarning;

    final filteredTasks = _selectedChip == 'Upcoming'
        ? upcoming
        : _selectedChip == 'Current'
            ? current
            : [...current, ...upcoming];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ready for new gigs?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: kMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                const Text(
                  'Available',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: available,
                  onChanged: _onAvailabilityToggle,
                  activeColor: kPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              _InfoCard(
                icon: available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                text: available
                    ? 'You are online. New offers can arrive anytime.'
                    : 'You are offline. Turn on availability to receive offers.',
              ),
              const SizedBox(height: 14),
              _WhiteCard(
                child: _EarningsCard(
                  period: period,
                  amount: earnings,
                  onChange: (p) => setState(() => period = p),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: _WhiteCard(
                  child: _KpiRow(
                    rating: rating,
                    reviews: reviews,
                    acceptance: acceptanceRate,
                    completion: completionRate,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your jobs',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: kTextDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ChipsRow(
                labels: _chipLabels,
                selected: _selectedChip,
                onTap: (v) => setState(() => _selectedChip = v),
              ),
              const SizedBox(height: 14),
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChip == 'All' ? 'Recent activity' : '$_selectedChip tasks',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        color: kTextDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredTasks.isEmpty)
                      const _EmptyState(
                        text: 'No tasks yet. Turn on availability to get offers.',
                      )
                    else
                      Column(
                        children: [
                          for (int i = 0; i < filteredTasks.length; i++) ...[
                            _TaskTile(task: filteredTasks[i]),
                            if (i != filteredTasks.length - 1)
                              Divider(height: 18, color: Colors.grey.withOpacity(0.18)),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _WhiteCard(
                child: Row(
                  children: [
                    CircleAvatar(radius: 24, backgroundImage: NetworkImage(_avatarUrl)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _badges
                                .map(
                                  (b) => Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: b.bg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(b.icon, size: 16, color: b.fg),
                                        const SizedBox(width: 6),
                                        Text(
                                          b.label,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11.5,
                                            color: b.fg,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
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

/// ===============================================================
/// UI WIDGETS
/// ===============================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: kPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kPrimary),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF5C2E91).withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onTap;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = labels[i];
          final sel = label == selected;
          return GestureDetector(
            onTap: () => onTap(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: sel ? null : Border.all(color: kPrimary.withOpacity(.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: sel ? Colors.white : kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.period,
    required this.amount,
    required this.onChange,
  });

  final String period;
  final int amount;
  final ValueChanged<String> onChange;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "\$${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            color: Color(0xFF3E1E69),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'per ${period.toLowerCase()}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kPrimary.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                label: 'Week',
                selected: period == 'Week',
                onTap: () => onChange('Week'),
              ),
              _Pill(
                label: 'Month',
                selected: period == 'Month',
                onTap: () => onChange('Month'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.rating,
    required this.reviews,
    required this.acceptance,
    required this.completion,
  });

  final double rating;
  final int reviews;
  final int acceptance;
  final int completion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _KpiTile(
          icon: Icons.star_rate_rounded,
          title: rating.toStringAsFixed(1),
          sub: '$reviews reviews',
        ),
        _KpiTile(
          icon: Icons.bolt_rounded,
          title: '$acceptance%',
          sub: 'acceptance',
        ),
        _KpiTile(
          icon: Icons.check_circle_rounded,
          title: '$completion%',
          sub: 'completion',
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final String title;
  final String sub;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.90),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 20),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF3E1E69),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Color(0xFF75748A),
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final _Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Color(0xFF3E1E69),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Text(task.date,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A))),
            const SizedBox(width: 14),
            const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Text(task.time,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A))),
            const SizedBox(width: 14),
            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A))),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF75748A)),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

class _Task {
  final String title;
  final String date;
  final String time;
  final String location;

  const _Task({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
  });
}
