import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../view/faculty_list_screen.dart';
import '../screens/settings_screen.dart'; // Updated to use new 2025 design
import '../screens/help_support.dart';
import '../screens/category_screen.dart';
import '../screens/modern_research_projects_screen.dart';
import '../providers/theme_provider.dart';
import '../screens/all_papers_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/trending/trending_screen.dart';
import '../screens/recommendations/recommendations_screen.dart';
import '../screens/auth/welcome_screen.dart';

class AppDrawer extends StatefulWidget {
  final Function(bool)? onThemeToggle;

  const AppDrawer({
    super.key,
    this.onThemeToggle,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _activeRoute = 'Home';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF0F1419) : Colors.white,
        elevation: 8,
        child: SafeArea(
          bottom: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildModernProfileHeader(context, isDarkMode),
                          Expanded(
                            child: _buildNavigationItems(
                              context,
                              isDarkMode,
                              themeProvider,
                              _activeRoute,
                            ),
                          ),
                          _buildBottomSection(
                              context, isDarkMode, themeProvider),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF3B82F6),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.2),
            width: 1, // 2025 Standard: 1px flat border
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar - Minimal design
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Info - Minimal spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Shahin",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: -0.5, // 2025 Standard: Negative spacing
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "shahin5646@gmail.com",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Close Button - Minimal design
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Manage Account Button - 2025 Minimal Design
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to Profile tab by going back to BottomNavController
                // The BottomNavController is the root, so we pop until we reach it
                // Then we can use a callback to switch to profile tab
                Future.delayed(const Duration(milliseconds: 250), () {
                  // Navigate to BottomNavController and pass profile index
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                    arguments: 4, // Profile tab index
                  );
                });
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Manage Account',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context, bool isDarkMode,
      ThemeProvider themeProvider, String currentRoute) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Explore', isDarkMode),
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            title: 'Home',
            isActive: currentRoute == 'Home',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Home');
              Navigator.pop(context);
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            title: 'Categories',
            isActive: currentRoute == 'Categories',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Categories');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            title: 'Faculty Members',
            isActive: currentRoute == 'Faculty',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Faculty');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FacultyListScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books_rounded,
            title: 'ALL Research Papers',
            isActive: currentRoute == 'Papers',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Papers');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AllPapersScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.school_outlined,
            activeIcon: Icons.school_rounded,
            title: 'Research Projects',
            isActive: currentRoute == 'Projects',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Projects');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ModernResearchProjectsScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics_rounded,
            title: 'Analytics',
            isActive: currentRoute == 'Analytics',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Analytics');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.trending_up_outlined,
            activeIcon: Icons.trending_up_rounded,
            title: 'Trending',
            isActive: currentRoute == 'Trending',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Trending');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrendingScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.recommend_outlined,
            activeIcon: Icons.recommend_rounded,
            title: 'Recommendations',
            isActive: currentRoute == 'Recommendations',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Recommendations');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecommendationsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSectionTitle('Settings', isDarkMode),
          _buildNavItem(
            context: context,
            icon: Icons.support_agent_outlined,
            activeIcon: Icons.support_agent_rounded,
            title: 'Support',
            isActive: currentRoute == 'Support',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Support');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            title: 'Settings',
            isActive: currentRoute == 'Settings',
            isDarkMode: isDarkMode,
            onTap: () {
              setState(() => _activeRoute = 'Settings');
              Navigator.pop(context);
              // Use root navigator to push Settings above the BottomNavController
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isActive,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDarkMode
                      ? const Color(0xFF3B82F6).withOpacity(0.15)
                      : const Color(0xFF3B82F6).withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox(width: 15),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    size: 20,
                    color: isActive
                        ? const Color(0xFF3B82F6)
                        : (isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? (isDarkMode
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF3B82F6))
                          : (isDarkMode
                              ? Colors.white
                              : const Color(0xFF1F2937)),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: const Color(0xFF3B82F6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sign Out", style: GoogleFonts.poppins()),
        content: Text(
          "Are you sure you want to sign out?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear user session (example: Hive box, SharedPreferences, etc.)
              // var box = await Hive.openBox('session');
              // await box.clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("Sign Out", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
      BuildContext context, bool isDarkMode, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF374151) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 18,
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        themeProvider.isDarkMode
                            ? 'Dark theme active'
                            : 'Light theme active',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    themeProvider.toggleTheme();
                    widget.onThemeToggle?.call(!themeProvider.isDarkMode);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 28,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: themeProvider.isDarkMode
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 14,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.pop(context);
                _showSignOutDialog(context);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
