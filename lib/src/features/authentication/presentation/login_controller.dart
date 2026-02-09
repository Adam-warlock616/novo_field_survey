import 'package:field_pro/src/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Define the Controller
class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository authRepository;

  LoginController({required this.authRepository})
    : super(const AsyncValue.data(null));

  // 2. The Logic to Sign In
  Future<void> signIn(String email, String password) async {
    // Set state to "Loading" (so the UI can show a spinner)
    state = const AsyncValue.loading();

    // guard() automatically catches errors and sets the state to AsyncValue.error
    state = await AsyncValue.guard(
      () => authRepository.signInWithEmail(email, password),
    );
  }
}

// 3. Create the Provider so the UI can find this Controller
final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return LoginController(authRepository: authRepository);
    });
