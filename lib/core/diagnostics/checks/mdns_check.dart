import 'dart:io';
import '../diagnostics_service.dart';

class MdnsCheck implements DiagnosticCheck {
  @override
  String get id => 'mdns_status';

  @override
  String get title => 'mDNS Multicast Port (UDP 5353)';

  @override
  Future<DiagnosticResult> run({Map<String, dynamic>? params}) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        5353,
        reuseAddress: true,
        reusePort: true,
      );

      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.passed,
        message: 'UDP 5353 is open and available for mDNS discovery.',
      );
    } catch (e) {
      return DiagnosticResult(
        id: id,
        title: title,
        status: DiagnosticStatus.warning,
        message: 'Port 5353 cannot be bound directly ($e). Hopper will use adb mdns fallback.',
        fixPrompt: 'Ensure third-party firewall or conflicting services do not block UDP 5353.',
      );
    } finally {
      socket?.close();
    }
  }
}
