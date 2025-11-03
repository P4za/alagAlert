# 🌦️ Guia Completo: Sistema de Bairros com Clima Real

## ✅ Problemas Corrigidos Nesta Branch

### 1. ❌ Busca de Cidades Mostrando Endereços
**Problema anterior:**
- Ao buscar "S", aparecia: "S, Rua Maria Longo, Saude, São Paulo..."
- Mostrava ruas, bairros, e cidades de TODOS os estados

**Solução implementada:**
- ✅ Busca SOMENTE cidades oficiais do IBGE
- ✅ Filtra apenas pelo estado selecionado
- ✅ Não mostra mais endereços ou ruas
- **Arquivo modificado:** `mobile/lib/screens/home_screen.dart`

```dart
// ANTES (GeocodeService - ERRADO)
suggestionsCallback: (pattern) async {
  return GeocodeService.searchCities(query: pattern); // ❌ Trazia endereços
}

// DEPOIS (IbgeService - CORRETO)
suggestionsCallback: (pattern) async {
  final uf = _selectedUf;
  if (uf == null || uf.isEmpty) return [];
  return IbgeService.searchCities(uf: uf, query: pattern); // ✅ Só cidades do estado
}
```

### 2. ❌ Estados Lentos para Carregar
**Problema anterior:**
- Buscava estados de uma API externa
- Demorava para carregar

**Solução implementada:**
- ✅ 27 estados hardcoded no código
- ✅ Busca instantânea
- **Arquivo modificado:** `mobile/lib/screens/home_screen.dart` (linhas 26-54)

### 3. ❌ Mapa Mostrando Municípios Inteiros ao Invés de Bairros
**Problema anterior:**
- Endpoint `/risk/areas` mostrava municípios completos
- Polígonos muito grandes

**Solução implementada:**
- ✅ Endpoint `/risk/neighborhoods` mostra bairros específicos
- ✅ Cada bairro tem previsão de chuva individual
- ✅ Polígonos pequenos (~1.5km²) centrados em cada bairro
- **Arquivo modificado:** `mobile/lib/screens/enhanced_map_screen.dart` (linha 81)

### 4. ❌ Legenda Mostrando "Polígonos (Roxo)"
**Problema anterior:**
- Legenda genérica sem indicador de condição

**Solução implementada:**
- ✅ Legenda mostra: **BOA**, **ATENÇÃO**, ou **CRÍTICA**
- ✅ Cores baseadas em precipitação real:
  - 🟢 Verde = < 10mm (Baixo risco)
  - 🟡 Laranja = 10-20mm (Médio risco)
  - 🔴 Vermelho = > 20mm (Alto risco)
- **Arquivo modificado:** `mobile/lib/screens/enhanced_map_screen.dart` (linhas 426-546)

---

## 🏗️ Arquitetura do Sistema

### Frontend (Flutter)
```
HomeScreen
  └─> Usuário seleciona Estado (hardcoded)
  └─> Usuário seleciona Cidade (IBGE API)
  └─> Clica em "Ver Mapa de Áreas de Risco"
      └─> EnhancedMapScreen abre
          └─> Chama backend: /risk/neighborhoods?city=X&uf=Y&forecast_days=N
          └─> Backend retorna GeoJSON com bairros
          └─> Mapa renderiza polígonos coloridos
```

### Backend (FastAPI + Open-Meteo)
```
/risk/neighborhoods
  └─> Recebe: city, uf, forecast_days, risk_level
  └─> Busca bairros no KNOWN_NEIGHBORHOODS
  └─> Para cada bairro:
      └─> Chama Open-Meteo API (lat, lon)
      └─> Recebe precipitação prevista (mm)
      └─> Calcula risco: < 10mm (low), 10-20mm (medium), > 20mm (high)
      └─> Cria polígono GeoJSON ao redor do bairro
  └─> Retorna FeatureCollection com todos os bairros
```

---

## 📊 Dados Atuais (Limitações)

### Cidades com Bairros Cadastrados

Atualmente, o sistema só funciona para **3 cidades**:

#### São Paulo (10 bairros)
- Tatuapé, Jabaquara, Santana, Centro, Lapa
- Itaquera, Vila Mariana, Pinheiros, Mooca, Butantã

#### Campinas (4 bairros)
- Cambuí, Taquaral, Barão Geraldo, Centro

#### Santos (4 bairros)
- Gonzaga, Boqueirão, Ponta da Praia, Centro

**Arquivo:** `backend/app/services/neighborhood_weather.py` (linhas 11-36)

### ⚠️ O Que Acontece se Buscar Outra Cidade?

Se você buscar qualquer outra cidade (ex: Rio de Janeiro, Curitiba, Salvador), o mapa abrirá mas mostrará:

```
╔════════════════════════════════════╗
║  ℹ️  Condição: SEM DADOS          ║
║                                    ║
║  Nenhum bairro cadastrado para     ║
║  Rio de Janeiro                    ║
╚════════════════════════════════════╝
```

---

## 🚀 Como Adicionar Mais Cidades

### Método 1: Manual (Rápido para Poucas Cidades)

Edite `backend/app/services/neighborhood_weather.py`:

```python
KNOWN_NEIGHBORHOODS = {
    # ... cidades existentes ...

    "Rio de Janeiro": [
        {"name": "Copacabana", "lat": -22.9711, "lon": -43.1822},
        {"name": "Ipanema", "lat": -22.9838, "lon": -43.2096},
        {"name": "Leblon", "lat": -22.9842, "lon": -43.2222},
        {"name": "Botafogo", "lat": -22.9519, "lon": -43.1824},
        {"name": "Flamengo", "lat": -22.9289, "lon": -43.1728},
    ],

    "Curitiba": [
        {"name": "Batel", "lat": -25.4416, "lon": -49.2772},
        {"name": "Centro", "lat": -25.4284, "lon": -49.2733},
        {"name": "Água Verde", "lat": -25.4492, "lon": -49.2394},
    ],
}
```

**Como obter coordenadas de bairros:**
1. Acesse: https://www.google.com/maps
2. Busque o bairro (ex: "Copacabana, Rio de Janeiro")
3. Clique com botão direito no centro do bairro
4. Copie as coordenadas (ex: -22.9711, -43.1822)

### Método 2: API Gratuita (Automático para Todas as Cidades)

#### Opção A: OSM Overpass API (Recomendado)

**Vantagens:**
- ✅ Gratuito
- ✅ Tem todos os bairros do Brasil
- ✅ Retorna polígonos reais (não quadrados)
- ✅ Dados do OpenStreetMap

**Exemplo de query:**
```python
import httpx

async def get_neighborhoods_from_osm(city: str, uf: str):
    """
    Busca bairros usando Overpass API
    """
    # Query Overpass QL
    query = f"""
    [out:json][timeout:25];
    area["name"="{city}"]["admin_level"="8"]->.city;
    (
      relation["place"="neighbourhood"](area.city);
      relation["place"="suburb"](area.city);
    );
    out center;
    """

    url = "https://overpass-api.de/api/interpreter"

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, data={"data": query})
        data = response.json()

        neighborhoods = []
        for element in data.get("elements", []):
            if "tags" in element and "center" in element:
                neighborhoods.append({
                    "name": element["tags"]["name"],
                    "lat": element["center"]["lat"],
                    "lon": element["center"]["lon"],
                })

        return neighborhoods

# Uso:
neighborhoods = await get_neighborhoods_from_osm("São Paulo", "SP")
# Retorna: [{"name": "Tatuapé", "lat": -23.532, "lon": -46.565}, ...]
```

**Implementação completa:**

1. Crie novo arquivo: `backend/app/services/osm_neighborhoods.py`

```python
"""
Busca bairros automaticamente via Overpass API
"""
import httpx
from typing import List, Dict

async def fetch_neighborhoods(city: str) -> List[Dict]:
    """
    Busca bairros de uma cidade via OSM Overpass API

    Args:
        city: Nome da cidade (ex: "São Paulo", "Rio de Janeiro")

    Returns:
        Lista de bairros com name, lat, lon
    """
    query = f"""
    [out:json][timeout:25];
    area["name"="{city}"]["admin_level"="8"]->.city;
    (
      relation["place"="neighbourhood"](area.city);
      relation["place"="suburb"](area.city);
    );
    out center;
    """

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://overpass-api.de/api/interpreter",
                data={"data": query}
            )
            response.raise_for_status()
            data = response.json()

            neighborhoods = []
            for element in data.get("elements", []):
                if "tags" in element and "center" in element:
                    neighborhoods.append({
                        "name": element["tags"].get("name", "Desconhecido"),
                        "lat": element["center"]["lat"],
                        "lon": element["center"]["lon"],
                    })

            return neighborhoods
    except Exception as e:
        print(f"Erro ao buscar bairros OSM: {e}")
        return []
```

2. Modifique `neighborhood_weather.py`:

```python
from .osm_neighborhoods import fetch_neighborhoods

async def get_neighborhoods_with_weather(
    city: str,
    uf: str,
    forecast_days: int = 1,
    risk_level: Optional[str] = None,
) -> Dict:
    # Tenta buscar do cache/hardcoded primeiro
    neighborhoods = KNOWN_NEIGHBORHOODS.get(city, [])

    # Se não encontrou, busca via OSM
    if not neighborhoods:
        print(f"Buscando bairros de {city} via OSM...")
        osm_data = await fetch_neighborhoods(city)
        neighborhoods = osm_data

    # ... resto do código igual
```

**Limitações do Overpass:**
- ⚠️ Rate limit: 2 requests/segundo
- ⚠️ Timeout de 25 segundos por query
- ⚠️ Alguns bairros podem não ter tags corretas no OSM

#### Opção B: IBGE Malhas (Subdistritos)

```python
async def get_ibge_subdistricts(city_code: str):
    """
    Busca subdistritos do IBGE
    Nota: Nem todas as cidades têm subdivisões no IBGE
    """
    url = f"https://servicodados.ibge.gov.br/api/v3/malhas/municipios/{city_code}/distritos"

    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        # Retorna GeoJSON com polígonos dos distritos
```

**Limitação:** IBGE só tem distritos (subdivisões administrativas), não bairros.

---

## 🧪 Como Testar o Sistema Atual

### 1. Rodar o Backend
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Testar API Diretamente
```bash
# Testar São Paulo (deve funcionar)
curl "http://localhost:8000/risk/neighborhoods?city=São%20Paulo&uf=SP&forecast_days=1"

# Testar Rio de Janeiro (deve retornar vazio)
curl "http://localhost:8000/risk/neighborhoods?city=Rio%20de%20Janeiro&uf=RJ&forecast_days=1"
```

**Resposta esperada para São Paulo:**
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
        "riskLevel": "low",
        "weather": {
          "total_precipitation_mm": 2.5,
          "avg_probability": 15.3
        }
      }
    }
  ],
  "metadata": {
    "city": "São Paulo",
    "uf": "SP",
    "total_features": 10
  }
}
```

### 3. Rodar o App Flutter
```bash
cd mobile
flutter clean
flutter pub get

# Android Emulator
flutter run --dart-define=API_URL=http://10.0.2.2:8000

# iOS Simulator
flutter run --dart-define=API_URL=http://localhost:8000

# Dispositivo físico (substitua SEU_IP pelo IP do seu computador)
flutter run --dart-define=API_URL=http://SEU_IP:8000
```

### 4. Testar Fluxo Completo
1. Abra o app
2. Busque estado: "SP" ou "São Paulo"
3. Busque cidade: "São Paulo" (deve aparecer apenas cidades de SP)
4. Clique em "Ver Mapa de Áreas de Risco"
5. **Resultado esperado:**
   - Mapa abre centrado em São Paulo
   - 10 polígonos coloridos aparecem (bairros)
   - Legenda mostra condição (BOA/ATENÇÃO/CRÍTICA)
   - Contador mostra "10 área(s) de risco"

---

## 📋 Checklist de Implementação para Todas as Cidades

### Fase 1: Preparação (✅ Concluído)
- [x] Busca de estados hardcoded (27 estados)
- [x] Busca de cidades via IBGE API
- [x] Integração com Open-Meteo para clima real
- [x] Cálculo de risco baseado em precipitação
- [x] Mapa com legenda inteligente

### Fase 2: Expansão de Dados (⏳ Pendente)
- [ ] Implementar OSM Overpass API no backend
- [ ] Adicionar cache de bairros (evitar consultas repetidas)
- [ ] Adicionar bairros das 50 maiores cidades do Brasil
- [ ] Testar com cidades de todos os estados

### Fase 3: Otimização (⏳ Futuro)
- [ ] Cache Redis para bairros
- [ ] Database PostgreSQL com PostGIS
- [ ] Polígonos reais dos bairros (não quadrados)
- [ ] Histórico de alagamentos real

---

## 🗺️ Roadmap Sugerido

### Curto Prazo (1-2 semanas)
1. ✅ Adicionar manualmente bairros das capitais:
   - Rio de Janeiro, Belo Horizonte, Brasília
   - Salvador, Recife, Fortaleza, Curitiba
   - Porto Alegre, Manaus, Belém

2. ✅ Implementar OSM Overpass para busca automática

### Médio Prazo (1 mês)
3. ✅ Adicionar todas as cidades com > 100k habitantes
4. ✅ Implementar cache de bairros
5. ✅ Melhorar algoritmo de risco (considerar topografia)

### Longo Prazo (3+ meses)
6. ✅ Integrar com dados reais da Defesa Civil
7. ✅ Machine Learning para previsão
8. ✅ Alertas push para áreas de risco

---

## 🆘 Próximos Passos Recomendados

### Para Testar Agora
1. Rode o backend e app
2. Teste com São Paulo, Campinas, Santos
3. Verifique que a busca de cidades está correta

### Para Expandir o Sistema
1. **Escolha uma abordagem:**
   - **Rápida:** Adicione manualmente 10-20 cidades principais
   - **Escalável:** Implemente OSM Overpass API

2. **Se escolher OSM Overpass:**
   - Copie o código da seção "Opção A" acima
   - Crie `backend/app/services/osm_neighborhoods.py`
   - Modifique `neighborhood_weather.py` para usar OSM como fallback
   - Teste com várias cidades

3. **Considere adicionar:**
   - Rate limiting para OSM (max 2 req/s)
   - Cache de bairros em arquivo JSON
   - Fallback para bairros hardcoded se OSM falhar

---

## 📚 Referências

- **IBGE API:** https://servicodados.ibge.gov.br/api/docs/localidades
- **Open-Meteo:** https://open-meteo.com/en/docs
- **OSM Overpass:** https://overpass-api.de/
- **FlutterMap:** https://docs.fleaflet.dev/

---

## ❓ FAQ

**Q: Por que só 3 cidades funcionam?**
A: Os bairros estão hardcoded. Implemente OSM Overpass ou adicione manualmente mais cidades.

**Q: Como adiciono Rio de Janeiro?**
A: Edite `neighborhood_weather.py` e adicione os bairros com lat/lon (veja seção "Como Adicionar Mais Cidades").

**Q: O OSM Overpass é confiável?**
A: Sim, mas depende da qualidade dos dados do OpenStreetMap. Grandes cidades têm ótimos dados.

**Q: Posso usar outra API de clima?**
A: Sim! Open-Meteo é gratuito e ilimitado. Alternativas: OpenWeatherMap (pago), Weather API.

**Q: Como adiciono histórico de alagamentos real?**
A: Integre com dados da Defesa Civil ou crie um banco de dados com pontos de alagamento reportados.

---

## 🎯 Resumo Executivo

### O Que Foi Feito ✅
1. Busca de cidades corrigida (apenas cidades reais do IBGE)
2. Filtro por estado funcionando (só mostra cidades do estado selecionado)
3. Mapa mostra bairros com clima real (não municípios inteiros)
4. Legenda inteligente (BOA/ATENÇÃO/CRÍTICA)
5. Cores baseadas em precipitação real da Open-Meteo

### Limitações Atuais ⚠️
- Funciona apenas para 3 cidades: São Paulo, Campinas, Santos
- Bairros estão hardcoded no backend

### Para Funcionar em TODAS as Cidades 🚀
**Implemente OSM Overpass API conforme código fornecido neste documento.**

Isso permitirá buscar bairros automaticamente de qualquer cidade do Brasil!
