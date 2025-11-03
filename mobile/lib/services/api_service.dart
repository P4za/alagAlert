import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/risk.dart';
import '../models/location.dart';

class ApiService {
  static final String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://191.252.193.10:8000',
  );

  static Uri _u(String path, [Map<String, String>? query]) {
    final base = _resolveBaseUri();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final basePath = _sanitizeBasePath(base.path);
    final fullPath = basePath.isEmpty ? normalizedPath : '$basePath$normalizedPath';
    final target = base.replace(path: fullPath, queryParameters: null);
    return query == null ? target : target.replace(queryParameters: query);
  }

  static Uri _resolveBaseUri() {
    final raw = baseUrl.trim();
    if (raw.isEmpty) {
      return kIsWeb ? Uri.base : Uri.parse('http://191.252.193.10:8000');
    }

    if (raw.contains('://')) {
      return Uri.parse(raw);
    }

    if (!kIsWeb) {
      if (raw.startsWith('/')) {
        throw StateError(
          'API_URL deve ser uma URL absoluta fora do ambiente web. Valor atual: $raw',
        );
      }
      return Uri.parse('http://$raw');
    }

    final relative = raw.startsWith('/') ? raw : '/$raw';
    return Uri.base.resolve(relative);
  }

  static String _sanitizeBasePath(String path) {
    if (path.isEmpty || path == '/') {
      return '';
    }
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static Future<RiskResult> getRiskByCity(String uf, String city) async {
    final url = _u('/risk/by-city', {
      'uf': uf,
      'city': Uri.encodeQueryComponent(city),
    });
    debugPrint('GET $url');

    final r = await http.get(url).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      debugPrint('ERRO ${r.statusCode}: ${r.body}');
      throw Exception('Erro ${r.statusCode} ao obter risco');
    }
    return RiskResult.fromJson(jsonDecode(r.body));
  }

  static Future<List<GeoCodeResult>> geocode(String q) async {
    final url = _u('/geocode', {
      'q': Uri.encodeQueryComponent(q),
    });
    debugPrint('GET $url');

    final r = await http.get(url).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return [];
    final data = jsonDecode(r.body) as List;
    return data.map((e) => GeoCodeResult.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getRegions(String level, {String? uf}) async {
    final query = {'level': level, if (uf != null) 'uf': uf};
    final url = _u('/regions', query);
    debugPrint('GET $url');

    final r = await http.get(url).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      debugPrint('ERRO ${r.statusCode}: ${r.body}');
      throw Exception('Erro ao obter regioes');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
