import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn({
    String email = 'galib.mahmud@gmail.com',
    String name = 'Galib Mahmud',
    String? googleId,
    String? avatarUrl,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().googleSignIn(
        email: email,
        name: name,
        googleId: googleId ?? 'goog_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        avatarUrl: avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                  ),
                  const SizedBox(width: 12),
                  const Text('Choose an account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('to continue to SignBoard', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Text('GM', style: TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.bold)),
                ),
                title: const Text('Galib Mahmud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('galib.mahmud@gmail.com', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleGoogleSignIn(
                    email: 'galib.mahmud@gmail.com',
                    name: 'Galib Mahmud',
                    googleId: 'goog_galib_mahmud',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFCE7F3),
                  child: Text('MJ', style: TextStyle(color: Color(0xFF9D174D), fontWeight: FontWeight.bold)),
                ),
                title: const Text('Maya Johnson', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('maya.j@example.com', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleGoogleSignIn(
                    email: 'maya.j@example.com',
                    name: 'Maya Johnson',
                    googleId: 'goog_maya_johnson_01',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person_add_outlined, color: AppTheme.primaryDark, size: 20),
                ),
                title: const Text('Add custom Google account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Enter your own name & email', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCustomAccountDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomAccountDialog() {
    final nameCtrl = TextEditingController(text: 'Galib Mahmud');
    final emailCtrl = TextEditingController(text: 'galib@gmail.com');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign in with Google Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Google Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (name.isNotEmpty && email.isNotEmpty) {
                Navigator.pop(ctx);
                _handleGoogleSignIn(email: email, name: name);
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo container
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.signpost_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Welcome to SignBoard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Find nearby tutors, services, rentals, and properties in one tap.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              // Primary: Sign in with Google Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isLoading ? null : _showAccountPicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Icon representation
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Alternative: Instant Guest Entry
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => _handleGoogleSignIn(
                          email: 'guest_${DateTime.now().millisecondsSinceEpoch}@signboard.app',
                          name: 'Guest Explorer',
                        ),
                child: const Text(
                  'Continue as Guest / New User',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
