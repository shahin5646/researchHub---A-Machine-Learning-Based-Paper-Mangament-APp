import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as classic_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/paper_models.dart' as complex_models;
import 'models/social_models.dart' as social_models;
import 'models/research_project.dart';
import 'models/task.dart';
import 'models/activity_log.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/social_provider.dart';
import 'services/paper_service.dart';
import 'services/social_service.dart';
import 'services/analytics_service.dart' as analytics;
import 'screens/auth/welcome_screen.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'navigation/bottom_nav_controller.dart';
import 'screens/papers/add_paper_screen.dart';
import 'screens/papers/my_papers_screen.dart';
import 'screens/linkedin_style_papers_screen.dart';
import 'screens/realtime_feed_screen.dart';
import 'screens/social/notifications_screen.dart';
import 'screens/pdf_viewer_demo.dart';
import 'screens/trending/trending_screen.dart';
import 'screens/recommendations/recommendations_screen.dart';

// Create a Riverpod provider for AuthProvider
final authProvider =
    ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure early message handling to prevent channel buffer warnings
  _preventChannelBufferWarnings();

  // Initialize the app
  try {
    await _initializeApp();
  } catch (error, stackTrace) {
    debugPrint('App initialization error: $error');
    debugPrint('Stack trace: $stackTrace');
    // Show a simple error UI if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('App initialization failed'),
                const SizedBox(height: 8),
                Text('Error: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prevent channel buffer warnings by handling early plugin messages
void _preventChannelBufferWarnings() {
  try {
    // This is the most effective way to handle early plugin messages
    // We set up listeners immediately after binding initialization

    final messenger = ServicesBinding.instance.defaultBinaryMessenger;

    // Handle lifecycle messages that commonly cause warnings
    messenger.setMessageHandler('flutter/lifecycle', (ByteData? data) async {
      // Just acknowledge the message to prevent "discarded" warning
      return ByteData(0);
    });

    // Handle system messages
    messenger.setMessageHandler('flutter/system', (ByteData? data) async {
      // Just acknowledge the message to prevent "discarded" warning
      return ByteData(0);
    });

    // Handle platform messages
    messenger.setMessageHandler('flutter/platform', (ByteData? data) async {
      // Just acknowledge the message to prevent "discarded" warning
      return ByteData(0);
    });

    debugPrint(
        'Early message handlers configured to prevent channel buffer warnings');
  } catch (e) {
    debugPrint('Warning: Could not configure early message handling: $e');
  }
}

Future<void> _initializeApp() async {
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized successfully');

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Analytics Service to load persisted data
  debugPrint('Initializing AnalyticsService...');
  await analytics.AnalyticsService().initialize();
  debugPrint('AnalyticsService initialized successfully');

  // Register Hive adapters
  // Register research project models adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ResearchProjectAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TaskAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ActivityLogAdapter());
  }

  // Register complex models adapters (used by PaperService)
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(complex_models.ResearchPaperAdapter());
  }
  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(complex_models.PaperCommentAdapter());
  }
  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(complex_models.PaperReactionAdapter());
  }
  if (!Hive.isAdapterRegistered(23)) {
    Hive.registerAdapter(complex_models.PaperCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(complex_models.PaperVisibilityAdapter());
  }
  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(complex_models.ReactionTypeAdapter());
  }

  // Register social model adapters
  if (!Hive.isAdapterRegistered(40)) {
    Hive.registerAdapter(social_models.FollowRelationshipAdapter());
  }
  if (!Hive.isAdapterRegistered(41)) {
    Hive.registerAdapter(social_models.DiscussionThreadAdapter());
  }
  if (!Hive.isAdapterRegistered(42)) {
    Hive.registerAdapter(social_models.DiscussionCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(43)) {
    Hive.registerAdapter(social_models.DiscussionCommentAdapter());
  }
  if (!Hive.isAdapterRegistered(44)) {
    Hive.registerAdapter(social_models.DiscussionReactionAdapter());
  }
  if (!Hive.isAdapterRegistered(45)) {
    Hive.registerAdapter(social_models.DiscussionReactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(46)) {
    Hive.registerAdapter(social_models.SocialNotificationAdapter());
  }
  if (!Hive.isAdapterRegistered(47)) {
    Hive.registerAdapter(social_models.NotificationTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(48)) {
    Hive.registerAdapter(social_models.ActivityFeedItemAdapter());
  }
  if (!Hive.isAdapterRegistered(49)) {
    Hive.registerAdapter(social_models.ActivityTypeAdapter());
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      child: classic_provider.MultiProvider(
        providers: [
          classic_provider.ChangeNotifierProvider<AuthProvider>(
            create: (context) => AuthProvider(),
          ),
          classic_provider.ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider(prefs),
          ),
          classic_provider.ChangeNotifierProvider<PaperService>(
            create: (context) {
              final service = PaperService();
              // Initialize asynchronously but don't wait for it in the constructor
              service.initialize().then((_) {
                debugPrint('PaperService fully initialized and ready');
              }).catchError((error) {
                debugPrint('PaperService initialization error: $error');
              });
              return service;
            },
          ),
          classic_provider.ChangeNotifierProvider<SocialService>(
            create: (context) {
              final service = SocialService();

              // We'll try to initialize it again just to be sure
              Future.delayed(Duration.zero, () async {
                if (!service.isInitialized) {
                  try {
                    await service.initialize();
                    debugPrint('SocialService fully initialized and ready');
                  } catch (error) {
                    debugPrint(
                        'SocialService initialization retry failed: $error');
                  }
                }
              });

              return service;
            },
          ),
          classic_provider.ChangeNotifierProxyProvider<SocialService,
              SocialProvider>(
            create: (context) => SocialProvider(
              classic_provider.Provider.of<SocialService>(context,
                  listen: false),
            ),
            update: (context, socialService, previous) =>
                previous ?? SocialProvider(socialService),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Research Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2563EB),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => Consumer(
              builder: (context, ref, _) {
                final auth = ref.watch(authProvider);

                if (!auth.isInitialized) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Initializing...'),
                        ],
                      ),
                    ),
                  );
                }

                final initialIndex = settings.arguments as int? ?? 0;

                // Check if user needs onboarding
                if (auth.isLoggedIn &&
                    auth.currentUser != null &&
                    !(auth.currentUser!.hasCompletedOnboarding)) {
                  return const RoleSelectionScreen();
                }

                return auth.isLoggedIn
                    ? BottomNavController(initialIndex: initialIndex)
                    : const WelcomeScreen();
              },
            ),
          );
        }
        return null;
      },
      routes: {
        '/add-paper': (context) => const AddPaperScreen(),
        '/my-papers': (context) => const MyPapersScreen(),
        '/social': (context) => const LinkedInStylePapersScreen(),
        '/realtime-feed': (context) => const RealtimeFeedScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/pdf-demo': (context) => const PdfViewerDemo(),
        '/trending': (context) => const TrendingScreen(),
        '/recommendations': (context) => const RecommendationsScreen(),
      },
    );
  }
}
