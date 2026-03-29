import 'package:byte_bite/owner/homepage.dart';
import 'package:byte_bite/helper/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Offline + Cloud Sync ────────────────────────────────────────────────
  // Must be set BEFORE any Firestore read/write in the app.
  //
  // persistenceEnabled: true  → Firestore caches all data locally.
  //   Reads are served from cache when offline.
  //   Writes (sales, stock, users) are queued and auto-sent when back online.
  //
  // cacheSizeBytes: UNLIMITED → Cache never evicts data automatically.
  //   Safe for a POS app where the product catalog must always be available.
  // ────────────────────────────────────────────────────────────────────────
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const ByteAndBiteApp());
}

class ByteAndBiteApp extends StatelessWidget {
  const ByteAndBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Byte & Bite POS',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppStartupPage(),
      routes: {
        '/dashboard': (context) => const POSHomePage(),
        '/helper-dashboard': (context) => const HelperHomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
      },
    );
  }
}

class AppStartupPage extends StatelessWidget {
  const AppStartupPage({super.key});

  Future<Widget> _getInitialPage() async {
    try {
      // First, check if user is already logged in via Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // User is authenticated, check their role (with timeout)
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          if (doc.exists) {
            final data = doc.data()!;
            final String role = data['role'] ?? 'Helper';
            
            // Load user data into UserStorage
            final email = currentUser.email ?? '';
            final username = UserStorage.fromFirebaseEmail(email);
            UserStorage.setCurrentUserWithRole(username, role);
            
            // Navigate to appropriate dashboard
            return role == 'Helper' ? const HelperHomePage() : const POSHomePage();
          }
        } on TimeoutException {
          // Firestore is slow/unavailable, but user is logged in locally
          return const LoginPage();
        } catch (e) {
          // Error fetching user data, sign out and show login
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
      }

      // No authenticated user, check if owner exists (with timeout)
      try {
        final ownerExists = await UserStorage.checkOwnerExistsInFirestore()
            .timeout(const Duration(seconds: 5));
        return ownerExists ? const LoginPage() : const SignUpPage();
      } on TimeoutException {
        // If Firestore check times out, default to login page
        return const LoginPage();
      }
    } catch (e) {
      // Fallback to login on any error
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF00A86B),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Byte & Bite POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const LoginPage();
        }

        return snapshot.data ?? const LoginPage();
      },
    );
  }
}
