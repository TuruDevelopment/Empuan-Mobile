# AI Chatbot API Documentation (Gemini)

## Overview

API chatbot menggunakan **Google Gemini AI (gemini-pro)** untuk memberikan respons AI yang natural dan contextual. Setiap user memiliki chat history sendiri yang tersimpan di database.

---

## Setup

### 1. Get Gemini API Key (FREE!)

1. Kunjungi: https://makersuite.google.com/app/apikey
2. Login dengan Google Account
3. Klik **"Create API Key"**
4. Copy API key yang didapat

### 2. Configure .env

```env
GEMINI_API_KEY=your-gemini-api-key-here
```

### 3. Run Migration

```bash
php artisan migrate
```

Migration akan membuat table `chat_histories`:

-   `id` - Primary key
-   `user_id` - Foreign key ke users table
-   `session_id` - UUID untuk grouping conversation
-   `role` - 'user' atau 'assistant'
-   `message` - Isi pesan
-   `created_at`, `updated_at`

---

## API Endpoints

### Base URL

```
http://192.168.8.48:8000/api
```

### Authentication

Semua endpoint memerlukan Bearer token di header:

```
Authorization: Bearer {your-token}
```

---

## 1. Send Message to Chatbot

**Endpoint**: `POST /chatbot/send`

Mengirim pesan ke AI dan mendapat response. Chat history otomatis tersimpan.

### Request Headers

```
Content-Type: application/json
Authorization: Bearer {token}
```

### Request Body

```json
{
    "message": "Apa itu kesehatan mental?",
    "session_id": "optional-uuid-v4",
    "use_history": true
}
```

**Parameters:**

-   `message` (required, string, max 5000) - Pesan dari user
-   `session_id` (optional, string) - UUID untuk conversation session. Jika tidak ada, akan generate baru
-   `use_history` (optional, boolean, default: true) - Include chat history untuk context

### Response Success (200)

```json
{
    "success": true,
    "data": {
        "session_id": "550e8400-e29b-41d4-a716-446655440000",
        "message": "Apa itu kesehatan mental?",
        "response": "Kesehatan mental adalah kondisi dimana seseorang dapat menyadari kemampuannya sendiri, dapat mengatasi tekanan hidup yang normal, dapat bekerja secara produktif, dan mampu memberikan kontribusi kepada komunitasnya...",
        "timestamp": "2025-11-06T14:30:00.000000Z"
    }
}
```

### Response Error (422) - Validation Failed

```json
{
    "success": false,
    "errors": {
        "message": ["The message field is required."]
    }
}
```

### Response Error (500) - API Error

```json
{
    "success": false,
    "error": "Failed to generate response",
    "session_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Example Request (cURL)

```bash
curl -X POST http://192.168.8.48:8000/api/chatbot/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01" \
  -d '{
    "message": "Bagaimana cara mengatasi stress?"
  }'
```

### Example Request (Dart/Flutter)

```dart
Future<Map<String, dynamic>> sendMessage(String message, {String? sessionId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse('$baseUrl/api/chatbot/send'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'message': message,
      'session_id': sessionId,
      'use_history': true,
    }),
  );

  return jsonDecode(response.body);
}
```

---

## 2. Create New Chat Session

**Endpoint**: `POST /chatbot/sessions/new`

Generate session ID baru untuk conversation baru.

### Request Headers

```
Authorization: Bearer {token}
```

### Response Success (201)

```json
{
    "success": true,
    "data": {
        "session_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "message": "New chat session created"
    }
}
```

### Example Request (cURL)

```bash
curl -X POST http://192.168.8.48:8000/api/chatbot/sessions/new \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01"
```

---

## 3. Get All Chat Sessions

**Endpoint**: `GET /chatbot/sessions`

Mendapatkan list semua chat sessions milik user (sorted by last message).

### Request Headers

```
Authorization: Bearer {token}
```

### Response Success (200)

```json
{
    "success": true,
    "data": [
        {
            "session_id": "550e8400-e29b-41d4-a716-446655440000",
            "preview": "Apa itu kesehatan mental?",
            "message_count": 12,
            "first_message": "2025-11-06T10:00:00.000000Z",
            "last_message": "2025-11-06T14:30:00.000000Z"
        },
        {
            "session_id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
            "preview": "Bagaimana cara mengatasi stress?",
            "message_count": 8,
            "first_message": "2025-11-05T15:20:00.000000Z",
            "last_message": "2025-11-05T16:45:00.000000Z"
        }
    ]
}
```

### Example Request (Dart/Flutter)

```dart
Future<List<ChatSession>> getChatSessions() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse('$baseUrl/api/chatbot/sessions'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((json) => ChatSession.fromJson(json))
        .toList();
  }

  throw Exception('Failed to load sessions');
}
```

---

## 4. Get Chat History

**Endpoint**: `GET /chatbot/history/{session_id}`

Mendapatkan semua messages dalam satu session.

### Request Headers

```
Authorization: Bearer {token}
```

### URL Parameters

-   `session_id` (required) - UUID dari session

### Response Success (200)

```json
{
    "success": true,
    "data": {
        "session_id": "550e8400-e29b-41d4-a716-446655440000",
        "history": [
            {
                "id": 1,
                "role": "user",
                "message": "Apa itu kesehatan mental?",
                "timestamp": "2025-11-06T14:00:00.000000Z"
            },
            {
                "id": 2,
                "role": "assistant",
                "message": "Kesehatan mental adalah...",
                "timestamp": "2025-11-06T14:00:02.000000Z"
            },
            {
                "id": 3,
                "role": "user",
                "message": "Bagaimana cara menjaganya?",
                "timestamp": "2025-11-06T14:05:00.000000Z"
            },
            {
                "id": 4,
                "role": "assistant",
                "message": "Beberapa cara menjaga kesehatan mental...",
                "timestamp": "2025-11-06T14:05:03.000000Z"
            }
        ],
        "count": 4
    }
}
```

### Example Request (cURL)

```bash
curl -X GET http://192.168.8.48:8000/api/chatbot/history/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01"
```

---

## 5. Delete Chat Session

**Endpoint**: `DELETE /chatbot/sessions/{session_id}`

Menghapus semua messages dalam satu session.

### Request Headers

```
Authorization: Bearer {token}
```

### URL Parameters

-   `session_id` (required) - UUID dari session

### Response Success (200)

```json
{
    "success": true,
    "message": "Chat session deleted successfully",
    "deleted_count": 12
}
```

### Response Not Found (404)

```json
{
    "success": false,
    "message": "Chat session not found"
}
```

### Example Request (cURL)

```bash
curl -X DELETE http://192.168.8.48:8000/api/chatbot/sessions/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01"
```

---

## Flutter Integration Example

### 1. Model Classes

```dart
class ChatMessage {
  final int id;
  final String role; // 'user' or 'assistant'
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatSession {
  final String sessionId;
  final String preview;
  final int messageCount;
  final DateTime firstMessage;
  final DateTime lastMessage;

  ChatSession({
    required this.sessionId,
    required this.preview,
    required this.messageCount,
    required this.firstMessage,
    required this.lastMessage,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'],
      preview: json['preview'],
      messageCount: json['message_count'],
      firstMessage: DateTime.parse(json['first_message']),
      lastMessage: DateTime.parse(json['last_message']),
    );
  }
}
```

### 2. Service Class

```dart
class ChatbotService {
  final String baseUrl = 'http://192.168.8.48:8000/api';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  // Send message and get AI response
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

  // Create new session
  Future<String> createNewSession() async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/sessions/new'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    return data['data']['session_id'];
  }

  // Get all sessions
  Future<List<ChatSession>> getSessions() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((json) => ChatSession.fromJson(json))
        .toList();
  }

  // Get chat history
  Future<List<ChatMessage>> getHistory(String sessionId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/history/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    return (data['data']['history'] as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  // Delete session
  Future<bool> deleteSession(String sessionId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/chatbot/sessions/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
```

### 3. UI Example (Chat Screen)

```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatbotService _chatbot = ChatbotService();
  final TextEditingController _messageController = TextEditingController();

  String? _sessionId;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _createNewSession();
  }

  Future<void> _createNewSession() async {
    final sessionId = await _chatbot.createNewSession();
    setState(() {
      _sessionId = sessionId;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(
        id: 0,
        role: 'user',
        message: message,
        timestamp: DateTime.now(),
      ));
    });

    try {
      final result = await _chatbot.sendMessage(
        message: message,
        sessionId: _sessionId,
      );

      if (result['success']) {
        setState(() {
          _messages.add(ChatMessage(
            id: 0,
            role: 'assistant',
            message: result['data']['response'],
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chatbot'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewSession,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  message: msg.message,
                  isUser: msg.role == 'user',
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
```

---

## Features

### ✅ Context-Aware Conversation

-   Chatbot mengingat 20 pesan terakhir (10 exchanges) untuk context
-   Setiap session terpisah, tidak tercampur dengan session lain

### ✅ Multi-Session Support

-   User bisa punya banyak conversation sessions
-   Setiap session punya session_id unik (UUID)
-   Bisa switch antar session

### ✅ Chat History Saved

-   Semua pesan tersimpan di database
-   Bisa load history kapan saja
-   Ownership by user_id (setiap user lihat chat-nya sendiri)

### ✅ Safety Settings

-   Built-in content filtering dari Gemini
-   Block harassment, hate speech, sexually explicit, dangerous content

---

## Configuration

### Gemini AI Settings (in GeminiService.php)

```php
'generationConfig' => [
    'temperature' => 0.9,     // Creativity (0.0 - 1.0)
    'topK' => 1,              // Token selection
    'topP' => 1,              // Nucleus sampling
    'maxOutputTokens' => 2048 // Max response length
]
```

### Adjust Settings:

-   **Lower temperature** (0.3-0.5) → More factual, consistent
-   **Higher temperature** (0.8-1.0) → More creative, varied
-   **maxOutputTokens** → Control response length

---

## Testing

### Test dengan cURL

```bash
# 1. Create new session
SESSION_ID=$(curl -s -X POST http://192.168.8.48:8000/api/chatbot/sessions/new \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01" \
  | jq -r '.data.session_id')

echo "Session ID: $SESSION_ID"

# 2. Send first message
curl -X POST http://192.168.8.48:8000/api/chatbot/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01" \
  -d "{
    \"message\": \"Halo, siapa kamu?\",
    \"session_id\": \"$SESSION_ID\"
  }"

# 3. Send follow-up (with context)
curl -X POST http://192.168.8.48:8000/api/chatbot/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01" \
  -d "{
    \"message\": \"Apa yang bisa kamu lakukan?\",
    \"session_id\": \"$SESSION_ID\"
  }"

# 4. Get history
curl -X GET http://192.168.8.48:8000/api/chatbot/history/$SESSION_ID \
  -H "Authorization: Bearer c0649cdb-907f-4a15-8199-2ff3789a0c01"
```

### Test dengan Postman

Import request baru:

-   **Method**: POST
-   **URL**: `{{base_url}}/chatbot/send`
-   **Headers**:
    -   `Content-Type: application/json`
    -   `Authorization: Bearer {{token}}`
-   **Body** (raw JSON):
    ```json
    {
        "message": "Halo AI!"
    }
    ```

---

## Rate Limits & Pricing

### Gemini API Free Tier

-   **60 requests per minute**
-   **1,500 requests per day**
-   **1 million tokens per day**
-   **FREE untuk penggunaan normal!**

### Paid Tier (jika perlu scale up)

-   Lebih tinggi rate limits
-   Info: https://ai.google.dev/pricing

---

## Troubleshooting

### Error: "No response generated"

-   **Cause**: Gemini API response invalid
-   **Fix**: Check API key, network connection

### Error: "Failed to generate response"

-   **Cause**: API call failed
-   **Fix**:
    -   Verify GEMINI_API_KEY di .env
    -   Check Laravel log: `storage/logs/laravel.log`
    -   Test API key di browser: https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY

### Response terlalu lambat

-   **Cause**: Network latency, complex query
-   **Fix**:
    -   Reduce maxOutputTokens
    -   Set use_history=false untuk query simple
    -   Consider caching frequent questions

### Chat tidak ada context

-   **Cause**: `use_history` set false atau session_id berbeda
-   **Fix**: Pastikan session_id konsisten dalam 1 conversation

---

## Security Notes

✅ **Bearer token required** - Semua endpoints protected  
✅ **User isolation** - User hanya bisa akses chat history sendiri  
✅ **Input validation** - Message max 5000 chars  
✅ **SQL injection safe** - Using Eloquent ORM  
✅ **API key server-side** - Frontend tidak perlu tahu Gemini API key

---

## Database Schema

```sql
CREATE TABLE chat_histories (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    role ENUM('user', 'assistant') NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session (session_id),
    INDEX idx_user_session (user_id, session_id)
);
```

---

## File Structure

```
app/
├── Http/Controllers/
│   └── ChatbotController.php    # API endpoints
├── Models/
│   └── ChatHistory.php           # Model untuk chat history
└── Services/
    └── GeminiService.php         # Service untuk call Gemini API

database/migrations/
└── 2025_11_06_064613_create_chat_histories_table.php

routes/
└── api.php                       # Route definitions
```

---

**Created**: November 6, 2025  
**Gemini Model**: gemini-pro  
**Laravel Version**: 10+  
**Status**: ✅ Production Ready
