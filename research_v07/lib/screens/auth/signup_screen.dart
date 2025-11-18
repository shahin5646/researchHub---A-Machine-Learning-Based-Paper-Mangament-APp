import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../models/user.dart'; // Updated to use user.dart for UserRole

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.student;

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color darkSlate = const Color(0xFF222B45);
  final Color mediumGray = const Color(0xFF7B8794);
  final Color lightGray = const Color(0xFFF5F6FA);
  final Color borderGray = const Color(0xFFE0E3EA);
  final Color offWhite = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo area replaced with ResearchHub text
                  Center(
                    child: Text(
                      'ResearchHub',
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: primaryBlue.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text('Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkSlate,
                      )),
                  const SizedBox(height: 8),
                  Text('Sign up to get started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: mediumGray,
                      )),
                  const SizedBox(height: 32),
                  // First/Last Name Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 400;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                          if (isWide) const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: mediumGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: mediumGray,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Role Selection
                  _buildRoleSelector(),
                  const SizedBox(height: 32),
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final firstName = _firstNameController.text.trim();
                        final lastName = _lastNameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;

                        if (firstName.isEmpty ||
                            lastName.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty ||
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Please fill all required fields.')),
                          );
                          return;
                        }
                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Passwords do not match.')),
                          );
                          return;
                        }
                        try {
                          final auth = ref.read(authProvider.notifier);
                          final success = await auth.register(
                            name: '$firstName $lastName',
                            email: email,
                            password: password,
                            role: _selectedRole,
                          );

                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Registration successful! Please login with your new account.')),
                              );
                              Navigator.pop(context); // Go back to login screen
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Email already exists!')),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Registration error: $e')),
                            );
                          }
                        }
                      },
                      child: Text('Sign Up',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Already have account? Sign in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: mediumGray,
                          )),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Sign in',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: darkSlate),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, color: mediumGray),
        floatingLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryBlue),
        prefixIcon: Icon(icon, color: mediumGray),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: lightGray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Role',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkSlate,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderGray),
          ),
          child: Column(
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                value: role,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
                title: Text(
                  _getRoleDisplayName(role),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: darkSlate,
                  ),
                ),
                subtitle: Text(
                  _getRoleDescription(role),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: mediumGray,
                  ),
                ),
                activeColor: primaryBlue,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.professor:
        return 'Faculty/Professor';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Undergraduate or graduate student';
      case UserRole.researcher:
        return 'Independent researcher or research associate';
      case UserRole.professor:
        return 'Professor, lecturer, or academic faculty';
      case UserRole.admin:
        return 'System administrator or moderator';
      case UserRole.guest:
        return 'Visitor with limited access';
    }
  }
}
