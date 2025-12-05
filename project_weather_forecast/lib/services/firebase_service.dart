import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== EMAIL/PASSWORD AUTHENTICATION =====

  /// Register with email and password
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Không thể tạo tài khoản'};
      }

      // Update display name
      await user.updateDisplayName(displayName);

      // Try to create user document in Firestore (optional)
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': displayName,
          'photoURL': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'authProvider': 'email',
        });
        debugPrint('✅ Created Firestore user document for $email');
      } catch (firestoreError) {
        debugPrint(
          '⚠️ Firestore sync failed (registration still successful): $firestoreError',
        );
      }

      return {'success': true, 'user': user, 'message': 'Đăng ký thành công!'};
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';

      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
          break;
        case 'email-already-in-use':
          message = 'Email đã được sử dụng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'operation-not-allowed':
          message = 'Phương thức đăng ký này không được phép';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Register error: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Đăng nhập thất bại'};
      }

      // Try to update last login in Firestore (optional)
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Updated Firestore last login for ${user.email}');
      } catch (firestoreError) {
        debugPrint(
          '⚠️ Firestore sync failed (login still successful): $firestoreError',
        );
      }

      return {
        'success': true,
        'user': user,
        'message': 'Đăng nhập thành công!',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';

      switch (e.code) {
        case 'user-not-found':
          message = 'Email không tồn tại';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'too-many-requests':
          message = 'Quá nhiều lần thử. Vui lòng thử lại sau';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Sign in error: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }

  // ===== GOOGLE SIGN IN =====

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return {'success': false, 'message': 'Đăng nhập bị hủy'};
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return {'success': false, 'message': 'Đăng nhập thất bại'};
      }

      // Try to sync with Firestore (optional - allow login even if Firestore fails)
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Create new user document
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          });
          debugPrint('✅ Created Firestore user document for ${user.email}');
        } else {
          // Update last login
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          });
          debugPrint('✅ Updated Firestore user document for ${user.email}');
        }
      } catch (firestoreError) {
        // Log Firestore error but don't fail the login
        debugPrint(
          '⚠️ Firestore sync failed (login still successful): $firestoreError',
        );
      }

      return {
        'success': true,
        'user': user,
        'message': 'Đăng nhập Google thành công!',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign in error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': 'Lỗi đăng nhập Google: ${e.message}',
      };
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }

  // ===== PASSWORD RESET =====

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message':
            'Email khôi phục mật khẩu đã được gửi! Vui lòng kiểm tra hộp thư của bạn.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Gửi email thất bại';

      switch (e.code) {
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'user-not-found':
          message = 'Email không tồn tại trong hệ thống';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Password reset error: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }

  // ===== SIGN OUT =====

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // ===== USER PROFILE =====

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _firestore.collection('users').doc(user.uid).update(updates);

      // Reload user to get updated info
      await user.reload();

      return {'success': true, 'message': 'Cập nhật thông tin thành công!'};
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'message': 'Cập nhật thất bại: $e'};
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }

  // ===== EMAIL VERIFICATION =====

  /// Send email verification
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email đã được xác thực'};
      }

      await user.sendEmailVerification();

      return {'success': true, 'message': 'Email xác thực đã được gửi!'};
    } catch (e) {
      debugPrint('Send email verification error: $e');
      return {'success': false, 'message': 'Gửi email thất bại: $e'};
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ===== DELETE ACCOUNT =====

  /// Delete user account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete auth account
      await user.delete();

      return {'success': true, 'message': 'Tài khoản đã được xóa'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return {
          'success': false,
          'message': 'Vui lòng đăng nhập lại để xác nhận xóa tài khoản',
          'requiresReauth': true,
        };
      }
      return {
        'success': false,
        'message': 'Xóa tài khoản thất bại: ${e.message}',
      };
    } catch (e) {
      debugPrint('Delete account error: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }
}
