import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:organiz4t3/screens/home_screen.dart';
import 'package:organiz4t3/screens/login_screen.dart';
import 'package:organiz4t3/screens/splash_screen.dart';
import 'package:organiz4t3/services/firebase_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData) {
          final firebaseService = FirebaseService();
          return FutureBuilder<String>(
            future: firebaseService.getUserName(),
            builder: (context, userNameSnapshot) {
              if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              } else {
                return HomeScreen(
                  userName: userNameSnapshot.data ?? 'Usuario',
                  updateTask: firebaseService.updateTask,
                  deleteTask: firebaseService.deleteTask,
                );
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}