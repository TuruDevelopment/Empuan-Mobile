import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/services/wellness_service.dart';

/// Helper class for period tracking operations with auto-upgrade support
/// 
/// This class wraps the catatan-haid (period tracking) API endpoints
/// and automatically handles app version upgrades.
/// 
/// Usage:
/// ```dart
/// // Simple usage with auto-upgrade
/// await PeriodTrackingHelper.submitPeriodData(
///   startDate: DateTime.now().subtract(Duration(days: 5)),
///   endDate: DateTime.now(),
///   autoUpgrade: true, // Auto-upgrade if needed
/// );
/// ```
class PeriodTrackingHelper {
  /// Submit period data with optional auto-upgrade
  /// 
  /// Parameters:
  /// - [startDate]: Period start date (required)
  /// - [endDate]: Period end date (optional)
  /// - [autoUpgrade]: If true, automatically upgrade user from general to health (default: true)
  /// - [onUpgrade]: Callback when user is auto-upgraded (optional)
  /// 
  /// Returns:
  /// Map containing response data, or null if failed
  static Future<Map<String, dynamic>?> submitPeriodData({
    required DateTime startDate,
    DateTime? endDate,
    bool autoUpgrade = true,
    VoidCallback? onUpgrade,
  }) async {
    print('[PERIOD_TRACKING] Submitting period data...');
    print('[PERIOD_TRACKING] Start: ${startDate.toIso8601String().split('T')[0]}');
    print('[PERIOD_TRACKING] End: ${endDate?.toIso8601String().split('T')[0]}');
    print('[PERIOD_TRACKING] Auto-upgrade: $autoUpgrade');

    try {
      final body = <String, dynamic>{
        'start_date': startDate.toIso8601String().split('T')[0],
      };

      if (endDate != null) {
        body['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      // Add auto-upgrade flag
      if (autoUpgrade) {
        body['auto_upgrade'] = true;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.catatanHaid}');
      final response = await http.post(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[PERIOD_TRACKING] Submit status: ${response.statusCode}');
      print('[PERIOD_TRACKING] Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('[PERIOD_TRACKING] ✅ Period data submitted successfully');
        
        // Check if user was upgraded (response might include upgrade info)
        if (data['upgraded'] == true && onUpgrade != null) {
          print('[PERIOD_TRACKING] ℹ️ User was auto-upgraded to health version');
          onUpgrade();
        }
        
        return data;
      } else if (response.statusCode == 403) {
        // Forbidden - user needs to upgrade
        print('[PERIOD_TRACKING] ❌ 403 Forbidden - User needs upgrade');
        
        final errorData = jsonDecode(response.body);
        
        if (errorData['upgrade_available'] == true && autoUpgrade) {
          // Try auto-upgrade
          print('[PERIOD_TRACKING] Attempting auto-upgrade...');
          final upgradeResult = await WellnessService().upgradeToHealth();
          
          if (upgradeResult == 'upgraded' || upgradeResult == 'already_upgraded') {
            // Retry the request after upgrade
            print('[PERIOD_TRACKING] Upgrade successful, retrying...');
            return await submitPeriodData(
              startDate: startDate,
              endDate: endDate,
              autoUpgrade: false, // Don't loop
              onUpgrade: onUpgrade,
            );
          }
        }
        
        return null;
      } else {
        print('[PERIOD_TRACKING] ❌ Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[PERIOD_TRACKING] Error: $e');
      return null;
    }
  }

  /// Get period history
  /// 
  /// Parameters:
  /// - [history]: true to get all records (default: false)
  /// - [months]: Number of months to retrieve (default: 5)
  /// - [autoUpgrade]: Auto-upgrade if needed (default: true)
  /// 
  /// Returns:
  /// List of period records
  static Future<List<Map<String, dynamic>>?> getPeriodHistory({
    bool history = false,
    int months = 5,
    bool autoUpgrade = true,
  }) async {
    print('[PERIOD_TRACKING] Fetching period history...');

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.catatanHaid}?history=$history&months=$months'
      );
      
      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[PERIOD_TRACKING] Get history status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final periods = data['data'] as List;
        print('[PERIOD_TRACKING] ✅ Retrieved ${periods.length} records');
        return periods.map((p) => Map<String, dynamic>.from(p)).toList();
      } else if (response.statusCode == 403 && autoUpgrade) {
        // Try auto-upgrade
        print('[PERIOD_TRACKING] 403 - Attempting auto-upgrade...');
        final upgradeResult = await WellnessService().upgradeToHealth();
        
        if (upgradeResult == 'upgraded' || upgradeResult == 'already_upgraded') {
          // Retry
          return await getPeriodHistory(
            history: history,
            months: months,
            autoUpgrade: false,
          );
        }
        return null;
      } else {
        print('[PERIOD_TRACKING] ❌ Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[PERIOD_TRACKING] Error: $e');
      return null;
    }
  }

  /// Get period statistics and predictions
  /// 
  /// Parameters:
  /// - [months]: Number of months for stats (default: 6)
  /// - [autoUpgrade]: Auto-upgrade if needed (default: true)
  /// 
  /// Returns:
  /// Stats data including predictions
  static Future<Map<String, dynamic>?> getPeriodStats({
    int months = 6,
    bool autoUpgrade = true,
  }) async {
    print('[PERIOD_TRACKING] Fetching period stats...');

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.catatanHaid}/stats?months=$months'
      );
      
      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[PERIOD_TRACKING] Get stats status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[PERIOD_TRACKING] ✅ Stats fetched successfully');
        return data['data'];
      } else if (response.statusCode == 403 && autoUpgrade) {
        // Try auto-upgrade
        print('[PERIOD_TRACKING] 403 - Attempting auto-upgrade...');
        final upgradeResult = await WellnessService().upgradeToHealth();
        
        if (upgradeResult == 'upgraded' || upgradeResult == 'already_upgraded') {
          // Retry
          return await getPeriodStats(
            months: months,
            autoUpgrade: false,
          );
        }
        return null;
      } else {
        print('[PERIOD_TRACKING] ❌ Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[PERIOD_TRACKING] Error: $e');
      return null;
    }
  }

  /// Check if user can access period tracking
  /// 
  /// Returns:
  /// - 'health': User has health version
  /// - 'general': User has general version (can upgrade)
  /// - 'error': Unable to check
  static Future<String> checkAccess() async {
    try {
      final appVersion = await WellnessService().getAppVersion();
      return appVersion;
    } catch (e) {
      print('[PERIOD_TRACKING] Error checking access: $e');
      return 'error';
    }
  }

  /// Upgrade user to health version (manual upgrade)
  /// 
  /// Returns:
  /// - 'upgraded': Successfully upgraded
  /// - 'already_upgraded': User already has health version
  /// - 'error': Upgrade failed
  static Future<String> upgradeToHealth() async {
    print('[PERIOD_TRACKING] Manual upgrade to health...');
    return await WellnessService().upgradeToHealth();
  }
}
