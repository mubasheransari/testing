import 'package:flutter/material.dart';


class Field extends StatefulWidget {
  final TextEditingController? controller; // can be null
  final String? initialText; // optional seed text
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  static const Color _fieldFill = Color(0xFFF9F8FE);
  static const Color _outlineConst = Color(0xFFE6E3EF);

  const Field({
    super.key,
    required this.hint,
    this.controller,
    this.initialText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  static const _radiusLg = 20.0;
  static const _primary = Color(0xFF8E7CFF);

  // ✅ Poppins constants
  static const _fontFamily = 'Poppins';
  static const _textStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF111827),
  );
  static const _hintStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9CA3AF),
  );
  static const _errorStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  TextEditingController? _ownedController;
  TextEditingController get _ctrl => widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _ownedController = TextEditingController(text: widget.initialText ?? '');
    } else {
      if (widget.controller!.text.isEmpty && widget.initialText != null) {
        widget.controller!.text = widget.initialText!;
      }
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,

      // ✅ Poppins for typed text
      style: _textStyle,

      decoration: InputDecoration(
        hintText: widget.hint,

        // ✅ Poppins for hint + error
        hintStyle: _hintStyle,
        errorStyle: _errorStyle,

        filled: true,
        fillColor: Field._fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: Field._outlineConst),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: Field._outlineConst),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
      ),
    );
  }
}


// class Field extends StatefulWidget {
//   final TextEditingController? controller;        // can be null
//   final String? initialText;                      // optional seed text
//   final String hint;
//   final TextInputType? keyboardType;
//   final TextInputAction? textInputAction;
//   final String? Function(String?)? validator;
//   final void Function(String)? onSubmitted;

//   // Local copies of constants to use inside this widget
//   static const Color _fieldFill = Color(0xFFF9F8FE);
//   static const Color _outlineConst = Color(0xFFE6E3EF);

//   const Field({
//     super.key,
//     required this.hint,
//     this.controller,
//     this.initialText,
//     this.keyboardType,
//     this.textInputAction,
//     this.validator,
//     this.onSubmitted,
//   });

//   @override
//   State<Field> createState() => _FieldState();
// }

// class _FieldState extends State<Field> {
//   static const _radiusLg = 20.0;
//   static const _primary = Color(0xFF8E7CFF);

//   TextEditingController? _ownedController; // only if we create one
//   TextEditingController get _ctrl => widget.controller ?? _ownedController!;

//   @override
//   void initState() {
//     super.initState();

//     // If no controller provided, create one seeded with initialText (if any)
//     if (widget.controller == null) {
//       _ownedController = TextEditingController(text: widget.initialText ?? '');
//     } else {
//       // If a controller is provided, seed it once if it's empty and we have initialText
//       if ((widget.controller!.text.isEmpty) && (widget.initialText != null)) {
//         widget.controller!.text = widget.initialText!;
//       }
//     }
//   }

//   @override
//   void dispose() {
//     // Only dispose the controller we created
//     _ownedController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: _ctrl,                       // <-- always use a controller
//       keyboardType: widget.keyboardType,
//       textInputAction: widget.textInputAction,
//       onFieldSubmitted: widget.onSubmitted,
//       validator: widget.validator,
//       decoration: InputDecoration(
        
//         hintText: widget.hint,
//         filled: true,
//         fillColor: Field._fieldFill,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: Field._outlineConst),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: Field._outlineConst),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: _primary, width: 1.6),
//         ),
//       ),
//     );
//   }
// }


// class Field extends StatelessWidget {
//   final TextEditingController controller;
//   final String hint;
//   final TextInputType? keyboardType;
//   final TextInputAction? textInputAction;
//   final String? Function(String?)? validator;
//   final void Function(String)? onSubmitted;

//   static const _fill = _fieldFill;
//   static const _outline =
//       _outlineConst; // just to demonstrate constants in this scope

//   const Field({
//     required this.controller,
//     required this.hint,
//     this.keyboardType,
//     this.textInputAction,
//     this.validator,
//     this.onSubmitted,
//   });

//   // Local copies of constants to use inside this StatelessWidget
//   static const Color _fieldFill = Color(0xFFF9F8FE);
//   static const Color _outlineConst = Color(0xFFE6E3EF);

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       textInputAction: textInputAction,
//       onFieldSubmitted: onSubmitted,
//       validator: validator,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: _fill,
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: _outline),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: _outline),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(_radiusLg),
//           borderSide: const BorderSide(color: _primary, width: 1.6),
//         ),
//       ),
//     );
//   }

//   // Reuse the same radii/primary colors used above
//   static const _radiusLg = 20.0;
//   static const _primary = Color(0xFF8E7CFF);
// }