import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';
import 'package:taskoon/Models/services_ui_model.dart';


import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

// put your real key here
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart' as gp;

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  const ServiceBookingFormScreen({super.key, required this.group});

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  static const purple = Color(0xFF4A2C73);

  // TODO: real key
  static const _kPlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  late final gp.GooglePlace _googlePlace;

  ServiceOption? _selectedSubcategory;
  String? _selectedTaskerLevel;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _locationCtrl = TextEditingController();
  gp.DetailsResponse? _pickedPlaceDetails;

  // validation flag
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _googlePlace = gp.GooglePlace(_kPlacesApiKey);
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
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
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
              _locationCtrl.text = prediction.description ?? '';
              _pickedPlaceDetails = details;
            });
          },
        );
      },
    );
  }

  void _onSubmit() {
    setState(() => _showErrors = true);

    final isValid = _selectedSubcategory != null &&
        _selectedDate != null &&
        _startTime != null &&
        _endTime != null &&
        _locationCtrl.text.trim().isNotEmpty &&
        _selectedTaskerLevel != null;

    if (!isValid) return;

    // proceed with API payload...
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.group.services;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFF5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1EFF5),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Booking Form',
          style: TextStyle(
            fontSize: 22,
            color: purple,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: Column(
            children: [
              _HeaderHero(title: widget.group.name),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
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

                    // Subcategory
                    _ModernFieldShell(
                      label: 'Subcategory',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ServiceOption>(
                          isExpanded: true,
                          value: _selectedSubcategory,
                          icon: const Icon(Icons.expand_more_rounded,
                              color: purple),
                          hint: const Text(
                            'Select subcategory',
                            style: TextStyle(
                                color: purple, fontWeight: FontWeight.w500),
                          ),
                          items: subs.map((s) {
                            return DropdownMenuItem<ServiceOption>(
                              value: s,
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  color: purple,
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
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 18),
                    const _SectionTitle(
                      icon: Icons.calendar_month_rounded,
                      label: 'Schedule',
                    ),
                    const SizedBox(height: 10),

                    // Date
                    _ModernFieldShell(
                      label: 'Booking date(s)',
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded,
                              color: purple.withOpacity(.85)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 43,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.5),
                                child: Text(
                                  _fmtDate(_selectedDate),
                                  style: const TextStyle(
                                      color: purple,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: purple),
                        ],
                      ),
                    ),
                    if (_showErrors && _selectedDate == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select a booking date',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 10),
                    Text(
                      'One booking fee',
                      style: TextStyle(
                        color: purple.withOpacity(.7),
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Duration',
                      style: TextStyle(
                        color: purple.withOpacity(.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Start time',
                            value: _fmtTime(_startTime),
                            onTap: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeBox(
                            label: 'End time',
                            value: _fmtTime(_endTime),
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
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 14),
                    const _SectionTitle(
                      icon: Icons.place_rounded,
                      label: 'Location',
                    ),
                    const SizedBox(height: 10),

                    // Google Places
                    _ModernFieldShell(
                      label: 'Location',
                      onTap: _openPlacesSheet,
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              size: 19, color: purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: IgnorePointer(
                              child: TextField(
                                controller: _locationCtrl,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText:
                                      'Search street, city, state (AU & global)',
                                  hintStyle: TextStyle(color: purple),
                                ),
                                style: const TextStyle(color: purple),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: purple),
                        ],
                      ),
                    ),
                    if (_showErrors &&
                        _locationCtrl.text.trim().isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Please select a location',
                          style: TextStyle(color: Colors.red, fontSize: 12),
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
                          icon: const Icon(Icons.expand_more_rounded,
                              color: purple),
                          hint: const Text(
                            'Tasker / Pro tasker',
                            style: TextStyle(color: purple),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'tasker',
                              child: Text('Tasker',
                                  style: TextStyle(color: purple)),
                            ),
                            DropdownMenuItem(
                              value: 'pro_tasker',
                              child: Text('Pro tasker',
                                  style: TextStyle(color: purple)),
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
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search_rounded,
                      size: 20, color: Colors.white),
                  label: const Text(
                    'FIND TASKER',
                    style: TextStyle(
                      letterSpacing: .3,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- small widgets ---------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    return Row(
      children: [
        Icon(icon, size: 18, color: purple),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: purple,
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

  static const purple = Color(0xFF4A2C73);

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FF),
        border: Border.all(color: purple.withOpacity(.25), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: purple.withOpacity(.8),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
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

  static const purple = Color(0xFF4A2C73);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF8FF),
          border: Border.all(color: purple.withOpacity(.25), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: purple.withOpacity(.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: purple),
          ],
        ),
      ),
    );
  }
}

class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2D3FF), Color(0xFFFBF8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Book: $title',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: purple),
          )
        ],
      ),
    );
  }
}

/* ---------------- Google Places bottom sheet ---------------- */

class _PlacesSheet extends StatefulWidget {
  const _PlacesSheet({
    required this.googlePlace,
    required this.onPlacePicked,
  });

  final gp.GooglePlace googlePlace;
  final void Function(
    gp.AutocompletePrediction,
    gp.DetailsResponse?,
  ) onPlacePicked;

  @override
  State<_PlacesSheet> createState() => _PlacesSheetState();
}

class _PlacesSheetState extends State<_PlacesSheet> {
  final _searchCtrl = TextEditingController();
  List<gp.AutocompletePrediction> _preds = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _preds = []);
      return;
    }
    setState(() => _loading = true);
    final res = await widget.googlePlace.autocomplete.get(
      q,
      // 🇦🇺 focus on AU
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
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Street, city, state, house no…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.builder(
                itemCount: _preds.length,
                itemBuilder: (ctx, i) {
                  final p = _preds[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(p.description ?? ''),
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

/*

// keep your models
class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  const ServiceBookingFormScreen({super.key, required this.group});

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  static const purple = Color(0xFF4A2C73);
  static const surface = Color(0xFFF7F3FF);

  ServiceOption? _selectedSubcategory;
  String? _selectedTaskerLevel;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _bookNow = false;
  final _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _locationCtrl.dispose();
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
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Pick time';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.group.services;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFF5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1EFF5),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Booking Form',
          style: const TextStyle(
            fontSize: 22,
            color: purple,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: Column(
            children: [
              // header card
              _HeaderHero(title: widget.group.name),
              const SizedBox(height: 16),

              // main card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
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
                          icon: const Icon(Icons.expand_more_rounded,
                              color: purple),
                          hint: const Text('Select subcategory',
                              style: TextStyle(
                                  color: purple,
                                  fontWeight: FontWeight.w500)),
                          items: subs.map((s) {
                            return DropdownMenuItem<ServiceOption>(
                              value: s,
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                    color: purple,
                                    fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSubcategory = val);
                          },
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
                          Icon(Icons.event_rounded,
                              color: purple.withOpacity(.85)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fmtDate(_selectedDate),
                              style: const TextStyle(
                                  color: purple, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'One booking fee',
                      style: TextStyle(
                        color: purple.withOpacity(.7),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Duration',
                      style: TextStyle(
                        color: purple.withOpacity(.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeBox(
                            label: 'Start time',
                            value: _fmtTime(_startTime),
                            onTap: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeBox(
                            label: 'End time',
                            value: _fmtTime(_endTime),
                            onTap: _pickEndTime,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // Row(
                    //   children: [
                    //     Checkbox(
                    //       value: _bookNow,
                    //       activeColor: purple,
                    //       onChanged: (v) =>
                    //           setState(() => _bookNow = v ?? false),
                    //     ),
                    //     const Text(
                    //       'Book now',
                    //       style: TextStyle(
                    //           color: purple,
                    //           fontSize: 13.5,
                    //           fontWeight: FontWeight.w500),
                    //     ),
                    //     const SizedBox(width: 6),
                    //     if (_bookNow)
                    //       Container(
                    //         padding: const EdgeInsets.symmetric(
                    //             horizontal: 10, vertical: 4),
                    //         decoration: BoxDecoration(
                    //           color: purple.withOpacity(.09),
                    //           borderRadius: BorderRadius.circular(999),
                    //         ),
                    //         child: const Text(
                    //           'Instant slot',
                    //           style: TextStyle(
                    //               color: purple, fontSize: 11.5),
                    //         ),
                    //       ),
                    //   ],
                    // ),

                    // const SizedBox(height: 16),
                    const _SectionTitle(
                      icon: Icons.place_rounded,
                      label: 'Location',
                    ),
                    const SizedBox(height: 10),

                    _ModernFieldShell(
                      label: 'Location',
                      child: TextField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Enter your location',
                          hintStyle: TextStyle(color: purple),
                        ),
                        style: const TextStyle(color: purple),
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
                          icon: const Icon(Icons.expand_more_rounded,
                              color: purple),
                          hint: const Text(
                            'Tasker / Pro tasker',
                            style: TextStyle(color: purple),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'tasker',
                              child: Text('Tasker',
                                  style: TextStyle(color: purple)),
                            ),
                            DropdownMenuItem(
                              value: 'pro_tasker',
                              child: Text('Pro tasker',
                                  style: TextStyle(color: purple)),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedTaskerLevel = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text(
                    'FIND TASKER',
                    style: TextStyle(
                      letterSpacing: .3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // submit
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------- small widgets ---------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    return Row(
      children: [
        Icon(icon, size: 18, color: purple),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: purple,
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

  static const purple = Color(0xFF4A2C73);

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FF),
        border: Border.all(color: purple.withOpacity(.25), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: purple.withOpacity(.8),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: content,
              )
            : content,
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

  static const purple = Color(0xFF4A2C73);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF8FF),
          border: Border.all(color: purple.withOpacity(.25), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: purple.withOpacity(.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: purple),
          ],
        ),
      ),
    );
  }
}

class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A2C73);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2D3FF), Color(0xFFFBF8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Book: $title',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: purple),
          )
        ],
      ),
    );
  }
}*/


// class ServiceBookingFormScreen extends StatefulWidget {
//   final CertificationGroup group;
//   const ServiceBookingFormScreen({super.key, required this.group});

//   @override
//   State<ServiceBookingFormScreen> createState() =>
//       _ServiceBookingFormScreenState();
// }

// class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
//   static const purple = Color(0xFF4A2C73);
//   static const borderRadius = 14.0;

//   ServiceOption? _selectedSubcategory;
//   String? _selectedTaskerLevel;
//   DateTime? _selectedDate;
//   TimeOfDay? _startTime;
//   TimeOfDay? _endTime;
//   bool _bookNow = false;
//   final _locationCtrl = TextEditingController();

//   @override
//   void dispose() {
//     _locationCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _pickDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       firstDate: now,
//       lastDate: DateTime(now.year + 1),
//       initialDate: now,
//     );
//     if (picked != null) {
//       setState(() => _selectedDate = picked);
//     }
//   }

//   Future<void> _pickStartTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() => _startTime = picked);
//     }
//   }

//   Future<void> _pickEndTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() => _endTime = picked);
//     }
//   }

//   String _fmtDate(DateTime? d) {
//     if (d == null) return 'Date';
//     return '${d.day}/${d.month}/${d.year}';
//   }

//   String _fmtTime(TimeOfDay? t) {
//     if (t == null) return 'Time';
//     final hh = t.hour.toString().padLeft(2, '0');
//     final mm = t.minute.toString().padLeft(2, '0');
//     return '$hh:$mm';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final subs = widget.group.services; // dynamic from API
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: purple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.group.name,
//           style: const TextStyle(color: purple),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Subcategory
//               _LabeledBox(
//                 label: 'Subcategory',
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<ServiceOption>(
//                     isExpanded: true,
//                     value: _selectedSubcategory,
//                     icon: const Icon(Icons.keyboard_arrow_down_rounded,
//                         color: purple),
//                     hint: const Text('Select subcategory',
//                         style: TextStyle(color: purple)),
//                     items: subs.map((s) {
//                       return DropdownMenuItem<ServiceOption>(
//                         value: s,
//                         child: Text(s.name,
//                             style: const TextStyle(color: purple)),
//                       );
//                     }).toList(),
//                     onChanged: (val) {
//                       setState(() => _selectedSubcategory = val);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 14),

//               // Booking date(s)
//               _LabeledBox(
//                 label: 'Booking date(s)',
//                 child: InkWell(
//                   onTap: _pickDate,
//                   child: SizedBox(
//                     height: 46,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         _fmtDate(_selectedDate),
//                         style: const TextStyle(color: purple),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               const Text('One booking fee',
//                   style: TextStyle(color: purple, fontSize: 12)),
//               const SizedBox(height: 14),

//               const Text('Duration',
//                   style: TextStyle(color: purple, fontSize: 12)),
//               const SizedBox(height: 8),

//               Row(
//                 children: [
//                   Expanded(
//                     child: _TappableBox(
//                       label: 'Start Time',
//                       text: _fmtTime(_startTime),
//                       onTap: _pickStartTime,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _TappableBox(
//                       label: 'End Time',
//                       text: _fmtTime(_endTime),
//                       onTap: _pickEndTime,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Checkbox(
//                     value: _bookNow,
//                     activeColor: purple,
//                     onChanged: (v) => setState(() => _bookNow = v ?? false),
//                   ),
//                   const Text('Book now',
//                       style: TextStyle(color: purple, fontSize: 13)),
//                 ],
//               ),
//               const SizedBox(height: 10),

//               // Location
//               _LabeledBox(
//                 label: 'Location',
//                 child: TextField(
//                   controller: _locationCtrl,
//                   decoration: const InputDecoration(
//                     isDense: true,
//                     border: InputBorder.none,
//                     hintText: 'Enter your location',
//                     hintStyle: TextStyle(color: purple),
//                   ),
//                   style: const TextStyle(color: purple),
//                 ),
//               ),
//               const SizedBox(height: 14),

//               // Tasker level
//               _LabeledBox(
//                 label: 'Tasker level',
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     isExpanded: true,
//                     value: _selectedTaskerLevel,
//                     icon: const Icon(Icons.keyboard_arrow_down_rounded,
//                         color: purple),
//                     hint: const Text('Tasker / pro tasker',
//                         style: TextStyle(color: purple)),
//                     items: const [
//                       DropdownMenuItem(
//                         value: 'tasker',
//                         child:
//                             Text('Tasker', style: TextStyle(color: purple)),
//                       ),
//                       DropdownMenuItem(
//                         value: 'pro_tasker',
//                         child: Text('Pro Tasker',
//                             style: TextStyle(color: purple)),
//                       ),
//                     ],
//                     onChanged: (val) => setState(() {
//                       _selectedTaskerLevel = val;
//                     }),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 26),

//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: purple,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                   onPressed: () {
//                     // collect data here & call API
//                   },
//                   child: const Text(
//                     'FIND TASKER',
//                     style: TextStyle(
//                         color: Colors.white,
//                         letterSpacing: .4,
//                         fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LabeledBox extends StatelessWidget {
//   const _LabeledBox({required this.label, required this.child});
//   final String label;
//   final Widget child;

//   static const purple = Color(0xFF4A2C73);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label,
//             style: const TextStyle(color: purple, fontSize: 12, height: 1.1)),
//         const SizedBox(height: 4),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//           decoration: BoxDecoration(
//             border: Border.all(color: purple, width: 1.4),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: child,
//         ),
//       ],
//     );
//   }
// }

// Future<bool?> showBookingAcceptDialog(
//   BuildContext context, {
//   required String topBadgeAsset,
//   required String watermarkAsset,
//   String title = 'Accept Booking',
//   String subtitle = 'Do you want to accept the booking?',
// }) {
//   return showGeneralDialog<bool>(
//     context: context,
//     useRootNavigator: true, // <- important
//     barrierDismissible: true,
//     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//     barrierColor: Colors.black.withOpacity(.15),
//     transitionDuration: const Duration(milliseconds: 220),
//     pageBuilder: (_, __, ___) {
//       final width = MediaQuery.of(context).size.width * 0.80;
//       return Stack(
//         fit: StackFit.expand,
//         children: [
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: const SizedBox.expand(),
//           ),
//           Center(
//             child: _DecisionDialogCard(
//               width: width,
//               title: title,
//               subtitle: subtitle,
//               topBadgeAsset: topBadgeAsset,
//               watermarkAsset: watermarkAsset,
//               primaryLabel: 'Accept',
//               primaryIcon: Icons.task_alt,
//               // close dialog on ROOT navigator and return true
//               onPrimary: () => Navigator.of(_, rootNavigator: true).pop(true),
//               secondaryLabel: 'Cancel',
//               secondaryIcon: Icons.cancel,
//               // close dialog and return false
//               onSecondary: () => Navigator.of(_, rootNavigator: true).pop(false),
//               secondaryOutlined: true,
//               warningText: 'Cancellations may affect your future bookings',
//             ),
//           ),
//         ],
//       );
//     },
//     transitionBuilder: (ctx, anim, _, child) {
//       final curved = CurvedAnimation(
//         parent: anim,
//         curve: Curves.easeOutCubic,
//         reverseCurve: Curves.easeInCubic,
//       );
//       return FadeTransition(
//         opacity: curved,
//         child: SlideTransition(
//           position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
//           child: child,
//         ),
//       );
//     },
//   );
// }

// class _DecisionDialogCard extends StatelessWidget {
//   const _DecisionDialogCard({
//     required this.width,
//     required this.title,
//     required this.subtitle,
//     required this.topBadgeAsset,
//     required this.watermarkAsset,
//     // Primary (right) action
//     required this.primaryLabel,
//     required this.primaryIcon,
//     required this.onPrimary,
//     // Secondary (left) action
//     required this.secondaryLabel,
//     required this.secondaryIcon,
//     required this.onSecondary,
//     this.secondaryOutlined = false,
//     // Optional extra texts
//     this.warningText,
//     this.highlightText,
//     this.highlightColor,
//   });

//   final double width;
//   final String title;
//   final String subtitle;

//   final String topBadgeAsset;
//   final String watermarkAsset;

//   final String primaryLabel;
//   final IconData primaryIcon;
//   final VoidCallback onPrimary;

//   final String secondaryLabel;
//   final IconData secondaryIcon;
//   final VoidCallback onSecondary;
//   final bool secondaryOutlined;

//   final String? warningText;   // red line (optional)
//   final String? highlightText; // green line (optional)
//   final Color? highlightColor;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final double clampedW = width.clamp(300.0, 420.0) as double;

//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         width: clampedW,
//         constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             // Glass card
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Colors.white.withOpacity(isDark ? 0.10 : 0.30),
//                         Colors.white.withOpacity(isDark ? 0.06 : 0.18),
//                       ],
//                     ),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(isDark ? 0.20 : 0.30),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.20),
//                         blurRadius: 28,
//                         offset: const Offset(0, 16),
//                       ),
//                     ],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Stack(
//                     children: [
//                       // Watermark
//                       Positioned(
//                         right: -8,
//                         bottom: -8,
//                         child: IgnorePointer(
//                           child: Opacity(
//                             opacity: isDark ? 0.12 : 0.10,
//                             child: Image.asset(
//                               watermarkAsset,
//                               width: 140,
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                         ),
//                       ),
//                       // Content
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const SizedBox(height: 26), // space for top badge
//                             Text(
//                               title,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w800,
//                                 color: isDark ? Colors.white : Colors.black,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               subtitle,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 13.5,
//                                 height: 1.35,
//                                 color: isDark ? Colors.white70 : Colors.black87,
//                               ),
//                             ),
//                             if (warningText != null) ...[
//                               const SizedBox(height: 8),
//                               Text(
//                                 warningText!,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 14.5,
//                                   height: 1.35,
//                                   color: Colors.red,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                             if (highlightText != null) ...[
//                               const SizedBox(height: 8),
//                               Text(
//                                 highlightText!,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 14.5,
//                                   height: 1.35,
//                                   color: highlightColor ?? Colors.green,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                             const SizedBox(height: 18),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _ActionButton(
//                                     label: secondaryLabel,
//                                     fallbackIcon: secondaryIcon,
//                                     outlined: secondaryOutlined,
//                                     onPressed: onSecondary,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: _ActionButton(
//                                     label: primaryLabel,
//                                     fallbackIcon: primaryIcon,
//                                     onPressed: onPrimary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Top circular badge
//             Positioned(
//               top: -28,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   width: 64,
//                   height: 64,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.25),
//                         blurRadius: 16,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: BackdropFilter(
//                       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                       child: DecoratedBox(
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(isDark ? 0.18 : 0.32),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(10.0),
//                           child: Image.asset(
//                             topBadgeAsset,
//                             fit: BoxFit.contain,
//                             color: Constants.primaryDark,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _ActionButton extends StatelessWidget {
//   const _ActionButton({
//     required this.label,
//     required this.fallbackIcon,
//     this.onPressed,
//     this.outlined = false,
//   });

//   final String label;
//   final IconData fallbackIcon;
//   final VoidCallback? onPressed;
//   final bool outlined;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final Color bg = outlined
//         ? Colors.white.withOpacity(isDark ? 0.02 : 0.06)
//         : Constants.primaryDark;
//     final Color fg =
//         outlined ? (isDark ? Colors.white : Colors.black87) : Colors.white;
//     final Color borderColor = outlined
//         ? Colors.white.withOpacity(isDark ? 0.25 : 0.28)
//         : Colors.transparent;

//     return SizedBox(
//       height: 48,
//       child: TextButton(
//         onPressed: onPressed,
//         style: ButtonStyle(
//           backgroundColor: MaterialStatePropertyAll<Color>(bg),
//           foregroundColor: MaterialStatePropertyAll<Color>(fg),
//           overlayColor:
//               MaterialStatePropertyAll<Color>(Colors.white.withOpacity(0.08)),
//           shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
//             RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//               side: BorderSide(color: borderColor, width: outlined ? 1 : 0),
//             ),
//           ),
//           padding: const MaterialStatePropertyAll<EdgeInsets>(
//             EdgeInsets.symmetric(horizontal: 12),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(fallbackIcon, size: 20),
//             const SizedBox(width: 8),
//             Flexible(
//               child: Text(
//                 label,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// class _TappableBox extends StatelessWidget {
//   const _TappableBox({
//     required this.label,
//     required this.text,
//     required this.onTap,
//   });
//   final String label;
//   final String text;
//   final VoidCallback onTap;

//   static const purple = Color(0xFF4A2C73);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: onTap,
//       child: Container(
//         height: 50,
//         decoration: BoxDecoration(
//           border: Border.all(color: purple, width: 1.4),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Center(
//           child: Text(
//             text.isEmpty ? label : text,
//             style: const TextStyle(color: purple),
//           ),
//         ),
//       ),
//     );
//   }
// }
