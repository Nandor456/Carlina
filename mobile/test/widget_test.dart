import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/main.dart';

class _FakeApiService extends ApiService {
  _FakeApiService() : super(cookieJar: CookieJar());

  @override
  Future<Map<String, dynamic>?> getMe() async => null;
}

void main() {
  testWidgets('App smoke test — renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWithValue(CookieJar()),
          apiServiceProvider.overrideWithValue(_FakeApiService()),
        ],
        child: const AutoDocApp(),
      ),
    );
    // App should mount without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
