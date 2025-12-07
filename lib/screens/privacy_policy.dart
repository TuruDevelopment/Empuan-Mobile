import 'package:flutter/material.dart';
import 'package:Empuan/styles/style.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

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
                      'Privacy Policy',
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
                              'At Empuan, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, store, and protect your data when you use our mobile application. By using Empuan, you consent to the data practices described in this policy.',
                        ),

                        _buildSection(
                          title: '2. Information We Collect',
                          content:
                              'We collect several types of information to provide and improve our services:\n\n• Personal Information: Name, email address, date of birth, phone number, and profile picture\n\n• Health Information: Menstrual cycle data, period start and end dates, symptoms, and related health information\n\n• Emergency Contacts: Names and phone numbers of your emergency contacts\n\n• Community Content: Posts, comments, and interactions in Suara Puan and Ruang Puan forums\n\n• Usage Data: App usage patterns, features accessed, and interaction data\n\n• Device Information: Device type, operating system, unique device identifiers, and mobile network information\n\n• Location Data: Location information when using emergency features (with your permission)',
                        ),

                        _buildSection(
                          title: '3. How We Use Your Information',
                          content:
                              'We use your information for the following purposes:\n\n• To provide and maintain the App\'s functionality\n• To personalize your experience and provide tailored health insights\n• To send notifications about your menstrual cycle and health reminders\n• To enable communication in community forums\n• To facilitate emergency contact features and safety services\n• To improve our App through analytics and user feedback\n• To respond to your questions and support requests\n• To detect, prevent, and address technical issues or fraud\n• To comply with legal obligations',
                        ),

                        _buildSection(
                          title: '4. Data Storage and Security',
                          content:
                              'We implement industry-standard security measures to protect your personal information:\n\n• All data transmitted between your device and our servers is encrypted using SSL/TLS\n• Your password is encrypted using secure hashing algorithms\n• We store your data on secure servers with restricted access\n• We regularly update our security practices to address new threats\n• We conduct periodic security audits and assessments\n\nHowever, no method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
                        ),

                        _buildSection(
                          title: '5. Data Sharing and Disclosure',
                          content:
                              'We do not sell your personal information to third parties. We may share your information only in the following circumstances:\n\n• With Your Consent: When you explicitly authorize us to share information\n\n• Service Providers: We may share data with trusted third-party service providers who help us operate the App (e.g., cloud hosting, analytics). These providers are contractually obligated to protect your data\n\n• Legal Requirements: We may disclose information if required by law, court order, or governmental regulation\n\n• Safety and Protection: To protect the rights, property, or safety of Empuan, our users, or the public\n\n• Business Transfers: In the event of a merger, acquisition, or sale of assets, your information may be transferred',
                        ),

                        _buildSection(
                          title: '6. Your Rights and Choices',
                          content:
                              'You have several rights regarding your personal information:\n\n• Access: You can view and access your data through the App\n\n• Correction: You can update or correct your information in your profile settings\n\n• Deletion: You can request deletion of your account and data through the App settings\n\n• Export: You can request a copy of your data in a portable format\n\n• Opt-out: You can opt out of certain data collection and notifications in the App settings\n\n• Withdraw Consent: You can withdraw consent for data processing at any time\n\nTo exercise these rights, contact us at support@empuan.com or use the in-app settings.',
                        ),

                        _buildSection(
                          title: '7. Children\'s Privacy',
                          content:
                              'Empuan is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that we have collected information from a child under 13, we will delete it immediately. If you believe we have collected information from a child under 13, please contact us.',
                        ),

                        _buildSection(
                          title: '8. Third-Party Services',
                          content:
                              'Our App may contain links to third-party websites or integrate with third-party services. This Privacy Policy does not apply to those external services. We encourage you to review the privacy policies of any third-party services you access through our App.',
                        ),

                        _buildSection(
                          title: '9. International Data Transfers',
                          content:
                              'Your information may be transferred to and processed in countries other than your country of residence. These countries may have different data protection laws. We ensure that appropriate safeguards are in place to protect your information in accordance with this Privacy Policy.',
                        ),

                        _buildSection(
                          title: '10. Data Retention',
                          content:
                              'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy. When you delete your account, we will delete or anonymize your personal information within 30 days, except where we are required to retain it for legal or regulatory purposes.',
                        ),

                        _buildSection(
                          title: '11. Changes to This Privacy Policy',
                          content:
                              'We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. When we make significant changes, we will notify you through the App or via email. The "Last Updated" date at the top of this policy indicates when it was last revised. Your continued use of the App after changes constitutes acceptance of the updated policy.',
                        ),

                        _buildSection(
                          title: '12. Contact Us',
                          content:
                              'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:\n\nEmail: support@empuan.com\nWebsite: www.empuan.com\n\nWe will respond to your inquiry within 30 days.',
                        ),

                        const SizedBox(height: 24),

                        // Privacy Commitment
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
                                Icons.shield_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Privacy Matters',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'We are committed to protecting your privacy and empowering you with control over your personal information.',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
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
