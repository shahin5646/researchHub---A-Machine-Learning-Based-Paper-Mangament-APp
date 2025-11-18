import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/faculty_data.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'firebase_paper_service.dart';
import 'ml_categorization_service.dart';
import '../models/research_paper.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();

  factory PdfService() {
    return _instance;
  }

  PdfService._internal() {
    // Initialize trending papers when service is created
    loadTrendingPapers();
    // Initialize ML-based clustering for automatic categorization
    _initializeMLClustering();
  }

  final _logger = Logger('PdfService');
  String? basePath; // Make nullable
  final Map<String, TrendingPaper> _trendingPapers = {};
  final FirebasePaperService _firebasePaperService = FirebasePaperService();
  final MLCategorizationService _mlService = MLCategorizationService();

  // ML-based paper clusters (auto-discovered categories)
  List<PaperCluster> _paperClusters = [];
  Map<String, String> _paperCategoryCache =
      {}; // Cache paper->category mappings

  // Map display names to asset folder names for fallback scanning
  final Map<String, String> _professorFolderMapping = const {
    'Professor Dr. Sheak Rashed Haider Noori':
        'ProfessorDrSheakRashedHaiderNoori',
    'Professor Dr. Md. Fokhray Hossain': 'Professor_Dr_Md_FokhrayHossain',
    'Dr. S. M. Aminul Haque': 'Dr_S_M_Aminul_Haque',
    'Ms. Nazmun Nessa Moon': 'Ms._Nazmun_Nessa_Moon',
    'Dr. Shaikh Muhammad Allayear': 'Dr_Shaikh_Muhammad_Allayear',
    'Dr. A. H. M. Saifullah Sadi': 'Dr_A_H_M_SaifullahSadi',
    'Dr. Imran Mahmud': 'DrImran_Mahmud',
    'Dr. Md. Sarowar Hossain': 'Dr_Md._Sarowar_Hossain',
  };

  // Cache to store prepared PDF paths for faster access
  final Map<String, String> _preparedPdfCache = {};

  /// Prepares a PDF file for viewing, handling both asset and file-based PDFs
  /// Returns the path to the prepared PDF file that can be used by PDF viewers
  Future<String> preparePdfForViewing(String pdfPath,
      {bool isAsset = false}) async {
    // Check if this PDF is already in cache to avoid re-processing
    final cacheKey = '$pdfPath:$isAsset';
    if (_preparedPdfCache.containsKey(cacheKey)) {
      final cachedPath = _preparedPdfCache[cacheKey];
      if (cachedPath != null && cachedPath.isNotEmpty) {
        // For files, verify they still exist before returning from cache
        if (!isAsset && !kIsWeb) {
          final file = File(cachedPath);
          if (await file.exists()) {
            _logger.info('Using cached PDF: $cachedPath');
            return cachedPath;
          } else {
            _logger.warning('Cached file no longer exists: $cachedPath');
            _preparedPdfCache.remove(cacheKey);
          }
        } else {
          return cachedPath;
        }
      }
    }

    try {
      if (kIsWeb) {
        // For web, return the path directly since we can't copy files
        final webPath = isAsset ? pdfPath : pdfPath;
        _preparedPdfCache[cacheKey] = webPath;
        _logger.info('Web PDF path prepared: $webPath');
        return webPath;
      }

      if (isAsset) {
        // For assets, copy to a temporary location
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(pdfPath);
        final localPath = path.join(appDir.path, 'pdf_cache', fileName);
        final localFile = File(localPath);

        // Create directory if it doesn't exist
        await localFile.parent.create(recursive: true);

        // Copy asset to local file if it doesn't exist or is older
        if (!await localFile.exists()) {
          _logger.info('Copying asset to local file: $pdfPath -> $localPath');
          try {
            final data = await rootBundle.load(pdfPath);
            await localFile.writeAsBytes(data.buffer.asUint8List());
            _logger.info('Successfully copied asset: $pdfPath');
          } catch (e) {
            _logger.severe('Failed to load asset $pdfPath: $e');
            throw Exception('Asset not found: $pdfPath');
          }
        }

        _preparedPdfCache[cacheKey] = localPath;
        _logger.info('Asset PDF prepared: $localPath');
        return localPath;
      } else {
        // For regular files, return the path directly
        final file = File(pdfPath);
        if (await file.exists()) {
          _preparedPdfCache[cacheKey] = pdfPath;
          _logger.info('File PDF prepared: $pdfPath');
          return pdfPath;
        } else {
          throw Exception('PDF file not found: $pdfPath');
        }
      }
    } catch (e) {
      _logger.severe('Error preparing PDF for viewing: $e');
      throw Exception('Failed to prepare PDF: $e');
    }
  }

  /// Get papers for a specific professor (for native platforms)
  Future<List<File>> getProfessorPapers(String professorName) async {
    if (kIsWeb) {
      // Return web-specific papers
      final webPapers = getWebPapers(professorName);
      _logger.info('Web papers found: ${webPapers.length}');
      return []; // For web, return empty list since we can't use File class
    }

    try {
      _logger.info('Getting papers for professor: $professorName');
      _logger.info(
          'Available keys in facultyResearchPapers: ${facultyResearchPapers.keys.toList()}');

      // Resolve best-matching key in case of formatting differences
      final resolvedKey = _resolveFacultyKey(professorName);
      if (resolvedKey != professorName) {
        _logger.info(
            'Resolved professor name "$professorName" to data key "$resolvedKey"');
      }

      // Get papers from faculty data
      final papers = facultyResearchPapers[resolvedKey] ?? [];
      _logger.info(
          'Found ${papers.length} papers in faculty data for: $resolvedKey');

      final List<File> professorPapers = [];

      for (final paper in papers) {
        final isAssetPaper = (paper.isAsset == true) ||
            (paper.pdfUrl.isNotEmpty && paper.pdfUrl.startsWith('assets/'));
        if (isAssetPaper && paper.pdfUrl.isNotEmpty) {
          try {
            // Copy asset to app directory so it can be accessed as File
            final preparedPath =
                await preparePdfForViewing(paper.pdfUrl, isAsset: true);
            final file = File(preparedPath);
            if (await file.exists()) {
              professorPapers.add(file);
              _logger.fine('Added paper: ${paper.title}');
            } else {
              _logger
                  .warning('Prepared PDF file does not exist: $preparedPath');
            }
          } catch (e) {
            _logger.warning('Failed to prepare paper ${paper.title}: $e');
          }
        }
      }

      // Fallback: if empty, scan AssetManifest for PDFs under professor folder
      if (professorPapers.isEmpty) {
        final fallbackAssets = await _findProfessorAssetPdfs(resolvedKey);
        _logger.info(
            'Fallback found ${fallbackAssets.length} assets for $resolvedKey');
        for (final assetPath in fallbackAssets) {
          try {
            final preparedPath =
                await preparePdfForViewing(assetPath, isAsset: true);
            final file = File(preparedPath);
            if (await file.exists()) {
              professorPapers.add(file);
            }
          } catch (e) {
            _logger.warning('Fallback prepare failed for $assetPath: $e');
          }
        }
      }

      _logger
          .info('Returning ${professorPapers.length} papers for $resolvedKey');
      return professorPapers;
    } catch (e) {
      _logger.severe('Error getting professor papers for $professorName: $e');
      return [];
    }
  }

  /// Get papers for a specific professor (for web platform)
  List<Map<String, String>> getWebPapers(String professorName) {
    try {
      _logger.info('Getting web papers for professor: $professorName');
      _logger.info(
          'Available keys in facultyResearchPapers: ${facultyResearchPapers.keys.toList()}');

      // Resolve best-matching key in case of formatting differences
      final resolvedKey = _resolveFacultyKey(professorName);
      if (resolvedKey != professorName) {
        _logger.info(
            'Resolved professor name "$professorName" to data key "$resolvedKey"');
      }

      // Get papers from faculty data
      final papers = facultyResearchPapers[resolvedKey] ?? [];
      _logger.info(
          'Found ${papers.length} papers in faculty data for: $resolvedKey');

      final List<Map<String, String>> webPapers = [];

      for (final paper in papers) {
        final isAssetPaper = (paper.isAsset == true) ||
            (paper.pdfUrl.isNotEmpty && paper.pdfUrl.startsWith('assets/'));
        if (isAssetPaper && paper.pdfUrl.isNotEmpty) {
          webPapers.add({
            'title': paper.title,
            'path': paper.pdfUrl,
            'author': paper.author,
            'year': paper.year,
            'journal': paper.journalName,
            'doi': paper.doi,
            'abstract': paper.abstract,
            'keywords': paper.keywords.join(', '),
          });
        }
      }

      // Fallback: if empty, scan AssetManifest for PDFs under professor folder
      if (webPapers.isEmpty) {
        // Note: synchronous API signature; best-effort by returning empty for web fallback here.
        _logger.info('No web papers found in data for $resolvedKey');
      }
      _logger.info('Returning ${webPapers.length} web papers for $resolvedKey');
      return webPapers;
    } catch (e) {
      _logger.severe('Error getting web papers for $professorName: $e');
      return [];
    }
  }

  /// Parse AssetManifest.json to find PDFs under the professor's asset folder
  Future<List<String>> _findProfessorAssetPdfs(String professorName) async {
    try {
      final resolved = _resolveFacultyKey(professorName);
      final folderName = _professorFolderMapping[resolved];
      if (folderName == null || folderName.isEmpty) {
        _logger.fine('No folder mapping for $professorName');
        return [];
      }
      final prefix = 'assets/papers/$folderName/';

      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson);
      final List<String> matches = [];
      for (final key in manifest.keys) {
        if (key.startsWith(prefix) && key.toLowerCase().endsWith('.pdf')) {
          matches.add(key);
        }
      }
      return matches;
    } catch (e) {
      _logger.warning('Error scanning AssetManifest for $professorName: $e');
      return [];
    }
  }

  /// Resolve the faculty key from the provided name by applying
  /// case-insensitive and punctuation-insensitive matching with fallbacks.
  String _resolveFacultyKey(String name) {
    if (facultyResearchPapers.containsKey(name)) return name;

    // Try case-insensitive direct match
    final ciMatch = facultyResearchPapers.keys.firstWhere(
      (k) => k.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    if (ciMatch.isNotEmpty) return ciMatch;

    // Normalize: remove spaces, dots, underscores and lowercase
    String normalize(String s) =>
        s.replaceAll(RegExp(r'[\s._]'), '').toLowerCase();
    final normalizedInput = normalize(name);
    final normMatch = facultyResearchPapers.keys.firstWhere(
      (k) => normalize(k) == normalizedInput,
      orElse: () => '',
    );
    if (normMatch.isNotEmpty) return normMatch;

    // Fallback: contains relationship
    final containsMatch = facultyResearchPapers.keys.firstWhere(
      (k) =>
          k.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(k.toLowerCase()),
      orElse: () => '',
    );
    if (containsMatch.isNotEmpty) return containsMatch;

    // As last resort, return original
    return name;
  }

  Future<void> loadTrendingPapers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? trendingDataJson = prefs.getString('trending_papers');

      if (trendingDataJson != null) {
        final Map<String, dynamic> trendingData = json.decode(trendingDataJson);
        _trendingPapers.clear();
        trendingData.forEach((key, value) {
          _trendingPapers[key] = TrendingPaper.fromJson(value);
        });
        _logger.info('Loaded ${_trendingPapers.length} trending papers');
      } else {
        // Initialize with sample data if no saved data exists
        _trendingPapers['sample1'] = TrendingPaper(
          title: 'Machine Learning in Healthcare',
          author: 'Dr. Sample Author',
          path: 'assets/papers/sample.pdf',
          viewCount: 15,
          downloadCount: 8,
          lastViewed: DateTime.now(),
        );
        // Add more sample papers as needed
        _logger.info('No saved trending papers found, using defaults');
      }
    } catch (e) {
      _logger.severe('Error loading trending papers: $e');
    }
  }

  /// Get trending papers (stub implementation)
  List<TrendingPaper> getTrendingPapers({int limit = 10}) {
    final papers = _trendingPapers.values.toList();
    papers.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return papers.take(limit).toList();
  }

  /// Get categorized papers (faculty papers only - for backward compatibility)
  Map<String, List<Map<String, String>>> getCategorizedPapers() {
    // Get all papers with categories
    final allPapers = _getAllPapersWithCategory();

    // Group papers by category
    final Map<String, List<Map<String, String>>> categorizedPapers = {};

    for (final paper in allPapers) {
      final category = paper['category'] ?? 'Uncategorized';
      if (!categorizedPapers.containsKey(category)) {
        categorizedPapers[category] = [];
      }
      categorizedPapers[category]!.add(paper);
    }

    return categorizedPapers;
  }

  /// Get categorized papers including user uploads from Firebase
  /// Uses K-Means clustering categories from ML service
  Future<Map<String, List<Map<String, String>>>>
      getCategorizedPapersWithUploads() async {
    // Get all papers including Firebase user uploads
    final allPapers = await getAllPapersIncludingUserUploads();

    // If ML clustering is available, use cluster-based categories
    if (_paperClusters.isNotEmpty) {
      _logger.info('🤖 Using K-Means ML clustering for categorization');

      final Map<String, List<Map<String, String>>> clusterCategories = {};

      // Group papers by their ML cluster categories
      for (final cluster in _paperClusters) {
        final clusterCategory = cluster.category;
        clusterCategories[clusterCategory] = [];

        for (final paper in cluster.papers) {
          // Find matching paper in allPapers and add to cluster category
          final matchingPaper = allPapers.firstWhere(
            (p) => p['title'] == paper.title && p['author'] == paper.author,
            orElse: () => <String, String>{},
          );

          if (matchingPaper.isNotEmpty) {
            // Update the category to match the ML cluster
            matchingPaper['category'] = clusterCategory;
            clusterCategories[clusterCategory]!.add(matchingPaper);
          }
        }
      }

      // Add any papers that weren't in clusters (e.g., newly uploaded user papers)
      final categorizedPaperTitles = <String>{};
      clusterCategories.values.forEach((papers) {
        papers.forEach((p) => categorizedPaperTitles.add(p['title'] ?? ''));
      });

      for (final paper in allPapers) {
        if (!categorizedPaperTitles.contains(paper['title'] ?? '')) {
          final category = paper['category'] ?? 'Other';
          clusterCategories.putIfAbsent(category, () => []).add(paper);
        }
      }

      _logger.info(
          '📚 K-Means Clustered ${allPapers.length} papers into ${clusterCategories.length} ML-discovered categories');
      clusterCategories.forEach((category, papers) {
        _logger.fine('   🎯 $category: ${papers.length} papers');
      });

      return clusterCategories;
    }

    // Fallback: Group papers by their individual category field
    _logger.warning(
        '⚠️ ML clustering not available, using individual paper categories');
    final Map<String, List<Map<String, String>>> categorizedPapers = {};

    for (final paper in allPapers) {
      final category = paper['category'] ?? 'Uncategorized';
      if (!categorizedPapers.containsKey(category)) {
        categorizedPapers[category] = [];
      }
      categorizedPapers[category]!.add(paper);
    }

    _logger.info(
        '📚 Categorized ${allPapers.length} papers into ${categorizedPapers.length} categories');
    return categorizedPapers;
  }

  /// Get category paper counts (stub implementation)
  Map<String, int> getCategoryPaperCounts() {
    final categorizedPapers = getCategorizedPapers();
    final Map<String, int> counts = {};

    categorizedPapers.forEach((category, papers) {
      counts[category] = papers.length;
    });

    return counts;
  }

  /// Get papers by category
  List<Map<String, String>> getPapersByCategory(String category) {
    final allPapers = _getAllPapersWithCategory();

    // Filter by exact category match
    return allPapers.where((paper) {
      final paperCategory = paper['category'] ?? '';
      return paperCategory == category;
    }).toList();
  }

  /// Get all unique categories from papers
  List<String> getAllCategories() {
    final allPapers = _getAllPapersWithCategory();
    final categories = allPapers
        .map((paper) => paper['category'] ?? 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Get total count of all papers
  int getTotalPaperCount() {
    return _getAllPapersWithCategory().length;
  }

  /// Get papers grouped by author
  Map<String, List<Map<String, String>>> getPapersByAuthor() {
    final allPapers = _getAllPapersWithCategory();
    final Map<String, List<Map<String, String>>> authorPapers = {};

    for (final paper in allPapers) {
      final author = paper['author'] ?? 'Unknown';
      authorPapers.putIfAbsent(author, () => []).add(paper);
    }

    return authorPapers;
  }

  /// Get all papers including user-uploaded papers from Firebase
  /// This combines faculty papers with user-uploaded papers
  Future<List<Map<String, String>>> getAllPapersIncludingUserUploads() async {
    final allPapers = _getAllPapersWithCategory();

    try {
      // Fetch user-uploaded papers from Firebase (public papers only)
      final userPapers = await _firebasePaperService.getPapers(
        limit: 1000, // Get all user papers
        visibility: 'public', // Only public papers
      );

      // Convert Firebase papers to the same format
      for (final userPaper in userPapers) {
        // Join authors list into single string
        final authorString = userPaper.authors.isNotEmpty
            ? userPaper.authors.join(', ')
            : 'Unknown Author';

        allPapers.add({
          'title': userPaper.title,
          'author': authorString,
          'year': userPaper.publishedDate.year.toString(),
          'path': userPaper.pdfUrl ?? '', // Handle nullable URL
          'journal': userPaper.journal ?? '',
          'doi': userPaper.doi ?? '',
          'abstract': userPaper.abstract ?? '',
          'keywords': userPaper.keywords.join(', '),
          'citations':
              userPaper.likesCount.toString(), // Use likes as citations
          'category': _categorizePaperByKeywords(
              userPaper.keywords, userPaper.abstract ?? '', userPaper.title),
          'isUserPaper': 'true', // Mark as user-uploaded
          'uploadedBy': userPaper.uploadedBy,
        });
      }

      _logger.info(
          'Total papers including user uploads: ${allPapers.length} (${userPapers.length} user papers)');
    } catch (e) {
      _logger.warning('Failed to fetch user-uploaded papers: $e');
      // Continue with faculty papers only if Firebase fetch fails
    }

    return allPapers;
  }

  /// ML-based initialization of paper clusters
  void _initializeMLClustering() {
    try {
      _logger.info('Initializing ML-based K-Means clustering...');
      // Perform K-Means clustering to automatically discover categories
      _paperClusters = _mlService.performKMeansClustering(k: 6);
      _logger.info(
          '✅ ML Clustering complete: ${_paperClusters.length} clusters discovered');

      // Build category cache for fast lookups
      for (final cluster in _paperClusters) {
        for (final paper in cluster.papers) {
          final paperKey = '${paper.title}_${paper.author}';
          _paperCategoryCache[paperKey] = cluster.category;
        }
      }

      _logger.info(
          '📊 Category cache built: ${_paperCategoryCache.length} papers categorized');
    } catch (e) {
      _logger.warning('⚠️ ML clustering failed, using fallback: $e');
      _paperClusters = [];
    }
  }

  /// ML-based categorization using K-Means clustering
  String _categorizePaperByKeywords(
      List<String> keywords, String abstract, String title) {
    // Try ML-based categorization first
    if (_paperClusters.isNotEmpty) {
      // Create a temporary ResearchPaper object for ML analysis
      final tempPaper = ResearchPaper(
        id: 'temp_${title.hashCode}',
        title: title,
        author: 'Unknown',
        journalName: '',
        year: DateTime.now().year.toString(),
        pdfUrl: '',
        doi: '',
        keywords: keywords,
        abstract: abstract,
        citations: 0,
      );

      // Find the best matching cluster using ML similarity
      PaperCluster? bestCluster;
      double maxSimilarity = 0.0;

      for (final cluster in _paperClusters) {
        // Use similarity with cluster papers
        if (cluster.papers.isNotEmpty) {
          final similarity = _mlService.calculateSemanticSimilarity(
            tempPaper,
            cluster.papers.first,
          );

          if (similarity > maxSimilarity) {
            maxSimilarity = similarity;
            bestCluster = cluster;
          }
        }
      }

      if (bestCluster != null && maxSimilarity > 0.3) {
        _logger.fine(
            'ML categorized "$title" as "${bestCluster.category}" (similarity: ${maxSimilarity.toStringAsFixed(2)})');
        return bestCluster.category;
      }
    }

    // Fallback to simple keyword matching if ML fails
    final combined = '${keywords.join(' ')} $abstract $title'.toLowerCase();

    if (combined.contains('machine learning') ||
        combined.contains('deep learning') ||
        combined.contains('ai') ||
        combined.contains('nlp') ||
        combined.contains('software') ||
        combined.contains('network') ||
        combined.contains('security')) {
      return 'Computer Science';
    }

    if (combined.contains('medical') ||
        combined.contains('healthcare') ||
        combined.contains('disease') ||
        combined.contains('cancer') ||
        combined.contains('drug')) {
      return 'Medical Science';
    }

    if (combined.contains('robot') ||
        combined.contains('iot') ||
        combined.contains('automation') ||
        combined.contains('engineering')) {
      return 'Engineering';
    }

    if (combined.contains('plant') ||
        combined.contains('agriculture') ||
        combined.contains('crop')) {
      return 'Biotechnology';
    }

    if (combined.contains('business') ||
        combined.contains('economics') ||
        combined.contains('banking')) {
      return 'Business & Economics';
    }

    if (combined.contains('education') ||
        combined.contains('learning') ||
        combined.contains('teaching')) {
      return 'Education';
    }

    return 'Computer Science';
  }

  /// Get all papers with proper categorization from faculty_data.dart
  List<Map<String, String>> _getAllPapersWithCategory() {
    final List<Map<String, String>> allPapers = [];

    // Iterate through all faculty research papers from faculty_data.dart
    facultyResearchPapers.forEach((facultyName, papers) {
      for (final paper in papers) {
        allPapers.add({
          'title': paper.title,
          'author': paper.author,
          'year': paper.year,
          'path': paper.pdfUrl,
          'journal': paper.journalName,
          'doi': paper.doi,
          'abstract': paper.abstract,
          'keywords': paper.keywords.join(', '),
          'citations': paper.citations.toString(),
          'category': _categorizePaper(paper),
        });
      }
    });

    _logger.info(
        'Loaded ${allPapers.length} papers from ${facultyResearchPapers.length} faculty members');
    return allPapers;
  }

  /// Automatically categorize a paper using ML clustering
  String _categorizePaper(dynamic paper) {
    // Check cache first for performance
    final paperKey = '${paper.title}_${paper.author}';
    if (_paperCategoryCache.containsKey(paperKey)) {
      return _paperCategoryCache[paperKey]!;
    }

    // Use ML-based categorization
    final category = _categorizePaperByKeywords(
      paper.keywords,
      paper.abstract,
      paper.title,
    );

    // Cache the result
    _paperCategoryCache[paperKey] = category;
    return category;
  }

  /// Track paper view (stub implementation)
  Future<void> trackPaperView(String title, String author, String path) async {
    try {
      final key = '$author:$title';
      if (_trendingPapers.containsKey(key)) {
        final paper = _trendingPapers[key]!;
        _trendingPapers[key] = TrendingPaper(
          title: paper.title,
          author: paper.author,
          path: paper.path,
          viewCount: paper.viewCount + 1,
          downloadCount: paper.downloadCount,
          lastViewed: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.warning('Error tracking paper view: $e');
    }
  }

  /// Track paper download (stub implementation)
  Future<void> trackPaperDownload(
      String title, String author, String path) async {
    try {
      final key = '$author:$title';
      if (_trendingPapers.containsKey(key)) {
        final paper = _trendingPapers[key]!;
        _trendingPapers[key] = TrendingPaper(
          title: paper.title,
          author: paper.author,
          path: paper.path,
          viewCount: paper.viewCount,
          downloadCount: paper.downloadCount + 1,
          lastViewed: paper.lastViewed,
        );
      }
    } catch (e) {
      _logger.warning('Error tracking paper download: $e');
    }
  }
}

class TrendingPaper {
  final String title;
  final String author;
  final String path;
  final int viewCount;
  final int downloadCount;
  final DateTime lastViewed;

  TrendingPaper({
    required this.title,
    required this.author,
    required this.path,
    required this.viewCount,
    required this.downloadCount,
    required this.lastViewed,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'path': path,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'lastViewed': lastViewed.toIso8601String(),
    };
  }

  factory TrendingPaper.fromJson(Map<String, dynamic> json) {
    return TrendingPaper(
      title: json['title'],
      author: json['author'],
      path: json['path'],
      viewCount: json['viewCount'],
      downloadCount: json['downloadCount'],
      lastViewed: DateTime.parse(json['lastViewed']),
    );
  }
}
