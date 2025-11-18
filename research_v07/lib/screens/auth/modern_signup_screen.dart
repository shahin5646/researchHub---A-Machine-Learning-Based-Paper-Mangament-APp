import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../models/user.dart';
import '../../navigation/bottom_nav_controller.dart';
import '../../theme/app_theme.dart';

class ModernSignUpScreen extends ConsumerStatefulWidget {
  const ModernSignUpScreen({super.key});

  @override
  ConsumerState<ModernSignUpScreen> createState() => _ModernSignUpScreenState();
}

class _ModernSignUpScreenState extends ConsumerState<ModernSignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _institutionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  UserRole _selectedRole = UserRole.student;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _institutionController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        institution: _institutionController.text.trim().isEmpty
            ? null
            : _institutionController.text.trim(),
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        designation: _designationController.text.trim().isEmpty
            ? null
            : _designationController.text.trim(),
      );

      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        final errorMessage = ref.read(authProvider).errorMessage ??
            'Registration failed. Please try again.';

        // Check if account already exists
        if (errorMessage.toLowerCase().contains('already') ||
            errorMessage.toLowerCase().contains('in use')) {
          _showAccountExistsDialog();
        } else if (errorMessage.toLowerCase().contains('too many')) {
          _showRateLimitDialog();
        } else {
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Sign up error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final success = await _signInWithGoogleMethod();

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BottomNavController(),
          ),
        );
      } else if (mounted) {
        final errorMessage =
            ref.read(authProvider).errorMessage ?? 'Google Sign-Up failed';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Google Sign-Up error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _signInWithGoogleMethod() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      return await authNotifier.signInWithGoogle();
    } catch (e) {
      debugPrint('Google sign-up error: $e');
      return false;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle,
                  color: AppTheme.accentGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Account Created!'),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. Please check your email to verify your account before logging in.',
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showAccountExistsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Account Exists'),
          ],
        ),
        content: const Text(
          'An account already exists for that email. Please login instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showRateLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Too Many Attempts'),
          ],
        ),
        content: const Text(
          'You have made too many registration attempts. Please wait a few minutes and try again, or use Google Sign-In instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _signUpWithGoogle(); // Try Google Sign-In
            },
            child: const Text('Try Google Sign-In'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGoogleIcon() {
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

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.professor:
        return 'Professor/Faculty';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Access papers, collaborate, and learn';
      case UserRole.professor:
        return 'Publish papers, mentor students';
      case UserRole.researcher:
        return 'Research, publish, and collaborate';
      case UserRole.admin:
        return 'Manage users and content';
      case UserRole.guest:
        return 'Browse public content';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.professor:
        return Icons.person_outline;
      case UserRole.researcher:
        return Icons.science_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.guest:
        return Icons.visibility_outlined;
    }
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
              AppTheme.primaryPurple.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          children: [
                            if (_currentStep == 0) ...[
                              _buildGoogleSignUpOption(),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                    child: Divider(color: AppTheme.lightGray)),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('OR',
                                        style: GoogleFonts.inter(
                                            color: AppTheme.mediumGray,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700))),
                                Expanded(
                                    child: Divider(color: AppTheme.lightGray))
                              ]),
                              const SizedBox(height: 14),
                            ],
                            _buildStepContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: AppTheme.darkSlate, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Create Account',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? AppTheme.primaryBlue
                  : AppTheme.lightGray,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGoogleSignUpOption() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signUpWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppTheme.lightGray.withOpacity(0.6)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: _buildGoogleIcon(),
        label: Text('Sign up with Google',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate)),
      ),
    );
  }

  Widget _buildStepContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.66),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: Colors.white.withOpacity(0.6), width: 1.0),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepTitle(),
                const SizedBox(height: 20),
                if (_currentStep == 0) _buildRoleSelectionStep(),
                if (_currentStep == 1) _buildBasicInfoStep(),
                if (_currentStep == 2) _buildProfessionalInfoStep(),
                const SizedBox(height: 20),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTitle() {
    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 0:
        title = 'Select Your Role';
        subtitle = 'Choose the role that best describes you';
        break;
      case 1:
        title = 'Basic Information';
        subtitle = 'Tell us about yourself';
        break;
      case 2:
        title = 'Professional Details';
        subtitle = 'Optional information to enhance your profile';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkSlate,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionStep() {
    final roles = [
      UserRole.student,
      UserRole.professor,
      UserRole.researcher,
    ];

    return Column(
      children: roles.map((role) => _buildRoleCard(role)).toList(),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final isSelected = _selectedRole == role;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.lightGray.withOpacity(0.4),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryPurple
                        ])
                      : null,
                  color:
                      isSelected ? null : AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRoleIcon(role),
                  color: isSelected ? Colors.white : AppTheme.mediumGray,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRoleLabel(role),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRoleDescription(role),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'John Doe',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'name@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'At least 6 characters',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppTheme.mediumGray,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppTheme.mediumGray,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _institutionController,
          label: 'Institution',
          hint: 'University or Organization (optional)',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _departmentController,
          label: 'Department',
          hint: 'Your department (optional)',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _designationController,
          label: 'Designation',
          hint: 'Your title or position (optional)',
          icon: Icons.work_outline,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.darkSlate),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppTheme.mediumGray, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppTheme.mediumGray),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppTheme.lightGray.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: ElevatedButton(
            onPressed: () {
              if (_currentStep < 2) {
                if (_formKey.currentState!.validate()) {
                  setState(() => _currentStep++);
                }
              } else {
                _signUp();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 10,
              shadowColor: AppTheme.primaryBlue.withOpacity(0.18),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentStep == 2 ? 'Create Account' : 'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
