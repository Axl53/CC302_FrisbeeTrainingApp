import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'drill.dart';

class DrillsApi {
  DrillsApi(this.client,
      {String? baseUrl, this.timeout = const Duration(seconds: 10)})
      : baseUrl = baseUrl ??
            const String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final http.Client client;
  final String baseUrl;
  final Duration timeout;

  Future<List<Drill>> fetch() async {
    final root = baseUrl.isNotEmpty
        ? baseUrl
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000'
            : 'http://localhost:8000');
    final response = await client
        .get(Uri.parse('${root.replaceFirst(RegExp(r'/+$'), '')}/api/drills'))
        .timeout(timeout);
    if (response.statusCode != 200) throw Exception('Drills request failed');
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) throw const FormatException('Expected a drill list');
    return data.map((item) {
      if (item is! Map ||
          item['title'] is! String ||
          (item['title'] as String).trim().isEmpty ||
          !['Beginner', 'Intermediate', 'Advanced'].contains(item['level']) ||
          item['minutes'] is! int ||
          (item['minutes'] as int) <= 0 ||
          item['instructions'] is! String ||
          (item['instructions'] as String).trim().isEmpty) {
        throw const FormatException('Invalid drill');
      }
      return Drill(item['title'] as String, item['level'] as String,
          item['minutes'] as int, item['instructions'] as String);
    }).toList();
  }
}
