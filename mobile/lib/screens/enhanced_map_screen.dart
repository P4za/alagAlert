import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

/// Tela de mapa melhorada com integração ao backend de áreas de risco
class EnhancedMapScreen extends StatefulWidget {
  final double? lat;
  final double? lon;
  final String? uf;

  const EnhancedMapScreen({
    super.key,
    this.lat,
    this.lon,
    this.uf,
  });

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  final MapController _mapController = MapController();

  // Centro padrão: São Paulo/SP
  late LatLng _center;
  double _zoom = 11.0;

  List<Polygon> _riskPolygons = [];
  bool _loading = false;
  String? _error;

  // Filtros
  String? _selectedRiskLevel; // low, medium, high
  DateTime _selectedDate = DateTime.now();
  final List<String> _riskLevels = ['Todos', 'Baixo', 'Médio', 'Alto'];

  @override
  void initState() {
    super.initState();

    // Define centro inicial
    if (widget.lat != null && widget.lon != null) {
      _center = LatLng(widget.lat!, widget.lon!);
    } else {
      // Padrão: São Paulo/SP
      _center = const LatLng(-23.5505, -46.6333);
    }

    // Carrega áreas de risco após o frame inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRiskAreas();
    });
  }

  /// Carrega áreas de risco do backend
  Future<void> _loadRiskAreas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParams = {
        'lat': _center.latitude.toString(),
        'lon': _center.longitude.toString(),
        'radius': '20', // 20 km de raio
        'zoom': _zoom.round().toString(),
        if (_selectedRiskLevel != null) 'risk_level': _selectedRiskLevel!,
        'date': _formatDate(_selectedDate),
      };

      final uri = Uri.parse('${ApiService.baseUrl}/risk/areas')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Erro ${response.statusCode} ao carregar áreas de risco');
      }

      final geojson = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (geojson['features'] as List?) ?? [];

      final polygons = <Polygon>[];

      for (final feature in features) {
        if (feature is! Map) continue;

        final geometry = feature['geometry'] as Map?;
        final properties = feature['properties'] as Map?;

        if (geometry == null || properties == null) continue;

        final type = geometry['type'] as String?;
        final coords = geometry['coordinates'];

        if (type == 'Polygon' && coords is List) {
          final polygon = _parsePolygon(coords, properties);
          if (polygon != null) {
            polygons.add(polygon);
          }
        }
      }

      if (mounted) {
        setState(() {
          _riskPolygons = polygons;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar áreas: $e';
          _loading = false;
        });
      }
    }
  }

  /// Parse de polígono GeoJSON para flutter_map Polygon
  Polygon? _parsePolygon(dynamic coords, Map properties) {
    if (coords is! List || coords.isEmpty) return null;

    final ring = coords[0];
    if (ring is! List) return null;

    final points = <LatLng>[];
    for (final pair in ring) {
      if (pair is List && pair.length >= 2) {
        final lon = (pair[0] as num?)?.toDouble();
        final lat = (pair[1] as num?)?.toDouble();
        if (lat != null && lon != null) {
          points.add(LatLng(lat, lon));
        }
      }
    }

    if (points.isEmpty) return null;

    // Cores baseadas no nível de risco
    final riskLevel = properties['riskLevel'] as String? ?? 'low';
    final color = _getRiskColor(riskLevel);

    return Polygon(
      points: points,
      color: color.withValues(alpha: 0.3),
      borderColor: color,
      borderStrokeWidth: 2.0,
    );
  }

  /// Retorna cor baseada no nível de risco
  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Formata data para API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Muda filtro de nível de risco
  void _changeRiskFilter(String? level) {
    String? apiLevel;
    if (level == 'Baixo') {
      apiLevel = 'low';
    } else if (level == 'Médio') {
      apiLevel = 'medium';
    } else if (level == 'Alto') {
      apiLevel = 'high';
    }

    setState(() {
      _selectedRiskLevel = apiLevel;
    });
    _loadRiskAreas();
  }

  /// Muda filtro de dia
  void _changeDay(int daysOffset) {
    final newDate = DateTime.now().add(Duration(days: daysOffset));
    setState(() {
      _selectedDate = newDate;
    });
    _loadRiskAreas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Áreas de Risco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _loading ? null : _loadRiskAreas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilters(),

          // Mapa
          Expanded(
            child: _loading && _riskPolygons.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRiskAreas,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildMap(),
          ),
        ],
      ),
    );
  }

  /// Widget de filtros
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro de dia
          const Text('Dia:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDayChip('Hoje', 0),
                const SizedBox(width: 8),
                _buildDayChip('+1 dia', 1),
                const SizedBox(width: 8),
                _buildDayChip('+2 dias', 2),
                const SizedBox(width: 8),
                _buildDayChip('+3 dias', 3),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filtro de intensidade
          const Text('Intensidade:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRiskLevel == null
                ? 'Todos'
                : _selectedRiskLevel == 'low'
                    ? 'Baixo'
                    : _selectedRiskLevel == 'medium'
                        ? 'Médio'
                        : 'Alto',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _riskLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level),
              );
            }).toList(),
            onChanged: (value) {
              if (value == 'Todos') {
                _changeRiskFilter(null);
              } else {
                _changeRiskFilter(value);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Chip para seleção de dia
  Widget _buildDayChip(String label, int daysOffset) {
    final isSelected = _selectedDate.day ==
        DateTime.now().add(Duration(days: daysOffset)).day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _changeDay(daysOffset),
      selectedColor: Colors.blue.shade200,
    );
  }

  /// Widget do mapa
  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _zoom,
            minZoom: 8,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (position, hasGesture) {
              // Atualiza zoom para simplificação
              if (hasGesture) {
                _zoom = position.zoom;
              }
            },
          ),
          children: [
            // Camada de tiles (mapa base)
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'alagalert',
            ),

            // Camada de polígonos de risco
            if (_riskPolygons.isNotEmpty) PolygonLayer(polygons: _riskPolygons),

            // Legenda
            _buildLegend(),
          ],
        ),

        // Loading overlay
        if (_loading)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Carregando áreas...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Legenda do mapa
  Widget _buildLegend() {
    // Calcula status geral baseado nas áreas visíveis
    final hasHighRisk = _riskPolygons.any((p) {
      // Verifica pela cor vermelha
      return p.borderColor == Colors.red;
    });
    final hasMediumRisk = _riskPolygons.any((p) {
      return p.borderColor == Colors.orange;
    });

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (hasHighRisk) {
      statusText = 'CRÍTICA';
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (hasMediumRisk) {
      statusText = 'ATENÇÃO';
      statusColor = Colors.orange;
      statusIcon = Icons.error_outline;
    } else if (_riskPolygons.isNotEmpty) {
      statusText = 'BOA';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'SEM DADOS';
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status geral
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Condição: $statusText',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Título
              const Text(
                'Nível de Risco',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              // Itens da legenda
              _buildLegendItem('Alto - Risco crítico', Colors.red, Icons.dangerous),
              _buildLegendItem('Médio - Atenção', Colors.orange, Icons.warning_amber),
              _buildLegendItem('Baixo - Seguro', Colors.green, Icons.check_circle_outline),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Contador de áreas
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${_riskPolygons.length} área(s) de risco',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item da legenda
  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
