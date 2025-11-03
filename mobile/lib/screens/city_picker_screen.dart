// lib/screens/city_picker_screen.dart
import 'package:flutter/material.dart';
import '../services/ibge_service.dart';

// Lista estática de UFs para o Dropdown
const List<String> _ufs = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
  'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
  'SP', 'SE', 'TO'
];

class CityPickerScreen extends StatefulWidget {
  final String? initialUf;    // sigla (ex.: SP)
  final String? initialCity;  // nome (ex.: Campinas)

  const CityPickerScreen({super.key, this.initialUf, this.initialCity});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final _cityCtl = TextEditingController();

  String? _selectedUf;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    if (widget.initialUf != null && widget.initialUf!.isNotEmpty) {
      _selectedUf = widget.initialUf!.toUpperCase();
    }
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _selectedCity = widget.initialCity!;
      _cityCtl.text = _selectedCity!;
    }
  }

  void _confirm() {
    if (_selectedUf == null || _selectedUf!.isEmpty ||
        _selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione UF e cidade')),
      );
      return;
    }
    Navigator.pop(context, {
      'uf': _selectedUf,
      'city': _selectedCity,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolher cidade")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Estado (Selecione a UF)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // --- Dropdown para Estado (Lista Estática) ---
          DropdownButtonFormField<String>(
            value: _selectedUf,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione o Estado',
              prefixIcon: Icon(Icons.map),
            ),
            items: _ufs.map((String uf) {
              return DropdownMenuItem<String>(
                value: uf,
                child: Text(uf),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedUf = newValue;
                // Limpa cidade ao trocar UF
                _selectedCity = null;
                _cityCtl.clear();
              });
            },
          ),
          // --- Fim Dropdown Estado ---

          const SizedBox(height: 24),
          const Text('Cidade', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // --- Campo de busca de cidade ---
          if (_selectedUf == null || _selectedUf!.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selecione primeiro um estado',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )
          else
            _CitySearchField(
              uf: _selectedUf!,
              initialCity: _selectedCity,
              onCitySelected: (cityName) {
                setState(() {
                  _selectedCity = cityName;
                  _cityCtl.text = cityName;
                });
              },
            ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _confirm,
            child: const Text('Usar esta cidade'),
          ),
        ],
      ),
    );
  }
}

/// Widget separado para busca de cidades
class _CitySearchField extends StatefulWidget {
  final String uf;
  final String? initialCity;
  final Function(String) onCitySelected;

  const _CitySearchField({
    required this.uf,
    this.initialCity,
    required this.onCitySelected,
  });

  @override
  State<_CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<_CitySearchField> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _allCities = [];
  List<Map<String, String>> _filteredCities = [];
  bool _loading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null) {
      _controller.text = widget.initialCity!;
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _loading = true);

    final cities = await IbgeService.getCitiesByUf(widget.uf);

    if (mounted) {
      setState(() {
        _allCities = cities;
        _loading = false;
        _filterCities(_controller.text);
      });
    }
  }

  void _filterCities(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredCities = _allCities.take(20).toList();
      });
      return;
    }

    final queryLower = IbgeService.removeDiacriticsPublic(query.toLowerCase());
    final filtered = _allCities.where((city) {
      final cityName = IbgeService.removeDiacriticsPublic(city['nome']!.toLowerCase());
      return cityName.contains(queryLower);
    }).take(20).toList();

    setState(() {
      _filteredCities = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Digite o nome da cidade',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_city),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _filterCities('');
                          setState(() => _showSuggestions = false);
                        },
                      )
                    : null,
          ),
          onChanged: (text) {
            _filterCities(text);
            setState(() => _showSuggestions = text.isNotEmpty);
          },
          onTap: () {
            if (_controller.text.isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
        ),

        // Lista de sugestões
        if (_showSuggestions && _filteredCities.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCities.length,
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(city['nome']!),
                  subtitle: Text('${city['nome']} - ${widget.uf}'),
                  dense: true,
                  onTap: () {
                    _controller.text = city['nome']!;
                    widget.onCitySelected(city['nome']!);
                    setState(() => _showSuggestions = false);
                  },
                );
              },
            ),
          ),

        // Mensagem se não encontrou
        if (_showSuggestions && _filteredCities.isEmpty && !_loading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhuma cidade encontrada com "${_controller.text}"',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
