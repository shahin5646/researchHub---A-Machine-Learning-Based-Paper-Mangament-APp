import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/category_papers_screen.dart';
import '../services/pdf_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  final PdfService _pdfService = PdfService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  List<Map<String, dynamic>> _mlCategories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadMLCategories();
  }

  Future<void> _loadMLCategories() async {
    try {
      // Get categorized papers using ML K-Means clustering
      final categorizedData =
          await _pdfService.getCategorizedPapersWithUploads();

      setState(() {
        // Build category list with dynamic ML-discovered categories
        _mlCategories = categorizedData.entries.map((entry) {
          final categoryName = entry.key;
          final papers = entry.value;
          final categoryColor = _getCategoryColor(categoryName);

          return {
            'name': categoryName,
            'count': papers.length,
            'icon': _getCategoryIcon(categoryName),
            'color': categoryColor,
            'gradient': _getCategoryGradient(categoryColor),
          };
        }).toList();

        _isLoading = false;
      });

      debugPrint('✅ ML Categories Loaded: ${_mlCategories.length} categories');
      for (final cat in _mlCategories) {
        debugPrint('   📂 ${cat['name']}: ${cat['count']} papers');
      }
    } catch (e) {
      debugPrint('❌ Error loading ML categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();

    // ML-discovered categories - intelligent color mapping
    if (categoryLower.contains('machine') ||
        categoryLower.contains('learning') ||
        categoryLower.contains('ai') ||
        categoryLower.contains('neural')) {
      return const Color(0xFF8B5CF6); // Purple for AI/ML
    }
    if (categoryLower.contains('computer') ||
        categoryLower.contains('software') ||
        categoryLower.contains('algorithm') ||
        categoryLower.contains('code')) {
      return const Color(0xFF3B82F6); // Blue for CS
    }
    if (categoryLower.contains('medical') ||
        categoryLower.contains('health') ||
        categoryLower.contains('disease') ||
        categoryLower.contains('clinical') ||
        categoryLower.contains('patient') ||
        categoryLower.contains('diagnosis')) {
      return const Color(0xFFEF4444); // Red for Medical
    }
    if (categoryLower.contains('engineer') ||
        categoryLower.contains('iot') ||
        categoryLower.contains('robot') ||
        categoryLower.contains('automation') ||
        categoryLower.contains('sensor')) {
      return const Color(0xFF10B981); // Green for Engineering
    }
    if (categoryLower.contains('plant') ||
        categoryLower.contains('crop') ||
        categoryLower.contains('bio') ||
        categoryLower.contains('agriculture') ||
        categoryLower.contains('gene')) {
      return const Color(0xFFF59E0B); // Amber for Biotech
    }
    if (categoryLower.contains('business') ||
        categoryLower.contains('econom') ||
        categoryLower.contains('bank') ||
        categoryLower.contains('commerce') ||
        categoryLower.contains('financ')) {
      return const Color(0xFF06B6D4); // Cyan for Business
    }
    if (categoryLower.contains('educat') ||
        categoryLower.contains('teach') ||
        categoryLower.contains('learn') ||
        categoryLower.contains('student')) {
      return const Color(0xFFF97316); // Orange for Education
    }
    if (categoryLower.contains('math') ||
        categoryLower.contains('statistic') ||
        categoryLower.contains('calculus')) {
      return const Color(0xFF6366F1); // Indigo for Math
    }
    if (categoryLower.contains('data') ||
        categoryLower.contains('analytics') ||
        categoryLower.contains('visualization')) {
      return const Color(0xFFA855F7); // Purple for Data Science
    }
    if (categoryLower.contains('network') ||
        categoryLower.contains('security') ||
        categoryLower.contains('cyber')) {
      return const Color(0xFF14B8A6); // Teal for Networks
    }

    // Fallback: Generate color from category hash for consistent colors
    final hash = category.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.55).toColor();
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();

    // ML-discovered categories - intelligent icon mapping
    if (categoryLower.contains('machine') ||
        categoryLower.contains('learning') ||
        categoryLower.contains('ai') ||
        categoryLower.contains('neural')) {
      return Icons.psychology_rounded;
    }
    if (categoryLower.contains('computer') ||
        categoryLower.contains('software') ||
        categoryLower.contains('algorithm')) {
      return Icons.computer_rounded;
    }
    if (categoryLower.contains('medical') ||
        categoryLower.contains('health') ||
        categoryLower.contains('disease') ||
        categoryLower.contains('clinical')) {
      return Icons.medical_services_rounded;
    }
    if (categoryLower.contains('engineer') ||
        categoryLower.contains('iot') ||
        categoryLower.contains('robot')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (categoryLower.contains('plant') ||
        categoryLower.contains('crop') ||
        categoryLower.contains('bio') ||
        categoryLower.contains('agriculture')) {
      return Icons.eco_rounded;
    }
    if (categoryLower.contains('business') ||
        categoryLower.contains('econom') ||
        categoryLower.contains('bank') ||
        categoryLower.contains('commerce')) {
      return Icons.business_center_rounded;
    }
    if (categoryLower.contains('educat') ||
        categoryLower.contains('teach') ||
        categoryLower.contains('student')) {
      return Icons.school_rounded;
    }
    if (categoryLower.contains('math') || categoryLower.contains('statistic')) {
      return Icons.calculate_rounded;
    }
    if (categoryLower.contains('data') || categoryLower.contains('analytics')) {
      return Icons.analytics_rounded;
    }
    if (categoryLower.contains('network') ||
        categoryLower.contains('security')) {
      return Icons.security_rounded;
    }
    if (categoryLower.contains('cloud') ||
        categoryLower.contains('distributed')) {
      return Icons.cloud_rounded;
    }

    return Icons.auto_awesome_rounded; // Default for ML-discovered categories
  }

  List<Color> _getCategoryGradient(Color baseColor) {
    // Create gradient by darkening the base color
    final hsl = HSLColor.fromColor(baseColor);
    final darkerColor =
        hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    return [baseColor, darkerColor];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                        const Color(0xFFEC4899)
                      ]
                    : [
                        const Color(0xFF3B82F6),
                        const Color(0xFF8B5CF6),
                        const Color(0xFFEC4899)
                      ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Back Button with glassmorphism
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Text(
                          'Categories',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Content Section
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final padding = 24.0;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Text(
                                    'Research Fields',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Explore papers by academic field',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : const Color(0xFF64748B),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Loading or Categories List
                                  _isLoading
                                      ? _buildLoadingState(isDarkMode)
                                      : _mlCategories.isEmpty
                                          ? _buildEmptyState(isDarkMode)
                                          : ListView.separated(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: _mlCategories.length,
                                              separatorBuilder: (context,
                                                      index) =>
                                                  const SizedBox(height: 12),
                                              itemBuilder: (context, index) {
                                                return _buildModernListItem(
                                                  _mlCategories[index],
                                                  index,
                                                  isDarkMode,
                                                );
                                              },
                                            ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernListItem(
      Map<String, dynamic> category, int index, bool isDarkMode) {
    final categoryColor = category['color'] as Color;
    final gradient = category['gradient'] as List<Color>;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPapersScreen(
                category: category['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF334155).withOpacity(0.8),
                    ]
                  : [
                      Colors.white,
                      categoryColor.withOpacity(0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient Icon Container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  category['icon'],
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      category['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Count with subtitle
                    Row(
                      children: [
                        Text(
                          '${category['count']} research papers',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Discovering Categories...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                Text(
                  'K-Means ML Clustering',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 64,
                color: isDarkMode
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Categories Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add research papers to discover\\ncategories automatically',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
