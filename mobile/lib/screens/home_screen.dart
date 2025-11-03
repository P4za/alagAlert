import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/ibge_service.dart';
import 'risk_result_screen.dart';
import 'enhanced_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController? _ufFieldCtrl;
  TextEditingController? _cityFieldCtrl;

  String? _selectedUf;        // ex.: "SP"
  String? _selectedCity;      // ex.: "Santos"
  double? _selectedLat;
  double? _selectedLon;

  final bool _loadingRisk = false;

  // Lista de estados do Brasil
  final List<Map<String, String>> _estados = [
    {'uf': 'AC', 'nome': 'Acre'},
    {'uf': 'AL', 'nome': 'Alagoas'},
    {'uf': 'AP', 'nome': 'Amapá'},
    {'uf': 'AM', 'nome': 'Amazonas'},
    {'uf': 'BA', 'nome': 'Bahia'},
    {'uf': 'CE', 'nome': 'Ceará'},
    {'uf': 'DF', 'nome': 'Distrito Federal'},
    {'uf': 'ES', 'nome': 'Espírito Santo'},
    {'uf': 'GO', 'nome': 'Goiás'},
    {'uf': 'MA', 'nome': 'Maranhão'},
    {'uf': 'MT', 'nome': 'Mato Grosso'},
    {'uf': 'MS', 'nome': 'Mato Grosso do Sul'},
    {'uf': 'MG', 'nome': 'Minas Gerais'},
    {'uf': 'PA', 'nome': 'Pará'},
    {'uf': 'PB', 'nome': 'Paraíba'},
    {'uf': 'PR', 'nome': 'Paraná'},
    {'uf': 'PE', 'nome': 'Pernambuco'},
    {'uf': 'PI', 'nome': 'Piauí'},
    {'uf': 'RJ', 'nome': 'Rio de Janeiro'},
    {'uf': 'RN', 'nome': 'Rio Grande do Norte'},
    {'uf': 'RS', 'nome': 'Rio Grande do Sul'},
    {'uf': 'RO', 'nome': 'Rondônia'},
    {'uf': 'RR', 'nome': 'Roraima'},
    {'uf': 'SC', 'nome': 'Santa Catarina'},
    {'uf': 'SP', 'nome': 'São Paulo'},
    {'uf': 'SE', 'nome': 'Sergipe'},
    {'uf': 'TO', 'nome': 'Tocantins'},
  ];

  Future<void> _verRisco() async {
    final uf = _selectedUf;
    final city = _selectedCity?.trim();

    if (uf == null || uf.isEmpty) {
      _showSnack('Escolha um estado primeiro.');
      return;
    }
    if (city == null || city.isEmpty) {
      _showSnack('Digite e selecione uma cidade.');
      return;
    }
    if (_loadingRisk) {
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskResultScreen(
          uf: uf,
          city: city,
          lat: _selectedLat,
          lon: _selectedLon,
        ),
      ),
    );
  }

  void _abrirMapa() {
    final uf = _selectedUf;
    final city = _selectedCity;

    if (uf == null || uf.isEmpty) {
      _showSnack('Escolha um estado primeiro.');
      return;
    }

    if (city == null || city.isEmpty) {
      _showSnack('Escolha uma cidade para ver áreas de risco.');
      return;
    }

    // Abrir mapa de bairros com previsão real
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnhancedMapScreen(
          lat: _selectedLat,
          lon: _selectedLon,
          uf: uf,
          cityName: city,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- ESTADO ----------
  Widget _buildUfTypeAhead() {
    return TypeAheadField<Map<String, String>>(
      hideOnEmpty: true,
      hideOnLoading: false,
      suggestionsCallback: (pattern) async {
        if (pattern.trim().isEmpty) return [];

        final queryLower = IbgeService.removeDiacriticsPublic(pattern.toLowerCase());

        return _estados.where((estado) {
          final ufLower = estado['uf']!.toLowerCase();
          final nomeLower = IbgeService.removeDiacriticsPublic(estado['nome']!.toLowerCase());
          return ufLower.contains(queryLower) || nomeLower.contains(queryLower);
        }).toList();
      },
      builder: (context, controller, focusNode) {
        _ufFieldCtrl = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Estado',
            hintText: 'Ex.: SP, São Paulo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map),
          ),
        );
      },
      itemBuilder: (context, estado) {
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text('${estado['nome']} (${estado['uf']})'),
        );
      },
      onSelected: (estado) {
        setState(() {
          _selectedUf = estado['uf'];
          _selectedCity = null;
          _selectedLat = null;
          _selectedLon = null;
        });
        _cityFieldCtrl?.clear();
        _ufFieldCtrl?.text = '${estado['nome']} (${estado['uf']})';
      },
      errorBuilder: (context, error) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Erro ao buscar estados.'),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhum estado encontrado.'),
      ),
    );
  }

  // ---------- CIDADE (do IBGE, apenas cidades reais) ----------
  Widget _buildCityTypeAhead() {
    return TypeAheadField<Map<String, String>>(
      hideOnEmpty: true,
      hideOnLoading: false,
      suggestionsCallback: (pattern) async {
        final uf = _selectedUf;
        if (uf == null || uf.isEmpty) return [];

        // Busca no IBGE - retorna APENAS cidades reais
        return IbgeService.searchCities(uf: uf, query: pattern);
      },
      builder: (context, controller, focusNode) {
        _cityFieldCtrl = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Cidade',
            hintText: _selectedUf == null
                ? 'Escolha o estado primeiro'
                : 'Ex.: Santos, Campinas',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_city),
          ),
          enabled: _selectedUf != null,
        );
      },
      itemBuilder: (context, city) {
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(city['nome']!),
          subtitle: Text('${city['nome']} - $_selectedUf'),
        );
      },
      onSelected: (city) {
        setState(() {
          _selectedCity = city['nome'];
          // As coordenadas serão obtidas do backend quando necessário
          _selectedLat = null;
          _selectedLon = null;
        });
        _cityFieldCtrl?.text = city['nome']!;
      },
      errorBuilder: (context, error) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Erro ao buscar cidades.'),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma cidade encontrada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlagAlert'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ícone e título
          const Icon(Icons.cloud_queue, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Previsão de Risco de Alagamento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildUfTypeAhead(),
          const SizedBox(height: 16),
          _buildCityTypeAhead(),
          const SizedBox(height: 24),

          // Botão Ver Risco
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _loadingRisk ? null : _verRisco,
              icon: _loadingRisk
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.warning_amber),
              label: const Text('Ver Risco de Alagamento'),
            ),
          ),

          const SizedBox(height: 12),

          // Botão Ver Mapa de Bairros
          OutlinedButton.icon(
            onPressed: _abrirMapa,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver Mapa de Áreas de Risco'),
          ),
        ],
      ),
    );
  }
}
