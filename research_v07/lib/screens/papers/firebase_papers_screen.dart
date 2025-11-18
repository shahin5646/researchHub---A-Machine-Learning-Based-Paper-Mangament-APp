import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/firebase_paper.dart';
import '../../providers/papers_provider.dart';
import '../../services/firebase_paper_service.dart';
import '../../services/reaction_service.dart';
import './firebase_upload_paper_screen.dart';

class FirebasePapersScreen extends ConsumerWidget {
  const FirebasePapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(firebasePapersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Research Papers',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirebaseUploadPaperScreen(),
                ),
              );
            },
            tooltip: 'Upload Paper',
          ),
        ],
        elevation: 0,
      ),
      body: papersAsync.when(
        data: (papers) {
          if (papers.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(firebasePapersProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: papers.length,
              itemBuilder: (context, index) {
                final paper = papers[index];
                return PaperCard(paper: paper);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading papers',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(firebasePapersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Papers Yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first research paper',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirebaseUploadPaperScreen(),
                ),
              );
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload Paper'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class PaperCard extends ConsumerStatefulWidget {
  final FirebasePaper paper;

  const PaperCard({super.key, required this.paper});

  @override
  ConsumerState<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends ConsumerState<PaperCard> {
  final FirebasePaperService _paperService = FirebasePaperService();
  final ReactionService _reactionService = ReactionService();
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkUserReactions();
  }

  Future<void> _checkUserReactions() async {
    // TODO: Get current user ID from auth provider
    final userId = 'current_user_id';
    final reaction = await _reactionService.getUserReaction(
      paperId: widget.paper.id,
      userId: userId,
    );

    if (mounted) {
      setState(() {
        _isLiked = reaction?.type == 'like';
        _isBookmarked = reaction?.type == 'bookmark';
      });
    }
  }

  Future<void> _toggleLike() async {
    final userId = 'current_user_id'; // TODO: Get from auth
    await _reactionService.toggleReaction(
      paperId: widget.paper.id,
      userId: userId,
      type: 'like',
    );
    await _checkUserReactions();
  }

  Future<void> _toggleBookmark() async {
    final userId = 'current_user_id'; // TODO: Get from auth
    await _reactionService.toggleReaction(
      paperId: widget.paper.id,
      userId: userId,
      type: 'bookmark',
    );
    await _checkUserReactions();
  }

  Future<void> _incrementDownload() async {
    await _paperService.incrementDownloads(widget.paper.id);
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to paper detail screen
          _paperService.incrementViews(paper.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                paper.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Authors
              if (paper.authors.isNotEmpty)
                Text(
                  paper.authors.join(', '),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Abstract
              Text(
                paper.abstract ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Keywords/Tags
              if (paper.keywords.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: paper.keywords.take(3).map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        keyword,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),

              // Metadata row
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    paper.category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(paper.publishedDate),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Engagement stats
                  Row(
                    children: [
                      _buildStat(Icons.visibility, paper.views.toString()),
                      const SizedBox(width: 16),
                      _buildStat(Icons.download, paper.downloads.toString()),
                      const SizedBox(width: 16),
                      _buildStat(Icons.comment_outlined,
                          paper.commentsCount.toString()),
                    ],
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleLike,
                        tooltip: 'Like',
                      ),
                      Text(
                        paper.likesCount.toString(),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isBookmarked ? Colors.blue : Colors.grey,
                        ),
                        onPressed: _toggleBookmark,
                        tooltip: 'Bookmark',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.grey),
                        onPressed: () {
                          // TODO: Implement share
                        },
                        tooltip: 'Share',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
