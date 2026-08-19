import 'package:Empuan/features/learning/models/learning_models.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/learning/widgets/learning_widgets.dart';
import 'package:Empuan/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LearningCertificateScreen extends StatefulWidget {
  const LearningCertificateScreen({
    super.key,
    required this.courseSlug,
    required this.service,
  });

  final String courseSlug;
  final LearningService service;

  @override
  State<LearningCertificateScreen> createState() =>
      _LearningCertificateScreenState();
}

class _LearningCertificateScreenState extends State<LearningCertificateScreen> {
  late Future<LearningCertificate> _certificateFuture;

  @override
  void initState() {
    super.initState();
    _certificateFuture = widget.service.getCertificate(widget.courseSlug);
  }

  void _reload() {
    setState(() {
      _certificateFuture = widget.service.getCertificate(widget.courseSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Certificate')),
      body: FutureBuilder<LearningCertificate>(
        future: _certificateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return LearningErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final certificate = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      certificate.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Awarded to',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.recipientName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'has completed the course',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.courseTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 19,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      certificate.issuedAt == null
                          ? ''
                          : DateFormat('dd MMM yyyy')
                              .format(certificate.issuedAt!.toLocal()),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.certificateNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: certificate.certificateNumber),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificate number copied.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy certificate number'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This certificate confirms completion of an Empuan educational '
                'course and is not a professional certification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
