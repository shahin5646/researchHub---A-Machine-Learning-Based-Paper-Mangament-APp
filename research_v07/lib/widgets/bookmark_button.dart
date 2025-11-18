import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../screens/saved_papers_screen.dart';

class BookmarkButton extends ConsumerStatefulWidget {
  final String paperId;
  final String paperTitle;
  final String paperAuthor;
  final String? year;
  final String? category;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const BookmarkButton({
    super.key,
    required this.paperId,
    required this.paperTitle,
    required this.paperAuthor,
    this.year,
    this.category,
    this.iconSize = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton> {
  bool _isBookmarked = false;
  bool _isLoading = true;

  // Helper function to create Firestore-safe document ID
  String _getFirestoreDocId(String paperId) {
    // Replace forward slashes with a safe separator
    return paperId.replaceAll('/', '_SLASH_').replaceAll('.', '_DOT_');
  }

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final docId = _getFirestoreDocId(widget.paperId);
      debugPrint('🔍 Checking bookmark status for: ${widget.paperId}');
      debugPrint('   Using Firestore doc ID: $docId');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('bookmarks')
          .doc(docId)
          .get();

      setState(() {
        _isBookmarked = doc.exists;
        _isLoading = false;
      });

      debugPrint(
          '   Status: ${doc.exists ? "BOOKMARKED ✅" : "NOT BOOKMARKED"}');
    } catch (e) {
      debugPrint('❌ Error checking bookmark status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save papers')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isBookmarked) {
        // Remove bookmark
        final docId = _getFirestoreDocId(widget.paperId);
        debugPrint('🗑️ Removing bookmark: ${widget.paperId}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('bookmarks')
            .doc(docId)
            .delete();

        setState(() {
          _isBookmarked = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from saved papers'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add bookmark
        final docId = _getFirestoreDocId(widget.paperId);
        final bookmarkData = {
          'paperId': widget.paperId,
          'paperTitle': widget.paperTitle,
          'paperAuthor': widget.paperAuthor,
          'bookmarkedAt': FieldValue.serverTimestamp(),
        };

        // Add optional fields if available
        if (widget.year != null && widget.year!.isNotEmpty) {
          bookmarkData['year'] = widget.year!;
        }
        if (widget.category != null && widget.category!.isNotEmpty) {
          bookmarkData['category'] = widget.category!;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('bookmarks')
            .doc(docId)
            .set(bookmarkData);
        debugPrint('📚 Bookmark saved: ${widget.paperTitle}');
        debugPrint('   ID: ${widget.paperId}');
        debugPrint('   Author: ${widget.paperAuthor}');
        if (widget.year != null) debugPrint('   Year: ${widget.year}');
        if (widget.category != null)
          debugPrint('   Category: ${widget.category}');

        setState(() {
          _isBookmarked = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bookmark saved successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedPapersScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save paper'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.iconSize,
        height: widget.iconSize,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(
        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: widget.iconSize,
        color: _isBookmarked
            ? (widget.activeColor ?? Colors.blue)
            : (widget.inactiveColor ?? Colors.grey),
      ),
      onPressed: _toggleBookmark,
      tooltip: _isBookmarked ? 'Remove from saved' : 'Save paper',
    );
  }
}
