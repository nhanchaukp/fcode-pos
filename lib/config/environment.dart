class Environment {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static const String apiEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: 'https://fcode.vn/api',
  );

  static const String baseURL = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://fcode.vn',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'FCODE Pos',
  );

  static const String telegramBotBaseApi = String.fromEnvironment(
    'TELEGRAM_BOT_BASE_API',
    defaultValue: 'https://telebot.fcode.vn',
  );

  static bool get isDev => env == 'dev';
  static bool get isProduction => env == 'production';
}
