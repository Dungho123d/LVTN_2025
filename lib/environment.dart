class Environment {
  const Environment._();

  static const String pocketBaseUrl =
      String.fromEnvironment('POCKETBASE_URL', defaultValue: 'http://127.0.0.1:8090');

  static const String pocketBaseAdminEmail =
      String.fromEnvironment('POCKETBASE_ADMIN_EMAIL', defaultValue: '');

  static const String pocketBaseAdminPassword =
      String.fromEnvironment('POCKETBASE_ADMIN_PASSWORD', defaultValue: '');

  static const String pocketBaseUserEmail =
      String.fromEnvironment('POCKETBASE_USER_EMAIL', defaultValue: '');

  static const String pocketBaseUserPassword =
      String.fromEnvironment('POCKETBASE_USER_PASSWORD', defaultValue: '');

  static bool get hasAdminCredentials =>
      pocketBaseAdminEmail.isNotEmpty && pocketBaseAdminPassword.isNotEmpty;

  static bool get hasUserCredentials =>
      pocketBaseUserEmail.isNotEmpty && pocketBaseUserPassword.isNotEmpty;
}
