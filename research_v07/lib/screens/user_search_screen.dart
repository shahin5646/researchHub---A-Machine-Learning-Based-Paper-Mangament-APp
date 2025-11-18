import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/realtime_social_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Instagram-style user search and discovery screen
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final RealtimeSocialService _realtimeService = RealtimeSocialService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Discover People',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // User List
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text(
          'Please sign in',
          style: GoogleFonts.inter(fontSize: 16),
        ),
      );
    }

    // Use search or show all users
    final stream = _searchQuery.isEmpty
        ? _realtimeService.getAllUsers(limit: 100)
        : _realtimeService.searchUsers(_searchQuery);

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];

        // Filter out current user
        final filteredUsers =
            users.where((doc) => doc.id != currentUser.id).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No users found'
                      : 'No results for "$_searchQuery"',
                  style: GoogleFonts.inter(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;

            final userId = userDoc.id;
            final name = userData['name'] ?? 'Unknown User';
            final email = userData['email'] ?? '';
            final followersCount = userData['followersCount'] ?? 0;
            final followingCount = userData['followingCount'] ?? 0;

            return _buildUserCard(
              userId: userId,
              name: name,
              email: email,
              followersCount: followersCount,
              followingCount: followingCount,
              currentUserId: currentUser.id,
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard({
    required String userId,
    required String name,
    required String email,
    required int followersCount,
    required int followingCount,
    required String currentUserId,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryBlue,
          child: Text(
            _getInitials(name),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$followersCount followers · $followingCount following',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: _buildFollowButton(userId, currentUserId),
      ),
    );
  }

  Widget _buildFollowButton(String targetUserId, String currentUserId) {
    return StreamBuilder<bool>(
      stream: _realtimeService.getFollowStatusStream(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      ),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return TextButton(
          onPressed: () {
            _realtimeService.toggleFollow(
              currentUserId: currentUserId,
              targetUserId: targetUserId,
            );
          },
          style: TextButton.styleFrom(
            backgroundColor:
                isFollowing ? Colors.grey.shade200 : AppTheme.primaryBlue,
            foregroundColor:
                isFollowing ? const Color(0xFF0F172A) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
