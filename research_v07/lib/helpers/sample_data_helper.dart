import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../models/paper_models.dart';
import '../services/paper_service.dart';

class SampleDataHelper {
  static Future<void> addSamplePapers(PaperService paperService) async {
    // Sample papers from assets folder
    final samplePapers = [
      {
        'title':
            'Adaptive Secure and Efficient Routing Protocol to Enhance the Performance of Mobile Ad Hoc Network (MANET)',
        'authors': ['Dr. A.H.M. SaifullahSadi'],
        'abstract':
            'This paper presents an adaptive secure and efficient routing protocol designed to enhance the performance of Mobile Ad Hoc Networks (MANETs).',
        'assetPath':
            'assets/papers/Dr_A_H_M_SaifullahSadi/Adaptive_Secure_and_Efficient_Routing_Protocol_to_Enhance_the_Performance_of_Mobile_Ad_Hoc_Network_(MANET).pdf',
      },
      {
        'title':
            'Design and Development of a Bipedal Robot with Adaptive Locomotion Control for Uneven Terrain',
        'authors': ['Dr. A.H.M. SaifullahSadi'],
        'abstract':
            'This research focuses on the design and development of a bipedal robot equipped with adaptive locomotion control mechanisms for navigating uneven terrain.',
        'assetPath':
            'assets/papers/Dr_A_H_M_SaifullahSadi/Design_and_Development_of_a_Bipedal_Robot_with_Adaptive_Locomotion_Control_for_Uneven_Terrain.pdf',
      },
      {
        'title':
            'Multiclass Blood Cancer Classification using Deep CNN with Optimized Features',
        'authors': ['Dr. A.H.M. SaifullahSadi'],
        'abstract':
            'This paper presents a multiclass blood cancer classification system using deep convolutional neural networks with optimized feature extraction.',
        'assetPath':
            'assets/papers/Dr_A_H_M_SaifullahSadi/Multiclass_blood_cancer_classification_using_deep_CNN_with_optimized_features.pdf',
      },
    ];

    for (int i = 0; i < samplePapers.length; i++) {
      final paperData = samplePapers[i];

      try {
        // Load PDF bytes from assets
        final ByteData assetData =
            await rootBundle.load(paperData['assetPath']! as String);
        final Uint8List pdfBytes = assetData.buffer.asUint8List();

        final now = DateTime.now().subtract(Duration(days: i));
        final paper = ResearchPaper(
          id: 'sample_${i}_${now.millisecondsSinceEpoch}',
          title: paperData['title']! as String,
          authors: paperData['authors']! as List<String>,
          abstract: paperData['abstract']! as String,
          keywords: ['research', 'academic', 'sample'],
          category: 'Computer Science',
          filePath: paperData['assetPath']! as String, // Store asset path
          fileBytes: pdfBytes, // Store actual bytes for viewing
          publishedDate: now,
          uploadedAt: now,
          uploadedBy: 'sample_user',
          visibility: PaperVisibility.public,
          views: (i + 1) * 15,
          downloads: (i + 1) * 8,
          averageRating: 4.0 + (i * 0.3),
          ratingsCount: (i + 1) * 12,
          tags: ['sample', 'research', 'pdf'],
          fileSize: pdfBytes.length,
          fileType: 'pdf',
        );

        await paperService.addPaper(paper, fileBytes: pdfBytes);
        print('Added sample paper: ${paper.title}');
      } catch (e) {
        print('Error loading sample paper ${paperData['title']}: $e');
      }
    }
  }
}
