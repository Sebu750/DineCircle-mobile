/// Runtime configuration for the DineCircle app.
///
/// The Android emulator maps `10.0.2.2` to the host machine's localhost,
/// so that is the default. Physical devices and desktop builds should
/// override [apiBase] or point at a reachable LAN / production host.
abstract final class DcConfig {
  /// Root URL of the DineCircle API (no trailing slash).
  static const String apiBase = 'http://10.0.2.2:4000';

  /// Key used to persist the session token between launches.
  static const String tokenKey = 'dc_auth_token';
}
