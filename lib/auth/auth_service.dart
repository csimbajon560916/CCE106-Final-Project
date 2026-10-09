import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 1. Sign In with Email & Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 2. Register Customer
  Future<UserCredential> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // 3. Google Sign In for Customers
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    User? user = userCredential.user;

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'Customer',
          'email': user.email,
          'photoUrl': user.photoURL,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

  // 4. Sign Out Method
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // Inside AuthService class in lib/auth/auth_service.dart

// Create a Store Admin Account
Future<void> createStoreAdmin({
  required String email,
  required String password,
  required String name,
  required String phone,
  required String storeName,
}) async {
  // Use a secondary Firebase App instance if you don't want to auto-logout the current Main Admin session
  UserCredential cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  await _firestore.collection('users').doc(cred.user!.uid).set({
    'uid': cred.user!.uid,
    'name': name,
    'email': email,
    'phone': phone,
    'storeName': storeName,
    'role': 'store_admin',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// Create a Rider Account
Future<void> createRider({
  required String email,
  required String password,
  required String name,
  required String phone,
  required String vehicleDetails,
}) async {
  UserCredential cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  await _firestore.collection('users').doc(cred.user!.uid).set({
    'uid': cred.user!.uid,
    'name': name,
    'email': email,
    'phone': phone,
    'vehicleDetails': vehicleDetails,
    'role': 'rider',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
}