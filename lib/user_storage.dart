// User storage with persistent-like functionality
// Supports one-time owner signup and user management

class UserStorage {
  // Users map: username -> {password, role}
  static final Map<String, Map<String, String>> _users = {};

  // Track if owner has been registered (one-time signup)
  static bool _ownerRegistered = false;

  // Current logged in user
  static String? _currentUser;
  static String? _currentUserRole;

  // Check if owner has already registered
  static bool get isOwnerRegistered => _ownerRegistered;

  // Check if this is first time setup (no owner yet)
  static bool get isFirstTimeSetup => !_ownerRegistered;

  // Register the owner (one-time only)
  static bool registerOwner(String username, String password) {
    if (_ownerRegistered) {
      return false; // Owner already exists
    }
    _users[username] = {'password': password, 'role': 'Owner'};
    _ownerRegistered = true;
    return true;
  }

  // Add a helper (only owner can do this)
  static void addHelper(String username, String password) {
    _users[username] = {'password': password, 'role': 'Helper'};
  }

  // Legacy method for backward compatibility
  static void addUser(String username, String password, String role) {
    if (role == 'Owner') {
      registerOwner(username, password);
    } else {
      addHelper(username, password);
    }
  }

  static bool validateUser(String username, String password) {
    if (_users.containsKey(username)) {
      return _users[username]!['password'] == password;
    }
    return false;
  }

  static String? getUserRole(String username) {
    return _users[username]?['role'];
  }

  static bool userExists(String username) {
    return _users.containsKey(username);
  }

  // Set current logged in user
  static void setCurrentUser(String username) {
    _currentUser = username;
    _currentUserRole = _users[username]?['role'];
  }

  // Get current user info
  static String? get currentUser => _currentUser;
  static String? get currentUserRole => _currentUserRole;
  static bool get isOwner => _currentUserRole == 'Owner';
  static bool get isHelper => _currentUserRole == 'Helper';

  // Logout
  static void logout() {
    _currentUser = null;
    _currentUserRole = null;
  }

  // Get all helpers (for user management)
  static List<Map<String, String>> getHelpers() {
    return _users.entries
        .where((entry) => entry.value['role'] == 'Helper')
        .map((entry) => {
              'username': entry.key,
              'password': entry.value['password']!,
            })
        .toList();
  }

  // Reset helper password (owner only)
  static bool resetHelperPassword(String username, String newPassword) {
    if (_users.containsKey(username) && _users[username]?['role'] == 'Helper') {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
  }

  // Delete helper account (owner only)
  static bool deleteHelper(String username) {
    if (_users.containsKey(username) && _users[username]?['role'] == 'Helper') {
      _users.remove(username);
      return true;
    }
    return false;
  }

  // Change own password
  static bool changePassword(String username, String oldPassword, String newPassword) {
    if (_users.containsKey(username) && _users[username]!['password'] == oldPassword) {
      _users[username]!['password'] = newPassword;
      return true;
    }
    return false;
  }

  // Get owner username (for display purposes)
  static String? getOwnerUsername() {
    for (var entry in _users.entries) {
      if (entry.value['role'] == 'Owner') {
        return entry.key;
      }
    }
    return null;
  }
}
