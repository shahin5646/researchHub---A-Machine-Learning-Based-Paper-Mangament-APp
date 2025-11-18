import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BookmarkService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> _bookmarkedPaperIds = {};
  bool _isInitialized = false;

  Set<String> get bookmarkedPapers => _bookmarkedPaperIds;
  bool get isInitialized => _isInitialized;

  /// Initialize bookmarks for a user
  Future<void> initialize(String userId) async {
    try {
      debugPrint('🔖 Initializing bookmarks for user: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();

      _bookmarkedPaperIds = snapshot.docs.map((doc) => doc.id).toSet();
      _isInitialized = true;

      debugPrint('✅ Loaded ${_bookmarkedPaperIds.length} bookmarks');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing bookmarks: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Check if a paper is bookmarked
  bool isBookmarked(String paperId) {
    return _bookmarkedPaperIds.contains(paperId);
  }

  /// Toggle bookmark status
  Future<bool> toggleBookmark(
    String userId,
    String paperId, {
    String? paperTitle,
    String? paperAuthor,
  }) async {
    try {
      final isCurrentlyBookmarked = _bookmarkedPaperIds.contains(paperId);

      if (isCurrentlyBookmarked) {
        // Remove bookmark
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('bookmarks')
            .doc(paperId)
            .delete();

        _bookmarkedPaperIds.remove(paperId);
        debugPrint('🗑️ Removed bookmark: $paperId');
      } else {
        // Add bookmark
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('bookmarks')
            .doc(paperId)
            .set({
          'paperId': paperId,
          'paperTitle': paperTitle ?? '',
          'paperAuthor': paperAuthor ?? '',
          'bookmarkedAt': FieldValue.serverTimestamp(),
        });

        _bookmarkedPaperIds.add(paperId);
        debugPrint('✅ Added bookmark: $paperId');
      }

      notifyListeners();
      return !isCurrentlyBookmarked; // Return new state
    } catch (e) {
      debugPrint('❌ Error toggling bookmark: $e');
      return isBookmarked(paperId);
    }
  }

  /// Get all bookmarked papers with details
  Future<List<Map<String, dynamic>>> getBookmarkedPapers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error getting bookmarked papers: $e');
      return [];
    }
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _bookmarkedPaperIds.clear();
      notifyListeners();

      debugPrint('🗑️ Cleared all bookmarks');
    } catch (e) {
      debugPrint('❌ Error clearing bookmarks: $e');
    }
  }

  int get bookmarkCount => _bookmarkedPaperIds.length;
}
