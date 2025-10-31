import 'package:flutter/material.dart';
import 'package:taskoon/Models/services_ui_model.dart';

class ServiceBookingFormScreen extends StatefulWidget {
  final CertificationGroup group;
  const ServiceBookingFormScreen({super.key, required this.group});

  @override
  State<ServiceBookingFormScreen> createState() =>
      _ServiceBookingFormScreenState();
}

class _ServiceBookingFormScreenState extends State<ServiceBookingFormScreen> {
  static const purple = Color(0xFF4A2C73);
  static const borderRadius = 14.0;

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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Date';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return 'Time';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.group.services; // dynamic from API
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.group.name,
          style: const TextStyle(color: purple),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subcategory
              _LabeledBox(
                label: 'Subcategory',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ServiceOption>(
                    isExpanded: true,
                    value: _selectedSubcategory,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: purple),
                    hint: const Text('Select subcategory',
                        style: TextStyle(color: purple)),
                    items: subs.map((s) {
                      return DropdownMenuItem<ServiceOption>(
                        value: s,
                        child: Text(s.name,
                            style: const TextStyle(color: purple)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSubcategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Booking date(s)
              _LabeledBox(
                label: 'Booking date(s)',
                child: InkWell(
                  onTap: _pickDate,
                  child: SizedBox(
                    height: 46,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fmtDate(_selectedDate),
                        style: const TextStyle(color: purple),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text('One booking fee',
                  style: TextStyle(color: purple, fontSize: 12)),
              const SizedBox(height: 14),

              const Text('Duration',
                  style: TextStyle(color: purple, fontSize: 12)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _TappableBox(
                      label: 'Start Time',
                      text: _fmtTime(_startTime),
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TappableBox(
                      label: 'End Time',
                      text: _fmtTime(_endTime),
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _bookNow,
                    activeColor: purple,
                    onChanged: (v) => setState(() => _bookNow = v ?? false),
                  ),
                  const Text('Book now',
                      style: TextStyle(color: purple, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              _LabeledBox(
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
              const SizedBox(height: 14),

              // Tasker level
              _LabeledBox(
                label: 'Tasker level',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTaskerLevel,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: purple),
                    hint: const Text('Tasker / pro tasker',
                        style: TextStyle(color: purple)),
                    items: const [
                      DropdownMenuItem(
                        value: 'tasker',
                        child:
                            Text('Tasker', style: TextStyle(color: purple)),
                      ),
                      DropdownMenuItem(
                        value: 'pro_tasker',
                        child: Text('Pro Tasker',
                            style: TextStyle(color: purple)),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      _selectedTaskerLevel = val;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // collect data here & call API
                  },
                  child: const Text(
                    'FIND TASKER',
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: .4,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledBox extends StatelessWidget {
  const _LabeledBox({required this.label, required this.child});
  final String label;
  final Widget child;

  static const purple = Color(0xFF4A2C73);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: purple, fontSize: 12, height: 1.1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: purple, width: 1.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _TappableBox extends StatelessWidget {
  const _TappableBox({
    required this.label,
    required this.text,
    required this.onTap,
  });
  final String label;
  final String text;
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
          border: Border.all(color: purple, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text.isEmpty ? label : text,
            style: const TextStyle(color: purple),
          ),
        ),
      ),
    );
  }
}
