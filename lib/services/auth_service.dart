import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Iniciar sesión con correo electrónico y contraseña
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredencial = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      print("Contenido de response: $userCredencial");

      return userCredencial;
    } on FirebaseAuthException catch (e) {
      if(e.code == 'user - not - found'){
        return null;
      }
      if (e.code == 'wrong-passowrd'){
        print("Error al iniciar sesión: $e");
        return null;}
    }
    return null;
  }

  // Registrar usuario con correo electrónico y contraseña
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print("Error al registrar: $e");
      return null;
    }
  }

  // Iniciar sesión con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
      return null;
    }
  }

  // Iniciar sesión con Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        return await _auth.signInWithCredential(credential);
      } else {
        print("Inicio de sesión con Facebook cancelado.");
        return null;
      }
    } catch (e) {
      print("Error al iniciar sesión con Facebook: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Cierra sesión en Firebase
      await _googleSignIn.signOut(); // Cierra sesión en Google
      await FacebookAuth.instance.logOut(); // Cierra sesión en Facebook
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}


