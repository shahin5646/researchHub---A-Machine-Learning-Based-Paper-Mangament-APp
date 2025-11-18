import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/firebase_paper.dart';
import '../../providers/search_providers.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();

  bool _showFilters = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String? _selectedInstitution;
  final List<String> _selectedKeywords = [];
  String _sortBy = 'uploadedAt';
  bool _descending = true;

  @override
  void dispose() {
    _searchController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchNotifierProvider);
    final searchResults = ref.watch(currentSearchResultsProvider);
    final popularKeywords = ref.watch(popularKeywordsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        actions: [
          IconButton(
            icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _resetFilters,
            tooltip: 'Reset All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(theme),

          // Filters Panel
          if (_showFilters) _buildFiltersPanel(theme),

          // Search Results or Initial State
          Expanded(
            child: searchState.query.isEmpty
                ? _buildInitialState(theme, popularKeywords, searchHistory)
                : _buildSearchResults(searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final suggestions =
        ref.watch(searchSuggestionsProvider(_searchController.text));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search papers, authors, keywords...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          ref
                              .read(searchNotifierProvider.notifier)
                              .updateQuery('');
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) {
              _performSearch();
            },
          ),

          // Suggestions
          if (_searchController.text.length >= 2)
            suggestions.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (suggestionsList) {
                if (suggestionsList.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestionsList.map((suggestion) {
                      return InkWell(
                        onTap: () {
                          _searchController.text = suggestion;
                          _performSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            suggestion,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(ThemeData theme) {
    final categories = ref.watch(categoriesProvider);
    final institutions = ref.watch(institutionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category Filter
            categories.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categoryList) => _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: categoryList,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Institution Filter
            institutions.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (institutionList) => _buildDropdown(
                label: 'Institution',
                value: _selectedInstitution,
                items: institutionList,
                onChanged: (value) {
                  setState(() {
                    _selectedInstitution = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Date Range Filter
            _buildDateRangeFilter(theme),
            const SizedBox(height: 12),

            // Keywords Filter
            _buildKeywordsFilter(theme),
            const SizedBox(height: 12),

            // Sort Options
            _buildSortOptions(theme),
            const SizedBox(height: 16),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _startDate != null
                      ? dateFormat.format(_startDate!)
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _endDate != null ? dateFormat.format(_endDate!) : 'End Date',
                ),
              ),
            ),
          ],
        ),
        if (_startDate != null || _endDate != null)
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
            },
            child: const Text('Clear Dates'),
          ),
      ],
    );
  }

  Widget _buildKeywordsFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Keywords', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  hintText: 'Add keyword',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addKeyword(value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _addKeyword(_keywordController.text),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (_selectedKeywords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedKeywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedKeywords.remove(keyword);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort By', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Recent'),
              selected: _sortBy == 'uploadedAt',
              onSelected: (selected) {
                setState(() {
                  _sortBy = 'uploadedAt';
                  _descending = true;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Most Liked'),
              selected: _sortBy == 'likesCount',
              onSelected: (selected) {
                setState(() {
                  _sortBy = 'likesCount';
                  _descending = true;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Most Viewed'),
              selected: _sortBy == 'viewsCount',
              onSelected: (selected) {
                setState(() {
                  _sortBy = 'viewsCount';
                  _descending = true;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Title A-Z'),
              selected: _sortBy == 'title',
              onSelected: (selected) {
                setState(() {
                  _sortBy = 'title';
                  _descending = false;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInitialState(
    ThemeData theme,
    AsyncValue<List<String>> popularKeywords,
    List<String> searchHistory,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search History
          if (searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(advancedSearchServiceProvider)
                        .clearSearchHistory();
                    setState(() {});
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...searchHistory.take(5).map((query) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    ref
                        .read(advancedSearchServiceProvider)
                        .removeFromHistory(query);
                    setState(() {});
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch();
                },
              );
            }),
            const Divider(height: 32),
          ],

          // Popular Keywords
          popularKeywords.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (keywords) {
              if (keywords.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending Keywords',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: keywords.map((keyword) {
                      return ActionChip(
                        label: Text(keyword),
                        onPressed: () {
                          _searchController.text = keyword;
                          _performSearch();
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<FirebasePaper>> searchResults) {
    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
      data: (papers) {
        if (papers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('No papers found'),
                const SizedBox(height: 8),
                const Text('Try adjusting your search filters'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            return _buildPaperCard(papers[index]);
          },
        );
      },
    );
  }

  Widget _buildPaperCard(FirebasePaper paper) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Convert FirebasePaper to ResearchPaper or update PaperDetailScreen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening paper: ${paper.title}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                paper.authors.join(', '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(paper.uploadedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (paper.description != null &&
                  paper.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  paper.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.visibility,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${paper.views}'),
                  const SizedBox(width: 16),
                  Icon(Icons.thumb_up,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${paper.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.comment,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${paper.commentsCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addKeyword(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isNotEmpty && !_selectedKeywords.contains(trimmed)) {
      setState(() {
        _selectedKeywords.add(trimmed);
        _keywordController.clear();
      });
    }
  }

  void _performSearch() {
    final notifier = ref.read(searchNotifierProvider.notifier);
    notifier.updateQuery(_searchController.text);
    notifier.updateCategory(_selectedCategory);
    notifier.updateDateRange(_startDate, _endDate);
    notifier.updateInstitution(_selectedInstitution);
    notifier.updateKeywords(
        _selectedKeywords.isNotEmpty ? _selectedKeywords : null);
    notifier.updateSortBy(_sortBy, _descending);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedInstitution = null;
      _startDate = null;
      _endDate = null;
      _selectedKeywords.clear();
      _sortBy = 'uploadedAt';
      _descending = true;
    });
    ref.read(searchNotifierProvider.notifier).reset();
  }
}
