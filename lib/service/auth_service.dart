import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'local_demo_users_v1';
  static const String _sessionMobileKey = 'session_mobile';
  static const String _sessionNameKey = 'session_name';

  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  Future<Map<String, dynamic>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_usersKey);
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data) as Map);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<String> _createHash(String password, List<int> salt) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  Future<String?> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    mobile = mobile.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (password.length < 8) {
      return 'Password must contain at least 8 characters';
    }

    final users = await _readUsers();
    if (users.containsKey(mobile)) {
      return 'This mobile number is already registered';
    }

    final salt = _generateSalt();
    final hash = await _createHash(password, base64Decode(salt));

    users[mobile] = {
      'name': name.trim(),
      'salt': salt,
      'passwordHash': hash,
    };

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_usersKey, jsonEncode(users));
    return saved ? null : 'Unable to save account';
  }

  /// Returns the user's name on success, null on failure.
  /// On success the session (mobile + name) is stored.
  Future<String?> login({
    required String mobile,
    required String password,
  }) async {
    mobile = mobile.trim();
    final users = await _readUsers();
    final user = users[mobile];

    if (user is! Map) return null;

    final salt = user['salt'];
    final storedHash = user['passwordHash'];
    if (salt is! String || storedHash is! String) return null;

    final enteredHash = await _createHash(password, base64Decode(salt));
    if (enteredHash != storedHash) return null;

    final name = (user['name'] as String?) ?? 'User';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionMobileKey, mobile);
    await prefs.setString(_sessionNameKey, name);
    return name;
  }

  /// Logged-in user as {'mobile': ..., 'name': ...}, or null.
  Future<Map<String, String>?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString(_sessionMobileKey);
    if (mobile == null) return null;
    return {
      'mobile': mobile,
      'name': prefs.getString(_sessionNameKey) ?? 'User',
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionMobileKey);
    await prefs.remove(_sessionNameKey);
  }
}
