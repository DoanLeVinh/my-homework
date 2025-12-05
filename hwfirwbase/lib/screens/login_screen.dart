import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  String? _phoneVerificationId;

  Future<UserCredential?> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Log tokens for debugging (do NOT expose these in production logs)
      debugPrint('Google accessToken: ${googleAuth.accessToken}');
      debugPrint('Google idToken: ${googleAuth.idToken}');

      if ((googleAuth.idToken == null || googleAuth.idToken!.isEmpty) &&
          (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty)) {
        throw Exception(
          'No idToken or accessToken received from Google Sign-In. Make sure SHA-1 is added in Firebase console and you are using a Google Play-enabled emulator/device.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return userCred;
    } catch (e, st) {
      debugPrint('Google sign-in error: $e\n$st');
      rethrow;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  height: 150,
                  child: Image.asset(
                    'lib/images/Logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, _, __) =>
                        const FlutterLogo(size: 120),
                  ),
                ),
                const SizedBox(height: 12),
                // Title SmartTasks
                Text(
                  'SmartTasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7DF7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A simple and efficient to-do app',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7DF7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            try {
                              final cred = await _signInWithGoogle();
                              if (!context.mounted) return;
                              if (cred != null) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfileScreen(user: cred.user),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign-in failed: $e')),
                              );
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://developers.google.com/identity/images/g-logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (c, a, b) => const Icon(
                            Icons.login,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_loading)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Text('SIGN IN WITH GOOGLE'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Email / Phone options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showEmailSignInDialog(context),
                      child: const Text('Sign in with Email'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showPhoneSignInDialog(context),
                      child: const Text('Sign in with Phone'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '© UTHSmartTasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEmailSignInDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email sign-in'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Sign up
              if (!formKey.currentState!.validate()) return;
              
              try {
                final cred = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text,
                    );
                if (!context.mounted) return;
                final navigator = Navigator.of(context);
                Navigator.of(ctx).pop();
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: cred.user),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                String message = 'Sign up failed';
                if (e.code == 'weak-password') {
                  message = 'Password is too weak';
                } else if (e.code == 'email-already-in-use') {
                  message = 'Email is already registered';
                } else if (e.code == 'invalid-email') {
                  message = 'Invalid email format';
                } else if (e.message != null) {
                  message = e.message!;
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            child: const Text('Sign up'),
          ),
          TextButton(
            onPressed: () async {
              // Sign in
              if (!formKey.currentState!.validate()) return;
              
              try {
                final cred = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text,
                    );
                if (!context.mounted) return;
                final navigator = Navigator.of(context);
                Navigator.of(ctx).pop();
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: cred.user),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                String message = 'Sign in failed';
                if (e.code == 'user-not-found') {
                  message = 'No user found with this email';
                } else if (e.code == 'wrong-password') {
                  message = 'Incorrect password';
                } else if (e.code == 'invalid-email') {
                  message = 'Invalid email format';
                } else if (e.code == 'user-disabled') {
                  message = 'This account has been disabled';
                } else if (e.message != null) {
                  message = e.message!;
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhoneSignInDialog(BuildContext context) async {
    final phoneCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> sendCode() async {
      if (!formKey.currentState!.validate()) return;
      
      final phone = phoneCtrl.text.trim();
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval
          final userCred = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
          if (!context.mounted) return;
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(user: userCred.user),
            ),
          );
        },
        verificationFailed: (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (verificationId, resendToken) {
          _phoneVerificationId = verificationId;
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Code sent')));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _phoneVerificationId = verificationId;
        },
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phone sign-in'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone (e.g. +84123456789)',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value.trim())) {
                    return 'Enter a valid phone number with country code (e.g. +84...)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Verification code'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_phoneVerificationId != null && (value == null || value.isEmpty)) {
                    return 'Enter verification code';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await sendCode();
            },
            child: const Text('Send code'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final code = codeCtrl.text.trim();
              if (_phoneVerificationId == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please request code first')),
                );
                return;
              }
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: _phoneVerificationId!,
                  smsCode: code,
                );
                final userCred = await FirebaseAuth.instance
                    .signInWithCredential(credential);
                if (!context.mounted) return;
                final navigator = Navigator.of(context);
                Navigator.of(ctx).pop();
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: userCred.user),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign in failed: ${e.message}')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
