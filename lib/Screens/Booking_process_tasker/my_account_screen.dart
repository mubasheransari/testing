// lib/screens/my_account_and_edit.dart
// Drop-in screens: MyAccountScreen + EditProfileScreen with photo upload.
// Requires: image_picker: ^1.x  (you said it's already added)

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/* ================================ MODEL ================================ */

// class UserProfile {
//   final String? avatarPath; // local file path
//   final String fullName;
//   final DateTime? dob;
//   final String address;

//   final String bankName;
//   final String accountNumberMasked; // store masked or plain per your needs
//   final String bsb;
//   final String abn;

//   const UserProfile({
//     this.avatarPath,
//     required this.fullName,
//     required this.dob,
//     required this.address,
//     required this.bankName,
//     required this.accountNumberMasked,
//     required this.bsb,
//     required this.abn,
//   });

//   UserProfile copyWith({
//     String? avatarPath,
//     String? fullName,
//     DateTime? dob,
//     String? address,
//     String? bankName,
//     String? accountNumberMasked,
//     String? bsb,
//     String? abn,
//   }) {
//     return UserProfile(
//       avatarPath: avatarPath ?? this.avatarPath,
//       fullName: fullName ?? this.fullName,
//       dob: dob ?? this.dob,
//       address: address ?? this.address,
//       bankName: bankName ?? this.bankName,
//       accountNumberMasked:
//           accountNumberMasked ?? this.accountNumberMasked,
//       bsb: bsb ?? this.bsb,
//       abn: abn ?? this.abn,
//     );
//   }
// }

// /* ============================ ACCOUNT SCREEN =========================== */

// class MyAccountScreen extends StatefulWidget {
//   const MyAccountScreen({
//     super.key,
//     this.bottomBar,
//     this.onSignOut,
//   });

//   final Widget? bottomBar;
//   final VoidCallback? onSignOut;

//   @override
//   State<MyAccountScreen> createState() => _MyAccountScreenState();
// }

// class _MyAccountScreenState extends State<MyAccountScreen> {
//   static const _p = Color(0xFF5C2E91);

//   UserProfile profile = const UserProfile(
//     avatarPath: null,
//     fullName: 'Steaphan Micheal',
//     dob: null,
//     address: '41 block, e-street',
//     bankName: 'ABC bank',
//     accountNumberMasked: '**** **** 4565',
//     bsb: '457',
//     abn: '36 123 456 789',
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F7FB),
//       bottomNavigationBar: widget.bottomBar,
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
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                           color: _p),
//                       onPressed: () => Navigator.of(context).maybePop(),
//                     ),
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
//                     _SignOutPill(onTap: widget.onSignOut),
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
//                     // Avatar (tap to edit profile)
//                     Center(
//                       child: GestureDetector(
//                         onTap: () => _openEdit(),
//                         child: CircleAvatar(
//                           radius: 76,
//                           backgroundColor: const Color(0xFFDADADA),
//                           backgroundImage: profile.avatarPath != null
//                               ? FileImage(File(profile.avatarPath!))
//                               : null,
//                           child: profile.avatarPath == null
//                               ? Icon(Icons.person_rounded,
//                                   size: 82, color: Colors.white.withOpacity(.95))
//                               : null,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 28),

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

//                     const _SectionLabel('Personal information'),
//                     const SizedBox(height: 8),
//                     _InfoRow(label: 'Full name:', value: profile.fullName),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'Date of birth:',
//                       value: profile.dob != null
//                           ? _fmtDate(profile.dob!)
//                           : '—',
//                     ),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'Address:',
//                       value: profile.address,
//                       trailing: _EditButton(onTap: _openEdit),
//                     ),
//                     const SizedBox(height: 28),

//                     const _SectionLabel('Bank details'),
//                     const SizedBox(height: 8),
//                     _InfoRow(label: 'Bank name:', value: profile.bankName),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'Account No.:',
//                       value: profile.accountNumberMasked,
//                     ),
//                     const SizedBox(height: 14),
//                     _InfoRow(
//                       label: 'BSB code:',
//                       value: profile.bsb,
//                       trailing: _EditButton(onTap: _openEdit),
//                     ),
//                     const SizedBox(height: 28),

//                     const _SectionLabel('ABN/ Business information'),
//                     const SizedBox(height: 8),
//                     _InfoRow(label: 'ABN No:', value: profile.abn),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _openEdit() async {
//     final updated = await Navigator.push<UserProfile>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => EditProfileScreen(initial: profile),
//       ),
//     );
//     if (updated != null) {
//       setState(() => profile = updated);
//     }
//   }

//   static String _fmtDate(DateTime d) {
//     // Simple readable format; replace with intl if desired
//     const months = [
//       'January','February','March','April','May','June',
//       'July','August','September','October','November','December'
//     ];
//     return '${d.day} ${months[d.month - 1]}, ${d.year}';
//     }
// }

// /* ============================= EDIT PROFILE ============================= */

// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({super.key, required this.initial});
//   final UserProfile initial;

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   static const _p = Color(0xFF5C2E91);

//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _name;
//   late TextEditingController _address;
//   late TextEditingController _bank;
//   late TextEditingController _account;
//   late TextEditingController _bsb;
//   late TextEditingController _abn;

//   DateTime? _dob;
//   String? _avatarPath;

//   final _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     final i = widget.initial;
//     _name = TextEditingController(text: i.fullName);
//     _address = TextEditingController(text: i.address);
//     _bank = TextEditingController(text: i.bankName);
//     _account = TextEditingController(text: i.accountNumberMasked);
//     _bsb = TextEditingController(text: i.bsb);
//     _abn = TextEditingController(text: i.abn);
//     _dob = i.dob;
//     _avatarPath = i.avatarPath;
//   }

//   @override
//   void dispose() {
//     _name.dispose();
//     _address.dispose();
//     _bank.dispose();
//     _account.dispose();
//     _bsb.dispose();
//     _abn.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F7FB),
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
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                           color: _p),
//                       onPressed: () => Navigator.of(context).maybePop(),
//                     ),
//                     const SizedBox(width: 6),
//                     const Text(
//                       'Edit profile',
//                       style: TextStyle(
//                         color: _p,
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const Spacer(),
//                     TextButton(
//                       onPressed: _save,
//                       style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         backgroundColor: _p,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: const Text('Save',
//                           style: TextStyle(fontWeight: FontWeight.w800)),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Form
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
//                 physics: const BouncingScrollPhysics(),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       // Avatar picker
//                       Stack(
//                         alignment: Alignment.bottomRight,
//                         children: [
//                           CircleAvatar(
//                             radius: 72,
//                             backgroundColor: const Color(0xFFDADADA),
//                             backgroundImage: _avatarPath != null
//                                 ? FileImage(File(_avatarPath!))
//                                 : null,
//                             child: _avatarPath == null
//                                 ? Icon(Icons.person_rounded,
//                                     size: 78,
//                                     color: Colors.white.withOpacity(.95))
//                                 : null,
//                           ),
//                           _SmallIconButton(
//                             icon: Icons.photo_camera_rounded,
//                             onTap: _pickAvatar,
//                           )
//                         ],
//                       ),
//                       const SizedBox(height: 22),

//                       _GlassField(
//                         label: 'Full name',
//                         controller: _name,
//                         textInputAction: TextInputAction.next,
//                         validator: (v) =>
//                             v == null || v.trim().isEmpty ? 'Required' : null,
//                       ),
//                       const SizedBox(height: 12),

//                       // DOB
//                       _GlassField(
//                         label: 'Date of birth',
//                         controller: TextEditingController(
//                             text: _dob != null
//                                 ? _fmtDate(_dob!)
//                                 : ''),
//                         readOnly: true,
//                         onTap: _pickDob,
//                         suffix: const Icon(Icons.calendar_month_rounded,
//                             color: Colors.black54),
//                       ),
//                       const SizedBox(height: 12),

//                       _GlassField(
//                         label: 'Address',
//                         controller: _address,
//                         textInputAction: TextInputAction.next,
//                       ),
//                       const SizedBox(height: 22),

//                       // BANK SECTION
//                       _GlassSectionLabel('Bank details'),
//                       const SizedBox(height: 10),

//                       _GlassField(
//                         label: 'Bank name',
//                         controller: _bank,
//                         textInputAction: TextInputAction.next,
//                       ),
//                       const SizedBox(height: 12),
//                       _GlassField(
//                         label: 'Account No.',
//                         controller: _account,
//                         keyboardType: TextInputType.number,
//                         textInputAction: TextInputAction.next,
//                       ),
//                       const SizedBox(height: 12),
//                       _GlassField(
//                         label: 'BSB code',
//                         controller: _bsb,
//                         keyboardType: TextInputType.number,
//                         textInputAction: TextInputAction.next,
//                       ),
//                       const SizedBox(height: 22),

//                       _GlassSectionLabel('ABN / Business information'),
//                       const SizedBox(height: 10),
//                       _GlassField(
//                         label: 'ABN',
//                         controller: _abn,
//                         keyboardType: TextInputType.number,
//                       ),
//                       const SizedBox(height: 36),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _pickAvatar() async {
//     final source = await showModalBottomSheet<ImageSource?>(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _PickSourceSheet(),
//     );
//     if (source == null) return;

//     final XFile? file = await _picker.pickImage(
//       source: source,
//       imageQuality: 90,
//       maxWidth: 1400,
//     );
//     if (file != null) {
//       setState(() => _avatarPath = file.path);
//     }
//   }

//   Future<void> _pickDob() async {
//     final now = DateTime.now();
//     final first = DateTime(now.year - 90);
//     final last = DateTime(now.year - 16, now.month, now.day);
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _dob ?? DateTime(now.year - 25),
//       firstDate: first,
//       lastDate: last,
//       builder: (ctx, child) {
//         // rounded dialog
//         return Theme(
//           data: Theme.of(ctx).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF5C2E91),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() => _dob = picked);
//     }
//   }

//   void _save() {
//     if (!_formKey.currentState!.validate()) return;

//     final updated = widget.initial.copyWith(
//       avatarPath: _avatarPath,
//       fullName: _name.text.trim(),
//       address: _address.text.trim(),
//       bankName: _bank.text.trim(),
//       accountNumberMasked: _account.text.trim(),
//       bsb: _bsb.text.trim(),
//       abn: _abn.text.trim(),
//       dob: _dob,
//     );

//     Navigator.pop(context, updated);
//   }

//   static String _fmtDate(DateTime d) {
//     const months = [
//       'January','February','March','April','May','June',
//       'July','August','September','October','November','December'
//     ];
//     return '${d.day} ${months[d.month - 1]}, ${d.year}';
//   }
// }

// /* =============================== WIDGETS ================================ */

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

// class _SectionLabel extends StatelessWidget {
//   const _SectionLabel(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return const Text(
//       '',
//       // kept for layout compatibility—no visible header here
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
//               size: 20, color: Color(0xFF5C2E91)),
//         ),
//       ),
//     );
//   }
// }

// /* --------- Pretty glassy text fields / labels for the edit screen -------- */

// class _GlassField extends StatelessWidget {
//   const _GlassField({
//     required this.label,
//     required this.controller,
//     this.keyboardType,
//     this.textInputAction,
//     this.validator,
//     this.readOnly = false,
//     this.onTap,
//     this.suffix,
//   });

//   final String label;
//   final TextEditingController controller;
//   final TextInputType? keyboardType;
//   final TextInputAction? textInputAction;
//   final String? Function(String?)? validator;
//   final bool readOnly;
//   final VoidCallback? onTap;
//   final Widget? suffix;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//         child: TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           textInputAction: textInputAction,
//           validator: validator,
//           readOnly: readOnly,
//           onTap: onTap,
//           decoration: InputDecoration(
//             labelText: label,
//             filled: true,
//             fillColor: Colors.white,
//             suffixIcon: suffix,
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: Color(0xFFE9E5F2)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: Color(0xFFE9E5F2)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide:
//                   const BorderSide(color: Color(0xFF5C2E91), width: 1.6),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _GlassSectionLabel extends StatelessWidget {
//   const _GlassSectionLabel(this.text);
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Color(0xFF5C2E91),
//           fontSize: 16,
//           fontWeight: FontWeight.w800,
//         ),
//       ),
//     );
//   }
// }

// class _SmallIconButton extends StatelessWidget {
//   const _SmallIconButton({required this.icon, this.onTap});
//   final IconData icon;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: const Color(0xFF5C2E91),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14),
//         child: const SizedBox(
//           width: 42,
//           height: 42,
//           child: Icon(Icons.photo_camera_rounded, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

// /* --------------------------- Image source sheet -------------------------- */

// class _PickSourceSheet extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         margin: const EdgeInsets.all(12),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.12),
//               blurRadius: 22,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _SheetTile(
//               icon: Icons.photo_library_rounded,
//               label: 'Choose from gallery',
//               onTap: () => Navigator.pop(context, ImageSource.gallery),
//             ),
//             const Divider(height: 1),
//             _SheetTile(
//               icon: Icons.photo_camera_rounded,
//               label: 'Take a photo',
//               onTap: () => Navigator.pop(context, ImageSource.camera),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SheetTile extends StatelessWidget {
//   const _SheetTile({required this.icon, required this.label, this.onTap});
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Icon(icon, color: const Color(0xFF5C2E91)),
//       title: Text(
//         label,
//         style: const TextStyle(fontWeight: FontWeight.w700),
//       ),
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 8),
//       minLeadingWidth: 0,
//       horizontalTitleGap: 12,
//     );
//   }
// }

// ✅ Redesigned MyAccount + EditProfile (same theme as your UserBookingHome / MoreScreen)
// - Poppins everywhere
// - Same functionality (edit, save, avatar pick, dob picker, signout callback)
// - Modern clean cards, section headers, no blank section label bug
// - Better spacing + consistent shadows/borders

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/* ============================ MODEL ============================ */

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
      accountNumberMasked: accountNumberMasked ?? this.accountNumberMasked,
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
  static const _p = _AppColors.primary;

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
      backgroundColor: const Color(0xFFF7F6FB),
      bottomNavigationBar: widget.bottomBar,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ✅ Header (same style family as your latest screens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeaderCard(
                title: 'My account',
                left: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _p),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                right: _HeaderPill(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  onTap: widget.onSignOut,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ✅ Profile hero card
                    _WhiteCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _AvatarEditable(
                              path: profile.avatarPath,
                              onTap: _openEdit,
                              radius: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: Color(0xFF3E1E69),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      color: Color(0xFF75748A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _MiniAction(
                              icon: Icons.edit_rounded,
                              onTap: _openEdit,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Personal
                    _SectionTitle(
                      title: 'Personal information',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoLine(label: 'Full name', value: profile.fullName),
                        const SizedBox(height: 12),
                        _InfoLine(
                          label: 'Date of birth',
                          value: profile.dob != null ? _fmtDate(profile.dob!) : '—',
                        ),
                        const SizedBox(height: 12),
                        _InfoLine(label: 'Address', value: profile.address),
                        const SizedBox(height: 14),
                        _PrimaryButton(
                          label: 'Edit personal info',
                          icon: Icons.edit_rounded,
                          onTap: _openEdit,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ✅ Bank
                    _SectionTitle(
                      title: 'Bank details',
                      icon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoLine(label: 'Bank name', value: profile.bankName),
                        const SizedBox(height: 12),
                        _InfoLine(
                          label: 'Account No.',
                          value: profile.accountNumberMasked,
                        ),
                        const SizedBox(height: 12),
                        _InfoLine(label: 'BSB code', value: profile.bsb),
                        const SizedBox(height: 14),
                        _PrimaryButton(
                          label: 'Edit bank details',
                          icon: Icons.edit_rounded,
                          onTap: _openEdit,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ✅ ABN
                    _SectionTitle(
                      title: 'ABN / Business information',
                      icon: Icons.business_center_rounded,
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoLine(label: 'ABN No.', value: profile.abn),
                        const SizedBox(height: 14),
                        _PrimaryButton(
                          label: 'Edit business info',
                          icon: Icons.edit_rounded,
                          onTap: _openEdit,
                        ),
                      ],
                    ),
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
    if (updated != null) setState(() => profile = updated);
  }

  static String _fmtDate(DateTime d) {
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
  static const _p = _AppColors.primary;

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
    final dobText = _dob != null ? _fmtDate(_dob!) : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ✅ Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HeaderCard(
                title: 'Edit profile',
                left: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _p),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                right: _HeaderPill(
                  label: 'Save',
                  icon: Icons.check_rounded,
                  onTap: _save,
                  filled: true,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _WhiteCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    _AvatarEditable(
                                      path: _avatarPath,
                                      onTap: _pickAvatar,
                                      radius: 46,
                                    ),
                                    _MiniAction(
                                      icon: Icons.photo_camera_rounded,
                                      onTap: _pickAvatar,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Tap to change photo',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF75748A).withOpacity(.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _SectionTitle(
                        title: 'Personal information',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 10),

                      _WhiteCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _Field(
                                label: 'Full name',
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: 'Date of birth',
                                controller: TextEditingController(text: dobText),
                                readOnly: true,
                                onTap: _pickDob,
                                suffix: const Icon(Icons.calendar_month_rounded,
                                    color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: 'Address',
                                controller: _address,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _SectionTitle(
                        title: 'Bank details',
                        icon: Icons.account_balance_rounded,
                      ),
                      const SizedBox(height: 10),

                      _WhiteCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _Field(
                                label: 'Bank name',
                                controller: _bank,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: 'Account No.',
                                controller: _account,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: 'BSB code',
                                controller: _bsb,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _SectionTitle(
                        title: 'ABN / Business information',
                        icon: Icons.business_center_rounded,
                      ),
                      const SizedBox(height: 10),

                      _WhiteCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: _Field(
                            label: 'ABN',
                            controller: _abn,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ bottom save button (optional, but feels premium)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _p,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: _p.withOpacity(.25),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _save,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
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
      builder: (_) => const _PickSourceSheet(),
    );
    if (source == null) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1400,
    );

    if (file != null) setState(() => _avatarPath = file.path);
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
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _p),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _dob = picked);
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

/* =============================== UI KIT ================================ */

class _AppColors {
  static const primary = Color(0xFF5C2E91);
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.left,
    required this.right,
  });

  final String title;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.primary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          left,
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF3E1E69),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          right,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.icon,
    this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? _AppColors.primary : _AppColors.primary.withOpacity(.08);
    final fg = filled ? Colors.white : _AppColors.primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AppColors.primary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: _AppColors.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            color: Color(0xFF3E1E69),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              color: Color(0xFF3E1E69),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: _AppColors.primary.withOpacity(.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: _AppColors.primary,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.primary.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: _AppColors.primary),
        ),
      ),
    );
  }
}

class _AvatarEditable extends StatelessWidget {
  const _AvatarEditable({
    required this.path,
    required this.onTap,
    required this.radius,
  });

  final String? path;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFDADADA),
        backgroundImage: (path != null && path!.isNotEmpty) ? FileImage(File(path!)) : null,
        child: (path == null || path!.isEmpty)
            ? Icon(Icons.person_rounded, size: radius * 1.15, color: Colors.white.withOpacity(.95))
            : null,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF75748A),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _AppColors.primary.withOpacity(.55), width: 1.6),
        ),
      ),
    );
  }
}

/* --------------------------- Image source sheet -------------------------- */

class _PickSourceSheet extends StatelessWidget {
  const _PickSourceSheet();

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
      leading: Icon(icon, color: _AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: Color(0xFF3E1E69),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minLeadingWidth: 0,
      horizontalTitleGap: 12,
    );
  }
}

