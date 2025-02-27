import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthApiProvider {
  Future<Map<String, dynamic>> firebaseUserSignUp(String emailAddress, String password) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      return {
        'success': true,
        'user': credential.user,
        'message': 'Account created successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An unknown error occurred.';
      }
      if (kDebugMode) {
        print(message);
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }
}