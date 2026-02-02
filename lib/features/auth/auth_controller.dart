import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/firebase_service.dart';


/// Giriş işlemlerini ve kullanıcı durumunu yöneten Riverpod provider'ı.
final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());


/// Kullanıcı oturum durumunu temsil eden model.
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? role;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.role,
  });

  /// Durumun kopyasını oluşturur.
  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
    );
  }
}


/// Giriş işlemlerini yöneten controller. Hata yönetimi ve açıklamalar eklendi.
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  /// Kullanıcı giriş işlemi. Hatalar state'e yazılır.
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Firebase Auth ile giriş
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(email: email, password: password);
      String role = 'öğrenci';
      if (email == 'yosinkhon1@gmail.com') {
        role = 'admin';
      } else {
        // Kullanıcı rolünü Firestore'dan çek (örnek: users koleksiyonu altında role alanı)
        final userDoc = await FirebaseService.firestore.collection('users').doc(credential.user?.uid).get();
        role = userDoc.data()?['role'] ?? 'öğrenci';
      }
      state = state.copyWith(isAuthenticated: true, role: role, isLoading: false);
    } on FirebaseAuthException catch (e) {
      String message = 'Bilinmeyen hata';
      if (e.code == 'user-not-found') {
        message = 'Kullanıcı bulunamadı';
      } else if (e.code == 'wrong-password') {
        message = 'Şifre yanlış';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta';
      } else {
        message = e.message ?? e.code;
      }
      state = state.copyWith(error: message, isLoading: false);
    } catch (e) {
      // Diğer hatalar
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Kullanıcı kayıt işlemi
  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await FirebaseService.auth.createUserWithEmailAndPassword(email: email, password: password);
      // Yeni kullanıcıya Firestore'da rol ata
      await FirebaseService.firestore.collection('users').doc(credential.user?.uid).set({'role': 'öğrenci'});
      state = state.copyWith(isAuthenticated: true, role: 'öğrenci', isLoading: false);
    } on FirebaseAuthException catch (e) {
      String message = 'Bilinmeyen hata';
      if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kayıtlı';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta';
      } else if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf';
      } else {
        message = e.message ?? e.code;
      }
      state = state.copyWith(error: message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Kullanıcı çıkış işlemi.
  void signOut() {
    state = AuthState();
  }
}
