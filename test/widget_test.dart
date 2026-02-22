// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_application_1/data/services/push_notification_service.dart';
import 'package:flutter_application_1/presentation/app/app_root.dart';
import 'package:flutter_application_1/presentation/providers/safety_providers.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushNotificationProvider.overrideWithValue(_FakePushService()),
        ],
        child: const AppRoot(),
      ),
    );

    expect(find.text('SafeTour'), findsOneWidget);
  });
}

class _FakePushService implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => null;
}
