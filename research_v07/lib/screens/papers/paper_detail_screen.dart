import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/paper_models.dart';
import '../../theme/app_theme.dart';

class PaperDetailScreen extends StatefulWidget {
  final ResearchPaper paper;

  const PaperDetailScreen({
    super.key,
    required this.paper,
  });

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Details'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.paper.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Authors: ${widget.paper.authors.join(', ')}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.paper.abstract?.isNotEmpty == true) ...[
              Text(
                'Abstract',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.paper.abstract!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Add more content as needed
          ],
        ),
      ),
    );
  }
}
