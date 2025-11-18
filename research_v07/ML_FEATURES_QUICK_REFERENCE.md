# Quick Reference - How to Use ML Features

## 🎯 Trending System

### View Trending Content
Navigate to `TrendingScreen` from your app:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TrendingScreen()),
);
```

### Calculate Trends Manually
```dart
final trendingService = TrendingService();
await trendingService.calculateAllTrends();
```

### Access Trending Data

**Get Trending Papers:**
```dart
// Using provider
final papers = ref.watch(trendingFirebasePapersProvider(20));

// Using service directly
final service = TrendingService();
final papers = await service.getTrendingPapers(limit: 20);
```

**Get Trending Faculty:**
```dart
final faculty = ref.watch(trendingFacultyProvider(10));
```

**Get Hot Topics:**
```dart
final topics = ref.watch(hotTopicsProvider(15));
```

---

## 🌟 Recommendations System

### View Recommendations
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => RecommendationsScreen()),
);
```

### Get Personalized Recommendations
```dart
final userId = 'user123';
final recommendations = ref.watch(
  personalizedRecommendationsProvider((userId: userId, limit: 20))
);
```

### Get Similar Papers
```dart
final similar = ref.watch(
  similarPapersRecommendationsProvider((paperId: 'paper123', limit: 5))
);
```

### Track User Behavior (for better recommendations)
```dart
final service = RecommendationService();

// Track paper view
await service.trackPaperView(userId, paperId);

// Track rating
await service.trackPaperRating(userId, paperId, 4.5);

// Track bookmark
await service.trackPaperBookmark(userId, paperId);

// Track download
await service.trackDownload(userId, paperId);
```

---

## 📱 Personalized Feed

### Get User's Feed
```dart
final feed = ref.watch(
  personalizedFeedProvider((userId: userId, limit: 30))
);
```

### Refresh Feed Cache
```dart
await ref.read(refreshFeedCacheProvider(userId).future);
```

### Use Feed in ListView
```dart
Widget build(BuildContext context) {
  final feed = ref.watch(
    personalizedFeedProvider((userId: currentUserId, limit: 30))
  );

  return feed.when(
    loading: () => CircularProgressIndicator(),
    error: (e, s) => Text('Error: $e'),
    data: (papers) => ListView.builder(
      itemCount: papers.length,
      itemBuilder: (context, index) {
        return PaperCard(paper: papers[index]);
      },
    ),
  );
}
```

---

## 🔧 Setup Cloud Function (Production)

### 1. Create Cloud Function
Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Run daily at 2 AM
exports.calculateDailyTrends = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Starting trend calculation...');
    
    try {
      // Calculate trending papers
      await calculateTrendingPapers();
      
      // Calculate trending faculty
      await calculateTrendingFaculty();
      
      // Calculate hot topics
      await calculateHotTopics();
      
      console.log('Trend calculation completed');
      return null;
    } catch (error) {
      console.error('Error calculating trends:', error);
      throw error;
    }
  });

async function calculateTrendingPapers() {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  
  const papersSnapshot = await db.collection('papers')
    .where('uploadedAt', '>=', sevenDaysAgo)
    .get();
  
  const scoredPapers = [];
  
  papersSnapshot.forEach(doc => {
    const data = doc.data();
    const score = 
      (data.views || 0) * 1 +
      (data.likesCount || 0) * 5 +
      (data.commentsCount || 0) * 10 +
      (data.sharesCount || 0) * 15 +
      (data.downloads || 0) * 8;
    
    scoredPapers.push({ id: doc.id, score });
  });
  
  // Sort and get top 50
  scoredPapers.sort((a, b) => b.score - a.score);
  const top50 = scoredPapers.slice(0, 50);
  
  // Cache in Firestore
  await db.collection('trending').doc('papers').set({
    paperIds: top50.map(p => p.id),
    scores: top50.map(p => p.score),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });
}

async function calculateTrendingFaculty() {
  // Implementation similar to papers
  // ...
}

async function calculateHotTopics() {
  // Implementation for keyword analysis
  // ...
}
```

### 2. Deploy
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📊 BigQuery Setup

### 1. Enable Export
```bash
# In Firebase Console
# Go to: Project Settings > Integrations > BigQuery
# Click "Link" and enable streaming
```

### 2. Query Analytics
```sql
-- Get most viewed papers
SELECT
  event_params.paperId,
  COUNT(*) as view_count
FROM
  `project.analytics.events_*`
WHERE
  event_name = 'paper_view'
  AND _TABLE_SUFFIX BETWEEN '20250101' AND '20250131'
GROUP BY
  event_params.paperId
ORDER BY
  view_count DESC
LIMIT 100;
```

---

## 🎨 UI Integration Examples

### Add Trending Section to Home
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingFirebasePapersProvider(5));
    
    return Scaffold(
      body: ListView(
        children: [
          // ... other sections
          
          // Trending section
          _buildSection(
            title: 'Trending Now 🔥',
            child: trending.when(
              loading: () => CircularProgressIndicator(),
              error: (e, s) => Text('Error loading trending'),
              data: (papers) => HorizontalPaperList(papers: papers),
            ),
          ),
          
          // ... more sections
        ],
      ),
    );
  }
}
```

### Add Recommendations Button
```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.recommend),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationsScreen(),
          ),
        );
      },
    ),
  ],
)
```

---

## 🔍 Testing Examples

### Test Trending Calculation
```dart
void main() {
  test('Trending calculation works', () async {
    final service = TrendingService();
    
    // Mock data would go here
    await service.calculateTrendingPapers();
    
    final papers = await service.getTrendingPapers(limit: 10);
    expect(papers.length, lessThanOrEqualTo(10));
  });
}
```

### Test Personalized Feed
```dart
void main() {
  test('Feed mixes sources correctly', () async {
    final service = PersonalizedFeedService();
    
    final feed = await service.getPersonalizedFeed('user123', limit: 100);
    
    // Check that feed has diverse sources
    // (Would need to tag papers with source in actual implementation)
    expect(feed.length, lessThanOrEqualTo(100));
  });
}
```

---

## 🐛 Debugging Tips

### Check Trending Cache
```dart
final doc = await FirebaseFirestore.instance
  .collection('trending')
  .doc('papers')
  .get();

if (doc.exists) {
  print('Last updated: ${doc.data()!['lastUpdated']}');
  print('Paper IDs: ${doc.data()!['paperIds']}');
}
```

### Debug Recommendations
```dart
final service = RecommendationService();
final results = service.getPersonalizedRecommendations('user123', limit: 10);

for (var result in results) {
  print('Paper: ${result.paper.title}');
  print('Score: ${result.score}');
  print('Reasoning: ${result.reasoning}');
  print('Type: ${result.recommendationType}');
  print('---');
}
```

### Monitor Performance
```dart
// Add logging in services
final stopwatch = Stopwatch()..start();

final papers = await getTrendingPapers(limit: 20);

stopwatch.stop();
print('Trending query took: ${stopwatch.elapsedMilliseconds}ms');
```

---

## 📱 Common Patterns

### Combine Multiple Providers
```dart
class DiscoverScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingFirebasePapersProvider(10));
    final recommended = ref.watch(
      personalizedRecommendationsProvider((userId: userId, limit: 10))
    );
    final hotTopics = ref.watch(hotTopicsProvider(5));
    
    return Scaffold(
      body: ListView(
        children: [
          // Show all three sections
          TrendingSection(papers: trending),
          RecommendedSection(papers: recommended),
          TopicsSection(topics: hotTopics),
        ],
      ),
    );
  }
}
```

### Refresh Multiple Sources
```dart
FloatingActionButton(
  onPressed: () {
    // Invalidate all caches
    ref.invalidate(trendingFirebasePapersProvider);
    ref.invalidate(trendingFacultyProvider);
    ref.invalidate(hotTopicsProvider);
  },
  child: Icon(Icons.refresh),
)
```

---

## 🎯 Best Practices

1. **Cache Aggressively**: Use Firestore caching to reduce queries
2. **Limit Results**: Always specify reasonable limits (10-50 items)
3. **Handle Errors**: Provide fallbacks when personalization fails
4. **Track User Actions**: More data = better recommendations
5. **Update Regularly**: Run trend calculations daily
6. **Monitor Performance**: Use Firebase Performance Monitoring
7. **Test with Real Data**: Use production-like datasets for testing
8. **Provide Explanations**: Show users why something was recommended

---

## 📚 Further Reading

- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Riverpod Documentation](https://riverpod.dev)
- [ML Recommendation Systems](https://developers.google.com/machine-learning/recommendation)
- [BigQuery for Firebase](https://firebase.google.com/docs/projects/bigquery-export)

---

**Last Updated**: November 14, 2025
