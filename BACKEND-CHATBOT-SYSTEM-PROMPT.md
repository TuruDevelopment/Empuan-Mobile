# Backend Update Required: Women's Health System Prompt

## Current Issue

The chatbot backend needs to be configured with a **system prompt** to specialize in women's health topics only.

## Required Backend Changes

### File: `app/Services/GeminiService.php`

Update the `generateResponse()` method to include a system instruction:

```php
public function generateResponse($userMessage, $conversationHistory = [])
{
    // Build conversation history with SYSTEM PROMPT
    $contents = [];

    // ADD THIS: System instruction for women's health specialization
    $systemPrompt = "You are Empuan AI, a specialized health assistant for women. Your expertise includes:

- Women's reproductive health and menstrual cycles
- Pregnancy, prenatal, and postnatal care
- Mental health and emotional wellness for women
- Nutrition and diet for women's health
- Breast health and screening
- Menopause and hormonal changes
- Women's fitness and exercise
- Sexual health and contraception
- Period tracking and cycle management
- Common women's health conditions (PCOS, endometriosis, etc.)

IMPORTANT RULES:
1. ONLY answer questions related to women's health topics listed above
2. If asked about topics outside women's health (sports, politics, general knowledge, etc.), politely redirect:
   'I'm specialized in women's health. I can help you with menstrual health, pregnancy, nutrition, mental wellness, and other women's health topics. How can I assist you with your health today?'
3. Always provide empathetic, supportive, and evidence-based responses
4. Use simple, easy-to-understand language
5. Encourage users to consult healthcare professionals for medical diagnosis
6. Never provide specific medical diagnoses or prescriptions

Respond naturally and warmly, as a supportive health companion.";

    // Add system message first
    $contents[] = [
        'role' => 'user',
        'parts' => [['text' => $systemPrompt]]
    ];

    $contents[] = [
        'role' => 'model',
        'parts' => [['text' => 'Understood. I am Empuan AI, specialized in women\'s health. I will only respond to women\'s health questions and redirect other topics appropriately.']]
    ];

    // Then add conversation history
    foreach ($conversationHistory as $chat) {
        $contents[] = [
            'role' => $chat->role === 'user' ? 'user' : 'model',
            'parts' => [['text' => $chat->message]]
        ];
    }

    // Add current user message
    $contents[] = [
        'role' => 'user',
        'parts' => [['text' => $userMessage]]
    ];

    // Rest of the code remains same...
    $response = Http::post($url, [
        'contents' => $contents,
        'generationConfig' => [
            'temperature' => 0.7,  // Slightly lower for more focused responses
            'topK' => 40,
            'topP' => 0.95,
            'maxOutputTokens' => 2048
        ]
    ]);

    // ... rest of method
}
```

## Alternative: Environment Variable Approach

If you want to make the system prompt configurable:

### 1. Add to `.env`:

```env
CHATBOT_SYSTEM_PROMPT="You are Empuan AI, a specialized health assistant for women..."
```

### 2. Update `config/services.php`:

```php
'gemini' => [
    'api_key' => env('GEMINI_API_KEY'),
    'system_prompt' => env('CHATBOT_SYSTEM_PROMPT', 'You are a helpful AI assistant.'),
],
```

### 3. Use in GeminiService.php:

```php
$systemPrompt = config('services.gemini.system_prompt');
```

## Testing the System Prompt

After implementing, test with these questions:

### ✅ Should Answer (Women's Health):

- "What are normal period symptoms?"
- "How can I reduce menstrual cramps?"
- "Tell me about PCOS"
- "What foods are good during pregnancy?"
- "How to deal with menopause symptoms?"

### ❌ Should Redirect (Non-Women's Health):

- "Who won the World Cup?" → Should redirect to women's health topics
- "How do I fix my car?" → Should redirect
- "What's the weather like?" → Should redirect
- "Tell me a joke" → Should redirect (or optionally allow general chat)

### Example Expected Response for Non-Health Topics:

**User**: "Who is the president?"

**AI**: "I'm specialized in women's health topics. I can help you with menstrual health, pregnancy, nutrition, mental wellness, and other women's health concerns. Is there anything related to your health that I can assist you with today? 💗"

## Why This Matters

1. **Focus**: Keeps chatbot responses relevant to app purpose
2. **Safety**: Prevents misinformation on medical topics
3. **Quality**: More accurate and helpful responses in specialized domain
4. **User Trust**: Builds credibility as a women's health resource
5. **Legal**: Reduces liability by staying within scope

## Mobile App Changes (Already Implemented)

The mobile app has been updated with:

- Welcome message highlighting women's health focus
- Empty state mentioning women's health topics
- UI text emphasizing health specialization

But the **backend system prompt is required** to actually enforce topic restrictions.

## Priority: HIGH

Without this backend update, the AI will answer any question (sports, politics, etc.), which:

- Dilutes the app's purpose
- May provide incorrect medical advice
- Creates poor user experience
- Doesn't match the app branding

## Implementation Checklist

- [ ] Update `GeminiService.php` with system prompt
- [ ] Test with women's health questions (should answer)
- [ ] Test with off-topic questions (should redirect)
- [ ] Verify empathetic and supportive tone
- [ ] Check response quality and accuracy
- [ ] Deploy to production
- [ ] Update API documentation

---

**Status**: Pending Backend Implementation  
**Priority**: HIGH  
**Estimated Time**: 30 minutes
