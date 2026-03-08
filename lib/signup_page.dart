// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';     // NEW
import 'package:firebase_auth/firebase_auth.dart';         // NEW
import 'package:flutter/material.dart';
import 'user_storage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ─── NEW: loading state to disable button during Firebase call ───────────
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ─── CHANGED: now checks Firestore via checkOwnerExistsInFirestore()
    //     instead of the unreliable in-memory isOwnerRegistered flag ─────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ownerExists = await UserStorage.checkOwnerExistsInFirestore();
      if (ownerExists) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ─── CHANGED: now async, writes to Firebase Auth + Firestore + UserStorage ─
  Future<void> _handleSignUp() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // ── Validation (unchanged) ───────────────────────────────────────────────
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.redAccent);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(
          'Password must be at least 6 characters', Colors.redAccent);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── STEP 1: Check Firestore — block duplicate Owner registration ───────
      final existingOwner =
          await UserStorage.checkOwnerExistsInFirestore();
      if (existingOwner) {
        _showSnackBar(
            'Owner already registered. Please login.', Colors.redAccent);
        Future.delayed(
            const Duration(seconds: 1),
            () => Navigator.pushReplacementNamed(context, '/login'));
        return;
      }

      // ── STEP 2: Create Firebase Auth account ──────────────────────────────
      // Username is stored in Firestore; Firebase Auth requires email format
      final email = UserStorage.toFirebaseEmail(username);
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // ── STEP 3: Write Owner document to Firestore ─────────────────────────
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'username': username,
        'role': 'Owner',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── STEP 4: Mirror to local UserStorage (fallback) ───────────────────
      UserStorage.registerOwner(username, password);

      _showSnackBar(
          'Owner account created! You can now login.', Colors.green);
      Future.delayed(const Duration(seconds: 2),
          () => Navigator.pushReplacementNamed(context, '/login'));
    } on FirebaseAuthException catch (e) {
      // ── Firebase Auth error — fall back to local registration ─────────────
      final localSuccess = UserStorage.registerOwner(username, password);
      if (localSuccess) {
        _showSnackBar(
            'Account created (offline mode). You can now login.',
            Colors.orange);
        Future.delayed(const Duration(seconds: 2),
            () => Navigator.pushReplacementNamed(context, '/login'));
      } else {
        _showSnackBar(
            e.message ?? 'Registration failed. Try again.',
            Colors.redAccent);
      }
    } catch (_) {
      _showSnackBar('An unexpected error occurred.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF009661).withValues(alpha: 0.2),
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
                  const SizedBox(height: 20),
                  const Text('Owner Setup',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  Text('Set up your owner account to get started',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009661).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.admin_panel_settings,
                            size: 16, color: Color(0xFF009661)),
                        SizedBox(width: 6),
                        Text('One-time setup',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF009661),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Username',
                    hint: 'Enter username',
                    controller: _usernameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Password',
                    hint: 'Enter password',
                    controller: _passwordController,
                    isPassword: true,
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 25),

                  // ── CHANGED: button shows spinner when _isLoading is true ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.how_to_reg_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Create Owner Account',
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
                    'You can add helper accounts later in Settings',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
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
    required TextEditingController controller,
    bool isPassword = false,
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