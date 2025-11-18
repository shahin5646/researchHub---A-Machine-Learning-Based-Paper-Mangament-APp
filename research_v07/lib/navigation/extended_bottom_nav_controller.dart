import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../view/main_dashboard_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/explore_nav.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/social/social_feed_screen.dart';
import '../screens/linkedin_style_papers_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ExtendedBottomNavController extends StatefulWidget {
  const ExtendedBottomNavController({super.key});

  @override
  State<ExtendedBottomNavController> createState() =>
      _ExtendedBottomNavControllerState();
}

class _ExtendedBottomNavControllerState
    extends State<ExtendedBottomNavController> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MainDashboardScreen(),
    const ExploreScreen(),
    const SocialFeedScreen(), // Original social feed
    const LinkedInStylePapersScreen(), // New LinkedIn-style feed
    const AnalyticsScreen(),
    const UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceColor(context),
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade500
                : Colors.grey.shade600,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            iconSize: 22,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined, size: 22),
                activeIcon: const Icon(Icons.home, size: 24),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search_outlined, size: 22),
                activeIcon: const Icon(Icons.search, size: 24),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.forum_outlined, size: 22),
                activeIcon: const Icon(Icons.forum, size: 24),
                label: 'Social',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_center_outlined, size: 22),
                activeIcon: const Icon(Icons.business_center, size: 24),
                label: 'Network',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.analytics_outlined, size: 22),
                activeIcon: const Icon(Icons.analytics, size: 24),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline, size: 22),
                activeIcon: const Icon(Icons.person, size: 24),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
