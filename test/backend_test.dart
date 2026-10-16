import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../backend/server.dart';

void main() {
  late HttpServer server;
  late HttpClient client;
  late Directory temporary;
  late File data;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('discfit_backend_');
    data = File('${temporary.path}/drills.json');
    await data.writeAsString(await File('backend/drills.json').readAsString());
    server = await startDrillsServer(dataFile: data, port: 0);
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
    await temporary.delete(recursive: true);
  });

  Future<(int, String, HttpHeaders)> request(String path,
      {String method = 'GET'}) async {
    final outgoing = await client.openUrl(
        method, Uri.parse('http://127.0.0.1:${server.port}$path'));
    final response = await outgoing.close();
    return (
      response.statusCode,
      await utf8.decoder.bind(response).join(),
      response.headers
    );
  }

  test('serves the six original drills and browser CORS headers', () async {
    final (status, body, headers) = await request('/api/drills');
    expect(status, 200);
    expect(headers.value('access-control-allow-origin'), '*');
    expect(headers.contentType?.mimeType, 'application/json');
    final drills = jsonDecode(body) as List;
    expect(drills.length, 6);
    expect(drills.first['title'], 'Backhand Throw');
    for (final drill in drills) {
      expect(drill['minutes'], greaterThan(0));
      expect(drill['instructions'], isNotEmpty);
    }
  });

  test('reads catalog changes, including empty results, without restart',
      () async {
    await data.writeAsString('[]');
    final (status, body, _) = await request('/api/drills');
    expect(status, 200);
    expect(jsonDecode(body), isEmpty);
  });

  test('invalid, non-list and missing catalogs return recoverable JSON errors',
      () async {
    for (final invalid in ['bad json', '{}']) {
      await data.writeAsString(invalid);
      final (status, body, _) = await request('/api/drills');
      expect(status, 500);
      expect(jsonDecode(body), {'error': 'Could not load drills'});
    }
    await data.delete();
    expect((await request('/api/drills')).$1, 500);
  });

  test('health, missing routes, preflight and unsupported methods', () async {
    final health = await request('/health');
    expect(health.$1, 200);
    expect(jsonDecode(health.$2), {'status': 'ok'});
    expect((await request('/missing')).$1, 404);
    final preflight = await request('/api/drills', method: 'OPTIONS');
    expect(preflight.$1, 204);
    expect(preflight.$3.value('access-control-allow-methods'), 'GET, OPTIONS');
    final post = await request('/api/drills', method: 'POST');
    expect(post.$1, 405);
    expect(post.$3.value('allow'), 'GET, OPTIONS');
  });
}
