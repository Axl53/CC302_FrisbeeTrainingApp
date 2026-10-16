import 'dart:convert';
import 'dart:io';

// A read-only REST API using Dart's built-in HTTP server.
// Keeping the data file injectable lets tests use temporary catalogs.
Future<HttpServer> startDrillsServer({
  required File dataFile,
  String host = '127.0.0.1',
  int port = 8000,
}) async {
  final server = await HttpServer.bind(host, port);
  server.listen((request) => handleRequest(request, dataFile));
  return server;
}

Future<void> handleRequest(HttpRequest request, File dataFile) async {
  final response = request.response;
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method == 'OPTIONS') {
    response.statusCode = HttpStatus.noContent;
    await response.close();
    return;
  }

  response.headers.contentType = ContentType.json;
  Object body;
  if (request.method != 'GET') {
    response.statusCode = HttpStatus.methodNotAllowed;
    response.headers.set('Allow', 'GET, OPTIONS');
    body = {'error': 'Method not allowed'};
  } else if (request.uri.path == '/health') {
    body = {'status': 'ok'};
  } else if (request.uri.path == '/api/drills') {
    try {
      final drills = jsonDecode(await dataFile.readAsString());
      if (drills is! List) {
        throw const FormatException('Expected a drill list');
      }
      body = drills;
    } on FileSystemException {
      response.statusCode = HttpStatus.internalServerError;
      body = {'error': 'Could not load drills'};
    } on FormatException {
      response.statusCode = HttpStatus.internalServerError;
      body = {'error': 'Could not load drills'};
    }
  } else {
    response.statusCode = HttpStatus.notFound;
    body = {'error': 'Not found'};
  }
  response.write(jsonEncode(body));
  await response.close();
}

Future<void> main(List<String> args) async {
  var host = '127.0.0.1';
  var port = 8000;
  for (var index = 0; index < args.length; index += 2) {
    if (index + 1 >= args.length ||
        !['--host', '--port'].contains(args[index])) {
      stderr.writeln(
          'Usage: dart run backend/server.dart [--host 0.0.0.0] [--port 8000]');
      exitCode = 64;
      return;
    }
    if (args[index] == '--host') {
      host = args[index + 1];
    } else {
      final number = int.tryParse(args[index + 1]);
      if (number == null || number < 1 || number > 65535) {
        stderr.writeln('Port must be an integer between 1 and 65535.');
        exitCode = 64;
        return;
      }
      port = number;
    }
  }

  try {
    await startDrillsServer(
      dataFile: File.fromUri(Platform.script.resolve('drills.json')),
      host: host,
      port: port,
    );
    stdout.writeln('Drills API: http://$host:$port/api/drills');
    stdout.writeln('Leave this terminal running. Press Ctrl+C to stop.');
  } on SocketException catch (error) {
    stderr.writeln('Could not start the API on $host:$port: ${error.message}');
    stderr.writeln('Check whether another server is already using this port.');
    exitCode = 1;
  }
}
