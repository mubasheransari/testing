import 'package:flutter/material.dart';

class Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  static const _fill = _fieldFill;
  static const _outline =
      _outlineConst; // just to demonstrate constants in this scope

  const Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  // Local copies of constants to use inside this StatelessWidget
  static const Color _fieldFill = Color(0xFFF9F8FE);
  static const Color _outlineConst = Color(0xFFE6E3EF);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
      ),
    );
  }

  // Reuse the same radii/primary colors used above
  static const _radiusLg = 20.0;
  static const _primary = Color(0xFF8E7CFF);
}