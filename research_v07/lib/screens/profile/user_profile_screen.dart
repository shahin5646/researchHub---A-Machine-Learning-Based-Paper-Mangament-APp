import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart'; // Updated to use user.dart for UserRole
import '../../services/role_access_service.dart';
import '../papers/my_papers_screen.dart';
import '../saved_papers_screen.dart';
import '../../main.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _institutionController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  int _papersCount = 0;
  int _bookmarksCount = 0;
  int _followingCount = 0;
  int _followersCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app resumes
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = ref.read(authProvider).currentUser;
    if (user != null) {
      debugPrint('📊 Loading profile data for user: ${user.id}');
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _departmentController.text = user.department ?? '';
      _institutionController.text = user.institution ?? '';
      _bioController.text = user.bio ?? '';
      _interestsController.text = user.interests.join(', ');

      // Fetch real-time papers count from Firestore
      try {
        final papersSnapshot = await FirebaseFirestore.instance
            .collection('papers')
            .where('authorId', isEqualTo: user.id)
            .get();
        debugPrint('📄 Papers count: ${papersSnapshot.docs.length}');

        final bookmarksSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('bookmarks')
            .get();
        debugPrint('🔖 Bookmarks count: ${bookmarksSnapshot.docs.length}');

        // Fetch or create user document in Firestore
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.id);

        final userDoc = await userDocRef.get();

        // If user document doesn't exist, create it with current data
        if (!userDoc.exists) {
          debugPrint('⚠️ User document not found in Firestore, creating...');
          await userDocRef.set({
            'id': user.id,
            'displayName': user.displayName,
            'email': user.email,
            'following': user.following,
            'followers': user.followers,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint(
              '✅ Created user document with ${user.following.length} following, ${user.followers.length} followers');
        }

        // Get the latest data
        final refreshedUserDoc = await userDocRef.get();

        if (mounted) {
          setState(() {
            _papersCount = papersSnapshot.docs.length;
            _bookmarksCount = bookmarksSnapshot.docs.length;

            // Get following and followers from Firestore user document
            final userData = refreshedUserDoc.data();
            if (userData != null) {
              _followingCount =
                  (userData['following'] as List<dynamic>?)?.length ?? 0;
              _followersCount =
                  (userData['followers'] as List<dynamic>?)?.length ?? 0;
              debugPrint(
                  '✅ Loaded from Firestore: $_followingCount following, $_followersCount followers');
            } else {
              // Fallback to local user data if Firestore data is not available
              _followingCount = user.following.length;
              _followersCount = user.followers.length;
              debugPrint(
                  '⚠️ Using local data: $_followingCount following, $_followersCount followers');
            }
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading user stats: $e');
        // Fallback to local user data on error
        if (mounted) {
          setState(() {
            _followingCount = user.following.length;
            _followersCount = user.followers.length;
            debugPrint(
                '⚠️ Error fallback: $_followingCount following, $_followersCount followers');
          });
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _institutionController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(authProvider).currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Parse interests
      final interests = _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Create update map
      final updates = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'department': _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        'institution': _institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        'interests': interests,
      };

      // Update user in auth provider
      final auth = ref.read(authProvider.notifier);
      final success = await auth.updateProfile(updates);

      if (success && mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final user = ref.watch(authProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    // Reload data when user changes (e.g., after following someone)
    ref.listen(authProvider, (previous, next) {
      if (previous?.currentUser?.id != next.currentUser?.id ||
          previous?.currentUser?.following.length !=
              next.currentUser?.following.length ||
          previous?.currentUser?.followers.length !=
              next.currentUser?.followers.length) {
        _loadUserData();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryBlue),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                _loadUserData(); // Reset form
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryPurple
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleDisplayName(user.role),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      _buildProfileField(
                        label: 'Full Name',
                        controller: _nameController,
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email (read-only)
                      _buildProfileField(
                        label: 'Email',
                        controller: _emailController,
                        enabled: false,
                      ),

                      const SizedBox(height: 16),

                      // Department
                      _buildProfileField(
                        label: 'Department',
                        controller: _departmentController,
                        enabled: _isEditing,
                        hint: 'e.g., Computer Science',
                      ),

                      const SizedBox(height: 16),

                      // Institution
                      _buildProfileField(
                        label: 'Institution',
                        controller: _institutionController,
                        enabled: _isEditing,
                        hint: 'e.g., University Name',
                      ),

                      const SizedBox(height: 16),

                      // Bio
                      _buildProfileField(
                        label: 'Bio',
                        controller: _bioController,
                        enabled: _isEditing,
                        maxLines: 3,
                        hint: 'Tell us about yourself...',
                      ),

                      const SizedBox(height: 16),

                      // Research Interests
                      _buildProfileField(
                        label: 'Research Interests',
                        controller: _interestsController,
                        enabled: _isEditing,
                        hint: 'Separate interests with commas',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Statistics',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Papers Uploaded',
                              _papersCount.toString(),
                              Icons.upload_file_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Bookmarks',
                              _bookmarksCount.toString(),
                              Icons.bookmark_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Following',
                              _followingCount.toString(),
                              Icons.people_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Followers',
                              _followersCount.toString(),
                              Icons.person_add_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Saved Papers - Available to all users
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Saved Papers',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        subtitle: Text(
                          'View your bookmarked research papers',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPapersScreen(),
                            ),
                          );
                        },
                      ),
                      if (RoleBasedAccessControl.canUploadPapers(
                          user.role)) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.primaryPurple
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.article_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'My Papers',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          subtitle: Text(
                            'Manage your uploaded research papers',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyPapersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(
            color: enabled ? AppTheme.darkSlate : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkSlate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.professor:
        return 'Professor';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.guest:
        return 'Guest';
    }
  }
}
