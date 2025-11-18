import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../data/research_papers_data.dart';
// Add this import at the top of the file
import '../screens/category_papers_screen.dart';

// Change class name from CategoryScreen to CategorySection
class CategorySection extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

// Update state class name
class _CategorySectionState extends State<CategorySection> {
  // Redesign categories based on fields and counts
  final List<Map<String, dynamic>> fieldCategories = [
    {
      'name': 'Computer Science',
      'count': 39,
      'icon': Icons.computer,
      'color': Colors.blue[50],
      'iconColor': Colors.blue[400],
    },
    {
      'name': 'Business & Economics',
      'count': 3,
      'icon': Icons.business_center,
      'color': Colors.green[50],
      'iconColor': Colors.green[400],
    },
    {
      'name': 'Education',
      'count': 2,
      'icon': Icons.school,
      'color': Colors.orange[50],
      'iconColor': Colors.orange[400],
    },
    {
      'name': 'Biomedical Science',
      'count': 1,
      'icon': Icons.biotech,
      'color': Colors.pink[50],
      'iconColor': Colors.pink[400],
    },
  ];

  List<CategoryItem> get categories {
    return fieldCategories.map((cat) {
      return CategoryItem(
        icon: cat['icon'],
        title: cat['name'],
        subtitle: '${cat['count']} Papers',
        color: cat['color'],
        iconColor: cat['iconColor'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final isSelected = widget.selectedIndex == index;
        return _buildCategoryCard(categories[index], index, isSelected);
      },
    );
  }

  Widget _buildCategoryCard(CategoryItem category, int index, bool isSelected) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            widget.onCategorySelected(index);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryPapersScreen(
                  category: category.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.3)
                  : category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      size: 32,
                      color: category.iconColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Keep CategoryItem class as is
class CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  CategoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });
}
