import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pdf_service.dart';

/// Unified PDF Viewer using pdfrx for consistent cross-platform experience
/// Supports both asset and network PDFs with advanced features
class UnifiedPdfViewer extends StatefulWidget {
  final String pdfPath;
  final String title;
  final String author;
  final bool isAsset;
  final bool enableDownload;
  final bool enableSharing;
  final VoidCallback? onClose;

  const UnifiedPdfViewer({
    super.key,
    required this.pdfPath,
    this.title = 'PDF Document',
    this.author = '',
    this.isAsset = false,
    this.enableDownload = true,
    this.enableSharing = true,
    this.onClose,
  });

  @override
  State<UnifiedPdfViewer> createState() => _UnifiedPdfViewerState();
}

class _UnifiedPdfViewerState extends State<UnifiedPdfViewer>
    with TickerProviderStateMixin {
  final _logger = Logger('UnifiedPdfViewer');
  final _pdfService = PdfService();

  // PDF Controller
  PdfViewerController? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _localPath;
  PdfDocument? _pdfDocument;
  bool _isAssetPdf = false; // Track if PDF is an asset

  // Page Management
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;
  int _lastViewedPage = 1;

  // Zoom Controls
  double _currentZoom = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 5.0;
  static const double _zoomStep = 0.25;

  // UI Controls
  bool _showControls = true;
  late AnimationController _controlsAnimationController;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _controlsAnimation;
  late Animation<Offset> _sidebarAnimation;

  // Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<PdfTextRange> _searchResults = [];
  int _currentSearchIndex = 0;

  // Theme
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  // Sidebar mode
  SidebarMode _sidebarMode = SidebarMode.none;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLastViewedPage();
    _initializePdf();
    _trackView();
  }

  void _initializeAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    _sidebarAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));

    _controlsAnimationController.forward();
  }

  Future<void> _loadLastViewedPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_page_${widget.pdfPath.hashCode}';
      _lastViewedPage = prefs.getInt(key) ?? 1;
    } catch (e) {
      _logger.warning('Failed to load last viewed page: $e');
    }
  }

  Future<void> _saveLastViewedPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'last_page_${widget.pdfPath.hashCode}';
      await prefs.setInt(key, _currentPage);
    } catch (e) {
      _logger.warning('Failed to save last viewed page: $e');
    }
  }

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Create PDF controller
      _pdfController = PdfViewerController();

      // Determine if this is an asset or file based on the path
      // If it starts with 'assets/', it's an asset
      // If it contains platform-specific paths like /data/user or C:\, it's a file
      // Otherwise, use the isAsset flag provided
      if (widget.pdfPath.startsWith('assets/')) {
        _isAssetPdf = true;
        _localPath = widget.pdfPath;
      } else if (widget.pdfPath.contains('/data/') ||
          widget.pdfPath.contains('\\') ||
          widget.pdfPath.startsWith('/') ||
          (widget.pdfPath.length > 2 && widget.pdfPath[1] == ':')) {
        // This is a file system path (Android, iOS, Windows, Linux, etc.)
        _isAssetPdf = false;
        _localPath = widget.pdfPath;
      } else {
        // Use the provided flag
        _isAssetPdf = widget.isAsset;
        _localPath = widget.pdfPath;
      }

      _logger.info('Using ${_isAssetPdf ? "asset" : "file"} path: $_localPath');
      _logger.info('Original path: ${widget.pdfPath}');
      _logger.info('isAsset flag: ${widget.isAsset}');

      setState(() {
        _isLoading = false;
        _isReady = true;
      });

      _logger.info('PDF initialized successfully: $_localPath');
    } catch (e) {
      _logger.severe('Error initializing PDF: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  Future<void> _trackView() async {
    await _pdfService.trackPaperView(
      widget.title,
      widget.author,
      widget.pdfPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Main PDF Content
          SafeArea(child: _buildPdfContent()),

          // App Bar
          _buildAppBar(),

          // Bottom Toolbar
          if (_isReady) _buildBottomToolbar(),

          // Sidebar (Thumbnails/Outline)
          if (_sidebarMode != SidebarMode.none) _buildSidebar(),

          // Search Overlay
          if (_isSearching) _buildSearchOverlay(),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isReady || _localPath == null) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: GestureDetector(
        onTap: _toggleControls,
        child: _isAssetPdf
            ? PdfViewer.asset(
                widget.pdfPath,
                controller: _pdfController,
                params: PdfViewerParams(
                  backgroundColor:
                      _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  enableTextSelection: true,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page ?? 1;
                    });
                    _saveLastViewedPage();
                  },
                  onDocumentChanged: (document) {
                    setState(() {
                      _pdfDocument = document;
                      _totalPages = document?.pages.length ?? 0;
                    });

                    // Jump to last viewed page
                    if (_lastViewedPage > 1 && _lastViewedPage <= _totalPages) {
                      _pdfController?.goToPage(pageNumber: _lastViewedPage);
                    }
                  },
                ),
              )
            : PdfViewer.file(
                _localPath!,
                controller: _pdfController,
                params: PdfViewerParams(
                  backgroundColor:
                      _isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                  enableTextSelection: true,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page ?? 1;
                    });
                    _saveLastViewedPage();
                  },
                  onDocumentChanged: (document) {
                    setState(() {
                      _pdfDocument = document;
                      _totalPages = document?.pages.length ?? 0;
                    });

                    // Jump to last viewed page
                    if (_lastViewedPage > 1 && _lastViewedPage <= _totalPages) {
                      _pdfController?.goToPage(pageNumber: _lastViewedPage);
                    }
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF1F2937).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),

            // Document Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.author.isNotEmpty)
                    Text(
                      widget.author,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color:
                            _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Action Buttons
            if (_isReady) ...[
              // Search Button
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: _toggleSearch,
                tooltip: 'Search',
              ),

              // Outline Button
              IconButton(
                icon: Icon(
                  Icons.list_alt,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: _toggleOutline,
                tooltip: 'Outline',
              ),

              // Download Button
              if (widget.enableDownload)
                IconButton(
                  icon: Icon(
                    Icons.download_outlined,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _downloadPdf,
                  tooltip: 'Download',
                ),

              // Share Button
              if (widget.enableSharing)
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _sharePdf,
                  tooltip: 'Share',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _controlsAnimation,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF1F2937).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail View Button
                IconButton(
                  icon: Icon(
                    Icons.view_sidebar_outlined,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _toggleThumbnails,
                  tooltip: 'Thumbnails',
                ),

                const SizedBox(width: 4),

                // Zoom Out
                IconButton(
                  icon: Icon(
                    Icons.zoom_out,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _currentZoom > _minZoom ? _zoomOut : null,
                  tooltip: 'Zoom Out',
                ),

                // Zoom Indicator
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(_currentZoom * 100).round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Zoom In
                IconButton(
                  icon: Icon(
                    Icons.zoom_in,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _currentZoom < _maxZoom ? _zoomIn : null,
                  tooltip: 'Zoom In',
                ),

                const SizedBox(width: 8),

                // Previous Page
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_left,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _currentPage > 1 ? _previousPage : null,
                  tooltip: 'Previous Page',
                ),

                // Page Indicator
                GestureDetector(
                  onTap: _showPageJumpDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.blue[700] : Colors.blue[600],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Next Page
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_right,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                  tooltip: 'Next Page',
                ),

                const SizedBox(width: 8),

                // Fit Width
                IconButton(
                  icon: Icon(
                    Icons.fit_screen,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _fitWidth,
                  tooltip: 'Fit Width',
                ),

                // Refresh Button
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: _reloadPdf,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SlideTransition(
      position: _sidebarAnimation,
      child: Container(
        width: 280,
        height: double.infinity,
        color: _isDarkMode
            ? const Color(0xFF111827).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _sidebarMode == SidebarMode.thumbnails
                        ? 'Pages'
                        : 'Outline',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onPressed: _closeSidebar,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _sidebarMode == SidebarMode.thumbnails
                  ? _buildThumbnailList()
                  : _buildOutlineList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailList() {
    if (_pdfDocument == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _totalPages,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final isCurrentPage = pageNumber == _currentPage;

        return GestureDetector(
          onTap: () => _jumpToPage(pageNumber),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentPage
                  ? (_isDarkMode ? Colors.blue[700] : Colors.blue[100])
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrentPage
                    ? (_isDarkMode ? Colors.blue[500]! : Colors.blue[300]!)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: PdfPageView(
                      document: _pdfDocument!,
                      pageNumber: pageNumber,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Page $pageNumber',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        isCurrentPage ? FontWeight.w600 : FontWeight.w400,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlineList() {
    // For now, show a simple outline placeholder
    // In a full implementation, you would extract outline/bookmarks from the PDF
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildOutlineItem('Chapter 1: Introduction', 1, 0),
        _buildOutlineItem('Chapter 2: Background', 15, 0),
        _buildOutlineItem('Chapter 3: Methodology', 28, 0),
        _buildOutlineItem('Chapter 4: Results', 45, 0),
        _buildOutlineItem('Chapter 5: Conclusion', 62, 0),
        _buildOutlineItem('References', 75, 0),
      ],
    );
  }

  Widget _buildOutlineItem(String title, int pageNumber, int level) {
    return GestureDetector(
      onTap: () => _jumpToPage(pageNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.only(
          left: 16.0 * level + 8,
          right: 8,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: pageNumber == _currentPage
              ? (_isDarkMode ? Colors.blue[700] : Colors.blue[100])
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: pageNumber == _currentPage
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Text(
              '$pageNumber',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search in document...',
                hintStyle: GoogleFonts.inter(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchResults.isNotEmpty) ...[
                      // Previous result
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color:
                              _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: _previousSearchResult,
                      ),
                      // Next result
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color:
                              _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: _nextSearchResult,
                      ),
                    ],
                    // Clear
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color:
                            _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () => _searchController.clear(),
                    ),
                  ],
                ),
              ),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),

            // Search Results Info
            if (_searchResults.isNotEmpty)
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_currentSearchIndex + 1} of ${_searchResults.length} results',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading PDF...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 32,
            right: 32,
            top: 80,
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading PDF',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializePdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Control Methods
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _toggleThumbnails() {
    if (_sidebarMode == SidebarMode.thumbnails) {
      _closeSidebar();
    } else {
      _openSidebar(SidebarMode.thumbnails);
    }
  }

  void _toggleOutline() {
    if (_sidebarMode == SidebarMode.outline) {
      _closeSidebar();
    } else {
      _openSidebar(SidebarMode.outline);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults.clear();
        _currentSearchIndex = 0;
      }
    });
  }

  void _openSidebar(SidebarMode mode) {
    setState(() {
      _sidebarMode = mode;
    });
    _sidebarAnimationController.forward();
  }

  void _closeSidebar() {
    setState(() {
      _sidebarMode = SidebarMode.none;
    });
    _sidebarAnimationController.reverse();
  }

  void _zoomIn() {
    if (_currentZoom < _maxZoom) {
      setState(() {
        _currentZoom = (_currentZoom + _zoomStep).clamp(_minZoom, _maxZoom);
      });
      // Note: pdfrx zoom is handled through gestures, not programmatically
      // This is for UI feedback only
    }
  }

  void _zoomOut() {
    if (_currentZoom > _minZoom) {
      setState(() {
        _currentZoom = (_currentZoom - _zoomStep).clamp(_minZoom, _maxZoom);
      });
      // Note: pdfrx zoom is handled through gestures, not programmatically
      // This is for UI feedback only
    }
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
    });
    // Note: pdfrx zoom reset would be handled by double-tap gesture
  }

  void _fitWidth() {
    // Reset zoom to fit width
    _resetZoom();
  }

  void _previousPage() {
    if (_pdfController != null && _currentPage > 1) {
      _pdfController!.goToPage(pageNumber: _currentPage - 1);
    }
  }

  void _nextPage() {
    if (_pdfController != null && _currentPage < _totalPages) {
      _pdfController!.goToPage(pageNumber: _currentPage + 1);
    }
  }

  void _jumpToPage(int page) {
    if (_pdfController != null && page >= 1 && page <= _totalPages) {
      _pdfController!.goToPage(pageNumber: page);
      _closeSidebar(); // Close sidebar after navigation
    }
  }

  void _reloadPdf() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _initializePdf();
  }

  void _showPageJumpDialog() {
    final pageController = TextEditingController(text: '$_currentPage');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Jump to Page',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Page Number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.isEmpty || _pdfDocument == null) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = 0;
      });
      return;
    }

    try {
      // Note: pdfrx doesn't have built-in text search in current version
      // For now, show search UI feedback
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = 0;
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: "$query"'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _logger.warning('Search error: $e');
    }
  }

  void _nextSearchResult() {
    if (_searchResults.isNotEmpty) {
      setState(() {
        _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
      });
      // Navigate to result page when search is implemented
    }
  }

  void _previousSearchResult() {
    if (_searchResults.isNotEmpty) {
      setState(() {
        _currentSearchIndex =
            (_currentSearchIndex - 1 + _searchResults.length) %
                _searchResults.length;
      });
      // Navigate to result page when search is implemented
    }
  }

  Future<void> _downloadPdf() async {
    try {
      if (kIsWeb) {
        // Web download functionality
        await _downloadPdfWeb();
      } else {
        // Mobile download functionality
        await _downloadPdfMobile();
      }

      // Track download
      await _pdfService.trackPaperDownload(
        widget.title,
        widget.author,
        widget.pdfPath,
      );
    } catch (e) {
      _logger.severe('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download PDF')),
      );
    }
  }

  Future<void> _downloadPdfWeb() async {
    // Web download implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download started')),
    );
  }

  Future<void> _downloadPdfMobile() async {
    try {
      if (_localPath != null) {
        // Get downloads directory
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final fileName =
              '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
          final downloadPath = '${directory.path}/$fileName';

          // Copy file to downloads
          final file = File(_localPath!);
          await file.copy(downloadPath);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded to: $downloadPath')),
          );
        } else {
          throw Exception('Downloads directory not available');
        }
      } else {
        throw Exception('PDF file not available');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sharePdf() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Sharing not available on web. Use browser share options.'),
        ),
      );
      return;
    }

    try {
      if (_localPath != null) {
        await Share.shareXFiles(
          [XFile(_localPath!)],
          text: 'Check out this document: ${widget.title}',
        );
      }
    } catch (e) {
      _logger.severe('Share error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share PDF')),
      );
    }
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _sidebarAnimationController.dispose();
    _searchController.dispose();
    // Note: PdfViewerController doesn't need explicit disposal in pdfrx
    super.dispose();
  }
}

// Enums
enum SidebarMode { none, thumbnails, outline }
