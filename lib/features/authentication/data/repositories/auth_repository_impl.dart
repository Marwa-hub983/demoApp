import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/mock_database_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final MockDatabaseService _mockDb;
  final CacheService _cache;

  AuthRepositoryImpl(this._mockDb, this._cache);

  @override
  Future<UserEntity> loginWithEmail(String email, String password) async {
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password cannot be empty');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find User
    final matches = _mockDb.users.where((user) => user['email'] == email).toList();
    if (matches.isEmpty) {
      throw const AuthException('No account associated with this email.');
    }
    
    final userData = matches.first;
    
    // Simple password check for mock engine (all accounts seeded use 'password')
    if (password != 'password') {
      throw const AuthException('Incorrect password. Please try again.');
    }

    final addresses = (userData['addresses'] as List)
        .map((a) => AddressEntity.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    final user = UserEntity(
      id: userData['id'] as String,
      email: userData['email'] as String,
      fullName: userData['fullName'] as String,
      role: userData['role'] as String,
      profilePicture: userData['profilePicture'] as String?,
      addresses: addresses,
    );

    // Save tokens and session details locally
    await _cache.saveSecure('jwt_auth_token', 'mock_jwt_token_${user.id}');
    await _cache.save('current_user_id', user.id);
    
    return user;
  }

  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      throw const AuthException('Please fill in all registration fields.');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // Check if account already exists
    final exists = _mockDb.users.any((u) => u['email'] == email);
    if (exists) {
      throw const AuthException('Email is already registered under another account.');
    }

    final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUserData = {
      'id': newUserId,
      'email': email,
      'fullName': fullName,
      'role': 'client',
      'profilePicture': null,
      'addresses': [],
      'createdAt': DateTime.now().toIso8601String(),
    };

    _mockDb.users.add(newUserData);

    final user = UserEntity(
      id: newUserId,
      email: email,
      fullName: fullName,
      role: 'client',
      profilePicture: null,
      addresses: const [],
    );

    // Auto-login after registration
    await _cache.saveSecure('jwt_auth_token', 'mock_jwt_token_${user.id}');
    await _cache.save('current_user_id', user.id);

    return user;
  }

  @override
  Future<void> sendForgotPasswordEmail(String email) async {
    if (email.isEmpty) {
      throw const AuthException('Please provide a valid email address.');
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cachedUserId = _cache.read('current_user_id');
    if (cachedUserId == null) return null;

    final doc = _mockDb.users.where((u) => u['id'] == cachedUserId).toList();
    if (doc.isEmpty) return null;

    final userData = doc.first;
    final addresses = (userData['addresses'] as List)
        .map((a) => AddressEntity.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return UserEntity(
      id: userData['id'] as String,
      email: userData['email'] as String,
      fullName: userData['fullName'] as String,
      role: userData['role'] as String,
      profilePicture: userData['profilePicture'] as String?,
      addresses: addresses,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _cache.deleteSecure('jwt_auth_token');
    await _cache.delete('current_user_id');
  }
}
