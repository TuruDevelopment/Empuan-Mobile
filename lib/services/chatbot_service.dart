import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatbotService {
  static const String baseUrl = 'http://192.168.8.48:8000/api';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  /// Send message and get AI response with streaming simulation
  /// Returns a stream that emits partial responses character by character
  Stream<String> sendMessageStream({
    required String message,
    String? sessionId,
    bool useHistory = true,
  }) async* {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          'use_history': useHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final fullResponse = data['data']['response'] as String;

          // Stream the response character by character for typewriter effect
          String currentText = '';

          // Split by words for more natural streaming
          final words = fullResponse.split(' ');

          for (int i = 0; i < words.length; i++) {
            currentText += words[i];
            if (i < words.length - 1) {
              currentText += ' ';
            }

            yield currentText;

            // Delay between words (faster for better UX)
            await Future.delayed(const Duration(milliseconds: 30));
          }

          // Ensure we yield the complete text at the end
          yield fullResponse;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in sendMessageStream: $e');
      yield '❌ Error: Failed to get response. Please try again.';
    }
  }

  /// Send message and get full AI response (non-streaming version)
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    bool useHistory = true,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        'use_history': useHistory,
      }),
    );

    return jsonDecode(response.body);
  }

  /// Create new session
  Future<String> createNewSession() async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/sessions/new'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    return data['data']['session_id'];
  }

  /// Get all sessions
  Future<List<ChatSession>> getSessions() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
    }

    return [];
  }

  /// Get chat history
  Future<List<ChatMessage>> getHistory(String sessionId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/history/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data']['history'] as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    }

    return [];
  }

  /// Delete session
  Future<bool> deleteSession(String sessionId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/chatbot/sessions/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
