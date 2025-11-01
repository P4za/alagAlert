import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';

class GeocodeService {
  // Cache em memória para evitar requisições duplicadas
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Timer para debounce
  static Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  /// Limpa entradas expiradas do cache
  static void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiry));
  }

  /// Retorna valor do cache se válido
  static List<Map<String, dynamic>>? _getFromCache(String key) {
    _cleanExpiredCache();
    final entry = _cache[key];
    if (entry != null && DateTime.now().isBefore(entry.expiry)) {
      return entry.data;
    }
    return null;
  }

  /// Armazena no cache
  static void _putInCache(String key, List<Map<String, dynamic>> data) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(_cacheDuration),
    );
  }

  // Estados (UFs)
  static Future<List<Map<String, dynamic>>> searchStates(String query) async {
    if (query.trim().isEmpty) return [];

    final cacheKey = 'states:${query.trim().toLowerCase()}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.parse('${ApiService.baseUrl}/geocode-states').replace(queryParameters: {
      'q': query.trim(),
      'country': 'br',
      'limit': '27',
    });

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final result = data.cast<Map<String, dynamic>>();
      _putInCache(cacheKey, result);
      return result;
    } catch (e) {
      return [];
    }
  }

  // Cidades (filtradas pela UF)
  static Future<List<Map<String, dynamic>>> searchCities({
    required String cityQuery,
    required String uf,
    int limit = 20,
  }) async {
    if (cityQuery.trim().isEmpty || uf.trim().isEmpty) return [];

    final cacheKey = 'cities:${uf.toUpperCase()}:${cityQuery.trim().toLowerCase()}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.parse('${ApiService.baseUrl}/geocode').replace(queryParameters: {
      'q': cityQuery.trim(),
      'country': 'br',
      'limit': '$limit',
      'cities_only': 'true',
      'uf': uf.toUpperCase(),
    });

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final List data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      final result = data.cast<Map<String, dynamic>>();
      _putInCache(cacheKey, result);
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Alias para compatibilidade (usado em city_picker_screen.dart)
  static Future<List<Map<String, String>>> suggestCities({
    required String query,
    required String uf,
  }) async {
    final results = await searchCities(cityQuery: query, uf: uf);
    return results.map((item) {
      return {
        'city': (item['city'] ?? '').toString(),
        'displayName': (item['display_name'] ?? '').toString(),
      };
    }).toList();
  }
}

/// Entrada de cache com dados e tempo de expiração
class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
}
