# Windows Setup - Fix Encoding Error

## Problem

If you see this error on Windows:

```
UnicodeDecodeError: 'charmap' codec can't decode byte 0x8f in position 497
```

This happens because the `.env` file contains special characters that Windows cannot read with the default encoding (cp1252).

## Quick Fix

### Step 1: Delete Existing .env File

```powershell
cd D:\alagAlert\backend
del .env
```

### Step 2: Create New .env File

Create a new file `backend\.env` with this content (NO EMOJIS):

```
# AlagAlert - Environment Variables
# Leave BRASIL_ABERTO_API_KEY empty to use hardcoded neighborhoods only

BRASIL_ABERTO_API_KEY=

HOST=0.0.0.0
PORT=8000
RATE_LIMIT=60/minute
```

**IMPORTANT:** Save the file with UTF-8 encoding (not ANSI/cp1252).

In VS Code:
1. Click on the encoding at the bottom right (it might say "UTF-8" or "ANSI")
2. Select "Save with Encoding"
3. Choose "UTF-8"

In Notepad:
1. File > Save As
2. Encoding dropdown: Select "UTF-8"
3. Save

### Step 3: Restart Backend

```powershell
cd D:\alagAlert\backend
.venv-1\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

You should now see:

```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

## Working Without Brasil Aberto API

The system will work with **3 hardcoded cities** if you don't configure the API key:

- Sao Paulo/SP (10 neighborhoods)
- Campinas/SP (4 neighborhoods)
- Santos/SP (4 neighborhoods)

### Test Backend

```powershell
# Test Sao Paulo (should work)
curl "http://localhost:8000/risk/neighborhoods?city=São Paulo&uf=SP&forecast_days=1"
```

### Test Frontend

1. Run Flutter app:
```powershell
cd D:\alagAlert\mobile
flutter run -d chrome
```

2. In the app:
   - Select state: **SP** or **Sao Paulo**
   - Search city: **Sao Paulo**
   - Click **"Ver Mapa de Areas de Risco"**

**Expected result:**
- Map opens centered on Sao Paulo
- 10 colored polygons appear (neighborhoods)
- Legend shows condition (BOA/ATENCAO/CRITICA)

## If Map Still Doesn't Open

### Check 1: Backend is Running

Make sure backend is running on port 8000:

```powershell
curl http://localhost:8000/health
```

Expected: `{"ok":true}`

### Check 2: Flutter Can Reach Backend

Check `mobile\lib\services\api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

For Windows, you may need to use your machine's IP address instead of `localhost`.

### Check 3: Backend Logs

Watch the backend console for errors when you click "Ver Mapa":

```
INFO:     127.0.0.1:12345 - "GET /risk/neighborhoods?city=Sao Paulo&uf=SP&forecast_days=1 HTTP/1.1" 200 OK
```

If you see **404** or **500**, there's an error. Check the error message.

### Check 4: Network Tab (Chrome DevTools)

If using Chrome:
1. Press F12 to open DevTools
2. Go to Network tab
3. Click "Ver Mapa de Areas de Risco"
4. Look for the request to `/risk/neighborhoods`

**If it fails:**
- Check the error message in the Response tab
- Verify the request URL includes correct city and uf parameters

## Common Issues

### Issue: "Failed to load risk areas: XMLHttpRequest error"

**Cause:** Backend not running or wrong URL

**Fix:**
1. Make sure backend is running: `uvicorn app.main:app --reload`
2. Check `api_service.dart` has correct URL
3. Try using IP address instead of localhost

### Issue: "Nenhum bairro cadastrado para X"

**Cause:** City not in hardcoded list (without API key)

**Fix:**
1. Only test with: Sao Paulo, Campinas, or Santos
2. OR configure Brasil Aberto API key (see BRASIL_ABERTO_SETUP.md)

### Issue: Backend starts but crashes immediately

**Cause:** Missing dependencies

**Fix:**
```powershell
cd D:\alagAlert\backend
.venv-1\Scripts\activate
pip install -r requirements.txt
```

## Configure Brasil Aberto API (Optional)

To make it work for ALL Brazilian cities:

1. Get API key from https://brasilaberto.com/
2. Edit `backend\.env`:
```
BRASIL_ABERTO_API_KEY=your_actual_key_here
```
3. Restart backend

See `BRASIL_ABERTO_SETUP.md` for detailed instructions.

## Verify Everything Works

### Test 1: Health Check

```powershell
curl http://localhost:8000/health
```

Expected: `{"ok":true}`

### Test 2: Neighborhoods Endpoint

```powershell
curl "http://localhost:8000/risk/neighborhoods?city=São Paulo&uf=SP&forecast_days=1"
```

Expected: JSON with 10 neighborhoods

### Test 3: Flutter App

1. Run app
2. Select: Sao Paulo/SP
3. Click "Ver Mapa de Areas de Risco"
4. See colored polygons on map

## Still Having Issues?

1. Check backend console logs for errors
2. Check Chrome DevTools Console (F12) for frontend errors
3. Make sure `.env` file is UTF-8 encoded (not ANSI)
4. Try deleting `.env` and recreating it
5. Verify all dependencies are installed: `pip install -r requirements.txt`

## Files to Check

```
backend/
├── .env              <- Create this (UTF-8 encoding)
├── .env.example      <- Template (don't edit)
├── .gitignore        <- Make sure .env is listed
└── app/
    └── main.py       <- Should start without errors
```

The `.env` file should NOT be committed to Git. It's in `.gitignore`.
