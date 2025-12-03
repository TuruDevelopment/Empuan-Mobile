class ApiConfig {
  // Base URL - matches api.json specification
  // PRODUCTION: Use the correct backend URL
  // static const String baseUrl = 'https://empuanback.test/api';

  // DEVELOPMENT: Use local IP if testing locally
  static const String baseUrl = 'http://192.168.8.52:8000/api';

  // Auth endpoints
  static const String register = '/register';
  static const String login = '/login';
  static const String me = '/me';
  static const String logout = '/logout';

  // User endpoints
  static const String users = '/users';
  static String userById(int id) => '/admin/users/$id';
  static String userByUsername(String username) =>
      '/admin/users/username/$username';
  static const String userProfile = '/user/profile';
  static const String usersCurrent = '/users/current';

  // Catatan Haid endpoints
  static const String catatanHaid = '/catatan-haid';
  static String catatanHaidById(int id) => '/admin/catatan-haid/$id';

  // Kontak Palsu endpoints
  static const String kontakPalsu = '/kontak-palsu';
  static String kontakPalsuById(int id) => '/kontak-palsu/$id';

  // Kontak Aman endpoints
  static const String kontakAman = '/kontak-aman';
  static String kontakAmanById(int id) => '/kontak-aman/$id';

  // Her Voice endpoints
  static const String suaraPuan = '/suara-puan';
  static String suaraPuanById(int id) => '/suara-puan/$id';
  static String suaraPuanComments(int id) => '/suara-puan/$id/comments';

  // Her Space endpoints
  static const String ruangPuan = '/ruang-puan';
  static String ruangPuanById(int id) => '/ruang-puan/$id';
  static String ruangPuanComments(int id) => '/ruang-puan/$id/comments';

  // For Her endpoints
  static const String untukPuan = '/untuk-puan';
  static String untukPuanById(int id) => '/untuk-puan/$id';

  // Kategori endpoints
  static const String kategoriSuaraPuan = '/kategori-suara-puan';
  static String kategoriSuaraPuanById(int id) => '/kategori-suara-puan/$id';
  static const String kategoriUntukPuan = '/kategori-untuk-puan';
  static String kategoriUntukPuanById(int id) => '/kategori-untuk-puan/$id';

  // Questions endpoints
  static const String questionsEndpoint = '/questions';
  static String questionById(int id) => '/questions/$id';
  static String questionOptions(int questionId) =>
      '/questions/$questionId/options';

  // Chatbot endpoints
  static const String chatbotSend = '/chatbot/send';
  static const String chatbotSessions = '/chatbot/sessions';
  static const String chatbotNewSession = '/chatbot/sessions/new';
  static String chatbotHistory(String sessionId) =>
      '/chatbot/history/$sessionId';
  static String chatbotDeleteSession(String sessionId) =>
      '/chatbot/sessions/$sessionId';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
