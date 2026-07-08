import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithEmail(String email, String password);
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> sendForgotPasswordEmail(String email);
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
}
