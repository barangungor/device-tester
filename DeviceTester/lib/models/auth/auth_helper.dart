import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthHelper {
  static FirebaseAuthHelper? _instance;
  static FirebaseAuthHelper get instance {
    _instance ??= FirebaseAuthHelper._init();
    return _instance!;
  }

  FirebaseAuthHelper._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  get user => _auth.currentUser;

  Future signIn({String? email, String? password}) async {
    try {
      await _auth
          .signInWithEmailAndPassword(email: email!, password: password!)
          .then((value) {
        if (value.user != null) return null;
      });
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
