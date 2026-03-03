import 'package:byte_bite/owner/homepage.dart';
import 'package:byte_bite/helper/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';                              // NEW
import 'login_page.dart';
import 'signup_page.dart';
import 'user_storage.dart';

// ─── CHANGED: main() is now async to await Firebase.initializeApp() ───────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();               // NEW
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,       // UPDATED
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
      // ─── CHANGED: replaced direct UserStorage.isFirstTimeSetup check
      //     with AppStartupPage which checks Firestore asynchronously ──────────
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

// ─── NEW: Checks Firestore (with local fallback) before deciding
//     whether to show LoginPage or SignUpPage ────────────────────────────────
class AppStartupPage extends StatelessWidget {
  const AppStartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserStorage.checkOwnerExistsInFirestore(),
      builder: (context, snapshot) {
        // Show branded splash while checking
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
        // Use Firestore result; fall back to local flag if offline
        final ownerExists =
            snapshot.data ?? UserStorage.isOwnerRegistered;
        return ownerExists ? const LoginPage() : const SignUpPage();
      },
    );
  }
}