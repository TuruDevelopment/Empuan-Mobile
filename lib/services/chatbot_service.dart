import 'dart:async';
import 'dart:convert';
import '../models/chat_message.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class ChatbotService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Send message and get AI response with streaming simulation
  /// Returns a stream that emits partial responses character by character
  Stream<String> sendMessageStream({
    required String message,
    String? sessionId,
    bool useHistory = true,
  }) async* {
    try {
      final response = await ApiClient.post(
        '$baseUrl/chatbot/send',
        body: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          'use_history': useHistory,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final fullResponse = data['data']['response'] as String;

          String currentText = '';
          final words = fullResponse.split(' ');

          for (int i = 0; i < words.length; i++) {
            currentText += words[i];
            if (i < words.length - 1) {
              currentText += ' ';
            }

            yield currentText;

            await Future.delayed(const Duration(milliseconds: 30));
          }

          yield fullResponse;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (_) {
      yield '❌ Error: Failed to get response. Please try again.';
    }
  }

  /// Send message and get full AI response (non-streaming version)
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    bool useHistory = true,
  }) async {
    final response = await ApiClient.post(
      '$baseUrl/chatbot/send',
      body: {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        'use_history': useHistory,
      },
    );

    return jsonDecode(response.body);
  }

  /// Create new session
  Future<String> createNewSession() async {
    final response = await ApiClient.post('$baseUrl/chatbot/sessions/new');

    final data = jsonDecode(response.body);
    return data['data']['session_id'];
  }

  /// Get all sessions
  Future<List<ChatSession>> getSessions() async {
    final response = await ApiClient.get('$baseUrl/chatbot/sessions');

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
    final response = await ApiClient.get('$baseUrl/chatbot/history/$sessionId');

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
    final response =
        await ApiClient.delete('$baseUrl/chatbot/sessions/$sessionId');

    return response.statusCode == 200;
  }
}
