import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/faculty_data.dart';

/// Debug utility to seed real faculty research papers into Firestore
/// Papers are sourced from actual faculty research with real-time engagement tracking
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed 60 real faculty research papers from 11 faculty members with varied engagement metrics
  Future<void> seedSamplePapers(String currentUserId) async {
    try {
      debugPrint(
          '🌱 Starting to seed 60 faculty papers from 11 faculty members...');

      // First, seed faculty users for the follow system
      await seedFacultyUsers();

      // Collect all faculty papers from the real data
      final allPapers = <Map<String, dynamic>>[];

      facultyResearchPapers.forEach((facultyName, papers) {
        for (final paper in papers) {
          allPapers.add({
            'title': paper.title,
            'abstract': paper.abstract,
            'category':
                paper.keywords.isNotEmpty ? paper.keywords.first : 'Research',
            'authorName': facultyName,
            'journalName': paper.journalName,
            'year': paper.year,
            'pdfUrl': paper.pdfUrl,
            'doi': paper.doi,
            'keywords': paper.keywords,
            'citations': paper.citations,
          });
        }
      });

      // Take all 60 papers (don't shuffle to ensure we get all of them)
      final papersToSeed = allPapers;

      int successCount = 0;
      for (int i = 0; i < papersToSeed.length; i++) {
        final paper = papersToSeed[i];

        try {
          // Generate unique authorId from author name
          final authorName = paper['authorName'] as String;
          final authorId =
              'user_${authorName.toLowerCase().replaceAll(' ', '_')}';

          await _firestore.collection('papers').add({
            'paperId': 'paper_${DateTime.now().millisecondsSinceEpoch}_$i',
            'title': paper['title'],
            'abstract': paper['abstract'],
            'category': paper['category'],
            'authorId': authorId,
            'authorName': authorName,
            'uploadedBy':
                authorId, // Use faculty authorId instead of currentUserId
            'visibility': 'public',
            'uploadedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            // Varied engagement metrics for real-time ranking
            'likesCount': (i * 3) % 15,
            'commentsCount': (i * 2) % 10,
            'sharesCount': (i * 1) % 5,
            'clicksCount': (i * 4) % 20,
            'views': (i * 5) % 30, // Add views for stats
            'pdfUrl': paper['pdfUrl'] ?? '',
            'reactions': {},
            'tags': paper['keywords'] ??
                [paper['category'].toString().toLowerCase()],
            'fileType': 'pdf',
            'journalName': paper['journalName'],
            'year': paper['year'],
            'doi': paper['doi'],
            'citations': paper['citations'] ?? 0,
          });
          successCount++;

          // Small delay to avoid rate limiting (reduced for faster loading)
          if (i % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          debugPrint('❌ Error adding paper ${i + 1}: $e');
        }
      }

      debugPrint(
          '✅ Successfully seeded $successCount/${papersToSeed.length} real faculty papers from 11 faculty members!');
    } catch (e) {
      debugPrint('❌ Error seeding papers: $e');
    }
  }

  /// Seed faculty members as users for the follow system
  Future<void> seedFacultyUsers() async {
    try {
      debugPrint('👥 Starting to seed faculty users...');

      int successCount = 0;
      for (final facultyName in facultyResearchPapers.keys) {
        try {
          final userId =
              'user_${facultyName.toLowerCase().replaceAll(' ', '_')}';

          // Check if user already exists
          final userDoc =
              await _firestore.collection('users').doc(userId).get();

          if (!userDoc.exists) {
            await _firestore.collection('users').doc(userId).set({
              'id': userId,
              'name': facultyName,
              'email':
                  '${facultyName.toLowerCase().replaceAll(' ', '.')}@university.edu',
              'photoURL': null,
              'role': 'faculty',
              'followersCount': 0,
              'followingCount': 0,
              'bookmarksCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            successCount++;
          }
        } catch (e) {
          debugPrint('❌ Error adding faculty user $facultyName: $e');
        }
      }

      debugPrint('✅ Successfully seeded $successCount faculty users!');
    } catch (e) {
      debugPrint('❌ Error seeding faculty users: $e');
    }
  }

  /// Clear all papers (use with caution!)
  Future<void> clearAllPapers() async {
    try {
      debugPrint('🗑️ Clearing all papers...');

      final snapshot = await _firestore.collection('papers').get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Cleared ${snapshot.docs.length} papers');
    } catch (e) {
      debugPrint('❌ Error clearing papers: $e');
    }
  }
}
