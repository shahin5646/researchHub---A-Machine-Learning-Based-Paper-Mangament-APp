import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/firebase_paper.dart';
import '../models/user_profile.dart';

/// Advanced search service with filtering and sorting capabilities
class AdvancedSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('AdvancedSearchService');

  // Search history storage
  final List<String> _searchHistory = [];
  static const int _maxHistoryItems = 20;

  /// Search papers with advanced filters
  Future<List<FirebasePaper>> searchPapers({
    required String query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? authorId,
    String? institution,
    List<String>? keywords,
    String sortBy =
        'uploadedAt', // 'uploadedAt', 'likesCount', 'viewsCount', 'title'
    bool descending = true,
    int limit = 20,
  }) async {
    try {
      // Add to search history
      _addToHistory(query);

      Query papersQuery = _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public');

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        papersQuery = papersQuery.where('category', isEqualTo: category);
      }

      // Apply author filter
      if (authorId != null && authorId.isNotEmpty) {
        papersQuery = papersQuery.where('uploadedBy', isEqualTo: authorId);
      }

      // Apply date range filter
      if (startDate != null) {
        papersQuery = papersQuery.where(
          'uploadedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        papersQuery = papersQuery.where(
          'uploadedAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Apply keywords filter
      if (keywords != null && keywords.isNotEmpty) {
        papersQuery = papersQuery.where(
          'keywords',
          arrayContainsAny: keywords,
        );
      }

      // Apply sorting
      papersQuery = papersQuery.orderBy(sortBy, descending: descending);

      // Apply limit
      papersQuery =
          papersQuery.limit(limit * 2); // Fetch more for client-side filtering

      final snapshot = await papersQuery.get();

      // Client-side filtering for title/abstract match
      final papers = snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .where((paper) {
            if (query.isEmpty) return true;

            final queryLower = query.toLowerCase();
            final titleMatch = paper.title.toLowerCase().contains(queryLower);
            final descMatch =
                (paper.description ?? '').toLowerCase().contains(queryLower);
            final authorsMatch = paper.authors.any(
              (author) => author.toLowerCase().contains(queryLower),
            );
            final keywordsMatch = paper.keywords.any(
              (keyword) => keyword.toLowerCase().contains(queryLower),
            );

            return titleMatch || descMatch || authorsMatch || keywordsMatch;
          })
          .take(limit)
          .toList();

      return papers;
    } catch (e) {
      _logger.severe('Error searching papers: $e');
      return [];
    }
  }

  /// Search users with filters
  Future<List<UserProfile>> searchUsers({
    required String query,
    String? institution,
    String? department,
    String? position,
    List<String>? researchInterests,
    String sortBy = 'followersCount',
    bool descending = true,
    int limit = 20,
  }) async {
    try {
      Query usersQuery = _firestore
          .collection('user_profiles')
          .where('isProfilePublic', isEqualTo: true);

      // Apply institution filter
      if (institution != null && institution.isNotEmpty) {
        usersQuery = usersQuery.where('institution', isEqualTo: institution);
      }

      // Apply department filter
      if (department != null && department.isNotEmpty) {
        usersQuery = usersQuery.where('department', isEqualTo: department);
      }

      // Apply position filter
      if (position != null && position.isNotEmpty) {
        usersQuery = usersQuery.where('position', isEqualTo: position);
      }

      // Apply research interests filter
      if (researchInterests != null && researchInterests.isNotEmpty) {
        usersQuery = usersQuery.where(
          'researchInterests',
          arrayContainsAny: researchInterests,
        );
      }

      // Apply sorting
      usersQuery = usersQuery.orderBy(sortBy, descending: descending);

      // Apply limit
      usersQuery = usersQuery.limit(limit * 2);

      final snapshot = await usersQuery.get();

      // Client-side filtering for name match
      final users = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) {
            if (query.isEmpty) return true;

            final queryLower = query.toLowerCase();
            final nameMatch =
                user.displayName.toLowerCase().contains(queryLower);
            final emailMatch = user.email.toLowerCase().contains(queryLower);
            final bioMatch =
                user.bio?.toLowerCase().contains(queryLower) ?? false;

            return nameMatch || emailMatch || bioMatch;
          })
          .take(limit)
          .toList();

      return users;
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Get suggestions from recent papers
      final papersSnapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .limit(100)
          .get();

      final suggestions = <String>{};

      for (var doc in papersSnapshot.docs) {
        final paper = FirebasePaper.fromFirestore(doc);

        // Add matching title words
        final titleWords = paper.title.split(' ');
        for (var word in titleWords) {
          if (word.toLowerCase().startsWith(queryLower)) {
            suggestions.add(word);
          }
        }

        // Add matching keywords
        for (var keyword in paper.keywords) {
          if (keyword.toLowerCase().startsWith(queryLower)) {
            suggestions.add(keyword);
          }
        }

        if (suggestions.length >= 10) break;
      }

      return suggestions.take(10).toList();
    } catch (e) {
      _logger.severe('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get popular search keywords
  Future<List<String>> getPopularKeywords({int limit = 10}) async {
    try {
      // Get most common keywords from recent papers
      final papersSnapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .limit(100)
          .get();

      final keywordCounts = <String, int>{};

      for (var doc in papersSnapshot.docs) {
        final paper = FirebasePaper.fromFirestore(doc);
        for (var keyword in paper.keywords) {
          keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
        }
      }

      // Sort by frequency
      final sortedKeywords = keywordCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedKeywords.take(limit).map((e) => e.key).toList();
    } catch (e) {
      _logger.severe('Error getting popular keywords: $e');
      return [];
    }
  }

  /// Get all available categories
  Future<List<String>> getCategories() async {
    try {
      final papersSnapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .get();

      final categories = <String>{};
      for (var doc in papersSnapshot.docs) {
        final paper = FirebasePaper.fromFirestore(doc);
        if (paper.category.isNotEmpty) {
          categories.add(paper.category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      _logger.severe('Error getting categories: $e');
      return [];
    }
  }

  /// Get all available institutions
  Future<List<String>> getInstitutions() async {
    try {
      final usersSnapshot = await _firestore
          .collection('user_profiles')
          .where('isProfilePublic', isEqualTo: true)
          .get();

      final institutions = <String>{};
      for (var doc in usersSnapshot.docs) {
        final user = UserProfile.fromFirestore(doc);
        if (user.institution != null && user.institution!.isNotEmpty) {
          institutions.add(user.institution!);
        }
      }

      return institutions.toList()..sort();
    } catch (e) {
      _logger.severe('Error getting institutions: $e');
      return [];
    }
  }

  /// Add query to search history
  void _addToHistory(String query) {
    if (query.isEmpty) return;

    _searchHistory.remove(query); // Remove duplicates
    _searchHistory.insert(0, query);

    // Keep only recent items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
  }

  /// Get search history
  List<String> getSearchHistory() {
    return List.from(_searchHistory);
  }

  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
  }

  /// Remove item from search history
  void removeFromHistory(String query) {
    _searchHistory.remove(query);
  }

  /// Search papers by specific field with exact match
  Future<List<FirebasePaper>> searchByField({
    required String field,
    required dynamic value,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where(field, isEqualTo: value)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching by field: $e');
      return [];
    }
  }

  /// Get papers by multiple authors
  Future<List<FirebasePaper>> searchByAuthors(List<String> authors) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where('authors', arrayContainsAny: authors)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching by authors: $e');
      return [];
    }
  }

  /// Advanced paper filtering with multiple criteria
  Future<List<FirebasePaper>> filterPapers({
    int? minLikes,
    int? maxLikes,
    int? minViews,
    int? maxViews,
    bool? hasComments,
    String? language,
  }) async {
    try {
      Query papersQuery = _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public');

      // Firestore doesn't support range queries on multiple fields
      // We'll fetch more and filter client-side
      final snapshot = await papersQuery
          .orderBy('uploadedAt', descending: true)
          .limit(100)
          .get();

      final papers = snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .where((paper) {
        bool matches = true;

        if (minLikes != null && paper.likesCount < minLikes) {
          matches = false;
        }
        if (maxLikes != null && paper.likesCount > maxLikes) {
          matches = false;
        }
        if (minViews != null && (paper.views ?? 0) < minViews) {
          matches = false;
        }
        if (maxViews != null && (paper.views ?? 0) > maxViews) {
          matches = false;
        }
        if (hasComments != null && (paper.commentsCount > 0) != hasComments) {
          matches = false;
        }

        return matches;
      }).toList();

      return papers;
    } catch (e) {
      _logger.severe('Error filtering papers: $e');
      return [];
    }
  }
}
