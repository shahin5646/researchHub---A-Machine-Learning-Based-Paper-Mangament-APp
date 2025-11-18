import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import 'modern_signup_screen.dart';
import '../../navigation/bottom_nav_controller.dart';
import '../../theme/app_theme.dart';

class ModernLoginScreen extends ConsumerStatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  ConsumerState<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends ConsumerState<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final auth = ref.read(authProvider);
        if (!auth.isEmailVerified) {
          _showEmailVerificationDialog();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNavController()),
          );
        }
      } else if (mounted) {
        final errorMessage =
            ref.read(authProvider).errorMessage ?? 'Invalid email or password';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Login error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavController()),
        );
      } else if (mounted) {
        final errorMessage =
            ref.read(authProvider).errorMessage ?? 'Google Sign-In failed';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Google Sign-In error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
      if (mounted)
        _showSuccessSnackBar('Password reset email sent! Check your inbox.');
    } catch (e) {
      if (mounted)
        _showErrorSnackBar('Error sending reset email: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.email_outlined,
                  color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Verify Email',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
            'Please verify your email address. We\'ve sent a verification link to your email.'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).sendEmailVerification();
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Verification email sent!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Error sending verification email');
                }
              }
            },
            child: Text('Resend',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).reloadUser();
              if (!mounted) return;
              final auth = ref.read(authProvider);
              Navigator.pop(context);
              if (auth.isEmailVerified) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const BottomNavController()));
              } else {
                _showErrorSnackBar('Email not verified yet');
              }
            },
            child: const Text('I\'ve Verified'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLogo({double radius = 72}) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.primaryPurple]),
        borderRadius: BorderRadius.circular(radius * 0.22),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Center(
        child: Icon(Icons.school_rounded,
            size: radius * 0.45, color: Colors.white),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    // Simplified visual for Google mark
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
      ),
      child: Center(
        child:
            Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 20),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppTheme.lightGray.withOpacity(0.6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: _buildGoogleIcon(),
        label: Text('Continue with Google',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate)),
      ),
    );
  }

  InputDecoration _pillDecoration({required String label, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintStyle: GoogleFonts.inter(color: AppTheme.mediumGray, fontSize: 13),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.lightGray)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.lightGray)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.6)),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.darkSlate),
      decoration: _pillDecoration(
          label: 'Email',
          prefix: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.email_outlined, color: AppTheme.mediumGray))),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!value.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.darkSlate),
      decoration: _pillDecoration(
        label: 'Password',
        prefix: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.lock_outline, color: AppTheme.mediumGray)),
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppTheme.mediumGray),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 10,
          shadowColor: AppTheme.primaryBlue.withOpacity(0.18),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text('Sign in',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.04),
              Colors.white,
              AppTheme.primaryPurple.withOpacity(0.02)
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModernLogo(),
                        const SizedBox(height: 22),
                        Text('Welcome back',
                            style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkSlate)),
                        const SizedBox(height: 6),
                        Text('Sign in to continue your research journey',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppTheme.mediumGray)),
                        const SizedBox(height: 28),

                        // Glass card (outer)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.66),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 1.0),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildGoogleSignInButton(),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Expanded(
                                          child: Divider(
                                              color: AppTheme.lightGray)),
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text('OR',
                                              style: GoogleFonts.inter(
                                                  color: AppTheme.mediumGray,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      Expanded(
                                          child: Divider(
                                              color: AppTheme.lightGray))
                                    ]),
                                    const SizedBox(height: 14),
                                    _buildEmailField(),
                                    const SizedBox(height: 12),
                                    _buildPasswordField(),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _forgotPassword,
                                        child: Text('Forgot password?',
                                            style: GoogleFonts.inter(
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSignInButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Don\'t have an account? ',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.mediumGray)),
                              TextButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                          pageBuilder: (context, a, sa) =>
                                              const ModernSignUpScreen(),
                                          transitionsBuilder:
                                              (c, an, sa, child) =>
                                                  FadeTransition(
                                                      opacity: an,
                                                      child: child),
                                          transitionDuration: const Duration(
                                              milliseconds: 300))),
                                  child: Text('Sign up',
                                      style: GoogleFonts.inter(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w700)))
                            ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
