import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import using your actual project structure
import '../auth/login_page.dart';
import 'main_navigation_screen.dart';
import 'rider_dashboard_screen.dart';
import 'store_admin_screen.dart';
import 'main_admin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not logged in, show LoginPage
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Fetch User Role from Firestore for logged-in user
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginPage();
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            String role = userData?['role'] ?? 'customer';

            switch (role) {
              case 'rider':
                return const RiderDashboardScreen();
              case 'store_admin':
                return const StoreAdminScreen();
              case 'main_admin':
                return const MainAdminScreen();
              case 'customer':
              default:
                return const MainNavigationScreen();
            }
          },
        );
      },
    );
  }
}