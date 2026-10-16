import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../ui/discfit_widgets.dart';
import 'weather_api.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, this.api});
  final WeatherApi? api;
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final http.Client? _client;
  late final WeatherApi _api;
  String _city = weatherCities.keys.first;
  Weather? _weather;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _client = widget.api == null ? http.Client() : null;
    _api = widget.api ?? WeatherApi(_client!);
    _fetch();
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  Future<void> _fetch() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _weather = null;
    });
    try {
      final result = await _api.fetch(_city);
      if (mounted && request == _request) setState(() => _weather = result);
    } on TimeoutException {
      if (mounted && request == _request) {
        setState(() => _error = 'Weather request timed out. Please retry.');
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error =
            'Could not load weather. Check your internet connection and retry.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    return Scaffold(
      appBar: AppBar(title: const Text('Training Weather')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const PageHeading('Before you head outside',
              'Check the current conditions for your practice.'),
          DropdownButtonFormField<String>(
            initialValue: _city,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_on_outlined)),
            items: weatherCities.keys
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (city) {
              if (city != null && city != _city) {
                setState(() => _city = city);
                _fetch();
              }
            },
          ),
          const SizedBox(height: 24),
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (_loading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  const Center(child: Text('Loading weather…')),
                ] else if (_error != null) ...[
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!),
                ] else if (weather == null) ...[
                  const Icon(Icons.cloud_queue, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                      'No weather data available for this city. Try again later.'),
                ] else ...[
                  Text(_city, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text('${weather.temperature.toStringAsFixed(1)} °C',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(weather.condition),
                  const SizedBox(height: 16),
                  LabelBadge('Wind: ${weather.wind.toStringAsFixed(1)} km/h',
                      icon: Icons.air),
                  const SizedBox(height: 16),
                  Text(
                      'Weather time: ${weather.time.replaceFirst('T', ' ')} (Philippine time)'),
                ],
              ])),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: const Icon(Icons.refresh),
              label: Text(_error != null || (!_loading && weather == null)
                  ? 'Retry'
                  : 'Refresh weather')),
          const SizedBox(height: 20),
          const SelectableText(
              'Weather data: Open-Meteo (CC BY 4.0)\nhttps://open-meteo.com/'),
        ]),
      ))),
    );
  }
}
