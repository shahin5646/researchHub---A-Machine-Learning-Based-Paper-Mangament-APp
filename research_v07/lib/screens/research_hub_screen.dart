import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/social/social_feed_screen.dart';
import '../screens/linkedin_style_papers_screen.dart';
import '../theme/app_theme.dart';

class ResearchHubScreen extends StatefulWidget {
  const ResearchHubScreen({super.key});

  @override
  State<ResearchHubScreen> createState() => _ResearchHubScreenState();
}

class _ResearchHubScreenState extends State<ResearchHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkSlate,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Research Hub',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppTheme.primaryBlue,
          labelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.business_center_outlined),
              text: 'Professional',
            ),
            Tab(
              icon: const Icon(Icons.forum_outlined),
              text: 'Social',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const LinkedInStylePapersScreen(),
          const SocialFeedScreen(),
        ],
      ),
    );
  }
}
