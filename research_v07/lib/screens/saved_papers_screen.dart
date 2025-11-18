import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'unified_pdf_viewer.dart';

class SavedPapersScreen extends ConsumerStatefulWidget {
  const SavedPapersScreen({super.key});

  @override
  ConsumerState<SavedPapersScreen> createState() => _SavedPapersScreenState();
}

class _SavedPapersScreenState extends ConsumerState<SavedPapersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedPapers = [];

  @override
  void initState() {
    super.initState();
    debugPrint('🔖 SavedPapersScreen initialized');
    _loadSavedPapers();
  }

  Future<void> _loadSavedPapers() async {
    setState(() => _isLoading = true);

    final user = ref.read(authProvider).currentUser;
    debugPrint('🔖 Loading saved papers for user: ${user?.id}');
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      _savedPapers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'paperId': data['paperId'] ?? '',
          'title': data['paperTitle'] ?? 'Unknown Title',
          'author': data['paperAuthor'] ?? 'Unknown Author',
          'year': data['year'] ?? '',
          'category': data['category'] ?? '',
          'path': data['paperId'] ?? '', // paperId is the path
        };
      }).toList();

      debugPrint(
          '🔖 SavedPapersScreen - Loaded ${_savedPapers.length} saved papers from Firestore');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading saved papers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load saved papers'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSavedPaper(String paperId) async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('bookmarks')
          .doc(paperId)
          .delete();

      setState(() {
        _savedPapers.removeWhere((paper) => paper['paperId'] == paperId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from saved papers'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error removing saved paper: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove bookmark'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Saved Papers',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryBlue),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _savedPapers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSavedPapers,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _savedPapers.length,
                    itemBuilder: (context, index) {
                      final paper = _savedPapers[index];
                      return _buildPaperCard(paper);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'No Saved Papers',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Papers you save will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.article_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          paper['title'] ?? 'Unknown Title',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    paper['author'] ?? 'Unknown Author',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (paper['year'] != null &&
                paper['year'].toString().isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  SizedBox(width: 4),
                  Text(
                    paper['year'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.bookmark, color: Colors.red),
          onPressed: () => _removeSavedPaper(paper['paperId'] ?? ''),
          tooltip: 'Remove from saved',
        ),
        onTap: () {
          final String pdfPath = paper['path'] ?? paper['paperId'] ?? '';
          if (pdfPath.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnifiedPdfViewer(
                  pdfPath: pdfPath,
                  title: paper['title'] ?? 'Research Paper',
                  author: paper['author'] ?? '',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF path not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
