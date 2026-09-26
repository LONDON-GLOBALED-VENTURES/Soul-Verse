import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soulverse/features/example/example_api.dart';
import 'package:soulverse/features/example/example_model.dart';
import 'package:soulverse/features/example/example_provider.dart';
import 'package:soulverse/main.dart';

class _FakeExampleApi implements ExampleApi {
  @override
  Future<List<Post>> getPosts() async => [
    Post(id: 1, title: 'Hello', body: 'World'),
  ];

  @override
  Future<Post> getPost(int id) async => Post(id: id, title: 'Hello', body: 'World');
}

void main() {
  testWidgets('Posts page shows fetched posts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [exampleApiProvider.overrideWithValue(_FakeExampleApi())],
        child: const MyApp(),
      ),
    );

    expect(find.text('Posts'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
  });
}
