import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frisbee_training/drills_api.dart';
import 'package:frisbee_training/drills_list.dart';

void main() {
  const body =
      '[{"title":"Remote drill","level":"Beginner","minutes":12,"instructions":"Practice passing."}]';
  test('fetches HTTP drills and rejects invalid responses', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://localhost:8000/api/drills');
      return http.Response(body, 200);
    });
    addTearDown(client.close);
    expect(
        (await DrillsApi(client, baseUrl: 'http://localhost:8000/').fetch())
            .single
            .title,
        'Remote drill');
    for (final response in [
      http.Response('{}', 200),
      http.Response('[{}]', 200),
      http.Response('bad', 200),
      http.Response('[]', 500)
    ]) {
      final bad = MockClient((_) async => response);
      await expectLater(DrillsApi(bad).fetch(), throwsException);
      bad.close();
    }
    final slow = MockClient((_) => Completer<http.Response>().future);
    addTearDown(slow.close);
    await expectLater(
        DrillsApi(slow, timeout: const Duration(milliseconds: 1)).fetch(),
        throwsA(isA<TimeoutException>()));
  });

  testWidgets('loading, failed request, retry, empty, fetched drill and search',
      (tester) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) return pending.future;
      return http.Response(calls == 2 ? '[]' : body, 200);
    });
    addTearDown(client.close);
    final api = DrillsApi(client);
    Widget app(String query) => MaterialApp(
        home: Scaffold(body: DrillsList(query: query, level: 'All', api: api)));
    await tester.pumpWidget(app(''));
    expect(find.text('Loading drills…'), findsOneWidget);
    pending.complete(http.Response('{}', 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load drills'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No drills available'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Remote drill'), findsOneWidget);
    await tester.tap(find.text('Remote drill'));
    await tester.pumpAndSettle();
    expect(find.text('Practice passing.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('missing'));
    expect(find.textContaining('No matching drills'), findsOneWidget);
  });
}
