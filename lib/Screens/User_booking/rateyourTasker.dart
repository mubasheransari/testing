import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';
import 'package:taskoon/widgets/toast_widget.dart';

class RateTaskerScreen extends StatefulWidget {
  const RateTaskerScreen({
    super.key,
    this.taskerName = 'Stephan Micheal',
    this.photoUrl,
    this.jobCode, // e.g., AU737
    this.onSubmit, // optional callback to receive payload
  });

  final String taskerName;
  final String? photoUrl;
  final String? jobCode;
  final void Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<RateTaskerScreen> createState() => _RateTaskerScreenState();
}

class _RateTaskerScreenState extends State<RateTaskerScreen> {
  // Theme
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kDeepPurple = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF6E6884);

  // Ratings
  int professionalism = 0;
  int quality = 0;
  int communication = 0;
  int overall = 0;

  final _commentsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (overall == 0) {
      _snack('Please rate Overall before submitting.');
      return;
    }
    setState(() => _submitting = true);

    final payload = {
      "jobCode": widget.jobCode,
      "taskerName": widget.taskerName,
      "ratings": {
        "professionalism": professionalism,
        "qualityOfWork": quality,
        "communication": communication,
        "overall": overall,
      },
      "comment": _commentsCtrl.text.trim(),
      "createdAt": DateTime.now().toIso8601String(),
    };

    // hand off to caller (if they want to post to API)
    widget.onSubmit?.call(payload);

    await Future.delayed(const Duration(milliseconds: 350)); // tiny UX pause
    if (!mounted) return;
    setState(() => _submitting = false);
    toastWidget('Thank you! Your feedback was submitted.', Colors.green);
    //_snack('Thank you! Your feedback was submitted.');
      Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => UserBottomNavBar()),
            (Route<dynamic> route) => false,
          );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurple, // full screen purple backdrop
      body: SafeArea(
        child: Column(
          children: [
            // ===== Top header bar (no close icon) =====
          const  Padding(
              padding:  EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  // Back arrow (optional). Remove if you push as root.
                  // IconButton(
                  //   splashRadius: 22,
                  //   icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  //   onPressed: () => Navigator.of(context).maybePop(),
                  // ),
                   SizedBox(width: 6),
                   Text(
                    'Rate your tasker',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ===== White content sheet =====
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    children: [
                      // avatar + name + code
                      _HeaderCard(
                        name: widget.taskerName,
                        jobCode: widget.jobCode,
                        photoUrl: widget.photoUrl,
                      ),
                      const SizedBox(height: 22),

                      // rating rows
                      _RatingRow(
                        label: 'Professionalism',
                        value: professionalism,
                        onChanged: (v) => setState(() => professionalism = v),
                      ),
                      const SizedBox(height: 14),
                      _RatingRow(
                        label: 'Quality of work',
                        value: quality,
                        onChanged: (v) => setState(() => quality = v),
                      ),
                      const SizedBox(height: 14),
                      _RatingRow(
                        label: 'Communication',
                        value: communication,
                        onChanged: (v) => setState(() => communication = v),
                      ),
                      const SizedBox(height: 14),
                      _RatingRow(
                        label: 'Overall',
                        value: overall,
                        onChanged: (v) => setState(() => overall = v),
                        highlight: true,
                      ),

                      const SizedBox(height: 22),

                      // comments
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Additional comments',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDeepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OutlinedField(controller: _commentsCtrl),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),

            // ===== Bottom submit bar pinned to safe area =====
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _PrimaryButton(
                text: _submitting ? 'Submitting…' : 'SUBMIT',
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== Pieces ===================== */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    this.jobCode,
    this.photoUrl,
  });

  final String name;
  final String? jobCode;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const Color kPurple = Color(0xFF5C2E91);
    const Color kDeepPurple = Color(0xFF3E1E69);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE7FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFF7F1FF),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!) as ImageProvider
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? const Icon(Icons.person, color: kPurple, size: 34)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kDeepPurple,
                  ),
                ),
                if (jobCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    jobCode!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: kPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.highlight = false,
  });

  final String label;
  final int value; // 0..5
  final ValueChanged<int> onChanged;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = highlight ? const Color(0xFF5C2E91) : const Color(0xFF3E1E69);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
        _StarBar(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _StarBar extends StatelessWidget {
  const _StarBar({required this.value, required this.onChanged, this.size = 26});
  final int value;
  final double size;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color kActive = Color(0xFFEEB54E); // warm star
    const Color kInactive = Color(0xFFC7CBD1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
          child: InkResponse(
            onTap: () => onChanged(i + 1),
            radius: size * .7,
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: filled ? kActive : kInactive,
            ),
          ),
        );
      }),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    const Color kPurple = Color(0xFF5C2E91);

    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5),
      decoration: InputDecoration(
        hintText: 'Type your comments…',
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF9EA3AE),
        ),
        filled: true,
        fillColor: const Color(0xFFFAF7FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9CFF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPurple, width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // gradient button (no extra packages)
    return Opacity(
      opacity: onPressed == null ? 0.7 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF3E1E69), Color(0xFF5C2E91)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C2E91).withOpacity(.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
