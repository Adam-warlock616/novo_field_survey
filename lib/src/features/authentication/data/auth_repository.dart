import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Constructor: We ask for FirebaseAuth to be "injected" in
  AuthRepository(this._firebaseAuth);

  // 1. Monitor Authentication State (Stream)
  // This tells the app in real-time if the user is logged in or out
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // 2. Get Current User
  User? get currentUser => _firebaseAuth.currentUser;

  // 3. Sign In Function
  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 4. Sign Out Function
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

// --- RIVERPOD PROVIDERS ---

// 1. Provider for the FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 2. Provider for our Repository (The UI talks to this)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthRepository(auth);
});

// 3. Provider for the User's State (Logged In or Null)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
