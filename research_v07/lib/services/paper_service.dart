import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/paper_models.dart';

class PaperService extends ChangeNotifier {
  static const String _paperBoxName = 'papers';
  static const String _categoryBoxName = 'paper_categories';

  Box<ResearchPaper>? _paperBox;
  Box<PaperCategory>? _categoryBox;

  List<ResearchPaper> _papers = [];
  List<PaperCategory> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';

  // Getters
  List<ResearchPaper> get papers => _papers;
  List<PaperCategory> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Initialize the service
  Future<void> initialize() async {
    try {
      _paperBox = await Hive.openBox<ResearchPaper>(_paperBoxName);
      _categoryBox = await Hive.openBox<PaperCategory>(_categoryBoxName);

      await _loadPapers();
      await _loadCategories();
      await _initializeDefaultCategories();

      debugPrint(
          'PaperService initialized successfully with ${_papers.length} papers');
    } catch (e) {
      debugPrint('Error initializing PaperService: $e');
      rethrow;
    }
  }

  // Load papers from Hive
  Future<void> _loadPapers() async {
    try {
      final savedPapers = _paperBox?.values.toList() ?? [];
      _papers = savedPapers;
      debugPrint('Loaded ${_papers.length} papers from local storage');
      if (_papers.isNotEmpty) {
        debugPrint(
            'Papers in storage: ${_papers.map((p) => p.title).join(', ')}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading papers: $e');
    }
  }

  // Load categories from Hive
  Future<void> _loadCategories() async {
    try {
      _categories = _categoryBox?.values.toList() ?? [];
      debugPrint('Loaded ${_categories.length} categories from local storage');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // Initialize default categories if none exist
  Future<void> _initializeDefaultCategories() async {
    if (_categories.isEmpty) {
      final defaultCategories = [
        PaperCategory(
          id: 'computer_science',
          name: 'Computer Science',
          description: 'Software Engineering, AI, Machine Learning',
          icon: 'computer',
          color: '#2196F3',
          subcategories: [
            'Artificial Intelligence',
            'Software Engineering',
            'Data Science',
            'Cybersecurity'
          ],
        ),
        PaperCategory(
          id: 'engineering',
          name: 'Engineering',
          description: 'Civil, Mechanical, Electrical Engineering',
          icon: 'engineering',
          color: '#FF9800',
          subcategories: [
            'Civil Engineering',
            'Mechanical Engineering',
            'Electrical Engineering'
          ],
        ),
        PaperCategory(
          id: 'business',
          name: 'Business & Management',
          description: 'Business Administration, Economics',
          icon: 'business',
          color: '#4CAF50',
          subcategories: ['Management', 'Finance', 'Marketing', 'Economics'],
        ),
        PaperCategory(
          id: 'science',
          name: 'Natural Sciences',
          description: 'Physics, Chemistry, Biology',
          icon: 'science',
          color: '#9C27B0',
          subcategories: ['Physics', 'Chemistry', 'Biology', 'Mathematics'],
        ),
        PaperCategory(
          id: 'social_sciences',
          name: 'Social Sciences',
          description: 'Psychology, Sociology, Education',
          icon: 'social',
          color: '#FF5722',
          subcategories: [
            'Psychology',
            'Sociology',
            'Education',
            'Political Science'
          ],
        ),
      ];

      for (final category in defaultCategories) {
        await addCategory(category);
      }
    }
  }

  // Add a new paper
  Future<bool> addPaper(ResearchPaper paper, {Uint8List? fileBytes}) async {
    try {
      // Ensure the box is initialized before adding
      if (_paperBox == null) {
        debugPrint('PaperService: Box not initialized, initializing first...');
        await initialize();
      }

      if (kIsWeb && fileBytes != null) {
        // For web platform, store the file bytes in the paper object
        final paperWithBytes = paper.copyWith(fileBytes: fileBytes);
        await _paperBox?.put(paperWithBytes.id, paperWithBytes);
        _papers.add(paperWithBytes);
        debugPrint(
            'Paper with bytes saved to Hive with ID: ${paperWithBytes.id}');
      } else {
        // For other platforms, store the paper as is
        await _paperBox?.put(paper.id, paper);
        _papers.add(paper);
        debugPrint('Paper saved to Hive with ID: ${paper.id}');
      }

      notifyListeners();
      debugPrint('Paper added successfully: ${paper.title}');
      debugPrint('Total papers after add: ${_papers.length}');

      // Verify the paper was actually saved to Hive
      final savedPaper = _paperBox?.get(paper.id);
      if (savedPaper != null) {
        debugPrint('Verified: Paper exists in Hive storage');
      } else {
        debugPrint('WARNING: Paper not found in Hive storage after save!');
      }

      return true;
    } catch (e) {
      debugPrint('Error adding paper: $e');
      return false;
    }
  }

  // Update a paper
  Future<bool> updatePaper(ResearchPaper paper) async {
    try {
      await _paperBox?.put(paper.id, paper);
      final index = _papers.indexWhere((p) => p.id == paper.id);
      if (index != -1) {
        _papers[index] = paper;
        notifyListeners();
        debugPrint('Paper updated successfully: ${paper.title}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating paper: $e');
      return false;
    }
  }

  // Delete a paper
  Future<bool> deletePaper(String paperId) async {
    try {
      await _paperBox?.delete(paperId);
      _papers.removeWhere((p) => p.id == paperId);
      notifyListeners();
      debugPrint('Paper deleted successfully: $paperId');
      return true;
    } catch (e) {
      debugPrint('Error deleting paper: $e');
      return false;
    }
  }

  // Get paper by ID
  ResearchPaper? getPaperById(String id) {
    try {
      return _papers.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search papers
  List<ResearchPaper> searchPapers(String query) {
    if (query.isEmpty) return _papers;

    final lowercaseQuery = query.toLowerCase();
    return _papers.where((paper) {
      return paper.title.toLowerCase().contains(lowercaseQuery) ||
          paper.authors
              .any((author) => author.toLowerCase().contains(lowercaseQuery)) ||
          paper.abstract?.toLowerCase().contains(lowercaseQuery) == true ||
          paper.keywords.any(
              (keyword) => keyword.toLowerCase().contains(lowercaseQuery)) ||
          paper.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Filter papers by category
  List<ResearchPaper> filterByCategory(String categoryId) {
    if (categoryId == 'all') return _papers;
    return _papers.where((paper) => paper.category == categoryId).toList();
  }

  // Get papers by user
  List<ResearchPaper> getPapersByUser(String userId) {
    return _papers.where((paper) => paper.uploadedBy == userId).toList();
  }

  // Get bookmarked papers for user
  List<ResearchPaper> getBookmarkedPapers(List<String> bookmarkedIds) {
    return _papers.where((paper) => bookmarkedIds.contains(paper.id)).toList();
  }

  // Get trending papers (most viewed/downloaded)
  List<ResearchPaper> getTrendingPapers({int limit = 10}) {
    final sortedPapers = List<ResearchPaper>.from(_papers);
    sortedPapers.sort(
        (a, b) => (b.views + b.downloads).compareTo(a.views + a.downloads));
    return sortedPapers.take(limit).toList();
  }

  // Get recent papers
  List<ResearchPaper> getRecentPapers({int limit = 10}) {
    final sortedPapers = List<ResearchPaper>.from(_papers);
    sortedPapers.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return sortedPapers.take(limit).toList();
  }

  // Increment paper views
  Future<void> incrementViews(String paperId) async {
    final paper = getPaperById(paperId);
    if (paper != null) {
      final updatedPaper = paper.copyWith(views: paper.views + 1);
      await updatePaper(updatedPaper);
    }
  }

  // Increment paper downloads
  Future<void> incrementDownloads(String paperId) async {
    final paper = getPaperById(paperId);
    if (paper != null) {
      final updatedPaper = paper.copyWith(downloads: paper.downloads + 1);
      await updatePaper(updatedPaper);
    }
  }

  // Add category
  Future<bool> addCategory(PaperCategory category) async {
    try {
      await _categoryBox?.put(category.id, category);
      _categories.add(category);
      notifyListeners();
      debugPrint('Category added successfully: ${category.name}');
      return true;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return false;
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Update selected category
  void updateSelectedCategory(String categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }

  // Get filtered and searched papers
  List<ResearchPaper> getFilteredPapers() {
    List<ResearchPaper> result = _papers;

    // Apply category filter
    if (_selectedCategory != 'all') {
      result =
          result.where((paper) => paper.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      result = result.where((paper) {
        return paper.title.toLowerCase().contains(lowercaseQuery) ||
            paper.authors.any(
                (author) => author.toLowerCase().contains(lowercaseQuery)) ||
            paper.abstract?.toLowerCase().contains(lowercaseQuery) == true ||
            paper.keywords.any(
                (keyword) => keyword.toLowerCase().contains(lowercaseQuery)) ||
            paper.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }

    return result;
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      await _paperBox?.clear();
      await _categoryBox?.clear();
      _papers.clear();
      _categories.clear();
      notifyListeners();
      debugPrint('All paper data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  @override
  void dispose() {
    _paperBox?.close();
    _categoryBox?.close();
    super.dispose();
  }
}
