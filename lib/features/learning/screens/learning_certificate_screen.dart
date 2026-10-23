import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../ui/em_ui.dart';
import '../models/learning_models.dart';
import '../services/learning_service.dart';
import '../widgets/learning_widgets.dart';

class LearningCertificateScreen extends StatefulWidget {
  const LearningCertificateScreen({super.key, required this.courseSlug, this.service, this.certificate});

  final String courseSlug;
  final LearningService? service;

  /// Shown straight away when the caller already has it, e.g. from the list.
  final LearningCertificate? certificate;

  @override
  State<LearningCertificateScreen> createState() => _LearningCertificateScreenState();
}

class _LearningCertificateScreenState extends State<LearningCertificateScreen> {
  late final LearningService _service = widget.service ?? LearningService();
  late Future<LearningCertificate> _future = _load();

  Future<LearningCertificate> _load() {
    final known = widget.certificate;
    if (known != null) return Future.value(known);
    return _service.getCertificate(widget.courseSlug);
  }

  Future<void> _reload() async {
    final future = _service.getCertificate(widget.courseSlug);
    setState(() => _future = future);
    await future;
  }

  Future<void> _share(LearningCertificate certificate) async {
    final lines = [
      'I completed “${certificate.courseTitle}” on Empuan.',
      if (certificate.certificateNumber.isNotEmpty) 'Certificate no. ${certificate.certificateNumber}',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: 'Empuan certificate'));
  }

  Future<void> _copy(LearningCertificate certificate) async {
    await Clipboard.setData(ClipboardData(text: certificate.certificateNumber));
    if (mounted) showEmToast(context, 'Certificate number copied', icon: Icons.check_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EmTopBar(title: 'Certificate'),
      body: FutureBuilder<LearningCertificate>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const EmLoading();
          if (snapshot.hasError) {
            return LearningScrollableState(
              onRefresh: _reload,
              child: EmStateView.error(message: '${snapshot.error}', onRetry: _reload),
            );
          }
          final certificate = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _CertificateCard(certificate: certificate),
              const SizedBox(height: 18),
              EmButton(label: 'Share', icon: Icons.ios_share_rounded, onPressed: () => _share(certificate)),
              if (certificate.certificateNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                EmButton(
                  label: 'Copy certificate number',
                  icon: Icons.copy_rounded,
                  variant: EmButtonVariant.text,
                  onPressed: () => _copy(certificate),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Confirms completion of an Empuan course. It isn’t a professional qualification.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.certificate});

  final LearningCertificate certificate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent),
        ),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        child: Column(
          children: [
            const EmWordmark(size: 30),
            const SizedBox(height: 6),
            const EmCaption('Certificate of completion', color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Awarded to', style: text.bodySmall),
            const SizedBox(height: 4),
            Text(certificate.recipientName, textAlign: TextAlign.center, style: text.headlineMedium),
            const SizedBox(height: 12),
            Text('for completing', style: text.bodySmall),
            const SizedBox(height: 4),
            Text(certificate.courseTitle, textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Fact(label: 'Issued', value: formatDate(certificate.issuedAt?.toLocal()))),
                Expanded(
                  child: _Fact(label: 'Certificate no.', value: certificate.certificateNumber, alignEnd: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        SelectableText(
          value.isEmpty ? '–' : value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
