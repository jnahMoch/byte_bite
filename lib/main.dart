import 'package:byte_bite/owner/homepage.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';


void main() {
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
      ),
      // Set the initial route to Login
      home: const LoginPage(),
      // Define routes for easy navigation
      routes: {
        '/dashboard': (context) => const POSHomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}