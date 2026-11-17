import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopper/core/connection/connection_state.dart';
import 'package:hopper/shared/widgets/status_dot.dart';
import 'package:hopper/shared/widgets/empty_state.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('StatusDot displays status label and dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusDot(status: DeviceStatus.connected),
          ),
        ),
      );

      expect(find.text('connected'), findsOneWidget);
    });

    testWidgets('EmptyState renders title, description, and action button',
        (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.phonelink_off,
              title: 'No Devices Found',
              description: 'Turn on wireless debugging to connect.',
              action: ElevatedButton(
                onPressed: () => actionTriggered = true,
                child: const Text('Retry'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Devices Found'), findsOneWidget);
      expect(
          find.text('Turn on wireless debugging to connect.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(actionTriggered, isTrue);
    });
  });
}
