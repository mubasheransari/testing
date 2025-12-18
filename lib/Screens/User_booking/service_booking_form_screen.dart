import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:google_place/google_place.dart' as gp;
import 'package:taskoon/Screens/User_booking/finding_tasker_screen.dart';

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  final ServiceOption? initialService;
  final String subCategoryId;

  const ServiceBookingFormScreen({
    super.key,
    required this.group,
    this.initialService,
    required this.subCategoryId,
  });

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  // Brand accent (kept)
  static const Color kPurple = Color(0xFF5C2E91);

  // New neutrals for black-first UI
  static const Color kPage = Color(0xFFF5F6FA);
  static const Color kText = Color(0xFF111827); // near-black
  static const Color kMuted = Color(0xFF6B7280); // label/assistive
  static const Color kFieldBg = Color(0xFFF9FAFB); // subtle bg

  // keep google places
  static const _kPlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  late final gp.GooglePlace _googlePlace;

  ServiceOption? _selectedSubcategory;
  String? _selectedTaskerLevel;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // manual location (VISIBLE)
  final _manualLocationCtrl = TextEditingController();
  // google places location (hidden)
  final _placesLocationCtrl = TextEditingController();
  gp.DetailsResponse? _pickedPlaceDetails;

  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.initialService;
    _googlePlace = gp.GooglePlace(_kPlacesApiKey);
  }

  @override
  void dispose() {
    _manualLocationCtrl.dispose();
    _placesLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        // force 12-hour picker UI
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        // force 12-hour picker UI
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  /// UI: show 8:00 / 9:00 (12-hour, no AM/PM text)
  String _fmtTimeUi(TimeOfDay? t) {
    if (t == null) return 'Pick time';

    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');

    return '$hour12:$minute'; // e.g. "8:00"
  }

  /// API: send "HH:mm:ss" like "20:00:00"
  String _fmtTimeForApi(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0'); // 0–23
    final m = t.minute.toString().padLeft(2, '0');
    const s = '00';
    return '$h:$m:$s';
  }

  Future<void> _openPlacesSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PlacesSheet(
          googlePlace: _googlePlace,
          onPlacePicked: (prediction, details) {
            Navigator.pop(ctx);
            setState(() {
              _placesLocationCtrl.text = prediction.description ?? '';
              _pickedPlaceDetails = details;
            });
          },
        );
      },
    );
  }

  void _onSubmit() {
    setState(() => _showErrors = true);

    final isValid =
        _selectedSubcategory != null &&
        _selectedDate != null &&
        _startTime != null &&
        _endTime != null &&
        _manualLocationCtrl.text.trim().isNotEmpty &&
        _selectedTaskerLevel != null;

    if (!isValid) return;

    context.read<UserBookingBloc>().add(
      CreateUserBookingRequested(
        userId:context.read<AuthenticationBloc>().state.userDetails!.userId.toString(),
        subCategoryId: int.parse(widget.subCategoryId),
        bookingDate: _selectedDate!, // DateTime
        startTime: _fmtTimeForApi(_startTime!), // "HH:mm:ss"
        endTime: _fmtTimeForApi(_endTime!), // "HH:mm:ss"
        address: _manualLocationCtrl.text.trim(),
        taskerLevelId: 2,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopInfoCard(title: widget.group.name),
              const SizedBox(height: 16),

              // main form card
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
                      label: 'Service details',
                    ),
                    const SizedBox(height: 10),

                    // subcategory
                    _ModernFieldShell(
                      label: 'Subcategory',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ServiceOption>(
                          isExpanded: true,
                          value: _selectedSubcategory,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: kPurple,
                          ),
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
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.calendar_month_rounded,
                      label: 'Schedule',
                    ),
                    const SizedBox(height: 10),

                    // date
                    _ModernFieldShell(
                      label: 'Booking date(s)',
                      onTap: _pickDate,
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
                                  _fmtDate(_selectedDate),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _selectedDate == null
                                        ? kMuted
                                        : kText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kPurple,
                          ),
                        ],
                      ),
                    ),
                    if (_showErrors && _selectedDate == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select a booking date',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    const Text(
                      'One booking fee',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: kMuted,
                        fontSize: 11.5,
                      ),
                    ),
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
                            value: _fmtTimeUi(_startTime), // UI string
                            onTap: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeBox(
                            label: 'End time',
                            value: _fmtTimeUi(_endTime), // UI string
                            onTap: _pickEndTime,
                          ),
                        ),
                      ],
                    ),
                    if (_showErrors && (_startTime == null || _endTime == null))
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select both start & end time',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),
                    const _SectionTitle(
                      icon: Icons.place_rounded,
                      label: 'Location',
                    ),
                    const SizedBox(height: 10),

                    // VISIBLE: manual field
                    _ModernFieldShell(
                      label: 'Location',
                      child: TextField(
                        controller: _manualLocationCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Enter your address / house / suburb',
                          hintStyle: TextStyle(
                            color: kMuted,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        style: const TextStyle(
                          color: kText,
                          fontFamily: 'Poppins',
                        ),
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
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                    // HIDDEN: google places (kept offstage)
                    Offstage(
                      offstage: true,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _ModernFieldShell(
                            label: 'Location (Google Places)',
                            onTap: _openPlacesSheet,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: kPurple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: IgnorePointer(
                                    child: TextField(
                                      controller: _placesLocationCtrl,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        hintText:
                                            'Search street, city, state (AU)',
                                        hintStyle: TextStyle(
                                          color: kMuted,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: kText,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: kPurple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Tasker level',
                    ),
                    const SizedBox(height: 10),
                    _ModernFieldShell(
                      label: 'Tasker level',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedTaskerLevel,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            color: kPurple,
                          ),
                          hint: const Text(
                            'Tasker / Pro tasker',
                            style: TextStyle(
                              color: kMuted,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'tasker',
                              child: Text(
                                'Tasker',
                                style: TextStyle(
                                  color: kText,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'pro_tasker',
                              child: Text(
                                'Pro tasker',
                                style: TextStyle(
                                  color: kText,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedTaskerLevel = val),
                        ),
                      ),
                    ),
                    if (_showErrors && _selectedTaskerLevel == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select tasker level',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              BlocConsumer<UserBookingBloc, UserBookingState>(
                listenWhen: (previous, current) =>
                    previous.createStatus != current.createStatus,
                listener: (context, state) {
                  if (state.createStatus == UserBookingCreateStatus.success) {
                    final booking = state
                        .bookingCreateResponse!
                        .result!
                        .first
                        .bookingDetailId;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Booking created successfully'
                          '${booking != null ? ' (ID: ${booking})' : ''}', //Testing@123
                        ),
                      ),
                    );

                    if (booking != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<UserBookingBloc>(),
                              ),
                              BlocProvider.value(
                                value: context.read<AuthenticationBloc>(),
                              ),
                            ],
                            child: FindingYourTaskerScreen(bookingid: booking),
                          ),
                        ),
                      );

                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) =>
                      //         FindingTaskerScreen(bookingid: booking),
                      //   ),
                      // );
                    }
                  } else if (state.createStatus ==
                      UserBookingCreateStatus.failure) {
                    print("ERROR PRINT ${state.createError}");
                    print("ERROR PRINT ${state.createError}");
                    print("ERROR PRINT ${state.createError}");
                    print("ERROR PRINT ${state.createError}");
                    print("ERROR PRINT ${state.createError}");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.createError ?? 'Failed to create booking',
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isSubmitting =
                      state.createStatus == UserBookingCreateStatus.submitting;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                      label: Text(
                        isSubmitting ? 'PROCESSING...' : 'FIND TASKER ',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          letterSpacing: .3,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting ? null : _onSubmit,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                    UI                                      */
/* -------------------------------------------------------------------------- */

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

/* ---------------- Google Places bottom sheet ---------------- */

class _PlacesSheet extends StatefulWidget {
  const _PlacesSheet({required this.googlePlace, required this.onPlacePicked});

  final gp.GooglePlace googlePlace;
  final void Function(gp.AutocompletePrediction, gp.DetailsResponse?)
  onPlacePicked;

  @override
  State<_PlacesSheet> createState() => _PlacesSheetState();
}

class _PlacesSheetState extends State<_PlacesSheet> {
  final _searchCtrl = TextEditingController();
  List<gp.AutocompletePrediction> _preds = [];
  bool _loading = false;

  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF6B7280);

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _preds = []);
      return;
    }
    setState(() => _loading = true);
    final res = await widget.googlePlace.autocomplete.get(
      q,
      components: [gp.Component('country', 'au')],
      language: 'en',
    );
    setState(() {
      _loading = false;
      _preds = res?.predictions ?? [];
    });
    if (res?.status != null && res!.status != 'OK') {
      debugPrint('Places error: ${res.status}');
    }
  }

  Future<void> _pick(gp.AutocompletePrediction p) async {
    gp.DetailsResponse? d;
    if (p.placeId != null) {
      d = await widget.googlePlace.details.get(p.placeId!);
    }
    widget.onPlacePicked(p, d);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Search address',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Poppins',
                color: kText,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Street, city, state, house no…',
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontFamily: 'Poppins', color: kText),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.builder(
                itemCount: _preds.length,
                itemBuilder: (ctx, i) {
                  final p = _preds[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined, color: kMuted),
                    title: Text(
                      p.description ?? '',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: kText,
                      ),
                    ),
                    onTap: () => _pick(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

