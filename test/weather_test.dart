import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frisbee_training/weather/weather_api.dart';
import 'package:frisbee_training/weather/weather_screen.dart';
import 'package:frisbee_training/drills_list.dart';

void main() {
  const body =
      '{"current":{"temperature_2m":29.5,"wind_speed_10m":12,"weather_code":2,"time":"2026-10-16T12:00"}}';

  test('requests HTTPS weather with explicit units and city coordinates',
      () async {
    final client = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.queryParameters['latitude'], '10.32');
      expect(request.url.queryParameters['wind_speed_unit'], 'kmh');
      return http.Response(body, 200);
    });
    addTearDown(client.close);
    final weather = (await WeatherApi(client).fetch('Cebu'))!;
    expect(weather.temperature, 29.5);
    expect(weather.wind, 12);
    expect(weather.condition, 'Partly cloudy');
  });

  test('empty, invalid, failed and timed out responses are handled', () async {
    for (final payload in [
      '{}',
      '{"current":{}}',
      '{"current":{"temperature_2m":null}}'
    ]) {
      final client = MockClient((_) async => http.Response(payload, 200));
      expect(await WeatherApi(client).fetch('Manila'), isNull);
      client.close();
    }
    for (final response in [
      http.Response('bad json', 200),
      http.Response('{}', 503),
      http.Response(
          '{"current":{"temperature_2m":"bad","wind_speed_10m":12,"weather_code":0,"time":"2026-10-16T12:00"}}',
          200)
    ]) {
      final client = MockClient((_) async => response);
      await expectLater(WeatherApi(client).fetch('Manila'), throwsException);
      client.close();
    }
    final client = MockClient((_) => Completer<http.Response>().future);
    addTearDown(client.close);
    await expectLater(
        WeatherApi(client, timeout: const Duration(milliseconds: 1))
            .fetch('Cebu'),
        throwsA(isA<TimeoutException>()));
  });

  testWidgets('weather loading, error, retry, empty and success states',
      (tester) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) return pending.future;
      return http.Response(calls == 2 ? '{}' : body, 200);
    });
    addTearDown(client.close);
    await tester
        .pumpWidget(MaterialApp(home: WeatherScreen(api: WeatherApi(client))));
    expect(find.text('Loading weather…'), findsOneWidget);
    pending.complete(http.Response('{}', 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load weather'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No weather data available'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('29.5 °C'), findsOneWidget);
    expect(find.text('Wind: 12.0 km/h'), findsOneWidget);
  });

  testWidgets('changing city ignores an older request', (tester) async {
    final first = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.queryParameters['latitude'] == '9.65') {
        return first.future;
      }
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    await tester
        .pumpWidget(MaterialApp(home: WeatherScreen(api: WeatherApi(client))));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cebu').last);
    await tester.pumpAndSettle();
    first.complete(http.Response(body, 200));
    await tester.pumpAndSettle();
    expect(find.text('29.5 °C'), findsNothing);
    expect(find.textContaining('No weather data available'), findsOneWidget);
  });

  testWidgets('bundled drill search and difficulty filtering work offline',
      (tester) async {
    Widget app(String query, String level) => MaterialApp(
        home: Scaffold(body: DrillsList(query: query, level: level)));
    await tester.pumpWidget(app('Backhand', 'All'));
    expect(find.text('Backhand Throw'), findsOneWidget);
    await tester.pumpWidget(app('Backhand', 'Advanced'));
    expect(find.textContaining('No matching drills'), findsOneWidget);
    await tester.pumpWidget(app('', 'Advanced'));
    expect(find.text('Long Throw Accuracy'), findsOneWidget);
  });
}
