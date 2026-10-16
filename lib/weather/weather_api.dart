import 'dart:convert';
import 'package:http/http.dart' as http;

const weatherCities = {
  'Tagbilaran': (9.65, 123.85),
  'Cebu': (10.32, 123.89),
  'Manila': (14.60, 120.98),
};

class Weather {
  const Weather(this.temperature, this.wind, this.code, this.time);
  final double temperature;
  final double wind;
  final int code;
  final String time;

  String get condition => switch (code) {
        0 => 'Clear sky',
        1 || 2 => 'Partly cloudy',
        3 => 'Overcast',
        45 || 48 => 'Fog',
        >= 51 && <= 57 => 'Drizzle',
        >= 61 && <= 67 => 'Rain',
        >= 71 && <= 77 => 'Snow',
        >= 80 && <= 82 => 'Rain showers',
        85 || 86 => 'Snow showers',
        >= 95 && <= 99 => 'Thunderstorm',
        _ => 'Conditions unavailable',
      };
}

class WeatherApi {
  WeatherApi(this.client, {this.timeout = const Duration(seconds: 12)});
  final http.Client client;
  final Duration timeout;

  Future<Weather?> fetch(String city) async {
    final coordinates = weatherCities[city];
    if (coordinates == null) throw ArgumentError.value(city, 'city');
    final response = await client
        .get(Uri.https('api.open-meteo.com', '/v1/forecast', {
          'latitude': '${coordinates.$1}',
          'longitude': '${coordinates.$2}',
          'current': 'temperature_2m,wind_speed_10m,weather_code',
          'temperature_unit': 'celsius',
          'wind_speed_unit': 'kmh',
          'timezone': 'Asia/Manila',
        }))
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Weather service unavailable');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) throw const FormatException('Invalid weather response');
    final current = data['current'];
    if (current == null || (current is Map && current.isEmpty)) return null;
    if (current is! Map) throw const FormatException('Invalid current weather');
    final temperature = current['temperature_2m'];
    final wind = current['wind_speed_10m'];
    final code = current['weather_code'];
    final time = current['time'];
    if (temperature == null || wind == null || code == null || time == null) {
      return null;
    }
    if (temperature is! num ||
        !temperature.isFinite ||
        wind is! num ||
        !wind.isFinite ||
        wind < 0 ||
        code is! int ||
        time is! String ||
        DateTime.tryParse(time) == null) {
      throw const FormatException('Invalid weather values');
    }
    return Weather(temperature.toDouble(), wind.toDouble(), code, time);
  }
}
