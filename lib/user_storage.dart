import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/local_auth_service.dart';
import 'database_helper.dart';

class UserStorage {
  static final Map<String, Map<String, String>> _users = {};
  static bool _ownerRegistered = false;
  static String? _currentUser;
  static String? _currentUserRole;

  static bool get isOwnerRegistered => _ownerRegistered;
  static bool get isFirstTimeSetup => !_ownerRegistered;

  static bool registerOwner(String username, String password) {
    if (_ownerRegistered) return false;
    _users[username] = {'password': password, 'role': 'Owner'};
    _ownerRegistered = true;
    return true;
  }

  static void addHelper(String username, String password) {
    _users[username] = {'password': password, 'role': 'Helper'};
  }

  static Future<void> addHelperPersistent(
    String username,
    String password,
  ) async {
    addHelper(username, password);
    await LocalAuthService.instance.upsertLocalCredential(
      username: username,
      password: password,
      role: 'Helper',
      email: toFirebaseEmail(username),
      name: username,
    );
  }

  static bool addUser(String username, String password, String role) {
    if (role == 'Owner') {
      return registerOwner(username, password);
    } else {
      addHelper(username, password);
      return true;
    }
  }

  static bool validateUser(String username, String password) {
    if (_users.containsKey(username)) {
      return _users[username]!['password'] == password;
    }
    return false;
  }

  static String? getUserRole(String username) => _users[username]?['role'];
  static bool userExists(String username) => _users.containsKey(username);

  static Future<bool> userExistsPersistent(String username) async {
    if (_users.containsKey(username)) return true;

    final existing = await DatabaseHelper.instance.getUserByUsername(username);
    if (existing == null) return false;

    final role = (existing['role'] ?? 'Helper').toString();
    _users[username] = {'password': '', 'role': role};
    if (role == 'Owner') _ownerRegistered = true;
    return true;
  }

  static Future<Map<String, String>> getCurrentUserProfilePersistent() async {
    final username = _currentUser?.trim() ?? '';
    if (username.isEmpty) {
      return {'name': 'User', 'email': '', 'phone': ''};
    }

    final existing = await DatabaseHelper.instance.getUserByUsername(username);
    return {
      'name': (existing?['name'] ?? username).toString(),
      'email': (existing?['email'] ?? toFirebaseEmail(username)).toString(),
      'phone': (existing?['phone'] ?? '').toString(),
    };
  }

  static void setCurrentUser(String username) {
    _currentUser = username;
    _currentUserRole = _users[username]?['role'];
  }

  static String? get currentUser => _currentUser;
  static String? get currentUserRole => _currentUserRole;
  static bool get isOwner => _currentUserRole == 'Owner';
  static bool get isHelper => _currentUserRole == 'Helper';

  static Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Firebase logout error handling
    }
    _currentUser = null;
    _currentUserRole = null;
  }

  static List<Map<String, String>> getHelpers() {
    return _users.entries
        .where((entry) => entry.value['role'] == 'Helper')
        .map(
          (entry) => {
            'username': entry.key,
            'password': entry.value['password']!,
          },
        )
        .toList();
  }

  static Future<void> hydrateHelpersFromSQLite() async {
    final db = await DatabaseHelper.instance.database;
    final helperRows = await db.query(
      'Users',
      columns: ['username', 'role'],
      where: 'role = ?',
      whereArgs: ['Helper'],
      orderBy: 'username COLLATE NOCASE ASC',
    );

    _users.removeWhere((_, user) => user['role'] == 'Helper');

    for (final row in helperRows) {
      final username = (row['username'] ?? '').toString();
      if (username.isEmpty) continue;
      _users[username] = {'password': '', 'role': 'Helper'};
    }
  }

  static bool resetHelperPassword(String username, String newPassword) {
    if (_users.containsKey(username) && _users[username]!['role'] == 'Helper') {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
  }

  static Future<bool> resetHelperPasswordPersistent(
    String username,
    String newPassword,
  ) async {
    final changedInMemory = resetHelperPassword(username, newPassword);
    if (!changedInMemory) {
      final existing = await DatabaseHelper.instance.getUserByUsername(
        username,
      );
      if (existing == null || (existing['role'] ?? '').toString() != 'Helper') {
        return false;
      }
    }

    await LocalAuthService.instance.upsertLocalCredential(
      username: username,
      password: newPassword,
      role: 'Helper',
      email: toFirebaseEmail(username),
      name: username,
    );

    return true;
  }

  static bool deleteHelper(String username) {
    if (_users.containsKey(username) && _users[username]!['role'] == 'Helper') {
      _users.remove(username);
      return true;
    }
    return false;
  }

  static Future<bool> deleteHelperPersistent(String username) async {
    final existing = await DatabaseHelper.instance.getUserByUsername(username);
    if (existing == null || (existing['role'] ?? '').toString() != 'Helper') {
      return false;
    }

    _users.remove(username);

    final db = await DatabaseHelper.instance.database;
    await db.delete('Users', where: 'username = ?', whereArgs: [username]);
    return true;
  }

  static bool changePassword(
    String username,
    String oldPassword,
    String newPassword,
  ) {
    if (_users.containsKey(username) &&
        _users[username]!['password'] == oldPassword) {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
  }

  static Future<String?> changeCurrentUserPasswordPersistent({
    required String oldPassword,
    required String newPassword,
  }) async {
    final username = _currentUser?.trim() ?? '';
    if (username.isEmpty) return 'No active user session';
    if (oldPassword == newPassword) {
      return 'New password cannot be the same as current password';
    }

    try {
      final verifiedRole = await LocalAuthService.instance.authenticateOffline(
        username: username,
        password: oldPassword,
      );
      if (verifiedRole == null) {
        return 'Current password is incorrect';
      }

      final existing = await DatabaseHelper.instance.getUserByUsername(
        username,
      );
      final role =
          ((existing?['role'] ?? _currentUserRole ?? verifiedRole).toString())
              .trim();

      await LocalAuthService.instance.upsertLocalCredential(
        username: username,
        password: newPassword,
        role: role.isEmpty ? verifiedRole : role,
        email: existing?['email']?.toString(),
        name: existing?['name']?.toString() ?? username,
      );

      _users[username] = {
        'password': newPassword,
        'role': role.isEmpty ? verifiedRole : role,
      };
      return null;
    } catch (_) {
      return 'Failed to update password. Please try again';
    }
  }

  static Future<String?> updateCurrentUserProfilePersistent({
    required String name,
    required String email,
    required String phone,
  }) async {
    final username = _currentUser?.trim() ?? '';
    if (username.isEmpty) return 'No active user session';

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) return 'Name cannot be empty';

    try {
      final updatedCount = await DatabaseHelper.instance
          .updateUserProfileByUsername(
            username: username,
            name: cleanName,
            email: cleanEmail,
            phone: cleanPhone,
          );

      if (updatedCount == 0) {
        return 'Unable to update profile';
      }

      return null;
    } catch (_) {
      return 'Unable to update profile. Please check the email address and try again';
    }
  }

  static String? getOwnerUsername() {
    for (var entry in _users.entries) {
      if (entry.value['role'] == 'Owner') return entry.key;
    }
    return null;
  }

  static String toFirebaseEmail(String username) {
    return '${username.toLowerCase().trim().replaceAll(' ', '_')}@bytebite.app';
  }

  static String fromFirebaseEmail(String email) {
    // Convert '@bytebite.app' email back to username
    return email.replaceAll('@bytebite.app', '').replaceAll('_', ' ').trim();
  }

  static void setCurrentUserWithRole(String username, String role) {
    _currentUser = username;
    _currentUserRole = role;

    if (!_users.containsKey(username)) {
      _users[username] = {'password': '', 'role': role};
    }
    if (role == 'Owner') _ownerRegistered = true;
  }

  static Future<bool> checkOwnerExistsInFirestore() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Owner')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final username = data['username'] as String? ?? '';

        if (username.isNotEmpty && !_users.containsKey(username)) {
          _users[username] = {'password': '', 'role': 'Owner'};
        }
        _ownerRegistered = true;
        return true;
      }
      return false;
    } catch (_) {
      return _ownerRegistered;
    }
  }

  static Future<void> syncUsersFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = data['username'] as String? ?? '';
        final role = data['role'] as String? ?? 'Helper';
        if (username.isNotEmpty && !_users.containsKey(username)) {
          _users[username] = {'password': '', 'role': role};
        }
        if (role == 'Owner') _ownerRegistered = true;
      }
    } catch (_) {}
  }
}
