import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'screens/barcode_scanner_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/enterprise_dashboard_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Firebase.initializeApp();
        print('Firebase initialized successfully');
        runApp(MyApp());
      } catch (e) {
        print('Error initializing Firebase: $e');
        // Fallback UI if Firebase fails
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Failed to initialize Firebase: $e')),
            ),
          ),
        );
      }
    },
    (error, stackTrace) {
      print('Top-level error: $error');
      print('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:
          FirebaseAuth.instance.currentUser == null
              ? BarcodeScannerScreen()
              : LoginScreen(),
      title: 'Food Analyzer',
      theme: ThemeData(primarySwatch: Colors.green),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/reset': (context) => ResetPasswordScreen(),
        '/scanner': (context) => BarcodeScannerScreen(),
        '/product': (context) => ProductDetailsScreen(),
        '/admin': (context) => AdminDashboardScreen(),
        '/enterprise': (context) => EnterpriseDashboardScreen(),
      },
    );
  }
}
