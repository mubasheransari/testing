import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';

import '../../Constants/constants.dart';

class ApplicationReviewScreen extends StatelessWidget {
  const ApplicationReviewScreen({super.key});

  static const purple = Color(0xFF7841BA);
  static const bg = Color(0xFFF9F7FF);
  static const cardBorder = Color(0xFFEFEFF6);

  @override
  Widget build(BuildContext context) {
    const currentStep = 7;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 150,
        automaticallyImplyLeading: false,
        elevation: 0,
        // surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Application Review',
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
                    valueColor: const AlwaysStoppedAnimation(Constants.purple),
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
                  padding:
                      const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
                  child: Text(
                      "Your application is in review and we will let you know shortly about the status. Here's a summary of your submission.",
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            children: [
              // Top blue info banner
              _InfoBanner(
                title: 'Application Under Review',
                subtitle: 'Estimated review time: 1–2 business days',
              ),
              const SizedBox(height: 18),

              // Application Summary section label
              const _SectionTitle('Application Summary'),
              const SizedBox(height: 10),

              // Summary cards
              _SummaryCard(
                iconBg: const Color(0xFFEFF8FF),
                icon: CupertinoIcons.doc_text_fill,
                iconColor: const Color(0xFF2E90FA),
                title: 'Personal Information',
                lines:  [
                  'Name: ${context.read<AuthenticationBloc>().state.userDetails!.fullName.toString()}',
                  'Email: ${context.read<AuthenticationBloc>().state.userDetails!.email.toString()}',
                  'Phone: ${context.read<AuthenticationBloc>().state.userDetails!.phone.toString()}',
                ],
                badgeText: 'Completed',
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                iconBg: const Color(0xFFEFFCF4),
                icon: CupertinoIcons.rosette,
                iconColor: const Color(0xFF16A34A),
                title: 'Certifications & Services',
                lines: const [
                  'Certifications: 2 selected',
                  'Services: 1 chosen',
                  'Total eligible services: 13',
                ],
                badgeText: 'Completed',
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                iconBg: const Color(0xFFEFF8FF),
                icon: CupertinoIcons.doc_checkmark_fill,
                iconColor: const Color(0xFF2E90FA),
                title: 'Document Verification',
                lines: const [
                  'Documents uploaded: 3',
                  'KYC Status: Verified',
                ],
                badgeText: 'Completed',
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                iconBg: const Color(0xFFEFFCF4),
                icon: CupertinoIcons.checkmark_seal_fill,
                iconColor: const Color(0xFF16A34A),
                title: 'Payment',
                lines: const [
                  'Payment Status: Completed',
                ],
                badgeText: 'Completed',
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                iconBg: const Color(0xFFF4F3FF),
                icon: CupertinoIcons.rosette,
                iconColor: purple,
                title: 'Training',
                lines: const [
                  'All training modules completed',
                  'Certification requirements met',
                ],
                badgeText: 'Completed',
              ),

              const SizedBox(height: 18),
              const _SectionTitle('What Happens Next?'),
              const SizedBox(height: 10),
              _NextStepsCard(
                email: '${context.read<AuthenticationBloc>().state.userDetails!.email.toString()}',
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Need Help?'),
              const SizedBox(height: 10),
              const _HelpCard(),
            ],
          ),

          // Sticky bottom bar
       /*xewex   Align(
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Application Submitted',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    /*  const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9C4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.check_mark_circled_solid,
                                  size: 18, color: Color(0xFF5B21B6)),
                              SizedBox(width: 8),
                              Text(
                                'Application Submitted',
                                style: TextStyle(
                                  color: Color(0xFF5B21B6),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),*/
                  ],
                ),
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}

/* -------------------- Pieces -------------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.time, color: Color(0xFF4A7BD0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF2C59A6))),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(color: Colors.black.withOpacity(.70))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
    required this.badgeText,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFEFF6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5),
                      ),
                    ),
                    _CompletedBadge(text: badgeText),
                  ],
                ),
                const SizedBox(height: 8),
                for (final l in lines) ...[
                  Text(l,
                      style: TextStyle(
                        color: Colors.black.withOpacity(.72),
                        height: 1.35,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7C3AED),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Our team will review your application and documents'
          'This typically takes 1–2 business days'),
      ("You'll receive an email notification with the decision"
          'Check your email at $email'),
      ('If approved, you can start accepting jobs immediately'
          'Access your dashboard to manage your services'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFEFF6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NumberDot(index: i + 1),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i],
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        items[i],
                        style: TextStyle(color: Colors.black.withOpacity(.65)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: Colors.black.withOpacity(.06),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NumberDot extends StatelessWidget {
  const _NumberDot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Color(0xFF7C3AED),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFEFF6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520; // stack on small widths

          final email = _ContactTile(
            icon: CupertinoIcons.envelope_badge,
            title: 'Email Support',
            subtitle: 'support@taskerplatform.com',
          );

          final phone = _ContactTile(
            icon: CupertinoIcons.phone_circle_fill,
            title: 'Phone Support',
            subtitle: '1-800-TASKER-1',
            alignRight: !isNarrow,
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                email,
                const SizedBox(height: 12),
                phone,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: email),
              const SizedBox(width: 16),
              Expanded(
                  child: Align(alignment: Alignment.centerRight, child: phone)),
            ],
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.alignRight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        // Let the text wrap instead of overflowing
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
