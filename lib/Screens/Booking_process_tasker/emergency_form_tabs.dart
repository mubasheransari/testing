// emergency_form_tabs.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// class EmergencyFormTabsScreen extends StatefulWidget {
//   const EmergencyFormTabsScreen({
//     super.key,
//     this.taskerName = 'Stephan Matt',
//     this.orderId = '464834',
//     this.dateLabel = '10.08.2025 10.19',
//     this.elapsed = '00:55',
//   });

//   final String taskerName;
//   final String orderId;
//   final String dateLabel;
//   final String elapsed;

//   @override
//   State<EmergencyFormTabsScreen> createState() =>
//       _EmergencyFormTabsScreenState();
// }

// class _EmergencyFormTabsScreenState extends State<EmergencyFormTabsScreen> {
//   static const kPrimary = Color(0xFF5C2E91);

//   final ImagePicker _picker = ImagePicker();

//   bool _pauseTimer = false;

//   // ------- Hazard tab state -------
//   final Set<String> _hazardTags = {};
//   String? _riskLikelihood;
//   String? _riskConsequence;
//   final TextEditingController _hazardDesc = TextEditingController();
//   final List<XFile> _hazardPhotos = <XFile>[];
//   XFile? _hazardVideo;

//   // ------- Incident tab state (sample) -------
//   String? _incidentType;
//   bool _involveCustomer = false;
//   bool _involveThirdParty = false;
//   String? _injuryPart;
//   String? _injuryNature;
//   bool _firstAid = false;
//   bool _notifiable = false;

//   // ------- Dispute tab state -------
//   String? _disputeReason;
//   String? _disputeOutcome;
//   final TextEditingController _disputeEvidence = TextEditingController();
//   final TextEditingController _customerNote = TextEditingController();
//   final List<XFile> _disputePhotos = <XFile>[];
//   XFile? _disputeVideo;

//   // ----------------- media pickers -----------------
//   Future<void> _pickPhotos(List<XFile> targetList) async {
//     final imgs = await _picker.pickMultiImage(
//       imageQuality: 85,
//       maxWidth: 2200,
//     );
//     if (imgs.isNotEmpty) {
//       setState(() => targetList.addAll(imgs));
//     }
//   }

//   Future<void> _pickVideo(bool fromCamera, ValueChanged<XFile?> setVideo) async {
//     final video = await _picker.pickVideo(
//       source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//       maxDuration: const Duration(minutes: 10),
//     );
//     if (video != null) {
//       setState(() => setVideo(video));
//     }
//   }

//   void _removePhotoAt(List<XFile> list, int index) {
//     setState(() => list.removeAt(index));
//   }

//   void _removeVideo(ValueChanged<XFile?> setVideo) {
//     setState(() => setVideo(null));
//   }

//   // -------------------------------------------------
//   void _onSOS() {}
//   void _onSupport() {}
//   void _submit() {}

//   @override
//   Widget build(BuildContext context) {
//     final bg = Theme.of(context).brightness == Brightness.dark
//         ? const Color(0xFF0F0F12)
//         : const Color(0xFFF8F7FB);

//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: DefaultTabController(
//           length: 3,
//           child: NestedScrollView(
//             headerSliverBuilder: (_, __) => [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 1, 12, 8),
//                   child: _GlassBox(
//                     child: Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                               color: kPrimary),
//                           onPressed: () => Navigator.of(context).maybePop(),
//                         ),
//                         const SizedBox(width: 6),
//                         const Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Emergency1',
//                                   style: TextStyle(
//                                     color: kPrimary,
//                                     fontSize: 26,
//                                     fontWeight: FontWeight.w800,
//                                   )),
//                               SizedBox(height: 2),
//                               Text('Refers to order:',
//                                   style: TextStyle(
//                                     color: Colors.black54,
//                                     fontWeight: FontWeight.w600,
//                                   )),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
//                   child: Column(
//                     children: [
//                       _InfoCard(
//                         name: widget.taskerName,
//                         id: widget.orderId,
//                         date: widget.dateLabel,
//                         elapsed: widget.elapsed,
//                       ),
//                       const SizedBox(height: 12),
//                       _GlassBox(
//                         child: Row(
//                           children: [
//                             const Expanded(
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 12),
//                                 child: Text(
//                                   'Safety first – the task timer is\npaused while this form is open.',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w800,
//                                     color: kPrimary,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Checkbox(
//                               value: _pauseTimer,
//                               onChanged: (v) =>
//                                   setState(() => _pauseTimer = v ?? false),
//                               side: const BorderSide(color: kPrimary),
//                               activeColor: kPrimary,
//                             ),
//                             const Text('Pause',
//                                 style: TextStyle(
//                                     color: Colors.black54,
//                                     fontWeight: FontWeight.w700)),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _PrimaryPill(
//                               label: 'SOS',
//                               bg: const Color(0xFFE74C3C),
//                               onTap: _onSOS,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _PrimaryPill(
//                               label: 'CALL SUPPORT',
//                               onTap: _onSupport,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ),
//               SliverPersistentHeader(
//                 pinned: true,
//                 delegate: _PinnedTabBar(
//                   child: const TabBar(
//                     labelStyle: TextStyle(
//                       color: kPrimary,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 18,
//                     ),
//                     unselectedLabelStyle: TextStyle(
//                       color: Colors.black54,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     indicatorColor: kPrimary,
//                     indicatorWeight: 3,
//                     labelColor: kPrimary,
//                     unselectedLabelColor: Colors.black54,
//                     tabs: [
//                       Tab(text: 'Hazard'),
//                       Tab(text: 'Incident'),
//                       Tab(text: 'Dispute'),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             body: TabBarView(
//               children: [
//                 // ------------------- HAZARD -------------------
//                 _TabScroll(
//                   children: [
//                     const _SectionTitle('What\'s the hazard?'),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: const [
//                         'Entry issue',
//                         'Aggressive person/animal',
//                         'Height/roof',
//                         'Gas/chemical/odor',
//                         'Asbestos (suspected)',
//                         'Other',
//                       ].map((t) {
//                         return StatefulBuilder(
//                           builder: (context, setSB) {
//                             final selected = _hazardTags.contains(t);
//                             return _ChipToggle(
//                               label: t,
//                               selected: selected,
//                               onTap: () {
//                                 setState(() {
//                                   selected
//                                       ? _hazardTags.remove(t)
//                                       : _hazardTags.add(t);
//                                 });
//                                 setSB(() {});
//                               },
//                             );
//                           },
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(height: 8),
//                     const _SectionTitle('Risk rating'),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _AppDropdown<String>(
//                             hint: 'Likelihood',
//                             value: _riskLikelihood,
//                             items: const [
//                               'Rare',
//                               'Unlikely',
//                               'Possible',
//                               'Likely',
//                               'Almost certain'
//                             ],
//                             onChanged: (v) => setState(() {
//                               _riskLikelihood = v;
//                             }),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _AppDropdown<String>(
//                             hint: 'Consequence',
//                             value: _riskConsequence,
//                             items: const [
//                               'Insignificant',
//                               'Minor',
//                               'Moderate',
//                               'Major',
//                               'Severe'
//                             ],
//                             onChanged: (v) => setState(() {
//                               _riskConsequence = v;
//                             }),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     const _SectionTitle('Evidence'),
//                     _BigInput(
//                       controller: _hazardDesc,
//                       hint: 'Describe the hazards and control taken',
//                     ),
//                     const SizedBox(height: 6),
//                     _MediaPickerBar(
//                       photos: _hazardPhotos,
//                       video: _hazardVideo,
//                       onPickPhotos: () => _pickPhotos(_hazardPhotos),
//                       onPickVideoFromGallery: () =>
//                           _pickVideo(false, (v) => _hazardVideo = v),
//                       onPickVideoFromCamera: () =>
//                           _pickVideo(true, (v) => _hazardVideo = v),
//                       onRemovePhotoAt: (i) => _removePhotoAt(_hazardPhotos, i),
//                       onRemoveVideo: () => _removeVideo((v) => _hazardVideo = v),
//                     ),
//                     const SizedBox(height: 10),
//                     _PrimaryButton(label: 'SUBMIT', onTap: _submit),
//                     const SizedBox(height: 12),
//                     _BottomActionsRow(),
//                   ],
//                 ),

//                 // ------------------- INCIDENT -------------------
//                 _TabScroll(
//                   children: [
//                     const _SectionTitle('Incident type'),
//                     _AppDropdown<String>(
//                       hint: 'Select',
//                       value: _incidentType,
//                       items: const [
//                         'Trip/Fall',
//                         'Cut/Scratch',
//                         'Motor Vehicle',
//                         'Other'
//                       ],
//                       onChanged: (v) => setState(() => _incidentType = v),
//                     ),
//                     const SizedBox(height: 10),
//                     const _SectionTitle('People involved'),
//                     _CheckRow(
//                       label: 'Customer involved',
//                       value: _involveCustomer,
//                       onChanged: (v) =>
//                           setState(() => _involveCustomer = v ?? false),
//                     ),
//                     _CheckRow(
//                       label: 'Third party involved',
//                       value: _involveThirdParty,
//                       onChanged: (v) =>
//                           setState(() => _involveThirdParty = v ?? false),
//                     ),
//                     const _SectionTitle('Injury details (if any)'),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _AppDropdown<String>(
//                             hint: 'Body part',
//                             value: _injuryPart,
//                             items: const [
//                               'Head',
//                               'Arm',
//                               'Hand',
//                               'Leg',
//                               'Foot',
//                               'Back',
//                               'Other',
//                             ],
//                             onChanged: (v) => setState(() => _injuryPart = v),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: _AppDropdown<String>(
//                             hint: 'Nature',
//                             value: _injuryNature,
//                             items: const [
//                               'Bruise',
//                               'Cut',
//                               'Fracture',
//                               'Strain',
//                               'Other',
//                             ],
//                             onChanged: (v) => setState(() => _injuryNature = v),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     _CheckRow(
//                       label: 'First aid provided',
//                       value: _firstAid,
//                       success: true,
//                       strong: true,
//                       onChanged: (v) =>
//                           setState(() => _firstAid = v ?? false),
//                     ),
//                     _CheckRow(
//                       label: 'Notifiable trigger check',
//                       value: _notifiable,
//                       success: true,
//                       strong: true,
//                       onChanged: (v) =>
//                           setState(() => _notifiable = v ?? false),
//                     ),
//                     const SizedBox(height: 8),
//                     _PrimaryButton(label: 'SUBMIT', onTap: _submit),
//                     const SizedBox(height: 12),
//                     _BottomActionsRow(),
//                   ],
//                 ),

//                 // ------------------- DISPUTE -------------------
//                 _TabScroll(
//                   children: [
//                     _AppDropdown<String>(
//                       hint: 'Reason',
//                       value: _disputeReason,
//                       items: const [
//                         'Quality concern',
//                         'Price dispute',
//                         'Time dispute',
//                         'Other',
//                       ],
//                       onChanged: (v) => setState(() => _disputeReason = v),
//                     ),
//                     const SizedBox(height: 10),
//                     _AppDropdown<String>(
//                       hint: 'Request Outcome',
//                       value: _disputeOutcome,
//                       items: const [
//                         'Refund',
//                         'Partial refund',
//                         'Redo',
//                         'Escalate',
//                       ],
//                       onChanged: (v) => setState(() => _disputeOutcome = v),
//                     ),
//                     const SizedBox(height: 12),
//                     const _SectionTitle('Evidence'),
//                     _BigInput(
//                       controller: _disputeEvidence,
//                       hint: 'Describe the hazards and control taken',
//                     ),
//                     const SizedBox(height: 6),

//                     // ---- new media UI (photos + video) ----
//                     _MediaPickerBar(
//                       photos: _disputePhotos,
//                       video: _disputeVideo,
//                       onPickPhotos: () => _pickPhotos(_disputePhotos),
//                       onPickVideoFromGallery: () =>
//                           _pickVideo(false, (v) => _disputeVideo = v),
//                       onPickVideoFromCamera: () =>
//                           _pickVideo(true, (v) => _disputeVideo = v),
//                       onRemovePhotoAt: (i) =>
//                           _removePhotoAt(_disputePhotos, i),
//                       onRemoveVideo: () =>
//                           _removeVideo((v) => _disputeVideo = v),
//                     ),

//                     const SizedBox(height: 12),
//                     const _SectionTitle('Comment to customer (optional)'),
//                     _TextInput(controller: _customerNote, hint: 'Write a short, respectful note..'),
//                     const SizedBox(height: 10),
//                     _PrimaryButton(label: 'SUBMIT', onTap: _submit),
//                     const SizedBox(height: 12),
//                     _BottomActionsRow(),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ────────────────────────── COMMON WIDGETS ────────────────────────── */

// class _PinnedTabBar extends SliverPersistentHeaderDelegate {
//   const _PinnedTabBar({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       alignment: Alignment.centerLeft,
//       child: child,
//     );
//   }

//   @override
//   double get maxExtent => 56;
//   @override
//   double get minExtent => 56;
//   @override
//   bool shouldRebuild(covariant _PinnedTabBar oldDelegate) => false;
// }

// class _GlassBox extends StatelessWidget {
//   const _GlassBox({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(isDark ? .08 : .30),
//               Colors.white.withOpacity(isDark ? .05 : .16),
//             ],
//           ),
//           border: Border.all(color: Colors.white.withOpacity(isDark ? .18 : .22)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.08),
//               blurRadius: 18,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(14),
//         child: child,
//       ),
//     );
//   }
// }

// class _InfoCard extends StatelessWidget {
//   const _InfoCard({
//     required this.name,
//     required this.id,
//     required this.date,
//     required this.elapsed,
//   });

//   final String name, id, date, elapsed;

//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     return _GlassBox(
//       child: Row(
//         children: [
//           const Icon(Icons.person_outline_rounded, color: k),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text('Tasker: $name\nDate: $date',
//                 style: const TextStyle(fontWeight: FontWeight.w700)),
//           ),
//           Text('ID: $id\nElapsed: $elapsed',
//               textAlign: TextAlign.right,
//               style: const TextStyle(fontWeight: FontWeight.w700)),
//         ],
//       ),
//     );
//   }
// }

// class _PrimaryPill extends StatelessWidget {
//   const _PrimaryPill({
//     required this.label,
//     this.bg = _EmergencyFormTabsScreenState.kPrimary,
//     required this.onTap,
//   });

//   final String label;
//   final Color bg;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 46,
//       child: TextButton(
//         onPressed: onTap,
//         style: TextButton.styleFrom(
//           backgroundColor: bg,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         ),
//         child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
//       ),
//     );
//   }
// }

// class _PrimaryButton extends StatelessWidget {
//   const _PrimaryButton({required this.label, required this.onTap});
//   final String label;
//   final VoidCallback onTap;
//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     return SizedBox(
//       height: 50,
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           elevation: 0, backgroundColor: k, foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         ),
//         child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
//       ),
//     );
//   }
// }

// class _BottomActionsRow extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     ButtonStyle outline = OutlinedButton.styleFrom(
//       foregroundColor: k,
//       side: const BorderSide(color: k),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     );
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('Resume task')),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('End task')),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('Replacement')),
//         ),
//       ],
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle(this.text);
//   final String text;
//   static const kPrimary = _EmergencyFormTabsScreenState.kPrimary;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, top: 2),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: kPrimary,
//           fontWeight: FontWeight.w900,
//           fontSize: 18,
//         ),
//       ),
//     );
//   }
// }

// class _ChipToggle extends StatelessWidget {
//   const _ChipToggle({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final Color k = _EmergencyFormTabsScreenState.kPrimary;
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(30),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: selected ? k.withOpacity(.12) : const Color(0xFFF3F1F8),
//           border: Border.all(color: selected ? k : const Color(0xFFE8E2F5)),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? k : Colors.black87,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AppDropdown<T> extends StatelessWidget {
//   const _AppDropdown({
//     required this.hint,
//     required this.value,
//     required this.items,
//     required this.onChanged,
//   });

//   final String hint;
//   final T? value;
//   final List<T> items;
//   final ValueChanged<T?> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     return DropdownButtonFormField<T>(
//       value: value,
//       isExpanded: true,
//       decoration: InputDecoration(
//         hintText: hint,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//         enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: const BorderSide(color: k)),
//         focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: const BorderSide(color: k, width: 2)),
//       ),
//       icon: const Icon(Icons.keyboard_arrow_down_rounded, color: k),
//       items: items
//           .map((e) => DropdownMenuItem<T>(
//                 value: e,
//                 child: Text(e.toString(),
//                     style: const TextStyle(fontWeight: FontWeight.w700)),
//               ))
//           .toList(),
//       onChanged: onChanged,
//     );
//   }
// }

// class _TextInput extends StatelessWidget {
//   const _TextInput({required this.controller, required this.hint});
//   final TextEditingController controller;
//   final String hint;

//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         hintText: hint,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: k),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: k, width: 2),
//         ),
//       ),
//     );
//   }
// }

// class _BigInput extends StatelessWidget {
//   const _BigInput({required this.controller, required this.hint});
//   final TextEditingController controller;
//   final String hint;

//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     return TextField(
//       controller: controller,
//       minLines: 3,
//       maxLines: 6,
//       decoration: InputDecoration(
//         hintText: hint,
//         contentPadding: const EdgeInsets.all(14),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: k),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: k, width: 2),
//         ),
//       ),
//     );
//   }
// }

// /// Makes each tab body cooperate with the NestedScrollView.
// class _TabScroll extends StatelessWidget {
//   const _TabScroll({required this.children});
//   final List<Widget> children;

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       primary: false,
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       physics: const BouncingScrollPhysics(),
//       children: children
//           .map((w) => Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 child: w,
//               ))
//           .toList(),
//     );
//   }
// }

// /* ─────────────────────── Media picker widgets ─────────────────────── */

// class _MediaPickerBar extends StatelessWidget {
//   const _MediaPickerBar({
//     required this.photos,
//     required this.video,
//     required this.onPickPhotos,
//     required this.onPickVideoFromGallery,
//     required this.onPickVideoFromCamera,
//     required this.onRemovePhotoAt,
//     required this.onRemoveVideo,
//   });

//   final List<XFile> photos;
//   final XFile? video;
//   final VoidCallback onPickPhotos;
//   final VoidCallback onPickVideoFromGallery;
//   final VoidCallback onPickVideoFromCamera;
//   final ValueChanged<int> onRemovePhotoAt;
//   final VoidCallback onRemoveVideo;

//   @override
//   Widget build(BuildContext context) {
//     final int attached = photos.length + (video == null ? 0 : 1);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Wrap(
//           spacing: 10,
//           runSpacing: 10,
//           children: [
//             _PickChip(
//               label: 'Add photo',
//               icon: Icons.photo_library_rounded,
//               onTap: onPickPhotos,
//             ),
//          _PickChip(
//   label: 'Add video',
//   icon: Icons.videocam_rounded,
//   menuBuilder: (context, _) => [
//     PopupMenuItem(
//       onTap: onPickVideoFromGallery,
//       child: const Row(
//         children: [
//           Icon(Icons.video_library_rounded),
//           SizedBox(width: 8),
//           Text('From gallery'),
//         ],
//       ),
//     ),
//     PopupMenuItem(
//       onTap: onPickVideoFromCamera,
//       child: const Row(
//         children: [
//           Icon(Icons.videocam_rounded),
//           SizedBox(width: 8),
//           Text('Record video'),
//         ],
//       ),
//     ),
//   ],
// ),

//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               decoration: BoxDecoration(
//                 color: (isDark ? Colors.white10 : const Color(0xFFF3F1F8)),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 '$attached attached',
//                 style: const TextStyle(fontWeight: FontWeight.w800),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),

//         // Photos grid
//         if (photos.isNotEmpty)
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: List.generate(
//               photos.length,
//               (i) => _PhotoThumb(
//                 file: photos[i],
//                 onRemove: () => onRemovePhotoAt(i),
//               ),
//             ),
//           ),

//         // Video tile
//         if (video != null) ...[
//           const SizedBox(height: 10),
//           _VideoTile(file: video!, onRemove: onRemoveVideo),
//         ],
//       ],
//     );
//   }
// }

// class _PickChip extends StatelessWidget {
//   const _PickChip({
//     required this.label,
//     required this.icon,
//     this.onTap,
//     this.menuBuilder,
//   });

//   final String label;
//   final IconData icon;
//   final VoidCallback? onTap;

//   /// If provided, shows a popup menu. Return the list of menu items to render.
//   final List<PopupMenuEntry<dynamic>> Function(
//     BuildContext context,
//     Offset globalTapPosition,
//   )? menuBuilder;

//   @override
//   Widget build(BuildContext context) {
//     final k = _EmergencyFormTabsScreenState.kPrimary;

//     return GestureDetector(
//       onTapDown: (details) {
//         if (menuBuilder != null) {
//           final items = menuBuilder!(context, details.globalPosition);
//           final size = MediaQuery.of(context).size;

//           showMenu(
//             context: context,
//             position: RelativeRect.fromLTRB(
//               details.globalPosition.dx,
//               details.globalPosition.dy,
//               size.width - details.globalPosition.dx,
//               size.height - details.globalPosition.dy,
//             ),
//             items: items,
//           );
//         } else {
//           onTap?.call();
//         }
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F1F8),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFE8E2F5)),
//         ),
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           Icon(icon, color: k, size: 18),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
//           ),
//         ]),
//       ),
//     );
//   }
// }


// class _VideoPickMenu {
//   _VideoPickMenu({
//     required this.onGallery,
//     required this.onCamera,
//     required this.anchor,
//   }) {
//     items = [
//       PopupMenuItem(
//         child: const Row(
//           children: [Icon(Icons.video_library_rounded), SizedBox(width: 8), Text('From gallery')],
//         ),
//         onTap: onGallery,
//       ),
//       PopupMenuItem(
//         child: const Row(
//           children: [Icon(Icons.videocam_rounded), SizedBox(width: 8), Text('Record video')],
//         ),
//         onTap: onCamera,
//       ),
//     ];
//   }

//   final VoidCallback onGallery;
//   final VoidCallback onCamera;
//   final Offset anchor;
//   late final List<PopupMenuEntry> items;
// }

// class _PhotoThumb extends StatelessWidget {
//   const _PhotoThumb({required this.file, required this.onRemove});
//   final XFile file;
//   final VoidCallback onRemove;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.file(
//             File(file.path),
//             width: 82,
//             height: 82,
//             fit: BoxFit.cover,
//           ),
//         ),
//         Positioned(
//           top: -8,
//           right: -8,
//           child: Material(
//             color: Colors.redAccent,
//             shape: const CircleBorder(),
//             child: InkWell(
//               customBorder: const CircleBorder(),
//               onTap: onRemove,
//               child: const Padding(
//                 padding: EdgeInsets.all(4),
//                 child: Icon(Icons.close, size: 16, color: Colors.white),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _VideoTile extends StatelessWidget {
//   const _VideoTile({required this.file, required this.onRemove});
//   final XFile file;
//   final VoidCallback onRemove;

//   @override
//   Widget build(BuildContext context) {
//     const k = _EmergencyFormTabsScreenState.kPrimary;
//     final name = file.name;
//     final sizeKB = (File(file.path).lengthSync() / 1024).toStringAsFixed(0);

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF3F1F8),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE8E2F5)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.videocam_rounded, color: k, size: 28),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               '$name  •  ${sizeKB}KB',
//               style: const TextStyle(fontWeight: FontWeight.w800),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
//             onPressed: onRemove,
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ─────────────────────── CheckRow (requested) ─────────────────────── */

// class _CheckRow extends StatelessWidget {
//   const _CheckRow({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//     this.strong = false,
//     this.success = false,
//   });

//   final String label;
//   final bool value;
//   final ValueChanged<bool?> onChanged;
//   final bool strong;   // bolder text
//   final bool success;  // green accent

//   @override
//   Widget build(BuildContext context) {
//     final Color accent =
//         success ? Colors.green : _EmergencyFormTabsScreenState.kPrimary;
//     final textColor =
//         success ? Colors.green.shade800 : (strong ? _EmergencyFormTabsScreenState.kPrimary : Colors.black87);

//     return _GlassBox(
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () => onChanged(!value),
//         child: Row(
//           children: [
//             Checkbox(
//               value: value,
//               onChanged: onChanged,
//               activeColor: accent,
//               side: BorderSide(color: accent, width: 1.6),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//             ),
//             const SizedBox(width: 6),
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   color: textColor,
//                   fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// emergency_form_tabs.dart (REDESIGNED UI ONLY - same logic)
// ✅ Keeps: fields, pickers, submit hooks, tab structure, state vars, media delete etc.
// ✅ Changes: UI styling to match your kPrimary/kTextDark/kMuted/kBg redesign style

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/* ===================== THEME (same as your redesign) ===================== */

const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);
const Color kBg = Color(0xFFF8F7FB);

class EmergencyFormTabsScreen extends StatefulWidget {
  const EmergencyFormTabsScreen({
    super.key,
    this.taskerName = 'Stephan Matt',
    this.orderId = '464834',
    this.dateLabel = '10.08.2025 10.19',
    this.elapsed = '00:55',
  });

  final String taskerName;
  final String orderId;
  final String dateLabel;
  final String elapsed;

  @override
  State<EmergencyFormTabsScreen> createState() => _EmergencyFormTabsScreenState();
}

class _EmergencyFormTabsScreenState extends State<EmergencyFormTabsScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _pauseTimer = false;

  // ------- Hazard tab state -------
  final Set<String> _hazardTags = {};
  String? _riskLikelihood;
  String? _riskConsequence;
  final TextEditingController _hazardDesc = TextEditingController();
  final List<XFile> _hazardPhotos = <XFile>[];
  XFile? _hazardVideo;

  // ------- Incident tab state (sample) -------
  String? _incidentType;
  bool _involveCustomer = false;
  bool _involveThirdParty = false;
  String? _injuryPart;
  String? _injuryNature;
  bool _firstAid = false;
  bool _notifiable = false;

  // ------- Dispute tab state -------
  String? _disputeReason;
  String? _disputeOutcome;
  final TextEditingController _disputeEvidence = TextEditingController();
  final TextEditingController _customerNote = TextEditingController();
  final List<XFile> _disputePhotos = <XFile>[];
  XFile? _disputeVideo;

  // ----------------- media pickers -----------------
  Future<void> _pickPhotos(List<XFile> targetList) async {
    final imgs = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2200);
    if (imgs.isNotEmpty) {
      setState(() => targetList.addAll(imgs));
    }
  }

  Future<void> _pickVideo(bool fromCamera, ValueChanged<XFile?> setVideo) async {
    final video = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (video != null) {
      setState(() => setVideo(video));
    }
  }

  void _removePhotoAt(List<XFile> list, int index) {
    setState(() => list.removeAt(index));
  }

  void _removeVideo(ValueChanged<XFile?> setVideo) {
    setState(() => setVideo(null));
  }

  // -------------------------------------------------
  void _onSOS() {}
  void _onSupport() {}
  void _submit() {}

  @override
  void dispose() {
    _hazardDesc.dispose();
    _disputeEvidence.dispose();
    _customerNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 10,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Emergency',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: kTextDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _TabPillBar(),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      _HeroOrderCard(
                        taskerName: widget.taskerName,
                        orderId: widget.orderId,
                        dateLabel: widget.dateLabel,
                        elapsed: widget.elapsed,
                      ),
                      const SizedBox(height: 12),
                      _PauseCard(
                        value: _pauseTimer,
                        onChanged: (v) => setState(() => _pauseTimer = v ?? false),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'SOS',
                              icon: Icons.warning_rounded,
                              bg: const Color(0xFFE53935),
                              fg: Colors.white,
                              onTap: _onSOS,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'CALL SUPPORT',
                              icon: Icons.support_agent_rounded,
                              bg: kPrimary,
                              fg: Colors.white,
                              onTap: _onSupport,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                // ------------------- HAZARD -------------------
                _TabScroll(
                  children: [
                    const _SectionTitle(
                      title: "What's the hazard?",
                      subtitle: "Select one or more tags to quickly describe the situation.",
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        'Entry issue',
                        'Aggressive person/animal',
                        'Height/roof',
                        'Gas/chemical/odor',
                        'Asbestos (suspected)',
                        'Other',
                      ].map((t) {
                        // NOTE: Uses parent state. Keep this wrapper same behavior as before.
                        return _HazardChip(label: t);
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(
                      title: 'Risk rating',
                      subtitle: 'Choose likelihood and consequence to classify the risk.',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _AppDropdown<String>(
                            hint: 'Likelihood',
                            value: _riskLikelihood,
                            items: const [
                              'Rare',
                              'Unlikely',
                              'Possible',
                              'Likely',
                              'Almost certain',
                            ],
                            onChanged: (v) => setState(() => _riskLikelihood = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AppDropdown<String>(
                            hint: 'Consequence',
                            value: _riskConsequence,
                            items: const [
                              'Insignificant',
                              'Minor',
                              'Moderate',
                              'Major',
                              'Severe',
                            ],
                            onChanged: (v) => setState(() => _riskConsequence = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Evidence', subtitle: 'Add notes + photos/video if needed.'),
                    _BigInput(
                      controller: _hazardDesc,
                      hint: 'Describe the hazard and control taken...',
                    ),
                    const SizedBox(height: 10),
                    _MediaPickerCard(
                      photos: _hazardPhotos,
                      video: _hazardVideo,
                      onPickPhotos: () => _pickPhotos(_hazardPhotos),
                      onPickVideoFromGallery: () => _pickVideo(false, (v) => _hazardVideo = v),
                      onPickVideoFromCamera: () => _pickVideo(true, (v) => _hazardVideo = v),
                      onRemovePhotoAt: (i) => _removePhotoAt(_hazardPhotos, i),
                      onRemoveVideo: () => _removeVideo((v) => _hazardVideo = v),
                    ),
                    const SizedBox(height: 12),
                    _PrimaryButton(label: 'SUBMIT', onTap: _submit),
                    const SizedBox(height: 12),
                    const _BottomActionsRow(),
                  ],
                ),

                // ------------------- INCIDENT -------------------
                _TabScroll(
                  children: [
                    const _SectionTitle(
                      title: 'Incident type',
                      subtitle: 'Pick the closest incident type.',
                    ),
                    _AppDropdown<String>(
                      hint: 'Select',
                      value: _incidentType,
                      items: const ['Trip/Fall', 'Cut/Scratch', 'Motor Vehicle', 'Other'],
                      onChanged: (v) => setState(() => _incidentType = v),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(
                      title: 'People involved',
                      subtitle: 'Select who is involved in this incident.',
                    ),
                    _CheckRow(
                      label: 'Customer involved',
                      value: _involveCustomer,
                      onChanged: (v) => setState(() => _involveCustomer = v ?? false),
                    ),
                    _CheckRow(
                      label: 'Third party involved',
                      value: _involveThirdParty,
                      onChanged: (v) => setState(() => _involveThirdParty = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(
                      title: 'Injury details (if any)',
                      subtitle: 'Optional — add injury details if applicable.',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _AppDropdown<String>(
                            hint: 'Body part',
                            value: _injuryPart,
                            items: const ['Head', 'Arm', 'Hand', 'Leg', 'Foot', 'Back', 'Other'],
                            onChanged: (v) => setState(() => _injuryPart = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AppDropdown<String>(
                            hint: 'Nature',
                            value: _injuryNature,
                            items: const ['Bruise', 'Cut', 'Fracture', 'Strain', 'Other'],
                            onChanged: (v) => setState(() => _injuryNature = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CheckRow(
                      label: 'First aid provided',
                      value: _firstAid,
                      strong: true,
                      success: true,
                      onChanged: (v) => setState(() => _firstAid = v ?? false),
                    ),
                    _CheckRow(
                      label: 'Notifiable trigger check',
                      value: _notifiable,
                      strong: true,
                      success: true,
                      onChanged: (v) => setState(() => _notifiable = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    _PrimaryButton(label: 'SUBMIT', onTap: _submit),
                    const SizedBox(height: 12),
                    const _BottomActionsRow(),
                  ],
                ),

                // ------------------- DISPUTE -------------------
                _TabScroll(
                  children: [
                    const _SectionTitle(
                      title: 'Dispute details',
                      subtitle: 'Select reason and requested outcome.',
                    ),
                    _AppDropdown<String>(
                      hint: 'Reason',
                      value: _disputeReason,
                      items: const ['Quality concern', 'Price dispute', 'Time dispute', 'Other'],
                      onChanged: (v) => setState(() => _disputeReason = v),
                    ),
                    const SizedBox(height: 10),
                    _AppDropdown<String>(
                      hint: 'Request outcome',
                      value: _disputeOutcome,
                      items: const ['Refund', 'Partial refund', 'Redo', 'Escalate'],
                      onChanged: (v) => setState(() => _disputeOutcome = v),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Evidence', subtitle: 'Explain + attach photos/video.'),
                    _BigInput(
                      controller: _disputeEvidence,
                      hint: 'Explain the dispute and attach evidence...',
                    ),
                    const SizedBox(height: 10),
                    _MediaPickerCard(
                      photos: _disputePhotos,
                      video: _disputeVideo,
                      onPickPhotos: () => _pickPhotos(_disputePhotos),
                      onPickVideoFromGallery: () => _pickVideo(false, (v) => _disputeVideo = v),
                      onPickVideoFromCamera: () => _pickVideo(true, (v) => _disputeVideo = v),
                      onRemovePhotoAt: (i) => _removePhotoAt(_disputePhotos, i),
                      onRemoveVideo: () => _removeVideo((v) => _disputeVideo = v),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle(
                      title: 'Comment to customer (optional)',
                      subtitle: 'Write a short, respectful note.',
                    ),
                    _TextInput(
                      controller: _customerNote,
                      hint: 'Write a short note...',
                    ),
                    const SizedBox(height: 12),
                    _PrimaryButton(label: 'SUBMIT', onTap: _submit),
                    const SizedBox(height: 12),
                    const _BottomActionsRow(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== Hazard chip needs access to state set ==================
  // We keep this helper to avoid rewriting your logic in every chip.
  bool _hazardSelected(String label) => _hazardTags.contains(label);

  void _toggleHazard(String label) {
    setState(() {
      if (_hazardTags.contains(label)) {
        _hazardTags.remove(label);
      } else {
        _hazardTags.add(label);
      }
    });
  }
}

/* ────────────────────────── REDESIGNED WIDGETS ────────────────────────── */

class _TabPillBar extends StatelessWidget {
  const _TabPillBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kPrimary.withOpacity(.14)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kPrimary.withOpacity(.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            )
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: kPrimary,
        unselectedLabelColor: kMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Hazard'),
          Tab(text: 'Incident'),
          Tab(text: 'Dispute'),
        ],
      ),
    );
  }
}

class _HeroOrderCard extends StatelessWidget {
  const _HeroOrderCard({
    required this.taskerName,
    required this.orderId,
    required this.dateLabel,
    required this.elapsed,
  });

  final String taskerName;
  final String orderId;
  final String dateLabel;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withOpacity(.16),
            kPrimary.withOpacity(.08),
            Colors.white,
          ],
        ),
        border: Border.all(color: kPrimary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kPrimary.withOpacity(.14)),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: kPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency report',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFEE8A41).withOpacity(.18)),
                ),
                child: const Text(
                  'In task',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEE8A41),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValueRow(icon: Icons.person_outline_rounded, k: 'Tasker', v: taskerName),
          const SizedBox(height: 8),
          _KeyValueRow(icon: Icons.confirmation_number_outlined, k: 'Order ID', v: orderId),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _KeyValueRow(icon: Icons.calendar_month_rounded, k: 'Date', v: dateLabel)),
              const SizedBox(width: 10),
              Expanded(child: _KeyValueRow(icon: Icons.timer_outlined, k: 'Elapsed', v: elapsed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.icon, required this.k, required this.v});
  final IconData icon;
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: kMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: kTextDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pause_circle_outline_rounded, color: kPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Safety first — the task timer can be paused while this form is open.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: kMuted,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) => onChanged(v),
            activeColor: kPrimary,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            color: kTextDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: kMuted,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _HazardChip extends StatelessWidget {
  const _HazardChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Access parent state
    final st = context.findAncestorStateOfType<_EmergencyFormTabsScreenState>();
    final selected = st?._hazardSelected(label) == true;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => st?._toggleHazard(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kPrimary : kPrimary.withOpacity(.22)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(.16),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: selected ? Colors.white : kPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _AppDropdown<T> extends StatelessWidget {
  const _AppDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: kMuted, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimary.withOpacity(.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  e.toString(),
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: kTextDark),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: kMuted, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimary.withOpacity(.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
      ),
    );
  }
}

class _BigInput extends StatelessWidget {
  const _BigInput({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: kMuted, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimary.withOpacity(.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
      ),
    );
  }
}

/// Makes each tab body cooperate with the NestedScrollView.
class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: children
          .map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: w,
              ))
          .toList(),
    );
  }
}

/* ─────────────────────── Media picker (REDESIGNED) ─────────────────────── */

class _MediaPickerCard extends StatelessWidget {
  const _MediaPickerCard({
    required this.photos,
    required this.video,
    required this.onPickPhotos,
    required this.onPickVideoFromGallery,
    required this.onPickVideoFromCamera,
    required this.onRemovePhotoAt,
    required this.onRemoveVideo,
  });

  final List<XFile> photos;
  final XFile? video;
  final VoidCallback onPickPhotos;
  final VoidCallback onPickVideoFromGallery;
  final VoidCallback onPickVideoFromCamera;
  final ValueChanged<int> onRemovePhotoAt;
  final VoidCallback onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    final attached = photos.length + (video == null ? 0 : 1);

    return _WhiteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.attach_file_rounded, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Attachments',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: kTextDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: kPrimary.withOpacity(.14)),
                ),
                child: Text(
                  '$attached attached',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PickChip(
                label: 'Add photo',
                icon: Icons.photo_library_rounded,
                onTap: onPickPhotos,
              ),
              _PickChip(
                label: 'Add video',
                icon: Icons.videocam_rounded,
                menuBuilder: (context, pos) => [
                  PopupMenuItem(
                    onTap: onPickVideoFromGallery,
                    child: const Row(
                      children: [
                        Icon(Icons.video_library_rounded),
                        SizedBox(width: 8),
                        Text('From gallery'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onPickVideoFromCamera,
                    child: const Row(
                      children: [
                        Icon(Icons.videocam_rounded),
                        SizedBox(width: 8),
                        Text('Record video'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhotosGrid(
              photos: photos,
              onRemoveAt: onRemovePhotoAt,
            ),
          ],
          if (video != null) ...[
            const SizedBox(height: 12),
            _VideoTile(file: video!, onRemove: onRemoveVideo),
          ],
        ],
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.label,
    required this.icon,
    this.onTap,
    this.menuBuilder,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  final List<PopupMenuEntry<dynamic>> Function(
    BuildContext context,
    Offset globalTapPosition,
  )? menuBuilder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (menuBuilder != null) {
          final items = menuBuilder!(context, details.globalPosition);
          final size = MediaQuery.of(context).size;

          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              size.width - details.globalPosition.dx,
              size.height - details.globalPosition.dy,
            ),
            items: items,
          );
        } else {
          onTap?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimary.withOpacity(.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: kPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: kPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ]),
      ),
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({required this.photos, required this.onRemoveAt});
  final List<XFile> photos;
  final ValueChanged<int> onRemoveAt;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
        photos.length,
        (i) => _PhotoThumb(
          file: photos[i],
          onRemove: () => onRemoveAt(i),
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
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(file.path),
            width: 86,
            height: 86,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(.35)),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = file.name;
    final sizeKB = (File(file.path).lengthSync() / 1024).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.videocam_rounded, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$name  •  ${sizeKB}KB',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                color: kTextDark,
                fontSize: 12.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────── Buttons / Actions ─────────────────────── */

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            letterSpacing: .3,
          ),
        ),
      ),
    );
  }
}

class _BottomActionsRow extends StatelessWidget {
  const _BottomActionsRow();

  @override
  Widget build(BuildContext context) {
    ButtonStyle outline = OutlinedButton.styleFrom(
      foregroundColor: kPrimary,
      side: BorderSide(color: kPrimary.withOpacity(.55)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('Resume task'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('End task'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: () {}, style: outline, child: const Text('Replacement'))),
      ],
    );
  }
}

/* ─────────────────────── CheckRow (Redesigned) ─────────────────────── */

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.strong = false,
    this.success = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool strong;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final Color accent = success ? const Color(0xFF1E8E66) : kPrimary;
    final Color bg = success ? const Color(0xFFEFF8F4) : kPrimary.withOpacity(.06);

    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(.18)),
              ),
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: accent,
                side: BorderSide(color: accent, width: 1.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: kTextDark,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent.withOpacity(.6)),
          ],
        ),
      ),
    );
  }
}
