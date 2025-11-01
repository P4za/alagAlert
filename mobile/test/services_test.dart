import 'package:flutter_test/flutter_test.dart';
import 'package:alagalert/services/weather_service.dart';
import 'package:alagalert/models/weather.dart';

void main() {
  group('WeatherService', () {
    test('filterByRainIntensity - low', () {
      final points = [
        WeatherPoint(
          timestamp: DateTime.now(),
          precipitation: 1.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 1)),
          precipitation: 5.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 2)),
          precipitation: 15.0,
        ),
      ];

      final filtered = WeatherService.filterByRainIntensity(points, 'low');
      expect(filtered.length, 1);
      expect(filtered.first.precipitation, 1.0);
    });

    test('filterByRainIntensity - medium', () {
      final points = [
        WeatherPoint(
          timestamp: DateTime.now(),
          precipitation: 1.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 1)),
          precipitation: 5.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 2)),
          precipitation: 15.0,
        ),
      ];

      final filtered = WeatherService.filterByRainIntensity(points, 'medium');
      expect(filtered.length, 1);
      expect(filtered.first.precipitation, 5.0);
    });

    test('filterByRainIntensity - high', () {
      final points = [
        WeatherPoint(
          timestamp: DateTime.now(),
          precipitation: 1.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 1)),
          precipitation: 5.0,
        ),
        WeatherPoint(
          timestamp: DateTime.now().add(const Duration(hours: 2)),
          precipitation: 15.0,
        ),
      ];

      final filtered = WeatherService.filterByRainIntensity(points, 'high');
      expect(filtered.length, 1);
      expect(filtered.first.precipitation, 15.0);
    });

    test('WeatherDaySummary.fromPoints - calcula corretamente', () {
      final date = DateTime.now();
      final points = [
        WeatherPoint(
          timestamp: date,
          temperature: 20.0,
          precipitation: 5.0,
          windSpeed: 10.0,
          precipitationProbability: 60,
        ),
        WeatherPoint(
          timestamp: date.add(const Duration(hours: 1)),
          temperature: 22.0,
          precipitation: 3.0,
          windSpeed: 12.0,
          precipitationProbability: 40,
        ),
      ];

      final summary = WeatherDaySummary.fromPoints(points, date);

      expect(summary.avgTemperature, 21.0);
      expect(summary.totalPrecipitation, 8.0);
      expect(summary.maxPrecipitation, 5.0);
      expect(summary.avgWindSpeed, 11.0);
      expect(summary.avgPrecipitationProbability, 50);
    });

    test('WeatherDaySummary.riskLevel - alto', () {
      final date = DateTime.now();
      final points = [
        WeatherPoint(
          timestamp: date,
          precipitation: 30.0,
        ),
        WeatherPoint(
          timestamp: date.add(const Duration(hours: 1)),
          precipitation: 25.0,
        ),
      ];

      final summary = WeatherDaySummary.fromPoints(points, date);
      expect(summary.riskLevel, 'Alto');
    });

    test('WeatherDaySummary.riskLevel - médio', () {
      final date = DateTime.now();
      final points = [
        WeatherPoint(
          timestamp: date,
          precipitation: 15.0,
        ),
        WeatherPoint(
          timestamp: date.add(const Duration(hours: 1)),
          precipitation: 10.0,
        ),
      ];

      final summary = WeatherDaySummary.fromPoints(points, date);
      expect(summary.riskLevel, 'Moderado');
    });

    test('WeatherDaySummary.riskLevel - baixo', () {
      final date = DateTime.now();
      final points = [
        WeatherPoint(
          timestamp: date,
          precipitation: 2.0,
        ),
        WeatherPoint(
          timestamp: date.add(const Duration(hours: 1)),
          precipitation: 1.0,
        ),
      ];

      final summary = WeatherDaySummary.fromPoints(points, date);
      expect(summary.riskLevel, 'Baixo');
    });
  });

  group('WeatherPoint', () {
    test('fromJson - parse correto', () {
      final json = {
        'timestamp': '2025-11-01T12:00:00Z',
        'temperature': 25.5,
        'precipitation': 3.2,
        'precipitation_probability': 70,
        'wind_speed': 15.0,
      };

      final point = WeatherPoint.fromJson(json);

      expect(point.temperature, 25.5);
      expect(point.precipitation, 3.2);
      expect(point.precipitationProbability, 70);
      expect(point.windSpeed, 15.0);
    });

    test('toJson - serializa correto', () {
      final point = WeatherPoint(
        timestamp: DateTime.parse('2025-11-01T12:00:00Z'),
        temperature: 25.5,
        precipitation: 3.2,
        precipitationProbability: 70,
        windSpeed: 15.0,
      );

      final json = point.toJson();

      expect(json['temperature'], 25.5);
      expect(json['precipitation'], 3.2);
      expect(json['precipitation_probability'], 70);
      expect(json['wind_speed'], 15.0);
    });
  });
}
