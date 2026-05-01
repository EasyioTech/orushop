import 'package:crypto/crypto.dart';

class HashService {
  static String generateHash(Map<String, dynamic> data, [String? previousHash]) {
    final jsonStr = _mapToString(data);
    final combined = previousHash != null ? '$previousHash|$jsonStr' : jsonStr;
    return sha256.convert(combined.codeUnits).toString();
  }

  static bool verifyHashChain(
    String currentHash,
    Map<String, dynamic> data,
    String? previousHash,
  ) {
    final expectedHash = generateHash(data, previousHash);
    return currentHash == expectedHash;
  }

  static String _mapToString(Map<String, dynamic> map) {
    final keys = map.keys.toList()..sort();
    final pairs = keys.map((key) => '$key=${map[key]}').join(',');
    return '{$pairs}';
  }
}
