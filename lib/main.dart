import 'package:byte_bite/owner/homepage.dart';
import 'package:byte_bite/helper/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
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
