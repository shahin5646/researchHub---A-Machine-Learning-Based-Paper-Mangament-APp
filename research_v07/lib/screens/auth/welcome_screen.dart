import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_login_screen.dart';
import 'modern_signup_screen.dart';
import '../../theme/app_theme.dart';
import '../../navigation/bottom_nav_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryPurple,
              AppTheme.accentOrange.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildFloatingElements(),

            // Main content - Scrollable to prevent overflow
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        (isSmallScreen ? 32 : 48),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo and title section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(height: isSmallScreen ? 20 : 40),
                            _buildLogo(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 20 : 32),
                            _buildTitle(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildSubtitle(isSmallScreen),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 30 : 60),

                      // Buttons section
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            _buildPrimaryButton(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildSecondaryButton(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _buildSkipButton(),
                            SizedBox(height: isSmallScreen ? 20 : 32),
                            _buildFeatureHighlights(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating circles
            Positioned(
              top: 100 + (_floatingAnimation.value * 20),
              right: 30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 200 + (_floatingAnimation.value * -15),
              left: 50,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentPink.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + (_floatingAnimation.value * 25),
              right: 80,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 150 + (_floatingAnimation.value * -10),
              left: 30,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    final logoSize = isSmallScreen ? 100.0 : 120.0;
    final iconSize = isSmallScreen ? 50.0 : 60.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.school,
        size: iconSize,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Research Hub',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          width: 80,
          height: 4,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Discover • Learn • Collaborate\nYour gateway to cutting-edge research',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 13 : 16,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.9),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToLogin(),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Get Started',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSignUp(),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Create Account',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => _navigateToSkip(),
      child: Text(
        'Skip to Dashboard',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.8),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
            child:
                _buildFeatureItem(Icons.search, 'Smart Search', isSmallScreen)),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Flexible(
            child:
                _buildFeatureItem(Icons.analytics, 'Analytics', isSmallScreen)),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Flexible(
            child: _buildFeatureItem(
                Icons.recommend, 'AI Powered', isSmallScreen)),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, bool isSmallScreen) {
    final containerSize = isSmallScreen ? 40.0 : 48.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return Column(
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModernLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModernSignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToSkip() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BottomNavController(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
