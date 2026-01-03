import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/named_bytes.dart';
import 'package:taskoon/Models/services_group_model.dart' as ms;
import 'package:taskoon/Screens/Tasker_Onboarding/payment_screen.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../Models/service_document_model.dart' as md;
import 'package:flutter_bloc/flutter_bloc.dart';

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
    required this.userId, // <-- used when dispatching events
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

  PickedDoc? profilePicture;
  PickedDoc? idDoc;
  PickedDoc? addressDoc;
  PickedDoc? insuranceDoc;

  final Map<String, PickedDoc?> _docFiles = {};
  String _k(int sId, int dId) => '$sId:$dId';

  bool _isOptionalProDoc(md.ServiceDocument d) {
    final n = d.documentName.toLowerCase();
    return n.contains('(pro');
  }

  bool get _allServiceCertsUploaded {
    if (widget.selectedDocs.isEmpty) return true;

    for (final d in widget.selectedDocs) {
      if (_isOptionalProDoc(d)) continue;

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

  bool get _isSubmitting =>
    context.read<AuthenticationBloc>().state.onboardingStatus ==
    OnboardingStatus.submitting;

  @override
  Widget build(BuildContext context) {
    const currentStep = 4;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    final Map<int, List<md.ServiceDocument>> docsByService = {};
    for (final d in widget.selectedDocs) {
      docsByService.putIfAbsent(d.serviceId, () => []).add(d);
    }

    

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthenticationBloc, AuthenticationState>(
          listenWhen: (p, n) =>
              p.certificateSubmitStatus != n.certificateSubmitStatus,
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
                  SnackBar(
                    content: Text(
                      state.certificateSubmitError ?? 'Upload failed',
                    ),
                  ),
                );
                break;
              case CertificateSubmitStatus.initial:
                break;
            }
          },
        ),

        BlocListener<AuthenticationBloc, AuthenticationState>(
  listenWhen: (p, n) => p.onboardingStatus != n.onboardingStatus,
  listener: (context, s) {
    switch (s.onboardingStatus) {
      case OnboardingStatus.submitting:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitting onboarding…')),
        );
        break;

      case OnboardingStatus.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onboarding submitted ✔')),
        );

        // ✅ Navigate only when success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentScreen()),
        );
        break;

      case OnboardingStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.onboardingError ?? 'Onboarding failed')),
        );
        break;

      case OnboardingStatus.initial:
        break;
    }
  },
),


      /*  BlocListener<AuthenticationBloc, AuthenticationState>(
          listenWhen: (p, n) => p.onboardingStatus != n.onboardingStatus,
          listener: (context, s) {
            switch (s.onboardingStatus) {
              case OnboardingStatus.submitting:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submitting onboarding…')),
                );
                break;
              case OnboardingStatus.success:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding submitted ✔')),
                );
                break;
              case OnboardingStatus.failure:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.onboardingError ?? 'Onboarding failed'),
                  ),
                );
                break;
              case OnboardingStatus.initial:
                break;
            }
          },
        ),*/
      ],
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
              Text(
                'Upload Documents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Tasker Onboarding',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '$currentStep/$totalSteps',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
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
                      Text(
                        'Progress',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}% complete',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 14.0,
                      left: 14.0,
                      top: 10,
                    ),
                    child: Text(
                      "We need to verify your identity and qualifications. All documents are securely encrypted.",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
                DocumentUploadCard(
                  title: 'Profile Picture',
                  subtitle: 'Recent Profile Picture',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName: profilePicture == null
                      ? null
                      : '${profilePicture!.name}  •  ${_fmtBytes(profilePicture!.size)}',
                  onChooseFile: () async {
                    final picked = await _pickDoc();
                    if (picked != null) setState(() => profilePicture = picked);
                  },
                ),
                const SizedBox(height: 18),
                DocumentUploadCard(
                  title: 'ID Verification',
                  subtitle: 'Government-issued photo ID',
                  requiredBadge: RequiredBadge.required,
                  pickedFileName: idDoc == null
                      ? null
                      : '${idDoc!.name}  •  ${_fmtBytes(idDoc!.size)}',
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
                  pickedFileName: addressDoc == null
                      ? null
                      : '${addressDoc!.name}  •  ${_fmtBytes(addressDoc!.size)}',
                  onChooseFile: () async {
                    final picked = await _pickDoc();
                    if (picked != null) setState(() => addressDoc = picked);
                  },
                ),
                const SizedBox(height: 18),

                _ProfessionalCertsSection(
                  userId: widget.userId,
                  services: widget.selectedServices,
                  docsByService: docsByService,
                  docFiles: _docFiles,
                  onPick: (serviceId, documentId, picked) {
                    setState(
                      () => _docFiles[_k(serviceId, documentId)] = picked,
                    );
                  },
                  fmtSize: _fmtBytes,
                  pickDoc: _pickDoc,
                ),

                const SizedBox(height: 18),
                DocumentUploadCard(
                  title: 'Insurance Documents',
                  subtitle: 'Liability insurance',
                  requiredBadge: RequiredBadge.required,
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

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
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
                        backgroundColor: _allServiceCertsUploaded
                            ? purple
                            : purple.withOpacity(.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (!_allServiceCertsUploaded || _isSubmitting)
    ? null
    : () {
        if (profilePicture == null ||
            idDoc == null ||
            addressDoc == null ||
            insuranceDoc == null) {
          _err('Please upload Profile Picture, ID Verification, Address Proof and Insurance.');
          return;
        }

        NamedBytes _nb(PickedDoc p) => NamedBytes(
          fileName: p.name,
          bytes: p.bytes,
          mimeType: p.mime ?? _guessMime(p.ext) ?? 'application/octet-stream',
        );

        context.read<AuthenticationBloc>().add(
              OnboardUserRequested(
                userId: widget.userId,
                servicesId: const <int>[], // ignored in repo (hardcoded)
                profilePicture: _nb(profilePicture!),
                docCertification: null,
                docInsurance: _nb(insuranceDoc!),
                docAddressProof: _nb(addressDoc!),
                docIdVerification: _nb(idDoc!),
              ),
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
      ),
    );
  }
}

class _ProfessionalCertsSection extends StatelessWidget {
  const _ProfessionalCertsSection({
    required this.userId,
    required this.services,
    required this.docsByService,
    required this.docFiles,
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

  static bool _isOptionalName(String name) =>
      name.toLowerCase().contains('(pro');

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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(),
            SizedBox(height: 8),
            Text(
              'No professional certifications are required for your selections.',
              style: TextStyle(color: Colors.black54),
            ),
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

          for (final s in services)
            if (docsByService[s.id]?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.work_outline, color: Color(0xFF9C8CE0)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // const _Badge(
                  //   text: 'Required',
                  //   color: Color(0xFFFF4D4F),
                  //   bg: Color(0xFFFFE7E7),
                  // ),
                ],
              ),
              const SizedBox(height: 8),

              for (final d in docsByService[s.id]!) ...[
                const SizedBox(height: 6),

                // Decide per-document if it's required or optional based on "(Pro)" in name.
                Builder(
                  builder: (context) {
                    final isOptional = _isOptionalName(d.documentName);
                    final badge = isOptional
                        ? RequiredBadge.optional
                        : RequiredBadge.required;

                    return DocumentUploadCard(
                      title: d.documentName,
                      subtitle: 'Accepted: PDF, JPG, PNG up to 10MB',
                      requiredBadge: badge,
                      pickedFileName:
                          docFiles[_k(d.serviceId, d.documentId)] == null
                          ? null
                          : '${docFiles[_k(d.serviceId, d.documentId)]!.name}  •  ${fmtSize(docFiles[_k(d.serviceId, d.documentId)]!.size)}',
                      onChooseFile: () async {
                        final picked = await pickDoc();
                        if (picked != null) {
                          // 1) update UI
                          onPick(d.serviceId, d.documentId, picked);

                          // 2) dispatch upload event immediately (same behavior for optional/required)
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
                    );
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
    return const Row(
      children: [
        Icon(Icons.workspace_premium_rounded, color: Color(0xFF9C8CE0)),
        SizedBox(width: 8),
        Text(
          'Professional Certifications',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

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
    const red = Color(0xFFFF4D4F);
    const redBg = Color(0xFFFFE7E7);
    const green = Color(0xFF16A34A);
    const greenBg = Color(0xFFE8FBEE);

    final isRequired = requiredBadge == RequiredBadge.required;
    final isOptional = requiredBadge == RequiredBadge.optional;

    final badgeColor = isRequired
        ? red
        : (isOptional ? green : const Color(0xFF9AA3AF));
    final badgeBg = isRequired
        ? redBg
        : (isOptional ? greenBg : const Color(0xFFF2F4F7));

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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (requiredBadge != RequiredBadge.none)
                _Badge(
                  text: isRequired ? 'Required' : 'Optional',
                  color: badgeColor,
                  bg: badgeBg,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.black.withOpacity(.65)),
          ),
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
                        pickedFileName == null
                            ? 'Tap to upload document'
                            : pickedFileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF344054),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF, JPG, PNG up to 10MB',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GhostButton(
                        text: 'Choose File',
                        onPressed: onChooseFile,
                      ),
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
          const Row(
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: Color(0xFF9C8CE0),
              ),
              SizedBox(width: 8),
              Text(
                'Identity Verification',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
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
            child: const Row(
              children: [
                Text('Status:', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                _Badge(
                  text: 'Pending',
                  color: Color(0xFF6B7280),
                  bg: Color(0xFFF2F4F7),
                ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
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

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
