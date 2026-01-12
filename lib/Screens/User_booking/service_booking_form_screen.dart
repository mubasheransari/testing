import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Screens/User_booking/finding_tasker_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


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
}

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

