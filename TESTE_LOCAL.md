# 🚀 Guia de Teste Local - AlagAlert

## ⚠️ IMPORTANTE: Mudanças Recentes

### Busca de Cidades
✅ **Agora funciona SEM o backend!**
- A busca de cidades usa diretamente a API do IBGE
- Não é necessário ter o backend rodando para selecionar estados e cidades
- Funciona offline do backend

### Mapa
✅ **Arquivos GeoJSON adicionados**
- Criados arquivos para 9 estados: SP, RJ, MG, PR, RS, BA, PE, CE, DF
- O mapa agora carrega corretamente para estes estados

---

## 📋 Pré-requisitos

### Para testar APENAS o Mobile (busca de cidades)
- ✅ Flutter 3.35.x instalado
- ✅ Emulador ou dispositivo conectado
- ❌ **Backend NÃO é necessário** para busca de cidades

### Para testar TUDO (incluindo risco de alagamento)
- ✅ Flutter 3.35.x instalado
- ✅ Emulador ou dispositivo conectado
- ✅ **Backend rodando** (necessário para cálculo de risco)
- ✅ Python 3.13+ instalado

---

## 🎯 Cenário 1: Testar APENAS Busca de Cidades e Mapa

**Você NÃO precisa do backend para isso!**

```bash
# 1. Entre na pasta mobile
cd mobile

# 2. IMPORTANTE: Limpe o projeto (necessário após adicionar assets)
flutter clean

# 3. Instale as dependências
flutter pub get

# 4. Execute o app
flutter run
```

### ✅ O que funciona SEM backend:
- ✅ Seleção de Estado (dropdown com todos os 27 estados)
- ✅ Busca de Cidades (API IBGE direta, funciona para todos os estados)
- ✅ Visualização do Mapa (funciona para SP, RJ, MG, PR, RS, BA, PE, CE, DF)

### ❌ O que NÃO funciona SEM backend:
- ❌ Cálculo de risco de alagamento
- ❌ Previsão meteorológica
- ❌ Áreas de risco no mapa

---

## 🎯 Cenário 2: Testar TUDO (Backend + Mobile)

### Passo 1: Iniciar o Backend

**Terminal 1:**
```bash
# 1. Entre na pasta backend
cd backend

# 2. Crie ambiente virtual (primeira vez)
python -m venv venv

# 3. Ative o ambiente virtual
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 4. Instale dependências (primeira vez)
pip install -r requirements.txt

# 5. Execute o servidor
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

✅ **Backend rodando em:** `http://localhost:8000`

### Passo 2: Iniciar o Mobile

**Terminal 2:**
```bash
# 1. Entre na pasta mobile
cd mobile

# 2. Limpe o projeto (IMPORTANTE após adicionar assets)
flutter clean

# 3. Instale dependências
flutter pub get

# 4. Execute com URL do backend
flutter run --dart-define=API_URL=http://localhost:8000
```

**⚠️ IMPORTANTE - Configuração de URL por Plataforma:**

- **Android Emulator:** Use `http://10.0.2.2:8000`
  ```bash
  flutter run --dart-define=API_URL=http://10.0.2.2:8000
  ```

- **iOS Simulator:** Use `http://localhost:8000`
  ```bash
  flutter run --dart-define=API_URL=http://localhost:8000
  ```

- **Dispositivo Físico:** Use o IP da sua máquina
  ```bash
  # Descubra seu IP:
  # Windows: ipconfig
  # Linux/Mac: ifconfig ou ip addr

  flutter run --dart-define=API_URL=http://192.168.1.10:8000
  ```

---

## 🧪 Roteiro de Testes

### Teste 1: Busca de Cidades (SEM Backend)

1. ✅ Abra o app
2. ✅ No dropdown "Estado", selecione **SP**
3. ✅ No campo "Cidade", digite **"camp"**
4. ✅ **Resultado esperado:** Deve aparecer "Campinas" e outras cidades de SP
5. ✅ Troque para **RJ** no dropdown
6. ✅ Digite **"rio"** no campo cidade
7. ✅ **Resultado esperado:** Deve aparecer "Rio de Janeiro" e outras cidades do RJ

**✅ Se funcionou:** Busca de cidades está OK!

---

### Teste 2: Visualização do Mapa (SEM Backend)

1. ✅ Selecione **SP** como estado
2. ✅ Selecione **Campinas** como cidade
3. ✅ Clique em **"Usar esta cidade"**
4. ✅ Na tela seguinte, clique em **"Abrir mapa por UF"** (botão de mapa)
5. ✅ **Resultado esperado:** O mapa deve abrir mostrando polígonos de SP

**✅ Se funcionou:** Mapa está OK!

**❌ Se deu erro:** Verifique se você rodou `flutter clean` antes de `flutter run`

---

### Teste 3: Cálculo de Risco (COM Backend)

**⚠️ Este teste requer o backend rodando!**

1. ✅ Certifique-se que o backend está rodando em `http://localhost:8000`
2. ✅ No app, selecione **SP** → **Santos**
3. ✅ Clique em **"Ver risco"** (ou similar)
4. ✅ **Resultado esperado:** Deve mostrar risco de alagamento, temperatura, precipitação

**✅ Se funcionou:** Integração backend está OK!

**❌ Se deu erro de conexão:**
- Verifique se o backend está rodando
- Verifique a URL no `--dart-define=API_URL=...`
- Para Android Emulator, use `http://10.0.2.2:8000`

---

## 🐛 Troubleshooting

### Erro: "Unable to load asset: assets/ibge/SP.geojson"

**Solução:**
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

O `flutter clean` é **OBRIGATÓRIO** após adicionar novos assets!

---

### Erro: "No cities found" ou autocomplete vazio

**Causa:** Problema de conexão com a API do IBGE

**Solução:**
1. Verifique sua conexão com a internet
2. Teste a API do IBGE manualmente:
   ```bash
   curl "https://servicodados.ibge.gov.br/api/v1/localidades/estados/SP/municipios"
   ```
3. Se a API do IBGE estiver fora do ar, aguarde retornar

---

### Erro: Mapa não carrega para meu estado

**Causa:** Apenas 9 estados têm GeoJSON no momento

**Estados disponíveis:** SP, RJ, MG, PR, RS, BA, PE, CE, DF

**Solução temporária:** Teste com um dos estados disponíveis

**Para adicionar mais estados:** Edite `backend/data/ibge/municipios.geojson` e rode o script de separação

---

### Erro: "Connection refused" ao calcular risco

**Causa:** Backend não está rodando ou URL incorreta

**Solução:**
1. Verifique se o backend está rodando: `http://localhost:8000/health`
2. Para Android Emulator, use: `--dart-define=API_URL=http://10.0.2.2:8000`
3. Para dispositivo físico, use o IP da sua máquina

---

## 📝 Checklist Final

Antes de reportar problemas, confirme:

- [ ] Rodou `flutter clean` após git pull
- [ ] Rodou `flutter pub get`
- [ ] Backend está rodando (se testando risco)
- [ ] URL está correta para sua plataforma (Android Emulator = 10.0.2.2)
- [ ] Testou com um dos 9 estados disponíveis

---

## ✅ Estados dos Recursos

| Recurso | Status | Depende do Backend? |
|---------|--------|---------------------|
| Busca de Estados | ✅ Funcionando | ❌ Não |
| Busca de Cidades | ✅ Funcionando | ❌ Não |
| Mapa de 9 Estados | ✅ Funcionando | ❌ Não |
| Cálculo de Risco | ✅ Funcionando | ✅ Sim |
| Previsão Meteorológica | ✅ Funcionando | ✅ Sim |
| Áreas de Risco | ✅ Funcionando | ✅ Sim |

---

## 🎉 Sucesso!

Se todos os testes passaram, seu ambiente está configurado corretamente! 🚀

Para dúvidas, abra uma issue no GitHub.
