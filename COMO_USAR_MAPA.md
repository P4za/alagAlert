# 🗺️ Como Usar o Mapa de Áreas de Risco Corretamente

## ✅ Problema Resolvido: Legenda Melhorada

Foi adicionado um **indicador de condição** na legenda do mapa que mostra claramente se a situação está:
- 🟢 **BOA** - Apenas áreas de baixo risco
- 🟡 **ATENÇÃO** - Existem áreas de médio risco
- 🔴 **CRÍTICA** - Existem áreas de alto risco

---

## 🎯 Qual Mapa Usar?

### ❌ **MapScreen** - NÃO É PARA ÁREAS DE RISCO!
- **Arquivo:** `mobile/lib/screens/map_screen.dart`
- **Mostra:** Limites de municípios inteiros (cidades completas)
- **Usa:** Arquivos GeoJSON do IBGE em `mobile/assets/ibge/`
- **Quando usar:** Para visualizar divisões administrativas (estados/municípios)

### ✅ **EnhancedMapScreen** - ESTE É O CORRETO!
- **Arquivo:** `mobile/lib/screens/enhanced_map_screen.dart`
- **Mostra:** **Áreas específicas de risco de alagamento dentro das cidades**
- **Usa:** Backend API `/risk/areas` com dados dinâmicos
- **Quando usar:** Para visualizar áreas de risco de alagamento

---

## 🚀 Como Usar o EnhancedMapScreen

### Método 1: Navegação Programática

No código onde você quer abrir o mapa de áreas de risco:

```dart
import '../screens/enhanced_map_screen.dart';

// Abrir mapa centrado em São Paulo
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedMapScreen(
      lat: -23.5505,  // Latitude
      lon: -46.6333,  // Longitude
    ),
  ),
);
```

### Método 2: Adicionar Botão na Tela de Risco

Edite `mobile/lib/screens/risk_result_screen.dart`:

```dart
// Adicione este botão na tela
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMapScreen(
          lat: widget.lat,   // Passa coordenadas da cidade
          lon: widget.lon,
        ),
      ),
    );
  },
  icon: Icon(Icons.map_outlined),
  label: Text('Ver Áreas de Risco no Mapa'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
),
```

---

## 📊 Como Funciona o EnhancedMapScreen

### 1. **Carrega Áreas de Risco do Backend**
O mapa faz uma chamada para: `GET /risk/areas?lat=X&lon=Y&radius=20`

### 2. **Renderiza Polígonos Coloridos**
- 🔴 Vermelho = Alto risco (áreas críticas)
- 🟡 Laranja = Médio risco (atenção)
- 🟢 Verde = Baixo risco (seguro)

### 3. **Mostra Legenda Inteligente**
A legenda agora inclui:

```
╔═══════════════════════════════════╗
║  ⚠️  Condição: CRÍTICA           ║  ← Status geral
╠═══════════════════════════════════╣
║  Nível de Risco                   ║
║  🔴 ⚠️ Alto - Risco crítico       ║
║  🟡 ⚠️ Médio - Atenção            ║
║  🟢 ✓ Baixo - Seguro              ║
║  ─────────────────────────────    ║
║  🗺️ 7 área(s) de risco           ║
╚═══════════════════════════════════╝
```

---

## 🧪 Como Testar

### Passo 1: Rode o Backend
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Passo 2: Verifique a API
```bash
# Teste direto da API
curl "http://localhost:8000/risk/areas?lat=-23.5505&lon=-46.6333&radius=20"
```

**Resposta esperada:**
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
        "name": "Zona Leste - Tatuapé",
        "riskLevel": "medium",
        "riskScore": 0.6,
        "fillColor": "#f59e0b"
      }
    }
  ]
}
```

### Passo 3: Rode o App
```bash
cd mobile
flutter clean
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000  # Android Emulator
```

### Passo 4: Navegue até o Mapa
1. Selecione cidade (ex: São Paulo - SP)
2. Veja o risco calculado
3. Clique no botão "Ver Áreas de Risco" (se adicionou)
4. **Resultado esperado:**
   - Mapa abre centrado em São Paulo
   - Polígonos coloridos aparecem nas áreas de risco
   - Legenda mostra: "Condição: CRÍTICA" (se houver áreas vermelhas)
   - Contador mostra "7 área(s) de risco"

---

## 🎨 O Que Você Verá

### Sem Áreas de Alto Risco:
```
┌─────────────────────┐
│ ✓ Condição: BOA     │  ← Verde
└─────────────────────┘
```

### Com Áreas de Médio Risco:
```
┌──────────────────────┐
│ ⚠️ Condição: ATENÇÃO │  ← Laranja
└──────────────────────┘
```

### Com Áreas de Alto Risco:
```
┌──────────────────────┐
│ ⚠️ Condição: CRÍTICA │  ← Vermelho
└──────────────────────┘
```

---

## 📝 Dados Atuais (Mock)

O backend possui **7 áreas de risco em São Paulo**:

| Área | Bairro | Risco Base |
|------|--------|------------|
| 1 | Tatuapé | Médio |
| 2 | Jabaquara | Alto |
| 3 | Santana | Baixo |
| 4 | Anhangabaú | Alto |
| 5 | Lapa | Médio |
| 6 | Campo Limpo | Alto |
| 7 | Itaquera | Médio |

**Localização:** `backend/app/services/risk_areas.py` (linhas 12-90)

---

## 🔧 Como Adicionar Mais Áreas

Edite `backend/app/services/risk_areas.py`:

```python
MOCK_RISK_AREAS = [
    # ... áreas existentes ...

    # Nova área
    {
        "name": "Zona Norte - Vila Maria",
        "base_risk": "high",  # low, medium, ou high
        "polygon": [
            [-46.5800, -23.5000],  # Ponto 1 (lon, lat)
            [-46.5700, -23.5000],  # Ponto 2
            [-46.5700, -23.5100],  # Ponto 3
            [-46.5800, -23.5100],  # Ponto 4
            [-46.5800, -23.5000],  # Fecha o polígono
        ],
    },
]
```

**Reinicie o backend** e as novas áreas aparecerão no mapa!

---

## 🎯 Filtros Disponíveis

### Filtro de Dia
- **Hoje** - Risco calculado para hoje
- **+1 dia** - Previsão para amanhã
- **+2 dias** - Previsão para depois de amanhã
- **+3 dias** - Previsão para 3 dias

O risco muda dinamicamente! Uma área que é "Média" hoje pode ser "Alta" amanhã.

### Filtro de Intensidade
- **Todos** - Mostra todas as áreas
- **Alto** - Mostra apenas áreas críticas
- **Médio** - Mostra apenas áreas de atenção
- **Baixo** - Mostra apenas áreas seguras

---

## ❓ FAQ

**Q: Por que o mapa não mostra áreas na minha cidade?**
A: Atualmente, apenas São Paulo tem áreas de risco mock. Adicione áreas para sua cidade no `risk_areas.py`.

**Q: Como integrar com dados reais?**
A: Substitua `MOCK_RISK_AREAS` por dados de:
- Defesa Civil (histórico de alagamentos)
- Sensores IoT (níveis de água)
- Topografia (áreas baixas)
- Machine Learning (previsão baseada em dados históricos)

**Q: O MapScreen serve para algo?**
A: Sim! Ele mostra limites administrativos. Use `EnhancedMapScreen` para áreas de risco.

**Q: Posso usar ambos os mapas?**
A: Sim! Você pode ter dois botões:
- "Ver Mapa da Região" → MapScreen (municípios)
- "Ver Áreas de Risco" → EnhancedMapScreen (áreas específicas)

---

## 📚 Resumo

1. ✅ Use **EnhancedMapScreen** para áreas de risco
2. ✅ A legenda agora mostra **status de condição** (Boa/Atenção/Crítica)
3. ✅ Backend precisa estar rodando para funcionar
4. ✅ Áreas de risco estão em `backend/app/services/risk_areas.py`
5. ✅ Adicione mais áreas editando o arquivo Python

**Próximo passo:** Adicione um botão em `risk_result_screen.dart` para abrir o `EnhancedMapScreen`!
