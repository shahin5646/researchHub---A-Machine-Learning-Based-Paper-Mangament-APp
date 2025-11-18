import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../view/main_dashboard_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/explore_nav.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/linkedin_style_papers_screen.dart';
import '../screens/messaging/conversations_list_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavController extends StatefulWidget {
  final int initialIndex;

  const BottomNavController({super.key, this.initialIndex = 0});

  @override
  State<BottomNavController> createState() => _BottomNavControllerState();
}

class _BottomNavControllerState extends State<BottomNavController> {
  late int _selectedIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      MainDashboardScreen(onNavigateToTab: _onItemTapped),
      const LinkedInStylePapersScreen(),
      const ExploreScreen(),
      const ConversationsListScreen(),
      const AnalyticsScreen(),
      const UserProfileScreen(),
    ];
  }

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
      // FAB is now provided by each screen, not globally here
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom:
            true, // Remove MediaQuery padding at bottom to avoid double padding
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
                icon: const Icon(Icons.feed_outlined, size: 22),
                activeIcon: const Icon(Icons.feed, size: 24),
                label: 'Feed',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search_outlined, size: 22),
                activeIcon: const Icon(Icons.search, size: 24),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.message_outlined, size: 22),
                activeIcon: const Icon(Icons.message, size: 24),
                label: 'Messages',
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
