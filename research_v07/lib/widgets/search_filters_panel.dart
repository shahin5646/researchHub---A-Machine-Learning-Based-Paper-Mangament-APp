import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/search_providers.dart';

class SearchFiltersPanel extends ConsumerStatefulWidget {
  final VoidCallback? onApply;

  const SearchFiltersPanel({
    super.key,
    this.onApply,
  });

  @override
  ConsumerState<SearchFiltersPanel> createState() => _SearchFiltersPanelState();
}

class _SearchFiltersPanelState extends ConsumerState<SearchFiltersPanel> {
  String? _selectedCategory;
  String? _selectedInstitution;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'uploadedAt';
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);
    final institutions = ref.watch(institutionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Category Filter
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            categories.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load categories'),
              data: (categoryList) => DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select category',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...categoryList.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Institution Filter
            Text(
              'Institution',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            institutions.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Failed to load institutions'),
              data: (institutionList) => DropdownButtonFormField<String>(
                value: _selectedInstitution,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select institution',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...institutionList.map((institution) => DropdownMenuItem(
                        value: institution,
                        child: Text(institution),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedInstitution = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Date Range
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDateRangeSelector(theme),
            const SizedBox(height: 16),

            // Sort Options
            Text(
              'Sort By',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSortOptions(theme),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                      widget.onApply?.call();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Row(
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
              style: theme.textTheme.bodySmall,
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
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
    );
  }

  void _applyFilters() {
    final notifier = ref.read(searchNotifierProvider.notifier);
    notifier.updateCategory(_selectedCategory);
    notifier.updateInstitution(_selectedInstitution);
    notifier.updateDateRange(_startDate, _endDate);
    notifier.updateSortBy(_sortBy, _descending);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedInstitution = null;
      _startDate = null;
      _endDate = null;
      _sortBy = 'uploadedAt';
      _descending = true;
    });
    ref.read(searchNotifierProvider.notifier).reset();
  }
}
