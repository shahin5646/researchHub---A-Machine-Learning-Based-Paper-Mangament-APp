import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/papers_provider.dart';
import '../../main.dart';

class FirebaseUploadPaperScreen extends ConsumerStatefulWidget {
  const FirebaseUploadPaperScreen({super.key});

  @override
  ConsumerState<FirebaseUploadPaperScreen> createState() =>
      _FirebaseUploadPaperScreenState();
}

class _FirebaseUploadPaperScreenState
    extends ConsumerState<FirebaseUploadPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _doiController = TextEditingController();
  final _journalController = TextEditingController();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  File? _selectedPdfFile;
  File? _selectedThumbnailFile;
  String _selectedCategory = 'Computer Science';
  String _selectedSubject = 'General';
  String _selectedFaculty = 'Engineering';
  String _selectedVisibility = 'public';

  final List<String> _categories = [
    'Computer Science',
    'Engineering',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Medicine',
    'Social Sciences',
  ];

  final List<String> _subjects = [
    'General',
    'Artificial Intelligence',
    'Machine Learning',
    'Data Science',
    'Software Engineering',
    'Networks',
    'Security',
  ];

  final List<String> _faculties = [
    'Engineering',
    'Science',
    'Medicine',
    'Arts',
    'Business',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _keywordsController.dispose();
    _descriptionController.dispose();
    _doiController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdfFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking PDF: $e', isError: true);
    }
  }

  Future<void> _pickThumbnailFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedThumbnailFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking thumbnail: $e', isError: true);
    }
  }

  Future<void> _uploadPaper() async {
    if (!_formKey.currentState!.validate() || _selectedPdfFile == null) {
      _showSnackBar('Please fill all required fields and select a PDF',
          isError: true);
      return;
    }

    final authState = ref.read(authProvider);
    final userId = authState.firebaseUser?.uid;

    if (userId == null) {
      _showSnackBar('Please login to upload papers', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final uploadService = ref.read(paperUploadProvider);

      // Parse keywords and authors
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      // Simulate progress (in production, use Firebase Storage onProgress callback)
      _updateProgress(0.2);

      final paperId = await uploadService.uploadPaper(
        userId: userId,
        pdfFile: _selectedPdfFile!,
        thumbnailFile: _selectedThumbnailFile,
        title: _titleController.text.trim(),
        authors: [authState.currentUser?.displayName ?? 'Anonymous'],
        abstract: _abstractController.text.trim(),
        keywords: keywords,
        category: _selectedCategory,
        subject: _selectedSubject,
        faculty: _selectedFaculty,
        visibility: _selectedVisibility,
        tags: keywords, // Use keywords as tags
        doi: _doiController.text.trim().isEmpty
            ? null
            : _doiController.text.trim(),
        journal: _journalController.text.trim().isEmpty
            ? null
            : _journalController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      _updateProgress(1.0);

      _showSnackBar('Paper uploaded successfully! ID: $paperId');

      // Clear form
      _clearForm();

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _updateProgress(double progress) {
    if (mounted) {
      setState(() {
        _uploadProgress = progress;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _abstractController.clear();
    _keywordsController.clear();
    _descriptionController.clear();
    _doiController.clear();
    _journalController.clear();
    setState(() {
      _selectedPdfFile = null;
      _selectedThumbnailFile = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload to Cloud',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Paper Title *',
                    hint: 'Enter paper title',
                    maxLines: 2,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _abstractController,
                    label: 'Abstract *',
                    hint: 'Enter paper abstract',
                    maxLines: 5,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Abstract is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _keywordsController,
                    label: 'Keywords (comma-separated)',
                    hint: 'AI, Machine Learning, Deep Learning',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Category *',
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Subject',
                    value: _selectedSubject,
                    items: _subjects,
                    onChanged: (v) => setState(() => _selectedSubject = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Faculty',
                    value: _selectedFaculty,
                    items: _faculties,
                    onChanged: (v) => setState(() => _selectedFaculty = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Visibility',
                    value: _selectedVisibility,
                    items: ['public', 'private', 'restricted'],
                    onChanged: (v) => setState(() => _selectedVisibility = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _doiController,
                    label: 'DOI (Optional)',
                    hint: '10.1234/example',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _journalController,
                    label: 'Journal (Optional)',
                    hint: 'Journal of Computer Science',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Additional information about the paper',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildFilePickerCard(
                    'Select PDF File *',
                    _selectedPdfFile,
                    _pickPdfFile,
                    Icons.picture_as_pdf,
                  ),
                  const SizedBox(height: 16),
                  _buildFilePickerCard(
                    'Select Thumbnail (Optional)',
                    _selectedThumbnailFile,
                    _pickThumbnailFile,
                    Icons.image,
                  ),
                  const SizedBox(height: 24),
                  if (_isUploading) ...[
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadPaper,
                    icon:
                        Icon(_isUploading ? Icons.cloud_upload : Icons.upload),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _isUploading ? 'Uploading...' : 'Upload to Cloud',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your paper will be uploaded to Firebase Cloud Storage',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFilePickerCard(
    String label,
    File? file,
    VoidCallback onPick,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        subtitle: file != null
            ? Text(
                file.path.split('/').last,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.green),
              )
            : Text(
                'No file selected',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
        trailing: ElevatedButton(
          onPressed: onPick,
          child: const Text('Browse'),
        ),
      ),
    );
  }
}
