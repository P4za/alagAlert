import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

/// Serviço dedicado para busca de meteorologia via Open-Meteo
/// Suporta cache, timeouts e filtros por dia/intensidade
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const Duration _cacheDuration = Duration(minutes: 10);
  static const Duration _requestTimeout = Duration(seconds: 8);

  // Cache em memória: chave = "lat,lon,days"
  static final Map<String, _WeatherCacheEntry> _cache = {};

  /// Limpa entradas expiradas do cache
  static void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiry));
  }

  /// Retorna do cache se válido
  static WeatherForecast? _getFromCache(String key) {
    _cleanExpiredCache();
    final entry = _cache[key];
    if (entry != null && DateTime.now().isBefore(entry.expiry)) {
      return entry.forecast;
    }
    return null;
  }

  /// Armazena no cache
  static void _putInCache(String key, WeatherForecast forecast) {
    _cache[key] = _WeatherCacheEntry(
      forecast: forecast,
      expiry: DateTime.now().add(_cacheDuration),
    );
  }

  /// Busca previsão meteorológica
  ///
  /// Parâmetros:
  /// - [lat], [lon]: coordenadas
  /// - [forecastDays]: número de dias (1-7, padrão: 3)
  /// - [timezone]: fuso horário (padrão: America/Sao_Paulo)
  static Future<WeatherForecast> fetchForecast({
    required double lat,
    required double lon,
    int forecastDays = 3,
    String timezone = 'America/Sao_Paulo',
  }) async {
    // Normaliza parâmetros para cache
    final latRound = lat.toStringAsFixed(4);
    final lonRound = lon.toStringAsFixed(4);
    final cacheKey = '$latRound,$lonRound,$forecastDays';

    // Tenta cache primeiro
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Busca da API
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': latRound,
      'longitude': lonRound,
      'hourly': 'temperature_2m,precipitation,precipitation_probability,wind_speed_10m',
      'forecast_days': forecastDays.toString(),
      'timezone': timezone,
    });

    try {
      final response = await http.get(uri).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw WeatherServiceException(
          'Erro ${response.statusCode} ao buscar previsão meteorológica',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final forecast = WeatherForecast.fromJson(json);

      // Armazena no cache
      _putInCache(cacheKey, forecast);

      return forecast;
    } on TimeoutException {
      throw WeatherServiceException(
        'Timeout ao buscar previsão (limite: ${_requestTimeout.inSeconds}s)',
      );
    } catch (e) {
      throw WeatherServiceException('Erro ao buscar previsão: $e');
    }
  }

  /// Busca resumo do dia específico
  ///
  /// Retorna um [WeatherDaySummary] com médias/totais do dia
  static Future<WeatherDaySummary> fetchDaySummary({
    required double lat,
    required double lon,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final daysDiff = date.difference(DateTime(now.year, now.month, now.day)).inDays;

    // Valida que a data está no futuro próximo (0-7 dias)
    if (daysDiff < 0 || daysDiff > 7) {
      throw WeatherServiceException(
        'Data inválida: use entre hoje e +7 dias',
      );
    }

    final forecast = await fetchForecast(
      lat: lat,
      lon: lon,
      forecastDays: daysDiff + 1,
    );

    // Filtra pontos do dia solicitado
    final targetDate = DateTime(date.year, date.month, date.day);
    final pointsInDay = forecast.hourlyPoints.where((point) {
      final pointDate = DateTime(
        point.timestamp.year,
        point.timestamp.month,
        point.timestamp.day,
      );
      return pointDate == targetDate;
    }).toList();

    if (pointsInDay.isEmpty) {
      throw WeatherServiceException('Sem dados para a data solicitada');
    }

    return WeatherDaySummary.fromPoints(pointsInDay, date);
  }

  /// Filtra pontos por intensidade de chuva
  ///
  /// Níveis:
  /// - 'low': < 2.5mm/h
  /// - 'medium': 2.5-10mm/h
  /// - 'high': > 10mm/h
  static List<WeatherPoint> filterByRainIntensity(
    List<WeatherPoint> points,
    String intensity,
  ) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return points.where((p) => (p.precipitation ?? 0) < 2.5).toList();
      case 'medium':
        return points
            .where((p) => (p.precipitation ?? 0) >= 2.5 && (p.precipitation ?? 0) <= 10)
            .toList();
      case 'high':
        return points.where((p) => (p.precipitation ?? 0) > 10).toList();
      default:
        return points;
    }
  }
}

/// Exceção específica do WeatherService
class WeatherServiceException implements Exception {
  final String message;
  WeatherServiceException(this.message);

  @override
  String toString() => 'WeatherServiceException: $message';
}

/// Entrada de cache com previsão e tempo de expiração
class _WeatherCacheEntry {
  final WeatherForecast forecast;
  final DateTime expiry;

  _WeatherCacheEntry({required this.forecast, required this.expiry});
}

/// Previsão meteorológica completa
class WeatherForecast {
  final double latitude;
  final double longitude;
  final String timezone;
  final List<WeatherPoint> hourlyPoints;

  WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.hourlyPoints,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourly['time'] as List?)?.cast<String>() ?? [];
    final temps = (hourly['temperature_2m'] as List?)?.cast<num?>() ?? [];
    final precs = (hourly['precipitation'] as List?)?.cast<num?>() ?? [];
    final precProbs = (hourly['precipitation_probability'] as List?)?.cast<num?>() ?? [];
    final winds = (hourly['wind_speed_10m'] as List?)?.cast<num?>() ?? [];

    final points = <WeatherPoint>[];
    for (int i = 0; i < times.length; i++) {
      points.add(WeatherPoint(
        timestamp: DateTime.parse(times[i]),
        temperature: temps.length > i ? temps[i]?.toDouble() : null,
        precipitation: precs.length > i ? precs[i]?.toDouble() : null,
        precipitationProbability: precProbs.length > i ? precProbs[i]?.toInt() : null,
        windSpeed: winds.length > i ? winds[i]?.toDouble() : null,
      ));
    }

    return WeatherForecast(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? 'UTC',
      hourlyPoints: points,
    );
  }
}

/// Resumo meteorológico de um dia
class WeatherDaySummary {
  final DateTime date;
  final double avgTemperature; // °C
  final double totalPrecipitation; // mm
  final double maxPrecipitation; // mm/h
  final double avgWindSpeed; // km/h
  final int avgPrecipitationProbability; // %

  WeatherDaySummary({
    required this.date,
    required this.avgTemperature,
    required this.totalPrecipitation,
    required this.maxPrecipitation,
    required this.avgWindSpeed,
    required this.avgPrecipitationProbability,
  });

  factory WeatherDaySummary.fromPoints(List<WeatherPoint> points, DateTime date) {
    if (points.isEmpty) {
      return WeatherDaySummary(
        date: date,
        avgTemperature: 0,
        totalPrecipitation: 0,
        maxPrecipitation: 0,
        avgWindSpeed: 0,
        avgPrecipitationProbability: 0,
      );
    }

    final temps = points.map((p) => p.temperature ?? 0).toList();
    final precs = points.map((p) => p.precipitation ?? 0).toList();
    final winds = points.map((p) => p.windSpeed ?? 0).toList();
    final probs = points.map((p) => p.precipitationProbability ?? 0).toList();

    return WeatherDaySummary(
      date: date,
      avgTemperature: temps.reduce((a, b) => a + b) / temps.length,
      totalPrecipitation: precs.reduce((a, b) => a + b),
      maxPrecipitation: precs.reduce((a, b) => a > b ? a : b),
      avgWindSpeed: winds.reduce((a, b) => a + b) / winds.length,
      avgPrecipitationProbability: (probs.reduce((a, b) => a + b) / probs.length).round(),
    );
  }

  /// Retorna nível de risco baseado na precipitação
  String get riskLevel {
    if (totalPrecipitation > 50 || maxPrecipitation > 10) return 'Alto';
    if (totalPrecipitation > 20 || maxPrecipitation > 5) return 'Moderado';
    return 'Baixo';
  }
}
