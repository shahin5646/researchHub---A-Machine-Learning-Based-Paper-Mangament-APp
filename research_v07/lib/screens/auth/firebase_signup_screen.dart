import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../navigation/bottom_nav_controller.dart';

class FirebaseSignUpScreen extends ConsumerStatefulWidget {
  const FirebaseSignUpScreen({super.key});

  @override
  ConsumerState<FirebaseSignUpScreen> createState() =>
      _FirebaseSignUpScreenState();
}

class _FirebaseSignUpScreenState extends ConsumerState<FirebaseSignUpScreen> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _institutionController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
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
        _showErrorSnackBar(errorMessage);
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
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Account Created!'),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. Please check your email to verify your account before logging in.',
        ),
        actions: [
          FilledButton(
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.g_mobiledata_rounded,
        size: 24,
        color: Colors.blue,
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      // Step 1: Basic Info
      Step(
        title: const Text('Basic Info'),
        content: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter your full name',
                prefixIcon:
                    Icon(Icons.person_outline, color: AppTheme.primaryBlue),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email *',
                hintText: 'Enter your email',
                prefixIcon:
                    Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      // Step 2: Password
      Step(
        title: const Text('Security'),
        content: Column(
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Enter your password',
                prefixIcon:
                    Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.mediumGray,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Re-enter your password',
                prefixIcon:
                    Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.mediumGray,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
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
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      // Step 3: Professional Info (Optional)
      Step(
        title: const Text('Professional'),
        content: Column(
          children: [
            TextFormField(
              controller: _institutionController,
              decoration: InputDecoration(
                labelText: 'Institution',
                hintText: 'Enter your institution (optional)',
                prefixIcon:
                    Icon(Icons.school_outlined, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _departmentController,
              decoration: InputDecoration(
                labelText: 'Department',
                hintText: 'Enter your department (optional)',
                prefixIcon:
                    Icon(Icons.business_outlined, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: InputDecoration(
                labelText: 'Designation',
                hintText: 'e.g., Professor, Researcher (optional)',
                prefixIcon:
                    Icon(Icons.work_outline, color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Google Sign-Up Option at Top
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signUpWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: AppTheme.mediumGray.withOpacity(0.3),
                                  width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _buildGoogleIcon(),
                            label: Text(
                              'Sign up with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: AppTheme.mediumGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Stepper(
                      type: StepperType.horizontal,
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_currentStep < 2) {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _currentStep++);
                          }
                        } else {
                          _signUp();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      onStepTapped: (step) {
                        if (step < _currentStep ||
                            _formKey.currentState!.validate()) {
                          setState(() => _currentStep = step);
                        }
                      },
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              FilledButton(
                                onPressed: details.onStepContinue,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                ),
                                child: Text(
                                    _currentStep == 2 ? 'Sign Up' : 'Continue'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: details.onStepCancel,
                                child:
                                    Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                              ),
                            ],
                          ),
                        );
                      },
                      steps: _getSteps(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
