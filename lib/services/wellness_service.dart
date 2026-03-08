import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/services/auth_service.dart';

/// Service for handling wellness and auto-upgrade operations
/// 
/// This service provides methods to:
/// - Get wellness/health questions
/// - Submit onboarding answers
/// - Get/update user wellness profile
/// - Auto-upgrade from general to health version
/// - Check user's app version
class WellnessService {
  static final WellnessService _instance = WellnessService._internal();
  factory WellnessService() => _instance;
  WellnessService._internal();

  final String _baseUrl = ApiConfig.baseUrl;

  /// Get current user's app version
  /// Returns 'general' or 'health'
  Future<String> getAppVersion() async {
    try {
      final profile = await getProfile();
      return profile['data']['user']['app_version'] ?? 'general';
    } catch (e) {
      print('[WELLNESS_SERVICE] Error getting app version: $e');
      return 'general'; // Default to general on error
    }
  }

  /// Check if user has health version
  Future<bool> isHealthVersion() async {
    final appVersion = await getAppVersion();
    return appVersion == 'health';
  }

  /// Check if user has general version
  Future<bool> isGeneralVersion() async {
    final appVersion = await getAppVersion();
    return appVersion == 'general';
  }

  /// Get wellness/health questions from backend
  /// 
  /// Parameters:
  /// - [type]: 'wellness' or 'health' (default: 'wellness')
  /// - [limit]: Number of questions (default: 10, max: 50)
  /// 
  /// Returns:
  /// List of questions with their options
  Future<List<Map<String, dynamic>>> getQuestions({
    String type = 'wellness',
    int limit = 10,
  }) async {
    print('[WELLNESS_SERVICE] Fetching $type questions (limit: $limit)...');
    
    try {
      final url = Uri.parse(
        '$_baseUrl${ApiConfig.wellnessQuestions}?type=$type&limit=$limit'
      );
      
      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[WELLNESS_SERVICE] Get questions status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questions = data['data'] as List;
        print('[WELLNESS_SERVICE] Received ${questions.length} questions');
        return questions.map((q) => Map<String, dynamic>.from(q)).toList();
      } else {
        print('[WELLNESS_SERVICE] Failed to get questions: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error fetching questions: $e');
      return [];
    }
  }

  /// Submit onboarding answers
  /// 
  /// Parameters:
  /// - [answers]: List of answer objects with question_id, option_id, answer_text, answer_type
  /// - [activityLevel]: User's activity level (optional)
  /// - [sleepQuality]: User's sleep quality (optional)
  /// - [wellnessConcerns]: List of wellness concerns (optional)
  /// - [cycleRegularity]: For health version - cycle regularity (optional)
  /// - [lastPeriodStart]: For health version - last period start date (optional)
  /// - [lastPeriodEnd]: For health version - last period end date (optional)
  /// 
  /// Returns:
  /// True if successful, false otherwise
  Future<bool> submitOnboarding({
    required List<Map<String, dynamic>> answers,
    String? activityLevel,
    String? sleepQuality,
    List<String>? wellnessConcerns,
    String? cycleRegularity,
    String? lastPeriodStart,
    String? lastPeriodEnd,
  }) async {
    print('[WELLNESS_SERVICE] Submitting onboarding...');
    
    try {
      final body = <String, dynamic>{
        'answers': answers,
      };

      // Add wellness fields if provided
      if (activityLevel != null) {
        body['activity_level'] = activityLevel;
      }
      if (sleepQuality != null) {
        body['sleep_quality'] = sleepQuality;
      }
      if (wellnessConcerns != null) {
        body['wellness_concerns'] = wellnessConcerns;
      }

      // Add health-specific fields if provided
      if (cycleRegularity != null) {
        body['cycle_regularity'] = cycleRegularity;
      }
      if (lastPeriodStart != null) {
        body['last_period_start'] = lastPeriodStart;
      }
      if (lastPeriodEnd != null) {
        body['last_period_end'] = lastPeriodEnd;
      }

      print('[WELLNESS_SERVICE] Submitting to: $_baseUrl${ApiConfig.onboardingSubmit}');
      print('[WELLNESS_SERVICE] Request body: $body');

      final url = Uri.parse('$_baseUrl${ApiConfig.onboardingSubmit}');
      final response = await http.post(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[WELLNESS_SERVICE] Onboarding status: ${response.statusCode}');
      print('[WELLNESS_SERVICE] Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[WELLNESS_SERVICE] ✅ Onboarding submitted successfully');
        return true;
      } else {
        print('[WELLNESS_SERVICE] ❌ Onboarding failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error submitting onboarding: $e');
      return false;
    }
  }

  /// Get user's wellness profile
  /// 
  /// Returns:
  /// Profile data including user info and answers
  Future<Map<String, dynamic>> getProfile() async {
    print('[WELLNESS_SERVICE] Fetching wellness profile...');
    
    try {
      final url = Uri.parse('$_baseUrl${ApiConfig.wellnessProfile}');
      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[WELLNESS_SERVICE] Get profile status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[WELLNESS_SERVICE] ✅ Profile fetched successfully');
        return data;
      } else {
        print('[WELLNESS_SERVICE] ❌ Failed to get profile: ${response.body}');
        return {};
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error fetching profile: $e');
      return {};
    }
  }

  /// Update user's wellness profile
  /// 
  /// Parameters:
  /// - [activityLevel]: New activity level
  /// - [sleepQuality]: New sleep quality
  /// - [wellnessConcerns]: New wellness concerns list
  /// - [appVersion]: Can upgrade to 'health' this way
  /// 
  /// Returns:
  /// True if successful
  Future<bool> updateProfile({
    String? activityLevel,
    String? sleepQuality,
    List<String>? wellnessConcerns,
    String? appVersion,
  }) async {
    print('[WELLNESS_SERVICE] Updating profile...');
    
    try {
      final body = <String, dynamic>{};

      if (activityLevel != null) body['activity_level'] = activityLevel;
      if (sleepQuality != null) body['sleep_quality'] = sleepQuality;
      if (wellnessConcerns != null) body['wellness_concerns'] = wellnessConcerns;
      if (appVersion != null) body['app_version'] = appVersion;

      final url = Uri.parse('$_baseUrl${ApiConfig.wellnessProfile}');
      final response = await http.put(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[WELLNESS_SERVICE] Update profile status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[WELLNESS_SERVICE] ✅ Profile updated successfully');
        return true;
      } else {
        print('[WELLNESS_SERVICE] ❌ Failed to update profile: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error updating profile: $e');
      return false;
    }
  }

  /// Manually upgrade user from general to health version
  /// 
  /// Returns:
  /// - 'already_upgraded' if user already has health version
  /// - 'upgraded' if user was successfully upgraded
  /// - 'error' if upgrade failed
  Future<String> upgradeToHealth() async {
    print('[WELLNESS_SERVICE] Upgrading to health version...');
    
    try {
      final url = Uri.parse('$_baseUrl${ApiConfig.wellnessUpgradeToHealth}');
      final response = await http.post(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[WELLNESS_SERVICE] Upgrade status: ${response.statusCode}');
      print('[WELLNESS_SERVICE] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['already_upgraded'] == true) {
          print('[WELLNESS_SERVICE] ℹ️ User already has health version');
          return 'already_upgraded';
        } else {
          print('[WELLNESS_SERVICE] ✅ Successfully upgraded to health version');
          return 'upgraded';
        }
      } else {
        print('[WELLNESS_SERVICE] ❌ Upgrade failed: ${response.body}');
        return 'error';
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error upgrading: $e');
      return 'error';
    }
  }

  /// Get wellness statistics
  /// 
  /// Returns:
  /// Stats including total answers and profile summary
  Future<Map<String, dynamic>> getStats() async {
    print('[WELLNESS_SERVICE] Fetching wellness stats...');
    
    try {
      final url = Uri.parse('$_baseUrl${ApiConfig.wellnessStats}');
      final response = await http.get(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('[WELLNESS_SERVICE] Get stats status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[WELLNESS_SERVICE] ✅ Stats fetched successfully');
        return data['data'] ?? {};
      } else {
        print('[WELLNESS_SERVICE] ❌ Failed to get stats: ${response.body}');
        return {};
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error fetching stats: $e');
      return {};
    }
  }

  /// Submit wellness/health answers separately (without profile update)
  /// 
  /// Parameters:
  /// - [answers]: List of answer objects
  /// 
  /// Returns:
  /// True if successful
  Future<bool> submitAnswers({
    required List<Map<String, dynamic>> answers,
  }) async {
    print('[WELLNESS_SERVICE] Submitting answers...');
    
    try {
      final url = Uri.parse('$_baseUrl${ApiConfig.wellnessAnswers}');
      final response = await http.post(
        url,
        headers: {
          ...AuthService.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'answers': answers}),
      );

      print('[WELLNESS_SERVICE] Submit answers status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[WELLNESS_SERVICE] ✅ Answers submitted successfully');
        return true;
      } else {
        print('[WELLNESS_SERVICE] ❌ Failed to submit answers: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[WELLNESS_SERVICE] Error submitting answers: $e');
      return false;
    }
  }
}
