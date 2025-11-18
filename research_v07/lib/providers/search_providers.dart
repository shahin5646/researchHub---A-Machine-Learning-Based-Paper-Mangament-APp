import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_paper.dart';
import '../models/user_profile.dart';
import '../services/advanced_search_service.dart';

/// Provider for AdvancedSearchService
final advancedSearchServiceProvider = Provider<AdvancedSearchService>((ref) {
  return AdvancedSearchService();
});

/// Provider for paper search results
final paperSearchResultsProvider =
    FutureProvider.family<List<FirebasePaper>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.watch(advancedSearchServiceProvider);

  return service.searchPapers(
    query: params['query'] as String? ?? '',
    category: params['category'] as String?,
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
    authorId: params['authorId'] as String?,
    institution: params['institution'] as String?,
    keywords: params['keywords'] as List<String>?,
    sortBy: params['sortBy'] as String? ?? 'uploadedAt',
    descending: params['descending'] as bool? ?? true,
    limit: params['limit'] as int? ?? 20,
  );
});

/// Provider for user search results
final userSearchResultsProvider =
    FutureProvider.family<List<UserProfile>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.watch(advancedSearchServiceProvider);

  return service.searchUsers(
    query: params['query'] as String? ?? '',
    institution: params['institution'] as String?,
    department: params['department'] as String?,
    position: params['position'] as String?,
    researchInterests: params['researchInterests'] as List<String>?,
    sortBy: params['sortBy'] as String? ?? 'followersCount',
    descending: params['descending'] as bool? ?? true,
    limit: params['limit'] as int? ?? 20,
  );
});

/// Provider for search suggestions
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>(
  (ref, query) async {
    final service = ref.watch(advancedSearchServiceProvider);
    return service.getSearchSuggestions(query);
  },
);

/// Provider for popular keywords
final popularKeywordsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(advancedSearchServiceProvider);
  return service.getPopularKeywords(limit: 15);
});

/// Provider for all categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(advancedSearchServiceProvider);
  return service.getCategories();
});

/// Provider for all institutions
final institutionsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(advancedSearchServiceProvider);
  return service.getInstitutions();
});

/// Provider for search history
final searchHistoryProvider = Provider<List<String>>((ref) {
  final service = ref.watch(advancedSearchServiceProvider);
  return service.getSearchHistory();
});

/// Search state notifier for managing search parameters
class SearchState {
  final String query;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? authorId;
  final String? institution;
  final List<String>? keywords;
  final String sortBy;
  final bool descending;

  const SearchState({
    this.query = '',
    this.category,
    this.startDate,
    this.endDate,
    this.authorId,
    this.institution,
    this.keywords,
    this.sortBy = 'uploadedAt',
    this.descending = true,
  });

  SearchState copyWith({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? authorId,
    String? institution,
    List<String>? keywords,
    String? sortBy,
    bool? descending,
  }) {
    return SearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      authorId: authorId ?? this.authorId,
      institution: institution ?? this.institution,
      keywords: keywords ?? this.keywords,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'category': category,
      'startDate': startDate,
      'endDate': endDate,
      'authorId': authorId,
      'institution': institution,
      'keywords': keywords,
      'sortBy': sortBy,
      'descending': descending,
    };
  }
}

/// Notifier for managing search state
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void updateAuthorId(String? authorId) {
    state = state.copyWith(authorId: authorId);
  }

  void updateInstitution(String? institution) {
    state = state.copyWith(institution: institution);
  }

  void updateKeywords(List<String>? keywords) {
    state = state.copyWith(keywords: keywords);
  }

  void updateSortBy(String sortBy, bool descending) {
    state = state.copyWith(sortBy: sortBy, descending: descending);
  }

  void reset() {
    state = const SearchState();
  }
}

/// Provider for search state notifier
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

/// Provider for current search results based on search state
final currentSearchResultsProvider =
    FutureProvider<List<FirebasePaper>>((ref) async {
  final searchState = ref.watch(searchNotifierProvider);
  final service = ref.watch(advancedSearchServiceProvider);

  return service.searchPapers(
    query: searchState.query,
    category: searchState.category,
    startDate: searchState.startDate,
    endDate: searchState.endDate,
    authorId: searchState.authorId,
    institution: searchState.institution,
    keywords: searchState.keywords,
    sortBy: searchState.sortBy,
    descending: searchState.descending,
  );
});
