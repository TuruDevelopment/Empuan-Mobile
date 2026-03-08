import 'package:flutter/material.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/services/wellness_service.dart';

/// Dialog for prompting user to upgrade from general to health version
/// 
/// Usage:
/// ```dart
/// final result = await UpgradeDialog.show(context);
/// if (result == true) {
///   // User upgraded successfully
/// }
/// ```
class UpgradeDialog extends StatelessWidget {
  const UpgradeDialog({super.key});

  /// Show upgrade dialog
  /// 
  /// Returns true if user upgraded successfully, false otherwise
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const UpgradeDialog(),
    );
  }

  /// Show upgrade dialog with auto-upgrade in progress
  static Future<bool?> showWithUpgrade(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _UpgradeProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.background,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upgrade_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Unlock Period Tracking',
              style: TextStyle(
                fontFamily: 'Brodies',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Upgrade to health version to access period tracking features and get personalized health insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Benefits list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.calendar_month_rounded,
                    title: 'Track Your Cycle',
                    description: 'Monitor your menstrual health',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.insights_rounded,
                    title: 'Get Predictions',
                    description: 'Know when your next period is due',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.analytics_rounded,
                    title: 'View Statistics',
                    description: 'Understand your health patterns',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitRow(
                    icon: Icons.favorite_rounded,
                    title: 'All Wellness Features',
                    description: 'Keep all your wellness data',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                // Later button
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Upgrade button
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryVariant,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upgrade_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upgrade Now',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Progress dialog shown during upgrade
class _UpgradeProgressDialog extends StatefulWidget {
  @override
  State<_UpgradeProgressDialog> createState() => _UpgradeProgressDialogState();
}

class _UpgradeProgressDialogState extends State<_UpgradeProgressDialog> {
  String _status = 'Upgrading your account...';

  @override
  void initState() {
    super.initState();
    _performUpgrade();
  }

  Future<void> _performUpgrade() async {
    // Simulate minimum display time for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    final result = await WellnessService().upgradeToHealth();
    
    if (!mounted) return;

    if (result == 'upgraded' || result == 'already_upgraded') {
      setState(() {
        _status = result == 'upgraded' 
            ? 'Successfully upgraded!' 
            : 'Already upgraded!';
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _status = 'Upgrade failed';
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.background,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.upgrade_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Status text
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Please wait while we upgrade your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
