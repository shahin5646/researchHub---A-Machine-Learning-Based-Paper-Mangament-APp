import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/common_widgets/safe_image.dart';

void main() {
  group('SafeImage Widget Tests', () {
    testWidgets('SafeImage displays correctly with valid path',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeImage(
              imagePath: 'assets/images/faculty/sadi_sir.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(SafeImage), findsOneWidget);
    });

    testWidgets('SafeCircleAvatar displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeCircleAvatar(
              imagePath: 'assets/images/faculty/sadi_sir.jpg',
              radius: 25,
            ),
          ),
        ),
      );

      expect(find.byType(SafeCircleAvatar), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('SafeImage handles missing image gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeImage(
              imagePath: 'assets/images/non_existent.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(SafeImage), findsOneWidget);
      // The widget should render without throwing an exception
    });
  });
}
