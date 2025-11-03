# 🗺️ Configuração da API Brasil Aberto

## 📋 O Que É?

A **API Brasil Aberto** fornece dados de bairros de todas as cidades brasileiras. Com ela, o sistema AlagAlert pode buscar automaticamente os bairros de qualquer cidade que o usuário selecionar, ao invés de usar apenas dados hardcoded.

## 🔑 Como Obter a Chave da API

### 1. Acesse o Site
Visite: https://brasilaberto.com/

### 2. Crie uma Conta
- Clique em "Entrar" ou "Registrar"
- Preencha seus dados
- Confirme seu email

### 3. Obtenha a Chave
- Faça login no dashboard
- Navegue até "API Keys" ou "Chaves de API"
- Copie sua chave de API

**Formato da chave:** Geralmente é uma string alfanumérica longa (ex: `abc123def456...`)

### 4. Planos Disponíveis
Consulte os planos em: https://brasilaberto.com/

- **Plano Gratuito:** Geralmente inclui um número limitado de requisições/mês
- **Planos Pagos:** Para uso mais intensivo

## ⚙️ Como Configurar no Projeto

### Passo 1: Criar Arquivo .env

```bash
cd backend
cp .env.example .env
```

### Passo 2: Editar o Arquivo .env

Abra o arquivo `backend/.env` e substitua `sua_chave_aqui` pela sua chave real:

```bash
# backend/.env
BRASIL_ABERTO_API_KEY=SUA_CHAVE_REAL_AQUI_ABC123DEF456
```

**Exemplo:**
```bash
BRASIL_ABERTO_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
```

### Passo 3: Reiniciar o Backend

```bash
cd backend
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows

uvicorn app.main:app --reload
```

## 🧪 Como Testar

### Teste 1: Verificar se a Chave Foi Carregada

No log do backend, você deve ver:

```
✅ BRASIL_ABERTO_API_KEY configurada
```

Ao invés de:

```
⚠️  AVISO: BRASIL_ABERTO_API_KEY não configurada. Usando apenas bairros hardcoded.
```

### Teste 2: Buscar Bairros de Outra Cidade

```bash
# Testar com Rio de Janeiro (antes não funcionava)
curl "http://localhost:8000/risk/neighborhoods?city=Rio%20de%20Janeiro&uf=RJ&forecast_days=1"
```

**Resposta esperada:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {...},
      "properties": {
        "name": "Copacabana",
        "riskLevel": "low",
        "weather": {
          "total_precipitation_mm": 2.3,
          "avg_probability": 15.5
        }
      }
    }
    // ... mais bairros
  ],
  "metadata": {
    "city": "Rio de Janeiro",
    "uf": "RJ",
    "total_features": 15
  }
}
```

### Teste 3: No App Flutter

1. Abra o app
2. Selecione estado: **RJ**
3. Busque cidade: **Rio de Janeiro**
4. Clique em **"Ver Mapa de Áreas de Risco"**

**Resultado esperado:**
- Mapa abre centrado no Rio de Janeiro
- Bairros aparecem com polígonos coloridos
- Legenda mostra condição (BOA/ATENÇÃO/CRÍTICA)

## 🔄 Como Funciona o Sistema

### Fluxo com API Configurada

```
1. Usuário seleciona: Rio de Janeiro/RJ
2. Flutter chama: /risk/neighborhoods?city=Rio de Janeiro&uf=RJ
3. Backend:
   ├─> Verifica cache de bairros
   ├─> Se não encontrado, busca código IBGE da cidade
   ├─> Chama Brasil Aberto API: /districts-by-ibge-code/{codigo}
   ├─> Recebe lista de bairros: ["Copacabana", "Ipanema", ...]
   ├─> Para cada bairro:
   │   ├─> Geocodifica (Nominatim) para obter lat/lon
   │   ├─> Busca clima (Open-Meteo) para lat/lon
   │   └─> Calcula risco baseado em precipitação
   └─> Retorna GeoJSON com polígonos coloridos
4. Flutter renderiza mapa com bairros
```

### Fluxo SEM API (Fallback)

```
1. Usuário seleciona: São Paulo/SP
2. Backend não tem API key
3. Backend usa bairros hardcoded (KNOWN_NEIGHBORHOODS)
4. Funciona apenas para: São Paulo, Campinas, Santos
```

## ⚠️ O Que Acontece se Não Configurar?

### Cidades que Funcionam (Hardcoded)
- ✅ São Paulo/SP (10 bairros)
- ✅ Campinas/SP (4 bairros)
- ✅ Santos/SP (4 bairros)

### Outras Cidades
- ❌ Rio de Janeiro/RJ → "Nenhum bairro cadastrado"
- ❌ Curitiba/PR → "Nenhum bairro cadastrado"
- ❌ Salvador/BA → "Nenhum bairro cadastrado"
- ❌ Todas as outras cidades

## 🎯 Cache de Bairros

O sistema implementa cache para evitar chamadas repetidas à API:

```python
# Primeira chamada para Rio de Janeiro
🔍 Buscando bairros de Rio de Janeiro/RJ na API Brasil Aberto...
✅ Encontrados 15 bairros via Brasil Aberto API

# Chamadas subsequentes
✅ Usando bairros do cache para Rio de Janeiro/RJ
```

**Vantagens:**
- ⚡ Resposta mais rápida
- 💰 Economiza chamadas de API
- 🚀 Melhor performance

**Nota:** O cache é reiniciado quando o servidor reinicia.

## 🐛 Troubleshooting

### Erro 401: "Chave da API Brasil Aberto inválida ou expirada"

**Causa:** Chave incorreta ou expirada

**Solução:**
1. Verifique se copiou a chave corretamente (sem espaços)
2. Gere uma nova chave no dashboard da Brasil Aberto
3. Atualize o arquivo `.env`
4. Reinicie o backend

### Erro 404: "Cidade com código IBGE X não encontrada"

**Causa:** Cidade não existe na base da Brasil Aberto

**Solução:**
- Verifique se o nome da cidade está correto
- Algumas cidades podem não estar cadastradas

### Nenhum Bairro Retornado

**Logs para investigar:**
```
⚠️  Código IBGE não encontrado para Cidade/UF
⚠️  API Brasil Aberto não retornou bairros. Usando hardcoded.
```

**Possíveis causas:**
1. Nome da cidade incorreto
2. Cidade não tem bairros cadastrados na API
3. Problema de conexão com a API

## 📊 Limites e Considerações

### Rate Limiting

1. **Brasil Aberto API:**
   - Depende do seu plano
   - Verifique no dashboard

2. **Nominatim (Geocodificação):**
   - Limite: 1 requisição/segundo
   - O código já implementa delay de 1.1s

3. **Open-Meteo (Clima):**
   - Sem limite (API gratuita e open-source)

### Número de Bairros

O código limita a 15 bairros por cidade para:
- ✅ Evitar timeout (geocodificação de 15 bairros = ~17 segundos)
- ✅ Manter o mapa legível
- ✅ Respeitar rate limits do Nominatim

**Código:**
```python
for district in districts[:15]:  # Limita a 15 bairros
```

Para aumentar:
```python
for district in districts[:30]:  # 30 bairros = ~34 segundos
```

## 🔒 Segurança

### ⚠️ NUNCA Compartilhe Sua Chave

- ❌ Não commite o arquivo `.env` no Git
- ❌ Não poste a chave em fóruns/issues
- ❌ Não compartilhe em screenshots

### Arquivo .gitignore

Verifique que `.env` está no `.gitignore`:

```bash
# backend/.gitignore
.env
```

### Rotação de Chaves

Se sua chave foi exposta:
1. Acesse o dashboard da Brasil Aberto
2. Revogue a chave antiga
3. Gere uma nova chave
4. Atualize o `.env`

## 📝 Arquivos Relacionados

```
backend/
├── .env.example          # Template com exemplo
├── .env                  # Seu arquivo (criar e NÃO commitar)
├── app/
│   ├── services/
│   │   ├── brasil_aberto.py           # Cliente da API
│   │   └── neighborhood_weather.py    # Integração completa
│   └── main.py           # Endpoint /risk/neighborhoods
```

## 🎓 Próximos Passos

### Depois de Configurar

1. ✅ Teste com várias cidades diferentes
2. ✅ Verifique os logs do backend
3. ✅ Monitore uso da API no dashboard Brasil Aberto
4. ✅ Ajuste o limite de bairros se necessário (linha 175 em brasil_aberto.py)

### Para Produção

Considere:
- Implementar banco de dados para cache persistente
- Usar Redis para cache distribuído
- Implementar retry logic para APIs
- Monitorar uso e custos das APIs

## 📚 Recursos

- **Brasil Aberto:** https://brasilaberto.com/
- **Documentação:** https://brasilaberto.com/docs/v1/districts
- **IBGE API:** https://servicodados.ibge.gov.br/api/docs/localidades
- **Open-Meteo:** https://open-meteo.com/en/docs
- **Nominatim:** https://nominatim.org/release-docs/develop/api/Overview/

## ❓ Dúvidas?

Se encontrar problemas:
1. Verifique os logs do backend (`uvicorn app.main:app --reload`)
2. Teste os endpoints manualmente com `curl`
3. Consulte este guia novamente
4. Verifique a documentação oficial da Brasil Aberto
