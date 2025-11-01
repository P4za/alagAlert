# AlagAlert

Sistema distribuído para previsão de risco de alagamentos em cidades brasileiras, com app Flutter e API FastAPI.

## Sobre o projeto

O **AlagAlert** é uma aplicação desenvolvida como parte da disciplina **Desenvolvimento de Sistemas Distribuídos (UNIP)**.

O sistema consiste em:
- **App mobile (Flutter)** → interface para consulta do risco de alagamentos por cidade/UF.
- **API intermediária (FastAPI)** → coleta dados de previsão meteorológica, geocodificação e processa riscos.
- **APIs externas** → serviços de clima (Open-Meteo) e mapas (Nominatim).

**Objetivo**: criar um sistema distribuído que auxilie na prevenção de problemas urbanos causados por chuvas intensas e alagamentos.

---

## 🚀 Melhorias Implementadas (Auditoria 2025-11)

### Frontend (Flutter)

#### ✅ Seleção de Estado e Cidade
- **Cache em memória** (15 min) para evitar requisições duplicadas
- **Unificação de baseUrl** entre ApiService e GeocodeService
- **Método `suggestCities()`** adicionado ao GeocodeService
- **Correção de erros de sintaxe** no `city_picker_screen.dart`
- **Timeout de 10s** em todas as requisições de geocodificação

#### ✅ Busca de Meteorologia
- **Novo `WeatherService` dedicado** com:
  - Cache de 10 minutos por coordenada+dias
  - Suporte a múltiplos dias (1-7)
  - Filtros por intensidade de chuva (low/medium/high)
  - Timeout de 8s
  - Exception handling com mensagens claras
- **Model `WeatherPoint` atualizado** com `precipitation_probability`
- **Classes `WeatherForecast` e `WeatherDaySummary`** para agregação

#### ✅ Mapa com Áreas de Risco
- **Nova tela `EnhancedMapScreen`** com:
  - Integração com endpoint `/risk/areas` do backend
  - Filtros por dia (hoje, +1, +2, +3 dias)
  - Filtros por intensidade (baixo/médio/alto)
  - Lazy-load com skeleton/loading
  - Legenda dinâmica
  - Polígonos coloridos por nível de risco
  - Performance otimizada (simplificação por zoom)

### Backend (FastAPI)

#### ✅ Weather Client
- **Suporte a múltiplos dias** (`forecast_days` 1-7)
- **Cache TTL** (10 min, 500 entradas)
- **Novo parâmetro `precipitation_probability`**
- **Funções `filter_forecast_by_date()` e `summarize_day()`**

#### ✅ Endpoints Atualizados
- **`/risk/by-city`**: agora aceita `forecast_days` e `date`
- **Novo `/risk/areas`**: GeoJSON de áreas de risco filtrável por:
  - `lat`/`lon`: centro da busca
  - `radius`: raio em km (1-50)
  - `risk_level`: low/medium/high
  - `date`: data de previsão (YYYY-MM-DD)
  - `zoom`: simplifica para zoom < 12

#### ✅ Mock de Áreas de Risco
- **7 áreas de São Paulo/SP** (Tatuapé, Jabaquara, Santana, Anhangabaú, Lapa, Campo Limpo, Itaquera)
- **Risco ajustado por dia** (simulação determinística)
- **Propriedades visuais** (cores, opacidade)

---

## 📋 Pré-requisitos

### Backend
- Python 3.13+
- pip

### Mobile
- Flutter 3.35.x (Dart 3.x)
- Android Studio / Xcode (para emuladores)

---

## 🔧 Instalação e Execução

### Backend (FastAPI)

```bash
# Entre na pasta do backend
cd backend

# Crie um ambiente virtual (opcional)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Instale as dependências
pip install -r requirements.txt

# Execute o servidor
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

O servidor estará disponível em: `http://localhost:8000`

Documentação Swagger: `http://localhost:8000/docs`

#### Variáveis de ambiente (opcionais)

```bash
export HOST=0.0.0.0
export PORT=8000
export RATE_LIMIT=60/minute
export OPEN_METEO_URL=https://api.open-meteo.com/v1/forecast
```

### Mobile (Flutter)

```bash
# Entre na pasta do mobile
cd mobile

# Instale as dependências
flutter pub get

# Execute no emulador/dispositivo
flutter run

# Para definir a URL da API (padrão: http://191.252.193.10:8000)
flutter run --dart-define=API_URL=http://localhost:8000
```

#### Build para produção

```bash
# Android
flutter build apk --release --dart-define=API_URL=https://sua-api.com

# iOS
flutter build ios --release --dart-define=API_URL=https://sua-api.com

# Web
flutter build web --release --dart-define=API_URL=https://sua-api.com
```

---

## 🧪 Testes

### Mobile

```bash
cd mobile
flutter test
```

Testes implementados:
- `test/services_test.dart`: WeatherService, WeatherPoint, filtros

### Backend

```bash
cd backend
pytest
```

---

## 📚 Endpoints da API

### Geocodificação

#### `GET /geocode`
Busca cidades via Nominatim.

**Parâmetros:**
- `q` (string, obrigatório): termo de busca
- `country` (string, padrão: "br"): código do país
- `limit` (int, padrão: 8): máximo de resultados
- `cities_only` (bool, padrão: true): apenas cidades
- `uf` (string, opcional): filtro por UF (ex: "SP")

**Exemplo:**
```bash
curl "http://localhost:8000/geocode?q=santos&uf=SP&limit=5"
```

#### `GET /geocode-states`
Busca estados/UFs.

**Parâmetros:**
- `q` (string, obrigatório): termo de busca
- `country` (string, padrão: "br"): código do país
- `limit` (int, padrão: 27): máximo de resultados

**Exemplo:**
```bash
curl "http://localhost:8000/geocode-states?q=sp"
```

### Risco de Alagamento

#### `GET /risk/by-city`
Retorna risco de alagamento para uma cidade.

**Parâmetros:**
- `uf` (string, obrigatório): sigla do estado (ex: "SP")
- `city` (string, obrigatório): nome da cidade
- `forecast_days` (int, padrão: 1): dias de previsão (1-7)
- `date` (string, opcional): filtrar por data (YYYY-MM-DD)

**Exemplo:**
```bash
curl "http://localhost:8000/risk/by-city?uf=SP&city=Santos&forecast_days=3"
```

**Resposta:**
```json
{
  "risk_score": 0.65,
  "level": "Alto",
  "message": "Risco alto. Fique atento a alagamentos.",
  "factors": {
    "precipitation_6h_mm": 25.5,
    "wind_avg_6h_kmh": 35.2,
    "temp_avg_6h_c": 22.1
  },
  "location": {
    "uf": "SP",
    "city": "Santos",
    "lat": -23.9608,
    "lon": -46.3331
  }
}
```

#### `GET /risk/areas`
Retorna GeoJSON com polígonos de áreas de risco.

**Parâmetros:**
- `lat` (float, obrigatório): latitude do centro
- `lon` (float, obrigatório): longitude do centro
- `radius` (float, padrão: 10): raio em km (1-50)
- `risk_level` (string, opcional): low/medium/high
- `date` (string, opcional): data de previsão (YYYY-MM-DD)
- `zoom` (int, opcional): nível de zoom (1-20)

**Exemplo:**
```bash
curl "http://localhost:8000/risk/areas?lat=-23.5505&lon=-46.6333&radius=20&risk_level=high&date=2025-11-02"
```

**Resposta:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[-46.6420, -23.6190], ...]]
      },
      "properties": {
        "name": "Zona Sul - Jabaquara",
        "riskLevel": "high",
        "riskScore": 0.85,
        "fillColor": "#dc2626",
        "fillOpacity": 0.4
      }
    }
  ],
  "metadata": {
    "total_features": 3,
    "date": "2025-11-02"
  }
}
```

---

## 📖 Como Testar (Checklist Manual)

### 1. Seleção de Estado e Cidade
- [ ] Abra o app
- [ ] Digite "sp" no campo Estado → deve sugerir "São Paulo (SP)"
- [ ] Selecione "São Paulo (SP)"
- [ ] Digite "santos" no campo Cidade → deve sugerir "Santos - SP"
- [ ] Selecione "Santos"
- [ ] Clique em "Ver risco" → deve carregar a tela de resultado

### 2. Filtros de Dia
- [ ] Na tela de risco, observe os dados
- [ ] Volte e selecione "São Paulo - São Paulo"
- [ ] Abra o mapa (botão "Abrir mapa por UF")
- [ ] Altere o filtro de dia para "+1 dia", "+2 dias", "+3 dias"
- [ ] Observe que as áreas mudam de cor

### 3. Filtros de Intensidade
- [ ] No mapa, altere o filtro de intensidade para "Baixo"
- [ ] Observe que apenas áreas verdes aparecem
- [ ] Altere para "Alto" → apenas áreas vermelhas

### 4. Performance do Mapa
- [ ] Faça pan e zoom no mapa
- [ ] Observe que não trava (60 FPS)
- [ ] Verifique que a legenda mostra o número correto de áreas

### 5. Modo Offline/Erro
- [ ] Desligue a conexão de rede
- [ ] Tente buscar uma cidade → deve mostrar mensagem de erro
- [ ] Religue a rede
- [ ] Tente novamente → deve funcionar

---

## 🛠️ Tecnologias Utilizadas

### Backend
- **FastAPI** 0.111.0 - Framework web assíncrono
- **Uvicorn** - Servidor ASGI
- **httpx** - Cliente HTTP assíncrono
- **Pydantic** - Validação de dados
- **cachetools** - Cache em memória com TTL
- **slowapi** - Rate limiting

### Frontend
- **Flutter** 3.35.x - Framework UI
- **Dart** 3.x - Linguagem
- **flutter_map** 8.2.2 - Mapas
- **latlong2** - Coordenadas geográficas
- **http** - Cliente HTTP
- **flutter_typeahead** - Autocomplete

### APIs Externas
- **Open-Meteo** - Previsão meteorológica
- **Nominatim** - Geocodificação
- **OpenStreetMap** - Tiles de mapa

---

## 📝 Estrutura do Projeto

```
alagAlert/
├── backend/
│   ├── app/
│   │   ├── main.py              # Endpoints FastAPI
│   │   ├── schemas.py           # Modelos Pydantic
│   │   ├── services/
│   │   │   ├── geocode.py       # Nominatim
│   │   │   ├── weather_client.py # Open-Meteo
│   │   │   ├── regions.py       # GeoJSON IBGE
│   │   │   └── risk_areas.py    # Áreas de risco (mock)
│   │   └── utils/
│   │       └── risk_engine.py   # Cálculo de risco
│   ├── requirements.txt
│   └── tools/
│       └── add_cities.py
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   ├── location.dart
│   │   │   ├── weather.dart
│   │   │   ├── risk.dart
│   │   │   └── region.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── geocode_service.dart
│   │   │   └── weather_service.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── city_picker_screen.dart
│   │   │   ├── map_screen.dart
│   │   │   ├── enhanced_map_screen.dart
│   │   │   └── risk_result_screen.dart
│   │   └── theme/
│   ├── test/
│   │   └── services_test.dart
│   └── pubspec.yaml
└── README.md
```

---

## 🐛 Issues Conhecidos

- [ ] Mock de áreas de risco foca apenas em São Paulo/SP
- [ ] Filtro por raio (radius) ainda não implementado (retorna todas as áreas)
- [ ] Simplificação de polígonos por zoom ainda não completa

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto é acadêmico e foi desenvolvido para fins educacionais.

---

## 👥 Autores

- **Equipe AlagAlert** - UNIP - Desenvolvimento de Sistemas Distribuídos

---

## 📞 Suporte

Para dúvidas ou problemas, abra uma [issue](https://github.com/mpereira356/alagalert/issues) no GitHub.
