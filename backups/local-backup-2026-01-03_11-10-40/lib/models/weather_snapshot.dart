class WeatherSnapshot {
  /// Stable code for storage (e.g. sunny/cloudy/rain/snow).
  final String condition;

  /// Optional temperature in Celsius.
  final double? tempC;

  /// Optional feels-like temperature in Celsius.
  final double? feelsLikeC;

  /// Optional humidity percent (0-100).
  final int? humidityPct;

  /// Optional wind speed (m/s).
  final double? windSpeedMs;

  /// Optional precipitation for last 1 hour (mm).
  final double? precipitation1hMm;

  /// Optional capture time (UTC recommended).
  final DateTime? capturedAt;

  /// Optional approximate latitude (rounded to reduce precision).
  final double? lat;

  /// Optional approximate longitude (rounded to reduce precision).
  final double? lon;

  /// How it was captured (e.g. manual / api / cached).
  final String source;

  const WeatherSnapshot({
    required this.condition,
    this.tempC,
    this.feelsLikeC,
    this.humidityPct,
    this.windSpeedMs,
    this.precipitation1hMm,
    this.capturedAt,
    this.lat,
    this.lon,
    this.source = 'manual',
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final temp = json['tempC'];
    final feelsLike = json['feelsLikeC'];
    final humidity = json['humidityPct'];
    final windSpeed = json['windSpeedMs'];
    final precip1h = json['precipitation1hMm'];
    final capturedAtRaw = json['capturedAt'];
    final latRaw = json['lat'];
    final lonRaw = json['lon'];
    return WeatherSnapshot(
      condition: json['condition'] as String? ?? '',
      tempC: temp is num ? temp.toDouble() : null,
      feelsLikeC: feelsLike is num ? feelsLike.toDouble() : null,
      humidityPct: humidity is num ? humidity.toInt() : null,
      windSpeedMs: windSpeed is num ? windSpeed.toDouble() : null,
      precipitation1hMm: precip1h is num ? precip1h.toDouble() : null,
      capturedAt: capturedAtRaw is String
          ? DateTime.tryParse(capturedAtRaw)
          : null,
      lat: latRaw is num ? latRaw.toDouble() : null,
      lon: lonRaw is num ? lonRaw.toDouble() : null,
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      if (tempC != null) 'tempC': tempC,
      if (feelsLikeC != null) 'feelsLikeC': feelsLikeC,
      if (humidityPct != null) 'humidityPct': humidityPct,
      if (windSpeedMs != null) 'windSpeedMs': windSpeedMs,
      if (precipitation1hMm != null) 'precipitation1hMm': precipitation1hMm,
      if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      'source': source,
    };
  }
}
