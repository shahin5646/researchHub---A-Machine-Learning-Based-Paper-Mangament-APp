import 'package:flutter/material.dart';
import '../../services/firebase_admin_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/app_user.dart';
import '../../models/firebase_paper.dart';
import '../../models/user.dart';

/// Admin dashboard screen for managing users and content
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAdminService _adminService = FirebaseAdminService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  late TabController _tabController;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAdmin() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showError('Not authenticated');
      Navigator.pop(context);
      return;
    }

    _currentAdminId = currentUser.uid;

    // Check admin privileges
    final isAdmin = await _adminService.isAdmin(currentUser.uid);
    if (!isAdmin) {
      _showError('You do not have admin privileges');
      Navigator.pop(context);
      return;
    }

    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getSystemStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load statistics: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.article), text: 'Papers'),
            Tab(icon: Icon(Icons.flag), text: 'Flagged'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildPapersTab(),
                _buildFlaggedTab(),
              ],
            ),
    );
  }

  // Overview Tab - System Statistics
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Total Users',
              _statistics['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Papers',
              _statistics['totalPapers']?.toString() ?? '0',
              Icons.article,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Pending Papers',
              _statistics['pendingPapers']?.toString() ?? '0',
              Icons.pending,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'View Logs',
                  Icons.list,
                  () => _viewAdminLogs(),
                ),
                _buildActionButton(
                  'Refresh Stats',
                  Icons.refresh,
                  () => _loadStatistics(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  // Users Tab
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Users',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (query) => _searchUsers(query),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AppUser>>(
            future: _adminService.getAllUsers(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserTile(user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(AppUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.displayName[0].toUpperCase()),
        ),
        title: Text(user.displayName),
        subtitle: Text(
            '${user.email}\nRole: ${user.role.toString().split('.').last}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'role', child: Text('Change Role')),
            const PopupMenuItem(value: 'ban', child: Text('Ban User')),
            const PopupMenuItem(value: 'papers', child: Text('View Papers')),
            const PopupMenuItem(value: 'logs', child: Text('View Activity')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserAction(String action, AppUser user) async {
    switch (action) {
      case 'role':
        await _changeUserRole(user);
        break;
      case 'ban':
        await _banUser(user);
        break;
      case 'papers':
        await _viewUserPapers(user.id);
        break;
      case 'logs':
        await _viewUserLogs(user.id);
        break;
    }
  }

  Future<void> _changeUserRole(AppUser user) async {
    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.toString().split('.').last),
              value: role,
              groupValue: user.role,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        await _adminService.updateUserRole(user.id, newRole);
        await _adminService.logAdminAction(
          adminUserId: _currentAdminId!,
          action: 'change_role',
          targetUserId: user.id,
          metadata: {
            'oldRole': user.role.toString(),
            'newRole': newRole.toString()
          },
        );
        _showSuccess('User role updated');
        setState(() {}); // Refresh
      } catch (e) {
        _showError('Failed to update role: $e');
      }
    }
  }

  Future<void> _banUser(AppUser user) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ban ${user.displayName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ban'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.banUser(user.id, reason: reasonController.text);
        await _adminService.logAdminAction(
          adminUserId: _currentAdminId!,
          action: 'ban_user',
          targetUserId: user.id,
          metadata: {'reason': reasonController.text},
        );
        _showSuccess('User banned');
        setState(() {});
      } catch (e) {
        _showError('Failed to ban user: $e');
      }
    }

    reasonController.dispose();
  }

  Future<void> _searchUsers(String query) async {
    try {
      final users = await _adminService.searchUsers(query);
      // Show results in a dialog or navigate to results screen
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Search Results (${users.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) => _buildUserTile(users[index]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Search failed: $e');
    }
  }

  // Papers Tab - Content Moderation
  Widget _buildPapersTab() {
    return FutureBuilder<List<FirebasePaper>>(
      future: _adminService.getPendingPapers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final papers = snapshot.data ?? [];

        if (papers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending papers to review'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: papers.length,
          itemBuilder: (context, index) {
            final paper = papers[index];
            return _buildPaperTile(paper);
          },
        );
      },
    );
  }

  Widget _buildPaperTile(FirebasePaper paper) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.article),
        title: Text(paper.title),
        subtitle: Text(
            'By: ${paper.authors.join(", ")}\\nCategory: ${paper.category}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Abstract:',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(paper.abstract ?? 'No abstract available'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _approvePaper(paper),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _rejectPaper(paper),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _deletePaper(paper),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePaper(FirebasePaper paper) async {
    try {
      await _adminService.approvePaper(paper.id);
      await _adminService.logAdminAction(
        adminUserId: _currentAdminId!,
        action: 'approve_paper',
        targetPaperId: paper.id,
      );
      _showSuccess('Paper approved');
      setState(() {});
    } catch (e) {
      _showError('Failed to approve paper: $e');
    }
  }

  Future<void> _rejectPaper(FirebasePaper paper) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Paper'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _adminService.rejectPaper(paper.id, reason: reason);
        await _adminService.logAdminAction(
          adminUserId: _currentAdminId!,
          action: 'reject_paper',
          targetPaperId: paper.id,
          metadata: {'reason': reason},
        );
        _showSuccess('Paper rejected');
        setState(() {});
      } catch (e) {
        _showError('Failed to reject paper: $e');
      }
    }

    reasonController.dispose();
  }

  Future<void> _deletePaper(FirebasePaper paper) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Paper'),
        content: Text('Permanently delete "${paper.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deletePaper(paper.id, _currentAdminId!);
        _showSuccess('Paper deleted');
        setState(() {});
      } catch (e) {
        _showError('Failed to delete paper: $e');
      }
    }
  }

  // Flagged Content Tab
  Widget _buildFlaggedTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminService.getFlaggedContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final flaggedItems = snapshot.data ?? [];

        if (flaggedItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No flagged content'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: flaggedItems.length,
          itemBuilder: (context, index) {
            final item = flaggedItems[index];
            return _buildFlaggedItemTile(item);
          },
        );
      },
    );
  }

  Widget _buildFlaggedItemTile(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.flag, color: Colors.red),
        title: Text(item['reason'] ?? 'No reason'),
        subtitle: Text('Flagged by: ${item['reportedBy'] ?? 'Unknown'}'),
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () => _resolveFlagged(item),
        ),
      ),
    );
  }

  Future<void> _resolveFlagged(Map<String, dynamic> item) async {
    final resolutionController = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Flagged Content'),
        content: TextField(
          controller: resolutionController,
          decoration: const InputDecoration(
            labelText: 'Resolution Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, resolutionController.text),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (resolution != null) {
      try {
        await _adminService.resolveFlaggedContent(
          item['id'],
          resolution: resolution,
          adminUserId: _currentAdminId!,
        );
        _showSuccess('Flagged content resolved');
        setState(() {});
      } catch (e) {
        _showError('Failed to resolve: $e');
      }
    }

    resolutionController.dispose();
  }

  Future<void> _viewUserPapers(String userId) async {
    try {
      final papers = await _adminService.getUserPapers(userId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('User Papers (${papers.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: papers.length,
              itemBuilder: (context, index) {
                final paper = papers[index];
                return ListTile(
                  title: Text(paper.title),
                  subtitle: Text(paper.category),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to load papers: $e');
    }
  }

  Future<void> _viewUserLogs(String userId) async {
    try {
      final logs = await _adminService.getUserActivityLogs(userId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Activity Logs (${logs.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log['action'] ?? 'Unknown'),
                  subtitle: Text(log['timestamp']?.toString() ?? ''),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to load logs: $e');
    }
  }

  Future<void> _viewAdminLogs() async {
    try {
      final logs = await _adminService.getAdminLogs(limit: 100);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Admin Logs (${logs.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log['action'] ?? 'Unknown'),
                  subtitle: Text(
                    'Admin: ${log['adminUserId']}\n${log['timestamp']?.toString() ?? ''}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Failed to load admin logs: $e');
    }
  }
}
