import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../database/app_database.dart';
import 'database_provider.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final AppDatabase database;
  final DatabaseProvider databaseProvider;
  final FirebaseService _firebaseService = FirebaseService();

  static const String _sessionTokenKey = 'user_session_token';

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider({required this.database, required this.databaseProvider});

  /// Hash password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random session token
  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Save session token to SharedPreferences
  Future<void> _saveSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  /// Get session token from SharedPreferences
  Future<String?> _getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Clear session token from SharedPreferences
  Future<void> _clearSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
  }

  /// Check if user has valid session
  Future<bool> checkSession() async {
    try {
      final token = await _getSessionToken();
      if (token == null) return false;

      final user = await database.getUserBySession(token);
      if (user != null) {
        _isAuthenticated = true;
        await databaseProvider.initialize(userEmail: user.email);
        notifyListeners();
        return true;
      }

      // Session expired or invalid
      await _clearSessionToken();
      return false;
    } catch (e) {
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  /// Login with email and password (supports Firebase + Local)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool useFirebase = true,
  }) async {
    try {
      // Try Firebase login first if enabled
      if (useFirebase) {
        final firebaseResult = await _firebaseService.signInWithEmail(
          email: email,
          password: password,
        );

        if (firebaseResult['success']) {
          final firebaseUser = firebaseResult['user'] as firebase_auth.User;

          // Sync Firebase user to local database
          await _syncFirebaseUserToLocal(firebaseUser);

          // Initialize database provider
          await databaseProvider.initialize(userEmail: email);

          _isAuthenticated = true;
          notifyListeners();

          return firebaseResult;
        }
        // If Firebase fails, fall back to local auth
      }

      // Local database authentication
      final user = await database.getUserByEmail(email);

      if (user == null) {
        return {'success': false, 'message': 'Email không tồn tại'};
      }

      // Verify password
      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Generate session token
      final sessionToken = _generateSessionToken();

      // Create session in database
      await database.createSession(user.id, sessionToken);

      // Save token to SharedPreferences
      await _saveSessionToken(sessionToken);

      // Initialize database provider with user data
      await databaseProvider.initialize(userEmail: email);

      _isAuthenticated = true;
      notifyListeners();

      return {'success': true, 'message': 'Đăng nhập thành công', 'user': user};
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Lỗi đăng nhập: ${e.toString()}'};
    }
  }

  /// Register new user (supports Firebase + Local)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
    bool useFirebase = true,
  }) async {
    try {
      // Try Firebase registration first if enabled
      if (useFirebase) {
        final firebaseResult = await _firebaseService.registerWithEmail(
          email: email,
          password: password,
          displayName: displayName ?? email.split('@')[0],
        );

        if (firebaseResult['success']) {
          final firebaseUser = firebaseResult['user'] as firebase_auth.User;

          // Sync Firebase user to local database
          await _syncFirebaseUserToLocal(firebaseUser);

          // Initialize database provider
          await databaseProvider.initialize(userEmail: email);

          _isAuthenticated = true;
          notifyListeners();

          return firebaseResult;
        }
        // If Firebase fails, fall back to local registration
      }

      // Local database registration
      // Check if email already exists
      final exists = await database.emailExists(email);
      if (exists) {
        return {'success': false, 'message': 'Email đã được sử dụng'};
      }

      // Hash password
      final hashedPassword = _hashPassword(password);

      // Create user
      final userId = await database.insertUser(
        UsersCompanion.insert(
          email: email,
          password: hashedPassword,
          displayName: Value(displayName),
          uid: _generateSessionToken(), // Use as unique user ID
          createdAt: Value(DateTime.now()),
        ),
      );

      // Generate session token
      final sessionToken = _generateSessionToken();

      // Create session
      await database.createSession(userId, sessionToken);

      // Save token to SharedPreferences
      await _saveSessionToken(sessionToken);

      // Initialize database provider
      await databaseProvider.initialize(userEmail: email);

      _isAuthenticated = true;
      notifyListeners();

      return {'success': true, 'message': 'Đăng ký thành công'};
    } catch (e) {
      debugPrint('Register error: $e');
      return {'success': false, 'message': 'Lỗi đăng ký: ${e.toString()}'};
    }
  }

  /// Login with Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final result = await _firebaseService.signInWithGoogle();

      if (result['success']) {
        final firebaseUser = result['user'] as firebase_auth.User;

        // Try to sync Firebase user to local database (allow login even if sync fails)
        try {
          await _syncFirebaseUserToLocal(firebaseUser);
        } catch (syncError) {
          debugPrint(
            '⚠️ Warning: Firestore sync failed, but login continues: $syncError',
          );
          // Continue with login even if Firestore sync fails
        }

        // Initialize database provider
        await databaseProvider.initialize(userEmail: firebaseUser.email!);

        _isAuthenticated = true;
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('Google login error: $e');
      return {
        'success': false,
        'message': 'Lỗi đăng nhập Google: ${e.toString()}',
      };
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      return await _firebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      return {
        'success': false,
        'message': 'Lỗi khôi phục mật khẩu: ${e.toString()}',
      };
    }
  }

  /// Sync Firebase user to local database
  Future<void> _syncFirebaseUserToLocal(firebase_auth.User firebaseUser) async {
    try {
      // Check if user exists in local database
      final existingUser = await database.getUserByEmail(firebaseUser.email!);

      if (existingUser == null) {
        // Create new local user
        final userId = await database.insertUser(
          UsersCompanion.insert(
            email: firebaseUser.email!,
            password: '', // Empty password for Firebase users
            displayName: Value(
              firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
            ),
            uid: firebaseUser.uid,
            createdAt: Value(DateTime.now()),
          ),
        );

        // Create session
        final sessionToken = _generateSessionToken();
        await database.createSession(userId, sessionToken);
        await _saveSessionToken(sessionToken);

        debugPrint('✅ Created new local user for ${firebaseUser.email}');
      } else {
        // Update existing user with Firebase UID
        await database.updateUser(
          UsersCompanion(
            id: Value(existingUser.id),
            uid: Value(firebaseUser.uid),
            displayName: Value(
              firebaseUser.displayName ?? existingUser.displayName,
            ),
          ),
        );

        // Create session
        final sessionToken = _generateSessionToken();
        await database.createSession(existingUser.id, sessionToken);
        await _saveSessionToken(sessionToken);

        debugPrint('✅ Updated existing user for ${firebaseUser.email}');
      }
    } catch (e) {
      debugPrint('❌ Sync Firebase user error: $e');
      // Don't rethrow - allow login to continue even if Firestore sync fails
      throw Exception('Firestore sync failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _firebaseService.signOut();

      // Clear local session
      final user = databaseProvider.currentUser;
      if (user != null) {
        await database.clearSession(user.id);
      }

      await _clearSessionToken();

      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = databaseProvider.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      // Verify current password
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (user.password != hashedCurrentPassword) {
        return {'success': false, 'message': 'Mật khẩu hiện tại không đúng'};
      }

      // Update password
      final hashedNewPassword = _hashPassword(newPassword);
      await database.updateUser(
        UsersCompanion(id: Value(user.id), password: Value(hashedNewPassword)),
      );

      return {'success': true, 'message': 'Đổi mật khẩu thành công'};
    } catch (e) {
      debugPrint('Change password error: $e');
      return {'success': false, 'message': 'Lỗi đổi mật khẩu: ${e.toString()}'};
    }
  }
}
