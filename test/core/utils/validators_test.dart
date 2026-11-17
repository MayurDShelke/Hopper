import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('isValidIp validates IPv4 correctly', () {
      expect(Validators.isValidIp('192.168.1.1'), isTrue);
      expect(Validators.isValidIp('10.0.0.254'), isTrue);
      expect(Validators.isValidIp('127.0.0.1'), isTrue);

      expect(Validators.isValidIp('256.1.1.1'), isFalse);
      expect(Validators.isValidIp('192.168.1'), isFalse);
      expect(Validators.isValidIp('abc.def.ghi.jkl'), isFalse);
      expect(Validators.isValidIp(''), isFalse);
    });

    test('isValidPort validates port range 1..65535', () {
      expect(Validators.isValidPort(5555), isTrue);
      expect(Validators.isValidPort(1), isTrue);
      expect(Validators.isValidPort(65535), isTrue);

      expect(Validators.isValidPort(0), isFalse);
      expect(Validators.isValidPort(-1), isFalse);
      expect(Validators.isValidPort(65536), isFalse);
    });

    test('isValidPairingCode validates exactly 6 digits', () {
      expect(Validators.isValidPairingCode('123456'), isTrue);
      expect(Validators.isValidPairingCode('000000'), isTrue);

      expect(Validators.isValidPairingCode('12345'), isFalse);
      expect(Validators.isValidPairingCode('1234567'), isFalse);
      expect(Validators.isValidPairingCode('12345a'), isFalse);
    });

    test('isValidPackageName validates Java/Android package syntax', () {
      expect(Validators.isValidPackageName('com.example.app'), isTrue);
      expect(Validators.isValidPackageName('org.hopper.companion'), isTrue);

      expect(Validators.isValidPackageName('invalid'), isFalse);
      expect(Validators.isValidPackageName('com..app'), isFalse);
    });
  });
}
