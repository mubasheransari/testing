import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskoon/Screens/Booking_process_tasker/task_countdown_screen.dart';

class PrestartSafetyCheckScreen extends StatefulWidget {
  const PrestartSafetyCheckScreen({super.key});

  @override
  State<PrestartSafetyCheckScreen> createState() =>
      _PrestartSafetyCheckScreenState();
}

class _PrestartSafetyCheckScreenState extends State<PrestartSafetyCheckScreen> {
  // Brand palette
  static const kPrimary = Color(0xFF5C2E91);
  static const kPrimaryDark = Color(0xFF411C6E);

  // ---- DATA (all toggled by switches) ----
  final List<_CheckItem> ppe = [
    _CheckItem('Hi-Vis outerwear'),
    _CheckItem('Safety boots'),
    _CheckItem('Eye protection'),
    _CheckItem('Gloves (task appropriate)'),
    _CheckItem('Hearing protection'),
    _CheckItem('Respiratory protection'),
  ];

  final List<_CheckItem> siteRisk = [
    _CheckItem('Site induction completed/site rules understood'),
    _CheckItem('Hazards identified (slips, sharp edges, bio hazards...)'),
    _CheckItem('Tools & equipment inspected and fit for use'),
    _CheckItem('Electrical RCD/earth-leakage tested.'),
    _CheckItem('Weather and conditions OK (wind, heat, rain)'),
    _CheckItem('Underground/overhead services located (DBYD, …)'),
    _CheckItem('Manual handling plans for heavy/awkward loads'),
    _CheckItem('Lone-worker/duress plan in place'),
    _CheckItem('Emergency plans and contacts known…'),
  ];

  // Safety analysis (informational toggle, not counted)
  bool swmsNA = false;

  // Counted toggles
  bool fitForWork = false;

  // Acknowledge (gates Start button, not counted)
  bool safetyAck = false;

  final otherPpeCtrl = TextEditingController();
  final additionalHazardCtrl = TextEditingController();

  XFile? sitePhoto;

  // --- COUNTERS: number of switches ON ---
  int get _totalChecks => ppe.length + siteRisk.length + 1; // + fitForWork
  int get _completedChecks =>
      ppe.where((e) => e.on).length +
      siteRisk.where((e) => e.on).length +
      (fitForWork ? 1 : 0);

  Future<void> _pickSitePhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => sitePhoto = img);
  }

  @override
  void dispose() {
    otherPpeCtrl.dispose();
    additionalHazardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF8F7FB);

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
                border: Border.all(color: const Color(0xFFE8E2F5)),
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
                    'Pre-start safety check',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // const Spacer(),
                  // Container(
                  //   margin: const EdgeInsets.only(right: 12),
                  //   padding:
                  //       const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFFF0ECF6),
                  //     borderRadius: BorderRadius.circular(14),
                  //   ),
                  //   child: const Text(
                  //     'Required',
                  //     style: TextStyle(
                  //       color: kPrimary,
                  //       fontWeight: FontWeight.w800,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SubtleLead(
              icon: Icons.info_outline_rounded,
              text:
                  'Jurisdiction: Relevant State/Territory OHS/WHS Act and Regulations. Refer to guidelines for full details',
            ),
            const SizedBox(height: 14),
            const _SectionHeading(
              icon: Icons.place_outlined,
              title: 'Job location and task details',
              trailing: '',
            ),

            const SizedBox(height: 14),

            // ------------------ PPE CARD ------------------
            _SectionCard(
              leadingIcon: Icons.hardware_outlined,
              title: 'Personal protective equipment',
              subtitle:
                  "Confirm you're wearing the required PPE for this task",
              children: [
                for (final item in ppe)
                  _SwitchTile(
                    label: item.title,
                    value: item.on,
                    onChanged: (v) => setState(() => item.on = v),
                  ),
                const SizedBox(height: 6),
                const Text('Other task specific PPE (Optional)'),
                const SizedBox(height: 8),
                _TextField(
                  controller: otherPpeCtrl,
                  hint: 'e.g., cut resistant sleeves',
                ),
              ],
            ),

            // ------------------ SITE RISK ------------------
            const SizedBox(height: 16),
            _SectionCard(
              leadingIcon: Icons.warning_amber_rounded,
              title: 'Site risk assessment',
              subtitle: 'Identify hazards and confirm controls are in place',
              children: [
                for (final item in siteRisk)
                  _SwitchTile(
                    label: item.title,
                    value: item.on,
                    onChanged: (v) => setState(() => item.on = v),
                  ),
              ],
            ),

            // ------------------ SAFETY ANALYSIS ------------------
            const SizedBox(height: 16),
            _SectionCard(
              leadingIcon: Icons.verified_user_rounded,
              title: 'Safety analysis',
              subtitle:
                  'Review documentation, fitness for work, and records.',
              children: [
                const _BodySmall('SWMS/JSA reviewed & understood'),
                const _GreyCaption(
                  'Required for high-risk construction work, mark N/A if not applicable to this task',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const _BodySmall('Not applicable'),
                    const Spacer(),
                    Switch.adaptive(
                      value: swmsNA,
                      onChanged: (v) => setState(() => swmsNA = v),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F3F8),
                      foregroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'View example',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),

            // ------------------ FIT FOR WORK + NOTES + PHOTO ------------------
            const SizedBox(height: 16),
            _RoundedContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SwitchTile(
                    label:
                        'I am fit for work (no alcohol/drugs, not fatigued/ill)',
                    value: fitForWork,
                    onChanged: (v) => setState(() => fitForWork = v),
                  ),
                  const SizedBox(height: 8),
                  const _SectionSubTitle(
                      'Additional hazards/controls (optional)'),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: additionalHazardCtrl,
                    hint: 'Note anything unusual about the site or task.',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  const _SectionSubTitle('Site photo (optional)'),
                  const SizedBox(height: 8),
                  _UploadBox(
                    label: sitePhoto == null
                        ? 'Choose file'
                        : (sitePhoto!.name),
                    onTap: _pickSitePhoto,
                    subLabel:
                        sitePhoto == null ? 'No file chosen' : 'Selected',
                    preview: sitePhoto?.path,
                  ),
                ],
              ),
            ),

            // ------------------ COMPLETION + ACK ------------------
            const SizedBox(height: 22),
            Row(
              children: [
                const Text(
                  'Completion',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_completedChecks}/${_totalChecks} checks',
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Divider(),

            // Acknowledge using switch
            SwitchListTile.adaptive(
              value: safetyAck,
              onChanged: (v) => setState(() => safetyAck = v),
              activeColor: const Color(0xFF2E7D32),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I acknowledge my duty to work safely and follow safety rules under the relevant state/territory WHS/OHS laws. If conditions change or become unsafe I will stop work and report immediately',
                style: TextStyle(height: 1.35),
              ),
            ),

            const SizedBox(height: 8),

            // ------------------ BUTTONS ------------------
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: const BorderSide(color: kPrimary, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'REPORT HAZARD',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: safetyAck && _completedChecks == _totalChecks
                    ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> TaskCountdownScreen()));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: kPrimary.withOpacity(.35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'START TASK',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFCBC6D7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CANCEL TASK',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/* ================================ WIDGETS ================================ */

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.icon, required this.title, this.trailing});
  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _PrestartSafetyCheckScreenState.kPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _PrestartSafetyCheckScreenState.kPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          Text(
            trailing!,
            style: const TextStyle(color: Colors.black54, fontSize: 14.5),
          ),
        ],
      ],
    );
  }
}

class _RoundedContainer extends StatelessWidget {
  const _RoundedContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _RoundedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _PrestartSafetyCheckScreenState.kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leadingIcon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.25,
                      )),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFD9EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _PrestartSafetyCheckScreenState.kPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F3F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E2F5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E2F5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: _PrestartSafetyCheckScreenState.kPrimary, width: 1.4),
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.subLabel,
    required this.onTap,
    this.preview,
  });

  final String label;
  final String subLabel;
  final VoidCallback onTap;
  final String? preview;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: const Color(0xFFD6D0E2),
      width: 1.2,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.file_upload_outlined,
                color: _PrestartSafetyCheckScreenState.kPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _PrestartSafetyCheckScreenState.kPrimary)),
                  const SizedBox(height: 2),
                  Text(subLabel, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(preview!),
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubtleLead extends StatelessWidget {
  const _SubtleLead({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        width: double.infinity,
        color: const Color(0xFFE8E2F5),
      );
}

class _GreyCaption extends StatelessWidget {
  const _GreyCaption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Colors.grey.shade600, height: 1.3));
}

class _BodySmall extends StatelessWidget {
  const _BodySmall(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
}

class _SectionSubTitle extends StatelessWidget {
  const _SectionSubTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _PrestartSafetyCheckScreenState.kPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
}

/* ------------------------------ Simple model ------------------------------ */
class _CheckItem {
  final String title;
  bool on;
  _CheckItem(this.title, {this.on = false});
}


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class PrestartSafetyCheckScreen extends StatefulWidget {
//   const PrestartSafetyCheckScreen({super.key});

//   @override
//   State<PrestartSafetyCheckScreen> createState() =>
//       _PrestartSafetyCheckScreenState();
// }

// class _PrestartSafetyCheckScreenState extends State<PrestartSafetyCheckScreen> {
//   // Brand palette
//   static const kPrimary = Color(0xFF5C2E91);
//   static const kPrimaryDark = Color(0xFF411C6E);

//   // ---- DATA ----
//   final List<_CheckItem> ppe = [
//     _CheckItem('Hi-Vis outerwear'),
//     _CheckItem('Safety boots'),
//     _CheckItem('Eye protection'),
//     _CheckItem('Gloves (task appropriate)'),
//     _CheckItem('Hearing protection'),
//     _CheckItem('Respiratory protection'),
//   ];

//   final List<_CheckItem> siteRisk = [
//     _CheckItem('Site induction completed/site rules understood'),
//     _CheckItem('Hazards identified (slips, sharp edges, bio hazards...)'),
//     _CheckItem('Tools & equipment inspected and fit for use'),
//     _CheckItem('Electrical RCD/earth-leakage tested.'),
//     _CheckItem('Weather and conditions OK (wind, heat, rain)'),
//     _CheckItem('Underground/overhead services located (DBYD, …)'),
//     _CheckItem('Manual handling plans for heavy/awkward loads'),
//     _CheckItem('Lone-worker/duress plan in place'),
//     _CheckItem('Emergency plans and contacts known…'),
//   ];

//   bool swmsNA = false; // Safety analysis "Not applicable"
//   bool fitForWork = false;
//   bool fitForWorkNA = false;
//   bool safetyAck = false;

//   final otherPpeCtrl = TextEditingController();
//   final additionalHazardCtrl = TextEditingController();

//   XFile? sitePhoto;

//   int get _totalChecks => ppe.length + siteRisk.length + 1; // + fit for work
//   int get _completedChecks =>
//       ppe.where((e) => e.checked).length +
//       siteRisk.where((e) => e.checked).length +
//       (fitForWork ? 1 : 0);

//   Future<void> _pickSitePhoto() async {
//     final picker = ImagePicker();
//     final img = await picker.pickImage(source: ImageSource.gallery);
//     if (img != null) setState(() => sitePhoto = img);
//   }

//   @override
//   void dispose() {
//     otherPpeCtrl.dispose();
//     additionalHazardCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bg = const Color(0xFFF8F7FB);

//     return Scaffold(
//       backgroundColor: bg,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(82),
//         child: SafeArea(
//           bottom: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
//             child: Container(
//               height: 62,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: const Color(0xFFE8E2F5)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(.06),
//                     blurRadius: 18,
//                     offset: const Offset(0, 8),
//                   )
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPrimary),
//                     onPressed: () => Navigator.maybePop(context),
//                   ),
//                   const SizedBox(width: 2),
//                   const Text(
//                     'Pre-start safety check',
//                     style: TextStyle(
//                       color: kPrimary,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     margin: const EdgeInsets.only(right: 12),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF0ECF6),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: const Text(
//                       'Required',
//                       style: TextStyle(
//                         color: kPrimary,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),

//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _SubtleLead(
//               icon: Icons.info_outline_rounded,
//               text:
//                   'Jurisdiction: Relevant State/Territory OHS/WHS Act and Regulations. Refer to guidelines for full details',
//             ),
//             const SizedBox(height: 14),
//             _SectionHeading(
//               icon: Icons.place_outlined,
//               title: 'Job location and task details',
//               trailing: '(auto filled)',
//             ),

//             const SizedBox(height: 14),

//             // ------------------ PPE CARD ------------------
//             _SectionCard(
//               leadingIcon: Icons.hardware_outlined, // available on Material 3
//               title: 'Personal protective equipment',
//               subtitle:
//                   "Confirm you're wearing the required PPE for this task",
//               children: [
//                 for (final item in ppe)
//                   _CheckTile(
//                     label: item.title,
//                     checked: item.checked,
//                     notApplicable: item.notApplicable,
//                     onChanged: (v) => setState(() => item.checked = v ?? false),
//                     onNAChanged: (v) =>
//                         setState(() => item.notApplicable = v),
//                   ),
//                 const SizedBox(height: 6),
//                 const Text('Other task specific PPE (Optional)'),
//                 const SizedBox(height: 8),
//                 _TextField(
//                   controller: otherPpeCtrl,
//                   hint: 'e.g., cut resistant sleeves',
//                 ),
//               ],
//             ),

//             // ------------------ SITE RISK ------------------
//             const SizedBox(height: 16),
//             _SectionCard(
//               leadingIcon: Icons.warning_amber_rounded,
//               title: 'Site risk assessment',
//               subtitle:
//                   'Identify hazards and confirm controls are in place',
//               children: [
//                 for (final item in siteRisk)
//                   _CheckTile(
//                     label: item.title,
//                     checked: item.checked,
//                     notApplicable: item.notApplicable,
//                     onChanged: (v) => setState(() => item.checked = v ?? false),
//                     onNAChanged: (v) =>
//                         setState(() => item.notApplicable = v),
//                   ),
//               ],
//             ),

//             // ------------------ SAFETY ANALYSIS ------------------
//             const SizedBox(height: 16),
//             _SectionCard(
//               leadingIcon: Icons.verified_user_rounded,
//               title: 'Safety analysis',
//               subtitle:
//                   'Review documentation, fitness for work, and records.',
//               children: [
//                 const _BodySmall('SWMS/JSA reviewed & understood'),
//                 const _GreyCaption(
//                   'Required for high-risk construction work, mark N/A if not applicable to this task',
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     const _BodySmall('Not applicable'),
//                     const Spacer(),
//                     Switch.adaptive(
//                       value: swmsNA,
//                       onChanged: (v) => setState(() => swmsNA = v),
//                       activeColor: const Color(0xFF2E7D32),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 SizedBox(
//                   height: 44,
//                   width: double.infinity,
//                   child: TextButton(
//                     style: TextButton.styleFrom(
//                       backgroundColor: const Color(0xFFF4F3F8),
//                       foregroundColor: kPrimary,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () {},
//                     child: const Text(
//                       'View example',
//                       style: TextStyle(fontWeight: FontWeight.w800),
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             // ------------------ FIT FOR WORK + NOTES + PHOTO ------------------
//             const SizedBox(height: 16),
//             _RoundedContainer(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _CheckTile(
//                     label:
//                         'I am fit for work (no alcohol/drugs, not fatigued/ill)',
//                     checked: fitForWork,
//                     notApplicable: fitForWorkNA,
//                     onChanged: (v) => setState(() => fitForWork = v ?? false),
//                     onNAChanged: (v) => setState(() => fitForWorkNA = v),
//                   ),
//                   const SizedBox(height: 8),
//                   const _SectionSubTitle(
//                       'Additional hazards/controls (optional)'),
//                   const SizedBox(height: 8),
//                   _TextField(
//                     controller: additionalHazardCtrl,
//                     hint:
//                         'Note anything unusual about the site or task.',
//                     maxLines: 4,
//                   ),
//                   const SizedBox(height: 16),
//                   const _SectionSubTitle('Site photo (optional)'),
//                   const SizedBox(height: 8),
//                   _UploadBox(
//                     label: sitePhoto == null
//                         ? 'Choose file'
//                         : (sitePhoto!.name),
//                     onTap: _pickSitePhoto,
//                     subLabel:
//                         sitePhoto == null ? 'No file chosen' : 'Selected',
//                     preview: sitePhoto?.path,
//                   ),
//                 ],
//               ),
//             ),

//             // ------------------ COMPLETION + ACK ------------------
//             const SizedBox(height: 22),
//             Row(
//               children: [
//                 const Text(
//                   'Completion',
//                   style: TextStyle(
//                     color: kPrimary,
//                     fontWeight: FontWeight.w800,
//                     fontSize: 20,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '${_completedChecks}/${_totalChecks} checks',
//                   style: const TextStyle(
//                     color: kPrimary,
//                     fontWeight: FontWeight.w800,
//                     fontSize: 18,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             _Divider(),

//             CheckboxListTile(
//               value: safetyAck,
//               onChanged: (v) => setState(() => safetyAck = v ?? false),
//               controlAffinity: ListTileControlAffinity.leading,
//               contentPadding: EdgeInsets.zero,
//               title: const Text(
//                 'I acknowledge my duty to work safely and follow safety rules under the relevant state/territory WHS/OHS laws. If conditions change or become unsafe I will stop work and report immediately',
//                 style: TextStyle(height: 1.35),
//               ),
//             ),

//             const SizedBox(height: 8),

//             // ------------------ BUTTONS ------------------
//             SizedBox(
//               height: 52,
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed: () {},
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: kPrimary,
//                   side: const BorderSide(color: kPrimary, width: 1.4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'REPORT HAZARD',
//                   style:
//                       TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 52,
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: safetyAck && _completedChecks == _totalChecks
//                     ? () {}
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: kPrimary,
//                   disabledBackgroundColor: kPrimary.withOpacity(.35),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'START TASK',
//                   style:
//                       TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 52,
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed: () {},
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.black87,
//                   side: const BorderSide(color: Color(0xFFCBC6D7)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: const Text(
//                   'CANCEL TASK',
//                   style: TextStyle(
//                       fontWeight: FontWeight.w800, color: Colors.black87),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ================================ WIDGETS ================================ */

// class _SectionHeading extends StatelessWidget {
//   const _SectionHeading(
//       {required this.icon, required this.title, this.trailing});
//   final IconData icon;
//   final String title;
//   final String? trailing;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, color: _PrestartSafetyCheckScreenState.kPrimary),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: _PrestartSafetyCheckScreenState.kPrimary,
//           ),
//         ),
//         if (trailing != null) ...[
//           const SizedBox(width: 6),
//           Text(
//             trailing!,
//             style: const TextStyle(color: Colors.black54, fontSize: 14.5),
//           ),
//         ],
//       ],
//     );
//   }
// }

// class _RoundedContainer extends StatelessWidget {
//   const _RoundedContainer({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: const Color(0xFFE8E2F5)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.06),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           )
//         ],
//       ),
//       child: child,
//     );
//   }
// }

// class _SectionCard extends StatelessWidget {
//   const _SectionCard({
//     required this.leadingIcon,
//     required this.title,
//     required this.subtitle,
//     required this.children,
//   });

//   final IconData leadingIcon;
//   final String title;
//   final String subtitle;
//   final List<Widget> children;

//   @override
//   Widget build(BuildContext context) {
//     return _RoundedContainer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: _PrestartSafetyCheckScreenState.kPrimary,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.notifications, // replaced by leadingIcon
//                   color: Colors.transparent), // keeps padding consistent
//             ),
//             Positioned.fill(
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Icon(leadingIcon, color: Colors.white),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                           fontWeight: FontWeight.w800, fontSize: 18)),
//                   const SizedBox(height: 2),
//                   Text(subtitle,
//                       style: TextStyle(
//                         color: Colors.grey.shade700,
//                         height: 1.25,
//                       )),
//                 ],
//               ),
//             ),
//           ]),
//           const SizedBox(height: 14),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

// class _CheckTile extends StatelessWidget {
//   const _CheckTile({
//     required this.label,
//     required this.checked,
//     required this.notApplicable,
//     required this.onChanged,
//     required this.onNAChanged,
//   });

//   final String label;
//   final bool checked;
//   final bool notApplicable;
//   final ValueChanged<bool?> onChanged;
//   final ValueChanged<bool> onNAChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFDFD9EC)),
//       ),
//       child: Row(
//         children: [
//           Checkbox(
//             value: checked,
//             onChanged: notApplicable ? null : onChanged,
//             activeColor: const Color(0xFF2E7D32),
//           ),
//           const SizedBox(width: 4),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w700, color: _PrestartSafetyCheckScreenState.kPrimary)),
//                 const SizedBox(height: 4),
//                 Text('Not applicable',
//                     style: TextStyle(color: Colors.grey.shade600)),
//               ],
//             ),
//           ),
//           Switch.adaptive(
//             value: notApplicable,
//             onChanged: onNAChanged,
//             activeColor: const Color(0xFF2E7D32),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TextField extends StatelessWidget {
//   const _TextField({
//     required this.controller,
//     required this.hint,
//     this.maxLines = 1,
//   });

//   final TextEditingController controller;
//   final String hint;
//   final int maxLines;

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: const Color(0xFFF4F3F8),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFFE8E2F5)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFFE8E2F5)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(
//               color: _PrestartSafetyCheckScreenState.kPrimary, width: 1.4),
//         ),
//       ),
//     );
//   }
// }

// class _UploadBox extends StatelessWidget {
//   const _UploadBox({
//     required this.label,
//     required this.subLabel,
//     required this.onTap,
//     this.preview,
//   });

//   final String label;
//   final String subLabel;
//   final VoidCallback onTap;
//   final String? preview;

//   @override
//   Widget build(BuildContext context) {
//     final border = Border.all(
//       color: const Color(0xFFD6D0E2),
//       width: 1.2,
//     );

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: border,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.file_upload_outlined, color: _PrestartSafetyCheckScreenState.kPrimary),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(label,
//                       style: const TextStyle(
//                           fontWeight: FontWeight.w800,
//                           color: _PrestartSafetyCheckScreenState.kPrimary)),
//                   const SizedBox(height: 2),
//                   Text(subLabel, style: TextStyle(color: Colors.grey.shade600)),
//                 ],
//               ),
//             ),
//             if (preview != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.file(
//                   File(preview!),
//                   width: 46,
//                   height: 46,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SubtleLead extends StatelessWidget {
//   const _SubtleLead({required this.icon, required this.text});
//   final IconData icon;
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.black54),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(color: Colors.black54, height: 1.35),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _Divider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Container(
//         height: 1,
//         width: double.infinity,
//         color: const Color(0xFFE8E2F5),
//       );
// }

// class _GreyCaption extends StatelessWidget {
//   const _GreyCaption(this.text);
//   final String text;
//   @override
//   Widget build(BuildContext context) =>
//       Text(text, style: TextStyle(color: Colors.grey.shade600, height: 1.3));
// }

// class _BodySmall extends StatelessWidget {
//   const _BodySmall(this.text);
//   final String text;
//   @override
//   Widget build(BuildContext context) =>
//       Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
// }

// class _SectionSubTitle extends StatelessWidget {
//   const _SectionSubTitle(this.text);
//   final String text;
//   @override
//   Widget build(BuildContext context) => Text(
//         text,
//         style: const TextStyle(
//           color: _PrestartSafetyCheckScreenState.kPrimary,
//           fontWeight: FontWeight.w800,
//           fontSize: 16,
//         ),
//       );
// }

// /* ------------------------------ Simple model ------------------------------ */

// class _CheckItem {
//   final String title;
//   bool checked;
//   bool notApplicable;
//   _CheckItem(this.title, {this.checked = false, this.notApplicable = false});
// }
