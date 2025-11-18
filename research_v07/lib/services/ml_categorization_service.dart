import 'dart:math' as math;
import '../models/research_paper.dart';
import '../data/faculty_data.dart';

class MLCategorizationService {
  static final MLCategorizationService _instance =
      MLCategorizationService._internal();
  factory MLCategorizationService() => _instance;
  MLCategorizationService._internal();

  // K-Means clustering for grouping research papers by field
  List<PaperCluster> performKMeansClustering({int k = 5}) {
    final allPapers = _getAllPapers();
    if (allPapers.isEmpty) return [];

    // Convert papers to feature vectors
    final features = allPapers.map((paper) => _extractFeatures(paper)).toList();

    // Initialize centroids randomly
    final centroids = _initializeCentroids(features, k);

    // Perform K-Means iterations
    List<List<int>> clusters = [];
    for (int iteration = 0; iteration < 100; iteration++) {
      final newClusters = _assignPointsToClusters(features, centroids);

      // Check for convergence
      if (_clustersEqual(clusters, newClusters)) break;

      clusters = newClusters;
      _updateCentroids(features, clusters, centroids);
    }

    // Create cluster objects with papers
    final paperClusters = <PaperCluster>[];
    for (int i = 0; i < k; i++) {
      final clusterPapers =
          clusters[i].map((index) => allPapers[index]).toList();
      if (clusterPapers.isNotEmpty) {
        paperClusters.add(PaperCluster(
          id: i,
          papers: clusterPapers,
          centroid: centroids[i],
          category: _inferClusterCategory(clusterPapers),
        ));
      }
    }

    return paperClusters;
  }

  // SVM-like classification for research types
  Map<String, double> classifyResearchType(ResearchPaper paper) {
    final features = _extractFeatures(paper);
    final scores = <String, double>{};

    // Define research type patterns (simplified SVM approach)
    final patterns = {
      'Theoretical': [
        1.0,
        0.2,
        0.1,
        0.8,
        0.3
      ], // Abstract, mathematical concepts
      'Experimental': [0.3, 1.0, 0.8, 0.2, 0.7], // Data, results, methodology
      'Survey': [0.5, 0.3, 0.2, 0.9, 0.4], // Review, comparison, analysis
      'Applied': [0.4, 0.8, 1.0, 0.3, 0.9], // Implementation, practical
      'Computational': [0.6, 0.7, 0.9, 0.4, 0.8], // Algorithm, simulation
    };

    for (final type in patterns.keys) {
      final pattern = patterns[type]!;
      scores[type] = _calculateSimilarity(features, pattern);
    }

    // Normalize scores
    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.forEach((key, value) => scores[key] = value / total);
    }

    return scores;
  }

  // Topic modeling using simple term frequency analysis
  List<ResearchTopic> extractTopics({int numTopics = 10}) {
    final allPapers = _getAllPapers();
    final termFrequency = <String, int>{};
    final documentFrequency = <String, int>{};

    // Calculate term and document frequencies
    for (final paper in allPapers) {
      final terms = _extractTerms(paper);
      final uniqueTerms = terms.toSet();

      for (final term in terms) {
        termFrequency[term] = (termFrequency[term] ?? 0) + 1;
      }

      for (final term in uniqueTerms) {
        documentFrequency[term] = (documentFrequency[term] ?? 0) + 1;
      }
    }

    // Calculate TF-IDF scores
    final tfidfScores = <String, double>{};
    final totalDocs = allPapers.length;

    for (final term in termFrequency.keys) {
      final tf = termFrequency[term]!;
      final df = documentFrequency[term]!;
      final idf = math.log(totalDocs / df);
      tfidfScores[term] = tf * idf;
    }

    // Get top terms as topics
    final sortedTerms = tfidfScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topics = <ResearchTopic>[];
    for (int i = 0; i < math.min(numTopics, sortedTerms.length); i++) {
      final entry = sortedTerms[i];
      final relatedPapers = allPapers.where((paper) {
        final paperTerms = _extractTerms(paper);
        return paperTerms.contains(entry.key);
      }).toList();

      topics.add(ResearchTopic(
        id: i,
        name: entry.key,
        score: entry.value,
        relatedPapers: relatedPapers.take(10).toList(),
        keywords: _getRelatedKeywords(entry.key, tfidfScores),
      ));
    }

    return topics;
  }

  // Semantic similarity between papers
  double calculateSemanticSimilarity(
      ResearchPaper paper1, ResearchPaper paper2) {
    final features1 = _extractFeatures(paper1);
    final features2 = _extractFeatures(paper2);
    return _calculateCosineSimilarity(features1, features2);
  }

  // Find similar papers using content-based similarity
  List<ResearchPaper> findSimilarPapers(ResearchPaper targetPaper,
      {int limit = 5}) {
    final allPapers = _getAllPapers().where((p) => p != targetPaper).toList();
    final targetFeatures = _extractFeatures(targetPaper);

    final similarities = allPapers.map((paper) {
      final features = _extractFeatures(paper);
      final similarity = _calculateCosineSimilarity(targetFeatures, features);
      return MapEntry(paper, similarity);
    }).toList();

    similarities.sort((a, b) => b.value.compareTo(a.value));
    return similarities.take(limit).map((e) => e.key).toList();
  }

  // Trend analysis
  List<ResearchTrend> analyzeTrends({int years = 5}) {
    final allPapers = _getAllPapers();
    final currentYear = DateTime.now().year;
    final trends = <String, Map<int, int>>{};

    // Group papers by keywords and year
    for (final paper in allPapers) {
      final year = int.tryParse(paper.year) ?? currentYear;
      if (year >= currentYear - years) {
        for (final keyword in paper.keywords) {
          trends[keyword] = trends[keyword] ?? {};
          trends[keyword]![year] = (trends[keyword]![year] ?? 0) + 1;
        }
      }
    }

    // Calculate trend scores
    final trendList = <ResearchTrend>[];
    for (final keyword in trends.keys) {
      final yearData = trends[keyword]!;
      final years = yearData.keys.toList()..sort();

      if (years.length >= 2) {
        final oldCount = yearData[years.first] ?? 0;
        final newCount = yearData[years.last] ?? 0;
        final growth = newCount > 0 ? (newCount - oldCount) / oldCount : 0.0;

        trendList.add(ResearchTrend(
          keyword: keyword,
          growthRate: growth,
          totalPapers: yearData.values.reduce((a, b) => a + b),
          yearlyData: Map.from(yearData),
        ));
      }
    }

    trendList.sort((a, b) => b.growthRate.compareTo(a.growthRate));
    return trendList.take(20).toList();
  }

  // Private helper methods
  List<ResearchPaper> _getAllPapers() {
    final papers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, paperList) {
      papers.addAll(paperList);
    });
    return papers;
  }

  List<double> _extractFeatures(ResearchPaper paper) {
    // Feature extraction based on text analysis
    final content =
        '${paper.title} ${paper.abstract} ${paper.keywords.join(' ')}'
            .toLowerCase();

    return [
      _countMatches(content, ['theory', 'theoretical', 'model', 'framework']),
      _countMatches(
          content, ['experiment', 'data', 'result', 'analysis', 'study']),
      _countMatches(
          content, ['implementation', 'system', 'application', 'practical']),
      _countMatches(content, ['survey', 'review', 'comparison', 'overview']),
      _countMatches(content, ['algorithm', 'method', 'approach', 'technique']),
    ].map((count) => count.toDouble()).toList();
  }

  double _countMatches(String content, List<String> terms) {
    double count = 0;
    for (final term in terms) {
      count += RegExp(r'\b' + term + r'\b').allMatches(content).length;
    }
    return count;
  }

  List<String> _extractTerms(ResearchPaper paper) {
    final content =
        '${paper.title} ${paper.abstract} ${paper.keywords.join(' ')}'
            .toLowerCase();
    return content
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 3)
        .toList();
  }

  List<List<double>> _initializeCentroids(List<List<double>> features, int k) {
    final centroids = <List<double>>[];
    final random = math.Random();

    for (int i = 0; i < k; i++) {
      final centroid = <double>[];
      for (int j = 0; j < features.first.length; j++) {
        centroid.add(random.nextDouble());
      }
      centroids.add(centroid);
    }

    return centroids;
  }

  List<List<int>> _assignPointsToClusters(
      List<List<double>> features, List<List<double>> centroids) {
    final clusters = List.generate(centroids.length, (_) => <int>[]);

    for (int i = 0; i < features.length; i++) {
      int closestCentroid = 0;
      double minDistance = double.infinity;

      for (int j = 0; j < centroids.length; j++) {
        final distance = _calculateEuclideanDistance(features[i], centroids[j]);
        if (distance < minDistance) {
          minDistance = distance;
          closestCentroid = j;
        }
      }

      clusters[closestCentroid].add(i);
    }

    return clusters;
  }

  void _updateCentroids(List<List<double>> features, List<List<int>> clusters,
      List<List<double>> centroids) {
    for (int i = 0; i < clusters.length; i++) {
      if (clusters[i].isNotEmpty) {
        for (int j = 0; j < centroids[i].length; j++) {
          double sum = 0;
          for (final pointIndex in clusters[i]) {
            sum += features[pointIndex][j];
          }
          centroids[i][j] = sum / clusters[i].length;
        }
      }
    }
  }

  bool _clustersEqual(List<List<int>> clusters1, List<List<int>> clusters2) {
    if (clusters1.length != clusters2.length) return false;

    for (int i = 0; i < clusters1.length; i++) {
      final set1 = clusters1[i].toSet();
      final set2 = clusters2[i].toSet();
      if (!set1.containsAll(set2) || !set2.containsAll(set1)) {
        return false;
      }
    }

    return true;
  }

  double _calculateEuclideanDistance(List<double> point1, List<double> point2) {
    double sum = 0;
    for (int i = 0; i < point1.length; i++) {
      sum += math.pow(point1[i] - point2[i], 2);
    }
    return math.sqrt(sum);
  }

  double _calculateCosineSimilarity(
      List<double> vector1, List<double> vector2) {
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
      norm1 += vector1[i] * vector1[i];
      norm2 += vector2[i] * vector2[i];
    }

    if (norm1 == 0 || norm2 == 0) return 0;
    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  double _calculateSimilarity(List<double> features, List<double> pattern) {
    return _calculateCosineSimilarity(features, pattern);
  }

  String _inferClusterCategory(List<ResearchPaper> papers) {
    final keywords = <String, int>{};

    for (final paper in papers) {
      for (final keyword in paper.keywords) {
        keywords[keyword] = (keywords[keyword] ?? 0) + 1;
      }
    }

    if (keywords.isEmpty) return 'General';

    final topKeyword =
        keywords.entries.reduce((a, b) => a.value > b.value ? a : b);
    return topKeyword.key;
  }

  List<String> _getRelatedKeywords(
      String term, Map<String, double> tfidfScores) {
    return tfidfScores.entries
        .where((e) => e.key.contains(term) || term.contains(e.key))
        .map((e) => e.key)
        .take(5)
        .toList();
  }
}

class PaperCluster {
  final int id;
  final List<ResearchPaper> papers;
  final List<double> centroid;
  final String category;

  PaperCluster({
    required this.id,
    required this.papers,
    required this.centroid,
    required this.category,
  });
}

class ResearchTopic {
  final int id;
  final String name;
  final double score;
  final List<ResearchPaper> relatedPapers;
  final List<String> keywords;

  ResearchTopic({
    required this.id,
    required this.name,
    required this.score,
    required this.relatedPapers,
    required this.keywords,
  });
}

class ResearchTrend {
  final String keyword;
  final double growthRate;
  final int totalPapers;
  final Map<int, int> yearlyData;

  ResearchTrend({
    required this.keyword,
    required this.growthRate,
    required this.totalPapers,
    required this.yearlyData,
  });
}
