/// Runtime configuration for the client.
///
/// The API base URL can be overridden at build/run time:
///   flutter run  --dart-define=API_BASE_URL=http://192.168.1.50:5000
///   flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:5000
///
/// The default targets the local backend as seen *from an Android emulator*,
/// where the host machine's `localhost` is reachable at the special alias
/// `10.0.2.2`. For a physical device on the same LAN, override with the
/// host's LAN IP.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
}
