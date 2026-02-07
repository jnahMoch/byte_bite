// Simple in-memory user storage (will be replaced with database later)
class UserStorage {
  static final Map<String, Map<String, String>> _users = {};

  static void addUser(String username, String password, String role) {
    _users[username] = {'password': password, 'role': role};
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
}
