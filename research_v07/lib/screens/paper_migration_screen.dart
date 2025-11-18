import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/paper_migration_service.dart';
import '../main.dart'; // For authProvider

class PaperMigrationScreen extends ConsumerStatefulWidget {
  const PaperMigrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaperMigrationScreen> createState() =>
      _PaperMigrationScreenState();
}

class _PaperMigrationScreenState extends ConsumerState<PaperMigrationScreen> {
  final PaperMigrationService _migrationService = PaperMigrationService();

  bool _isMigrating = false;
  bool _isComplete = false;
  int _currentPaper = 0;
  int _totalPapers = 0;
  int _successCount = 0;
  String _currentStatus = '';
  Map<String, int>? _verificationResult;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.firebaseUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrate Papers to Cloud'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInformationCard(),
            const SizedBox(height: 24),
            if (_verificationResult != null) ...[
              _buildVerificationCard(),
              const SizedBox(height: 24),
            ],
            if (_isMigrating) ...[
              _buildProgressCard(),
              const SizedBox(height: 24),
            ],
            if (_isComplete) ...[
              _buildSuccessCard(),
              const SizedBox(height: 24),
            ],
            _buildActionButtons(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.cloud_upload, size: 64, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Cloud Migration',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Migrate your research papers from local storage to Firebase Cloud',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'What happens during migration?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem('1. PDF files will be uploaded to Firebase Storage'),
            _buildInfoItem('2. Paper metadata will be saved to Firestore'),
            _buildInfoItem('3. Comments and reactions will be migrated'),
            _buildInfoItem('4. Local files will remain intact for safety'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This process requires internet connection and may take time depending on paper count',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final hiveCount = _verificationResult!['hive'] ?? 0;
    final firestoreCount = _verificationResult!['firestore'] ?? 0;
    final missingCount = _verificationResult!['missing'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildVerificationRow('Local Papers:', hiveCount.toString()),
            _buildVerificationRow('Cloud Papers:', firestoreCount.toString()),
            _buildVerificationRow(
              'Not Migrated:',
              missingCount.toString(),
              color: missingCount > 0 ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _totalPapers > 0 ? _currentPaper / _totalPapers : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Migration in Progress...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              '$_currentPaper / $_totalPapers papers',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentStatus,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text(
              'Migration Complete!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_successCount papers migrated successfully',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: userId != null && !_isMigrating
              ? () => _verifyMigration(userId)
              : null,
          icon: const Icon(Icons.verified),
          label: const Text('Verify Migration Status'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: userId != null && !_isMigrating
              ? () => _startMigration(userId)
              : null,
          icon: const Icon(Icons.cloud_upload),
          label: Text(_isMigrating ? 'Migrating...' : 'Start Migration'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        if (_isComplete) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _verifyMigration(String userId) async {
    try {
      setState(() {
        _verificationResult = null;
      });

      final result = await _migrationService.verifyMigration(userId);

      setState(() {
        _verificationResult = result;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${result['hive']} local papers, ${result['firestore']} cloud papers',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startMigration(String userId) async {
    // Confirm before starting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Migration?'),
        content: const Text(
          'This will upload your papers to Firebase Cloud. The process may take several minutes. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMigrating = true;
      _isComplete = false;
      _currentPaper = 0;
      _totalPapers = 0;
      _successCount = 0;
      _currentStatus = 'Preparing migration...';
    });

    try {
      final successCount = await _migrationService.migrateAllPapers(
        userId: userId,
        onProgress: (current, total, status) {
          setState(() {
            _currentPaper = current;
            _totalPapers = total;
            _currentStatus = status;
          });
        },
      );

      setState(() {
        _isMigrating = false;
        _isComplete = true;
        _successCount = successCount;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration complete! $successCount papers migrated'),
          backgroundColor: Colors.green,
        ),
      );

      // Verify after migration
      await _verifyMigration(userId);
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
