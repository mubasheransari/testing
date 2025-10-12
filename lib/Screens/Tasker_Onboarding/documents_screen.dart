import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Models/services_group_model.dart';


class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.selectedServices});

  /// Services the user selected on the previous screen.
  final List<ServiceItem> selectedServices;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const purple = Color(0xFF7841BA);
  static const softBG = Color(0xFFF9F7FF);

  // General uploads (unchanged)
  String? idPath;
  String? addressPath;
  String? insurancePath;

  /// One file per selected service (serviceId → fileName/path)
  late final Map<int, String?> _serviceCertFiles = {
    for (final s in widget.selectedServices) s.id: null,
  };

  bool get _allServiceCertsUploaded =>
      _serviceCertFiles.values.every((v) => v != null && v!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    print('IDS ::::: ${widget.selectedServices}');
    print('IDS ::::: ${widget.selectedServices}');
    print('IDS ::::: ${widget.selectedServices}');
    const currentStep = 4;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: softBG,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 170,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Documents',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Tasker Onboarding',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('$currentStep/$totalSteps',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.black54)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey,
                    valueColor: const AlwaysStoppedAnimation(purple),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Progress',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54)),
                    const Spacer(),
                    Text('${(progress * 100).round()}% complete',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
                  child: Text(
                      "We need to verify your identity and qualifications. All documents are securely encrypted.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
            children: [
              // General cards (same as before)
              DocumentUploadCard(
                title: 'ID Verification',
                subtitle: 'Government-issued photo ID',
                requiredBadge: RequiredBadge.required,
                pickedFileName: idPath,
                onChooseFile: () async {
                  setState(() => idPath = 'id_document.pdf'); // TODO: integrate picker
                },
              ),
              const SizedBox(height: 18),
              DocumentUploadCard(
                title: 'Proof of Address',
                subtitle: 'Utility bill or bank statement',
                requiredBadge: RequiredBadge.required,
                pickedFileName: addressPath,
                onChooseFile: () async {
                  setState(() => addressPath = 'address_bill.pdf');
                },
              ),
              const SizedBox(height: 18),

              // ---------- Professional Certifications (dynamic) ----------
              _ProfessionalCertsSection(
                services: widget.selectedServices,
                serviceFiles: _serviceCertFiles,
                onPick: (serviceId, pickedName) {
                  setState(() => _serviceCertFiles[serviceId] = pickedName);
                },
              ),
              // -----------------------------------------------------------

              const SizedBox(height: 18),
              DocumentUploadCard(
                title: 'Insurance Documents',
                subtitle: 'Liability insurance (optional)',
                requiredBadge: RequiredBadge.optional,
                pickedFileName: insurancePath,
                onChooseFile: () async {
                  setState(() => insurancePath = 'liability_insurance.png');
                },
              ),
              const SizedBox(height: 18),
              const IdentityVerificationCard(status: 'Pending'),
            ],
          ),

          // Sticky bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor:
                          _allServiceCertsUploaded ? purple : purple.withOpacity(.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: !_allServiceCertsUploaded
                        ? null
                        : () {
                            // Build your API payload
                            final certUploads = <Map<String, dynamic>>[
                              for (final s in widget.selectedServices)
                                {
                                  'serviceId': s.id,
                                  'fileName': _serviceCertFiles[s.id],
                                }
                            ];

                            // TODO: call upload API here with:
                            // idPath, addressPath, insurancePath, certUploads

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All service certificates added ✔')),
                            );
                          },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.1, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Professional Certs (dynamic) ---------------- */

class _ProfessionalCertsSection extends StatelessWidget {
  const _ProfessionalCertsSection({
    required this.services,
    required this.serviceFiles,
    required this.onPick,
  });

  final List<ServiceItem> services;
  final Map<int, String?> serviceFiles;
  final void Function(int serviceId, String pickedFileName) onPick;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFEFF6)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
            SizedBox(width: 8),
            Text('Professional Certifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(width: 10),
            _Badge(text: 'Required', color: Color(0xFFFF4D4F), bg: Color(0xFFFFE7E7)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Upload the certificate/license for each service you selected.',
            style: TextStyle(color: Colors.black.withOpacity(.65)),
          ),
          const SizedBox(height: 12),

          for (final s in services) ...[
            const SizedBox(height: 6),
            DocumentUploadCard(
              title: s.name,
              subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
              requiredBadge: RequiredBadge.required,
              pickedFileName: serviceFiles[s.id],
              onChooseFile: () async {
                // TODO: integrate file/image picker; using placeholder name for now
                onPick(s.id, '${s.name}.pdf');
              },
            ),
          ],
        ],
      ),
    );
  }
}

/* ---------------- Reusable Cards ---------------- */

enum RequiredBadge { required, optional, none }

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.requiredBadge,
    required this.onChooseFile,
    this.pickedFileName,
  });

  final String title;
  final String subtitle;
  final RequiredBadge requiredBadge;
  final VoidCallback onChooseFile;
  final String? pickedFileName;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: const Color(0xFFEFEFF6));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (requiredBadge != RequiredBadge.none)
                _Badge(
                  text: requiredBadge == RequiredBadge.required ? 'Required' : 'Optional',
                  color: requiredBadge == RequiredBadge.required
                      ? const Color(0xFFFF4D4F)
                      : const Color(0xFF9AA3AF),
                  bg: requiredBadge == RequiredBadge.required
                      ? const Color(0xFFFFE7E7)
                      : const Color(0xFFF2F4F7),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(.65))),
          const SizedBox(height: 14),
          DottedBorder(
            color: const Color(0xFFE1E1EA),
            dashPattern: const [6, 6],
            strokeWidth: 1.4,
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            child: InkWell(
              onTap: onChooseFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.upload_circle_fill,
                          color: Color(0xFF53688F),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pickedFileName == null ? 'Tap to upload document' : pickedFileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF344054),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text('PDF, JPG, PNG up to 10MB',
                          style: TextStyle(color: Color(0xFF667085), fontSize: 12)),
                      const SizedBox(height: 14),
                      _GhostButton(text: 'Choose File', onPressed: onChooseFile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IdentityVerificationCard extends StatelessWidget {
  const IdentityVerificationCard({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFEFF6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF9C8CE0)),
            SizedBox(width: 8),
            Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(
            "We need to verify your identity and qualifications. All documents are securely encrypted.",
            style: TextStyle(color: Colors.black.withOpacity(.70)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFF),
              border: Border.all(color: const Color(0xFFF0F2F7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Text('Status:', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                _Badge(text: 'Pending', color: Color(0xFF6B7280), bg: Color(0xFFF2F4F7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.bg});
  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}


// class DocumentsScreen extends StatefulWidget {
//   const DocumentsScreen({super.key});

//   @override
//   State<DocumentsScreen> createState() => _DocumentsScreenState();
// }

// class _DocumentsScreenState extends State<DocumentsScreen> {
//   static const purple = Color(0xFF7841BA);
//   static const softBG = Color(0xFFF9F7FF);

//   // fake “picked file” states (wire to image_picker/file_picker as needed)
//   String? idPath;
//   String? addressPath;
//   String? certPath;
//   String? insurancePath;

//   @override
//   Widget build(BuildContext context) {
//     const currentStep = 4;
//     const totalSteps = 7;
//     final progress = currentStep / totalSteps;
//     return Scaffold(
//       backgroundColor: softBG,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         toolbarHeight: 170,
//         automaticallyImplyLeading: false,
//         elevation: 0,
//         // surfaceTintColor: Colors.transparent,
//         centerTitle: false,
//         titleSpacing: 20,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Upload Documents',
//                 style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 2),
//             Text('Tasker Onboarding',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyMedium
//                     ?.copyWith(color: Colors.black54)),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: Text('$currentStep/$totalSteps',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyLarge
//                     ?.copyWith(color: Colors.black54)),
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(36),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
//             child: Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(999),
//                   child: LinearProgressIndicator(
//                     value: progress,
//                     minHeight: 6,
//                     backgroundColor: Colors.grey,
//                     valueColor: const AlwaysStoppedAnimation(Constants.purple),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     Text('Progress',
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.black54)),
//                     const Spacer(),
//                     Text('${(progress * 100).round()}% complete',
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(color: Colors.black54)),
//                   ],
//                 ),
//                 Padding(
//                   padding:
//                       const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
//                   child: Text(
//                       "We need to verify your identity and qualifications. All documents are securely encrypted.",
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodyMedium
//                           ?.copyWith(color: Colors.black54)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           ListView(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
//             children: [
//               DocumentUploadCard(
//                 title: 'ID Verification',
//                 subtitle: 'Government-issued photo ID',
//                 requiredBadge: RequiredBadge.required,
//                 pickedFileName: idPath,
//                 onChooseFile: () async {
//                   // TODO pick file
//                   setState(() => idPath = 'id_document.pdf');
//                 },
//               ),
//               const SizedBox(height: 18),
//               DocumentUploadCard(
//                 title: 'Proof of Address',
//                 subtitle: 'Utility bill or bank statement',
//                 requiredBadge: RequiredBadge.required,
//                 pickedFileName: addressPath,
//                 onChooseFile: () async {
//                   setState(() => addressPath = 'address_bill.pdf');
//                 },
//               ),
//               const SizedBox(height: 18),
//               DocumentUploadCard(
//                 title: 'Professional Certification',
//                 subtitle: 'Relevant licenses or certifications',
//                 requiredBadge: RequiredBadge.required,
//                 pickedFileName: certPath,
//                 onChooseFile: () async {
//                   setState(() => certPath = 'certificate.jpg');
//                 },
//               ),
//               const SizedBox(height: 18),
//               DocumentUploadCard(
//                 title: 'Insurance Documents',
//                 subtitle: 'Liability insurance (optional)',
//                 requiredBadge: RequiredBadge.optional,
//                 pickedFileName: insurancePath,
//                 onChooseFile: () async {
//                   setState(() => insurancePath = 'liability_insurance.png');
//                 },
//               ),
//               const SizedBox(height: 18),
//               const IdentityVerificationCard(status: 'Pending'),
//             ],
//           ),

//           // Sticky bottom bar (edge-to-edge purple)
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0x1A000000),
//                     blurRadius: 20,
//                     offset: Offset(0, -6),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 top: false,
//                 minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: purple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => PaymentScreen()));
//                     },
//                     child: const Text(
//                       'Continue',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 0.1,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ---------------- Reusable Cards ---------------- */

// enum RequiredBadge { required, optional, none }

// class DocumentUploadCard extends StatelessWidget {
//   const DocumentUploadCard({
//     super.key,
//     required this.title,
//     required this.subtitle,
//     required this.requiredBadge,
//     required this.onChooseFile,
//     this.pickedFileName,
//   });

//   final String title;
//   final String subtitle;
//   final RequiredBadge requiredBadge;
//   final VoidCallback onChooseFile;
//   final String? pickedFileName;

//   @override
//   Widget build(BuildContext context) {
//     final border = Border.all(color: const Color(0xFFEFEFF6));
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: border,
//       ),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header row with badge
//           Row(
//             children: [
//               Text(
//                 title,
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(width: 10),
//               if (requiredBadge != RequiredBadge.none)
//                 _Badge(
//                   text: requiredBadge == RequiredBadge.required
//                       ? 'Required'
//                       : 'Optional',
//                   color: requiredBadge == RequiredBadge.required
//                       ? const Color(0xFFFF4D4F)
//                       : const Color(0xFF9AA3AF),
//                   bg: requiredBadge == RequiredBadge.required
//                       ? const Color(0xFFFFE7E7)
//                       : const Color(0xFFF2F4F7),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             subtitle,
//             style: TextStyle(color: Colors.black.withOpacity(.65)),
//           ),
//           const SizedBox(height: 14),

//           // Dashed drop-zone
//           DottedBorder(
//             color: const Color(0xFFE1E1EA),
//             dashPattern: const [6, 6],
//             strokeWidth: 1.4,
//             borderType: BorderType.RRect,
//             radius: const Radius.circular(16),
//             child: Container(
//               width: double.infinity,
//               height: 180,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFDFDFF),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEFF3FF),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: const Icon(
//                         CupertinoIcons.upload_circle_fill,
//                         color: Color(0xFF53688F),
//                         size: 28,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       pickedFileName == null
//                           ? 'Tap to upload document'
//                           : pickedFileName!,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF344054),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       'PDF, JPG, PNG up to 10MB',
//                       style: TextStyle(color: Color(0xFF667085), fontSize: 12),
//                     ),
//                     const SizedBox(height: 14),
//                     _GhostButton(text: 'Choose File', onPressed: onChooseFile),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class IdentityVerificationCard extends StatelessWidget {
//   const IdentityVerificationCard({super.key, required this.status});
//   final String status;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color(0xFFEFEFF6)),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: const [
//             Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF9C8CE0)),
//             SizedBox(width: 8),
//             Text('Identity Verification',
//                 style: TextStyle(fontWeight: FontWeight.w700)),
//           ]),
//           const SizedBox(height: 12),
//           Text(
//             "We need to verify your identity and qualifications. All documents are securely encrypted.",
//             style: TextStyle(color: Colors.black.withOpacity(.70)),
//           ),
//           const SizedBox(height: 14),
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFBFCFF),
//               border: Border.all(color: const Color(0xFFF0F2F7)),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 const Text('Status:',
//                     style: TextStyle(fontWeight: FontWeight.w700)),
//                 const SizedBox(width: 8),
//                 _Badge(
//                   text: status,
//                   color: const Color(0xFF6B7280),
//                   bg: const Color(0xFFF2F4F7),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ---------------- Small UI helpers ---------------- */

// class _Badge extends StatelessWidget {
//   const _Badge({required this.text, required this.color, required this.bg});
//   final String text;
//   final Color color;
//   final Color bg;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
// }

// class _GhostButton extends StatelessWidget {
//   const _GhostButton({required this.text, required this.onPressed});
//   final String text;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return OutlinedButton(
//       style: OutlinedButton.styleFrom(
//         side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
//         backgroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
//       ),
//       onPressed: onPressed,
//       child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
//     );
//   }
// }
