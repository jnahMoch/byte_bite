import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        .map((entry) => {
              'username': entry.key,
              'password': entry.value['password']!,
            })
        .toList();
  }

  static bool resetHelperPassword(String username, String newPassword) {
    if (_users.containsKey(username) &&
        _users[username]!['role'] == 'Helper') {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
  }

  static bool deleteHelper(String username) {
    if (_users.containsKey(username) &&
        _users[username]!['role'] == 'Helper') {
      _users.remove(username);
      return true;
    }
    return false;
  }

  static bool changePassword(
      String username, String oldPassword, String newPassword) {
    if (_users.containsKey(username) &&
        _users[username]!['password'] == oldPassword) {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
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
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = data['username'] as String? ?? '';
        final role = data['role'] as String? ?? 'Helper';
        if (username.isNotEmpty && !_users.containsKey(username)) {
          _users[username] = {'password': '', 'role': role};
        }
        if (role == 'Owner') _ownerRegistered = true;
      }
    } catch (_) {
      
    }
  }
}