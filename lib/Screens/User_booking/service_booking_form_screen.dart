import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_places_flutter/model/place_type.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Screens/User_booking/finding_tasker_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_place/google_place.dart';




class BookingTypeIds {
  static const int asap = 1;
  static const int future = 2;
  static const int recurrence = 3;
  static const int multiDays = 4;
}

class RecurrencePatternIds {
  static const int daily = 1;
  static const int monthly = 2;
  static const int weekly = 3;
  static const int customDays = 4;
}

/* ============================== SCREEN ============================== */

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  final ServiceOption? initialService;

  /// API expects SubCategoryId
  final int serviceId;

  const ServiceBookingFormScreen({
    super.key,
    required this.group,
    this.initialService,
    required this.serviceId,
  });

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  // ✅ Put your key here
  static const String _googlePlacesKey =
      "AIzaSyBFIEDQXjgT6djAIrXB466aR1oG5EmXojQ";

  // ✅ booking minimum duration
  static const int _minBookingMinutes = 30;

  // selections
  ServiceOption? _selectedSubcategory;
  int? _selectedTaskerLevelId;

  // booking mode
  int _bookingTypeId = BookingTypeIds.asap;

  // recurrence
  int _recurrencePatternId = RecurrencePatternIds.daily;
  final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

  // dates/times
  DateTime? _selectedDate; // start date
  DateTime? _endDate; // recurrence/multi-days
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // form
  final _manualLocationCtrl = TextEditingController();
  bool _showErrors = false;

  // navigation guard
  bool _navigated = false;

  /* ===================== PLACES (CUSTOM UI) ===================== */

  late final GooglePlace _googlePlace;
  Timer? _placesDebounce;

  final FocusNode _locFocus = FocusNode();
  final LayerLink _locLink = LayerLink();

  OverlayEntry? _locOverlay;
  List<AutocompletePrediction> _locPredictions = [];
  bool _locLoading = false;

  double? _pickedLat;
  double? _pickedLng;
  String? _pickedPlaceId;
  String _lastCommittedAddress = "";

  @override
  void initState() {
    super.initState();

    _selectedSubcategory = widget.initialService;
    _selectedSubcategory ??= widget.group.services.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.group.services.isNotEmpty
          ? widget.group.services.first
          : ServiceOption(id: widget.serviceId, name: ''),
    );

    _selectedDate = DateTime.now();

    _googlePlace = GooglePlace(_googlePlacesKey);

    _locFocus.addListener(() {
      if (!_locFocus.hasFocus) {
        _removeLocOverlay();
      } else {
        if (_locPredictions.isNotEmpty) _showLocOverlay();
      }
    });
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    _removeLocOverlay();
    _locFocus.dispose();
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  /* ============================== DATE/TIME ============================== */

  // ✅ Time helpers
  int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;

  TimeOfDay _fromMinutes(int totalMinutes) {
    totalMinutes = totalMinutes % (24 * 60);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  TimeOfDay _addMinutes(TimeOfDay t, int minutes) =>
      _fromMinutes(_toMinutes(t) + minutes);

  // ✅ FIXED: supports cross-midnight
  bool _isEndValid(TimeOfDay start, TimeOfDay end) {
    final s = _toMinutes(start);
    var e = _toMinutes(end);

    // ✅ if end is earlier than start => next day
    if (e < s) e += 24 * 60;

    return (e - s) >= _minBookingMinutes;
  }

  void _ensureMinEndTime() {
    if (_startTime == null) return;
    final minEnd = _addMinutes(_startTime!, _minBookingMinutes);

    // if end is null OR invalid, force it to minimum end
    if (_endTime == null || !_isEndValid(_startTime!, _endTime!)) {
      _endTime = minEnd;
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: initial.isBefore(now) ? now : initial,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_isRecurrenceOrMultiDays() &&
            _endDate != null &&
            _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime(now.year + 2),
      initialDate: _endDate ?? start,
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ✅ UPDATED: pick start time -> auto end time = start + 30 mins (or fix invalid)
  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _ensureMinEndTime(); // ✅ enforce minimum duration
      });
    }
  }

  // ✅ UPDATED: pick end time -> cannot be < start + 30 mins (auto-correct)
  // ✅ supports cross-midnight
  Future<void> _pickEndTime() async {
    final start = _startTime;

    // If start not picked yet, allow normal pick
    if (start == null) {
      final picked = await showTimePicker(
        context: context,
        initialTime: _endTime ?? TimeOfDay.now(),
      );
      if (picked != null) setState(() => _endTime = picked);
      return;
    }

    final minEnd = _addMinutes(start, _minBookingMinutes);

    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? minEnd,
    );

    if (picked != null) {
      final isValid = _isEndValid(start, picked);

      setState(() {
        _endTime = isValid ? picked : minEnd;
      });

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Minimum booking time is 30 minutes."),
          ),
        );
      }
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTimeUi(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $suffix';
  }

  bool _isRecurrenceOrMultiDays() =>
      _bookingTypeId == BookingTypeIds.recurrence ||
      _bookingTypeId == BookingTypeIds.multiDays;

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ✅ FIXED: build correct end datetime (moves to next day when end is earlier than start)
  DateTime _buildEndDateTime(DateTime startDate, TimeOfDay start, TimeOfDay end) {
    final startDT = _combine(startDate, start);
    var endDT = _combine(startDate, end);

    if (!endDT.isAfter(startDT)) {
      endDT = endDT.add(const Duration(days: 1));
    }
    return endDT;
  }

  /* ============================== BOOKING TYPE ============================== */

  void _pickTaskerLevel(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTaskerLevelId = id;
      if (_showErrors) _showErrors = false;
    });
  }

  void _setBookingType(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _bookingTypeId = id;

      if (_bookingTypeId == BookingTypeIds.asap) {
        _selectedDate = DateTime.now();
        _endDate = null;
      } else {
        _selectedDate ??= DateTime.now();
      }

      if (_bookingTypeId != BookingTypeIds.recurrence) {
        _recurrencePatternId = RecurrencePatternIds.daily;
        _selectedWeekdays.clear();
      }

      if (_bookingTypeId == BookingTypeIds.multiDays) {
        _endDate ??= _selectedDate;
      } else if (_bookingTypeId == BookingTypeIds.future ||
          _bookingTypeId == BookingTypeIds.asap) {
        _endDate = null;
      }
    });
  }

  void _setRecurrencePattern(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _recurrencePatternId = id;
      if (id != RecurrencePatternIds.customDays) {
        _selectedWeekdays.clear();
      }
    });
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  /* ============================== HELPERS ============================== */

  int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

  double _resolveLat() => _pickedLat ?? 0.0;
  double _resolveLng() => _pickedLng ?? 0.0;

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "Monday";
    }
  }

  String _buildCustomDaysString() {
    final list = _selectedWeekdays.toList()..sort();
    return list.map(_weekdayName).join(',');
  }

  bool _validate() {
    final hasBase = _selectedSubcategory != null &&
        _startTime != null &&
        _endTime != null &&
        _manualLocationCtrl.text.trim().isNotEmpty &&
        _selectedTaskerLevelId != null &&
        _selectedDate != null;

    if (!hasBase) return false;

    // ✅ UPDATED: enforce minimum 30 minutes (supports cross-midnight)
    if (!_isEndValid(_startTime!, _endTime!)) return false;

    if (_bookingTypeId == BookingTypeIds.recurrence) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;
      if (_recurrencePatternId == RecurrencePatternIds.customDays &&
          _selectedWeekdays.isEmpty) return false;
    }

    if (_bookingTypeId == BookingTypeIds.multiDays) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;
    }

    return true;
  }

  void _onSubmit() {
    setState(() => _showErrors = true);

    // ✅ keep end time always corrected before validate/submit
    setState(() {
      _ensureMinEndTime();
    });

    if (!_validate()) return;

    _navigated = false;

    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.userDetails?.userId.toString();
    if (userId == null || userId.isEmpty) return;

    final startDate = _selectedDate!;
    final startDateTime = _combine(startDate, _startTime!);

    // ✅ FIXED: correct end datetime (next day if needed)
    final endDateTime = _buildEndDateTime(startDate, _startTime!, _endTime!);

    final serviceIdForApi = _resolveServiceIdForApi();

    int bookingTypeId = _bookingTypeId;
    int? recurrencePatternId;
    String? customDays;
    DateTime? endDateForApi;

    if (_bookingTypeId == BookingTypeIds.asap ||
        _bookingTypeId == BookingTypeIds.future) {
      endDateForApi = null;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.multiDays) {
      endDateForApi = _endDate;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.recurrence) {
      endDateForApi = _endDate;
      recurrencePatternId = _recurrencePatternId;
      if (_recurrencePatternId == RecurrencePatternIds.customDays) {
        customDays = _buildCustomDaysString();
      }
    }

    context.read<UserBookingBloc>().add(
          CreateUserBookingRequested(
            userId: userId,
            subCategoryId: serviceIdForApi,
            bookingTypeId: bookingTypeId,
            bookingDate: startDate,
            startTime: startDateTime.toUtc().toIso8601String(),
            endTime: endDateTime.toUtc().toIso8601String(),
            endDate: endDateForApi,
            recurrencePatternId: recurrencePatternId,
            customDays: customDays,
            address: _manualLocationCtrl.text.trim(),
            taskerLevelId: _selectedTaskerLevelId!,
            latitude: _resolveLat(),
            longitude: _resolveLng(),
          ),
        );
  }

  /* ============================== PLACES (CUSTOM SEARCH) ============================== */

  void _removeLocOverlay() {
    _locOverlay?.remove();
    _locOverlay = null;
  }

  void _showLocOverlay() {
    if (_locOverlay != null) return;

    _locOverlay = OverlayEntry(
      builder: (context) {
        final t = _UiTokens.of(context);
        final width = MediaQuery.of(context).size.width - 32; // same page padding

        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              _removeLocOverlay();
            },
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _locLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 58),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: width,
                      constraints: const BoxConstraints(maxHeight: 270),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(.96),
                        border: Border.all(color: t.primary.withOpacity(.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.10),
                            blurRadius: 22,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: _locLoading
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation(t.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Searching...',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: t.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: _locPredictions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.black.withOpacity(.06),
                              ),
                              itemBuilder: (_, i) {
                                final p = _locPredictions[i];
                                final main = p.structuredFormatting?.mainText ??
                                    p.description ??
                                    '';
                                final secondary =
                                    p.structuredFormatting?.secondaryText ?? '';

                                return InkWell(
                                  onTap: () => _selectPrediction(p),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            color: t.primary.withOpacity(.10),
                                            border: Border.all(
                                                color:
                                                    t.primary.withOpacity(.14)),
                                          ),
                                          child: Icon(Icons.place_rounded,
                                              color: t.primaryDark, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                main,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: t.primaryText,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (secondary.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  secondary,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: t.mutedText,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            color: t.primaryDark),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_locOverlay!);
  }

  Future<void> _searchPlaces(String input) async {
    final q = input.trim();
    if (q.length < 3) {
      if (!mounted) return;
      setState(() {
        _locPredictions = [];
        _locLoading = false;
      });
      _removeLocOverlay();
      return;
    }

    setState(() => _locLoading = true);
    if (_locFocus.hasFocus) _showLocOverlay();

    try {
      final res = await _googlePlace.autocomplete.get(
        q,
        components: [Component('country', 'au')],
        types: 'geocode',
      );

      final preds = res?.predictions ?? <AutocompletePrediction>[];
      if (!mounted) return;

      setState(() {
        _locPredictions = preds;
        _locLoading = false;
      });

      if (_locPredictions.isEmpty) {
        _removeLocOverlay();
      } else if (_locFocus.hasFocus) {
        _showLocOverlay();
        _locOverlay?.markNeedsBuild();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locPredictions = [];
        _locLoading = false;
      });
      _removeLocOverlay();
    }
  }

  Future<void> _selectPrediction(AutocompletePrediction p) async {
    final desc = p.description ?? '';
    final placeId = p.placeId;

    _manualLocationCtrl.text = desc;
    _manualLocationCtrl.selection =
        TextSelection.fromPosition(TextPosition(offset: desc.length));

    _lastCommittedAddress = desc.trim();
    _pickedPlaceId = placeId;

    _removeLocOverlay();
    FocusScope.of(context).unfocus();

    if (placeId == null) return;

    try {
      final details = await _googlePlace.details.get(placeId);
      final loc = details?.result?.geometry?.location;
      if (!mounted) return;

      setState(() {
        _pickedLat = loc?.lat;
        _pickedLng = loc?.lng;
      });
    } catch (_) {
      // ignore
    }
  }

  /* ============================== UI ============================== */

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);
    final subs = widget.group.services;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(t),
        body: BlocConsumer<UserBookingBloc, UserBookingState>(
          listenWhen: (prev, curr) =>
              prev.createStatus != curr.createStatus ||
              prev.bookingCreateResponse != curr.bookingCreateResponse ||
              prev.createError != curr.createError,
          listener: (context, state) {
            if (state.createStatus == UserBookingCreateStatus.success) {
              final firstDetailId =
                  state.bookingCreateResponse?.result?.isNotEmpty == true
                      ? state.bookingCreateResponse!.result!.first.bookingDetailId
                      : null;

              if (firstDetailId == null) return;
              if (_navigated) return;
              _navigated = true;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FindingYourTaskerScreen(
                    bookingid: firstDetailId.toString(),
                    id: firstDetailId.toString(),
                  ),
                ),
              );
            }

            if (state.createStatus == UserBookingCreateStatus.failure) {
              _navigated = false;
              final msg = state.createError ?? "Booking failed";
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          builder: (context, state) {
            final isLoading =
                state.createStatus == UserBookingCreateStatus.submitting;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroHeader(t: t, title: widget.group.name),
                    const SizedBox(height: 14),

                    _Glass(
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitleModern(
                              t: t,
                              icon: Icons.list_alt_rounded,
                              title: "Service details",
                              subtitle: "Pick service & schedule in minutes",
                            ),
                            const SizedBox(height: 14),

                            _FieldModern(
                              t: t,
                              label: "Subcategory",
                              prefixIcon: Icons.category_rounded,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ServiceOption>(
                                  isExpanded: true,
                                  value: _selectedSubcategory,
                                  icon: Icon(Icons.expand_more_rounded,
                                      color: t.primaryDark),
                                  hint: Text(
                                    "Select subcategory",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: t.mutedText.withOpacity(.9),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  items: subs.map((s) {
                                    return DropdownMenuItem<ServiceOption>(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: t.primaryText,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedSubcategory = val),
                                ),
                              ),
                              errorText:
                                  (_showErrors && _selectedSubcategory == null)
                                      ? "Please select a subcategory"
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.category_rounded,
                              title: "Booking type",
                              subtitle: "ASAP, future, recurring or multi-day",
                            ),
                            const SizedBox(height: 12),

                            _TypeGrid(
                              t: t,
                              bookingTypeId: _bookingTypeId,
                              recurrencePatternId: _recurrencePatternId,
                              onPick: (typeId, pattId) {
                                _setBookingType(typeId);
                                if (pattId != null) _setRecurrencePattern(pattId);
                              },
                            ),

                            if (_bookingTypeId == BookingTypeIds.recurrence &&
                                _recurrencePatternId ==
                                    RecurrencePatternIds.customDays) ...[
                              const SizedBox(height: 12),
                              Text(
                                "Select days",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: t.primaryText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DayChipModern(
                                      t: t,
                                      label: "Mon",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.monday),
                                      onTap: () => _toggleDay(DateTime.monday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Tue",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.tuesday),
                                      onTap: () => _toggleDay(DateTime.tuesday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Wed",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.wednesday),
                                      onTap: () =>
                                          _toggleDay(DateTime.wednesday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Thu",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.thursday),
                                      onTap: () =>
                                          _toggleDay(DateTime.thursday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Fri",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.friday),
                                      onTap: () => _toggleDay(DateTime.friday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Sat",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.saturday),
                                      onTap: () =>
                                          _toggleDay(DateTime.saturday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Sun",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.sunday),
                                      onTap: () => _toggleDay(DateTime.sunday)),
                                ],
                              ),
                              if (_showErrors && _selectedWeekdays.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "Please select at least one day",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.red.withOpacity(.9),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.calendar_month_rounded,
                              title: "Schedule",
                              subtitle: "Pick date & time window",
                            ),
                            const SizedBox(height: 12),

                            _FieldModern(
                              t: t,
                              label: _isRecurrenceOrMultiDays()
                                  ? "Start date"
                                  : "Booking date",
                              prefixIcon: Icons.event_rounded,
                              onTap: _bookingTypeId == BookingTypeIds.asap
                                  ? null
                                  : _pickStartDate,
                              trailing: Icon(
                                _bookingTypeId == BookingTypeIds.asap
                                    ? Icons.lock_rounded
                                    : Icons.chevron_right_rounded,
                                color: t.primaryDark,
                              ),
                              child: Text(
                                _bookingTypeId == BookingTypeIds.asap
                                    ? _fmtDate(DateTime.now())
                                    : _fmtDate(_selectedDate),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: (_selectedDate == null)
                                      ? t.mutedText
                                      : t.primaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              errorText: (_showErrors && _selectedDate == null)
                                  ? "Please select a date"
                                  : null,
                            ),

                            if (_isRecurrenceOrMultiDays()) ...[
                              const SizedBox(height: 12),
                              _FieldModern(
                                t: t,
                                label: "End date",
                                prefixIcon: Icons.date_range_rounded,
                                onTap: _pickEndDate,
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: t.primaryDark),
                                child: Text(
                                  _fmtDate(_endDate),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _endDate == null
                                        ? t.mutedText
                                        : t.primaryText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                errorText: (_showErrors && _endDate == null)
                                    ? "Please select end date"
                                    : null,
                              ),
                            ],

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _TimePill(
                                    t: t,
                                    label: "Start time",
                                    value: _fmtTimeUi(_startTime),
                                    onTap: _pickStartTime,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TimePill(
                                    t: t,
                                    label: "End time",
                                    value: _fmtTimeUi(_endTime),
                                    onTap: _pickEndTime,
                                  ),
                                ),
                              ],
                            ),

                            if (_showErrors &&
                                (_startTime == null || _endTime == null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Please select both start & end time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            // ✅ UPDATED: error uses 30-min rule with cross-midnight support
                            if (_showErrors &&
                                _startTime != null &&
                                _endTime != null &&
                                !_isEndValid(_startTime!, _endTime!))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "End time must be at least 30 minutes after start time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.place_rounded,
                              title: "Location",
                              subtitle: "Search address with Google Places",
                            ),
                            const SizedBox(height: 12),

                            _buildLocationField(t),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.workspace_premium_rounded,
                              title: "Tasker level",
                              subtitle: "Choose standard or pro",
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _LevelCardModern(
                                    t: t,
                                    title: "Tasker",
                                    subtitle: "Standard",
                                    selected: _selectedTaskerLevelId == 1,
                                    onTap: () => _pickTaskerLevel(1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _LevelCardModern(
                                    t: t,
                                    title: "Pro tasker",
                                    subtitle: "Premium",
                                    selected: _selectedTaskerLevelId == 2,
                                    onTap: () => _pickTaskerLevel(2),
                                  ),
                                ),
                              ],
                            ),

                            if (_showErrors && _selectedTaskerLevelId == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Please select tasker level",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: t.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isLoading ? null : _onSubmit,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isLoading
                              ? const SizedBox(
                                  key: ValueKey("loading"),
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  key: ValueKey("normal"),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      "FIND TASKER",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_UiTokens t) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _Glass(
                radius: 16,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.chevron_left_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Service booking",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: t.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(_UiTokens t) {
    final hasPinned = _pickedLat != null && _pickedLng != null;

    return _FieldModern(
      t: t,
      label: "Location",
      prefixIcon: Icons.place_rounded,
      helperText: hasPinned ? "Pinned" : "Search",
      errorText: (_showErrors && _manualLocationCtrl.text.trim().isEmpty)
          ? "Please enter location"
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPinned)
            Icon(Icons.verified_rounded, size: 20, color: t.primaryDark),
          if (_manualLocationCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _manualLocationCtrl.clear();
                  _pickedLat = null;
                  _pickedLng = null;
                  _pickedPlaceId = null;
                  _locPredictions = [];
                  _lastCommittedAddress = "";
                });
                _removeLocOverlay();
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18, color: t.mutedText),
              ),
            ),
          ],
        ],
      ),
      child: CompositedTransformTarget(
        link: _locLink,
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: _manualLocationCtrl,
            focusNode: _locFocus,
            keyboardType: TextInputType.streetAddress,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: t.primaryText,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              isCollapsed: true,
              contentPadding: const EdgeInsets.only(top: 12.5),
              hintText: "Enter your address / house / suburb",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                color: t.mutedText.withOpacity(.85),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onTap: () {
              if (_locPredictions.isNotEmpty) _showLocOverlay();
            },
            onChanged: (v) {
              _placesDebounce?.cancel();
              _placesDebounce = Timer(const Duration(milliseconds: 450), () {
                if (!mounted) return;
                _searchPlaces(v);
              });
            },
          ),
        ),
      ),
    );
  }
}

/* ============================== TOKENS + GLASS ============================== */

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color primaryText;
  final Color mutedText;
  final Color bg;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.primaryText,
    required this.mutedText,
    required this.bg,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF7841BA),
        primaryDark: Color(0xFF5C2E91),
        primaryText: Color(0xFF3E1E69),
        mutedText: Color(0xFF75748A),
        bg: Color(0xFFF8F7FB),
      );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
            border: Border.all(color: t.primary.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ============================== MODERN HEADER ============================== */

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.t, required this.title});
  final _UiTokens t;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.primary.withOpacity(.14),
            t.primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: t.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: t.primary.withOpacity(.10),
              border: Border.all(color: t.primary.withOpacity(.14)),
            ),
            child: Icon(Icons.task_alt_rounded, color: t.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Book service",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
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

/* ============================== SECTION TITLE ============================== */

class _SectionTitleModern extends StatelessWidget {
  const _SectionTitleModern({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _UiTokens t;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: t.primary.withOpacity(.10),
            border: Border.all(color: t.primary.withOpacity(.14)),
          ),
          child: Icon(icon, color: t.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================== FIELD MODERN ============================== */

class _FieldModern extends StatelessWidget {
  const _FieldModern({
    required this.t,
    required this.label,
    required this.child,
    this.prefixIcon,
    this.helperText,
    this.errorText,
    this.trailing,
    this.onTap,
  });

  final _UiTokens t;
  final String label;
  final Widget child;

  final IconData? prefixIcon;
  final String? helperText;
  final String? errorText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    final field = _Glass(
      radius: 18,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasError
                ? Colors.red.withOpacity(.35)
                : t.primary.withOpacity(.14),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.primary.withOpacity(.10),
                  border: Border.all(color: t.primary.withOpacity(.12)),
                ),
                child: Icon(prefixIcon, color: t.primaryDark, size: 20),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: child),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (helperText != null && !hasError)
              Text(
                helperText!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        onTap == null
            ? field
            : InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: field,
              ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.red.withOpacity(.9),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]
      ],
    );
  }
}

/* ============================== TYPE GRID ============================== */

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.t,
    required this.bookingTypeId,
    required this.recurrencePatternId,
    required this.onPick,
  });

  final _UiTokens t;
  final int bookingTypeId;
  final int recurrencePatternId;
  final void Function(int typeId, int? recurrencePatternId) onPick;

  bool _sel(int typeId, {int? patt}) {
    if (typeId == BookingTypeIds.recurrence) {
      return bookingTypeId == BookingTypeIds.recurrence &&
          recurrencePatternId == (patt ?? recurrencePatternId);
    }
    return bookingTypeId == typeId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "ASAP",
                subtitle: "Today",
                selected: _sel(BookingTypeIds.asap),
                onTap: () => onPick(BookingTypeIds.asap, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Future",
                subtitle: "Schedule",
                selected: _sel(BookingTypeIds.future),
                onTap: () => onPick(BookingTypeIds.future, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Multi days",
                subtitle: "Range",
                selected: _sel(BookingTypeIds.multiDays),
                onTap: () => onPick(BookingTypeIds.multiDays, null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Daily",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.daily),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.daily),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Weekly",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.weekly),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.weekly),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Monthly",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.monthly),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.monthly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Custom days",
                subtitle: "Pick days",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.customDays),
                onTap: () => onPick(BookingTypeIds.recurrence,
                    RecurrencePatternIds.customDays),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? t.primary.withOpacity(.10) : Colors.white;
    final border =
        selected ? t.primary.withOpacity(.35) : t.primary.withOpacity(.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
          border: Border.all(color: border, width: selected ? 1.8 : 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: selected ? t.primaryDark : t.primaryDark.withOpacity(.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== DAY CHIP ============================== */

class _DayChipModern extends StatelessWidget {
  const _DayChipModern({
    required this.t,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.primary.withOpacity(.14) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? t.primary : Colors.black.withOpacity(.10),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            color: selected ? t.primaryDark : t.primaryText,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/* ============================== TIME PILL ============================== */

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.t,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final _UiTokens t;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value == 'Pick time' || value.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: _Glass(
        radius: 18,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.primary.withOpacity(.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.primary.withOpacity(.10),
                  border: Border.all(color: t.primary.withOpacity(.12)),
                ),
                child: Icon(Icons.access_time_rounded,
                    size: 18, color: t.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  empty ? label : value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: empty ? t.mutedText : t.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== LEVEL CARD ============================== */

class _LevelCardModern extends StatelessWidget {
  const _LevelCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? t.primary.withOpacity(.10) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: bg,
          border: Border.all(
            color: selected ? t.primary.withOpacity(.40) : t.primary.withOpacity(.14),
            width: selected ? 1.8 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.primary.withOpacity(.18),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? Icon(CupertinoIcons.check_mark_circled_solid,
                      key: const ValueKey("sel"),
                      size: 22,
                      color: t.primaryDark)
                  : const SizedBox(
                      key: ValueKey("nosel"),
                      width: 22,
                      height: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


// class BookingTypeIds {
//   static const int asap = 1;
//   static const int future = 2;
//   static const int recurrence = 3;
//   static const int multiDays = 4;
// }

// class RecurrencePatternIds {
//   static const int daily = 1;
//   static const int monthly = 2;
//   static const int weekly = 3;
//   static const int customDays = 4;
// }

// /* ============================== SCREEN ============================== */

// class ServiceBookingFormScreen extends StatefulWidget {
//   final CertificationGroup group;
//   final ServiceOption? initialService;

//   /// API expects SubCategoryId
//   final int serviceId;

//   const ServiceBookingFormScreen({
//     super.key,
//     required this.group,
//     this.initialService,
//     required this.serviceId,
//   });

//   @override
//   State<ServiceBookingFormScreen> createState() =>
//       _ServiceBookingFormScreenState();
// }

// class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
//   // ✅ Put your key here
//   static const String _googlePlacesKey =
//       "AIzaSyBFIEDQXjgT6djAIrXB466aR1oG5EmXojQ";

//   // ✅ booking minimum duration
//   static const int _minBookingMinutes = 30;

//   // selections
//   ServiceOption? _selectedSubcategory;
//   int? _selectedTaskerLevelId;

//   // booking mode
//   int _bookingTypeId = BookingTypeIds.asap;

//   // recurrence
//   int _recurrencePatternId = RecurrencePatternIds.daily;
//   final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

//   // dates/times
//   DateTime? _selectedDate; // start date
//   DateTime? _endDate; // recurrence/multi-days
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;

//   // form
//   final _manualLocationCtrl = TextEditingController();
//   bool _showErrors = false;

//   // navigation guard
//   bool _navigated = false;

//   /* ===================== PLACES (CUSTOM UI) ===================== */

//   late final GooglePlace _googlePlace;
//   Timer? _placesDebounce;

//   final FocusNode _locFocus = FocusNode();
//   final LayerLink _locLink = LayerLink();

//   OverlayEntry? _locOverlay;
//   List<AutocompletePrediction> _locPredictions = [];
//   bool _locLoading = false;

//   double? _pickedLat;
//   double? _pickedLng;
//   String? _pickedPlaceId;
//   String _lastCommittedAddress = "";

//   @override
//   void initState() {
//     super.initState();

//     _selectedSubcategory = widget.initialService;
//     _selectedSubcategory ??= widget.group.services.firstWhere(
//       (s) => s.id == widget.serviceId,
//       orElse: () => widget.group.services.isNotEmpty
//           ? widget.group.services.first
//           : ServiceOption(id: widget.serviceId, name: ''),
//     );

//     _selectedDate = DateTime.now();

//     _googlePlace = GooglePlace(_googlePlacesKey);

//     _locFocus.addListener(() {
//       if (!_locFocus.hasFocus) {
//         _removeLocOverlay();
//       } else {
//         if (_locPredictions.isNotEmpty) _showLocOverlay();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _placesDebounce?.cancel();
//     _removeLocOverlay();
//     _locFocus.dispose();
//     _manualLocationCtrl.dispose();
//     super.dispose();
//   }

//   /* ============================== DATE/TIME ============================== */

//   // ✅ Time helpers
//   int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;

//   TimeOfDay _fromMinutes(int totalMinutes) {
//     totalMinutes = totalMinutes % (24 * 60);
//     final h = totalMinutes ~/ 60;
//     final m = totalMinutes % 60;
//     return TimeOfDay(hour: h, minute: m);
//   }

//   TimeOfDay _addMinutes(TimeOfDay t, int minutes) =>
//       _fromMinutes(_toMinutes(t) + minutes);

//   bool _isEndValid(TimeOfDay start, TimeOfDay end) {
//     return _toMinutes(end) >= _toMinutes(start) + _minBookingMinutes;
//   }

//   void _ensureMinEndTime() {
//     if (_startTime == null) return;
//     final minEnd = _addMinutes(_startTime!, _minBookingMinutes);

//     // if end is null OR invalid, force it to minimum end
//     if (_endTime == null || !_isEndValid(_startTime!, _endTime!)) {
//       _endTime = minEnd;
//     }
//   }

//   Future<void> _pickStartDate() async {
//     final now = DateTime.now();
//     final initial = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: now,
//       lastDate: DateTime(now.year + 2),
//       initialDate: initial.isBefore(now) ? now : initial,
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//         if (_isRecurrenceOrMultiDays() &&
//             _endDate != null &&
//             _endDate!.isBefore(picked)) {
//           _endDate = null;
//         }
//       });
//     }
//   }

//   Future<void> _pickEndDate() async {
//     final now = DateTime.now();
//     final start = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: start,
//       lastDate: DateTime(now.year + 2),
//       initialDate: _endDate ?? start,
//     );
//     if (picked != null) setState(() => _endDate = picked);
//   }

//   // ✅ UPDATED: pick start time -> auto end time = start + 30 mins (or fix invalid)
//   Future<void> _pickStartTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _startTime = picked;
//         _ensureMinEndTime(); // ✅ enforce minimum duration
//       });
//     }
//   }

//   // ✅ UPDATED: pick end time -> cannot be < start + 30 mins (auto-correct)
//   Future<void> _pickEndTime() async {
//     final start = _startTime;

//     // If start not picked yet, allow normal pick (or you can force start first)
//     if (start == null) {
//       final picked = await showTimePicker(
//         context: context,
//         initialTime: _endTime ?? TimeOfDay.now(),
//       );
//       if (picked != null) setState(() => _endTime = picked);
//       return;
//     }

//     final minEnd = _addMinutes(start, _minBookingMinutes);

//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime ?? minEnd,
//     );

//     if (picked != null) {
//       final isValid = _isEndValid(start, picked);

//       setState(() {
//         _endTime = isValid ? picked : minEnd;
//       });

//       if (!isValid) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Minimum booking time is 30 minutes."),
//           ),
//         );
//       }
//     }
//   }

//   String _fmtDate(DateTime? d) =>
//       d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

//   String _fmtTimeUi(TimeOfDay? t) {
//     if (t == null) return 'Pick time';
//     final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
//     final minute = t.minute.toString().padLeft(2, '0');
//     final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
//     return '$hour12:$minute $suffix';
//   }

//   bool _isRecurrenceOrMultiDays() =>
//       _bookingTypeId == BookingTypeIds.recurrence ||
//       _bookingTypeId == BookingTypeIds.multiDays;

//   DateTime _combine(DateTime date, TimeOfDay time) {
//     return DateTime(date.year, date.month, date.day, time.hour, time.minute);
//   }

//   /* ============================== BOOKING TYPE ============================== */

//   void _pickTaskerLevel(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _selectedTaskerLevelId = id;
//       if (_showErrors) _showErrors = false;
//     });
//   }

//   void _setBookingType(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _bookingTypeId = id;

//       if (_bookingTypeId == BookingTypeIds.asap) {
//         _selectedDate = DateTime.now();
//         _endDate = null;
//       } else {
//         _selectedDate ??= DateTime.now();
//       }

//       if (_bookingTypeId != BookingTypeIds.recurrence) {
//         _recurrencePatternId = RecurrencePatternIds.daily;
//         _selectedWeekdays.clear();
//       }

//       if (_bookingTypeId == BookingTypeIds.multiDays) {
//         _endDate ??= _selectedDate;
//       } else if (_bookingTypeId == BookingTypeIds.future ||
//           _bookingTypeId == BookingTypeIds.asap) {
//         _endDate = null;
//       }
//     });
//   }

//   void _setRecurrencePattern(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _recurrencePatternId = id;
//       if (id != RecurrencePatternIds.customDays) {
//         _selectedWeekdays.clear();
//       }
//     });
//   }

//   void _toggleDay(int weekday) {
//     setState(() {
//       if (_selectedWeekdays.contains(weekday)) {
//         _selectedWeekdays.remove(weekday);
//       } else {
//         _selectedWeekdays.add(weekday);
//       }
//     });
//   }

//   /* ============================== HELPERS ============================== */

//   int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

//   double _resolveLat() => _pickedLat ?? 0.0;
//   double _resolveLng() => _pickedLng ?? 0.0;

//   String _weekdayName(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return "Monday";
//       case DateTime.tuesday:
//         return "Tuesday";
//       case DateTime.wednesday:
//         return "Wednesday";
//       case DateTime.thursday:
//         return "Thursday";
//       case DateTime.friday:
//         return "Friday";
//       case DateTime.saturday:
//         return "Saturday";
//       case DateTime.sunday:
//         return "Sunday";
//       default:
//         return "Monday";
//     }
//   }

//   String _buildCustomDaysString() {
//     final list = _selectedWeekdays.toList()..sort();
//     return list.map(_weekdayName).join(',');
//   }

//   bool _validate() {
//     final hasBase = _selectedSubcategory != null &&
//         _startTime != null &&
//         _endTime != null &&
//         _manualLocationCtrl.text.trim().isNotEmpty &&
//         _selectedTaskerLevelId != null &&
//         _selectedDate != null;

//     if (!hasBase) return false;

//     // ✅ UPDATED: enforce minimum 30 minutes
//     final startM = _toMinutes(_startTime!);
//     final endM = _toMinutes(_endTime!);
//     if (endM < startM + _minBookingMinutes) return false;

//     if (_bookingTypeId == BookingTypeIds.recurrence) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;
//       if (_recurrencePatternId == RecurrencePatternIds.customDays &&
//           _selectedWeekdays.isEmpty) return false;
//     }

//     if (_bookingTypeId == BookingTypeIds.multiDays) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;
//     }

//     return true;
//   }

//   void _onSubmit() {
//     setState(() => _showErrors = true);

//     // ✅ keep end time always corrected before validate/submit
//     setState(() {
//       _ensureMinEndTime();
//     });

//     if (!_validate()) return;

//     _navigated = false;

//     final authState = context.read<AuthenticationBloc>().state;
//     final userId = authState.userDetails?.userId.toString();
//     if (userId == null || userId.isEmpty) return;

//     final startDate = _selectedDate!;
//     final startDateTime = _combine(startDate, _startTime!);
//     final endDateTime = _combine(startDate, _endTime!);

//     final serviceIdForApi = _resolveServiceIdForApi();

//     int bookingTypeId = _bookingTypeId;
//     int? recurrencePatternId;
//     String? customDays;
//     DateTime? endDateForApi;

//     if (_bookingTypeId == BookingTypeIds.asap ||
//         _bookingTypeId == BookingTypeIds.future) {
//       endDateForApi = null;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.multiDays) {
//       endDateForApi = _endDate;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.recurrence) {
//       endDateForApi = _endDate;
//       recurrencePatternId = _recurrencePatternId;
//       if (_recurrencePatternId == RecurrencePatternIds.customDays) {
//         customDays = _buildCustomDaysString();
//       }
//     }

//     context.read<UserBookingBloc>().add(
//           CreateUserBookingRequested(
//             userId: userId,
//             subCategoryId: serviceIdForApi,
//             bookingTypeId: bookingTypeId,
//             bookingDate: startDate,
//             startTime: startDateTime.toUtc().toIso8601String(),
//             endTime: endDateTime.toUtc().toIso8601String(),
//             endDate: endDateForApi,
//             recurrencePatternId: recurrencePatternId,
//             customDays: customDays,
//             address: _manualLocationCtrl.text.trim(),
//             taskerLevelId: _selectedTaskerLevelId!,
//             latitude: _resolveLat(),
//             longitude: _resolveLng(),
//           ),
//         );
//   }

//   /* ============================== PLACES (CUSTOM SEARCH) ============================== */

//   void _removeLocOverlay() {
//     _locOverlay?.remove();
//     _locOverlay = null;
//   }

//   void _showLocOverlay() {
//     if (_locOverlay != null) return;

//     _locOverlay = OverlayEntry(
//       builder: (context) {
//         final t = _UiTokens.of(context);
//         final width = MediaQuery.of(context).size.width - 32; // same page padding

//         return Positioned.fill(
//           child: GestureDetector(
//             behavior: HitTestBehavior.translucent,
//             onTap: () {
//               FocusScope.of(context).unfocus();
//               _removeLocOverlay();
//             },
//             child: Stack(
//               children: [
//                 CompositedTransformFollower(
//                   link: _locLink,
//                   showWhenUnlinked: false,
//                   offset: const Offset(0, 58),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Container(
//                       width: width,
//                       constraints: const BoxConstraints(maxHeight: 270),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(18),
//                         color: Colors.white.withOpacity(.96),
//                         border: Border.all(color: t.primary.withOpacity(.12)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(.10),
//                             blurRadius: 22,
//                             offset: const Offset(0, 14),
//                           ),
//                         ],
//                       ),
//                       child: _locLoading
//                           ? Padding(
//                               padding: const EdgeInsets.all(14),
//                               child: Row(
//                                 children: [
//                                   SizedBox(
//                                     width: 18,
//                                     height: 18,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2.4,
//                                       valueColor:
//                                           AlwaysStoppedAnimation(t.primary),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     'Searching...',
//                                     style: TextStyle(
//                                       fontFamily: 'Poppins',
//                                       color: t.mutedText,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           : ListView.separated(
//                               padding: const EdgeInsets.symmetric(vertical: 6),
//                               itemCount: _locPredictions.length,
//                               separatorBuilder: (_, __) => Divider(
//                                 height: 1,
//                                 thickness: 1,
//                                 color: Colors.black.withOpacity(.06),
//                               ),
//                               itemBuilder: (_, i) {
//                                 final p = _locPredictions[i];
//                                 final main = p.structuredFormatting?.mainText ??
//                                     p.description ??
//                                     '';
//                                 final secondary =
//                                     p.structuredFormatting?.secondaryText ?? '';

//                                 return InkWell(
//                                   onTap: () => _selectPrediction(p),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 12, vertical: 12),
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           width: 36,
//                                           height: 36,
//                                           decoration: BoxDecoration(
//                                             borderRadius:
//                                                 BorderRadius.circular(14),
//                                             color: t.primary.withOpacity(.10),
//                                             border: Border.all(
//                                                 color:
//                                                     t.primary.withOpacity(.14)),
//                                           ),
//                                           child: Icon(Icons.place_rounded,
//                                               color: t.primaryDark, size: 18),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 main,
//                                                 maxLines: 1,
//                                                 overflow: TextOverflow.ellipsis,
//                                                 style: TextStyle(
//                                                   fontFamily: 'Poppins',
//                                                   color: t.primaryText,
//                                                   fontWeight: FontWeight.w900,
//                                                   fontSize: 13,
//                                                 ),
//                                               ),
//                                               if (secondary.isNotEmpty) ...[
//                                                 const SizedBox(height: 2),
//                                                 Text(
//                                                   secondary,
//                                                   maxLines: 1,
//                                                   overflow:
//                                                       TextOverflow.ellipsis,
//                                                   style: TextStyle(
//                                                     fontFamily: 'Poppins',
//                                                     color: t.mutedText,
//                                                     fontWeight: FontWeight.w600,
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ],
//                                           ),
//                                         ),
//                                         Icon(Icons.chevron_right_rounded,
//                                             color: t.primaryDark),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     Overlay.of(context).insert(_locOverlay!);
//   }

//   Future<void> _searchPlaces(String input) async {
//     final q = input.trim();
//     if (q.length < 3) {
//       if (!mounted) return;
//       setState(() {
//         _locPredictions = [];
//         _locLoading = false;
//       });
//       _removeLocOverlay();
//       return;
//     }

//     setState(() => _locLoading = true);
//     if (_locFocus.hasFocus) _showLocOverlay();

//     try {
//       final res = await _googlePlace.autocomplete.get(
//         q,
//         components: [Component('country', 'au')],
//         types: 'geocode',
//       );

//       final preds = res?.predictions ?? <AutocompletePrediction>[];
//       if (!mounted) return;

//       setState(() {
//         _locPredictions = preds;
//         _locLoading = false;
//       });

//       if (_locPredictions.isEmpty) {
//         _removeLocOverlay();
//       } else if (_locFocus.hasFocus) {
//         _showLocOverlay();
//         _locOverlay?.markNeedsBuild();
//       }
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _locPredictions = [];
//         _locLoading = false;
//       });
//       _removeLocOverlay();
//     }
//   }

//   Future<void> _selectPrediction(AutocompletePrediction p) async {
//     final desc = p.description ?? '';
//     final placeId = p.placeId;

//     _manualLocationCtrl.text = desc;
//     _manualLocationCtrl.selection =
//         TextSelection.fromPosition(TextPosition(offset: desc.length));

//     _lastCommittedAddress = desc.trim();
//     _pickedPlaceId = placeId;

//     _removeLocOverlay();
//     FocusScope.of(context).unfocus();

//     if (placeId == null) return;

//     try {
//       final details = await _googlePlace.details.get(placeId);
//       final loc = details?.result?.geometry?.location;
//       if (!mounted) return;

//       setState(() {
//         _pickedLat = loc?.lat;
//         _pickedLng = loc?.lng;
//       });
//     } catch (_) {
//       // ignore
//     }
//   }

//   /* ============================== UI ============================== */

//   @override
//   Widget build(BuildContext context) {
//     final t = _UiTokens.of(context);
//     final subs = widget.group.services;

//     return Theme(
//       data: Theme.of(context).copyWith(
//         scaffoldBackgroundColor: t.bg,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           surfaceTintColor: Colors.transparent,
//           elevation: 0,
//         ),
//       ),
//       child: Scaffold(
//         appBar: _buildAppBar(t),
//         body: BlocConsumer<UserBookingBloc, UserBookingState>(
//           listenWhen: (prev, curr) =>
//               prev.createStatus != curr.createStatus ||
//               prev.bookingCreateResponse != curr.bookingCreateResponse ||
//               prev.createError != curr.createError,
//           listener: (context, state) {
//             if (state.createStatus == UserBookingCreateStatus.success) {
//               final firstDetailId =
//                   state.bookingCreateResponse?.result?.isNotEmpty == true
//                       ? state.bookingCreateResponse!.result!.first.bookingDetailId
//                       : null;

//               if (firstDetailId == null) return;
//               if (_navigated) return;
//               _navigated = true;

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => FindingYourTaskerScreen(
//                     bookingid: firstDetailId.toString(),
//                     id: firstDetailId.toString(),
//                   ),
//                 ),
//               );
//             }

//             if (state.createStatus == UserBookingCreateStatus.failure) {
//               _navigated = false;
//               final msg = state.createError ?? "Booking failed";
//               ScaffoldMessenger.of(context)
//                   .showSnackBar(SnackBar(content: Text(msg)));
//             }
//           },
//           builder: (context, state) {
//             final isLoading =
//                 state.createStatus == UserBookingCreateStatus.submitting;

//             return SafeArea(
//               top: false,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _HeroHeader(t: t, title: widget.group.name),
//                     const SizedBox(height: 14),

//                     _Glass(
//                       radius: 22,
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _SectionTitleModern(
//                               t: t,
//                               icon: Icons.list_alt_rounded,
//                               title: "Service details",
//                               subtitle: "Pick service & schedule in minutes",
//                             ),
//                             const SizedBox(height: 14),

//                             _FieldModern(
//                               t: t,
//                               label: "Subcategory",
//                               prefixIcon: Icons.category_rounded,
//                               child: DropdownButtonHideUnderline(
//                                 child: DropdownButton<ServiceOption>(
//                                   isExpanded: true,
//                                   value: _selectedSubcategory,
//                                   icon: Icon(Icons.expand_more_rounded,
//                                       color: t.primaryDark),
//                                   hint: Text(
//                                     "Select subcategory",
//                                     style: TextStyle(
//                                       fontFamily: 'Poppins',
//                                       color: t.mutedText.withOpacity(.9),
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                   items: subs.map((s) {
//                                     return DropdownMenuItem<ServiceOption>(
//                                       value: s,
//                                       child: Text(
//                                         s.name,
//                                         style: TextStyle(
//                                           fontFamily: 'Poppins',
//                                           color: t.primaryText,
//                                           fontWeight: FontWeight.w800,
//                                         ),
//                                       ),
//                                     );
//                                   }).toList(),
//                                   onChanged: (val) =>
//                                       setState(() => _selectedSubcategory = val),
//                                 ),
//                               ),
//                               errorText:
//                                   (_showErrors && _selectedSubcategory == null)
//                                       ? "Please select a subcategory"
//                                       : null,
//                             ),

//                             const SizedBox(height: 16),

//                             _SectionTitleModern(
//                               t: t,
//                               icon: Icons.category_rounded,
//                               title: "Booking type",
//                               subtitle: "ASAP, future, recurring or multi-day",
//                             ),
//                             const SizedBox(height: 12),

//                             _TypeGrid(
//                               t: t,
//                               bookingTypeId: _bookingTypeId,
//                               recurrencePatternId: _recurrencePatternId,
//                               onPick: (typeId, pattId) {
//                                 _setBookingType(typeId);
//                                 if (pattId != null) _setRecurrencePattern(pattId);
//                               },
//                             ),

//                             if (_bookingTypeId == BookingTypeIds.recurrence &&
//                                 _recurrencePatternId ==
//                                     RecurrencePatternIds.customDays) ...[
//                               const SizedBox(height: 12),
//                               Text(
//                                 "Select days",
//                                 style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: t.primaryText,
//                                   fontWeight: FontWeight.w900,
//                                   fontSize: 12.8,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Wrap(
//                                 spacing: 8,
//                                 runSpacing: 8,
//                                 children: [
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Mon",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.monday),
//                                       onTap: () => _toggleDay(DateTime.monday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Tue",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.tuesday),
//                                       onTap: () => _toggleDay(DateTime.tuesday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Wed",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.wednesday),
//                                       onTap: () =>
//                                           _toggleDay(DateTime.wednesday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Thu",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.thursday),
//                                       onTap: () =>
//                                           _toggleDay(DateTime.thursday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Fri",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.friday),
//                                       onTap: () => _toggleDay(DateTime.friday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Sat",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.saturday),
//                                       onTap: () =>
//                                           _toggleDay(DateTime.saturday)),
//                                   _DayChipModern(
//                                       t: t,
//                                       label: "Sun",
//                                       selected: _selectedWeekdays
//                                           .contains(DateTime.sunday),
//                                       onTap: () => _toggleDay(DateTime.sunday)),
//                                 ],
//                               ),
//                               if (_showErrors && _selectedWeekdays.isEmpty)
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 8),
//                                   child: Text(
//                                     "Please select at least one day",
//                                     style: TextStyle(
//                                       fontFamily: 'Poppins',
//                                       color: Colors.red.withOpacity(.9),
//                                       fontWeight: FontWeight.w800,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                             ],

//                             const SizedBox(height: 16),

//                             _SectionTitleModern(
//                               t: t,
//                               icon: Icons.calendar_month_rounded,
//                               title: "Schedule",
//                               subtitle: "Pick date & time window",
//                             ),
//                             const SizedBox(height: 12),

//                             _FieldModern(
//                               t: t,
//                               label: _isRecurrenceOrMultiDays()
//                                   ? "Start date"
//                                   : "Booking date",
//                               prefixIcon: Icons.event_rounded,
//                               onTap: _bookingTypeId == BookingTypeIds.asap
//                                   ? null
//                                   : _pickStartDate,
//                               trailing: Icon(
//                                 _bookingTypeId == BookingTypeIds.asap
//                                     ? Icons.lock_rounded
//                                     : Icons.chevron_right_rounded,
//                                 color: t.primaryDark,
//                               ),
//                               child: Text(
//                                 _bookingTypeId == BookingTypeIds.asap
//                                     ? _fmtDate(DateTime.now())
//                                     : _fmtDate(_selectedDate),
//                                 style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: (_selectedDate == null)
//                                       ? t.mutedText
//                                       : t.primaryText,
//                                   fontWeight: FontWeight.w900,
//                                 ),
//                               ),
//                               errorText: (_showErrors && _selectedDate == null)
//                                   ? "Please select a date"
//                                   : null,
//                             ),

//                             if (_isRecurrenceOrMultiDays()) ...[
//                               const SizedBox(height: 12),
//                               _FieldModern(
//                                 t: t,
//                                 label: "End date",
//                                 prefixIcon: Icons.date_range_rounded,
//                                 onTap: _pickEndDate,
//                                 trailing: Icon(Icons.chevron_right_rounded,
//                                     color: t.primaryDark),
//                                 child: Text(
//                                   _fmtDate(_endDate),
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: _endDate == null
//                                         ? t.mutedText
//                                         : t.primaryText,
//                                     fontWeight: FontWeight.w900,
//                                   ),
//                                 ),
//                                 errorText: (_showErrors && _endDate == null)
//                                     ? "Please select end date"
//                                     : null,
//                               ),
//                             ],

//                             const SizedBox(height: 14),

//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _TimePill(
//                                     t: t,
//                                     label: "Start time",
//                                     value: _fmtTimeUi(_startTime),
//                                     onTap: _pickStartTime,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: _TimePill(
//                                     t: t,
//                                     label: "End time",
//                                     value: _fmtTimeUi(_endTime),
//                                     onTap: _pickEndTime,
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             if (_showErrors &&
//                                 (_startTime == null || _endTime == null))
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 8),
//                                 child: Text(
//                                   "Please select both start & end time",
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: Colors.red.withOpacity(.9),
//                                     fontWeight: FontWeight.w800,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),

//                             // ✅ UPDATED: error uses 30-min rule
//                             if (_showErrors &&
//                                 _startTime != null &&
//                                 _endTime != null &&
//                                 !_isEndValid(_startTime!, _endTime!))
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 8),
//                                 child: Text(
//                                   "End time must be at least 30 minutes after start time",
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: Colors.red.withOpacity(.9),
//                                     fontWeight: FontWeight.w800,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),

//                             const SizedBox(height: 16),

//                             _SectionTitleModern(
//                               t: t,
//                               icon: Icons.place_rounded,
//                               title: "Location",
//                               subtitle: "Search address with Google Places",
//                             ),
//                             const SizedBox(height: 12),

//                             _buildLocationField(t),

//                             const SizedBox(height: 16),

//                             _SectionTitleModern(
//                               t: t,
//                               icon: Icons.workspace_premium_rounded,
//                               title: "Tasker level",
//                               subtitle: "Choose standard or pro",
//                             ),
//                             const SizedBox(height: 12),

//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _LevelCardModern(
//                                     t: t,
//                                     title: "Tasker",
//                                     subtitle: "Standard",
//                                     selected: _selectedTaskerLevelId == 1,
//                                     onTap: () => _pickTaskerLevel(1),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: _LevelCardModern(
//                                     t: t,
//                                     title: "Pro tasker",
//                                     subtitle: "Premium",
//                                     selected: _selectedTaskerLevelId == 2,
//                                     onTap: () => _pickTaskerLevel(2),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             if (_showErrors && _selectedTaskerLevelId == null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 8),
//                                 child: Text(
//                                   "Please select tasker level",
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: Colors.red.withOpacity(.9),
//                                     fontWeight: FontWeight.w800,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 54,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           elevation: 0,
//                           backgroundColor: t.primary,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         onPressed: isLoading ? null : _onSubmit,
//                         child: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 180),
//                           child: isLoading
//                               ? const SizedBox(
//                                   key: ValueKey("loading"),
//                                   height: 22,
//                                   width: 22,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.6,
//                                     valueColor:
//                                         AlwaysStoppedAnimation<Color>(Colors.white),
//                                   ),
//                                 )
//                               : const Row(
//                                   key: ValueKey("normal"),
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(Icons.search_rounded, size: 20),
//                                     SizedBox(width: 10),
//                                     Text(
//                                       "FIND TASKER",
//                                       style: TextStyle(
//                                         fontFamily: 'Poppins',
//                                         fontWeight: FontWeight.w900,
//                                         letterSpacing: .2,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(_UiTokens t) {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(80),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//           child: Row(
//             children: [
//               _Glass(
//                 radius: 16,
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(16),
//                   onTap: () => Navigator.pop(context),
//                   child: const SizedBox(
//                     width: 46,
//                     height: 46,
//                     child: Icon(Icons.chevron_left_rounded),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   "Service booking",
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w900,
//                     fontSize: 16,
//                     color: t.primaryText,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationField(_UiTokens t) {
//     final hasPinned = _pickedLat != null && _pickedLng != null;

//     return _FieldModern(
//       t: t,
//       label: "Location",
//       prefixIcon: Icons.place_rounded,
//       helperText: hasPinned ? "Pinned" : "Search",
//       errorText: (_showErrors && _manualLocationCtrl.text.trim().isEmpty)
//           ? "Please enter location"
//           : null,
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (hasPinned)
//             Icon(Icons.verified_rounded, size: 20, color: t.primaryDark),
//           if (_manualLocationCtrl.text.trim().isNotEmpty) ...[
//             const SizedBox(width: 6),
//             InkWell(
//               borderRadius: BorderRadius.circular(999),
//               onTap: () {
//                 setState(() {
//                   _manualLocationCtrl.clear();
//                   _pickedLat = null;
//                   _pickedLng = null;
//                   _pickedPlaceId = null;
//                   _locPredictions = [];
//                   _lastCommittedAddress = "";
//                 });
//                 _removeLocOverlay();
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(6),
//                 child: Icon(Icons.close_rounded, size: 18, color: t.mutedText),
//               ),
//             ),
//           ],
//         ],
//       ),
//       child: CompositedTransformTarget(
//         link: _locLink,
//         child: SizedBox(
//           height: 44,
//           child: TextField(
//             controller: _manualLocationCtrl,
//             focusNode: _locFocus,
//             keyboardType: TextInputType.streetAddress,
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               color: t.primaryText,
//               fontSize: 13.5,
//               fontWeight: FontWeight.w900,
//             ),
//             decoration: InputDecoration(
//               border: InputBorder.none,
//               enabledBorder: InputBorder.none,
//               focusedBorder: InputBorder.none,
//               isDense: true,
//               isCollapsed: true,
//               contentPadding: const EdgeInsets.only(top: 12.5),
//               hintText: "Enter your address / house / suburb",
//               hintStyle: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: t.mutedText.withOpacity(.85),
//                 fontWeight: FontWeight.w700,
//                 fontSize: 13,
//               ),
//             ),
//             onTap: () {
//               if (_locPredictions.isNotEmpty) _showLocOverlay();
//             },
//             onChanged: (v) {
//               _placesDebounce?.cancel();
//               _placesDebounce = Timer(const Duration(milliseconds: 450), () {
//                 if (!mounted) return;
//                 _searchPlaces(v);
//               });
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ============================== TOKENS + GLASS ============================== */

// class _UiTokens {
//   final Color primary;
//   final Color primaryDark;
//   final Color primaryText;
//   final Color mutedText;
//   final Color bg;

//   const _UiTokens({
//     required this.primary,
//     required this.primaryDark,
//     required this.primaryText,
//     required this.mutedText,
//     required this.bg,
//   });

//   static _UiTokens of(BuildContext context) => const _UiTokens(
//         primary: Color(0xFF7841BA),
//         primaryDark: Color(0xFF5C2E91),
//         primaryText: Color(0xFF3E1E69),
//         mutedText: Color(0xFF75748A),
//         bg: Color(0xFFF8F7FB),
//       );
// }

// class _Glass extends StatelessWidget {
//   const _Glass({required this.child, this.radius = 18});
//   final Widget child;
//   final double radius;

//   @override
//   Widget build(BuildContext context) {
//     final t = _UiTokens.of(context);

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(radius),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(radius),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(.92),
//                 Colors.white.withOpacity(.78),
//               ],
//             ),
//             border: Border.all(color: t.primary.withOpacity(.10)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.05),
//                 blurRadius: 18,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// /* ============================== MODERN HEADER ============================== */

// class _HeroHeader extends StatelessWidget {
//   const _HeroHeader({required this.t, required this.title});
//   final _UiTokens t;
//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             t.primary.withOpacity(.14),
//             t.primary.withOpacity(.06),
//             Colors.white,
//           ],
//         ),
//         border: Border.all(color: t.primary.withOpacity(.14)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.05),
//             blurRadius: 22,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 46,
//             width: 46,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(18),
//               color: t.primary.withOpacity(.10),
//               border: Border.all(color: t.primary.withOpacity(.14)),
//             ),
//             child: Icon(Icons.task_alt_rounded, color: t.primaryDark),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Book service",
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.mutedText,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 12.5,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.primaryText,
//                     fontWeight: FontWeight.w900,
//                     fontSize: 15.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ============================== SECTION TITLE ============================== */

// class _SectionTitleModern extends StatelessWidget {
//   const _SectionTitleModern({
//     required this.t,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//   });

//   final _UiTokens t;
//   final IconData icon;
//   final String title;
//   final String subtitle;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 42,
//           height: 42,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: t.primary.withOpacity(.10),
//             border: Border.all(color: t.primary.withOpacity(.14)),
//           ),
//           child: Icon(icon, color: t.primaryDark, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: t.primaryText,
//                   fontWeight: FontWeight.w900,
//                   fontSize: 14,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: t.mutedText,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 12.3,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// /* ============================== FIELD MODERN ============================== */

// class _FieldModern extends StatelessWidget {
//   const _FieldModern({
//     required this.t,
//     required this.label,
//     required this.child,
//     this.prefixIcon,
//     this.helperText,
//     this.errorText,
//     this.trailing,
//     this.onTap,
//   });

//   final _UiTokens t;
//   final String label;
//   final Widget child;

//   final IconData? prefixIcon;
//   final String? helperText;
//   final String? errorText;
//   final Widget? trailing;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     final hasError = errorText != null && errorText!.trim().isNotEmpty;

//     final field = _Glass(
//       radius: 18,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(
//             color: hasError
//                 ? Colors.red.withOpacity(.35)
//                 : t.primary.withOpacity(.14),
//             width: 1.2,
//           ),
//         ),
//         padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
//         child: Row(
//           children: [
//             if (prefixIcon != null) ...[
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14),
//                   color: t.primary.withOpacity(.10),
//                   border: Border.all(color: t.primary.withOpacity(.12)),
//                 ),
//                 child: Icon(prefixIcon, color: t.primaryDark, size: 20),
//               ),
//               const SizedBox(width: 10),
//             ],
//             Expanded(child: child),
//             if (trailing != null) ...[
//               const SizedBox(width: 10),
//               trailing!,
//             ],
//           ],
//         ),
//       ),
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             if (helperText != null && !hasError)
//               Text(
//                 helperText!,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: t.mutedText,
//                   fontSize: 11.5,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         onTap == null
//             ? field
//             : InkWell(
//                 borderRadius: BorderRadius.circular(18),
//                 onTap: onTap,
//                 child: field,
//               ),
//         if (hasError) ...[
//           const SizedBox(height: 6),
//           Text(
//             errorText!,
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               color: Colors.red.withOpacity(.9),
//               fontSize: 12,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ]
//       ],
//     );
//   }
// }

// /* ============================== TYPE GRID ============================== */

// class _TypeGrid extends StatelessWidget {
//   const _TypeGrid({
//     required this.t,
//     required this.bookingTypeId,
//     required this.recurrencePatternId,
//     required this.onPick,
//   });

//   final _UiTokens t;
//   final int bookingTypeId;
//   final int recurrencePatternId;
//   final void Function(int typeId, int? recurrencePatternId) onPick;

//   bool _sel(int typeId, {int? patt}) {
//     if (typeId == BookingTypeIds.recurrence) {
//       return bookingTypeId == BookingTypeIds.recurrence &&
//           recurrencePatternId == (patt ?? recurrencePatternId);
//     }
//     return bookingTypeId == typeId;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "ASAP",
//                 subtitle: "Today",
//                 selected: _sel(BookingTypeIds.asap),
//                 onTap: () => onPick(BookingTypeIds.asap, null),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Future",
//                 subtitle: "Schedule",
//                 selected: _sel(BookingTypeIds.future),
//                 onTap: () => onPick(BookingTypeIds.future, null),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Multi days",
//                 subtitle: "Range",
//                 selected: _sel(BookingTypeIds.multiDays),
//                 onTap: () => onPick(BookingTypeIds.multiDays, null),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Daily",
//                 subtitle: "Recurrence",
//                 selected: _sel(BookingTypeIds.recurrence,
//                     patt: RecurrencePatternIds.daily),
//                 onTap: () => onPick(
//                     BookingTypeIds.recurrence, RecurrencePatternIds.daily),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Weekly",
//                 subtitle: "Recurrence",
//                 selected: _sel(BookingTypeIds.recurrence,
//                     patt: RecurrencePatternIds.weekly),
//                 onTap: () => onPick(
//                     BookingTypeIds.recurrence, RecurrencePatternIds.weekly),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Monthly",
//                 subtitle: "Recurrence",
//                 selected: _sel(BookingTypeIds.recurrence,
//                     patt: RecurrencePatternIds.monthly),
//                 onTap: () => onPick(
//                     BookingTypeIds.recurrence, RecurrencePatternIds.monthly),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _TypeCard(
//                 t: t,
//                 title: "Custom days",
//                 subtitle: "Pick days",
//                 selected: _sel(BookingTypeIds.recurrence,
//                     patt: RecurrencePatternIds.customDays),
//                 onTap: () => onPick(BookingTypeIds.recurrence,
//                     RecurrencePatternIds.customDays),
//               ),
//             ),
//             const SizedBox(width: 10),
//             const Expanded(child: SizedBox()),
//             const SizedBox(width: 10),
//             const Expanded(child: SizedBox()),
//           ],
//         ),
//       ],
//     );
//   }
// }

// class _TypeCard extends StatelessWidget {
//   const _TypeCard({
//     required this.t,
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? t.primary.withOpacity(.10) : Colors.white;
//     final border =
//         selected ? t.primary.withOpacity(.35) : t.primary.withOpacity(.14);

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: bg,
//           border: Border.all(color: border, width: selected ? 1.8 : 1.2),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.03),
//               blurRadius: 14,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Icon(
//               selected ? Icons.check_circle_rounded : Icons.circle_outlined,
//               size: 18,
//               color: selected ? t.primaryDark : t.primaryDark.withOpacity(.55),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: t.primaryText,
//                       fontWeight: FontWeight.w900,
//                       fontSize: 12.8,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: t.mutedText,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 11.6,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== DAY CHIP ============================== */

// class _DayChipModern extends StatelessWidget {
//   const _DayChipModern({
//     required this.t,
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? t.primary.withOpacity(.14) : Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//             color: selected ? t.primary : Colors.black.withOpacity(.10),
//             width: 1.2,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w900,
//             color: selected ? t.primaryDark : t.primaryText,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ============================== TIME PILL ============================== */

// class _TimePill extends StatelessWidget {
//   const _TimePill({
//     required this.t,
//     required this.label,
//     required this.value,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String label;
//   final String value;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final empty = value == 'Pick time' || value.isEmpty;

//     return InkWell(
//       borderRadius: BorderRadius.circular(18),
//       onTap: onTap,
//       child: _Glass(
//         radius: 18,
//         child: Container(
//           height: 52,
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: t.primary.withOpacity(.12)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14),
//                   color: t.primary.withOpacity(.10),
//                   border: Border.all(color: t.primary.withOpacity(.12)),
//                 ),
//                 child: Icon(Icons.access_time_rounded,
//                     size: 18, color: t.primaryDark),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   empty ? label : value,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: empty ? t.mutedText : t.primaryText,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ),
//               Icon(Icons.chevron_right_rounded, color: t.primaryDark),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ============================== LEVEL CARD ============================== */

// class _LevelCardModern extends StatelessWidget {
//   const _LevelCardModern({
//     required this.t,
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? t.primary.withOpacity(.10) : Colors.white;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: bg,
//           border: Border.all(
//             color: selected ? t.primary.withOpacity(.40) : t.primary.withOpacity(.14),
//             width: selected ? 1.8 : 1.2,
//           ),
//           boxShadow: selected
//               ? [
//                   BoxShadow(
//                     color: t.primary.withOpacity(.18),
//                     blurRadius: 18,
//                     offset: const Offset(0, 12),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(.03),
//                     blurRadius: 14,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: t.primaryText,
//                       fontWeight: FontWeight.w900,
//                       fontSize: 13.2,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: t.mutedText,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 180),
//               child: selected
//                   ? Icon(CupertinoIcons.check_mark_circled_solid,
//                       key: const ValueKey("sel"),
//                       size: 22,
//                       color: t.primaryDark)
//                   : const SizedBox(
//                       key: ValueKey("nosel"),
//                       width: 22,
//                       height: 22,
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


/*
class BookingTypeIds {
  static const int asap = 1;
  static const int future = 2;
  static const int recurrence = 3;
  static const int multiDays = 4;
}

class RecurrencePatternIds {
  static const int daily = 1;
  static const int monthly = 2;
  static const int weekly = 3;
  static const int customDays = 4;
}

/* ============================== SCREEN ============================== */

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  final ServiceOption? initialService;

  /// API expects SubCategoryId
  final int serviceId;

  const ServiceBookingFormScreen({
    super.key,
    required this.group,
    this.initialService,
    required this.serviceId,
  });

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  // ✅ Put your key here
  static const String _googlePlacesKey = "AIzaSyBFIEDQXjgT6djAIrXB466aR1oG5EmXojQ";

  // selections
  ServiceOption? _selectedSubcategory;
  int? _selectedTaskerLevelId;

  // booking mode
  int _bookingTypeId = BookingTypeIds.asap;

  // recurrence
  int _recurrencePatternId = RecurrencePatternIds.daily;
  final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

  // dates/times
  DateTime? _selectedDate; // start date
  DateTime? _endDate; // recurrence/multi-days
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // form
  final _manualLocationCtrl = TextEditingController();
  bool _showErrors = false;

  // navigation guard
  bool _navigated = false;

  /* ===================== PLACES (CUSTOM UI) ===================== */

  late final GooglePlace _googlePlace;
  Timer? _placesDebounce;

  final FocusNode _locFocus = FocusNode();
  final LayerLink _locLink = LayerLink();

  OverlayEntry? _locOverlay;
  List<AutocompletePrediction> _locPredictions = [];
  bool _locLoading = false;

  double? _pickedLat;
  double? _pickedLng;
  String? _pickedPlaceId;
  String _lastCommittedAddress = "";

  @override
  void initState() {
    super.initState();

    _selectedSubcategory = widget.initialService;
    _selectedSubcategory ??= widget.group.services.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.group.services.isNotEmpty
          ? widget.group.services.first
          : ServiceOption(id: widget.serviceId, name: ''),
    );

    _selectedDate = DateTime.now();

    _googlePlace = GooglePlace(_googlePlacesKey);

    _locFocus.addListener(() {
      if (!_locFocus.hasFocus) {
        _removeLocOverlay();
      } else {
        if (_locPredictions.isNotEmpty) _showLocOverlay();
      }
    });
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    _removeLocOverlay();
    _locFocus.dispose();
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  /* ============================== DATE/TIME ============================== */

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: initial.isBefore(now) ? now : initial,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_isRecurrenceOrMultiDays() &&
            _endDate != null &&
            _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime(now.year + 2),
      initialDate: _endDate ?? start,
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTimeUi(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $suffix';
  }

  bool _isRecurrenceOrMultiDays() =>
      _bookingTypeId == BookingTypeIds.recurrence ||
      _bookingTypeId == BookingTypeIds.multiDays;

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /* ============================== BOOKING TYPE ============================== */

  void _pickTaskerLevel(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTaskerLevelId = id;
      if (_showErrors) _showErrors = false;
    });
  }

  void _setBookingType(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _bookingTypeId = id;

      if (_bookingTypeId == BookingTypeIds.asap) {
        _selectedDate = DateTime.now();
        _endDate = null;
      } else {
        _selectedDate ??= DateTime.now();
      }

      if (_bookingTypeId != BookingTypeIds.recurrence) {
        _recurrencePatternId = RecurrencePatternIds.daily;
        _selectedWeekdays.clear();
      }

      if (_bookingTypeId == BookingTypeIds.multiDays) {
        _endDate ??= _selectedDate;
      } else if (_bookingTypeId == BookingTypeIds.future ||
          _bookingTypeId == BookingTypeIds.asap) {
        _endDate = null;
      }
    });
  }

  void _setRecurrencePattern(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _recurrencePatternId = id;
      if (id != RecurrencePatternIds.customDays) {
        _selectedWeekdays.clear();
      }
    });
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        _selectedWeekdays.remove(weekday);
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  /* ============================== HELPERS ============================== */

  int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

  double _resolveLat() => _pickedLat ?? 0.0;
  double _resolveLng() => _pickedLng ?? 0.0;

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "Monday";
    }
  }

  String _buildCustomDaysString() {
    final list = _selectedWeekdays.toList()..sort();
    return list.map(_weekdayName).join(',');
  }

  bool _validate() {
    final hasBase = _selectedSubcategory != null &&
        _startTime != null &&
        _endTime != null &&
        _manualLocationCtrl.text.trim().isNotEmpty &&
        _selectedTaskerLevelId != null &&
        _selectedDate != null;

    if (!hasBase) return false;

    final startDT = _combine(_selectedDate!, _startTime!);
    final endDT = _combine(_selectedDate!, _endTime!);
    if (!endDT.isAfter(startDT)) return false;

    if (_bookingTypeId == BookingTypeIds.recurrence) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;
      if (_recurrencePatternId == RecurrencePatternIds.customDays &&
          _selectedWeekdays.isEmpty) return false;
    }

    if (_bookingTypeId == BookingTypeIds.multiDays) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;
    }

    return true;
  }

  void _onSubmit() {
    setState(() => _showErrors = true);
    if (!_validate()) return;

    _navigated = false;

    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.userDetails?.userId.toString();
    if (userId == null || userId.isEmpty) return;

    final startDate = _selectedDate!;
    final startDateTime = _combine(startDate, _startTime!);
    final endDateTime = _combine(startDate, _endTime!);

    final serviceIdForApi = _resolveServiceIdForApi();

    int bookingTypeId = _bookingTypeId;
    int? recurrencePatternId;
    String? customDays;
    DateTime? endDateForApi;

    if (_bookingTypeId == BookingTypeIds.asap ||
        _bookingTypeId == BookingTypeIds.future) {
      endDateForApi = null;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.multiDays) {
      endDateForApi = _endDate;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.recurrence) {
      endDateForApi = _endDate;
      recurrencePatternId = _recurrencePatternId;
      if (_recurrencePatternId == RecurrencePatternIds.customDays) {
        customDays = _buildCustomDaysString();
      }
    }

    context.read<UserBookingBloc>().add(
          CreateUserBookingRequested(
            userId: userId,
            subCategoryId: serviceIdForApi,
            bookingTypeId: bookingTypeId,
            bookingDate: startDate,
            startTime: startDateTime.toUtc().toIso8601String(),
            endTime: endDateTime.toUtc().toIso8601String(),
            endDate: endDateForApi,
            recurrencePatternId: recurrencePatternId,
            customDays: customDays,
            address: _manualLocationCtrl.text.trim(),
            taskerLevelId: _selectedTaskerLevelId!,
            latitude: _resolveLat(),
            longitude: _resolveLng(),
          ),
        );
  }

  /* ============================== PLACES (CUSTOM SEARCH) ============================== */

  void _removeLocOverlay() {
    _locOverlay?.remove();
    _locOverlay = null;
  }

  void _showLocOverlay() {
    if (_locOverlay != null) return;

    _locOverlay = OverlayEntry(
      builder: (context) {
        final t = _UiTokens.of(context);
        final width = MediaQuery.of(context).size.width - 32; // same page padding

        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              _removeLocOverlay();
            },
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _locLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 58),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: width,
                      constraints: const BoxConstraints(maxHeight: 270),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(.96),
                        border: Border.all(color: t.primary.withOpacity(.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.10),
                            blurRadius: 22,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: _locLoading
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation(t.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Searching...',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: t.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: _locPredictions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.black.withOpacity(.06),
                              ),
                              itemBuilder: (_, i) {
                                final p = _locPredictions[i];
                                final main = p.structuredFormatting?.mainText ??
                                    p.description ??
                                    '';
                                final secondary =
                                    p.structuredFormatting?.secondaryText ?? '';

                                return InkWell(
                                  onTap: () => _selectPrediction(p),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            color: t.primary.withOpacity(.10),
                                            border: Border.all(
                                                color:
                                                    t.primary.withOpacity(.14)),
                                          ),
                                          child: Icon(Icons.place_rounded,
                                              color: t.primaryDark, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                main,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: t.primaryText,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (secondary.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  secondary,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: t.mutedText,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded,
                                            color: t.primaryDark),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_locOverlay!);
  }

  Future<void> _searchPlaces(String input) async {
    final q = input.trim();
    if (q.length < 3) {
      if (!mounted) return;
      setState(() {
        _locPredictions = [];
        _locLoading = false;
      });
      _removeLocOverlay();
      return;
    }

    setState(() => _locLoading = true);
    if (_locFocus.hasFocus) _showLocOverlay();

    try {
      final res = await _googlePlace.autocomplete.get(
        q,
        components: [Component('country', 'au')],
        types: 'geocode',
      );

      final preds = res?.predictions ?? <AutocompletePrediction>[];
      if (!mounted) return;

      setState(() {
        _locPredictions = preds;
        _locLoading = false;
      });

      if (_locPredictions.isEmpty) {
        _removeLocOverlay();
      } else if (_locFocus.hasFocus) {
        _showLocOverlay();
        _locOverlay?.markNeedsBuild();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locPredictions = [];
        _locLoading = false;
      });
      _removeLocOverlay();
    }
  }

  Future<void> _selectPrediction(AutocompletePrediction p) async {
    final desc = p.description ?? '';
    final placeId = p.placeId;

    _manualLocationCtrl.text = desc;
    _manualLocationCtrl.selection =
        TextSelection.fromPosition(TextPosition(offset: desc.length));

    _lastCommittedAddress = desc.trim();
    _pickedPlaceId = placeId;

    _removeLocOverlay();
    FocusScope.of(context).unfocus();

    if (placeId == null) return;

    try {
      final details = await _googlePlace.details.get(placeId);
      final loc = details?.result?.geometry?.location;
      if (!mounted) return;

      setState(() {
        _pickedLat = loc?.lat;
        _pickedLng = loc?.lng;
      });
    } catch (_) {
      // ignore
    }
  }

  /* ============================== UI ============================== */

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);
    final subs = widget.group.services;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(t),
        body: BlocConsumer<UserBookingBloc, UserBookingState>(
          listenWhen: (prev, curr) =>
              prev.createStatus != curr.createStatus ||
              prev.bookingCreateResponse != curr.bookingCreateResponse ||
              prev.createError != curr.createError,
          listener: (context, state) {
            if (state.createStatus == UserBookingCreateStatus.success) {
              final firstDetailId =
                  state.bookingCreateResponse?.result?.isNotEmpty == true
                      ? state.bookingCreateResponse!.result!.first.bookingDetailId
                      : null;

              if (firstDetailId == null) return;
              if (_navigated) return;
              _navigated = true;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FindingYourTaskerScreen(
                    bookingid: firstDetailId.toString(),
                    id: firstDetailId.toString(),
                  ),
                ),
              );
            }

            if (state.createStatus == UserBookingCreateStatus.failure) {
              _navigated = false;
              final msg = state.createError ?? "Booking failed";
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          builder: (context, state) {
            final isLoading =
                state.createStatus == UserBookingCreateStatus.submitting;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroHeader(t: t, title: widget.group.name),
                    const SizedBox(height: 14),

                    _Glass(
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitleModern(
                              t: t,
                              icon: Icons.list_alt_rounded,
                              title: "Service details",
                              subtitle: "Pick service & schedule in minutes",
                            ),
                            const SizedBox(height: 14),

                            _FieldModern(
                              t: t,
                              label: "Subcategory",
                              prefixIcon: Icons.category_rounded,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ServiceOption>(
                                  isExpanded: true,
                                  value: _selectedSubcategory,
                                  icon: Icon(Icons.expand_more_rounded,
                                      color: t.primaryDark),
                                  hint: Text(
                                    "Select subcategory",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: t.mutedText.withOpacity(.9),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  items: subs.map((s) {
                                    return DropdownMenuItem<ServiceOption>(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: t.primaryText,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedSubcategory = val),
                                ),
                              ),
                              errorText:
                                  (_showErrors && _selectedSubcategory == null)
                                      ? "Please select a subcategory"
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.category_rounded,
                              title: "Booking type",
                              subtitle: "ASAP, future, recurring or multi-day",
                            ),
                            const SizedBox(height: 12),

                            _TypeGrid(
                              t: t,
                              bookingTypeId: _bookingTypeId,
                              recurrencePatternId: _recurrencePatternId,
                              onPick: (typeId, pattId) {
                                _setBookingType(typeId);
                                if (pattId != null) _setRecurrencePattern(pattId);
                              },
                            ),

                            if (_bookingTypeId == BookingTypeIds.recurrence &&
                                _recurrencePatternId ==
                                    RecurrencePatternIds.customDays) ...[
                              const SizedBox(height: 12),
                              Text(
                                "Select days",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: t.primaryText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DayChipModern(
                                      t: t,
                                      label: "Mon",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.monday),
                                      onTap: () => _toggleDay(DateTime.monday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Tue",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.tuesday),
                                      onTap: () => _toggleDay(DateTime.tuesday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Wed",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.wednesday),
                                      onTap: () =>
                                          _toggleDay(DateTime.wednesday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Thu",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.thursday),
                                      onTap: () =>
                                          _toggleDay(DateTime.thursday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Fri",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.friday),
                                      onTap: () => _toggleDay(DateTime.friday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Sat",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.saturday),
                                      onTap: () =>
                                          _toggleDay(DateTime.saturday)),
                                  _DayChipModern(
                                      t: t,
                                      label: "Sun",
                                      selected: _selectedWeekdays
                                          .contains(DateTime.sunday),
                                      onTap: () => _toggleDay(DateTime.sunday)),
                                ],
                              ),
                              if (_showErrors && _selectedWeekdays.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "Please select at least one day",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.red.withOpacity(.9),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.calendar_month_rounded,
                              title: "Schedule",
                              subtitle: "Pick date & time window",
                            ),
                            const SizedBox(height: 12),

                            _FieldModern(
                              t: t,
                              label: _isRecurrenceOrMultiDays()
                                  ? "Start date"
                                  : "Booking date",
                              prefixIcon: Icons.event_rounded,
                              onTap: _bookingTypeId == BookingTypeIds.asap
                                  ? null
                                  : _pickStartDate,
                              trailing: Icon(
                                _bookingTypeId == BookingTypeIds.asap
                                    ? Icons.lock_rounded
                                    : Icons.chevron_right_rounded,
                                color: t.primaryDark,
                              ),
                              child: Text(
                                _bookingTypeId == BookingTypeIds.asap
                                    ? _fmtDate(DateTime.now())
                                    : _fmtDate(_selectedDate),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: (_selectedDate == null)
                                      ? t.mutedText
                                      : t.primaryText,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              errorText: (_showErrors && _selectedDate == null)
                                  ? "Please select a date"
                                  : null,
                            ),

                            if (_isRecurrenceOrMultiDays()) ...[
                              const SizedBox(height: 12),
                              _FieldModern(
                                t: t,
                                label: "End date",
                                prefixIcon: Icons.date_range_rounded,
                                onTap: _pickEndDate,
                                trailing: Icon(Icons.chevron_right_rounded,
                                    color: t.primaryDark),
                                child: Text(
                                  _fmtDate(_endDate),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _endDate == null
                                        ? t.mutedText
                                        : t.primaryText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                errorText: (_showErrors && _endDate == null)
                                    ? "Please select end date"
                                    : null,
                              ),
                            ],

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _TimePill(
                                    t: t,
                                    label: "Start time",
                                    value: _fmtTimeUi(_startTime),
                                    onTap: _pickStartTime,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TimePill(
                                    t: t,
                                    label: "End time",
                                    value: _fmtTimeUi(_endTime),
                                    onTap: _pickEndTime,
                                  ),
                                ),
                              ],
                            ),

                            if (_showErrors &&
                                (_startTime == null || _endTime == null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Please select both start & end time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            if (_showErrors &&
                                _startTime != null &&
                                _endTime != null &&
                                !_combine(_selectedDate!, _endTime!).isAfter(
                                    _combine(_selectedDate!, _startTime!)))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "End time must be later than start time",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.place_rounded,
                              title: "Location",
                              subtitle: "Search address with Google Places",
                            ),
                            const SizedBox(height: 12),

                            _buildLocationField(t),

                            const SizedBox(height: 16),

                            _SectionTitleModern(
                              t: t,
                              icon: Icons.workspace_premium_rounded,
                              title: "Tasker level",
                              subtitle: "Choose standard or pro",
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _LevelCardModern(
                                    t: t,
                                    title: "Tasker",
                                    subtitle: "Standard",
                                    selected: _selectedTaskerLevelId == 1,
                                    onTap: () => _pickTaskerLevel(1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _LevelCardModern(
                                    t: t,
                                    title: "Pro tasker",
                                    subtitle: "Premium",
                                    selected: _selectedTaskerLevelId == 2,
                                    onTap: () => _pickTaskerLevel(2),
                                  ),
                                ),
                              ],
                            ),

                            if (_showErrors && _selectedTaskerLevelId == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Please select tasker level",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red.withOpacity(.9),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: t.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isLoading ? null : _onSubmit,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isLoading
                              ? const SizedBox(
                                  key: ValueKey("loading"),
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              :const Row(
                                  key: const ValueKey("normal"),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.search_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      "FIND TASKER",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_UiTokens t) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _Glass(
                radius: 16,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.chevron_left_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Service booking",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: t.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(_UiTokens t) {
    final hasPinned = _pickedLat != null && _pickedLng != null;

    return _FieldModern(
      t: t,
      label: "Location",
      prefixIcon: Icons.place_rounded,
      helperText: hasPinned ? "Pinned" : "Search",
      errorText: (_showErrors && _manualLocationCtrl.text.trim().isEmpty)
          ? "Please enter location"
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPinned)
            Icon(Icons.verified_rounded, size: 20, color: t.primaryDark),
          if (_manualLocationCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _manualLocationCtrl.clear();
                  _pickedLat = null;
                  _pickedLng = null;
                  _pickedPlaceId = null;
                  _locPredictions = [];
                  _lastCommittedAddress = "";
                });
                _removeLocOverlay();
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child:
                    Icon(Icons.close_rounded, size: 18, color: t.mutedText),
              ),
            ),
          ],
        ],
      ),
      child: CompositedTransformTarget(
        link: _locLink,
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: _manualLocationCtrl,
            focusNode: _locFocus,
            keyboardType: TextInputType.streetAddress,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: t.primaryText,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              isCollapsed: true,
contentPadding: const EdgeInsets.only(top: 12.5),
              hintText: "Enter your address / house / suburb",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                color: t.mutedText.withOpacity(.85),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onTap: () {
              if (_locPredictions.isNotEmpty) _showLocOverlay();
            },
            onChanged: (v) {
              _placesDebounce?.cancel();
              _placesDebounce = Timer(const Duration(milliseconds: 450), () {
                if (!mounted) return;
                _searchPlaces(v);
              });
            },
          ),
        ),
      ),
    );
  }
}

/* ============================== TOKENS + GLASS ============================== */

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color primaryText;
  final Color mutedText;
  final Color bg;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.primaryText,
    required this.mutedText,
    required this.bg,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF7841BA),
        primaryDark: Color(0xFF5C2E91),
        primaryText: Color(0xFF3E1E69),
        mutedText: Color(0xFF75748A),
        bg: Color(0xFFF8F7FB),
      );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
            border: Border.all(color: t.primary.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ============================== MODERN HEADER ============================== */

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.t, required this.title});
  final _UiTokens t;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.primary.withOpacity(.14),
            t.primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: t.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: t.primary.withOpacity(.10),
              border: Border.all(color: t.primary.withOpacity(.14)),
            ),
            child: Icon(Icons.task_alt_rounded, color: t.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Book service",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
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

/* ============================== SECTION TITLE ============================== */

class _SectionTitleModern extends StatelessWidget {
  const _SectionTitleModern({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _UiTokens t;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: t.primary.withOpacity(.10),
            border: Border.all(color: t.primary.withOpacity(.14)),
          ),
          child: Icon(icon, color: t.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================== FIELD MODERN ============================== */

class _FieldModern extends StatelessWidget {
  const _FieldModern({
    required this.t,
    required this.label,
    required this.child,
    this.prefixIcon,
    this.helperText,
    this.errorText,
    this.trailing,
    this.onTap,
  });

  final _UiTokens t;
  final String label;
  final Widget child;

  final IconData? prefixIcon;
  final String? helperText;
  final String? errorText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    final field = _Glass(
      radius: 18,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasError
                ? Colors.red.withOpacity(.35)
                : t.primary.withOpacity(.14),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.primary.withOpacity(.10),
                  border: Border.all(color: t.primary.withOpacity(.12)),
                ),
                child: Icon(prefixIcon, color: t.primaryDark, size: 20),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: child),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Expanded(
            //   child: Text(
            //     label,
            //     style: TextStyle(
            //       fontFamily: 'Poppins',
            //       color: t.primaryText,
            //       fontSize: 12.5,
            //       fontWeight: FontWeight.w900,
            //     ),
            //   ),
            // ),
            if (helperText != null && !hasError)
              Text(
                helperText!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        onTap == null
            ? field
            : InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: field,
              ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.red.withOpacity(.9),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]
      ],
    );
  }
}

/* ============================== TYPE GRID ============================== */

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.t,
    required this.bookingTypeId,
    required this.recurrencePatternId,
    required this.onPick,
  });

  final _UiTokens t;
  final int bookingTypeId;
  final int recurrencePatternId;
  final void Function(int typeId, int? recurrencePatternId) onPick;

  bool _sel(int typeId, {int? patt}) {
    if (typeId == BookingTypeIds.recurrence) {
      return bookingTypeId == BookingTypeIds.recurrence &&
          recurrencePatternId == (patt ?? recurrencePatternId);
    }
    return bookingTypeId == typeId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "ASAP",
                subtitle: "Today",
                selected: _sel(BookingTypeIds.asap),
                onTap: () => onPick(BookingTypeIds.asap, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Future",
                subtitle: "Schedule",
                selected: _sel(BookingTypeIds.future),
                onTap: () => onPick(BookingTypeIds.future, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Multi days",
                subtitle: "Range",
                selected: _sel(BookingTypeIds.multiDays),
                onTap: () => onPick(BookingTypeIds.multiDays, null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Daily",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.daily),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.daily),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Weekly",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.weekly),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.weekly),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Monthly",
                subtitle: "Recurrence",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.monthly),
                onTap: () => onPick(
                    BookingTypeIds.recurrence, RecurrencePatternIds.monthly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                t: t,
                title: "Custom days",
                subtitle: "Pick days",
                selected: _sel(BookingTypeIds.recurrence,
                    patt: RecurrencePatternIds.customDays),
                onTap: () => onPick(BookingTypeIds.recurrence,
                    RecurrencePatternIds.customDays),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? t.primary.withOpacity(.10) : Colors.white;
    final border = selected ? t.primary.withOpacity(.35) : t.primary.withOpacity(.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
          border: Border.all(color: border, width: selected ? 1.8 : 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: selected ? t.primaryDark : t.primaryDark.withOpacity(.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== DAY CHIP ============================== */

class _DayChipModern extends StatelessWidget {
  const _DayChipModern({
    required this.t,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.primary.withOpacity(.14) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? t.primary : Colors.black.withOpacity(.10),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            color: selected ? t.primaryDark : t.primaryText,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/* ============================== TIME PILL ============================== */

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.t,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final _UiTokens t;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value == 'Pick time' || value.isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: _Glass(
        radius: 18,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.primary.withOpacity(.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.primary.withOpacity(.10),
                  border: Border.all(color: t.primary.withOpacity(.12)),
                ),
                child: Icon(Icons.access_time_rounded,
                    size: 18, color: t.primaryDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  empty ? label : value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: empty ? t.mutedText : t.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== LEVEL CARD ============================== */

class _LevelCardModern extends StatelessWidget {
  const _LevelCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? t.primary.withOpacity(.10) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: bg,
          border: Border.all(
            color: selected ? t.primary.withOpacity(.40) : t.primary.withOpacity(.14),
            width: selected ? 1.8 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.primary.withOpacity(.18),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: t.mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? Icon(CupertinoIcons.check_mark_circled_solid,
                      key: const ValueKey("sel"),
                      size: 22,
                      color: t.primaryDark)
                  : const SizedBox(
                      key: ValueKey("nosel"),
                      width: 22,
                      height: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

*/

// class BookingTypeIds {
//   static const int asap = 1;
//   static const int future = 2;

//   /// Recurrence group (backend uses RecurrencePatternId)
//   static const int recurrence = 3;

//   /// Multi days (range)
//   static const int multiDays = 4;
// }

// class RecurrencePatternIds {
//   static const int daily = 1;
//   static const int monthly = 2;
//   static const int weekly = 3;
//   static const int customDays = 4;
// }

// // ---------------- Screen ----------------

// class ServiceBookingFormScreen extends StatefulWidget {
//   final CertificationGroup group;
//   final ServiceOption? initialService;

//   /// API expects as SubCategoryId
//   final int serviceId;

//   const ServiceBookingFormScreen({
//     super.key,
//     required this.group,
//     this.initialService,
//     required this.serviceId,
//   });

//   @override
//   State<ServiceBookingFormScreen> createState() =>
//       _ServiceBookingFormScreenState();
// }

// class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
//   static const Color kPurple = Color(0xFF5C2E91);
//   static const Color kPage = Color(0xFFF5F6FA);
//   static const Color kText = Color(0xFF111827);
//   static const Color kMuted = Color(0xFF6B7280);

//   // ✅ Put your Places API Key here (better: load from dotenv / --dart-define)
//   static const String _googlePlacesKey = "AIzaSyBFIEDQXjgT6djAIrXB466aR1oG5EmXojQ";

//   ServiceOption? _selectedSubcategory;
//   int? _selectedTaskerLevelId;

//   // booking mode
//   int _bookingTypeId = BookingTypeIds.asap;

//   // recurrence pattern (only used when _bookingTypeId == recurrence)
//   int _recurrencePatternId = RecurrencePatternIds.daily;

//   // custom days
//   final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

//   // dates/times
//   DateTime? _selectedDate; // start date
//   DateTime? _endDate; // recurrence/multi-days
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;

//   final _manualLocationCtrl = TextEditingController();

//   // ✅ Places selection (lat/lng)
//   double? _pickedLat;
//   double? _pickedLng;
//   String? _pickedPlaceId;

//   bool _showErrors = false;

//   // ✅ navigation guard (prevents multiple pushes)
//   bool _navigated = false;

//   // ✅ If user edits address after selecting a suggestion, we clear coords
//   String _lastCommittedAddress = "";

//   @override
//   void initState() {
//     super.initState();

//     _selectedSubcategory = widget.initialService;

//     _selectedSubcategory ??= widget.group.services.firstWhere(
//       (s) => s.id == widget.serviceId,
//       orElse: () => widget.group.services.isNotEmpty
//           ? widget.group.services.first
//           : ServiceOption(id: widget.serviceId, name: ''),
//     );

//     _selectedDate = DateTime.now();

//     _manualLocationCtrl.addListener(() {
//       final current = _manualLocationCtrl.text.trim();
//       // if user changes the address after a selection, reset lat/lng
//       if (_lastCommittedAddress.isNotEmpty && current != _lastCommittedAddress) {
//         _pickedLat = null;
//         _pickedLng = null;
//         _pickedPlaceId = null;
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _manualLocationCtrl.dispose();
//     super.dispose();
//   }

//   // -------------------- date/time pickers --------------------

//   Future<void> _pickStartDate() async {
//     final now = DateTime.now();
//     final initial = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: now,
//       lastDate: DateTime(now.year + 2),
//       initialDate: initial.isBefore(now) ? now : initial,
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;

//         if (_isRecurrenceOrMultiDays() &&
//             _endDate != null &&
//             _endDate!.isBefore(picked)) {
//           _endDate = null;
//         }
//       });
//     }
//   }

//   Future<void> _pickEndDate() async {
//     final now = DateTime.now();
//     final start = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: start,
//       lastDate: DateTime(now.year + 2),
//       initialDate: _endDate ?? start,
//     );
//     if (picked != null) setState(() => _endDate = picked);
//   }

//   Future<void> _pickStartTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) setState(() => _startTime = picked);
//   }

//   Future<void> _pickEndTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) setState(() => _endTime = picked);
//   }

//   String _fmtDate(DateTime? d) =>
//       d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

//   String _fmtTimeUi(TimeOfDay? t) {
//     if (t == null) return 'Pick time';
//     final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
//     final minute = t.minute.toString().padLeft(2, '0');
//     final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
//     return '$hour12:$minute $suffix';
//   }

//   bool _isRecurrenceOrMultiDays() =>
//       _bookingTypeId == BookingTypeIds.recurrence ||
//       _bookingTypeId == BookingTypeIds.multiDays;

//   void _pickTaskerLevel(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _selectedTaskerLevelId = id;
//       if (_showErrors) _showErrors = false;
//     });
//   }

//   // booking type selection
//   void _setBookingType(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _bookingTypeId = id;

//       // defaults
//       if (_bookingTypeId == BookingTypeIds.asap) {
//         _selectedDate = DateTime.now();
//         _endDate = null;
//       } else {
//         _selectedDate ??= DateTime.now();
//       }

//       // reset recurrence config unless recurrence selected
//       if (_bookingTypeId != BookingTypeIds.recurrence) {
//         _recurrencePatternId = RecurrencePatternIds.daily;
//         _selectedWeekdays.clear();
//       }

//       // multi-days needs endDate
//       if (_bookingTypeId == BookingTypeIds.multiDays) {
//         _endDate ??= _selectedDate;
//       } else if (_bookingTypeId == BookingTypeIds.future ||
//           _bookingTypeId == BookingTypeIds.asap) {
//         _endDate = null;
//       }
//     });
//   }

//   void _setRecurrencePattern(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _recurrencePatternId = id;
//       if (id != RecurrencePatternIds.customDays) {
//         _selectedWeekdays.clear();
//       }
//     });
//   }

//   int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

//   // ✅ real coords from Places (fallback to 0.0)
//   double _resolveLat() => _pickedLat ?? 0.0;
//   double _resolveLng() => _pickedLng ?? 0.0;

//   double? _asDouble(dynamic v) {
//     if (v == null) return null;
//     if (v is double) return v;
//     if (v is int) return v.toDouble();
//     return double.tryParse(v.toString());
//   }

//   String _weekdayName(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return "Monday";
//       case DateTime.tuesday:
//         return "Tuesday";
//       case DateTime.wednesday:
//         return "Wednesday";
//       case DateTime.thursday:
//         return "Thursday";
//       case DateTime.friday:
//         return "Friday";
//       case DateTime.saturday:
//         return "Saturday";
//       case DateTime.sunday:
//         return "Sunday";
//       default:
//         return "Monday";
//     }
//   }

//   String _buildCustomDaysString() {
//     final list = _selectedWeekdays.toList()..sort();
//     return list.map(_weekdayName).join(',');
//   }

//   DateTime _combine(DateTime date, TimeOfDay time) {
//     return DateTime(date.year, date.month, date.day, time.hour, time.minute);
//   }

//   bool _validate() {
//     final hasBase = _selectedSubcategory != null &&
//         _startTime != null &&
//         _endTime != null &&
//         _manualLocationCtrl.text.trim().isNotEmpty &&
//         _selectedTaskerLevelId != null &&
//         _selectedDate != null;

//     if (!hasBase) return false;

//     // ✅ Optional: if you want to force user to pick from Places suggestion
//     // (uncomment this to require lat/lng)
//     // if (_pickedLat == null || _pickedLng == null) return false;

//     // validate start < end (same day)
//     final startDT = _combine(_selectedDate!, _startTime!);
//     final endDT = _combine(_selectedDate!, _endTime!);
//     if (!endDT.isAfter(startDT)) return false;

//     // recurrence requires endDate + valid
//     if (_bookingTypeId == BookingTypeIds.recurrence) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;

//       if (_recurrencePatternId == RecurrencePatternIds.customDays) {
//         if (_selectedWeekdays.isEmpty) return false;
//       }
//     }

//     // multi-days requires endDate + valid
//     if (_bookingTypeId == BookingTypeIds.multiDays) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;
//     }

//     return true;
//   }

//   void _onSubmit() {
//     setState(() => _showErrors = true);
//     if (!_validate()) return;

//     // ✅ reset navigation guard for this submit
//     _navigated = false;

//     // ✅ IMPORTANT: Change this to your real auth bloc state path
//     final authState = context.read<AuthenticationBloc>().state;
//     final userId = authState.userDetails?.userId.toString();
//     if (userId == null || userId.isEmpty) return;

//     final startDate = _selectedDate!;
//     final startDateTime = _combine(startDate, _startTime!);
//     final endDateTime = _combine(startDate, _endTime!);

//     final serviceIdForApi = _resolveServiceIdForApi();

//     int bookingTypeId = _bookingTypeId;
//     int? recurrencePatternId;
//     String? customDays;
//     DateTime? endDateForApi;

//     if (_bookingTypeId == BookingTypeIds.asap) {
//       endDateForApi = null;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.future) {
//       endDateForApi = null;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.multiDays) {
//       endDateForApi = _endDate;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.recurrence) {
//       endDateForApi = _endDate;
//       recurrencePatternId = _recurrencePatternId;
//       if (_recurrencePatternId == RecurrencePatternIds.customDays) {
//         customDays = _buildCustomDaysString();
//       }
//     }

//     // debug
//     // ignore: avoid_print
//     print("SUB CATEGORY ID $serviceIdForApi");
//     // ignore: avoid_print
//     print("ADDRESS ${_manualLocationCtrl.text.trim()}");
//     // ignore: avoid_print
//     print("LAT/LNG ${_resolveLat()} / ${_resolveLng()}");

//     context.read<UserBookingBloc>().add(
//           CreateUserBookingRequested(
//             userId: userId,
//             subCategoryId: serviceIdForApi,
//             bookingTypeId: bookingTypeId,
//             bookingDate: startDate,

//             // ✅ backend expects DateTime => always send ISO-8601
//             startTime: startDateTime.toUtc().toIso8601String(),
//             endTime: endDateTime.toUtc().toIso8601String(),

//             endDate: endDateForApi,
//             recurrencePatternId: recurrencePatternId,
//             customDays: customDays,

//             address: _manualLocationCtrl.text.trim(),
//             taskerLevelId: _selectedTaskerLevelId!,
//             latitude: _resolveLat(),
//             longitude: _resolveLng(),
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final subs = widget.group.services;

//     return Scaffold(
//       backgroundColor: kPage,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.chevron_left_rounded, color: kPurple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Service booking',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 17,
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),

//       body: BlocConsumer<UserBookingBloc, UserBookingState>(
//         listenWhen: (prev, curr) =>
//             prev.createStatus != curr.createStatus ||
//             prev.bookingCreateResponse != curr.bookingCreateResponse ||
//             prev.createError != curr.createError,
//         listener: (context, state) {
//           if (state.createStatus == UserBookingCreateStatus.success) {
//             final firstDetailId =
//                 state.bookingCreateResponse?.result?.isNotEmpty == true
//                     ? state.bookingCreateResponse!.result!.first.bookingDetailId
//                     : null;

//             if (firstDetailId == null) return;
//             if (_navigated) return;
//             _navigated = true;

//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => FindingYourTaskerScreen(
//                   bookingid: firstDetailId.toString(),
//                   id: firstDetailId.toString(),
//                 ),
//               ),
//             );
//           }

//           if (state.createStatus == UserBookingCreateStatus.failure) {
//             _navigated = false;
//             final msg = state.createError ?? "Booking failed";
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(msg)),
//             );
//           }
//         },
//         builder: (context, state) {
//           final isLoading =
//               state.createStatus == UserBookingCreateStatus.submitting;

//           return SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _TopInfoCard(title: widget.group.name),
//                   const SizedBox(height: 16),

//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(18),
//                       border: Border.all(color: Colors.black.withOpacity(.03)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(.03),
//                           blurRadius: 16,
//                           offset: const Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const _SectionTitle(
//                             icon: Icons.list_alt_rounded,
//                             label: 'Service details'),
//                         const SizedBox(height: 10),

//                         _ModernFieldShell(
//                           label: 'Subcategory',
//                           child: DropdownButtonHideUnderline(
//                             child: DropdownButton<ServiceOption>(
//                               isExpanded: true,
//                               value: _selectedSubcategory,
//                               icon: const Icon(Icons.expand_more_rounded,
//                                   color: kPurple),
//                               hint: const Text(
//                                 'Select subcategory',
//                                 style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: kMuted,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               items: subs.map((s) {
//                                 return DropdownMenuItem<ServiceOption>(
//                                   value: s,
//                                   child: Text(
//                                     s.name,
//                                     style: const TextStyle(
//                                       fontFamily: 'Poppins',
//                                       color: kText,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 );
//                               }).toList(),
//                               onChanged: (val) =>
//                                   setState(() => _selectedSubcategory = val),
//                             ),
//                           ),
//                         ),
//                         if (_showErrors && _selectedSubcategory == null)
//                           const Padding(
//                             padding: EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Please select a subcategory',
//                               style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 12,
//                                   fontFamily: 'Poppins'),
//                             ),
//                           ),

//                         const SizedBox(height: 18),
//                         const _SectionTitle(
//                             icon: Icons.category_rounded, label: 'Booking type'),
//                         const SizedBox(height: 10),

//                         _ModernFieldShell(
//                           label: 'Select booking type',
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'ASAP',
//                                       subtitle: 'Today',
//                                       selected:
//                                           _bookingTypeId == BookingTypeIds.asap,
//                                       onTap: () =>
//                                           _setBookingType(BookingTypeIds.asap),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Future',
//                                       subtitle: 'Schedule',
//                                       selected: _bookingTypeId ==
//                                           BookingTypeIds.future,
//                                       onTap: () => _setBookingType(
//                                           BookingTypeIds.future),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Multi days',
//                                       subtitle: 'Range',
//                                       selected: _bookingTypeId ==
//                                           BookingTypeIds.multiDays,
//                                       onTap: () => _setBookingType(
//                                           BookingTypeIds.multiDays),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Daily',
//                                       subtitle: 'Recurrence',
//                                       selected: _bookingTypeId ==
//                                               BookingTypeIds.recurrence &&
//                                           _recurrencePatternId ==
//                                               RecurrencePatternIds.daily,
//                                       onTap: () {
//                                         _setBookingType(
//                                             BookingTypeIds.recurrence);
//                                         _setRecurrencePattern(
//                                             RecurrencePatternIds.daily);
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Weekly',
//                                       subtitle: 'Recurrence',
//                                       selected: _bookingTypeId ==
//                                               BookingTypeIds.recurrence &&
//                                           _recurrencePatternId ==
//                                               RecurrencePatternIds.weekly,
//                                       onTap: () {
//                                         _setBookingType(
//                                             BookingTypeIds.recurrence);
//                                         _setRecurrencePattern(
//                                             RecurrencePatternIds.weekly);
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Monthly',
//                                       subtitle: 'Recurrence',
//                                       selected: _bookingTypeId ==
//                                               BookingTypeIds.recurrence &&
//                                           _recurrencePatternId ==
//                                               RecurrencePatternIds.monthly,
//                                       onTap: () {
//                                         _setBookingType(
//                                             BookingTypeIds.recurrence);
//                                         _setRecurrencePattern(
//                                             RecurrencePatternIds.monthly);
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: _BookingTypeCard(
//                                       title: 'Custom days',
//                                       subtitle: 'Pick days',
//                                       selected: _bookingTypeId ==
//                                               BookingTypeIds.recurrence &&
//                                           _recurrencePatternId ==
//                                               RecurrencePatternIds.customDays,
//                                       onTap: () {
//                                         _setBookingType(
//                                             BookingTypeIds.recurrence);
//                                         _setRecurrencePattern(
//                                             RecurrencePatternIds.customDays);
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   const Expanded(child: SizedBox()),
//                                   const SizedBox(width: 10),
//                                   const Expanded(child: SizedBox()),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(height: 18),
//                         const _SectionTitle(
//                             icon: Icons.calendar_month_rounded,
//                             label: 'Schedule'),
//                         const SizedBox(height: 10),

//                         _ModernFieldShell(
//                           label: _isRecurrenceOrMultiDays()
//                               ? 'Start date'
//                               : 'Booking date',
//                           onTap: _bookingTypeId == BookingTypeIds.asap
//                               ? null
//                               : _pickStartDate,
//                           child: Row(
//                             children: [
//                               const Icon(Icons.event_rounded, color: kPurple),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: SizedBox(
//                                   height: 43,
//                                   child: Align(
//                                     alignment: Alignment.centerLeft,
//                                     child: Text(
//                                       _bookingTypeId == BookingTypeIds.asap
//                                           ? _fmtDate(DateTime.now())
//                                           : _fmtDate(_selectedDate),
//                                       style: TextStyle(
//                                         fontFamily: 'Poppins',
//                                         color: (_selectedDate == null)
//                                             ? kMuted
//                                             : kText,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Icon(
//                                 _bookingTypeId == BookingTypeIds.asap
//                                     ? Icons.lock_rounded
//                                     : Icons.chevron_right_rounded,
//                                 color: kPurple,
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (_showErrors && _selectedDate == null)
//                           const Padding(
//                             padding: EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Please select a date',
//                               style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: Colors.red,
//                                   fontSize: 12),
//                             ),
//                           ),

//                         if (_isRecurrenceOrMultiDays()) ...[
//                           const SizedBox(height: 12),
//                           _ModernFieldShell(
//                             label: 'End date',
//                             onTap: _pickEndDate,
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.date_range_rounded,
//                                     color: kPurple),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: SizedBox(
//                                     height: 43,
//                                     child: Align(
//                                       alignment: Alignment.centerLeft,
//                                       child: Text(
//                                         _fmtDate(_endDate),
//                                         style: TextStyle(
//                                           fontFamily: 'Poppins',
//                                           color:
//                                               _endDate == null ? kMuted : kText,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const Icon(Icons.chevron_right_rounded,
//                                     color: kPurple),
//                               ],
//                             ),
//                           ),
//                           if (_showErrors && _endDate == null)
//                             const Padding(
//                               padding: EdgeInsets.only(top: 4),
//                               child: Text(
//                                 'Please select end date',
//                                 style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: Colors.red,
//                                     fontSize: 12),
//                               ),
//                             ),
//                         ],

//                         if (_bookingTypeId == BookingTypeIds.recurrence &&
//                             _recurrencePatternId ==
//                                 RecurrencePatternIds.customDays) ...[
//                           const SizedBox(height: 12),
//                           const Text(
//                             'Select days',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: kText,
//                               fontSize: 12.5,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Wrap(
//                             spacing: 8,
//                             runSpacing: 8,
//                             children: [
//                               _DayChip(
//                                 label: 'Mon',
//                                 selected:
//                                     _selectedWeekdays.contains(DateTime.monday),
//                                 onTap: () =>
//                                     setState(() => _toggleDay(DateTime.monday)),
//                               ),
//                               _DayChip(
//                                 label: 'Tue',
//                                 selected:
//                                     _selectedWeekdays.contains(DateTime.tuesday),
//                                 onTap: () => setState(
//                                     () => _toggleDay(DateTime.tuesday)),
//                               ),
//                               _DayChip(
//                                 label: 'Wed',
//                                 selected: _selectedWeekdays
//                                     .contains(DateTime.wednesday),
//                                 onTap: () => setState(() =>
//                                     _toggleDay(DateTime.wednesday)),
//                               ),
//                               _DayChip(
//                                 label: 'Thu',
//                                 selected: _selectedWeekdays
//                                     .contains(DateTime.thursday),
//                                 onTap: () => setState(
//                                     () => _toggleDay(DateTime.thursday)),
//                               ),
//                               _DayChip(
//                                 label: 'Fri',
//                                 selected:
//                                     _selectedWeekdays.contains(DateTime.friday),
//                                 onTap: () =>
//                                     setState(() => _toggleDay(DateTime.friday)),
//                               ),
//                               _DayChip(
//                                 label: 'Sat',
//                                 selected: _selectedWeekdays
//                                     .contains(DateTime.saturday),
//                                 onTap: () => setState(
//                                     () => _toggleDay(DateTime.saturday)),
//                               ),
//                               _DayChip(
//                                 label: 'Sun',
//                                 selected:
//                                     _selectedWeekdays.contains(DateTime.sunday),
//                                 onTap: () =>
//                                     setState(() => _toggleDay(DateTime.sunday)),
//                               ),
//                             ],
//                           ),
//                           if (_showErrors && _selectedWeekdays.isEmpty)
//                             const Padding(
//                               padding: EdgeInsets.only(top: 6),
//                               child: Text(
//                                 'Please select at least one day',
//                                 style: TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 12,
//                                     fontFamily: 'Poppins'),
//                               ),
//                             ),
//                         ],

//                         const SizedBox(height: 16),
//                         const Text(
//                           'Duration',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             color: kText,
//                             fontSize: 12.5,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _TimeBox(
//                                 label: 'Start time',
//                                 value: _fmtTimeUi(_startTime),
//                                 onTap: _pickStartTime,
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: _TimeBox(
//                                 label: 'End time',
//                                 value: _fmtTimeUi(_endTime),
//                                 onTap: _pickEndTime,
//                               ),
//                             ),
//                           ],
//                         ),
//                         if (_showErrors &&
//                             (_startTime == null || _endTime == null))
//                           const Padding(
//                             padding: EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Please select both start & end time',
//                               style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: Colors.red,
//                                   fontSize: 12),
//                             ),
//                           ),
//                         if (_showErrors &&
//                             _startTime != null &&
//                             _endTime != null &&
//                             !_combine(_selectedDate!, _endTime!)
//                                 .isAfter(_combine(_selectedDate!, _startTime!)))
//                           const Padding(
//                             padding: EdgeInsets.only(top: 4),
//                             child: Text(
//                               'End time must be later than start time',
//                               style: TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: Colors.red,
//                                   fontSize: 12),
//                             ),
//                           ),

//                         const SizedBox(height: 14),
//                         const _SectionTitle(
//                             icon: Icons.place_rounded, label: 'Location'),
//                         const SizedBox(height: 10),

//                         // ✅ Google Places integrated here
//                         _ModernFieldShell(
//                           label: 'Location',
//                           child: GooglePlaceAutoCompleteTextField(
//                             textEditingController: _manualLocationCtrl,
//                             googleAPIKey: _googlePlacesKey,
//                             debounceTime: 600,

//                             // ✅ AU launch (Melbourne)
//                             countries: const ["au"],

//                             // ✅ ensure coords
//                             isLatLngRequired: true,

//                             // keep your field style
//                             inputDecoration: const InputDecoration(
//                               isDense: true,
//                               border: InputBorder.none,
//                               hintText: 'Enter your address / house / suburb',
//                               hintStyle: TextStyle(
//                                   color: kMuted, fontFamily: 'Poppins'),
//                             ),
//                             keyboardType: TextInputType.streetAddress,
//                             isCrossBtnShown: true,
//                             placeType: PlaceType.geocode,

//                             // suggestion tap
//                             itemClick: (Prediction prediction) {
//                               final desc = prediction.description ?? '';
//                               _manualLocationCtrl.text = desc;
//                               _manualLocationCtrl.selection =
//                                   TextSelection.fromPosition(
//                                 TextPosition(offset: desc.length),
//                               );
//                               _lastCommittedAddress = desc.trim();
//                             },

//                             // lat/lng detail
//                             getPlaceDetailWithLatLng: (Prediction prediction) {
//                               setState(() {
//                                 _pickedLat = _asDouble(prediction.lat);
//                                 _pickedLng = _asDouble(prediction.lng);
//                                 _pickedPlaceId = prediction.placeId;
//                               });
//                             },

//                             // list UI
//                             itemBuilder:
//                                 (context, index, Prediction prediction) {
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 10),
//                                 child: Row(
//                                   children: [
//                                     const Icon(Icons.place_rounded,
//                                         color: kPurple, size: 18),
//                                     const SizedBox(width: 10),
//                                     Expanded(
//                                       child: Text(
//                                         prediction.description ?? "",
//                                         style: const TextStyle(
//                                           fontFamily: 'Poppins',
//                                           color: kText,
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },

//                             seperatedBuilder: Divider(
//                               height: 1,
//                               color: Colors.black.withOpacity(.06),
//                             ),

//                             containerHorizontalPadding: 6,
//                           ),
//                         ),
//                         if (_showErrors &&
//                             _manualLocationCtrl.text.trim().isEmpty)
//                           const Padding(
//                             padding: EdgeInsets.only(top: 4),
//                             child: Text(
//                               'Please enter location',
//                               style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 12,
//                                   fontFamily: 'Poppins'),
//                             ),
//                           ),
//                         // ✅ Optional message if you want strict Places selection
//                         // if (_showErrors &&
//                         //     _manualLocationCtrl.text.trim().isNotEmpty &&
//                         //     (_pickedLat == null || _pickedLng == null))
//                         //   const Padding(
//                         //     padding: EdgeInsets.only(top: 4),
//                         //     child: Text(
//                         //       'Please select an address from suggestions',
//                         //       style: TextStyle(
//                         //           color: Colors.red,
//                         //           fontSize: 12,
//                         //           fontFamily: 'Poppins'),
//                         //     ),
//                         //   ),

//                         const SizedBox(height: 18),
//                         const _SectionTitle(
//                             icon: Icons.workspace_premium_rounded,
//                             label: 'Tasker level'),
//                         const SizedBox(height: 10),

//                         _ModernFieldShell(
//                           label: 'Select level',
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: _LevelCardNoIcon(
//                                   title: 'Tasker',
//                                   subtitle: 'Standard',
//                                   selected: _selectedTaskerLevelId == 1,
//                                   onTap: () => _pickTaskerLevel(1),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _LevelCardNoIcon(
//                                   title: 'Pro tasker',
//                                   subtitle: 'Premium',
//                                   selected: _selectedTaskerLevelId == 2,
//                                   onTap: () => _pickTaskerLevel(2),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (_showErrors && _selectedTaskerLevelId == null)
//                           const Padding(
//                             padding: EdgeInsets.only(top: 6),
//                             child: Text(
//                               'Please select tasker level',
//                               style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 12,
//                                   fontFamily: 'Poppins'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: kPurple,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 0,
//                       ),
//                       onPressed: isLoading ? null : _onSubmit,
//                       child: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 180),
//                         child: isLoading
//                             ? const SizedBox(
//                                 key: ValueKey("loading"),
//                                 height: 22,
//                                 width: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.5,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white),
//                                 ),
//                               )
//                             : const Row(
//                                 key: ValueKey("normal"),
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.search_rounded,
//                                       size: 20, color: Colors.white),
//                                   SizedBox(width: 10),
//                                   Text(
//                                     'FIND TASKER',
//                                     style: TextStyle(
//                                       fontFamily: 'Poppins',
//                                       letterSpacing: .3,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _toggleDay(int weekday) {
//     if (_selectedWeekdays.contains(weekday)) {
//       _selectedWeekdays.remove(weekday);
//     } else {
//       _selectedWeekdays.add(weekday);
//     }
//   }
// }

// // ---------------- BookingType UI card ----------------

// class _BookingTypeCard extends StatelessWidget {
//   const _BookingTypeCard({
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);
//   static const Color lilac = Color(0xFFF3ECFF);
//   static const Color border = Color(0xFFE3DAFF);

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? lilac : Colors.white;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             width: selected ? 2 : 1.5,
//             color: selected ? purple.withOpacity(.45) : border,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontFamily: 'Poppins',
//                 color: purple,
//                 fontWeight: FontWeight.w700,
//                 fontSize: 12.5,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               subtitle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: Colors.black.withOpacity(.70),
//                 fontWeight: FontWeight.w400,
//                 fontSize: 11.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DayChip extends StatelessWidget {
//   const _DayChip({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? purple.withOpacity(.12) : Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//             color: selected ? purple : Colors.black.withOpacity(.12),
//             width: 1.4,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w700,
//             color: selected ? purple : Colors.black.withOpacity(.70),
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------------- UI helpers ----------------

// class _TopInfoCard extends StatelessWidget {
//   const _TopInfoCard({required this.title});
//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     const kPurple = Color(0xFF5C2E91);
//     const kText = Color(0xFF111827);
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.black.withOpacity(.03)),
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.03),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 42,
//             width: 42,
//             decoration: BoxDecoration(
//               color: kPurple.withOpacity(.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(Icons.task_alt_rounded, color: kPurple),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Book: $title',
//               style: const TextStyle(
//                 fontFamily: 'Poppins',
//                 color: kText,
//                 fontSize: 14.5,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     const kText = Color(0xFF111827);
//     const kMuted = Color(0xFF6B7280);
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: kMuted),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'Poppins',
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ModernFieldShell extends StatelessWidget {
//   const _ModernFieldShell({
//     required this.label,
//     required this.child,
//     this.onTap,
//   });

//   final String label;
//   final Widget child;
//   final VoidCallback? onTap;

//   static const kMuted = Color(0xFF6B7280);
//   static const kFieldBg = Color(0xFFF9FAFB);

//   @override
//   Widget build(BuildContext context) {
//     final box = Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: kFieldBg,
//         border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: child,
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'Poppins',
//             color: kMuted,
//             fontSize: 12.5,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 6),
//         onTap != null
//             ? InkWell(
//                 borderRadius: BorderRadius.circular(14),
//                 onTap: onTap,
//                 child: box,
//               )
//             : box,
//       ],
//     );
//   }
// }

// class _TimeBox extends StatelessWidget {
//   const _TimeBox({
//     required this.label,
//     required this.value,
//     required this.onTap,
//   });

//   final String label;
//   final String value;
//   final VoidCallback onTap;

//   static const kPurple = Color(0xFF5C2E91);
//   static const kText = Color(0xFF111827);
//   static const kFieldBg = Color(0xFFF9FAFB);

//   @override
//   Widget build(BuildContext context) {
//     final isEmpty = value.isEmpty || value == 'Pick time';
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: onTap,
//       child: Container(
//         height: 50,
//         decoration: BoxDecoration(
//           color: kFieldBg,
//           border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: Row(
//           children: [
//             const Icon(Icons.access_time_rounded, size: 18, color: kPurple),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 isEmpty ? label : value,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: isEmpty ? Colors.grey[500] : kText,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const Icon(Icons.chevron_right_rounded, color: kPurple),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LevelCardNoIcon extends StatelessWidget {
//   const _LevelCardNoIcon({
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);
//   static const Color lilac = Color(0xFFF3ECFF);
//   static const Color border = Color(0xFFE3DAFF);

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? lilac : Colors.white;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(18),
//       splashColor: purple.withOpacity(.08),
//       highlightColor: Colors.transparent,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOutCubic,
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(
//             width: selected ? 2 : 1.5,
//             color: selected ? purple.withOpacity(.45) : border,
//           ),
//           boxShadow: selected
//               ? [
//                   BoxShadow(
//                     color: purple.withOpacity(.10),
//                     blurRadius: 16,
//                     offset: const Offset(0, 8),
//                   ),
//                 ]
//               : const [],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: purple,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                       letterSpacing: .1,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     subtitle,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: Colors.black.withOpacity(.70),
//                       fontWeight: FontWeight.w400,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               switchInCurve: Curves.easeOutBack,
//               child: selected
//                   ? const Icon(
//                       CupertinoIcons.check_mark_circled_solid,
//                       key: ValueKey('check'),
//                       color: purple,
//                       size: 22,
//                     )
//                   : const SizedBox(
//                       key: ValueKey('empty'),
//                       width: 22,
//                       height: 22,
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


/*
class BookingTypeIds {
  static const int asap = 1;
  static const int future = 2;

  /// Recurrence group (backend uses RecurrencePatternId)
  static const int recurrence = 3;

  /// Multi days (range)
  static const int multiDays = 4;
}

class RecurrencePatternIds {
  static const int daily = 1;
  static const int monthly = 2;
  static const int weekly = 3;
  static const int customDays = 4;
}

// ---------------- Screen ----------------

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  final ServiceOption? initialService;

  /// API expects as SubCategoryId
  final int serviceId;

  const ServiceBookingFormScreen({
    super.key,
    required this.group,
    this.initialService,
    required this.serviceId,
  });

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPage = Color(0xFFF5F6FA);
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF6B7280);

  ServiceOption? _selectedSubcategory;
  int? _selectedTaskerLevelId;

  // booking mode
  int _bookingTypeId = BookingTypeIds.asap;

  // recurrence pattern (only used when _bookingTypeId == recurrence)
  int _recurrencePatternId = RecurrencePatternIds.daily;

  // custom days
  final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

  // dates/times
  DateTime? _selectedDate; // start date
  DateTime? _endDate; // recurrence/multi-days
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _manualLocationCtrl = TextEditingController();

  bool _showErrors = false;

  // ✅ navigation guard (prevents multiple pushes)
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _selectedSubcategory = widget.initialService;

    _selectedSubcategory ??= widget.group.services.firstWhere(
      (s) => s.id == widget.serviceId,
      orElse: () => widget.group.services.isNotEmpty
          ? widget.group.services.first
          : ServiceOption(id: widget.serviceId, name: ''),
    );

    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _manualLocationCtrl.dispose();
    super.dispose();
  }

  // -------------------- date/time pickers --------------------

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: initial.isBefore(now) ? now : initial,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;

        if (_isRecurrenceOrMultiDays() &&
            _endDate != null &&
            _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime(now.year + 2),
      initialDate: _endDate ?? start,
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTimeUi(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $suffix';
  }

  bool _isRecurrenceOrMultiDays() =>
      _bookingTypeId == BookingTypeIds.recurrence ||
      _bookingTypeId == BookingTypeIds.multiDays;

  void _pickTaskerLevel(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTaskerLevelId = id;
      if (_showErrors) _showErrors = false;
    });
  }

  // booking type selection
  void _setBookingType(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _bookingTypeId = id;

      // defaults
      if (_bookingTypeId == BookingTypeIds.asap) {
        _selectedDate = DateTime.now();
        _endDate = null;
      } else {
        _selectedDate ??= DateTime.now();
      }

      // reset recurrence config unless recurrence selected
      if (_bookingTypeId != BookingTypeIds.recurrence) {
        _recurrencePatternId = RecurrencePatternIds.daily;
        _selectedWeekdays.clear();
      }

      // multi-days needs endDate
      if (_bookingTypeId == BookingTypeIds.multiDays) {
        _endDate ??= _selectedDate;
      } else if (_bookingTypeId == BookingTypeIds.future ||
          _bookingTypeId == BookingTypeIds.asap) {
        _endDate = null;
      }
    });
  }

  void _setRecurrencePattern(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _recurrencePatternId = id;
      if (id != RecurrencePatternIds.customDays) {
        _selectedWeekdays.clear();
      }
    });
  }

  int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

  double _resolveLat() => 67.0; // keep 0 if you don’t have Places yet
  double _resolveLng() => 70.0;

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "Monday";
    }
  }

  String _buildCustomDaysString() {
    final list = _selectedWeekdays.toList()..sort();
    return list.map(_weekdayName).join(',');
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _validate() {
    final hasBase = _selectedSubcategory != null &&
        _startTime != null &&
        _endTime != null &&
        _manualLocationCtrl.text.trim().isNotEmpty &&
        _selectedTaskerLevelId != null &&
        _selectedDate != null;

    if (!hasBase) return false;

    // validate start < end (same day)
    final startDT = _combine(_selectedDate!, _startTime!);
    final endDT = _combine(_selectedDate!, _endTime!);
    if (!endDT.isAfter(startDT)) return false;

    // recurrence requires endDate + valid
    if (_bookingTypeId == BookingTypeIds.recurrence) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;

      if (_recurrencePatternId == RecurrencePatternIds.customDays) {
        if (_selectedWeekdays.isEmpty) return false;
      }
    }

    // multi-days requires endDate + valid
    if (_bookingTypeId == BookingTypeIds.multiDays) {
      if (_endDate == null) return false;
      if (_endDate!.isBefore(_selectedDate!)) return false;
    }

    return true;
  }

  void _onSubmit() {
    setState(() => _showErrors = true);
    if (!_validate()) return;

    // ✅ reset navigation guard for this submit
    _navigated = false;

    // ✅ IMPORTANT: Change this to your real auth bloc state path
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState.userDetails?.userId.toString();
    if (userId == null || userId.isEmpty) return;

    final startDate = _selectedDate!;
    final startDateTime = _combine(startDate, _startTime!);
    final endDateTime = _combine(startDate, _endTime!);

    final serviceIdForApi = _resolveServiceIdForApi();
   

    int bookingTypeId = _bookingTypeId;
    int? recurrencePatternId;
    String? customDays;
    DateTime? endDateForApi;

    if (_bookingTypeId == BookingTypeIds.asap) {
      endDateForApi = null;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.future) {
      endDateForApi = null;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.multiDays) {
      endDateForApi = _endDate;
      recurrencePatternId = null;
      customDays = null;
    } else if (_bookingTypeId == BookingTypeIds.recurrence) {
      endDateForApi = _endDate;
      recurrencePatternId = _recurrencePatternId;
      if (_recurrencePatternId == RecurrencePatternIds.customDays) {
        customDays = _buildCustomDaysString();
      }
    }
 print("SUB CATEGORY ID $serviceIdForApi");
 print("SUB CATEGORY ID $serviceIdForApi");
 print("SUB CATEGORY ID $serviceIdForApi");
 print("SUB CATEGORY ID $serviceIdForApi");
 print("SUB CATEGORY ID $serviceIdForApi");
    context.read<UserBookingBloc>().add(
          CreateUserBookingRequested(
            userId: userId,
            subCategoryId: serviceIdForApi,
            bookingTypeId: bookingTypeId,
            bookingDate: startDate,

            // ✅ backend expects DateTime => always send ISO-8601
            startTime: startDateTime.toUtc().toIso8601String(),
            endTime: endDateTime.toUtc().toIso8601String(),

            endDate: endDateForApi,
            recurrencePatternId: recurrencePatternId,
            customDays: customDays,

            address: _manualLocationCtrl.text.trim(),
            taskerLevelId: _selectedTaskerLevelId!,
            latitude: _resolveLat(),
            longitude: _resolveLng(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.group.services;

    return Scaffold(
      backgroundColor: kPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: kPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service booking',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            color: kText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ✅ BlocConsumer handles:
      // - dynamic navigation on success
      // - snack on failure
      // - progress inside button on submitting
      body: BlocConsumer<UserBookingBloc, UserBookingState>(
        listenWhen: (prev, curr) =>
            prev.createStatus != curr.createStatus ||
            prev.bookingCreateResponse != curr.bookingCreateResponse ||
            prev.createError != curr.createError,
        listener: (context, state) {
          // success => navigate dynamically
          if (state.createStatus == UserBookingCreateStatus.success) {
            final firstDetailId = state.bookingCreateResponse?.result?.isNotEmpty == true
                ? state.bookingCreateResponse!.result!.first.bookingDetailId
                : null;

            if (firstDetailId == null) return;
            if (_navigated) return;
            _navigated = true;

            // ✅ You can route differently per type here
            // right now all types go to FindingYourTaskerScreen (as per your ask)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindingYourTaskerScreen(
                  bookingid: firstDetailId.toString(),
                  id: firstDetailId.toString(),
                ),
              ),
            );
          }

          // failure => show message
          if (state.createStatus == UserBookingCreateStatus.failure) {
            _navigated = false;
            final msg = state.createError ?? "Booking failed";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state.createStatus == UserBookingCreateStatus.submitting;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopInfoCard(title: widget.group.name),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(.03)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                            icon: Icons.list_alt_rounded,
                            label: 'Service details'),
                        const SizedBox(height: 10),

                        _ModernFieldShell(
                          label: 'Subcategory',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ServiceOption>(
                              isExpanded: true,
                              value: _selectedSubcategory,
                              icon: const Icon(Icons.expand_more_rounded,
                                  color: kPurple),
                              hint: const Text(
                                'Select subcategory',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: kMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              items: subs.map((s) {
                                return DropdownMenuItem<ServiceOption>(
                                  value: s,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: kText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedSubcategory = val),
                            ),
                          ),
                        ),
                        if (_showErrors && _selectedSubcategory == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Please select a subcategory',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontFamily: 'Poppins'),
                            ),
                          ),

                        const SizedBox(height: 18),
                        const _SectionTitle(
                            icon: Icons.category_rounded, label: 'Booking type'),
                        const SizedBox(height: 10),

                        _ModernFieldShell(
                          label: 'Select booking type',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'ASAP',
                                      subtitle: 'Today',
                                      selected:
                                          _bookingTypeId == BookingTypeIds.asap,
                                      onTap: () =>
                                          _setBookingType(BookingTypeIds.asap),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Future',
                                      subtitle: 'Schedule',
                                      selected: _bookingTypeId ==
                                          BookingTypeIds.future,
                                      onTap: () => _setBookingType(
                                          BookingTypeIds.future),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Multi days',
                                      subtitle: 'Range',
                                      selected: _bookingTypeId ==
                                          BookingTypeIds.multiDays,
                                      onTap: () => _setBookingType(
                                          BookingTypeIds.multiDays),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Daily',
                                      subtitle: 'Recurrence',
                                      selected: _bookingTypeId ==
                                              BookingTypeIds.recurrence &&
                                          _recurrencePatternId ==
                                              RecurrencePatternIds.daily,
                                      onTap: () {
                                        _setBookingType(
                                            BookingTypeIds.recurrence);
                                        _setRecurrencePattern(
                                            RecurrencePatternIds.daily);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Weekly',
                                      subtitle: 'Recurrence',
                                      selected: _bookingTypeId ==
                                              BookingTypeIds.recurrence &&
                                          _recurrencePatternId ==
                                              RecurrencePatternIds.weekly,
                                      onTap: () {
                                        _setBookingType(
                                            BookingTypeIds.recurrence);
                                        _setRecurrencePattern(
                                            RecurrencePatternIds.weekly);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Monthly',
                                      subtitle: 'Recurrence',
                                      selected: _bookingTypeId ==
                                              BookingTypeIds.recurrence &&
                                          _recurrencePatternId ==
                                              RecurrencePatternIds.monthly,
                                      onTap: () {
                                        _setBookingType(
                                            BookingTypeIds.recurrence);
                                        _setRecurrencePattern(
                                            RecurrencePatternIds.monthly);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BookingTypeCard(
                                      title: 'Custom days',
                                      subtitle: 'Pick days',
                                      selected: _bookingTypeId ==
                                              BookingTypeIds.recurrence &&
                                          _recurrencePatternId ==
                                              RecurrencePatternIds.customDays,
                                      onTap: () {
                                        _setBookingType(
                                            BookingTypeIds.recurrence);
                                        _setRecurrencePattern(
                                            RecurrencePatternIds.customDays);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(child: SizedBox()),
                                  const SizedBox(width: 10),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        const _SectionTitle(
                            icon: Icons.calendar_month_rounded,
                            label: 'Schedule'),
                        const SizedBox(height: 10),

                        _ModernFieldShell(
                          label: _isRecurrenceOrMultiDays()
                              ? 'Start date'
                              : 'Booking date',
                          onTap: _bookingTypeId == BookingTypeIds.asap
                              ? null
                              : _pickStartDate,
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, color: kPurple),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 43,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _bookingTypeId == BookingTypeIds.asap
                                          ? _fmtDate(DateTime.now())
                                          : _fmtDate(_selectedDate),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: (_selectedDate == null)
                                            ? kMuted
                                            : kText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                _bookingTypeId == BookingTypeIds.asap
                                    ? Icons.lock_rounded
                                    : Icons.chevron_right_rounded,
                                color: kPurple,
                              ),
                            ],
                          ),
                        ),
                        if (_showErrors && _selectedDate == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Please select a date',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.red,
                                  fontSize: 12),
                            ),
                          ),

                        if (_isRecurrenceOrMultiDays()) ...[
                          const SizedBox(height: 12),
                          _ModernFieldShell(
                            label: 'End date',
                            onTap: _pickEndDate,
                            child: Row(
                              children: [
                                const Icon(Icons.date_range_rounded,
                                    color: kPurple),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 43,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _fmtDate(_endDate),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color:
                                              _endDate == null ? kMuted : kText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: kPurple),
                              ],
                            ),
                          ),
                          if (_showErrors && _endDate == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Please select end date',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.red,
                                    fontSize: 12),
                              ),
                            ),
                        ],

                        if (_bookingTypeId == BookingTypeIds.recurrence &&
                            _recurrencePatternId ==
                                RecurrencePatternIds.customDays) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Select days',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: kText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DayChip(
                                label: 'Mon',
                                selected:
                                    _selectedWeekdays.contains(DateTime.monday),
                                onTap: () =>
                                    setState(() => _toggleDay(DateTime.monday)),
                              ),
                              _DayChip(
                                label: 'Tue',
                                selected:
                                    _selectedWeekdays.contains(DateTime.tuesday),
                                onTap: () => setState(
                                    () => _toggleDay(DateTime.tuesday)),
                              ),
                              _DayChip(
                                label: 'Wed',
                                selected: _selectedWeekdays
                                    .contains(DateTime.wednesday),
                                onTap: () => setState(() =>
                                    _toggleDay(DateTime.wednesday)),
                              ),
                              _DayChip(
                                label: 'Thu',
                                selected: _selectedWeekdays
                                    .contains(DateTime.thursday),
                                onTap: () => setState(
                                    () => _toggleDay(DateTime.thursday)),
                              ),
                              _DayChip(
                                label: 'Fri',
                                selected:
                                    _selectedWeekdays.contains(DateTime.friday),
                                onTap: () =>
                                    setState(() => _toggleDay(DateTime.friday)),
                              ),
                              _DayChip(
                                label: 'Sat',
                                selected: _selectedWeekdays
                                    .contains(DateTime.saturday),
                                onTap: () => setState(
                                    () => _toggleDay(DateTime.saturday)),
                              ),
                              _DayChip(
                                label: 'Sun',
                                selected:
                                    _selectedWeekdays.contains(DateTime.sunday),
                                onTap: () =>
                                    setState(() => _toggleDay(DateTime.sunday)),
                              ),
                            ],
                          ),
                          if (_showErrors && _selectedWeekdays.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Please select at least one day',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontFamily: 'Poppins'),
                              ),
                            ),
                        ],

                        const SizedBox(height: 16),
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: kText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeBox(
                                label: 'Start time',
                                value: _fmtTimeUi(_startTime),
                                onTap: _pickStartTime,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TimeBox(
                                label: 'End time',
                                value: _fmtTimeUi(_endTime),
                                onTap: _pickEndTime,
                              ),
                            ),
                          ],
                        ),
                        if (_showErrors &&
                            (_startTime == null || _endTime == null))
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Please select both start & end time',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.red,
                                  fontSize: 12),
                            ),
                          ),
                        if (_showErrors &&
                            _startTime != null &&
                            _endTime != null &&
                            !_combine(_selectedDate!, _endTime!)
                                .isAfter(_combine(_selectedDate!, _startTime!)))
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'End time must be later than start time',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.red,
                                  fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 14),
                        const _SectionTitle(
                            icon: Icons.place_rounded, label: 'Location'),
                        const SizedBox(height: 10),

                        _ModernFieldShell(
                          label: 'Location',
                          child: TextField(
                            controller: _manualLocationCtrl,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Enter your address / house / suburb',
                              hintStyle: TextStyle(
                                  color: kMuted, fontFamily: 'Poppins'),
                            ),
                            style: const TextStyle(
                                color: kText, fontFamily: 'Poppins'),
                          ),
                        ),
                        if (_showErrors && _manualLocationCtrl.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Please enter location',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontFamily: 'Poppins'),
                            ),
                          ),

                        const SizedBox(height: 18),
                        const _SectionTitle(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Tasker level'),
                        const SizedBox(height: 10),

                        _ModernFieldShell(
                          label: 'Select level',
                          child: Row(
                            children: [
                              Expanded(
                                child: _LevelCardNoIcon(
                                  title: 'Tasker',
                                  subtitle: 'Standard',
                                  selected: _selectedTaskerLevelId == 1,
                                  onTap: () => _pickTaskerLevel(1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _LevelCardNoIcon(
                                  title: 'Pro tasker',
                                  subtitle: 'Premium',
                                  selected: _selectedTaskerLevelId == 2,
                                  onTap: () => _pickTaskerLevel(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showErrors && _selectedTaskerLevelId == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Please select tasker level',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading ? null : _onSubmit,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey("loading"),
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            :const Row(
                                key:  ValueKey("normal"),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded,
                                      size: 20, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'FIND TASKER',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      letterSpacing: .3,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleDay(int weekday) {
    if (_selectedWeekdays.contains(weekday)) {
      _selectedWeekdays.remove(weekday);
    } else {
      _selectedWeekdays.add(weekday);
    }
  }
}

// ---------------- BookingType UI card ----------------

class _BookingTypeCard extends StatelessWidget {
  const _BookingTypeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const Color purple = Color(0xFF7841BA);
  static const Color lilac = Color(0xFFF3ECFF);
  static const Color border = Color(0xFFE3DAFF);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? lilac : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: selected ? 2 : 1.5,
            color: selected ? purple.withOpacity(.45) : border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: purple,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.black.withOpacity(.70),
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color purple = Color(0xFF7841BA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? purple.withOpacity(.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? purple : Colors.black.withOpacity(.12),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: selected ? purple : Colors.black.withOpacity(.70),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ---------------- UI helpers ----------------

class _TopInfoCard extends StatelessWidget {
  const _TopInfoCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    const kPurple = Color(0xFF5C2E91);
    const kText = Color(0xFF111827);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(.03)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: kPurple.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.task_alt_rounded, color: kPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Book: $title',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: kText,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const kText = Color(0xFF111827);
    const kMuted = Color(0xFF6B7280);
    return Row(
      children: [
        Icon(icon, size: 18, color: kMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: kText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModernFieldShell extends StatelessWidget {
  const _ModernFieldShell({
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  static const kMuted = Color(0xFF6B7280);
  static const kFieldBg = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kFieldBg,
        border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: kMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: box,
              )
            : box,
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  static const kPurple = Color(0xFF5C2E91);
  static const kText = Color(0xFF111827);
  static const kFieldBg = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty || value == 'Pick time';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: kFieldBg,
          border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: kPurple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEmpty ? label : value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isEmpty ? Colors.grey[500] : kText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kPurple),
          ],
        ),
      ),
    );
  }
}

class _LevelCardNoIcon extends StatelessWidget {
  const _LevelCardNoIcon({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  static const Color purple = Color(0xFF7841BA);
  static const Color lilac = Color(0xFFF3ECFF);
  static const Color border = Color(0xFFE3DAFF);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? lilac : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: purple.withOpacity(.08),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: selected ? 2 : 1.5,
            color: selected ? purple.withOpacity(.45) : border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: purple.withOpacity(.10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: .1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(.70),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              child: selected
                  ? const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      key: ValueKey('check'),
                      color: purple,
                      size: 22,
                    )
                  : const SizedBox(
                      key: ValueKey('empty'),
                      width: 22,
                      height: 22,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}*/

/* -------------------------------------------------------------------------- */
/*  ✅ NOTE: Your missing types below must exist in your project               */
/*  - CertificationGroup                                                      */
/*  - ServiceOption                                                           */
/*  - AuthenticationBloc / AuthenticationState.userDetails.userId             */
/*  - UserBookingBloc / UserBookingState                                      */
/*  - CreateUserBookingRequested event                                         */
/*  - FindingYourTaskerScreen                                                 */
/* -------------------------------------------------------------------------- */



// /// ✅ Backend IDs (as you shared)
// class BookingTypeIds {
//   static const int asap = 1;
//   static const int future = 2;

//   /// Recurrence group (backend uses RecurrencePatternId)
//   static const int recurrence = 3;

//   /// Multi days (range)
//   static const int multiDays = 4;
// }

// class RecurrencePatternIds {
//   static const int daily = 1;
//   static const int monthly = 2;
//   static const int weekly = 3;
//   static const int customDays = 4;
// }


// class ServiceBookingFormScreen extends StatefulWidget {
//   final CertificationGroup group;
//   final ServiceOption? initialService;

//   /// API expects as SubCategoryId
//   final int serviceId;

//   const ServiceBookingFormScreen({
//     super.key,
//     required this.group,
//     this.initialService,
//     required this.serviceId,
//   });

//   @override
//   State<ServiceBookingFormScreen> createState() =>
//       _ServiceBookingFormScreenState();
// }

// class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
//   static const Color kPurple = Color(0xFF5C2E91);
//   static const Color kPage = Color(0xFFF5F6FA);
//   static const Color kText = Color(0xFF111827);
//   static const Color kMuted = Color(0xFF6B7280);

//   ServiceOption? _selectedSubcategory;
//   int? _selectedTaskerLevelId;

//   // booking mode
//   int _bookingTypeId = BookingTypeIds.asap;

//   // recurrence pattern (only used when _bookingTypeId == recurrence)
//   int _recurrencePatternId = RecurrencePatternIds.daily;

//   // custom days
//   final Set<int> _selectedWeekdays = {}; // 1..7 (Mon..Sun)

//   // dates/times
//   DateTime? _selectedDate; // start date
//   DateTime? _endDate; // recurrence/multi-days
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;

//   final _manualLocationCtrl = TextEditingController();

//   bool _showErrors = false;

//   @override
//   void initState() {
//     super.initState();

//     _selectedSubcategory = widget.initialService;

//     _selectedSubcategory ??= widget.group.services.firstWhere(
//       (s) => s.id == widget.serviceId,
//       orElse: () => widget.group.services.isNotEmpty
//           ? widget.group.services.first
//           : ServiceOption(id: widget.serviceId, name: ''),
//     );

//     _selectedDate = DateTime.now();
//   }

//   @override
//   void dispose() {
//     _manualLocationCtrl.dispose();
//     super.dispose();
//   }

//   // -------------------- date/time pickers --------------------

//   Future<void> _pickStartDate() async {
//     final now = DateTime.now();
//     final initial = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: now,
//       lastDate: DateTime(now.year + 2),
//       initialDate: initial.isBefore(now) ? now : initial,
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;

//         if (_isRecurrenceOrMultiDays() &&
//             _endDate != null &&
//             _endDate!.isBefore(picked)) {
//           _endDate = null;
//         }
//       });
//     }
//   }

//   Future<void> _pickEndDate() async {
//     final now = DateTime.now();
//     final start = _selectedDate ?? now;

//     final picked = await showDatePicker(
//       context: context,
//       firstDate: start,
//       lastDate: DateTime(now.year + 2),
//       initialDate: _endDate ?? start,
//     );
//     if (picked != null) setState(() => _endDate = picked);
//   }

//   Future<void> _pickStartTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) setState(() => _startTime = picked);
//   }

//   Future<void> _pickEndTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) setState(() => _endTime = picked);
//   }

//   String _fmtDate(DateTime? d) =>
//       d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

//   String _fmtTimeUi(TimeOfDay? t) {
//     if (t == null) return 'Pick time';
//     final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
//     final minute = t.minute.toString().padLeft(2, '0');
//     final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
//     return '$hour12:$minute $suffix';
//   }

//   bool _isRecurrenceOrMultiDays() =>
//       _bookingTypeId == BookingTypeIds.recurrence ||
//       _bookingTypeId == BookingTypeIds.multiDays;

//   void _pickTaskerLevel(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _selectedTaskerLevelId = id;
//       if (_showErrors) _showErrors = false;
//     });
//   }

//   // booking type selection
//   void _setBookingType(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _bookingTypeId = id;

//       // defaults
//       if (_bookingTypeId == BookingTypeIds.asap) {
//         _selectedDate = DateTime.now();
//         _endDate = null;
//       } else {
//         _selectedDate ??= DateTime.now();
//       }

//       // reset recurrence config unless recurrence selected
//       if (_bookingTypeId != BookingTypeIds.recurrence) {
//         _recurrencePatternId = RecurrencePatternIds.daily;
//         _selectedWeekdays.clear();
//       }

//       // multi-days needs endDate
//       if (_bookingTypeId == BookingTypeIds.multiDays) {
//         _endDate ??= _selectedDate;
//       } else if (_bookingTypeId == BookingTypeIds.future ||
//           _bookingTypeId == BookingTypeIds.asap) {
//         _endDate = null;
//       }
//     });
//   }

//   void _setRecurrencePattern(int id) {
//     HapticFeedback.selectionClick();
//     setState(() {
//       _recurrencePatternId = id;
//       if (id != RecurrencePatternIds.customDays) {
//         _selectedWeekdays.clear();
//       }
//     });
//   }

//   int _resolveServiceIdForApi() => _selectedSubcategory?.id ?? widget.serviceId;

//   double _resolveLat() => 0.0; // ✅ keep 0 if you don’t have Places yet
//   double _resolveLng() => 0.0;

//   String _weekdayName(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return "Monday";
//       case DateTime.tuesday:
//         return "Tuesday";
//       case DateTime.wednesday:
//         return "Wednesday";
//       case DateTime.thursday:
//         return "Thursday";
//       case DateTime.friday:
//         return "Friday";
//       case DateTime.saturday:
//         return "Saturday";
//       case DateTime.sunday:
//         return "Sunday";
//       default:
//         return "Monday";
//     }
//   }

//   String _buildCustomDaysString() {
//     final list = _selectedWeekdays.toList()..sort();
//     return list.map(_weekdayName).join(',');
//   }

//   DateTime _combine(DateTime date, TimeOfDay time) {
//     return DateTime(date.year, date.month, date.day, time.hour, time.minute);
//   }

//   bool _validate() {
//     final hasBase = _selectedSubcategory != null &&
//         _startTime != null &&
//         _endTime != null &&
//         _manualLocationCtrl.text.trim().isNotEmpty &&
//         _selectedTaskerLevelId != null &&
//         _selectedDate != null;

//     if (!hasBase) return false;

//     // validate start < end (same day)
//     final startDT = _combine(_selectedDate!, _startTime!);
//     final endDT = _combine(_selectedDate!, _endTime!);
//     if (!endDT.isAfter(startDT)) return false;

//     // recurrence requires endDate + valid
//     if (_bookingTypeId == BookingTypeIds.recurrence) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;

//       if (_recurrencePatternId == RecurrencePatternIds.customDays) {
//         if (_selectedWeekdays.isEmpty) return false;
//       }
//     }

//     // multi-days requires endDate + valid
//     if (_bookingTypeId == BookingTypeIds.multiDays) {
//       if (_endDate == null) return false;
//       if (_endDate!.isBefore(_selectedDate!)) return false;
//     }

//     return true;
//   }

//   void _onSubmit() {
//     setState(() => _showErrors = true);
//     if (!_validate()) return;

//     // ✅ IMPORTANT: Change this to your real auth bloc state path
//     final authState = context.read<AuthenticationBloc>().state;
//     final userId = authState.userDetails?.userId.toString();
//     if (userId == null || userId.isEmpty) return;

//     final startDate = _selectedDate!;
//     final startDateTime = _combine(startDate, _startTime!);
//     final endDateTime = _combine(startDate, _endTime!);

//     final serviceIdForApi = _resolveServiceIdForApi();

//     int bookingTypeId = _bookingTypeId;
//     int? recurrencePatternId;
//     String? customDays;
//     DateTime? endDateForApi;
// //
//     if (_bookingTypeId == BookingTypeIds.asap && context.read<UserBookingBloc>().state.createStatus == UserBookingCreateStatus.success) {
//       endDateForApi = null;
//       recurrencePatternId = null;
//       customDays = null;
//       Navigator.push(context, MaterialPageRoute(builder: (context)=> FindingYourTaskerScreen(bookingid: context.read<UserBookingBloc>().state.bookingCreateResponse!.result!.first.bookingDetailId.toString(), id: context.read<UserBookingBloc>().state.bookingCreateResponse!.result!.first.bookingDetailId.toString())));
//     } else if (_bookingTypeId == BookingTypeIds.future) {
//       endDateForApi = null;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.multiDays) {
//       endDateForApi = _endDate;
//       recurrencePatternId = null;
//       customDays = null;
//     } else if (_bookingTypeId == BookingTypeIds.recurrence) {
//       endDateForApi = _endDate;
//       recurrencePatternId = _recurrencePatternId;
//       if (_recurrencePatternId == RecurrencePatternIds.customDays) {
//         customDays = _buildCustomDaysString();
//       }
//     }

//     context.read<UserBookingBloc>().add(
//           CreateUserBookingRequested(
//             userId: userId,
//             subCategoryId: serviceIdForApi,

//             bookingTypeId: bookingTypeId,
//             bookingDate: startDate,

//             startTime: startDateTime.toString(), // ✅ DateTime
//             endTime: endDateTime.toString(), // ✅ DateTime

//             endDate: endDateForApi,
//             recurrencePatternId: recurrencePatternId,
//             customDays: customDays,

//             address: _manualLocationCtrl.text.trim(),
//             taskerLevelId: _selectedTaskerLevelId!,

//             latitude: _resolveLat(),
//             longitude: _resolveLng(),
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final subs = widget.group.services;

//     return Scaffold(
//       backgroundColor: kPage,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.chevron_left_rounded, color: kPurple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Service booking',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 17,
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _TopInfoCard(title: widget.group.name),
//               const SizedBox(height: 16),

//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: Colors.black.withOpacity(.03)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.03),
//                       blurRadius: 16,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const _SectionTitle(
//                         icon: Icons.list_alt_rounded, label: 'Service details'),
//                     const SizedBox(height: 10),

//                     _ModernFieldShell(
//                       label: 'Subcategory',
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<ServiceOption>(
//                           isExpanded: true,
//                           value: _selectedSubcategory,
//                           icon: const Icon(Icons.expand_more_rounded,
//                               color: kPurple),
//                           hint: const Text(
//                             'Select subcategory',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: kMuted,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           items: subs.map((s) {
//                             return DropdownMenuItem<ServiceOption>(
//                               value: s,
//                               child: Text(
//                                 s.name,
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: kText,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           onChanged: (val) =>
//                               setState(() => _selectedSubcategory = val),
//                         ),
//                       ),
//                     ),
//                     if (_showErrors && _selectedSubcategory == null)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Text(
//                           'Please select a subcategory',
//                           style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 12,
//                               fontFamily: 'Poppins'),
//                         ),
//                       ),

//                     const SizedBox(height: 18),
//                     const _SectionTitle(
//                         icon: Icons.category_rounded, label: 'Booking type'),
//                     const SizedBox(height: 10),

//                     _ModernFieldShell(
//                       label: 'Select booking type',
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'ASAP',
//                                   subtitle: 'Today',
//                                   selected:
//                                       _bookingTypeId == BookingTypeIds.asap,
//                                   onTap: () =>
//                                       _setBookingType(BookingTypeIds.asap),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Future',
//                                   subtitle: 'Schedule',
//                                   selected:
//                                       _bookingTypeId == BookingTypeIds.future,
//                                   onTap: () =>
//                                       _setBookingType(BookingTypeIds.future),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Multi days',
//                                   subtitle: 'Range',
//                                   selected: _bookingTypeId ==
//                                       BookingTypeIds.multiDays,
//                                   onTap: () =>
//                                       _setBookingType(BookingTypeIds.multiDays),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Daily',
//                                   subtitle: 'Recurrence',
//                                   selected: _bookingTypeId ==
//                                           BookingTypeIds.recurrence &&
//                                       _recurrencePatternId ==
//                                           RecurrencePatternIds.daily,
//                                   onTap: () {
//                                     _setBookingType(BookingTypeIds.recurrence);
//                                     _setRecurrencePattern(
//                                         RecurrencePatternIds.daily);
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Weekly',
//                                   subtitle: 'Recurrence',
//                                   selected: _bookingTypeId ==
//                                           BookingTypeIds.recurrence &&
//                                       _recurrencePatternId ==
//                                           RecurrencePatternIds.weekly,
//                                   onTap: () {
//                                     _setBookingType(BookingTypeIds.recurrence);
//                                     _setRecurrencePattern(
//                                         RecurrencePatternIds.weekly);
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Monthly',
//                                   subtitle: 'Recurrence',
//                                   selected: _bookingTypeId ==
//                                           BookingTypeIds.recurrence &&
//                                       _recurrencePatternId ==
//                                           RecurrencePatternIds.monthly,
//                                   onTap: () {
//                                     _setBookingType(BookingTypeIds.recurrence);
//                                     _setRecurrencePattern(
//                                         RecurrencePatternIds.monthly);
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _BookingTypeCard(
//                                   title: 'Custom days',
//                                   subtitle: 'Pick days',
//                                   selected: _bookingTypeId ==
//                                           BookingTypeIds.recurrence &&
//                                       _recurrencePatternId ==
//                                           RecurrencePatternIds.customDays,
//                                   onTap: () {
//                                     _setBookingType(BookingTypeIds.recurrence);
//                                     _setRecurrencePattern(
//                                         RecurrencePatternIds.customDays);
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               const Expanded(child: SizedBox()),
//                               const SizedBox(width: 10),
//                               const Expanded(child: SizedBox()),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 18),
//                     const _SectionTitle(
//                         icon: Icons.calendar_month_rounded, label: 'Schedule'),
//                     const SizedBox(height: 10),

//                     _ModernFieldShell(
//                       label: _isRecurrenceOrMultiDays()
//                           ? 'Start date'
//                           : 'Booking date',
//                       onTap: _bookingTypeId == BookingTypeIds.asap
//                           ? null
//                           : _pickStartDate,
//                       child: Row(
//                         children: [
//                           const Icon(Icons.event_rounded, color: kPurple),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: SizedBox(
//                               height: 43,
//                               child: Align(
//                                 alignment: Alignment.centerLeft,
//                                 child: Text(
//                                   _bookingTypeId == BookingTypeIds.asap
//                                       ? _fmtDate(DateTime.now())
//                                       : _fmtDate(_selectedDate),
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color:
//                                         (_selectedDate == null) ? kMuted : kText,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Icon(
//                             _bookingTypeId == BookingTypeIds.asap
//                                 ? Icons.lock_rounded
//                                 : Icons.chevron_right_rounded,
//                             color: kPurple,
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (_showErrors && _selectedDate == null)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Text(
//                           'Please select a date',
//                           style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: Colors.red,
//                               fontSize: 12),
//                         ),
//                       ),

//                     if (_isRecurrenceOrMultiDays()) ...[
//                       const SizedBox(height: 12),
//                       _ModernFieldShell(
//                         label: 'End date',
//                         onTap: _pickEndDate,
//                         child: Row(
//                           children: [
//                             const Icon(Icons.date_range_rounded, color: kPurple),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: SizedBox(
//                                 height: 43,
//                                 child: Align(
//                                   alignment: Alignment.centerLeft,
//                                   child: Text(
//                                     _fmtDate(_endDate),
//                                     style: TextStyle(
//                                       fontFamily: 'Poppins',
//                                       color: _endDate == null ? kMuted : kText,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const Icon(Icons.chevron_right_rounded,
//                                 color: kPurple),
//                           ],
//                         ),
//                       ),
//                       if (_showErrors && _endDate == null)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 4),
//                           child: Text(
//                             'Please select end date',
//                             style: TextStyle(
//                                 fontFamily: 'Poppins',
//                                 color: Colors.red,
//                                 fontSize: 12),
//                           ),
//                         ),
//                     ],

//                     if (_bookingTypeId == BookingTypeIds.recurrence &&
//                         _recurrencePatternId == RecurrencePatternIds.customDays)
//                       ...[
//                         const SizedBox(height: 12),
//                         const Text(
//                           'Select days',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             color: kText,
//                             fontSize: 12.5,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             _DayChip(
//                               label: 'Mon',
//                               selected:
//                                   _selectedWeekdays.contains(DateTime.monday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.monday)),
//                             ),
//                             _DayChip(
//                               label: 'Tue',
//                               selected:
//                                   _selectedWeekdays.contains(DateTime.tuesday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.tuesday)),
//                             ),
//                             _DayChip(
//                               label: 'Wed',
//                               selected: _selectedWeekdays
//                                   .contains(DateTime.wednesday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.wednesday)),
//                             ),
//                             _DayChip(
//                               label: 'Thu',
//                               selected: _selectedWeekdays
//                                   .contains(DateTime.thursday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.thursday)),
//                             ),
//                             _DayChip(
//                               label: 'Fri',
//                               selected:
//                                   _selectedWeekdays.contains(DateTime.friday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.friday)),
//                             ),
//                             _DayChip(
//                               label: 'Sat',
//                               selected:
//                                   _selectedWeekdays.contains(DateTime.saturday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.saturday)),
//                             ),
//                             _DayChip(
//                               label: 'Sun',
//                               selected:
//                                   _selectedWeekdays.contains(DateTime.sunday),
//                               onTap: () => setState(
//                                   () => _toggleDay(DateTime.sunday)),
//                             ),
//                           ],
//                         ),
//                         if (_showErrors && _selectedWeekdays.isEmpty)
//                           const Padding(
//                             padding: EdgeInsets.only(top: 6),
//                             child: Text(
//                               'Please select at least one day',
//                               style: TextStyle(
//                                   color: Colors.red,
//                                   fontSize: 12,
//                                   fontFamily: 'Poppins'),
//                             ),
//                           ),
//                       ],

//                     const SizedBox(height: 16),
//                     const Text(
//                       'Duration',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         color: kText,
//                         fontSize: 12.5,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _TimeBox(
//                             label: 'Start time',
//                             value: _fmtTimeUi(_startTime),
//                             onTap: _pickStartTime,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _TimeBox(
//                             label: 'End time',
//                             value: _fmtTimeUi(_endTime),
//                             onTap: _pickEndTime,
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (_showErrors && (_startTime == null || _endTime == null))
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Text(
//                           'Please select both start & end time',
//                           style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: Colors.red,
//                               fontSize: 12),
//                         ),
//                       ),
//                     if (_showErrors &&
//                         _startTime != null &&
//                         _endTime != null &&
//                         !_combine(_selectedDate!, _endTime!)
//                             .isAfter(_combine(_selectedDate!, _startTime!)))
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Text(
//                           'End time must be later than start time',
//                           style: TextStyle(
//                               fontFamily: 'Poppins',
//                               color: Colors.red,
//                               fontSize: 12),
//                         ),
//                       ),

//                     const SizedBox(height: 14),
//                     const _SectionTitle(
//                         icon: Icons.place_rounded, label: 'Location'),
//                     const SizedBox(height: 10),

//                     _ModernFieldShell(
//                       label: 'Location',
//                       child: TextField(
//                         controller: _manualLocationCtrl,
//                         decoration: const InputDecoration(
//                           isDense: true,
//                           border: InputBorder.none,
//                           hintText: 'Enter your address / house / suburb',
//                           hintStyle:
//                               TextStyle(color: kMuted, fontFamily: 'Poppins'),
//                         ),
//                         style: const TextStyle(
//                             color: kText, fontFamily: 'Poppins'),
//                       ),
//                     ),
//                     if (_showErrors && _manualLocationCtrl.text.trim().isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4),
//                         child: Text(
//                           'Please enter location',
//                           style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 12,
//                               fontFamily: 'Poppins'),
//                         ),
//                       ),

//                     const SizedBox(height: 18),
//                     const _SectionTitle(
//                         icon: Icons.workspace_premium_rounded,
//                         label: 'Tasker level'),
//                     const SizedBox(height: 10),

//                     _ModernFieldShell(
//                       label: 'Select level',
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: _LevelCardNoIcon(
//                               title: 'Tasker',
//                               subtitle: 'Standard',
//                               selected: _selectedTaskerLevelId == 1,
//                               onTap: () => _pickTaskerLevel(1),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _LevelCardNoIcon(
//                               title: 'Pro tasker',
//                               subtitle: 'Premium',
//                               selected: _selectedTaskerLevelId == 2,
//                               onTap: () => _pickTaskerLevel(2),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (_showErrors && _selectedTaskerLevelId == null)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 6),
//                         child: Text(
//                           'Please select tasker level',
//                           style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 12,
//                               fontFamily: 'Poppins'),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 18),

//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.search_rounded,
//                       size: 20, color: Colors.white),
//                   label: const Text(
//                     'FIND TASKER',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       letterSpacing: .3,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kPurple,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     elevation: 0,
//                   ),
//                   onPressed: _onSubmit,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _toggleDay(int weekday) {
//     if (_selectedWeekdays.contains(weekday)) {
//       _selectedWeekdays.remove(weekday);
//     } else {
//       _selectedWeekdays.add(weekday);
//     }
//   }
// }

// /* ---------------- BookingType UI card ---------------- */

// class _BookingTypeCard extends StatelessWidget {
//   const _BookingTypeCard({
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);
//   static const Color lilac = Color(0xFFF3ECFF);
//   static const Color border = Color(0xFFE3DAFF);

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? lilac : Colors.white;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             width: selected ? 2 : 1.5,
//             color: selected ? purple.withOpacity(.45) : border,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontFamily: 'Poppins',
//                 color: purple,
//                 fontWeight: FontWeight.w700,
//                 fontSize: 12.5,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               subtitle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: Colors.black.withOpacity(.70),
//                 fontWeight: FontWeight.w400,
//                 fontSize: 11.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DayChip extends StatelessWidget {
//   const _DayChip(
//       {required this.label, required this.selected, required this.onTap});
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? purple.withOpacity(.12) : Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//               color: selected ? purple : Colors.black.withOpacity(.12),
//               width: 1.4),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontWeight: FontWeight.w700,
//             color: selected ? purple : Colors.black.withOpacity(.70),
//             fontSize: 12,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                                    UI                                      */
// /* -------------------------------------------------------------------------- */

// class _TopInfoCard extends StatelessWidget {
//   const _TopInfoCard({required this.title});
//   final String title;

//   @override
//   Widget build(BuildContext context) {
//     const kPurple = Color(0xFF5C2E91);
//     const kText = Color(0xFF111827);
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.black.withOpacity(.03)),
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.03),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 42,
//             width: 42,
//             decoration: BoxDecoration(
//               color: kPurple.withOpacity(.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(Icons.task_alt_rounded, color: kPurple),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Book: $title',
//               style: const TextStyle(
//                 fontFamily: 'Poppins',
//                 color: kText,
//                 fontSize: 14.5,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     const kText = Color(0xFF111827);
//     const kMuted = Color(0xFF6B7280);
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: kMuted),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'Poppins',
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ModernFieldShell extends StatelessWidget {
//   const _ModernFieldShell({
//     required this.label,
//     required this.child,
//     this.onTap,
//   });

//   final String label;
//   final Widget child;
//   final VoidCallback? onTap;

//   static const kMuted = Color(0xFF6B7280);
//   static const kFieldBg = Color(0xFFF9FAFB);

//   @override
//   Widget build(BuildContext context) {
//     final box = Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: kFieldBg,
//         border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: child,
//     );

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'Poppins',
//             color: kMuted,
//             fontSize: 12.5,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 6),
//         onTap != null
//             ? InkWell(
//                 borderRadius: BorderRadius.circular(14),
//                 onTap: onTap,
//                 child: box,
//               )
//             : box,
//       ],
//     );
//   }
// }

// class _TimeBox extends StatelessWidget {
//   const _TimeBox({
//     required this.label,
//     required this.value,
//     required this.onTap,
//   });

//   final String label;
//   final String value;
//   final VoidCallback onTap;

//   static const kPurple = Color(0xFF5C2E91);
//   static const kText = Color(0xFF111827);
//   static const kFieldBg = Color(0xFFF9FAFB);

//   @override
//   Widget build(BuildContext context) {
//     final isEmpty = value.isEmpty || value == 'Pick time';
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: onTap,
//       child: Container(
//         height: 50,
//         decoration: BoxDecoration(
//           color: kFieldBg,
//           border: Border.all(color: Colors.black.withOpacity(.08), width: 1),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: Row(
//           children: [
//             const Icon(Icons.access_time_rounded, size: 18, color: kPurple),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 isEmpty ? label : value,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: isEmpty ? Colors.grey[500] : kText,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const Icon(Icons.chevron_right_rounded, color: kPurple),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LevelCardNoIcon extends StatelessWidget {
//   const _LevelCardNoIcon({
//     required this.title,
//     required this.subtitle,
//     required this.selected,
//     required this.onTap,
//   });

//   final String title;
//   final String subtitle;
//   final bool selected;
//   final VoidCallback onTap;

//   static const Color purple = Color(0xFF7841BA);
//   static const Color lilac = Color(0xFFF3ECFF);
//   static const Color border = Color(0xFFE3DAFF);

//   @override
//   Widget build(BuildContext context) {
//     final bg = selected ? lilac : Colors.white;

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(18),
//       splashColor: purple.withOpacity(.08),
//       highlightColor: Colors.transparent,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeOutCubic,
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(
//             width: selected ? 2 : 1.5,
//             color: selected ? purple.withOpacity(.45) : border,
//           ),
//           boxShadow: selected
//               ? [
//                   BoxShadow(
//                     color: purple.withOpacity(.10),
//                     blurRadius: 16,
//                     offset: const Offset(0, 8),
//                   ),
//                 ]
//               : const [],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: purple,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                       letterSpacing: .1,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     subtitle,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: Colors.black.withOpacity(.70),
//                       fontWeight: FontWeight.w400,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 200),
//               switchInCurve: Curves.easeOutBack,
//               child: selected
//                   ? const Icon(
//                       CupertinoIcons.check_mark_circled_solid,
//                       key: ValueKey('check'),
//                       color: purple,
//                       size: 22,
//                     )
//                   : const SizedBox(
//                       key: ValueKey('empty'),
//                       width: 22,
//                       height: 22,
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

