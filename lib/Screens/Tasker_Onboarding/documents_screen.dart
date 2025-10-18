import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/service_document_model.dart';
import 'package:taskoon/Models/services_group_model.dart' as ms;
import 'package:taskoon/Screens/Tasker_Onboarding/payment_screen.dart';

import '../../Models/services_group_model.dart';

import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
// lib/Screens/Tasker_Onboarding/documents_screen.dart
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';

// Use your real models (fix paths if needed)
import '../../Models/service_document_model.dart' as md;
import '../../Models/services_ui_model.dart' as ms;

// lib/Screens/Tasker_Onboarding/documents_screen.dart
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 👇 your models (update paths if needed)
import '../../Models/service_document_model.dart' as md;
import '../../Models/services_ui_model.dart' as ms;

// 👇 your bloc (update path if needed)
// e.g., '../../bloc/authentication_bloc.dart' or wherever your bloc lives.

/// ---------- Bytes model kept in-memory ----------
class PickedDoc {
  final String name;
  final Uint8List bytes;
  final String ext;
  final int size;
  final String? mime;
  const PickedDoc({
    required this.name,
    required this.bytes,
    required this.ext,
    required this.size,
    this.mime,
  });
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.userId,             // <-- used when dispatching events
    required this.selectedServices,
    required this.selectedDocs,
  });

  final String userId; // <-- pass in on navigation
  final List<ms.ServiceItem> selectedServices;
  final List<md.ServiceDocument> selectedDocs;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const purple = Color(0xFF7841BA);
  static const softBG = Color(0xFFF9F7FF);

  // General uploads (not sent here; different API likely)
  PickedDoc? idDoc;
  PickedDoc? addressDoc;
  PickedDoc? insuranceDoc;

  // One file per (serviceId, documentId)
  final Map<String, PickedDoc?> _docFiles = {}; // key: '$serviceId:$documentId'
  String _k(int sId, int dId) => '$sId:$dId';

  bool get _allServiceCertsUploaded {
    if (widget.selectedDocs.isEmpty) return true;
    for (final d in widget.selectedDocs) {
      final v = _docFiles[_k(d.serviceId, d.documentId)];
      if (v == null || v.bytes.isEmpty) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    for (final d in widget.selectedDocs) {
      _docFiles[_k(d.serviceId, d.documentId)] = null;
    }
  }

  // -------- File picking (bytes) helpers --------
  static const _maxBytes = 10 * 1024 * 1024; // 10MB
  static const _exts = ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'];

  Future<PickedDoc?> _pickDoc() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _exts,
    );
    final file = result?.files.single;
    if (file == null) return null;

    final size = file.size;
    if (size > _maxBytes) {
      _err('File is too large. Max allowed is 10 MB.');
      return null;
    }

    final name = file.name;
    final ext = (name.split('.').lastOrNull ?? '').toLowerCase();
    if (!_exts.contains(ext)) {
      _err('Unsupported file type .$ext. Use: PDF, JPG, PNG, HEIC, WEBP');
      return null;
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _err('Could not read file bytes. Try a different file.');
      return null;
    }

    return PickedDoc(
      name: name,
      bytes: bytes,
      ext: ext,
      size: size,
      mime: _guessMime(ext),
    );
  }

  void _err(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String? _guessMime(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const currentStep = 4;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    // Group docs by service
    final Map<int, List<md.ServiceDocument>> docsByService = {};
    for (final d in widget.selectedDocs) {
      docsByService.putIfAbsent(d.serviceId, () => []).add(d);
    }

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (p, n) => p.certificateSubmitStatus != n.certificateSubmitStatus,
      listener: (context, state) {
        switch (state.certificateSubmitStatus) {
          case CertificateSubmitStatus.uploading:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading document…')),
            );
            break;
          case CertificateSubmitStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded ✔')),
            );
            break;
          case CertificateSubmitStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.certificateSubmitError ?? 'Upload failed')),
            );
            break;
          case CertificateSubmitStatus.initial:
            break;
        }
      },
      child: Scaffold(
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
              Text('Upload Documents', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('Tasker Onboarding',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text('$currentStep/$totalSteps',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
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
                // —— General cards (local only) ——
                DocumentUploadCard(
                  title: 'ID Verification',
                  subtitle: 'Government-issued photo ID',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName: idDoc == null ? null : '${idDoc!.name}  •  ${_fmtBytes(idDoc!.size)}',
                  onChooseFile: () async {
                    final picked = await _pickDoc();
                    if (picked != null) setState(() => idDoc = picked);
                  },
                ),
                const SizedBox(height: 18),
                DocumentUploadCard(
                  title: 'Proof of Address',
                  subtitle: 'Utility bill or bank statement',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName:
                      addressDoc == null ? null : '${addressDoc!.name}  •  ${_fmtBytes(addressDoc!.size)}',
                  onChooseFile: () async {
                    final picked = await _pickDoc();
                    if (picked != null) setState(() => addressDoc = picked);
                  },
                ),
                const SizedBox(height: 18),

                // —— Professional Certifications (per required document) ——
                _ProfessionalCertsSection(
                  userId: widget.userId, // <-- for event dispatch
                  services: widget.selectedServices,
                  docsByService: docsByService,
                  docFiles: _docFiles,
                  onPick: (serviceId, documentId, picked) {
                    setState(() => _docFiles[_k(serviceId, documentId)] = picked);
                  },
                  fmtSize: _fmtBytes,
                  pickDoc: _pickDoc,
                ),

                const SizedBox(height: 18),
                DocumentUploadCard(
                  title: 'Insurance Documents',
                  subtitle: 'Liability insurance (optional)',
                  requiredBadge: RequiredBadge.optional,
                  pickedFileName: insuranceDoc == null
                      ? null
                      : '${insuranceDoc!.name}  •  ${_fmtBytes(insuranceDoc!.size)}',
                  onChooseFile: () async {
                    final picked = await _pickDoc();
                    if (picked != null) setState(() => insuranceDoc = picked);
                  },
                ),
                const SizedBox(height: 18),
                const IdentityVerificationCard(status: 'Pending'),
              ],
            ),

            // —— Sticky bottom bar ——
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
                        backgroundColor: _allServiceCertsUploaded ? purple : purple.withOpacity(.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> PaymentScreen()));
                      },
                      // onPressed: !_allServiceCertsUploaded
                      //     ? null
                      //     : () {
                      //         final bloc = context.read<AuthenticationBloc>();

                      //         // Dispatch one event per picked required doc
                      //         for (final d in widget.selectedDocs) {
                      //           final p = _docFiles[_k(d.serviceId, d.documentId)];
                      //           if (p != null) {

                      //             print('USER ID : ${widget.userId}');
                      //             print('SERVICES ID : ${d.serviceId}');
                      //             print('DOCUMENT ID : ${d.documentId}');
                      //             print('BYTES : ${p.bytes}');
                      //             print('FILENAME : ${p.name}');
                      //             print('USER ID : ${p.mime}');


                      //             // bloc.add(SubmitCertificateBytesRequested(
                      //             //   userId: widget.userId,
                      //             //   serviceId: d.serviceId,
                      //             //   documentId: d.documentId,
                      //             //   bytes: p.bytes,
                      //             //   fileName: p.name,
                      //             //   mimeType: p.mime,
                      //             // ));
                      //           }
                      //         }

                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           const SnackBar(content: Text('Uploading your documents…')),
                      //         );
                      //       },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Professional Certs (dynamic by document) ---------------- */

class _ProfessionalCertsSection extends StatelessWidget {
  const _ProfessionalCertsSection({
    required this.userId,
    required this.services,
    required this.docsByService,        // serviceId -> list of docs
    required this.docFiles,             // key "$sid:$did" -> PickedDoc?
    required this.onPick,
    required this.fmtSize,
    required this.pickDoc,
  });

  final String userId;
  final List<ms.ServiceItem> services;
  final Map<int, List<md.ServiceDocument>> docsByService;
  final Map<String, PickedDoc?> docFiles;
  final void Function(int serviceId, int documentId, PickedDoc picked) onPick;
  final String Function(int bytes) fmtSize;
  final Future<PickedDoc?> Function() pickDoc;

  String _k(int sId, int dId) => '$sId:$dId';

  @override
  Widget build(BuildContext context) {
    final hasAnyDocs = docsByService.isNotEmpty;

    if (!hasAnyDocs) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFEFF6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionHeader(),
            SizedBox(height: 8),
            Text('No professional certifications are required for your selections.',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

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
          const _SectionHeader(),
          const SizedBox(height: 8),
          Text(
            'Upload the certificate/license for each required document.',
            style: TextStyle(color: Colors.black.withOpacity(.65)),
          ),
          const SizedBox(height: 12),

          // For each selected service, list its required documents
          for (final s in services)
            if (docsByService[s.id]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.work_outline, color: Color(0xFF9C8CE0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const _Badge(
                    text: 'Required',
                    color: Color(0xFFFF4D4F),
                    bg: Color(0xFFFFE7E7),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              for (final d in docsByService[s.id]!) ...[
                const SizedBox(height: 6),
                DocumentUploadCard(
                  title: d.documentName,
                  subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName: docFiles[_k(d.serviceId, d.documentId)] == null
                      ? null
                      : '${docFiles[_k(d.serviceId, d.documentId)]!.name}  •  ${fmtSize(docFiles[_k(d.serviceId, d.documentId)]!.size)}',
                  onChooseFile: () async {
                    final picked = await pickDoc();
                    if (picked != null) {
                      // 1) update UI
                      onPick(d.serviceId, d.documentId, picked);

                      // 2) dispatch upload event immediately
                      context.read<AuthenticationBloc>().add(
                        SubmitCertificateBytesRequested(
                          userId: userId,
                          serviceId: d.serviceId,
                          documentId: d.documentId,
                          bytes: picked.bytes,
                          fileName: picked.name,
                          mimeType: picked.mime,
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
      SizedBox(width: 8),
      Text('Professional Certifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]);
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

// tiny extension
extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}


/// Bytes container kept in-memory only (no paths).
// class PickedDoc {
//   final String name;
//   final Uint8List bytes;
//   final String ext;
//   final int size;
//   final String? mime; // optional
//   const PickedDoc({
//     required this.name,
//     required this.bytes,
//     required this.ext,
//     required this.size,
//     this.mime,
//   });
// }

// class DocumentsScreen extends StatefulWidget {
//   const DocumentsScreen({
//     super.key,
//     required this.selectedServices,
//     required this.selectedDocs, // required documents per service
//   });

//   /// Services the user selected on the previous screen.
//   final List<ms.ServiceItem> selectedServices;

//   /// Required documents for those selected services.
//   final List<md.ServiceDocument> selectedDocs;

//   @override
//   State<DocumentsScreen> createState() => _DocumentsScreenState();
// }

// class _DocumentsScreenState extends State<DocumentsScreen> {
//   static const purple = Color(0xFF7841BA);
//   static const softBG = Color(0xFFF9F7FF);

//   // General uploads (bytes only)
//   PickedDoc? idDoc;
//   PickedDoc? addressDoc;
//   PickedDoc? insuranceDoc;

//   // One file per (serviceId, documentId)
//   final Map<String, PickedDoc?> _docFiles = {}; // key: '$serviceId:$documentId'

//   String _k(int sId, int dId) => '$sId:$dId';

//   bool get _allServiceCertsUploaded {
//     if (widget.selectedDocs.isEmpty) return true; // nothing required
//     for (final d in widget.selectedDocs) {
//       final v = _docFiles[_k(d.serviceId, d.documentId)];
//       if (v == null || v.bytes.isEmpty) return false;
//     }
//     return true;
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Initialize keys for all required docs
//     for (final d in widget.selectedDocs) {
//       _docFiles[_k(d.serviceId, d.documentId)] = null;
//     }
//   }

//   // -------- File picking (bytes) helpers --------
//   static const _maxBytes = 10 * 1024 * 1024; // 10MB
//   static const _exts = ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'];

//   Future<PickedDoc?> _pickDoc() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: false,
//       withData: true, // <- important to get bytes
//       type: FileType.custom,
//       allowedExtensions: _exts,
//     );
//     final file = result?.files.single;
//     if (file == null) return null;

//     // Validate size
//     final size = file.size;
//     if (size > _maxBytes) {
//       _err('File is too large. Max allowed is 10 MB.');
//       return null;
//     }

//     // Validate extension
//     final name = file.name;
//     final ext = (name.split('.').lastOrNull ?? '').toLowerCase();
//     if (!_exts.contains(ext)) {
//       _err('Unsupported file type .$ext. Use: PDF, JPG, PNG, HEIC, WEBP');
//       return null;
//     }

//     final bytes = file.bytes;
//     if (bytes == null || bytes.isEmpty) {
//       _err('Could not read file bytes. Try a different file.');
//       return null;
//     }

//     return PickedDoc(
//       name: name,
//       bytes: bytes,
//       ext: ext,
//       size: size,
//       mime: _guessMime(ext),
//     );
//   }

//   void _err(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   String _fmtBytes(int b) {
//     if (b < 1024) return '$b B';
//     if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
//     return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }

//   static String? _guessMime(String ext) {
//     switch (ext) {
//       case 'pdf':
//         return 'application/pdf';
//       case 'jpg':
//       case 'jpeg':
//         return 'image/jpeg';
//       case 'png':
//         return 'image/png';
//       case 'heic':
//         return 'image/heic';
//       case 'webp':
//         return 'image/webp';
//       default:
//         return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const currentStep = 4;
//     const totalSteps = 7;
//     final progress = currentStep / totalSteps;

//     // Group docs by service for nicer UI sections
//     final Map<int, List<md.ServiceDocument>> docsByService = {};
//     for (final d in widget.selectedDocs) {
//       docsByService.putIfAbsent(d.serviceId, () => []).add(d);
//     }

//     return Scaffold(
//       backgroundColor: softBG,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         toolbarHeight: 170,
//         automaticallyImplyLeading: false,
//         elevation: 0,
//         centerTitle: false,
//         titleSpacing: 20,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Upload Documents', style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 2),
//             Text('Tasker Onboarding',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20),
//             child: Text('$currentStep/$totalSteps',
//                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
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
//                     valueColor: const AlwaysStoppedAnimation(purple),
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
//                   padding: const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
//                   child: Text(
//                     "We need to verify your identity and qualifications. All documents are securely encrypted.",
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
//                   ),
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
//               // —— General cards ——
//               DocumentUploadCard(
//                 title: 'ID Verification',
//                 subtitle: 'Government-issued photo ID',
//                 requiredBadge: RequiredBadge.required,
//                 pickedFileName: idDoc == null ? null : '${idDoc!.name}  •  ${_fmtBytes(idDoc!.size)}',
//                 onChooseFile: () async {
//                   final picked = await _pickDoc();
//                   if (picked != null) setState(() => idDoc = picked);
//                 },
//               ),
//               const SizedBox(height: 18),
//               DocumentUploadCard(
//                 title: 'Proof of Address',
//                 subtitle: 'Utility bill or bank statement',
//                 requiredBadge: RequiredBadge.required,
//                 pickedFileName: addressDoc == null ? null : '${addressDoc!.name}  •  ${_fmtBytes(addressDoc!.size)}',
//                 onChooseFile: () async {
//                   final picked = await _pickDoc();
//                   if (picked != null) setState(() => addressDoc = picked);
//                 },
//               ),
//               const SizedBox(height: 18),

//               // —— Professional Certifications (per required document) ——
//               _ProfessionalCertsSection(
//                 services: widget.selectedServices,
//                 docsByService: docsByService,
//                 docFiles: _docFiles,
//                 onPick: (serviceId, documentId, picked) {
//                   setState(() => _docFiles[_k(serviceId, documentId)] = picked);
//                 },
//                 fmtSize: _fmtBytes,
//                 pickDoc: _pickDoc,
//               ),

//               const SizedBox(height: 18),
//               DocumentUploadCard(
//                 title: 'Insurance Documents',
//                 subtitle: 'Liability insurance (optional)',
//                 requiredBadge: RequiredBadge.optional,
//                 pickedFileName: insuranceDoc == null ? null : '${insuranceDoc!.name}  •  ${_fmtBytes(insuranceDoc!.size)}',
//                 onChooseFile: () async {
//                   final picked = await _pickDoc();
//                   if (picked != null) setState(() => insuranceDoc = picked);
//                 },
//               ),
//               const SizedBox(height: 18),
//               const IdentityVerificationCard(status: 'Pending'),
//             ],
//           ),

//           // —— Sticky bottom bar ——
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -6))],
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
//                       backgroundColor: _allServiceCertsUploaded ? purple : purple.withOpacity(.4),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                     onPressed: !_allServiceCertsUploaded
//                         ? null
//                         : () {
//                             // Build an in-memory payload (bytes-only, no API).
//                             final general = {
//                               if (idDoc != null)
//                                 'id': {
//                                   'name': idDoc!.name,
//                                   'size': idDoc!.size,
//                                   'bytes': idDoc!.bytes,
//                                   'mime': idDoc!.mime
//                                 },
//                               if (addressDoc != null)
//                                 'address': {
//                                   'name': addressDoc!.name,
//                                   'size': addressDoc!.size,
//                                   'bytes': addressDoc!.bytes,
//                                   'mime': addressDoc!.mime
//                                 },
//                               if (insuranceDoc != null)
//                                 'insurance': {
//                                   'name': insuranceDoc!.name,
//                                   'size': insuranceDoc!.size,
//                                   'bytes': insuranceDoc!.bytes,
//                                   'mime': insuranceDoc!.mime
//                                 },
//                             };

//                             final certUploads = <Map<String, dynamic>>[
//                               for (final d in widget.selectedDocs)
//                                 {
//                                   'serviceId': d.serviceId,
//                                   'serviceName': d.serviceName,
//                                   'documentId': d.documentId,
//                                   'documentName': d.documentName,
//                                   if (_docFiles[_k(d.serviceId, d.documentId)] != null)
//                                     'file': {
//                                       'name': _docFiles[_k(d.serviceId, d.documentId)]!.name,
//                                       'size': _docFiles[_k(d.serviceId, d.documentId)]!.size,
//                                       'bytes': _docFiles[_k(d.serviceId, d.documentId)]!.bytes,
//                                       'mime': _docFiles[_k(d.serviceId, d.documentId)]!.mime,
//                                     }
//                                 }
//                             ];

//                             // For now: just log to confirm it works.
//                             debugPrint('GENERAL: ${general.map((k, v) => MapEntry(k, (v['size'])))}');
//                             debugPrint('CERTS: ${certUploads.map((e) => {
//                               'sid': e['serviceId'],
//                               'did': e['documentId'],
//                               'size': (e['file']?['size'])
//                             }).toList()}');

//                             // ScaffoldMessenger.of(context).showSnackBar(
//                             //   const SnackBar(content: Text('All required documents captured in memory ✔')),
//                             // );

//                             // Next phase: send 'bytes' via multipart/form-data or base64 to your API.
//                              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen()));
//                           },
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

// /* ---------------- Professional Certs (dynamic by document) ---------------- */

// class _ProfessionalCertsSection extends StatelessWidget {
//   const _ProfessionalCertsSection({
//     required this.services,
//     required this.docsByService,        // serviceId -> list of docs
//     required this.docFiles,             // key "$sid:$did" -> PickedDoc?
//     required this.onPick,
//     required this.fmtSize,
//     required this.pickDoc,
//   });

//   final List<ms.ServiceItem> services;
//   final Map<int, List<md.ServiceDocument>> docsByService;
//   final Map<String, PickedDoc?> docFiles;
//   final void Function(int serviceId, int documentId, PickedDoc picked) onPick;
//   final String Function(int bytes) fmtSize;
//   final Future<PickedDoc?> Function() pickDoc;

//   String _k(int sId, int dId) => '$sId:$dId';

//   @override
//   Widget build(BuildContext context) {
//     final hasAnyDocs = docsByService.isNotEmpty;

//     if (!hasAnyDocs) {
//       return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0xFFEFEFF6)),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             _SectionHeader(),
//             SizedBox(height: 8),
//             Text('No professional certifications are required for your selections.',
//                 style: TextStyle(color: Colors.black54)),
//           ],
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color(0xFFEFEFF6)),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const _SectionHeader(),
//           const SizedBox(height: 8),
//           Text(
//             'Upload the certificate/license for each required document.',
//             style: TextStyle(color: Colors.black.withOpacity(.65)),
//           ),
//           const SizedBox(height: 12),

//           // For each selected service, list its required documents
//           for (final s in services)
//             if (docsByService[s.id]?.isNotEmpty ?? false) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(Icons.work_outline, color: Color(0xFF9C8CE0)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       s.name,
//                       style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                   const _Badge(
//                     text: 'Required',
//                     color: Color(0xFFFF4D4F),
//                     bg: Color(0xFFFFE7E7),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),

//               for (final d in docsByService[s.id]!) ...[
//                 const SizedBox(height: 6),
//                 DocumentUploadCard(
//                   title: d.documentName, // show document title
//                   subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
//                   requiredBadge: RequiredBadge.required,
//                   pickedFileName: docFiles[_k(d.serviceId, d.documentId)] == null
//                       ? null
//                       : '${docFiles[_k(d.serviceId, d.documentId)]!.name}  •  ${fmtSize(docFiles[_k(d.serviceId, d.documentId)]!.size)}',
//                   onChooseFile: () async {
//                     final picked = await pickDoc();
//                     if (picked != null) onPick(d.serviceId, d.documentId, picked);
//                   },
//                 ),
//               ],
//             ],
//         ],
//       ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader();

//   @override
//   Widget build(BuildContext context) {
//     return Row(children: const [
//       Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
//       SizedBox(width: 8),
//       Text('Professional Certifications',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//     ]);
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
//           Row(
//             children: [
//               Expanded(
//                 child: Text(title,
//                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//               ),
//               if (requiredBadge != RequiredBadge.none)
//                 _Badge(
//                   text: requiredBadge == RequiredBadge.required ? 'Required' : 'Optional',
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
//           Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(.65))),
//           const SizedBox(height: 14),
//           DottedBorder(
//             color: const Color(0xFFE1E1EA),
//             dashPattern: const [6, 6],
//             strokeWidth: 1.4,
//             borderType: BorderType.RRect,
//             radius: const Radius.circular(16),
//             child: InkWell(
//               onTap: onChooseFile,
//               borderRadius: BorderRadius.circular(16),
//               child: Container(
//                 width: double.infinity,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFDFDFF),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFEFF3FF),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Icon(
//                           CupertinoIcons.upload_circle_fill,
//                           color: Color(0xFF53688F),
//                           size: 28,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         pickedFileName == null ? 'Tap to upload document' : pickedFileName!,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF344054),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 6),
//                       const Text('PDF, JPG, PNG up to 10MB',
//                           style: TextStyle(color: Color(0xFF667085), fontSize: 12)),
//                       const SizedBox(height: 14),
//                       _GhostButton(text: 'Choose File', onPressed: onChooseFile),
//                     ],
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
//             Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.w700)),
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
//               children: const [
//                 Text('Status:', style: TextStyle(fontWeight: FontWeight.w700)),
//                 SizedBox(width: 8),
//                 _Badge(text: 'Pending', color: Color(0xFF6B7280), bg: Color(0xFFF2F4F7)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Badge extends StatelessWidget {
//   const _Badge({required this.text, required this.color, required this.bg});
//   final String text;
//   final Color color;
//   final Color bg;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
//       child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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

// // tiny extension
// extension _LastOrNull<T> on List<T> {
//   T? get lastOrNull => isEmpty ? null : last;
// }


/*
// ——— DocumentsScreen.dart ———
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.selectedServices,
    required this.selectedDocs, // <<<<<< ADD
  });

  /// Services the user selected on the previous screen.
  final List<ServiceItem> selectedServices;

  /// Required documents for those selected services.
  final List<ServiceDocument> selectedDocs; // <<<<<< ADD

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const purple = Color(0xFF7841BA);
  static const softBG = Color(0xFFF9F7FF);

  // General uploads
  String? idPath;
  String? addressPath;
  String? insurancePath;

  // One file per (serviceId, documentId)
  final Map<String, String?> _docFiles = {}; // key: '$serviceId:$documentId'

  String _k(int sId, int dId) => '$sId:$dId';

  bool get _allServiceCertsUploaded {
    if (widget.selectedDocs.isEmpty) return true; // nothing required
    for (final d in widget.selectedDocs) {
      final v = _docFiles[_k(d.serviceId, d.documentId)];
      if (v == null || v.isEmpty) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Initialize keys for all required docs
    for (final d in widget.selectedDocs) {
      _docFiles[_k(d.serviceId, d.documentId)] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const currentStep = 4;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    // Group docs by service for nicer UI sections
    final Map<int, List<ServiceDocument>> docsByService = {};
    for (final d in widget.selectedDocs) {
      docsByService.putIfAbsent(d.serviceId, () => []).add(d);
    }

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
            Text('Upload Documents', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Tasker Onboarding',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('$currentStep/$totalSteps',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
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
              // —— General cards ——
              DocumentUploadCard(
                title: 'ID Verification',
                subtitle: 'Government-issued photo ID',
                requiredBadge: RequiredBadge.required,
                pickedFileName: idPath,
                onChooseFile: () async {
                  // TODO: integrate file picker
                  setState(() => idPath = 'id_document.pdf');
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

              // —— Professional Certifications (per required document) ——
              _ProfessionalCertsSection(
                services: widget.selectedServices,
                docsByService: docsByService,           // <<<<<< ADD
                docFiles: _docFiles,                    // <<<<<< ADD
                onPick: (serviceId, documentId, pickedName) {
                  setState(() => _docFiles[_k(serviceId, documentId)] = pickedName);
                },
              ),

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

          // —— Sticky bottom bar ——
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
                      backgroundColor: _allServiceCertsUploaded ? purple : purple.withOpacity(.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: !_allServiceCertsUploaded
                        ? null
                        : () {
                            // Build payload for per-document uploads
                            final certUploads = <Map<String, dynamic>>[
                              for (final d in widget.selectedDocs)
                                {
                                  'serviceId': d.serviceId,
                                  'serviceName': d.serviceName,
                                  'documentId': d.documentId,
                                  'documentName': d.documentName,
                                  'fileName': _docFiles[_k(d.serviceId, d.documentId)],
                                }
                            ];

                            // TODO: Call your upload API with:
                            // idPath, addressPath, insurancePath, certUploads

                            // Example next step (e.g., payment):
                            // Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen()));

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All required certificates added ✔')),
                            );
                          },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        fontSize: 16,
                      ),
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

/* ---------------- Professional Certs (dynamic by document) ---------------- */

class _ProfessionalCertsSection extends StatelessWidget {
  const _ProfessionalCertsSection({
    required this.services,
    required this.docsByService,        // serviceId -> list of docs
    required this.docFiles,             // key "$sid:$did" -> filename
    required this.onPick,
  });

  final List<ServiceItem> services;
  final Map<int, List<ServiceDocument>> docsByService;
  final Map<String, String?> docFiles;
  final void Function(int serviceId, int documentId, String pickedFileName) onPick;

  String _k(int sId, int dId) => '$sId:$dId';

  @override
  Widget build(BuildContext context) {
    final hasAnyDocs = docsByService.isNotEmpty;

    if (!hasAnyDocs) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFEFF6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SectionHeader(),
            SizedBox(height: 8),
            Text('No professional certifications are required for your selections.',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

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
          const _SectionHeader(),
          const SizedBox(height: 8),
          Text(
            'Upload the certificate/license for each required document.',
            style: TextStyle(color: Colors.black.withOpacity(.65)),
          ),
          const SizedBox(height: 12),

          // For each selected service, list its required documents
          for (final s in services)
            if (docsByService[s.id]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.work_outline, color: Color(0xFF9C8CE0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const _Badge(
                    text: 'Required',
                    color: Color(0xFFFF4D4F),
                    bg: Color(0xFFFFE7E7),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              for (final d in docsByService[s.id]!) ...[
                const SizedBox(height: 6),
                DocumentUploadCard(
                  title: d.documentName, // show document title
                  subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName: docFiles[_k(d.serviceId, d.documentId)],
                  onChooseFile: () async {
                    // TODO: integrate file picker; using placeholder name
                    onPick(d.serviceId, d.documentId, '${d.documentName}.pdf');
                  },
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
      SizedBox(width: 8),
      Text('Professional Certifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]);
  }
}

/* ---------------- Reusable Cards (unchanged from your file) ---------------- */
// enum RequiredBadge { required, optional, none }
// DocumentUploadCard, IdentityVerificationCard, _Badge, _GhostButton


/*
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

                                                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentScreen()));

                            

                            // TODO: call upload API here with:
                            // idPath, addressPath, insurancePath, certUploads

                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(content: Text('All service certificates added ✔')),
                            // );
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
}*/

/* ---------------- Professional Certs (dynamic) ---------------- */

// class _ProfessionalCertsSection extends StatelessWidget {
//   const _ProfessionalCertsSection({
//     required this.services,
//     required this.serviceFiles,
//     required this.onPick,
//   });

//   final List<ServiceItem> services;
//   final Map<int, String?> serviceFiles;
//   final void Function(int serviceId, String pickedFileName) onPick;

//   @override
//   Widget build(BuildContext context) {
//     if (services.isEmpty) return const SizedBox.shrink();

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color(0xFFEFEFF6)),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: const [
//             Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
//             SizedBox(width: 8),
//             Text('Professional Certifications',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
//             SizedBox(width: 10),
//             _Badge(text: 'Required', color: Color(0xFFFF4D4F), bg: Color(0xFFFFE7E7)),
//           ]),
//           const SizedBox(height: 8),
//           Text(
//             'Upload the certificate/license for each service you selected.',
//             style: TextStyle(color: Colors.black.withOpacity(.65)),
//           ),
//           const SizedBox(height: 12),

//           for (final s in services) ...[
//             const SizedBox(height: 6),
//             DocumentUploadCard(
//               title: s.name,
//               subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
//               requiredBadge: RequiredBadge.required,
//               pickedFileName: serviceFiles[s.id],
//               onChooseFile: () async {
//                 // TODO: integrate file/image picker; using placeholder name for now
//                 onPick(s.id, '${s.name}.pdf');
//               },
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//}

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
*/

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
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => PaymentScreen()));
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
