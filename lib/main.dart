import 'package:byte_bite/auth/backup_service.dart';
import 'package:byte_bite/owner/homepage.dart';
import 'package:byte_bite/helper/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  // ── Security: Automatic Daily Backups ─────────────────────────────────
  // Schedule automatic backups on app startup to prevent data loss.
  // Backups are stored locally and can be restored if needed.
  // ────────────────────────────────────────────────────────────────────────
  await BackupService().scheduleAutomaticBackups();

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
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
      },
      onGenerateRoute: (settings) {
        // Route guard for protected pages
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (context) => const POSHomePage(),
            settings: settings,
          );
        }
        if (settings.name == '/helper-dashboard') {
          return MaterialPageRoute(
            builder: (context) => const HelperHomePage(),
            settings: settings,
          );
        }
        return null; // Let MaterialApp handle unknown routes
      },
    );
  }
}

class AppStartupPage extends StatelessWidget {
  const AppStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Session Persistence Fix ─────────────────────────────────────────
    // Firebase Auth automatically saves the login session on device.
    // If currentUser is not null, the user already logged in previously
    // and does not need to log in again — go straight to their dashboard.
    // ────────────────────────────────────────────────────────────────────
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final role = UserStorage.getUserRole(UserStorage.currentUser ?? '');
      if (role == 'Helper') return const HelperHomePage();
      return const POSHomePage();
    }

    // No active session — run normal startup check
    return FutureBuilder<bool>(
      future: UserStorage.checkOwnerExistsInFirestore(),
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
        final ownerExists = snapshot.data ?? UserStorage.isOwnerRegistered;
        return ownerExists ? const LoginPage() : const SignUpPage();
      },
    );
  }
}