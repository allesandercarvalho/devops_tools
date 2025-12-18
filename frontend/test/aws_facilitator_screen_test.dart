import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/cli_hub/aws/aws_facilitator_screen.dart';

void main() {
  testWidgets('AWS Facilitator Screen UI Structure Verification', (WidgetTester tester) async {
    // Set a desktop-like size to avoid overflow in the terminal/layout
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AWSFacilitatorScreen(
          searchQuery: '',
          viewType: 'grid',
          selectedCategory: 'Compute',
        ),
      ),
    ));

    // 1. Verify Top Bar Elements (Search, View Toggles)
    // Identifier and Modules are now in the parent screen (AWSConfigsScreen)
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsOneWidget);

    // 2. Verify Filter Bar Categories
    expect(find.text('Compute'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    // 4. Verify Content Area Selection Labels
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Resource'), findsOneWidget);

    // 5. Verify Default Selection
    // "EC2" should be visible in the Service dropdown and potentially in the list if selected
    expect(find.text('EC2'), findsAtLeastNWidgets(1)); 
    
    // "Instances" should be visible in the Resource dropdown
    expect(find.text('Instances'), findsAtLeastNWidgets(1));

    // 6. Verify Actions are present (e.g., Launch, Start for EC2 Instances)
    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
