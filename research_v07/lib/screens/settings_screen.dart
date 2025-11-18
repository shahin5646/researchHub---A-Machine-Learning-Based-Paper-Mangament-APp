import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/auth/welcome_screen.dart';
import './paper_migration_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color darkSlate = const Color(0xFF222B45);
  final Color mediumGray = const Color(0xFF7B8794);
  final Color lightGray = const Color(0xFFF5F6FA);
  final Color borderGray = const Color(0xFFE0E3EA);
  final Color softRed = const Color(0xFFE57373);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68), // 2025 Standard: 68px
        child: SafeArea(
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: borderGray,
                  width: 1, // 2025 Standard: 1px flat border
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: darkSlate,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: darkSlate,
                    letterSpacing: -0.5, // 2025 Standard: Negative spacing
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // User Profile Section
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: borderGray,
                child: Icon(Icons.person_rounded, color: primaryBlue, size: 32),
              ),
              title: Text('Shahin',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkSlate)),
              subtitle: Text('Student',
                  style: GoogleFonts.inter(fontSize: 14, color: mediumGray)),
              trailing: IconButton(
                icon: Icon(Icons.edit_rounded, color: primaryBlue, size: 24),
                onPressed: () {},
                tooltip: 'Edit Profile',
              ),
            ),
          ),
          // Display & Accessibility
          _sectionHeader('Display & Accessibility'),
          _settingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            subtext: 'Enable dark theme for low-light environments',
            trailing: Switch(
                value: false, onChanged: (v) {}, activeColor: primaryBlue),
          ),
          _settingsTile(
            icon: Icons.text_fields_rounded,
            label: 'Text Size',
            subtext: 'Adjust text size for better readability',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          _settingsTile(
            icon: Icons.language_rounded,
            label: 'Language',
            subtext: 'Select your preferred language',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          const SizedBox(height: 18),
          // Research Preferences
          _sectionHeader('Research Preferences'),
          _settingsTile(
            icon: Icons.notifications_active_rounded,
            label: 'Paper Notifications',
            subtext: 'Get notified about new research papers',
            trailing: Switch(
                value: true, onChanged: (v) {}, activeColor: primaryBlue),
          ),
          _settingsTile(
            icon: Icons.format_quote_rounded,
            label: 'Citation Format',
            subtext: 'Choose your preferred citation style',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          _settingsTile(
            icon: Icons.folder_rounded,
            label: 'Download Location',
            subtext: 'Manage where files are saved',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          const SizedBox(height: 18),
          // Account & Security
          _sectionHeader('Account & Security'),
          _settingsTile(
            icon: Icons.person_rounded,
            label: 'Profile Settings',
            subtext: 'Edit your profile and account info',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          _settingsTile(
            icon: Icons.cloud_upload_rounded,
            label: 'Migrate to Cloud',
            subtext: 'Move your papers to Firebase cloud storage',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaperMigrationScreen(),
                ),
              );
            },
          ),
          _settingsTile(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy',
            subtext: 'Manage privacy settings',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          const SizedBox(height: 18),
          // Support & About
          _sectionHeader('Support & About'),
          _settingsTile(
            icon: Icons.help_center_rounded,
            label: 'Help Center',
            subtext: 'Get help and support',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          _settingsTile(
            icon: Icons.info_rounded,
            label: 'About ResearchHub',
            subtext: 'Learn more about the app',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          _settingsTile(
            icon: Icons.share_rounded,
            label: 'Share App',
            subtext: 'Invite friends to ResearchHub',
            trailing: Icon(Icons.chevron_right_rounded, color: borderGray),
          ),
          const SizedBox(height: 32),
          // Sign Out Button
          Center(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(Icons.logout_rounded, color: Colors.white),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('Sign Out',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: softRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: softRed),
                          const SizedBox(width: 8),
                          Text('Sign Out',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Text('Are you sure you want to sign out?',
                          style: GoogleFonts.inter()),
                      actions: [
                        TextButton(
                          child: Text('Cancel', style: GoogleFonts.inter()),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: softRed,
                              foregroundColor: Colors.white),
                          child: Text('Sign Out', style: GoogleFonts.inter()),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            // Clear user session (example: Hive box, SharedPreferences, etc.)
                            // If using Hive:
                            // var box = await Hive.openBox('session');
                            // await box.clear();
                            // Navigate to WelcomeScreen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const WelcomeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      // No bottom navigation bar - Settings is a secondary screen
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: darkSlate,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    String? subtext,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryBlue, size: 26),
        title: Text(label,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600, color: darkSlate)),
        subtitle: subtext != null
            ? Text(subtext,
                style: GoogleFonts.inter(fontSize: 13, color: mediumGray))
            : null,
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: onTap ?? () {},
      ),
    );
  }
}
