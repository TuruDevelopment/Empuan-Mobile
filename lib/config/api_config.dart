class ApiConfig {
  // Environment configuration
  // To use different environments, build with:
  // flutter run --dart-define=ENV=production
  // flutter build apk --dart-define=ENV=production
  static const String _environment =
      String.fromEnvironment('ENV', defaultValue: 'development');

  // Base URLs for different environments
  static const String _developmentUrl = 'https://empuanapp.id/api';
  static const String _productionUrl = 'https://empuanapp.id/api';
  static const String _stagingUrl = 'https://staging.empuanapp.id/api';

  // Get base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _productionUrl;
      case 'staging':
        return _stagingUrl;
      case 'development':
      default:
        return _developmentUrl;
    }
  }

  // Get environment name
  static String get environment => _environment;

  // Check if running in production
  static bool get isProduction => _environment == 'production';

  // Public. Tells this build whether it must or can update, see
  // BACKEND_CHANGES.md ("App version gate").
  static const String appVersion = '/app/version';

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
  static const String changePassword = '/user/change-password';

  // Account endpoints that need backend support, see BACKEND_CHANGES.md.
  static const String forgotPassword = '/password/forgot';
  static const String deleteAccount = '/user/delete-account';

  // Reporting and blocking (Google Play UGC and AI content policies).
  // Needs backend support, see BACKEND_CHANGES.md.
  static const String reports = '/reports';
  static const String blocks = '/blocks';

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
  static String ruangPuanLike(int id) => '/ruang-puan/$id/like';

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

  // Onboarding: what the user wants to learn about. Needs backend support,
  // see BACKEND_CHANGES.md.
  static const String onboardingInterests = '/onboarding/interests';

  // Chatbot endpoints
  static const String chatbotSend = '/chatbot/send';
  static const String chatbotSessions = '/chatbot/sessions';
  static const String chatbotNewSession = '/chatbot/sessions/new';
  static String chatbotHistory(String sessionId) =>
      '/chatbot/history/$sessionId';
  static String chatbotDeleteSession(String sessionId) =>
      '/chatbot/sessions/$sessionId';
  // Empuan AI v2: streamed answers (Server-Sent Events) and feedback.
  static const String chatbotStream = '/chatbot/stream';
  static String chatbotRegenerate(String sessionId) =>
      '/chatbot/sessions/$sessionId/regenerate';
  static String chatbotFeedback(int messageId) =>
      '/chatbot/messages/$messageId/feedback';

  // Learning endpoints (18+)
  static const String learningHome = '/learning/home';
  static const String learningLifeStages = '/learning/life-stages';
  static const String learningCategories = '/learning/categories';
  static const String learningCourses = '/learning/courses';
  static const String learningProgress = '/learning/me/progress';
  static String learningCourse(String slug) => '/learning/courses/$slug';
  static String learningEnroll(String slug) => '/learning/courses/$slug/enroll';
  static String learningLesson(int id) => '/learning/lessons/$id';
  static String learningLessonQuiz(int id) => '/learning/lessons/$id/quiz';
  static String learningLessonProgress(int id) =>
      '/learning/lessons/$id/progress';
  static String learningQuizAttempts(int id) =>
      '/learning/quizzes/$id/attempts';
  static String learningCertificate(String slug) =>
      '/learning/courses/$slug/certificate';
  static const String learningCertificates = '/learning/me/certificates';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
