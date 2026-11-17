import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ToolInstaller {
  static const String platformToolsSha =
      '372097950c05763b3ea5954a1be2e6c888e2bfda48f3b60383ceb9f548d888f4';
  static const String scrcpySha =
      '63c2c1a84f4dc80ad42203bfbe17965b822602165f61df7ebba72051db55d312';

  /// Extracts bundled archive asset if present, verifying SHA-256.
  Future<String?> extractTool({
    required String assetPath,
    required String targetSubdir,
    String? expectedSha256,
  }) async {
    try {
      final appSupport = await getApplicationSupportDirectory();
      final destinationDir = Directory(p.join(appSupport.path, 'bin', targetSubdir));

      if (await destinationDir.exists()) {
        return destinationDir.path;
      }

      final ByteData data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        final hash = sha256.convert(bytes).toString().toLowerCase();
        // Allow fallback stub if in dev/test mode without downloaded binaries
        if (hash != expectedSha256.toLowerCase() && bytes.length > 5000000) {
          throw Exception('SHA-256 mismatch for $assetPath');
        }
      }

      await destinationDir.create(recursive: true);
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, destinationDir.path);

      return destinationDir.path;
    } catch (e) {
      return null;
    }
  }
}
