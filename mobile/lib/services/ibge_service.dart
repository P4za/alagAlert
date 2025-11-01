import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para buscar dados diretamente da API do IBGE
/// Não depende do backend - funciona mesmo offline do backend
class IbgeService {
  static const String _baseUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  /// Cache de cidades por UF para evitar requisições repetidas
  static final Map<String, List<Map<String, String>>> _cityCache = {};

  /// Busca todas as cidades de uma UF
  static Future<List<Map<String, String>>> getCitiesByUf(String uf) async {
    final ufUpper = uf.toUpperCase();

    // Retorna do cache se já buscou
    if (_cityCache.containsKey(ufUpper)) {
      return _cityCache[ufUpper]!;
    }

    try {
      final url = Uri.parse('$_baseUrl/estados/$ufUpper/municipios');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final List data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      final cities = data.map((city) {
        return {
          'id': city['id'].toString(),
          'nome': city['nome'].toString(),
        };
      }).toList();

      // Ordena alfabeticamente
      cities.sort((a, b) => a['nome']!.compareTo(b['nome']!));

      // Armazena no cache
      _cityCache[ufUpper] = cities;

      return cities;
    } catch (e) {
      print('Erro ao buscar cidades do IBGE: $e');
      return [];
    }
  }

  /// Filtra cidades por query (busca local após carregar do IBGE)
  static Future<List<Map<String, String>>> searchCities({
    required String uf,
    required String query,
  }) async {
    final allCities = await getCitiesByUf(uf);

    if (query.trim().isEmpty) {
      return allCities;
    }

    final queryLower = _removeDiacritics(query.toLowerCase());

    return allCities.where((city) {
      final cityName = _removeDiacritics(city['nome']!.toLowerCase());
      return cityName.contains(queryLower);
    }).toList();
  }

  /// Remove acentos para facilitar busca
  static String _removeDiacritics(String str) {
    final withDiacritics = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    final withoutDiacritics = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';

    String result = str;
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }

  /// Limpa o cache (útil para testes)
  static void clearCache() {
    _cityCache.clear();
  }
}
