import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import '../models/firebase_paper.dart';

class FirebasePaperService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger('FirebasePaperService');

  // Collection references
  CollectionReference get _papersCollection => _firestore.collection('papers');

  /// Upload paper PDF to Firebase Storage
  Future<String> uploadPaperFile({
    required String userId,
    required File file,
    required String paperId,
  }) async {
    try {
      _logger.info('Uploading paper file for user: $userId');

      final fileName =
          '${paperId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('papers/$userId/$fileName');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      _logger.info('Paper file uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.severe('Error uploading paper file: $e');
      rethrow;
    }
  }

  /// Upload thumbnail to Firebase Storage
  Future<String?> uploadThumbnail({
    required String userId,
    required File file,
    required String paperId,
  }) async {
    try {
      _logger.info('Uploading thumbnail for paper: $paperId');

      final fileName =
          '${paperId}_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('thumbnails/$userId/$fileName');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      _logger.info('Thumbnail uploaded successfully');
      return downloadUrl;
    } catch (e) {
      _logger.warning('Error uploading thumbnail: $e');
      return null;
    }
  }

  /// Create a new paper in Firestore
  Future<String> createPaper(FirebasePaper paper) async {
    try {
      _logger.info('Creating paper: ${paper.title}');

      final docRef = await _papersCollection.add(paper.toFirestore());

      _logger.info('Paper created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error creating paper: $e');
      rethrow;
    }
  }

  /// Get paper by ID
  Future<FirebasePaper?> getPaper(String paperId) async {
    try {
      _logger.info('Fetching paper: $paperId');

      final doc = await _papersCollection.doc(paperId).get();

      if (doc.exists) {
        return FirebasePaper.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.severe('Error fetching paper: $e');
      rethrow;
    }
  }

  /// Get paper stream for real-time updates
  Stream<FirebasePaper?> getPaperStream(String paperId) {
    return _papersCollection.doc(paperId).snapshots().map((doc) {
      if (doc.exists) {
        return FirebasePaper.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Get all papers (with pagination)
  Future<List<FirebasePaper>> getPapers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    String? visibility,
  }) async {
    try {
      _logger.info('Fetching papers with limit: $limit');

      Query query = _papersCollection.orderBy('uploadedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (visibility != null) {
        query = query.where('visibility', isEqualTo: visibility);
      }

      query = query.limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching papers: $e');
      return [];
    }
  }

  /// Get papers stream for real-time feed
  Stream<List<FirebasePaper>> getPapersStream({
    int limit = 20,
    String? category,
    String? visibility,
  }) {
    Query query = _papersCollection.orderBy('uploadedAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (visibility != null) {
      query = query.where('visibility', isEqualTo: visibility);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    });
  }

  /// Get papers by user
  Future<List<FirebasePaper>> getUserPapers(String userId) async {
    try {
      _logger.info('Fetching papers for user: $userId');

      final snapshot = await _papersCollection
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching user papers: $e');
      return [];
    }
  }

  /// Update paper
  Future<void> updatePaper(String paperId, Map<String, dynamic> updates) async {
    try {
      _logger.info('Updating paper: $paperId');

      updates['lastUpdated'] = FieldValue.serverTimestamp();
      await _papersCollection.doc(paperId).update(updates);

      _logger.info('Paper updated successfully');
    } catch (e) {
      _logger.severe('Error updating paper: $e');
      rethrow;
    }
  }

  /// Delete paper
  Future<void> deletePaper(String paperId, String userId) async {
    try {
      _logger.info('Deleting paper: $paperId');

      // Delete the Firestore document
      await _papersCollection.doc(paperId).delete();

      // Delete associated files from Storage
      try {
        final listResult =
            await _storage.ref().child('papers/$userId').listAll();
        for (var item in listResult.items) {
          if (item.name.contains(paperId)) {
            await item.delete();
          }
        }
      } catch (e) {
        _logger.warning('Error deleting storage files: $e');
      }

      _logger.info('Paper deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting paper: $e');
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementViews(String paperId) async {
    try {
      await _papersCollection.doc(paperId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      _logger.warning('Error incrementing views: $e');
    }
  }

  /// Increment download count
  Future<void> incrementDownloads(String paperId) async {
    try {
      await _papersCollection.doc(paperId).update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      _logger.warning('Error incrementing downloads: $e');
    }
  }

  /// Add comment to paper
  Future<void> addComment(PaperComment comment) async {
    try {
      _logger.info('Adding comment to paper: ${comment.paperId}');

      final batch = _firestore.batch();

      // Add comment
      final commentRef =
          _papersCollection.doc(comment.paperId).collection('comments').doc();

      batch.set(commentRef, comment.toFirestore());

      // Increment comment count
      final paperRef = _papersCollection.doc(comment.paperId);
      batch.update(paperRef, {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();

      _logger.info('Comment added successfully');
    } catch (e) {
      _logger.severe('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get comments for paper
  Future<List<PaperComment>> getComments(String paperId,
      {int limit = 50}) async {
    try {
      final snapshot = await _papersCollection
          .doc(paperId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PaperComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching comments: $e');
      return [];
    }
  }

  /// Get comments stream
  Stream<List<PaperComment>> getCommentsStream(String paperId) {
    return _papersCollection
        .doc(paperId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaperComment.fromFirestore(doc))
          .toList();
    });
  }

  /// Add reaction to paper
  Future<void> addReaction(String paperId, PaperReaction reaction) async {
    try {
      _logger.info('Adding reaction to paper: $paperId');

      final batch = _firestore.batch();

      // Add reaction
      final reactionRef = _papersCollection
          .doc(paperId)
          .collection('reactions')
          .doc(reaction.userId);

      batch.set(reactionRef, reaction.toFirestore());

      // Increment likes count
      final paperRef = _papersCollection.doc(paperId);
      batch.update(paperRef, {
        'likesCount': FieldValue.increment(1),
      });

      await batch.commit();

      _logger.info('Reaction added successfully');
    } catch (e) {
      _logger.severe('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove reaction from paper
  Future<void> removeReaction(String paperId, String userId) async {
    try {
      _logger.info('Removing reaction from paper: $paperId');

      final batch = _firestore.batch();

      // Remove reaction
      final reactionRef =
          _papersCollection.doc(paperId).collection('reactions').doc(userId);

      batch.delete(reactionRef);

      // Decrement likes count
      final paperRef = _papersCollection.doc(paperId);
      batch.update(paperRef, {
        'likesCount': FieldValue.increment(-1),
      });

      await batch.commit();

      _logger.info('Reaction removed successfully');
    } catch (e) {
      _logger.severe('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Check if user has reacted to paper
  Future<bool> hasUserReacted(String paperId, String userId) async {
    try {
      final doc = await _papersCollection
          .doc(paperId)
          .collection('reactions')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      _logger.warning('Error checking reaction: $e');
      return false;
    }
  }

  /// Search papers by title or authors
  Future<List<FirebasePaper>> searchPapers(String query) async {
    try {
      _logger.info('Searching papers: $query');

      // This is a basic search, for production use Algolia or ElasticSearch
      final snapshot = await _papersCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching papers: $e');
      return [];
    }
  }

  /// Get trending papers (most viewed in last 7 days)
  Future<List<FirebasePaper>> getTrendingPapers({int limit = 10}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _papersCollection
          .where('uploadedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('uploadedAt', descending: true)
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching trending papers: $e');
      return [];
    }
  }
}
