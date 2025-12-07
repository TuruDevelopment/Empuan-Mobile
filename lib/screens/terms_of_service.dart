import 'package:flutter/material.dart';
import 'package:Empuan/styles/style.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Last Updated
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Last Updated: December 3, 2025',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Introduction
                        _buildSection(
                          title: '1. Introduction',
                          content:
                              'Welcome to Empuan! These Terms of Service ("Terms") govern your use of the Empuan mobile application ("App") and services. By accessing or using our App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use our App.',
                        ),

                        _buildSection(
                          title: '2. Acceptance of Terms',
                          content:
                              'By creating an account or using our services, you confirm that you are at least 13 years of age and have the legal capacity to enter into these Terms. If you are under 18, you must have parental or guardian consent to use the App.',
                        ),

                        _buildSection(
                          title: '3. User Account',
                          content:
                              'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to:\n\n• Provide accurate and complete information during registration\n• Keep your password secure and confidential\n• Notify us immediately of any unauthorized access\n• Accept responsibility for all activities under your account',
                        ),

                        _buildSection(
                          title: '4. Use of the App',
                          content:
                              'Empuan is designed to provide women with health information, period tracking, emergency contacts, and community support. You agree to:\n\n• Use the App only for lawful purposes\n• Not violate any local, national, or international laws\n• Not transmit harmful, offensive, or inappropriate content\n• Respect other users\' privacy and rights\n• Not attempt to hack, disrupt, or misuse the App',
                        ),

                        _buildSection(
                          title: '5. Health Information Disclaimer',
                          content:
                              'The health information and AI assistant provided through Empuan are for informational purposes only and should not be considered medical advice. Always consult with qualified healthcare professionals for medical concerns. Empuan is not responsible for any decisions made based on information provided through the App.',
                        ),

                        _buildSection(
                          title: '6. Emergency Features',
                          content:
                              'Empuan provides emergency contact features including panic button and fake call functionality. While we strive to ensure these features work properly, we cannot guarantee their availability or functionality in all situations. In case of actual emergency, always contact local emergency services (112 in Indonesia).',
                        ),

                        _buildSection(
                          title: '7. Privacy and Data Protection',
                          content:
                              'We take your privacy seriously. Your use of the App is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal information. Please review our Privacy Policy to understand our practices.',
                        ),

                        _buildSection(
                          title: '8. User-Generated Content',
                          content:
                              'When you post content in community forums (Suara Puan, Ruang Puan), you grant Empuan a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content within the App. You are responsible for the content you post and agree that it:\n\n• Does not violate any laws or rights of others\n• Is not offensive, harmful, or inappropriate\n• Does not contain personal information of others without consent',
                        ),

                        _buildSection(
                          title: '9. Intellectual Property',
                          content:
                              'All content, features, and functionality of the App, including but not limited to text, graphics, logos, icons, images, and software, are the property of Empuan or its licensors and are protected by intellectual property laws. You may not copy, modify, distribute, or reverse engineer any part of the App without our written permission.',
                        ),

                        _buildSection(
                          title: '10. Termination',
                          content:
                              'We reserve the right to suspend or terminate your account at any time, with or without notice, for violations of these Terms or for any other reason at our sole discretion. You may also delete your account at any time through the App settings.',
                        ),

                        _buildSection(
                          title: '11. Limitation of Liability',
                          content:
                              'To the maximum extent permitted by law, Empuan and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the App. This includes but is not limited to damages for loss of data, profits, or other intangible losses.',
                        ),

                        _buildSection(
                          title: '12. Changes to Terms',
                          content:
                              'We may modify these Terms at any time. When we do, we will update the "Last Updated" date at the top of this page. Your continued use of the App after changes constitutes acceptance of the modified Terms. We encourage you to review these Terms periodically.',
                        ),

                        _buildSection(
                          title: '13. Governing Law',
                          content:
                              'These Terms shall be governed by and construed in accordance with the laws of the Republic of Indonesia, without regard to its conflict of law provisions.',
                        ),

                        _buildSection(
                          title: '14. Contact Information',
                          content:
                              'If you have any questions about these Terms of Service, please contact us at:\n\nEmail: support@empuan.com\nWebsite: www.empuan.com',
                        ),

                        const SizedBox(height: 24),

                        // Agreement Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'By using Empuan, you acknowledge that you have read and understood these Terms of Service and agree to be bound by them.',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
