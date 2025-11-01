class WeatherPoint {
  final DateTime timestamp;
  final double? temperature; // °C
  final double? precipitation; // mm
  final int? precipitationProbability; // %
  final double? windSpeed; // km/h

  WeatherPoint({
    required this.timestamp,
    this.temperature,
    this.precipitation,
    this.precipitationProbability,
    this.windSpeed,
  });

  factory WeatherPoint.fromJson(Map<String, dynamic> j) => WeatherPoint(
        timestamp: DateTime.parse(j['timestamp']),
        temperature: (j['temperature'] as num?)?.toDouble(),
        precipitation: (j['precipitation'] as num?)?.toDouble(),
        precipitationProbability: (j['precipitation_probability'] as num?)?.toInt(),
        windSpeed: (j['wind_speed'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'temperature': temperature,
        'precipitation': precipitation,
        'precipitation_probability': precipitationProbability,
        'wind_speed': windSpeed,
      };
}
