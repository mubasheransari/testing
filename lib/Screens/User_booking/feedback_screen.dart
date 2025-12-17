import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/Widgets/rating_row_widget.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // ==== Brand tokens (aligned with your other screens) ====
  static const kPurple = Color(0xFF5C2E91);
  static const kPurpleText = Color(0xFF3E1E69);
  static const kMuted = Color(0xFF75748A);
  static const kLilac = Color(0xFFF3EFFF);
  static const kLilacDark = Color(0xFFE7DAFF);
  static const kBorder = Color(0xFFCECCE0);
  static const kShadow = Color(0x14000000);

  final _reasonsCtrl = TextEditingController();
  final _wishlistCtrl = TextEditingController();

  int _rating = -1; // 0..4, -1=none
  bool _consentContact = false;
  bool _consentResearch = false;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonsCtrl.dispose();
    _wishlistCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: kMuted,
        fontSize: 13.5,
      ),
      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPurple, width: 1.7),
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating < 0) {
      _snack('Please select a rating.');
      return;
    }
    setState(() => _submitting = true);

    // Build payload (ready for your API)
    final payload = {
      "rating": _rating + 1, // 1..5
      "reasons": _reasonsCtrl.text.trim(),
      "wishlist": _wishlistCtrl.text.trim(),
      "consentContact": _consentContact,
      "consentResearch": _consentResearch,
      "submittedAt": DateTime.now().toIso8601String(),
    };

    // TODO: call your backend here
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _submitting = false);
    _snack('Thanks for your feedback!');
   // Navigator.maybePop(context);
Navigator.push(context, MaterialPageRoute(builder: (context)=> UserBottomNavBar()));
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      
        title: const Text(
          'Feedback',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: kPurple,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Heading =====
              const _BigHeading(),
              const SizedBox(height: 10),
              const Text(
                'How was your overall experience with the\nbooking and service?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: kMuted,
                  fontSize: 15.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // ===== Rating pills =====
              RatingRow(
                selected: _rating,
                onSelect: (i) => setState(() => _rating = i),
              ),
              const SizedBox(height: 26),

              // ===== Reasons =====
              const Text(
                'What are the main reasons for your rating?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.5,
                  color: kPurpleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                elevation: 6,
                shadowColor: kShadow,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: _reasonsCtrl,
                  minLines: 4,
                  maxLines: 6,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5),
                  decoration: _inputDecoration('Tell us a bit more…'),
                ),
              ),
              const SizedBox(height: 24),

              // ===== Wishlist =====
              const Text(
                'What services would you like to see\nadded in the app in future?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.5,
                  color: kPurpleText,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                elevation: 6,
                shadowColor: kShadow,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: _wishlistCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5),
                  decoration: _inputDecoration('Your suggestions…'),
                ),
              ),
              const SizedBox(height: 20),

              // ===== Consents =====
              _ConsentTile(
                value: _consentContact,
                onChanged: (v) => setState(() => _consentContact = v),
                label: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kPurpleText,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'I may be contacted for this feedback. '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                          onTap: () {
                            // TODO: open privacy policy
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: kPurple,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ConsentTile(
                value: _consentResearch,
                onChanged: (v) => setState(() => _consentResearch = v),
                label: const Text(
                  "I'd like to help improving by joining the\nResearch Group",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: kPurpleText,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ===== Buttons =====
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD3DD)),
                        foregroundColor: const Color(0xFF506070),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        elevation: 2,
                        shadowColor: kShadow,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('SUBMIT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SafeArea(top: false, child: SizedBox(height: 4)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== Widgets ===================== */

class _BigHeading extends StatelessWidget {
  const _BigHeading();

  @override
  Widget build(BuildContext context) {
    const kPurple = _FeedbackScreenState.kPurple;
    const kPurpleText = _FeedbackScreenState.kPurpleText;
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:  [
        Text(
          'Please share your\nvaluable feedback!',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: kPurpleText,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 6),
      ],
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    const kPurple = _FeedbackScreenState.kPurple;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox.adaptive(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: kPurple,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Expanded(child: label),
      ],
    );
  }
}
