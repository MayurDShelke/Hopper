import 'app_error.dart';

class ErrorMapper {
  ErrorMapper._();

  static AppError map(dynamic error) {
    final str = error.toString();

    if (str.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE')) {
      return const AppError(
        title: 'Installation Incompatible',
        cause: 'The application signature does not match the version currently installed.',
        fix: 'Uninstall the existing version from your phone first and try again.',
      );
    }

    if (str.contains('INSTALL_FAILED_VERSION_DOWNGRADE')) {
      return const AppError(
        title: 'Version Downgrade Blocked',
        cause: 'The APK you are trying to install is older than the installed version.',
        fix: 'Enable Allow Downgrade in install options or uninstall the newer app first.',
      );
    }

    if (str.contains('INSTALL_FAILED_INSUFFICIENT_STORAGE')) {
      return const AppError(
        title: 'Insufficient Phone Storage',
        cause: 'Your phone does not have enough free internal storage.',
        fix: 'Free up space on your phone storage and retry.',
      );
    }

    if (str.contains('INSTALL_FAILED_USER_RESTRICTED')) {
      return const AppError(
        title: 'Installation Restricted by Phone',
        cause: 'The phone operating system blocked USB/wireless installation.',
        fix: 'On Xiaomi/Redmi phones, open Developer options and enable "Install via USB".',
      );
    }

    if (str.contains('Connection refused') || str.contains('10061')) {
      return const AppError(
        title: 'Connection Refused',
        cause: 'Wireless debugging may have turned off or the port changed.',
        fix: 'Ensure Wireless debugging is still enabled on your phone and refresh discovery.',
      );
    }

    if (str.contains('timed out') || str.contains('timeout')) {
      return const AppError(
        title: 'Connection Timed Out',
        cause: 'The phone did not reply in time. Router AP/Client Isolation may be active.',
        fix: 'Check that phone and laptop are on the same private Wi-Fi and not a guest network.',
      );
    }

    return AppError(
      title: 'Action Failed',
      cause: 'An unexpected error occurred during execution.',
      fix: 'Review settings or check Diagnostics.',
      technicalDetails: str,
    );
  }
}
