import 'dart:math' as math;
import '../models/research_paper.dart';
import '../data/faculty_data.dart';
import '../services/pdf_service.dart';

class EnhancedSearchService {
  static final EnhancedSearchService _instance =
      EnhancedSearchService._internal();
  factory EnhancedSearchService() => _instance;
  EnhancedSearchService._internal();

  final PdfService _pdfService = PdfService();

  // BM25 parameters
  static const double k1 = 1.2;
  static const double b = 0.75;

  // Search with advanced ranking using BM25-like algorithm
  List<SearchResult> advancedSearch(
    String query, {
    List<String>? authors,
    String? field,
    int? year,
    int? startYear,
    int? endYear,
    double threshold = 0.1,
  }) {
    if (query.isEmpty) return [];

    final queryTerms = _tokenize(query.toLowerCase());
    final allPapers = _getAllPapers();
    final results = <SearchResult>[];

    // Calculate document frequencies
    final docFreq = <String, int>{};
    for (final term in queryTerms) {
      docFreq[term] = 0;
      for (final paper in allPapers) {
        final content = _getDocumentContent(paper);
        if (content.contains(term)) {
          docFreq[term] = (docFreq[term] ?? 0) + 1;
        }
      }
    }

    for (final paper in allPapers) {
      // Apply filters
      if (authors != null && authors.isNotEmpty) {
        if (!authors.any((author) =>
            paper.author.toLowerCase().contains(author.toLowerCase()))) {
          continue;
        }
      }

      if (field != null && field.isNotEmpty) {
        final category = _getCategoryForPaper(paper);
        if (category?.toLowerCase() != field.toLowerCase()) {
          continue;
        }
      }

      if (year != null) {
        final paperYear = int.tryParse(paper.year) ?? 0;
        if (paperYear != year) continue;
      }

      if (startYear != null || endYear != null) {
        final paperYear = int.tryParse(paper.year) ?? 0;
        if (startYear != null && paperYear < startYear) continue;
        if (endYear != null && paperYear > endYear) continue;
      }

      // Calculate BM25 score
      final score =
          _calculateBM25Score(paper, queryTerms, docFreq, allPapers.length);

      if (score > threshold) {
        results.add(SearchResult(
          paper: paper,
          score: score,
          matchedTerms: _getMatchedTerms(paper, queryTerms),
          category: _getCategoryForPaper(paper) ?? 'Unknown',
        ));
      }
    }

    // Sort by score (descending)
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // Smart search suggestions
  List<String> getSearchSuggestions(String partialQuery) {
    if (partialQuery.length < 2) return [];

    final suggestions = <String>{};
    final allPapers = _getAllPapers();
    final lowerQuery = partialQuery.toLowerCase();

    for (final paper in allPapers) {
      // Title suggestions
      final titleWords = _tokenize(paper.title.toLowerCase());
      for (final word in titleWords) {
        if (word.startsWith(lowerQuery)) {
          suggestions.add(word);
        }
      }

      // Author suggestions
      if (paper.author.toLowerCase().contains(lowerQuery)) {
        suggestions.add(paper.author);
      }

      // Keywords suggestions
      for (final keyword in paper.keywords) {
        if (keyword.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(keyword);
        }
      }
    }

    return suggestions.take(10).toList();
  }

  // Get all available filter options
  SearchFilters getAvailableFilters() {
    final allPapers = _getAllPapers();
    final authors = <String>{};
    final fields = <String>{};
    final years = <int>{};

    for (final paper in allPapers) {
      authors.add(paper.author);
      final category = _getCategoryForPaper(paper);
      if (category != null) fields.add(category);
      final year = int.tryParse(paper.year);
      if (year != null) years.add(year);
    }

    return SearchFilters(
      authors: authors.toList()..sort(),
      fields: fields.toList()..sort(),
      years: years.toList()..sort((a, b) => b.compareTo(a)),
    );
  }

  // Advanced filtering
  List<SearchResult> filterResults(
      List<SearchResult> results, SearchFilterOptions options) {
    return results.where((result) {
      final paper = result.paper;

      // Author filter
      if (options.selectedAuthors.isNotEmpty) {
        if (!options.selectedAuthors.contains(paper.author)) {
          return false;
        }
      }

      // Field filter
      if (options.selectedFields.isNotEmpty) {
        final category = _getCategoryForPaper(paper);
        if (category == null || !options.selectedFields.contains(category)) {
          return false;
        }
      }

      // Year range filter
      final paperYear = int.tryParse(paper.year) ?? 0;
      if (options.startYear != null && paperYear < options.startYear!) {
        return false;
      }
      if (options.endYear != null && paperYear > options.endYear!) {
        return false;
      }

      // Minimum citations filter
      if (options.minCitations != null &&
          paper.citations < options.minCitations!) {
        return false;
      }

      return true;
    }).toList();
  }

  // Private helper methods
  List<ResearchPaper> _getAllPapers() {
    final papers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, paperList) {
      papers.addAll(paperList);
    });
    return papers;
  }

  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 2)
        .toList();
  }

  String _getDocumentContent(ResearchPaper paper) {
    return '${paper.title} ${paper.abstract} ${paper.keywords.join(' ')}'
        .toLowerCase();
  }

  double _calculateBM25Score(ResearchPaper paper, List<String> queryTerms,
      Map<String, int> docFreq, int totalDocs) {
    final content = _getDocumentContent(paper);
    final terms = _tokenize(content);
    final avgDocLength = 100.0; // Assumed average document length
    final docLength = terms.length.toDouble();

    double score = 0.0;
    for (final term in queryTerms) {
      final tf = _termFrequency(term, terms);
      final df = docFreq[term] ?? 0;

      if (tf > 0 && df > 0) {
        final idf = math.log((totalDocs - df + 0.5) / (df + 0.5));
        final numerator = tf * (k1 + 1);
        final denominator = tf + k1 * (1 - b + b * (docLength / avgDocLength));
        score += idf * (numerator / denominator);
      }
    }

    return score;
  }

  int _termFrequency(String term, List<String> terms) {
    return terms.where((t) => t == term).length;
  }

  List<String> _getMatchedTerms(ResearchPaper paper, List<String> queryTerms) {
    final content = _getDocumentContent(paper);
    return queryTerms.where((term) => content.contains(term)).toList();
  }

  String? _getCategoryForPaper(ResearchPaper paper) {
    final categorizedPapers = _pdfService.getCategorizedPapers();
    for (final category in categorizedPapers.keys) {
      final papers = categorizedPapers[category] ?? [];
      if (papers.any((p) => p['title'] == paper.title)) {
        return category;
      }
    }
    return null;
  }

  // Faceted search
  Map<String, List<SearchResult>> getFacetedResults(String query) {
    final results = advancedSearch(query);
    final facets = <String, List<SearchResult>>{};

    for (final result in results) {
      final category = result.category;
      facets[category] = facets[category] ?? [];
      facets[category]!.add(result);
    }

    return facets;
  }

  // Auto-complete functionality
  List<String> getAutoComplete(String prefix) {
    final suggestions = <String>{};
    final allPapers = _getAllPapers();

    for (final paper in allPapers) {
      // Title auto-complete
      final titleWords = paper.title.split(' ');
      for (final word in titleWords) {
        if (word.toLowerCase().startsWith(prefix.toLowerCase()) &&
            word.length > prefix.length) {
          suggestions.add(word);
        }
      }

      // Author auto-complete
      if (paper.author.toLowerCase().startsWith(prefix.toLowerCase())) {
        suggestions.add(paper.author);
      }
    }

    return suggestions.take(8).toList();
  }
}

class SearchResult {
  final ResearchPaper paper;
  final double score;
  final List<String> matchedTerms;
  final String category;

  SearchResult({
    required this.paper,
    required this.score,
    required this.matchedTerms,
    required this.category,
  });
}

class SearchFilters {
  final List<String> authors;
  final List<String> fields;
  final List<int> years;

  SearchFilters({
    required this.authors,
    required this.fields,
    required this.years,
  });
}

class SearchFilterOptions {
  final List<String> selectedAuthors;
  final List<String> selectedFields;
  final int? startYear;
  final int? endYear;
  final int? minCitations;

  SearchFilterOptions({
    this.selectedAuthors = const [],
    this.selectedFields = const [],
    this.startYear,
    this.endYear,
    this.minCitations,
  });
}
