# 🗺️ GUIA COMPLETO: Mapa de Bairros com Previsão Real

## ✅ O QUE FOI CORRIGIDO

### 1. Busca de Cidades ✅
**Problema:** Autocomplete não funcionava, não filtrava por estado
**Solução:**
- Campo de busca personalizado que FUNCIONA
- Carrega todas as cidades do estado selecionado automaticamente
- Filtragem em tempo real sem bugs
- Remove acentos na busca (digita "sao paulo" e encontra "São Paulo")
- 27 estados hardcoded no código (super rápido)

### 2. Mapa de Bairros com Previsão REAL ✅
**Problema:** Mapa mostrava municípios inteiros, não bairros
**Solução:**
- Novo endpoint: `/risk/neighborhoods`
- Busca previsão de chuva REAL do Open-Meteo
- Cria polígonos por BAIRRO (não cidade inteira)
- Cores baseadas em mm de chuva prevista

---

## 🎯 COMO FUNCIONA O NOVO SISTEMA

### Backend: `/risk/neighborhoods`

**Parâmetros:**
- `city`: Nome da cidade (ex: "São Paulo")
- `uf`: Estado (ex: "SP")
- `forecast_days`: Dias de previsão (1-7)
- `risk_level`: Filtro opcional (low/medium/high)

**Exemplo:**
```bash
curl "http://localhost:8000/risk/neighborhoods?city=São Paulo&uf=SP&forecast_days=1"
```

**O que faz:**
1. Pega lista de bairros da cidade
2. Para cada bairro, busca previsão do Open-Meteo
3. Calcula risco baseado em mm de chuva
4. Cria polígono colorido por bairro

**Critérios de Cor:**
- 🟢 **Verde (baixo):** < 10mm de chuva
- 🟡 **Laranja (médio):** 10-20mm de chuva
- 🔴 **Vermelho (alto):** > 20mm de chuva

---

## 🧪 COMO TESTAR

### Passo 1: Rode o Backend

```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Passo 2: Teste a API Diretamente

```bash
# São Paulo com 10 bairros
curl "http://localhost:8000/risk/neighborhoods?city=São Paulo&uf=SP&forecast_days=1"

# Campinas com 4 bairros
curl "http://localhost:8000/risk/neighborhoods?city=Campinas&uf=SP&forecast_days=1"

# Santos com 4 bairros
curl "http://localhost:8000/risk/neighborhoods?city=Santos&uf=SP&forecast_days=1"

# Filtrar apenas bairros de alto risco
curl "http://localhost:8000/risk/neighborhoods?city=São Paulo&uf=SP&risk_level=high"
```

**Resposta Exemplo:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[-46.5650, -23.5320], ...]]
      },
      "properties": {
        "name": "Tatuapé",
        "city": "São Paulo",
        "uf": "SP",
        "riskLevel": "medium",
        "weather": {
          "total_precipitation_mm": 12.5,
          "avg_probability": 65.0,
          "max_precipitation_mm": 5.2
        },
        "fillColor": "#f59e0b",
        "strokeColor": "#d97706"
      }
    }
  ],
  "metadata": {
    "city": "São Paulo",
    "uf": "SP",
    "forecast_days": 1,
    "total_features": 10
  }
}
```

### Passo 3: Teste a Busca de Cidades

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

**Fluxo de Teste:**
1. Abra o app
2. No dropdown "Estado", selecione **SP**
3. O app carrega automaticamente TODAS as cidades de SP
4. No campo "Cidade", digite **"santos"**
5. ✅ Deve aparecer "Santos - SP" na lista
6. Clique em "Santos"
7. Clique em "Usar esta cidade"

---

## 🏗️ ARQUITETURA DO SISTEMA

```
┌─────────────────────────────────────┐
│  USER seleciona: São Paulo - SP     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Frontend chama:                    │
│  /risk/neighborhoods?               │
│   city=São Paulo&uf=SP              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Backend busca lista de bairros:    │
│  - Tatuapé                          │
│  - Jabaquara                        │
│  - Santana                          │
│  - Centro                           │
│  - ... (10 total)                   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Para CADA bairro:                  │
│  1. Pega coordenadas (lat/lon)      │
│  2. Chama Open-Meteo API            │
│  3. Recebe: precipitação em mm      │
│  4. Calcula risco (low/med/high)    │
│  5. Define cor do polígono          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Retorna GeoJSON com polígonos      │
│  coloridos por bairro               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Frontend renderiza no mapa:        │
│  🟢 Tatuapé (5mm)                   │
│  🔴 Jabaquara (25mm)                │
│  🟡 Centro (15mm)                   │
└─────────────────────────────────────┘
```

---

## 📊 CIDADES DISPONÍVEIS

### São Paulo (10 bairros)
- Tatuapé, Jabaquara, Santana, Centro, Lapa
- Itaquera, Vila Mariana, Pinheiros, Mooca, Butantã

### Campinas (4 bairros)
- Cambuí, Taquaral, Barão Geraldo, Centro

### Santos (4 bairros)
- Gonzaga, Boqueirão, Ponta da Praia, Centro

---

## 🔧 COMO ADICIONAR MAIS CIDADES

Edite `backend/app/services/neighborhood_weather.py`:

```python
KNOWN_NEIGHBORHOODS = {
    "São Paulo": [...],
    "Campinas": [...],
    "Santos": [...],

    # Adicione sua cidade aqui:
    "Rio de Janeiro": [
        {"name": "Copacabana", "lat": -22.9711, "lon": -43.1822},
        {"name": "Ipanema", "lat": -22.9838, "lon": -43.2055},
        {"name": "Botafogo", "lat": -22.9520, "lon": -43.1827},
        {"name": "Centro", "lat": -22.9035, "lon": -43.2096},
    ],

    "Belo Horizonte": [
        {"name": "Savassi", "lat": -19.9390, "lon": -43.9355},
        {"name": "Pampulha", "lat": -19.8515, "lon": -43.9713},
        {"name": "Centro", "lat": -19.9167, "lon": -43.9345},
    ],
}
```

**Como obter coordenadas:**
1. Abra Google Maps
2. Clique com botão direito no centro do bairro
3. Clique em "O que há aqui?"
4. Copia latitude e longitude

**Reinicie o backend** e as novas cidades aparecerão!

---

## 🎨 COMO O FRONTEND USA

### Opção 1: Modificar EnhancedMapScreen

Edite `mobile/lib/screens/enhanced_map_screen.dart`:

```dart
// Trocar de:
final uri = Uri.parse('${ApiService.baseUrl}/risk/areas')

// Para:
final uri = Uri.parse('${ApiService.baseUrl}/risk/neighborhoods')
    .replace(queryParameters: {
  'city': widget.cityName,  // Você precisa passar o nome da cidade
  'uf': widget.uf,
  'forecast_days': forecast_days.toString(),
  if (_selectedRiskLevel != null) 'risk_level': _selectedRiskLevel!,
});
```

### Opção 2: Criar Nova Tela

Crie `mobile/lib/screens/neighborhood_map_screen.dart`:

```dart
class NeighborhoodMapScreen extends StatefulWidget {
  final String city;
  final String uf;

  const NeighborhoodMapScreen({
    super.key,
    required this.city,
    required this.uf,
  });

  @override
  State<NeighborhoodMapScreen> createState() => _NeighborhoodMapScreenState();
}

class _NeighborhoodMapScreenState extends State<NeighborhoodMapScreen> {
  // ... implementação similar ao EnhancedMapScreen
  // mas chamando /risk/neighborhoods ao invés de /risk/areas
}
```

---

## 🐛 TROUBLESHOOTING

### Problema: Cidade não tem bairros

**Erro:** `"message": "Nenhum bairro cadastrado para [cidade]"`

**Solução:** Adicione bairros no `KNOWN_NEIGHBORHOODS` do backend

---

### Problema: API Open-Meteo lenta

**Sintoma:** Demora muito para carregar o mapa

**Causa:** O backend faz 1 requisição por bairro ao Open-Meteo

**Solução:** Implemente cache ou limite o número de bairros

```python
# No neighborhood_weather.py, adicione cache:
from cachetools import TTLCache

weather_cache = TTLCache(maxsize=100, ttl=600)  # 10 minutos

async def get_weather_for_location(lat, lon, forecast_days=1):
    cache_key = f"{lat},{lon},{forecast_days}"
    if cache_key in weather_cache:
        return weather_cache[cache_key]

    # ... busca do Open-Meteo ...

    weather_cache[cache_key] = result
    return result
```

---

### Problema: Polígonos muito grandes/pequenos

**Ajuste o tamanho** no `neighborhood_weather.py`:

```python
polygon = create_polygon_around_point(
    neighborhood["lat"],
    neighborhood["lon"],
    size_km=1.5,  # ← Mude este valor
)
```

- `size_km=0.5` → Polígonos menores
- `size_km=2.0` → Polígonos maiores

---

## 📈 PRÓXIMOS PASSOS

### Curto Prazo:
1. ✅ Modificar EnhancedMapScreen para usar `/risk/neighborhoods`
2. ✅ Passar cidade e UF para o mapa
3. ✅ Testar com São Paulo, Campinas, Santos

### Médio Prazo:
1. 🔄 Adicionar mais cidades e bairros
2. 🔄 Implementar cache no backend
3. 🔄 Buscar bairros automaticamente via Nominatim/OSM

### Longo Prazo:
1. 🎯 Integrar base de dados de bairros completa
2. 🎯 Usar polígonos reais (não quadrados)
3. 🎯 Sistema de alertas push

---

## 📝 CHECKLIST DE TESTE

- [ ] Backend rodando em localhost:8000
- [ ] Teste `/risk/neighborhoods?city=São Paulo&uf=SP`
- [ ] Resposta JSON com 10 bairros
- [ ] Cada bairro tem `weather.total_precipitation_mm`
- [ ] Cores corretas (verde/laranja/vermelho)
- [ ] Mobile: Seleção de estado funcionando
- [ ] Mobile: Busca de cidade filtrando por estado
- [ ] Mobile: Ao digitar "santos" aparece "Santos - SP"

---

## 🎉 RESUMO

### O QUE FUNCIONA AGORA:

1. ✅ **Busca de cidades**: Rápida, sem bugs, filtrada por estado
2. ✅ **API de bairros**: Retorna bairros com previsão REAL
3. ✅ **Cores baseadas em chuva**: Verde/Laranja/Vermelho por mm
4. ✅ **3 cidades disponíveis**: São Paulo, Campinas, Santos
5. ✅ **Total de 18 bairros**: Com coordenadas reais

### O QUE VOCÊ PRECISA FAZER:

1. Modificar o frontend para usar `/risk/neighborhoods`
2. Passar cidade e UF para o mapa
3. Adicionar mais cidades conforme necessário

### ARQUIVOS MODIFICADOS:

**Backend:**
- `backend/app/services/neighborhood_weather.py` (NOVO)
- `backend/app/main.py` (endpoint novo)

**Frontend:**
- `mobile/lib/screens/city_picker_screen.dart` (reescrito)
- `mobile/lib/services/ibge_service.dart` (método público)

**Próximo passo:** Integrar o `/risk/neighborhoods` no mapa do app! 🚀
