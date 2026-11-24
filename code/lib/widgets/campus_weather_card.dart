import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Loads and displays weather separately from Home's shared academic data.
class CampusWeatherCard extends StatefulWidget {
  const CampusWeatherCard({super.key});

  @override
  State<CampusWeatherCard> createState() => _CampusWeatherCardState();
}

class _CampusWeatherCardState extends State<CampusWeatherCard> {
  late Future<_CampusWeather> _weather;

  @override
  void initState() {
    super.initState();

    // Start once, rather than sending a request every time Home rebuilds.
    _weather = _fetchWeather();
  }

  Future<_CampusWeather> _fetchWeather() async {
    // Fixed North campus coordinates; no device location permission is needed.
    final Uri url = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '43.945',
      'longitude': '-78.896',
      'current': 'temperature_2m,weather_code',
      'temperature_unit': 'celsius',
      'timezone': 'UTC',
    });

    final http.Client client = http.Client();

    try {
      // A timeout prevents an endless loading indicator.
      final http.Response response = await client
          .get(url)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw StateError('Weather service unavailable');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final Map<String, dynamic> current =
          data['current'] as Map<String, dynamic>;

      final double temperature = (current['temperature_2m'] as num).toDouble();

      if (!temperature.isFinite) {
        throw const FormatException('Invalid temperature');
      }

      // The request uses UTC. Convert the returned time to the device's timezone.
      final DateTime updatedAt = DateTime.parse('${current['time']}Z')
          .toLocal();

      return _CampusWeather(
        temperature: temperature,
        code: current['weather_code'] as int,
        updatedAt: updatedAt,
      );
    } finally {
      client.close();
    }
  }

  void _refresh() {
    setState(() {
      _weather = _fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<_CampusWeather>(
          future: _weather,
          builder: (context, snapshot) {
            // Loading state.
            if (snapshot.connectionState != ConnectionState.done) {
              return const Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading campus weather',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(child: Text('Loading campus weather…')),
                ],
              );
            }

            // Network or response errors show a useful message and Retry.
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weather is unavailable. '
                    'Check your connection and try again.',
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              );
            }

            // Successful response.
            final _CampusWeather weather = snapshot.data!;
            final String updatedTime = TimeOfDay.fromDateTime(weather.updatedAt)
                .format(context);

            final String updatedDate =
                '${weather.updatedAt.day}/'
                '${weather.updatedAt.month}/'
                '${weather.updatedAt.year}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ontario Tech · North campus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${weather.temperature.toStringAsFixed(1)} °C',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(weather.description),
                const SizedBox(height: 12),
                Text(
                  'Updated $updatedDate at $updatedTime',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Text('Weather data: Open-Meteo'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Holds the weather values returned by the web service.
class _CampusWeather {
  const _CampusWeather({
    required this.temperature,
    required this.code,
    required this.updatedAt,
  });

  final double temperature;
  final int code;
  final DateTime updatedAt;

  // Translate WMO weather codes into readable conditions.
  String get description {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Current conditions';
    }
  }
}
