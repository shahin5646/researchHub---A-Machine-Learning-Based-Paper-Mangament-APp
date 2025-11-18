/// Upload Paper Screen
///
/// This screen provides a modern, accessible, and professional interface for uploading research papers.
/// Features include drag & drop file upload, animated UI, category/visibility selection, tag chips, and more.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart' as classic_provider;
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../theme/app_theme.dart';
import '../../models/paper_models.dart';
import '../../services/paper_service.dart';
import '../../services/role_access_service.dart';
import '../../main.dart';

/// Main widget for the upload paper screen.
class AddPaperScreen extends ConsumerStatefulWidget {
  const AddPaperScreen({super.key});

  @override
  ConsumerState<AddPaperScreen> createState() => _AddPaperScreenState();
}

/// State for AddPaperScreen, manages form, animation, and upload logic.
class _AddPaperScreenState extends ConsumerState<AddPaperScreen>
    with TickerProviderStateMixin {
  // ------------------------------
  // Controllers & State
  // ------------------------------
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _authorsController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _journalController = TextEditingController();
  final _doiController = TextEditingController();
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// List of tags selected by the user.
  final List<String> _selectedTags = [];

  // Form state
  String _selectedCategory = 'computer_science';
  String _selectedCategoryName = 'Computer Science';
  PaperVisibility _selectedVisibility = PaperVisibility.public;
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  /// List of available categories for selection.
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'computer_science',
      'name': 'Computer Science',
      'icon': Icons.computer_rounded,
      'color': const Color(0xFF6366F1),
      'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
    },
    {
      'id': 'engineering',
      'name': 'Engineering',
      'icon': Icons.precision_manufacturing_rounded,
      'color': const Color(0xFF10B981),
      'gradient': [const Color(0xFF10B981), const Color(0xFF059669)]
    },
    {
      'id': 'business',
      'name': 'Business',
      'icon': Icons.business_center_rounded,
      'color': const Color(0xFFEF4444),
      'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)]
    },
    {
      'id': 'science',
      'name': 'Natural Sciences',
      'icon': Icons.science_rounded,
      'color': const Color(0xFF8B5CF6),
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
    },
    {
      'id': 'social_sciences',
      'name': 'Social Sciences',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFFF59E0B),
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFEA580C)]
    },
  ];

  // Add a field to store file bytes for web
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    // Ensure _selectedCategoryName matches the default id
    final defaultCategory = _categories.firstWhere(
        (c) => c['id'] == _selectedCategory,
        orElse: () => _categories.first);
    _selectedCategoryName = defaultCategory['name'];
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Dispose controllers
    _titleController.dispose();
    _abstractController.dispose();
    _authorsController.dispose();
    _keywordsController.dispose();
    _journalController.dispose();
    _doiController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Handles file picking and triggers animation.
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // Always load bytes for both web and mobile
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (100MB limit)
        if (file.size > 100 * 1024 * 1024) {
          if (mounted) {
            _showErrorSnackBar('File size must be less than 100MB');
          }
          return;
        }

        // Ensure we have the bytes for both platforms
        if (file.bytes == null) {
          _showErrorSnackBar('Could not read file data');
          return;
        }

        setState(() {
          _selectedFileBytes = file.bytes;
          _selectedFileName = file.name;
          _selectedFileSize = file.size;
          _selectedFilePath = kIsWeb ? null : file.path;
        });

        HapticFeedback.lightImpact();
        // Trigger success animation
        _pulseController.stop();
        _pulseController.reset();
        await _pulseController.forward();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error picking file: $e');
      }
    }
  }

  /// Shows an error snackbar with the given message.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a success snackbar with the given message.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Clears the selected file state
  void _clearSelectedFile() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedFilePath = null;
      _selectedFileSize = null;
    });
  }

  /// Handles form submission and paper upload.
  Future<void> _submitPaper() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileBytes == null && _selectedFilePath == null) {
      _showErrorSnackBar('Please select a file');
      return;
    }

    // Ensure we have either file path (for native platforms) or bytes (for web)
    if (kIsWeb && _selectedFileBytes == null) {
      _showErrorSnackBar('File data is not available');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = ref.read(authProvider).currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Parse authors, keywords, and tags
      final authors = _authorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final keywords = _keywordsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final tags = _selectedTags;

      // Create paper object
      final paper = ResearchPaper(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        authors: authors,
        abstract: _abstractController.text.trim().isNotEmpty
            ? _abstractController.text.trim()
            : null,
        keywords: keywords,
        category: _selectedCategory,
        filePath: _selectedFilePath ??
            _selectedFileName ??
            '', // fallback to name for web
        publishedDate: DateTime.now(),
        uploadedAt: DateTime.now(),
        uploadedBy: currentUser.id,
        visibility: _selectedVisibility,
        tags: tags,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        journal: _journalController.text.trim().isNotEmpty
            ? _journalController.text.trim()
            : null,
        doi: _doiController.text.trim().isNotEmpty
            ? _doiController.text.trim()
            : null,
        fileType: _selectedFileName?.split('.').last ?? 'pdf',
        fileSize: _selectedFileSize ?? 0, // Set the file size
      );

      debugPrint('Uploading paper: ${paper.title}');

      // Get the existing PaperService from the provider instead of creating a new one
      final paperService =
          classic_provider.Provider.of<PaperService>(context, listen: false);

      // For web platform, pass the file bytes
      final success = await paperService.addPaper(
        paper,
        fileBytes: _selectedFileBytes, // Pass the bytes for web platform
      );

      if (success && mounted) {
        _showSuccessSnackBar('🎉 Paper uploaded successfully!');

        // Show a celebration dialog with proper delay
        showDialog(
          context: context,
          barrierDismissible: true, // Allow closing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button at the top right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '🎉 Success!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your paper has been uploaded successfully and is now available in your papers list.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Close button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context)
                              .pop(true); // Return to previous screen
                        },
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      // View My Papers button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context)
                              .pop(true); // Return to previous screen
                          // Navigate to my papers screen
                          Navigator.pushNamed(context, '/my-papers');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'View My Papers',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      } else if (mounted) {
        _showErrorSnackBar('Failed to upload paper');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error uploading paper: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Minimal, borderless text field
  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkSlate)),
            if (required) ...[
              const SizedBox(width: 2),
              const Text('*',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.darkSlate),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 15, color: AppTheme.mediumGray),
            filled: true,
            fillColor: AppTheme.offWhite,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Minimal dropdown with overflow prevention
  Widget _buildMinimalDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkSlate)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkSlate,
                    ),
                    dropdownColor: Colors.white,
                    selectedItemBuilder: (BuildContext context) {
                      return items.map((item) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkSlate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    items: items
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => v != null ? onChanged(v) : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null ||
        !RoleBasedAccessControl.canUploadPapers(currentUser.role)) {
      return _buildAccessDeniedScreen(isDarkMode);
    }

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Upload Card
              Container(
                width: 480,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // File Upload Icon
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        size: 48,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select Paper File',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PDF, DOC, DOCX files supported',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        child: const Text('Choose File'),
                      ),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.primaryPurple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Paper Details Card
              Container(
                width: 480,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paper Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMinimalTextField(
                        controller: _titleController,
                        label: 'Paper Title',
                        hint: 'Enter paper title',
                        required: true,
                      ),
                      const SizedBox(height: 18),
                      _buildMinimalTextField(
                        controller: _authorsController,
                        label: 'Authors',
                        hint: 'Separate multiple authors with commas',
                        required: true,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMinimalDropdown(
                              label: 'Category',
                              value: _selectedCategoryName,
                              items: _categories
                                  .map((c) => c['name'] as String)
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoryName = val;
                                  _selectedCategory = _categories.firstWhere(
                                      (c) => c['name'] == val)['id'];
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMinimalDropdown(
                              label: 'Visibility',
                              value: _selectedVisibility.name[0].toUpperCase() +
                                  _selectedVisibility.name.substring(1),
                              items: ['Public', 'Private', 'Restricted'],
                              onChanged: (val) {
                                setState(() {
                                  _selectedVisibility = PaperVisibility.values
                                      .firstWhere((v) =>
                                          v.name.toLowerCase() ==
                                          val.toLowerCase());
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildMinimalTextField(
                        controller: _abstractController,
                        label: 'Abstract',
                        hint: 'Brief summary of the paper',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 18),
                      _buildMinimalTextField(
                        controller: _keywordsController,
                        label: 'Keywords',
                        hint: 'Separate keywords with commas',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMinimalTextField(
                              controller: _journalController,
                              label: 'Journal',
                              hint: 'Journal name',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMinimalTextField(
                              controller: _doiController,
                              label: 'DOI',
                              hint: '10.xxxx/xxxxx',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPaper,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Submit Paper'),
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

  /// Builds the modern app bar for the upload screen.
  Widget _buildModernAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Paper',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Share your research with the world',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.white60 : Colors.black54,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
      ),
    );
  }

  /// Builds the access denied screen for unauthorized users.
  Widget _buildAccessDeniedScreen(bool isDarkMode) {
    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your role does not have permission to upload papers. Please contact an administrator for assistance.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a section card with a title, subtitle, and child widget.
  Widget _buildSectionCard(
      String title, String subtitle, IconData icon, bool isDarkMode,
      {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Builds the hero file upload section with animation.
  Widget _buildHeroFileUploadSection(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              AppTheme.darkSlate.withOpacity(0.85),
                              AppTheme.primaryPurple.withOpacity(0.18),
                            ]
                          : [
                              Colors.white.withOpacity(0.85),
                              AppTheme.primaryBlue.withOpacity(0.10),
                            ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.10),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: _selectedFileName == null
                      ? _buildModernDragDropArea(isDarkMode)
                      : _buildFilePreview(isDarkMode),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modernized drag & drop area with floating action and animation
  Widget _buildModernDragDropArea(bool isDarkMode) {
    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: 260,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.13),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppTheme.darkSlate.withOpacity(0.85),
                    AppTheme.primaryPurple.withOpacity(0.10),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    AppTheme.primaryBlue.withOpacity(0.08),
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              width: 100 + 10 * _pulseAnimation.value,
              height: 100 + 10 * _pulseAnimation.value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Drag & drop or tap to upload',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.darkSlate,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PDF, DOC, DOCX up to 100MB',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : AppTheme.mediumGray,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pickFile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.13),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Browse Files',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the file preview widget after file selection.
  Widget _buildFilePreview(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getFileIcon(_selectedFileName!),
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFileName!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatFileSize(_selectedFileSize ?? 0),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to upload',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFileName = null;
                  _selectedFilePath = null;
                  _selectedFileSize = null;
                  _selectedFileBytes = null; // clear bytes on remove
                });
                _pulseController.repeat(reverse: true);
              },
              icon: Icon(
                Icons.close_rounded,
                color: isDarkMode ? Colors.white60 : Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the paper details section (title, authors, abstract, etc).
  Widget _buildPaperDetailsSection(bool isDarkMode) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _titleController,
          label: 'Paper Title',
          hint: 'Enter the title of your research paper',
          icon: Icons.title_rounded,
          isDarkMode: isDarkMode,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _authorsController,
          label: 'Authors',
          hint: 'John Doe, Jane Smith, Robert Johnson',
          helperText: 'Separate multiple authors with commas',
          icon: Icons.people_rounded,
          isDarkMode: isDarkMode,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Please enter at least one author';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _abstractController,
          label: 'Abstract',
          hint: 'Brief summary of your research paper and key findings',
          icon: Icons.description_rounded,
          maxLines: 4,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          controller: _descriptionController,
          label: 'Your Thoughts',
          hint:
              'Share your insights, motivation, or why others should read this paper...',
          helperText:
              'Add personal context like a LinkedIn post to engage readers',
          icon: Icons.psychology_rounded,
          maxLines: 6,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  /// Builds the category and visibility selection section.
  Widget _buildCategoryAndVisibilitySection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Selection
        Text(
          'Category',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.87)
                : Colors.black.withValues(alpha: 0.87),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['id'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: category['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            isDarkMode
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? category['color'].withValues(alpha: 0.3)
                          : (isDarkMode
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05)),
                      blurRadius: isSelected ? 16 : 12,
                      offset: const Offset(0, 4),
                      spreadRadius: isSelected ? 0 : -4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category['name'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.7)),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Visibility Selection
        Text(
          'Who can see this paper?',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.87)
                : Colors.black.withValues(alpha: 0.87),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 16),
        _buildVisibilitySelector(isDarkMode),
      ],
    );
  }

  /// Builds the additional details section (keywords, tags, journal, doi).
  Widget _buildAdditionalDetailsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _keywordsController,
                label: 'Keywords',
                hint: 'machine learning, AI, neural networks',
                helperText: 'Separate with commas',
                icon: Icons.local_offer_rounded,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Tags',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedTags.map((tag) => _buildTagChip(tag, isDarkMode, true)),
            _buildTagInput(isDarkMode),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _journalController,
                label: 'Journal',
                hint: 'Nature, Science, IEEE, etc.',
                icon: Icons.library_books_rounded,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _doiController,
                label: 'DOI',
                hint: '10.1000/xyz123',
                icon: Icons.link_rounded,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the bottom call-to-action buttons (Save Draft, Publish).
  Widget _buildUltraModernUploadButton(bool isDarkMode) {
    return Row(
      children: [
        // Save Draft Button (optional, can be removed if not needed)
        Expanded(
          child: Container(
            height: 64,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        // TODO: Implement save draft functionality
                        HapticFeedback.lightImpact();
                      },
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_rounded,
                        size: 22,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save Draft',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Upload Button
        Expanded(
          flex: 2,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isLoading
                  ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                  : null,
              borderRadius: BorderRadius.circular(28),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _submitPaper,
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Uploading your paper...',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rocket_launch_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Upload Paper',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a modern styled text field with floating label and icon.
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required bool isDarkMode,
    String? hint,
    String? helperText,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: 0.1,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon != null
                  ? Container(
                      margin: const EdgeInsets.only(left: 16, right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                            AppTheme.primaryPurple.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.primaryBlue,
                        size: 22,
                      ),
                    )
                  : null,
              labelStyle: GoogleFonts.inter(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              hintStyle: GoogleFonts.inter(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  EdgeInsets.fromLTRB(icon != null ? 0 : 20, 20, 20, 20),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the visibility selector (public/private/restricted).
  Widget _buildVisibilitySelector(bool isDarkMode) {
    final visibilityOptions = [
      {
        'value': PaperVisibility.public,
        'icon': Icons.public_rounded,
        'title': 'Public',
        'description': 'Anyone can view this paper',
        'color': Colors.green,
      },
      {
        'value': PaperVisibility.private,
        'icon': Icons.lock_rounded,
        'title': 'Private',
        'description': 'Only you can view this paper',
        'color': Colors.orange,
      },
      {
        'value': PaperVisibility.restricted,
        'icon': Icons.group_rounded,
        'title': 'Restricted',
        'description': 'Only specific roles can view this paper',
        'color': Colors.blue,
      },
    ];

    return Column(
      children: visibilityOptions.map((option) {
        final isSelected = _selectedVisibility == option['value'];
        final color = option['color'] as Color;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVisibility = option['value'] as PaperVisibility;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02)),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : (isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    option['icon'] as IconData,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.6)),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? color
                              : (isDarkMode
                                  ? Colors.white.withValues(alpha: 0.87)
                                  : Colors.black.withValues(alpha: 0.87)),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 28,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Returns the appropriate icon for a file based on its extension.
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// Formats file size in a human-readable string.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Builds a tag chip for the tag input system.
  Widget _buildTagChip(String tag, bool isDarkMode, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                  AppTheme.primaryPurple.withValues(alpha: 0.2),
                ],
              )
            : null,
        color: !isSelected
            ? (isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05))
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedTags.remove(tag);
                });
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the tag input field for adding new tags.
  Widget _buildTagInput(bool isDarkMode) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 200),
      child: TextField(
        controller: _tagsController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Add tag...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty && !_selectedTags.contains(value)) {
            setState(() {
              _selectedTags.add(value);
              _tagsController.clear();
            });
          }
        },
      ),
    );
  }
}
