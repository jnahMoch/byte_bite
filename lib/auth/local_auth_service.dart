import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../database_helper.dart';

class LocalAuthService {
  LocalAuthService._();

  static final LocalAuthService instance = LocalAuthService._();

  static const int _iterations = 12000;
  static const int _saltLength = 16;

  String _createHashPayload(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(
      _saltLength,
      (_) => random.nextInt(256),
    );
    final salt = base64Encode(saltBytes);
    final hash = _deriveHash(
      password: password,
      salt: salt,
      iterations: _iterations,
    );
    return 'v1\$$_iterations\$$salt\$$hash';
  }

  String _deriveHash({
    required String password,
    required String salt,
    required int iterations,
  }) {
    List<int> digest = utf8.encode('$password::$salt');
    for (var i = 0; i < iterations; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Encode(digest);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var mismatch = 0;
    for (var i = 0; i < a.length; i++) {
      mismatch |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return mismatch == 0;
  }

  bool verifyPassword({required String password, required String stored}) {
    if (stored.startsWith('v1\$')) {
      final parts = stored.split('\$');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]) ?? _iterations;
      final salt = parts[2];
      final expected = parts[3];
      final actual = _deriveHash(
        password: password,
        salt: salt,
        iterations: iterations,
      );
      return _constantTimeEquals(actual, expected);
    }

    // Backward compatibility for older plain-text local records.
    return _constantTimeEquals(password, stored);
  }

  Future<void> upsertLocalCredential({
    required String username,
    required String password,
    required String role,
    String? email,
    String? name,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await DatabaseHelper.instance.getUserByUsername(username);
    final hashPayload = _createHashPayload(password);

    if (existing == null) {
      await DatabaseHelper.instance.insertUser({
        'name': (name == null || name.trim().isEmpty) ? username : name.trim(),
        'role': role,
        'username': username,
        'email': email,
        'password': hashPayload,
      });
      return;
    }

    await db.update(
      'Users',
      {
        'name': (name == null || name.trim().isEmpty)
            ? existing['name'] ?? username
            : name.trim(),
        'role': role,
        'email': email ?? existing['email'],
        'password': hashPayload,
      },
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<String?> authenticateOffline({
    required String username,
    required String password,
  }) async {
    final user = await DatabaseHelper.instance.getUserByUsername(username);
    if (user == null) return null;

    final storedPassword = (user['password'] ?? '').toString();
    if (storedPassword.isEmpty) return null;

    final valid = verifyPassword(password: password, stored: storedPassword);
    if (!valid) return null;

    final role = (user['role'] ?? '').toString();
    if (role.isEmpty) return null;
    return role;
  }
}
