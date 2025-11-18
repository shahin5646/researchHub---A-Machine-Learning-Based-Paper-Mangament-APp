import 'package:flutter/material.dart';
import '../widgets/linkedin_style_paper_card.dart';
import '../models/paper_models.dart';
import '../models/user_models.dart';
import '../theme/app_theme.dart';

class LinkedInStyleDemo extends StatelessWidget {
  const LinkedInStyleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('LinkedIn-Style Research Feed'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildDemoPaper(),
          const SizedBox(height: 8),
          _buildDemoPaper2(),
        ],
      ),
    );
  }

  Widget _buildDemoPaper() {
    final paper = ResearchPaper(
      id: 'demo1',
      title: 'Machine Learning Applications in Healthcare',
      authors: ['Dr. Sarah Johnson'],
      abstract:
          'This research explores the implementation of ML algorithms in medical diagnosis.',
      publishedDate: DateTime.now().subtract(const Duration(days: 3)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
      uploadedBy: 'user1',
      filePath: 'assets/papers/demo.pdf',
      category: 'Computer Science',
      journal: 'Healthcare AI Journal',
      views: 156,
      downloads: 42,
      description: 'Excited to share our breakthrough findings in medical AI!',
      comments: [],
      reactions: {},
      tags: ['AI', 'Healthcare', 'Machine Learning'],
    );

    final author = User(
      id: 'user1',
      name: 'Dr. Sarah Johnson',
      email: 'sarah@university.edu',
      role: UserRole.faculty,
      department: 'Computer Science',
      affiliation: 'MIT',
      profileImageUrl: 'https://via.placeholder.com/150',
      preferences: UserPreferences(
        theme: 'light',
        language: 'en',
        emailNotifications: true,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastLoginAt: DateTime.now(),
    );

    return LinkedInStylePaperCard(
      paper: paper,
      author: author,
    );
  }

  Widget _buildDemoPaper2() {
    final paper = ResearchPaper(
      id: 'demo2',
      title: 'Quantum Computing Breakthrough in Cryptography',
      authors: ['Prof. Michael Chen'],
      abstract:
          'Revolutionary advances in quantum-resistant encryption methods.',
      publishedDate: DateTime.now().subtract(const Duration(days: 7)),
      uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
      uploadedBy: 'user2',
      filePath: 'assets/papers/quantum.pdf',
      category: 'Physics',
      journal: 'Quantum Research Today',
      views: 298,
      downloads: 89,
      description: 'The future of digital security is quantum-resistant!',
      comments: [],
      reactions: {},
      tags: ['Quantum Computing', 'Cryptography', 'Security'],
    );

    final author = User(
      id: 'user2',
      name: 'Prof. Michael Chen',
      email: 'chen@stanford.edu',
      role: UserRole.faculty,
      department: 'Physics',
      affiliation: 'Stanford University',
      profileImageUrl: 'https://via.placeholder.com/150',
      preferences: UserPreferences(
        theme: 'light',
        language: 'en',
        emailNotifications: true,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 800)),
      lastLoginAt: DateTime.now(),
    );

    return LinkedInStylePaperCard(
      paper: paper,
      author: author,
    );
  }
}
