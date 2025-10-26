// lib/screens/my_account_and_edit.dart
// Drop-in screens: MyAccountScreen + EditProfileScreen with photo upload.
// Requires: image_picker: ^1.x  (you said it's already added)

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/* ================================ MODEL ================================ */

class UserProfile {
  final String? avatarPath; // local file path
  final String fullName;
  final DateTime? dob;
  final String address;

  final String bankName;
  final String accountNumberMasked; // store masked or plain per your needs
  final String bsb;
  final String abn;

  const UserProfile({
    this.avatarPath,
    required this.fullName,
    required this.dob,
    required this.address,
    required this.bankName,
    required this.accountNumberMasked,
    required this.bsb,
    required this.abn,
  });

  UserProfile copyWith({
    String? avatarPath,
    String? fullName,
    DateTime? dob,
    String? address,
    String? bankName,
    String? accountNumberMasked,
    String? bsb,
    String? abn,
  }) {
    return UserProfile(
      avatarPath: avatarPath ?? this.avatarPath,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      bankName: bankName ?? this.bankName,
      accountNumberMasked:
          accountNumberMasked ?? this.accountNumberMasked,
      bsb: bsb ?? this.bsb,
      abn: abn ?? this.abn,
    );
  }
}

/* ============================ ACCOUNT SCREEN =========================== */

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({
    super.key,
    this.bottomBar,
    this.onSignOut,
  });

  final Widget? bottomBar;
  final VoidCallback? onSignOut;

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  static const _p = Color(0xFF5C2E91);

  UserProfile profile = const UserProfile(
    avatarPath: null,
    fullName: 'Steaphan Micheal',
    dob: null,
    address: '41 block, e-street',
    bankName: 'ABC bank',
    accountNumberMasked: '**** **** 4565',
    bsb: '457',
    abn: '36 123 456 789',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      bottomNavigationBar: widget.bottomBar,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    //       color: _p),
                    //   onPressed: () => Navigator.of(context).maybePop(),
                    // ),
                    const SizedBox(width: 6),
                    const Text(
                      'My account',
                      style: TextStyle(
                        color: _p,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _SignOutPill(onTap: widget.onSignOut),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar (tap to edit profile)
                    Center(
                      child: GestureDetector(
                        onTap: () => _openEdit(),
                        child: CircleAvatar(
                          radius: 76,
                          backgroundColor: const Color(0xFFDADADA),
                          backgroundImage: profile.avatarPath != null
                              ? FileImage(File(profile.avatarPath!))
                              : null,
                          child: profile.avatarPath == null
                              ? Icon(Icons.person_rounded,
                                  size: 82, color: Colors.white.withOpacity(.95))
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: _p,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    const _SectionLabel('Personal information'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Full name:', value: profile.fullName),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Date of birth:',
                      value: profile.dob != null
                          ? _fmtDate(profile.dob!)
                          : '—',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Address:',
                      value: profile.address,
                      trailing: _EditButton(onTap: _openEdit),
                    ),
                    const SizedBox(height: 28),

                    const _SectionLabel('Bank details'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Bank name:', value: profile.bankName),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Account No.:',
                      value: profile.accountNumberMasked,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'BSB code:',
                      value: profile.bsb,
                      trailing: _EditButton(onTap: _openEdit),
                    ),
                    const SizedBox(height: 28),

                    const _SectionLabel('ABN/ Business information'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'ABN No:', value: profile.abn),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initial: profile),
      ),
    );
    if (updated != null) {
      setState(() => profile = updated);
    }
  }

  static String _fmtDate(DateTime d) {
    // Simple readable format; replace with intl if desired
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
    }
}

/* ============================= EDIT PROFILE ============================= */

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.initial});
  final UserProfile initial;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _p = Color(0xFF5C2E91);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _address;
  late TextEditingController _bank;
  late TextEditingController _account;
  late TextEditingController _bsb;
  late TextEditingController _abn;

  DateTime? _dob;
  String? _avatarPath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i.fullName);
    _address = TextEditingController(text: i.address);
    _bank = TextEditingController(text: i.bankName);
    _account = TextEditingController(text: i.accountNumberMasked);
    _bsb = TextEditingController(text: i.bsb);
    _abn = TextEditingController(text: i.abn);
    _dob = i.dob;
    _avatarPath = i.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _bank.dispose();
    _account.dispose();
    _bsb.dispose();
    _abn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _p),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Edit profile',
                      style: TextStyle(
                        color: _p,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _save,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _p,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar picker
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 72,
                            backgroundColor: const Color(0xFFDADADA),
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? Icon(Icons.person_rounded,
                                    size: 78,
                                    color: Colors.white.withOpacity(.95))
                                : null,
                          ),
                          _SmallIconButton(
                            icon: Icons.photo_camera_rounded,
                            onTap: _pickAvatar,
                          )
                        ],
                      ),
                      const SizedBox(height: 22),

                      _GlassField(
                        label: 'Full name',
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // DOB
                      _GlassField(
                        label: 'Date of birth',
                        controller: TextEditingController(
                            text: _dob != null
                                ? _fmtDate(_dob!)
                                : ''),
                        readOnly: true,
                        onTap: _pickDob,
                        suffix: const Icon(Icons.calendar_month_rounded,
                            color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      _GlassField(
                        label: 'Address',
                        controller: _address,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 22),

                      // BANK SECTION
                      _GlassSectionLabel('Bank details'),
                      const SizedBox(height: 10),

                      _GlassField(
                        label: 'Bank name',
                        controller: _bank,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _GlassField(
                        label: 'Account No.',
                        controller: _account,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _GlassField(
                        label: 'BSB code',
                        controller: _bsb,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 22),

                      _GlassSectionLabel('ABN / Business information'),
                      const SizedBox(height: 10),
                      _GlassField(
                        label: 'ABN',
                        controller: _abn,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickSourceSheet(),
    );
    if (source == null) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1400,
    );
    if (file != null) {
      setState(() => _avatarPath = file.path);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 90);
    final last = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) {
        // rounded dialog
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5C2E91),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.initial.copyWith(
      avatarPath: _avatarPath,
      fullName: _name.text.trim(),
      address: _address.text.trim(),
      bankName: _bank.text.trim(),
      accountNumberMasked: _account.text.trim(),
      bsb: _bsb.text.trim(),
      abn: _abn.text.trim(),
      dob: _dob,
    );

    Navigator.pop(context, updated);
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}

/* =============================== WIDGETS ================================ */

class _SignOutPill extends StatelessWidget {
  const _SignOutPill({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: const Color(0xFFF2F2F7),
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                'Sign out',
                style: TextStyle(
                  color: Color(0xFF5E6272),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return const Text(
      '',
      // kept for layout compatibility—no visible header here
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.black.withOpacity(.62),
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
    );
    const valueStyle = TextStyle(
      color: Color(0xFF28303D),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: '$label ', style: labelStyle),
                TextSpan(text: value, style: valueStyle),
              ],
            ),
          ),
        ),
        if (trailing != null) const SizedBox(width: 8),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE9E5F2)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(Icons.edit_rounded,
              size: 20, color: Color(0xFF5C2E91)),
        ),
      ),
    );
  }
}

/* --------- Pretty glassy text fields / labels for the edit screen -------- */

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9E5F2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE9E5F2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF5C2E91), width: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSectionLabel extends StatelessWidget {
  const _GlassSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5C2E91),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5C2E91),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.photo_camera_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

/* --------------------------- Image source sheet -------------------------- */

class _PickSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Divider(height: 1),
            _SheetTile(
              icon: Icons.photo_camera_rounded,
              label: 'Take a photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5C2E91)),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minLeadingWidth: 0,
      horizontalTitleGap: 12,
    );
  }
}



// // lib/screens/my_account_screen.dart
// import 'dart:ui';
// import 'package:flutter/material.dart';

// class MyAccountScreen extends StatelessWidget {
//   const MyAccountScreen({
//     super.key,
//     this.onBack,
//     this.onSignOut,
//     this.onEditPersonal,
//     this.onEditBank,
//     this.bottomBar, // pass your global bottom nav here if needed
//   });

//   final VoidCallback? onBack;
//   final VoidCallback? onSignOut;
//   final VoidCallback? onEditPersonal;
//   final VoidCallback? onEditBank;
//   final Widget? bottomBar;

//   static const _p = _AppColors.primary;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F7FB),
//       bottomNavigationBar: bottomBar,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.06),
//                       blurRadius: 18,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     // IconButton(
//                     //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                     //       color: _p),
//                     //   onPressed: onBack ?? () => Navigator.of(context).maybePop(),
//                     // ),
//                     const SizedBox(width: 6),
//                     const Text(
//                       'My account',
//                       style: TextStyle(
//                         color: _p,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const Spacer(),
//                     _SignOutPill(onTap: onSignOut),
//                   ],
//                 ),
//               ),
//             ),

//             // Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
//                 physics: const BouncingScrollPhysics(),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Avatar
//                     Center(
//                       child: CircleAvatar(
//                         radius: 76,
//                         backgroundColor: const Color(0xFFDADADA),
//                         child: Icon(Icons.person_rounded,
//                             size: 82, color: Colors.white.withOpacity(.95)),
//                       ),
//                     ),
//                     const SizedBox(height: 28),

//                     // Profile title
//                     const Text(
//                       'Profile',
//                       style: TextStyle(
//                         color: _p,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: .2,
//                       ),
//                     ),
//                     const SizedBox(height: 18),

//                     // PERSONAL
//                     const _SectionLabel('Personal information'),
//                     const SizedBox(height: 8),
//                     const _InfoRow(label: 'Full name:', value: 'Steaphan Micheal'),
//                     const SizedBox(height: 14),
//                     const _InfoRow(
//                         label: 'Date of birth:', value: '22 January, 1998'),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'Address:',
//                       value: '41 block, e-street',
//                       trailing: _EditButton(onTap: onEditPersonal),
//                     ),

//                     const SizedBox(height: 28),

//                     // BANK
//                     const _SectionLabel('Bank details'),
//                     const SizedBox(height: 8),
//                     const _InfoRow(label: 'Bank name:', value: 'ABC bank'),
//                     const SizedBox(height: 14),
//                     const _InfoRow(
//                         label: 'Account No.:', value: '**** **** 4565'),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'BSB code:',
//                       value: '457',
//                       trailing: _EditButton(onTap: onEditBank),
//                     ),

//                     const SizedBox(height: 28),

//                     // ABN
//                     const _SectionLabel('ABN/ Business information'),
//                     const SizedBox(height: 8),
//                     const _InfoRow(label: 'ABN No:', value: '36 123 456 789'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ------------------------------ Header pill ----------------------------- */

// class _SignOutPill extends StatelessWidget {
//   const _SignOutPill({this.onTap});
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Material(
//           color: const Color(0xFFF2F2F7),
//           child: InkWell(
//             onTap: onTap,
//             child: const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//               child: Text(
//                 'Sign out',
//                 style: TextStyle(
//                   color: Color(0xFF5E6272),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ------------------------------- Sections -------------------------------- */

// class _SectionLabel extends StatelessWidget {
//   const _SectionLabel(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: const TextStyle(
//         color: _AppColors.primary,
//         fontWeight: FontWeight.w800,
//         fontSize: 16,
//       ),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   const _InfoRow({
//     required this.label,
//     required this.value,
//     this.trailing,
//   });

//   final String label;
//   final String value;
//   final Widget? trailing;

//   @override
//   Widget build(BuildContext context) {
//     final labelStyle = TextStyle(
//       color: Colors.black.withOpacity(.62),
//       fontWeight: FontWeight.w700,
//       letterSpacing: .2,
//     );
//     const valueStyle = TextStyle(
//       color: Color(0xFF28303D),
//       fontSize: 18,
//       fontWeight: FontWeight.w600,
//     );

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: RichText(
//             text: TextSpan(
//               style: DefaultTextStyle.of(context).style,
//               children: [
//                 TextSpan(text: '$label ', style: labelStyle),
//                 TextSpan(text: value, style: valueStyle),
//               ],
//             ),
//           ),
//         ),
//         if (trailing != null) const SizedBox(width: 8),
//         trailing ?? const SizedBox.shrink(),
//       ],
//     );
//   }
// }

// class _EditButton extends StatelessWidget {
//   const _EditButton({this.onTap});
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 38,
//       height: 38,
//       child: Material(
//         color: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: const BorderSide(color: Color(0xFFE9E5F2)),
//         ),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: const Icon(Icons.edit_rounded,
//               size: 20, color: _AppColors.primary),
//         ),
//       ),
//     );
//   }
// }

// /* --------------------------------- THEME -------------------------------- */

// class _AppColors {
//   static const primary = Color(0xFF5C2E91);
// }
