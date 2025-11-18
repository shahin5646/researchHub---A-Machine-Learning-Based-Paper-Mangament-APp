import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/research_project.dart';

class ModernProjectDetailsScreen extends StatefulWidget {
  final ResearchProject project;

  const ModernProjectDetailsScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ModernProjectDetailsScreen> createState() =>
      _ModernProjectDetailsScreenState();
}

class _ModernProjectDetailsScreenState extends State<ModernProjectDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Color(0xFF374151)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.more_vert, color: Color(0xFF374151)),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.project.status)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(widget.project.status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.project.status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(widget.project.status),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title
                    Text(
                      widget.project.title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Description
                    Text(
                      widget.project.description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${(widget.project.progress * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: widget.project.progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab Bar
                      Container(
                        margin: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Color(0xFF6B7280),
                          labelStyle:
                              GoogleFonts.inter(fontWeight: FontWeight.w600),
                          tabs: [
                            Tab(text: 'Overview'),
                            Tab(text: 'Team'),
                            Tab(text: 'Timeline'),
                            Tab(text: 'Files'),
                          ],
                        ),
                      ),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildTeamTab(),
                            _buildTimelineTab(),
                            _buildFilesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Info Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Start Date',
                  '${widget.project.startDate.day}/${widget.project.startDate.month}/${widget.project.startDate.year}',
                  Icons.calendar_today,
                  Color(0xFF10B981),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'End Date',
                  '${widget.project.endDate.day}/${widget.project.endDate.month}/${widget.project.endDate.year}',
                  Icons.event,
                  Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Budget',
                  '\$${widget.project.budget.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Team Size',
                  '${widget.project.teamMembers.length} members',
                  Icons.people,
                  Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Tags
          if (widget.project.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.project.tags
                  .map((tag) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Color(0xFF6366F1).withOpacity(0.3)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: 24),
          ],

          // Funding Source
          if (widget.project.fundingSource.isNotEmpty) ...[
            Text(
              'Funding Source',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.project.fundingSource,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Members',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 16),
          if (widget.project.teamMembers.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No team members added yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.project.teamMembers
                .map((member) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _getAvatarColor(member),
                            child: Text(
                              _getInitials(member),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  'Team Member',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.more_vert,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'Timeline view coming soon',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Files',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 16),
          if (widget.project.documents.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No files uploaded yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.project.documents
                .map((doc) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description,
                                color: Color(0xFF6366F1)),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              doc,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.download,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Color(0xFF10B981);
      case 'pending':
        return Color(0xFFF59E0B);
      case 'completed':
        return Color(0xFF3B82F6);
      case 'on hold':
      case 'archived':
        return Color(0xFF6B7280);
      default:
        return Color(0xFF6366F1);
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[name.hashCode % colors.length];
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
