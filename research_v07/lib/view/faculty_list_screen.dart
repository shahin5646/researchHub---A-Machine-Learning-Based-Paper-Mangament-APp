import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/faculty.dart';
import '../data/faculty_data.dart';
import '../screens/faculty_profile_screen.dart';
import '../common_widgets/safe_image.dart';

class FacultyListScreen extends StatefulWidget {
  const FacultyListScreen({super.key});

  @override
  State<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen>
    with TickerProviderStateMixin {
  String _selectedDepartment = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Enhanced filtering to include search functionality
  List<Faculty> get _filteredFaculty {
    List<Faculty> filtered = facultyMembers;

    // Filter by department
    if (_selectedDepartment != 'All') {
      filtered = filtered.where((faculty) {
        String department = faculty.department.toUpperCase();
        if (_selectedDepartment == 'CSE') {
          return department.contains('COMPUTER SCIENCE');
        } else if (_selectedDepartment == 'SWE') {
          return department.contains('SOFTWARE');
        } else if (_selectedDepartment == 'PHARMACY') {
          return department.contains('PHARMACY');
        } else if (_selectedDepartment == 'EEE') {
          return department.contains('ELECTRICAL');
        }
        return false;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((faculty) {
        return faculty.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            faculty.designation
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            faculty.department
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchSection(isDarkMode),
            _buildFilterChips(isDarkMode),
            Expanded(child: _buildModernFacultyList(isDarkMode)),
          ],
        ),
      ),
    );
  }

  // Modern AppBar with clean design
  PreferredSizeWidget _buildModernAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      systemOverlayStyle:
          isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Research Faculty',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '${_filteredFaculty.length} ${_filteredFaculty.length == 1 ? 'Member' : 'Members'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
          onPressed: () => _showFilterOptions(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Search section with modern design
  Widget _buildSearchSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.inter(
          fontSize: 16,
          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search faculty by name, title, or department...',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Modern filter chips with improved design
  Widget _buildFilterChips(bool isDarkMode) {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildModernChip('All', isDarkMode),
          _buildModernChip('CSE', isDarkMode),
          _buildModernChip('SWE', isDarkMode),
          _buildModernChip('PHARMACY', isDarkMode),
          _buildModernChip('EEE', isDarkMode),
        ],
      ),
    );
  }

  // Modern chip design
  Widget _buildModernChip(String label, bool isDarkMode) {
    final isSelected = _selectedDepartment == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedDepartment = label);
          },
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF2563EB))
                  : (isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDarkMode
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF2563EB))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.grey[300] : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern faculty list with professional layout
  Widget _buildModernFacultyList(bool isDarkMode) {
    if (_filteredFaculty.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredFaculty.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
        indent: 72, // Align with content after avatar
      ),
      itemBuilder: (context, index) {
        final faculty = _filteredFaculty[index];
        return _buildModernFacultyListItem(faculty, isDarkMode);
      },
    );
  }

  // Modern faculty list item with horizontal layout
  Widget _buildModernFacultyListItem(Faculty faculty, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToProfile(faculty),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              // Profile Image (Left)
              Hero(
                tag: 'faculty_${faculty.employeeId}',
                child: SafeCircleAvatar(
                  radius: 28,
                  imagePath: faculty.imageUrl,
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(width: 16),

              // Name and Designation (Center)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      faculty.designation,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDepartmentAbbreviation(faculty.department),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action Button (Right)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]?.withOpacity(0.5)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No faculty members found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDepartment = 'All';
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: Text(
              'Clear all filters',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getDepartmentAbbreviation(String department) {
    if (department.contains('Computer Science')) return 'CSE';
    if (department.contains('Software')) return 'SWE';
    if (department.contains('Pharmacy')) return 'PHARMACY';
    if (department.contains('Electrical')) return 'EEE';
    return department.split(' ').take(2).join(' ');
  }

  void _navigateToProfile(Faculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacultyProfileScreen(faculty: faculty),
      ),
    );
  }

  void _showFilterOptions() {
    // Placeholder for future filter options
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Advanced filter options coming soon!',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
