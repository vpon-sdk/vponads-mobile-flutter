/// Logger for Vpon Plugin
class VponLogger {
  static const bool enabled = true;

  /// Info message log
  static void i(String msg) {
    if (enabled) {
      print('<VPON> [INFO] $msg');
    }
  }

  /// Error message log
  static void e(String msg) {
    if (enabled) {
      print('<VPON> [ERROR] $msg');
    }
  }

  /// Debug message log
  static void d(String msg) {
    if (enabled) {
      print('<VPON> [DEBUG] $msg');
    }
  }
}
