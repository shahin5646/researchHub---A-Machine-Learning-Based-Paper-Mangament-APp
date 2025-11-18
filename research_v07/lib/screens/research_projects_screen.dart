import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/research_project.dart';
import '../models/task.dart';
import '../models/activity_log.dart';

class ResearchProjectsScreen extends StatefulWidget {
  const ResearchProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ResearchProjectsScreen> createState() => _ResearchProjectsScreenState();
}

class _ResearchProjectsScreenState extends State<ResearchProjectsScreen> {
  int _selectedTabIndex = 0;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'icon': Icons.apps},
    {'label': 'Ongoing', 'icon': Icons.timelapse},
    {'label': 'Completed', 'icon': Icons.check_circle},
    {'label': 'Collaborative', 'icon': Icons.handshake},
    {'label': 'Funded', 'icon': Icons.attach_money},
  ];
  Box<ResearchProject>? projectsBox;
  Box<Task>? tasksBox;
  Box<ActivityLog>? activityLogBox;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Last Updated';
  String _groupBy = 'Status';

  @override
  void initState() {
    super.initState();
    _openHiveBoxes();
  }

  Future<void> _openHiveBoxes() async {
    projectsBox = await Hive.openBox<ResearchProject>('projects');
    tasksBox = await Hive.openBox<Task>('tasks');
    activityLogBox = await Hive.openBox<ActivityLog>('activity_logs');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (projectsBox == null || tasksBox == null || activityLogBox == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final projects = projectsBox!.values.toList();
    final filteredProjects =
        _getSortedAndGroupedProjects(_filterProjects(projects));
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Research Projects',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: () => _showSearchModal(context),
                      tooltip: 'Search',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: () => _showFilterModal(context),
                      tooltip: 'Filter',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Modern minimal tab system
              Container(
                height: 44,
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(4),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final selected = index == _selectedTabIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab['icon'],
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              tab['label'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Modern statistics cards
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                          'Active',
                          _countByStatus(projects, 'Active').toString(),
                          const Color(0xFF10B981),
                          Icons.circle),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E7EB),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildStatusCard(
                          'Pending',
                          _countByStatus(projects, 'Pending').toString(),
                          const Color(0xFFF59E0B),
                          Icons.circle),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E7EB),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildStatusCard(
                          'Completed',
                          _countByStatus(projects, 'Completed').toString(),
                          const Color(0xFF3B82F6),
                          Icons.circle),
                    ),
                  ],
                ),
              ),
              // Sort and filter bar
              _buildSortAndGroupBar(),
              Expanded(
                child: filteredProjects.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return Dismissible(
                            key: ValueKey(project.id),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 32),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.archive,
                                  color: Colors.white, size: 32),
                            ),
                            onDismissed: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // Mark as completed
                                project.status = 'Completed';
                                project.lastUpdated = DateTime.now();
                                await project.save();
                                setState(() {});
                              } else {
                                // Archive (remove from box)
                                await project.delete();
                                setState(() {});
                              }
                            },
                            child: _buildProjectCard(project),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showProjectCreationModal(context),
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 2,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  int _countByStatus(List<ResearchProject> projects, String status) {
    return projects.where((p) => p.status == status).length;
  }

  List<ResearchProject> _filterProjects(List<ResearchProject> projects) {
    final tabLabel = _tabs[_selectedTabIndex]['label'];
    List<ResearchProject> filtered = projects;
    if (tabLabel != 'All') {
      filtered = filtered.where((p) => p.status == tabLabel).toList();
    }
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((p) => p.tags.contains(_selectedCategory)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  Widget _buildStatusCard(
      String label, String count, Color color, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = _tabs.indexWhere((tab) => tab['label'] == label);
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Icon(icon, color: color, size: 8),
              const SizedBox(width: 8),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              size: 60,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No projects yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showProjectCreationModal(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Create Project',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern sort and filter bar
  Widget _buildSortAndGroupBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            isDense: true,
            underline: const SizedBox(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            items: [
              DropdownMenuItem(
                  value: 'Last Updated',
                  child: Text('Last Updated',
                      style: GoogleFonts.inter(fontSize: 13))),
              DropdownMenuItem(
                  value: 'Due Date',
                  child:
                      Text('Due Date', style: GoogleFonts.inter(fontSize: 13))),
              DropdownMenuItem(
                  value: 'Project Name',
                  child: Text('Project Name',
                      style: GoogleFonts.inter(fontSize: 13))),
              DropdownMenuItem(
                  value: 'Creation Date',
                  child: Text('Creation Date',
                      style: GoogleFonts.inter(fontSize: 13))),
            ],
            onChanged: (val) {
              setState(() => _sortBy = val ?? 'Last Updated');
            },
          ),
          const Spacer(),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFFE5E7EB),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Icon(Icons.group_work_outlined,
              size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _groupBy,
            isDense: true,
            underline: const SizedBox(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
            items: [
              DropdownMenuItem(
                  value: 'Status',
                  child:
                      Text('Status', style: GoogleFonts.inter(fontSize: 13))),
              DropdownMenuItem(
                  value: 'Lead',
                  child: Text('Lead', style: GoogleFonts.inter(fontSize: 13))),
              DropdownMenuItem(
                  value: 'Due Date',
                  child:
                      Text('Due Date', style: GoogleFonts.inter(fontSize: 13))),
            ],
            onChanged: (val) {
              setState(() => _groupBy = val ?? 'Status');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ResearchProject project) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _statusColor(project.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 6, color: _statusColor(project.status)),
                        const SizedBox(width: 4),
                        Text(
                          project.status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _statusColor(project.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        size: 20, color: Color(0xFF6B7280)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined,
                                size: 18, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            Text('View Details',
                                style: GoogleFonts.inter(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'tasks',
                        child: Row(
                          children: [
                            const Icon(Icons.checklist_outlined,
                                size: 18, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            Text('View Tasks',
                                style: GoogleFonts.inter(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _showProjectDetails(project);
                      } else if (value == 'tasks') {
                        // TODO: Show tasks modal
                      } else if (value == 'delete') {
                        _confirmDeleteProject(context, project);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Progress',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${project.progress.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: _statusColor(project.status),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Metadata row
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(project.endDate),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline,
                      size: 14, color: const Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${project.teamMembers.length} members',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProject(BuildContext context, ResearchProject project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete Project',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${project.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await project.delete();
              setState(() {});
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Avatar stack widget
  Widget _buildAvatarStack(List<String> members) {
    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          for (int i = 0; i < (members.length > 3 ? 3 : members.length); i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                child: Text(
                  members[i][0],
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (members.length > 3)
            Positioned(
              left: 3 * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[400],
                child: Text('+${members.length - 3}',
                    style: GoogleFonts.poppins(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
      case 'Ongoing':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      case 'Collaborative':
        return Colors.purple;
      case 'Funded':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter Projects',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'AI', 'ML', 'Robotics', 'Other'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6B7280),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        String tempQuery = _searchQuery;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Search Projects',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter project name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                            color: Color(0xFF3B82F6), width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                    onChanged: (val) => tempQuery = val,
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _searchQuery = tempQuery);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Search',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProjectDetails(ResearchProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        final Color primaryBlue = const Color(0xFF3B82F6);
        final Color darkSlate = const Color(0xFF1F2937);
        final Color mediumGray = const Color(0xFF6B7280);
        final Color lightGray = const Color(0xFFF9FAFB);
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Project Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkSlate,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _showProjectCreationModal(context,
                            editingProject: project);
                      },
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        foregroundColor: primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      style: IconButton.styleFrom(
                        foregroundColor: mediumGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Title and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkSlate,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(project.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _statusColor(project.status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 6, color: _statusColor(project.status)),
                          const SizedBox(width: 4),
                          Text(
                            project.status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(project.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                if (project.description.isNotEmpty) ...[
                  Text(
                    project.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: mediumGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: mediumGray,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${project.progress.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkSlate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: project.progress / 100,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: _statusColor(project.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Metadata grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: mediumGray),
                            const SizedBox(height: 8),
                            Text(
                              'Due Date',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: mediumGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(project.endDate),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.people_outline,
                                size: 16, color: mediumGray),
                            const SizedBox(height: 8),
                            Text(
                              'Team',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: mediumGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${project.teamMembers.length} members',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Guided project creation modal
  void _showProjectCreationModal(BuildContext context,
      {ResearchProject? editingProject}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final Color primaryBlue = const Color(0xFF1565C0);
        final Color darkSlate = const Color(0xFF222B45);
        final Color lightGray = const Color(0xFFF5F6FA);
        final Color borderGray = const Color(0xFFE0E3EA);
        TextEditingController titleController =
            TextEditingController(text: editingProject?.title ?? '');
        TextEditingController descriptionController =
            TextEditingController(text: editingProject?.description ?? '');
        DateTime? endDate = editingProject?.endDate;
        final bool isEditing = editingProject != null;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.add_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isEditing ? '✏️ Edit Project' : 'Create New Project',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Project Title
                    Text('Project Title',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter project title',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: lightGray,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: darkSlate),
                    ),
                    const SizedBox(height: 18),
                    // Description
                    Text('Description',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Describe your project...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                        filled: true,
                        fillColor: lightGray,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryBlue, width: 2),
                        ),
                      ),
                      style: GoogleFonts.inter(color: darkSlate),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 18),
                    // Due Date
                    Text('Due Date',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.calendar_today_outlined,
                              color: primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: lightGray,
                              foregroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Text(
                              endDate == null
                                  ? 'Select Date'
                                  : _formatDate(endDate!),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    endDate == null ? primaryBlue : darkSlate,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          isEditing
                              ? Icons.save
                              : Icons.check_circle_outline_rounded,
                          size: 24,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            isEditing ? 'Update Project' : 'Create Project',
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                        ),
                        onPressed: () async {
                          if (titleController.text.isNotEmpty &&
                              descriptionController.text.isNotEmpty &&
                              endDate != null) {
                            if (isEditing) {
                              final updatedProject = editingProject.copyWith(
                                title: titleController.text,
                                description: descriptionController.text,
                                endDate: endDate,
                                lastUpdated: DateTime.now(),
                              );
                              await editingProject.delete();
                              await projectsBox?.add(updatedProject);
                            } else {
                              final newProject = ResearchProject(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                title: titleController.text,
                                description: descriptionController.text,
                                status: 'Active',
                                progress: 0,
                                startDate: DateTime.now(),
                                endDate: endDate!,
                                lastUpdated: DateTime.now(),
                                teamMembers: [],
                                tags: [],
                              );
                              await projectsBox?.add(newProject);
                            }
                            setState(() {});
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Sorting and grouping logic
  List<ResearchProject> _getSortedAndGroupedProjects(
      List<ResearchProject> projects) {
    List<ResearchProject> sorted = List.from(projects);
    switch (_sortBy) {
      case 'Last Updated':
        sorted.sort((a, b) =>
            (b.lastUpdated ?? b.endDate).compareTo(a.lastUpdated ?? a.endDate));
        break;
      case 'Due Date':
        sorted.sort((a, b) => a.endDate.compareTo(b.endDate));
        break;
      case 'Project Name':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Creation Date':
        sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
    }
    // Grouping can be implemented as needed
    return sorted;
  }
}
