// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';     // NEW
import 'package:firebase_auth/firebase_auth.dart';         // NEW
import 'package:flutter/material.dart';
import 'user_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // ─── NEW: loading state while Firebase responds ──────────────────────────
  bool _isLoading = false;

  // ─── CHANGED: now async — tries Firebase first, falls back to UserStorage ─
  Future<void> _handleLogin() async {
    String username = _userController.text.trim();
    String password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    // ════════════════════════════════════════════════════════════════════════
    // PATH A — Firebase Auth (online)
    // ════════════════════════════════════════════════════════════════════════
    try {
      final email = UserStorage.toFirebaseEmail(username);

      // Authenticate with Firebase Auth
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Fetch role from Firestore using the Firebase UID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        _showSnackBar('User profile not found. Contact your owner.',
            Colors.redAccent);
        return;
      }

      final data = doc.data()!;

      // Check if account is active (owner can deactivate helpers)
      if (data['isActive'] == false) {
        await FirebaseAuth.instance.signOut();
        _showSnackBar('Your account has been deactivated.', Colors.redAccent);
        return;
      }

      final String role = data['role'] ?? 'Helper';

      // Sync into local UserStorage so existing code (e.g. UserStorage.isOwner) works
      UserStorage.setCurrentUserWithRole(username, role);

      // Also sync all users in background for fallback
      UserStorage.syncUsersFromFirestore();

      _navigateByRole(role);
      return; // ← success via Firebase, skip fallback

    } on FirebaseAuthException {
      // ── Firebase failed (wrong password or network error) ─────────────────
      // Fall through to PATH B below
    } catch (_) {
      // ── Unexpected Firebase error — fall through to PATH B ────────────────
    }

    // ════════════════════════════════════════════════════════════════════════
    // PATH B — Local UserStorage fallback (offline / Firebase unreachable)
    // ════════════════════════════════════════════════════════════════════════
    if (UserStorage.validateUser(username, password)) {
      UserStorage.setCurrentUser(username);
      final String? role = UserStorage.getUserRole(username);
      _showSnackBar('Logged in (offline mode)', Colors.orange);
      _navigateByRole(role ?? 'Helper');
    } else {
      _showSnackBar('Invalid username or password', Colors.redAccent);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Navigate to the correct dashboard based on role
  void _navigateByRole(String role) {
    if (role == 'Helper') {
      Navigator.pushReplacementNamed(context, '/helper-dashboard');
    } else {
      // Owner (or any unrecognized role defaults to owner dashboard)
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ─── BUILD (UI completely unchanged) ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF009661).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/byte and bite logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 8),
                  Text('Sign in to continue',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 28),
                  _buildTextField(
                      label: 'Username',
                      hint: 'Enter username',
                      controller: _userController,
                      icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildTextField(
                      label: 'Password',
                      hint: 'Enter password',
                      isPassword: true,
                      controller: _passController,
                      icon: Icons.lock_outline),
                  const SizedBox(height: 28),

                  // ── CHANGED: shows spinner when _isLoading is true ─────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        shadowColor:
                            const Color(0xFF009661).withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Login',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Byte & Bite POS v1.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF374151))),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF009661), size: 20)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF009661), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}