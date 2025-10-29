import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';

class TaskCompletionScreen extends StatefulWidget {
  const TaskCompletionScreen({super.key});

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  // Brand palette
  static const kPrimary = Color(0xFF5C2E91);
  static const kPrimaryDark = Color(0xFF411C6E);
  static const kStroke = Color(0xFFE8E2F5);

  final _reviewCtrl = TextEditingController();

  final _items = <_ChecklistItem>[
    _ChecklistItem('I have collected all tools and materials'),
    _ChecklistItem('The area is clean and tidy'),
    _ChecklistItem('Power/water/gas are returned to normal (if applicable)'),
    _ChecklistItem('Completion photos taken (recommended)'),
    _ChecklistItem('Customer has confirmed the handover'),
  ];

  final _picker = ImagePicker();
  final List<XFile> _images = [];
  double _rating = 0; // 0..5

  bool get _canSubmit =>
      _items.every((e) => e.checked) && _rating > 0 && mounted;

  Future<void> _pickFromGallery() async {
    // Try multi select first
    final multi = await _picker.pickMultiImage(imageQuality: 85);
    if (multi.isNotEmpty) {
      setState(() {
        _images.addAll(multi);
      });
      return;
    }
    // Fallback single
    final one = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (one != null) setState(() => _images.add(one));
  }

  Future<void> _pickFromCamera() async {
    final one = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (one != null) setState(() => _images.add(one));
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
              title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: kPrimary),
              title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> TaskoonApp()));
    // Replace with real API call
    // await showDialog(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Text('Submitted'),
    //     content: Text(
    //       'Rating: ${_rating.toStringAsFixed(1)}\n'
    //       'Photos: ${_images.length}\n'
    //       'Review: ${_reviewCtrl.text.isEmpty ? "(none)" : _reviewCtrl.text}',
    //     ),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
    //     ],
    //   ),
    // );
    // if (!mounted) return;
    // Navigator.maybePop(context);
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F7FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPrimary),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Task completion',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SubLabel('Refers to order:'),
            const SizedBox(height: 10),
            _OrderCard(),
            const SizedBox(height: 12),
            _TipCard(
              text:
                  'Before you leave: do a final sweep of the tools, tidy the workplace, restore utilities, and confirm handover',
            ),

            const SizedBox(height: 18),
            const _SectionTitle('Checklist:'),
            const SizedBox(height: 6),
            ..._items.map((e) => _ChecklistTile(
                  title: e.title,
                  value: e.checked,
                  onChanged: (v) => setState(() => e.checked = v ?? false),
                )),
            const SizedBox(height: 10),

            _UploadArea(
              onTap: _showPickSheet,
              children: [
                for (int i = 0; i < _images.length; i++)
                  _PhotoThumb(
                    file: _images[i],
                    onRemove: () => setState(() => _images.removeAt(i)),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            const _SectionTitle('Rate the resident'),
            const SizedBox(height: 6),
            _StarRating(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
              starColor: kPrimary,
            ),

            const SizedBox(height: 18),
            const _SectionTitle('Short review (optional)'),
            const SizedBox(height: 6),
            _RoundedField(
              controller: _reviewCtrl,
              hint: 'E.g. clear instructions, easy access',
            ),

            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: kPrimary.withOpacity(.35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('SUBMIT',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================================ Pieces ================================ */

class _OrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          _IconChip(icon: Icons.person_rounded),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tasker: Stephan Matt    ID: 464834',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: const Color(0xFFD8CFF0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconChip(icon: Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? _TaskCompletionScreenState.kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _TaskCompletionScreenState.kPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person, color: Colors.white), // keep padding
    );
  }
}

class _ChecklistItem {
  _ChecklistItem(this.title, {this.checked = false});
  final String title;
  bool checked;
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: Text(title, style: const TextStyle(height: 1.35)),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({required this.onTap, required this.children});
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: const Color(0xFFD9D2E8), width: 1.2);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.image_outlined, color: _TaskCompletionScreenState.kPrimary),
                SizedBox(width: 8),
                Text('Upload image(s)',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _TaskCompletionScreenState.kPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Container(
                height: 80,
                alignment: Alignment.center,
                child: Text('Tap to add photos',
                    style: TextStyle(color: Colors.grey.shade600)),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: children,
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 86,
            height: 86,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.value,
    required this.onChanged,
    this.starColor = Colors.amber,
    this.size = 28,
  });

  final double value; // 0..5
  final ValueChanged<double> onChanged;
  final Color starColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    // draw 5 tappable stars with half-step precision
    Widget star(int index) {
      final filled = value >= index + 1;
      final half = !filled && value > index && value < index + 1;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(d.globalPosition);
          // if tapped on left half -> half star
          final isHalf = (local.dx - index * (size + 6)) < size / 2;
          final v = isHalf ? index + 0.5 : index + 1.0;
          onChanged(v);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Stack(
            children: [
              Icon(Icons.star_border_rounded, size: size, color: starColor.withOpacity(.35)),
              if (filled)
                Icon(Icons.star_rounded, size: size, color: starColor)
              else if (half)
                Icon(Icons.star_half_rounded, size: size, color: starColor),
            ],
          ),
        ),
      );
    }

    return Row(
      children: List.generate(5, star),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F3F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _TaskCompletionScreenState.kStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _TaskCompletionScreenState.kStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _TaskCompletionScreenState.kPrimary, width: 1.4),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _TaskCompletionScreenState.kPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Colors.grey.shade700));
}
