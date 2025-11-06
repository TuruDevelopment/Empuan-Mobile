import 'dart:convert';

/// Decode JWT token to see payload (for debugging only)
/// Returns the payload as a Map
Map<String, dynamic>? decodeJWT(String token) {
  try {
    // JWT format: header.payload.signature
    final parts = token.split('.');

    if (parts.length != 3) {
      print('Invalid JWT format');
      return null;
    }

    // Decode payload (second part)
    final payload = parts[1];

    // Add padding if needed for base64 decoding
    var normalized = base64Url.normalize(payload);
    var decoded = utf8.decode(base64Url.decode(normalized));

    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (e) {
    print('Error decoding JWT: $e');
    return null;
  }
}

/// Print decoded JWT token for debugging
void debugToken(String? token) {
  if (token == null || token.isEmpty) {
    print('[JWT] No token to decode');
    return;
  }

  print('╔════════════════════════════════════════════════════════╗');
  print('║              🔍 JWT TOKEN DECODER                      ║');
  print('╠════════════════════════════════════════════════════════╣');

  final payload = decodeJWT(token);

  if (payload != null) {
    print('║  Token Payload:');
    payload.forEach((key, value) {
      print('║    $key: $value');
    });

    // Check user_id
    final userId = payload['sub'] ?? payload['user_id'] ?? payload['id'];
    if (userId != null) {
      print('╠════════════════════════════════════════════════════════╣');
      if (userId == 1 || userId == 2) {
        print('║  ⚠️  TOKEN HAS OLD USER_ID: $userId');
        print('║  ⚠️  This token is from old user!');
      } else {
        print('║  ✅ TOKEN HAS CORRECT USER_ID: $userId');
      }
    }
  } else {
    print('║  ❌ Failed to decode token');
  }

  print('╚════════════════════════════════════════════════════════╝');
}
