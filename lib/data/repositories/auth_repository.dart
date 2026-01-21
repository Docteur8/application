import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _createUserDocument(
          uid: credential.user!.uid,
          email: email.trim(),
          name: name,
          phone: phone,
        );

        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDoc = await FirebaseService.usersCollection
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _createUserDocument(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'Utilisateur',
            phone: '',
          );
        }
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    final user = UserModel(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      favorites: [],
      createdAt: DateTime.now(),
    );

    await FirebaseService.usersCollection.doc(uid).set(user.toFirestore());
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await FirebaseService.usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données utilisateur');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await FirebaseService.usersCollection.doc(uid).update(updates);

      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil');
    }
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'invalid-email':
          return 'Email invalide';
        case 'weak-password':
          return 'Le mot de passe est trop faible';
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard';
        case 'network-request-failed':
          return 'Erreur de connexion réseau';
        default:
          return 'Erreur d\'authentification: ${e.message}';
      }
    }
    return e.toString();
  }
}