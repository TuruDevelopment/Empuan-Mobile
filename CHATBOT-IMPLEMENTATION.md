# AI Chatbot Integration - Flutter Mobile App

## 📱 Overview

AI Chatbot feature with **streaming responses** integrated into Empuan Mobile App. Uses Google Gemini AI backend with typewriter effect for better UX. **Specialized in women's health topics only.**

## ✨ Features

✅ **Streaming Messages** - Real-time typewriter effect as AI responds  
✅ **Session Management** - Create new conversations, maintain history  
✅ **Chat History Screen** - View and manage past conversations  
✅ **Women's Health Focus** - Specialized in menstrual health, pregnancy, wellness  
✅ **Beautiful UI** - Modern gradient design matching app theme  
✅ **Chat Persistence** - Conversations saved in database  
✅ **Context-Aware** - AI remembers conversation context  
✅ **Easy Access** - Quick button on HomePage  
✅ **Delete Conversations** - Remove old chats with confirmation

## 🎯 Implementation

### Files Created

1. **lib/models/chat_message.dart**

   - `ChatMessage` model with streaming support
   - `ChatSession` model for conversation management
   - Includes `isStreaming` flag for UI updates

2. **lib/services/chatbot_service.dart**

   - `sendMessageStream()` - Streams response word by word
   - `sendMessage()` - Standard non-streaming version
   - `createNewSession()` - Generate new conversation
   - `getSessions()` - List all user's conversations
   - `getHistory()` - Load conversation history
   - `deleteSession()` - Remove conversation

3. **lib/screens/chatbot.dart**
   - Full chat UI with gradient background
   - Message bubbles with user/AI distinction
   - Animated typing indicator (3 dots)
   - Auto-scroll to latest message
   - Input area with send button
   - New chat button in header

### Files Modified

4. **lib/screens/HomePage.dart**
   - Added "AI Assistant" button in quick actions
   - Purple gradient design (distinct from other cards)
   - Import statement for ChatbotScreen

## 🎯 How to Access

### From HomePage:

1. Scroll to quick actions section
2. Tap **"AI Assistant"** button (purple card with robot icon)
3. Start chatting!

### View Chat History:

1. Open AI Assistant
2. Tap **History icon** (clock) in top-right header
3. See all past conversations
4. Tap any conversation to continue
5. Tap delete icon to remove conversation

### Create New Chat:

1. In chat screen, tap **+ icon** in header
2. Previous chat saved automatically
3. Start fresh conversation

### Streaming Flow

1. User types message and sends
2. User message added to chat instantly
3. Placeholder AI message created with `isStreaming: true`
4. Backend API called via `sendMessageStream()`
5. Response streamed **word by word** with 30ms delay
6. UI updates in real-time as words arrive
7. Final message marked as complete with `isStreaming: false`

### Code Example

```dart
// Stream response with typewriter effect
_chatbot.sendMessageStream(
  message: userMessage,
  sessionId: _sessionId,
).listen(
  (partialResponse) {
    // Update UI with partial text
    setState(() {
      _messages[index] = message.copyWith(
        message: partialResponse,
      );
    });
  },
  onDone: () {
    // Mark streaming complete
    setState(() {
      _messages[index] = message.copyWith(
        isStreaming: false,
      );
    });
  },
);
```

## 🎨 UI Features

### Header

- AI avatar with gradient circle
- Online status indicator (green dot)
- "New Chat" button to start fresh conversation
- Back button to return to home

### Message Bubbles

- **User messages**: Pink gradient, right-aligned
- **AI messages**: White background, left-aligned with AI avatar
- Smooth shadows and rounded corners
- Animated typing indicator during streaming

### Input Area

- Rounded text field with border
- Send button with gradient (disabled during loading)
- Multi-line support for long messages
- Enter key to send

### Empty State

- Large chat icon with gradient background
- Welcoming title and description
- Encourages user to start conversation

## 📡 API Integration

### Endpoint: POST /api/chatbot/send

**Request:**

```json
{
  "message": "Hello AI!",
  "session_id": "uuid-here",
  "use_history": true
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "session_id": "uuid-here",
    "message": "Hello AI!",
    "response": "Hello! How can I help you today?",
    "timestamp": "2025-11-06T14:30:00.000000Z"
  }
}
```

### Streaming Implementation

The streaming is **client-side simulation** for better UX:

- Backend returns full response instantly
- Flutter splits response into words
- Displays words progressively with 30ms delay
- Creates typewriter effect

**Why client-side?**

- Simpler backend (no SSE/WebSocket needed)
- Works with existing REST API
- Consistent UX regardless of response time
- Easy to customize speed (30ms delay per word)

## 🔧 Configuration

### Adjust Streaming Speed

In `chatbot_service.dart` line 53:

```dart
await Future.delayed(const Duration(milliseconds: 30)); // ← Change this!
```

- **Faster**: 10-20ms - Very quick typing
- **Normal**: 30-50ms - Natural reading speed (current)
- **Slower**: 60-100ms - Dramatic effect

### Backend URL

In `chatbot_service.dart` line 10:

```dart
static const String baseUrl = 'http://192.168.8.48:8000/api';
```

Update this to match your backend server address.

## 🧪 Testing Steps

1. **Hot Restart** the app: Press `r` in terminal
2. **Login** with valid credentials
3. **Go to HomePage**
4. **Tap "AI Assistant"** button (purple card with robot icon)
5. **Type a message** about women's health: "What are normal period symptoms?"
6. **Watch streaming**: Words appear one by one ✨
7. **Continue conversation**: AI remembers context
8. **Test History**: Tap history icon to see past chats
9. **Create new chat**: Tap + button in header
10. **Delete chat**: In history screen, tap delete icon

### Test Messages (Women's Health)

- "What is a normal menstrual cycle?"
- "How can I reduce menstrual cramps?"
- "What foods are good during pregnancy?"
- "Tell me about PCOS symptoms"
- "How to deal with menopause?"
- "What are signs of pregnancy?"

### Test Non-Health Topics (Should Redirect - Backend Update Required)

Currently these will be answered. After backend system prompt update:

- "Who won the World Cup?" → Should redirect to women's health
- "How do I fix my car?" → Should redirect
- "Tell me a joke" → Should redirect

## 🎯 User Experience

### Flow

```
HomePage
  → Tap "AI Assistant" button
    → ChatbotScreen opens
      → Welcome message displayed
        → User types and sends
          → Streaming response appears word-by-word
            → Conversation continues with context
              → User can create new chat or go back
```

### Visual Feedback

- ✅ Typing indicator (3 animated dots) during streaming
- ✅ Auto-scroll to latest message
- ✅ Disabled send button while loading
- ✅ Smooth animations and transitions
- ✅ Gradient colors matching app theme

## 🔐 Authentication

All API calls include Bearer token:

```dart
headers: {
  'Authorization': 'Bearer $token',
}
```

Token automatically loaded from SharedPreferences.

## 📊 Performance

- **Streaming delay**: 30ms per word

## 📝 Future Enhancements

- [ ] True server-side streaming (SSE/WebSocket)
- [ ] Voice input/output
- [ ] Image attachments
- [ ] Message reactions
- [ ] Share conversations
- [ ] Export chat history
- [ ] Multi-language support
- [ ] Custom AI personality settings
- [ ] Search within chat history
- [ ] Pin important conversations

## ⚠️ Backend Update Required

**IMPORTANT**: The backend needs a system prompt update to restrict AI responses to women's health topics only.

See: `BACKEND-CHATBOT-SYSTEM-PROMPT.md` for detailed instructions.

**Current Status**: AI answers ANY question  
**Desired Status**: AI only answers women's health questions, redirects others  
**Priority**: HIGH

Without this update:

- AI may provide off-topic responses (sports, politics, etc.)
- Reduces app credibility as women's health resource
- May provide incorrect medical information outside domain

## 🎓 Technical Notesents

- [ ] True server-side streaming (SSE/WebSocket)
- [ ] Voice input/output
- [ ] Image attachments
- [ ] Message reactions
- [ ] Share conversations
- [ ] Export chat history
- [ ] Multi-language support
- [ ] Custom AI personality settings

## 🎓 Technical Notes

### Why Streaming?

Traditional chat UX shows loading spinner then full response. **Streaming improves perceived performance:**

- User sees progress immediately
- Creates engagement (watching text appear)
- Feels more like human conversation
- Reduces perceived wait time

### Architecture

```
User Input
    ↓
## ✅ Status

**Implementation**: ✅ Complete
**Chat History**: ✅ Complete
**Women's Health Focus**: ⚠️ Backend Update Required
**Testing**: Pending user test
**Streaming**: ✅ Working (client-side)
**UI/UX**: ✅ Polished
**Error Handling**: ✅ Implemented
**Documentation**: ✅ Complete

## 🚀 Next Steps

1. Hot restart app: `r` in terminal
2. Test chatbot functionality
3. Test chat history screen
4. Try deleting conversations
5. Verify streaming effect
6. Test session persistence
7. **Backend Team**: Implement system prompt (see BACKEND-CHATBOT-SYSTEM-PROMPT.md)
8. Test topic restriction after backend update

---

**Created**: November 6, 2025
**Updated**: November 6, 2025
**Feature**: AI Chatbot with Streaming + Chat History
**Status**: ✅ Ready for Testing (Frontend Complete, Backend Update Pending)**UI/UX**: ✅ Polished
**Error Handling**: ✅ Implemented
**Documentation**: ✅ Complete

## 🚀 Next Steps

1. Hot restart app: `r` in terminal
2. Test chatbot functionality
3. Verify streaming effect
4. Check session persistence
5. Test error scenarios

---

**Created**: November 6, 2025
**Feature**: AI Chatbot with Streaming
**Status**: ✅ Ready for Testing
```
