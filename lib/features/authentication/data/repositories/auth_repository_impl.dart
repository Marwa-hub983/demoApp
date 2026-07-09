import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
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
    if (email.isEmpty || password.isEmpty) {
      throw const AuthException('Email and password cannot be empty');
    }
    
    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Failed to login with Firebase.');
      }

      // Sync user to mock DB in case they are not registered in the e-commerce database lists
      final matches = _mockDb.users.where((user) => user['id'] == firebaseUser.uid).toList();
      final Map<String, dynamic> userData;
      if (matches.isEmpty) {
        final role = _determineRole(firebaseUser.email ?? email);
        userData = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? email,
          'fullName': firebaseUser.displayName ?? (role == 'admin' ? 'Admin User' : 'Firebase User'),
          'role': role,
          'profilePicture': firebaseUser.photoURL,
          'addresses': [],
          'createdAt': DateTime.now().toIso8601String(),
        };
        _mockDb.users.add(userData);
      } else {
        userData = matches.first;
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
      final token = await firebaseUser.getIdToken();
      await _cache.saveSecure('jwt_auth_token', token ?? 'mock_token');
      await _cache.save('current_user_id', user.id);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An authentication error occurred.');
    } catch (e) {
      throw AuthException(e.toString());
    }
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

    try {
      final userCredential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Failed to register user.');
      }

      // Update displayName in Firebase
      await firebaseUser.updateDisplayName(fullName);

      // Sync new user to Mock Database
      final role = _determineRole(email);
      final newUserData = {
        'id': firebaseUser.uid,
        'email': email,
        'fullName': fullName,
        'role': role,
        'profilePicture': null,
        'addresses': [],
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockDb.users.add(newUserData);

      final user = UserEntity(
        id: firebaseUser.uid,
        email: email,
        fullName: fullName,
        role: role,
        profilePicture: null,
        addresses: const [],
      );

      // Save locally
      final token = await firebaseUser.getIdToken();
      await _cache.saveSecure('jwt_auth_token', token ?? 'mock_token');
      await _cache.save('current_user_id', user.id);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'A registration error occurred.');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> sendForgotPasswordEmail(String email) async {
    if (email.isEmpty) {
      throw const AuthException('Please provide a valid email address.');
    }
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cachedUserId = _cache.read('current_user_id');
    if (cachedUserId == null) return null;

    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != cachedUserId) {
      return null;
    }

    // Sync from Mock Database
    final doc = _mockDb.users.where((u) => u['id'] == cachedUserId).toList();
    final Map<String, dynamic> userData;
    if (doc.isEmpty) {
      // If missing in mock database, sync it back
      userData = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'fullName': firebaseUser.displayName ?? 'Firebase User',
        'role': 'client',
        'profilePicture': firebaseUser.photoURL,
        'addresses': [],
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockDb.users.add(userData);
    } else {
      userData = doc.first;
    }

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
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _cache.deleteSecure('jwt_auth_token');
    await _cache.delete('current_user_id');
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw const AuthException('Google Sign-In was cancelled by the user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential =
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw const AuthException('Failed to authenticate with Google.');
      }

      // Sync Google User to Mock Database
      final matches = _mockDb.users.where((user) => user['id'] == firebaseUser.uid).toList();
      
      final Map<String, dynamic> userData;
      if (matches.isEmpty) {
        final role = _determineRole(firebaseUser.email);
        userData = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'fullName': firebaseUser.displayName ?? (role == 'admin' ? 'Admin User' : 'Google User'),
          'role': role,
          'profilePicture': firebaseUser.photoURL,
          'addresses': [],
          'createdAt': DateTime.now().toIso8601String(),
        };
        _mockDb.users.add(userData);
      } else {
        userData = matches.first;
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
      await _cache.saveSecure('jwt_auth_token', googleAuth.idToken ?? 'mock_token');
      await _cache.save('current_user_id', user.id);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google Sign-In error occurred.');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  String _determineRole(String? email) {
    if (email == null) return 'client';
    final normalized = email.toLowerCase();
    if (normalized == 'admin@example.com' || normalized.contains('admin')) {
      return 'admin';
    }
    return 'client';
  }
}
