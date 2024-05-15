import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;
      if (user != null) {
        // Create a user record in Firestore
        await _createUserRecord(user.uid, email, password);
      }
      return user;
    } catch (e) {
      print("Error occurred during signup: $e");
      throw e; // Rethrow the error to handle it in the UI
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Some error occured");
    }
  }

  Future<void> _createUserRecord(
    String userId,
    String email,
    String password,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('student').doc(userId).set({
        'email': email,
        'password': password,
      });
    } catch (e) {
      print("Error occurred while creating user record: $e");
      throw e;
    }
  }
}
