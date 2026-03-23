import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_application_1/main.dart' as app;

void main() {
  // Initializes the integration test environment
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Journey: Login, Sync, CRUD, Search, and Logout',
      (WidgetTester tester) async {
    // 1. Boot the application
    await app.main();
    await tester.pumpAndSettle();

    // ===================================
    // SCENARIO 1: Authentication (Login)
    // ===================================
    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'), 'admin');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Verify routing success
    expect(find.text('My Tasks'), findsOneWidget);

    // =====================================
    // SCENARIO 2: Pull-to-Refresh (Syncing)
    // =====================================

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);

    // =======================================
    // SCENARIO 3: Create Tasks (Optimistic UI)
    // =======================================
    final task1 = 'Buy groceries for the week';
    final task2 = 'Finish Flutter E2E tests';

    // Add Task 1
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, task1);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Task'));
    await tester.pumpAndSettle();

    expect(find.text(task1), findsOneWidget);

    // Add Task 2
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, task2);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Task'));
    await tester.pumpAndSettle();

    expect(find.text(task2), findsOneWidget);

    // ================================================
    // SCENARIO 4: Search and Filter (Debounce Testing)
    // ================================================
    await tester.enterText(find.byType(TextField).first, 'groceries');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify list is filtered
    expect(find.text(task1), findsOneWidget);
    expect(find.text(task2), findsNothing); // Task 2 should be hidden

    // Clear search
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // ==========================================
    // SCENARIO 5: Update Task (Mark as Complete)
    // ===========================================
    final firstCheckbox = find.byType(Checkbox).first;
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    // Verify it was checked (Testing the Optimistic State Update)
    Checkbox checkboxWidget = tester.widget(firstCheckbox);
    expect(checkboxWidget.value, isTrue);

    // ==========================
    // SCENARIO 6: Delete a Task
    // ==========================
    final task1Tile = find.widgetWithText(ListTile, task1);
    final deleteButton = find.descendant(
        of: task1Tile, matching: find.byIcon(Icons.delete_outline_rounded));

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify task1 is gone, but task2 remains
    expect(find.text(task1), findsNothing);
    expect(find.text(task2), findsOneWidget);

    // ===================================
    // SCENARIO 7: Logout
    // ===================================
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
