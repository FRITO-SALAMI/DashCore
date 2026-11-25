/// Public client configuration. Override with --dart-define for other projects.
/// Never put a service-role/secret key in the APK.
abstract final class BackendConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://znrxgcfdvsmqkvejyrbo.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_9DzQWpzXWrMFUcmVKgn1tA_smmkTWOj',
  );
  static const googleSignInEnabled = bool.fromEnvironment(
    'GOOGLE_SIGN_IN_ENABLED',
    defaultValue: false,
  );
  static const storageUrl = '$url/storage/v1/object/public';
}
