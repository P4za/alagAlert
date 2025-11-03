# 🗺️ Sistema de Polígonos - Explicação Completa

## 📊 Existem DOIS Sistemas de Mapa no App

### **1. MapScreen** (Polígonos GRANDES - Municípios/Estados)
- **Arquivo:** `mobile/lib/screens/map_screen.dart`
- **O que mostra:** Limites geográficos de MUNICÍPIOS inteiros
- **Dados:** GeoJSON do IBGE em `mobile/assets/ibge/`
- **Uso:** Visualizar regiões administrativas
- **❌ NÃO mostra áreas de risco de alagamento!**

### **2. EnhancedMapScreen** (Polígonos PEQUENOS - Áreas de Risco)
- **Arquivo:** `mobile/lib/screens/enhanced_map_screen.dart`
- **O que mostra:** Áreas PEQUENAS de risco de alagamento dentro das cidades
- **Dados:** Backend API `/risk/areas`
- **Uso:** Visualizar regiões específicas com risco de alagamento
- **✅ ESTE é o que você precisa usar!**

---

## 🎯 Como Funciona o Sistema de Áreas de Risco (O que você precisa!)

### **Backend:** `backend/app/services/risk_areas.py`

Atualmente possui **7 áreas de risco MOCK** em São Paulo:

```python
MOCK_RISK_AREAS = [
    {
        "name": "Zona Leste - Tatuapé",
        "base_risk": "medium",
        "polygon": [
            [-46.5650, -23.5320],  # lon, lat
            [-46.5550, -23.5320],
            [-46.5550, -23.5420],
            [-46.5650, -23.5420],
            [-46.5650, -23.5320],
        ],
    },
    {
        "name": "Zona Sul - Jabaquara",
        "base_risk": "high",
        "polygon": [
            [-46.6420, -23.6190],
            [-46.6320, -23.6190],
            [-46.6320, -23.6290],
            [-46.6420, -23.6290],
            [-46.6420, -23.6190],
        ],
    },
    # ... mais 5 áreas (Santana, Anhangabaú, Lapa, Campo Limpo, Itaquera)
]
```

### **Como as áreas são renderizadas:**

1. **Cores por Nível de Risco:**
   - 🔴 **Alto (high):** Vermelho `#dc2626` - Opacidade 0.4
   - 🟡 **Médio (medium):** Laranja `#f59e0b` - Opacidade 0.3
   - 🟢 **Baixo (low):** Verde `#10b981` - Opacidade 0.2

2. **Tamanho dos Polígonos:**
   - Cada polígono representa uma **área pequena** (aproximadamente 1km²)
   - Exemplo: Tatuapé = 0.01° x 0.01° ≈ 1.1km x 1.1km

3. **Risco Dinâmico:**
   - O risco muda baseado no **dia da previsão** (hoje, +1, +2, +3 dias)
   - Simula que o risco aumenta/diminui conforme a previsão de chuva

---

## 🔧 Como Usar o Mapa de Áreas de Risco

### **Opção 1: Via Código (Navegação Programática)**

No arquivo onde você quer abrir o mapa de risco:

```dart
import 'package:flutter/material.dart';
import '../screens/enhanced_map_screen.dart';

// Dentro de um botão ou ação:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedMapScreen(
      lat: -23.5505,  // Latitude da cidade (ex: São Paulo)
      lon: -46.6333,  // Longitude da cidade
    ),
  ),
);
```

### **Opção 2: Adicionar Botão na Tela de Resultado**

Edite `mobile/lib/screens/risk_result_screen.dart` e adicione:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMapScreen(
          lat: widget.lat,  // Passa a latitude da cidade
          lon: widget.lon,  // Passa a longitude da cidade
        ),
      ),
    );
  },
  icon: Icon(Icons.map),
  label: Text('Ver Áreas de Risco'),
),
```

---

## 📍 Como Adicionar Mais Áreas de Risco

### **Passo 1: Identificar Coordenadas**

Use ferramentas como:
- **Google Maps:** Clique com botão direito → "O que há aqui?" → Copia lat/lon
- **OpenStreetMap:** Clique no local → Veja coordenadas no canto inferior direito
- **Geojson.io:** Desenhe polígonos visualmente e exporte as coordenadas

### **Passo 2: Adicionar no Backend**

Edite `backend/app/services/risk_areas.py` e adicione na lista `MOCK_RISK_AREAS`:

```python
{
    "name": "Bairro XYZ - Descrição",
    "base_risk": "medium",  # ou "low" ou "high"
    "polygon": [
        [-46.xxxx, -23.yyyy],  # Ponto 1 (lon, lat)
        [-46.xxxx, -23.yyyy],  # Ponto 2
        [-46.xxxx, -23.yyyy],  # Ponto 3
        [-46.xxxx, -23.yyyy],  # Ponto 4
        [-46.xxxx, -23.yyyy],  # Ponto 1 (fecha o polígono)
    ],
},
```

**⚠️ IMPORTANTE:**
- Formato: `[longitude, latitude]` (lon primeiro!)
- Primeiro e último ponto devem ser iguais (fechar o polígono)
- Coordenadas negativas para Brasil (hemisfério sul/oeste)

### **Passo 3: Criar Polígonos Realistas**

Para criar áreas mais realistas baseadas em dados reais:

```python
# Exemplo: Área perto de um rio
{
    "name": "Marginal Tietê - Próximo à Ponte das Bandeiras",
    "base_risk": "high",
    "polygon": [
        [-46.6330, -23.5180],
        [-46.6280, -23.5180],
        [-46.6280, -23.5230],
        [-46.6330, -23.5230],
        [-46.6330, -23.5180],
    ],
},
```

---

## 🎨 Exemplo Completo: Adicionando 3 Novas Áreas

```python
# Adicione estas áreas no MOCK_RISK_AREAS:

{
    "name": "Zona Norte - Tucuruvi (Próximo ao Córrego)",
    "base_risk": "high",
    "polygon": [
        [-46.6030, -23.4750],
        [-46.5980, -23.4750],
        [-46.5980, -23.4800],
        [-46.6030, -23.4800],
        [-46.6030, -23.4750],
    ],
},
{
    "name": "Zona Oeste - Pinheiros (Próximo ao Rio)",
    "base_risk": "medium",
    "polygon": [
        [-46.6920, -23.5650],
        [-46.6870, -23.5650],
        [-46.6870, -23.5700],
        [-46.6920, -23.5700],
        [-46.6920, -23.5650],
    ],
},
{
    "name": "Zona Sul - Brooklin (Área Baixa)",
    "base_risk": "medium",
    "polygon": [
        [-46.6970, -23.5950],
        [-46.6920, -23.5950],
        [-46.6920, -23.6000],
        [-46.6970, -23.6000],
        [-46.6970, -23.5950],
    ],
},
```

---

## 🧪 Como Testar

### **1. Rode o Backend:**
```bash
cd backend
source venv/bin/activate  # ou venv\Scripts\activate no Windows
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### **2. Teste a API Diretamente:**
```bash
# Ver todas as áreas de risco em São Paulo
curl "http://localhost:8000/risk/areas?lat=-23.5505&lon=-46.6333&radius=20"

# Filtrar apenas áreas de alto risco
curl "http://localhost:8000/risk/areas?lat=-23.5505&lon=-46.6333&risk_level=high"

# Ver previsão para amanhã
curl "http://localhost:8000/risk/areas?lat=-23.5505&lon=-46.6333&date=2025-11-02"
```

### **3. Rode o Mobile:**
```bash
cd mobile
flutter run --dart-define=API_URL=http://10.0.2.2:8000  # Android Emulator
```

### **4. Abra o Mapa de Áreas de Risco:**
- Na tela do app, navegue até o `EnhancedMapScreen`
- Você verá os polígonos coloridos nas áreas de risco
- Use os filtros para mostrar apenas alto/médio/baixo risco
- Mude o dia (+1, +2, +3) para ver como o risco muda

---

## 📐 Diferenças Visuais

### **MapScreen (Municípios):**
```
┌─────────────────────────────────┐
│                                 │
│     ╔═════════════════════╗     │
│     ║                     ║     │
│     ║   MUNICÍPIO DE      ║     │
│     ║   SÃO PAULO         ║     │  ← Polígono GRANDE
│     ║   (cidade inteira)  ║     │
│     ║                     ║     │
│     ╚═════════════════════╝     │
│                                 │
└─────────────────────────────────┘
```

### **EnhancedMapScreen (Áreas de Risco):**
```
┌─────────────────────────────────┐
│                                 │
│     ╔══╗         ╔══╗          │
│     ║🔴║         ║🟢║          │  ← Polígonos PEQUENOS
│     ╚══╝         ╚══╝          │    (áreas específicas)
│                                 │
│          ╔════╗                 │
│          ║🟡  ║                 │
│          ╚════╝                 │
│                                 │
└─────────────────────────────────┘
```

---

## 🚀 Próximos Passos Sugeridos

### **Curto Prazo:**
1. ✅ Usar `EnhancedMapScreen` ao invés de `MapScreen`
2. ✅ Adicionar mais áreas de risco no backend (baseado em dados reais)
3. ✅ Integrar com dados meteorológicos reais

### **Médio Prazo:**
1. 🔄 Substituir MOCK por dados reais de:
   - Defesa Civil
   - Histórico de alagamentos
   - Topografia (áreas baixas)
   - Proximidade a rios/córregos
2. 🔄 Calcular risco dinamicamente baseado em:
   - Previsão de chuva (Open-Meteo)
   - Capacidade de drenagem
   - Histórico da região

### **Longo Prazo:**
1. 🎯 Machine Learning para prever áreas de risco
2. 🎯 Integração com sensores IoT
3. 🎯 Alertas em tempo real

---

## 💡 Exemplo Prático: Fonte de Dados Reais

### **Defesa Civil de São Paulo:**
Muitas cidades disponibilizam dados de pontos de alagamento. Você pode:

1. Obter lista de endereços históricos de alagamento
2. Geocodificar (converter endereço → lat/lon)
3. Criar polígonos ao redor desses pontos

**Código exemplo para geocodificar:**
```python
import httpx

async def geocode_address(address: str):
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "q": address,
        "format": "json",
        "limit": 1,
    }
    headers = {"User-Agent": "AlagAlert/1.0"}

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=headers)
        data = response.json()

        if data:
            return {
                "lat": float(data[0]["lat"]),
                "lon": float(data[0]["lon"]),
            }
    return None

# Criar polígono 200m ao redor do ponto
def create_polygon_around_point(lat: float, lon: float, radius_m: float = 200):
    # Conversão aproximada: 1° ≈ 111km
    radius_deg = radius_m / 111000

    return [
        [lon - radius_deg, lat - radius_deg],
        [lon + radius_deg, lat - radius_deg],
        [lon + radius_deg, lat + radius_deg],
        [lon - radius_deg, lat + radius_deg],
        [lon - radius_deg, lat - radius_deg],
    ]
```

---

## 📚 Recursos Úteis

- **GeoJSON.io:** https://geojson.io/ (Desenhar polígonos visualmente)
- **OpenStreetMap:** https://www.openstreetmap.org/ (Obter coordenadas)
- **Leaflet Docs:** https://leafletjs.com/ (Entender GeoJSON)
- **FlutterMap Docs:** https://docs.fleaflet.dev/ (Documentação do plugin)

---

## ❓ FAQ

**Q: Por que os polígonos são quadrados?**
A: É apenas mock! Na produção, você usaria polígonos irregulares baseados em topografia real.

**Q: Como faço para mostrar outras cidades além de São Paulo?**
A: Adicione áreas no `MOCK_RISK_AREAS` com coordenadas de outras cidades.

**Q: Posso usar dados vetoriais reais?**
A: Sim! Substitua MOCK_RISK_AREAS por dados de shapefiles (.shp) ou GeoJSON de fontes oficiais.

**Q: Como calcular o risco automaticamente?**
A: Integre com Open-Meteo (já implementado) e crie uma função que calcule risco baseado em:
- mm de chuva prevista
- velocidade do vento
- histórico da área
- capacidade de drenagem

---

## 🎯 Resumo

**O que você precisa fazer:**

1. ✅ Use `EnhancedMapScreen` ao invés de `MapScreen`
2. ✅ Adicione mais áreas no `MOCK_RISK_AREAS`
3. ✅ Use coordenadas reais baseadas em dados históricos
4. ✅ Integre com previsão meteorológica para cálculo dinâmico

**Arquivo principal a editar:**
- `backend/app/services/risk_areas.py` - Adicionar áreas de risco

Qualquer dúvida, é só perguntar! 🚀
