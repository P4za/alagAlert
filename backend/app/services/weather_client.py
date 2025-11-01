from typing import Dict, List, Optional
import os
import httpx
from cachetools import TTLCache
from datetime import datetime

OPEN_METEO_URL = os.getenv("OPEN_METEO_URL", "https://api.open-meteo.com/v1/forecast")

# Cache: maxsize=500 entradas, TTL=10 minutos
_weather_cache = TTLCache(maxsize=500, ttl=600)

async def fetch_hourly_forecast(
    lat: float,
    lon: float,
    forecast_days: int = 1,
    timezone: str = "America/Sao_Paulo",
) -> List[Dict]:
    """
    Retorna lista de pontos horários:
      [{"timestamp", "temperature", "precipitation", "precipitation_probability", "wind_speed"}, ...]

    Args:
        lat: Latitude
        lon: Longitude
        forecast_days: Número de dias (1-7, padrão: 1)
        timezone: Fuso horário (padrão: America/Sao_Paulo)
    """
    # Normaliza coordenadas para cache (4 casas decimais)
    lat_key = round(lat, 4)
    lon_key = round(lon, 4)
    cache_key = f"{lat_key},{lon_key},{forecast_days},{timezone}"

    # Verifica cache
    if cache_key in _weather_cache:
        return _weather_cache[cache_key]

    # Limita forecast_days
    if forecast_days < 1:
        forecast_days = 1
    elif forecast_days > 7:
        forecast_days = 7

    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "temperature_2m,precipitation,precipitation_probability,wind_speed_10m",
        "forecast_days": forecast_days,
        "timezone": timezone,
    }

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(OPEN_METEO_URL, params=params)
        r.raise_for_status()
        j = r.json()
        h = j.get("hourly", {})
        times = h.get("time", []) or []
        temps = h.get("temperature_2m", []) or []
        precs = h.get("precipitation", []) or []
        prec_probs = h.get("precipitation_probability", []) or []
        winds = h.get("wind_speed_10m", []) or []

        out = []
        for i in range(len(times)):
            out.append({
                "timestamp": times[i],
                "temperature": float(temps[i]) if i < len(temps) and temps[i] is not None else None,
                "precipitation": float(precs[i]) if i < len(precs) and precs[i] is not None else None,
                "precipitation_probability": int(prec_probs[i]) if i < len(prec_probs) and prec_probs[i] is not None else None,
                "wind_speed": float(winds[i]) if i < len(winds) and winds[i] is not None else None,
            })

        # Armazena no cache
        _weather_cache[cache_key] = out

        return out


def filter_forecast_by_date(
    forecast: List[Dict],
    target_date: Optional[str] = None,
) -> List[Dict]:
    """
    Filtra previsão por data específica (formato: YYYY-MM-DD)
    Se target_date for None, retorna todos os pontos
    """
    if not target_date:
        return forecast

    return [
        point for point in forecast
        if point.get("timestamp", "").startswith(target_date)
    ]


def summarize_day(forecast: List[Dict]) -> Dict:
    """
    Retorna resumo estatístico de um conjunto de pontos horários
    """
    if not forecast:
        return {
            "avg_temperature": None,
            "total_precipitation": 0.0,
            "max_precipitation": 0.0,
            "avg_wind_speed": None,
            "avg_precipitation_probability": None,
        }

    temps = [p["temperature"] for p in forecast if p.get("temperature") is not None]
    precs = [p["precipitation"] for p in forecast if p.get("precipitation") is not None]
    winds = [p["wind_speed"] for p in forecast if p.get("wind_speed") is not None]
    probs = [p["precipitation_probability"] for p in forecast if p.get("precipitation_probability") is not None]

    return {
        "avg_temperature": round(sum(temps) / len(temps), 1) if temps else None,
        "total_precipitation": round(sum(precs), 2) if precs else 0.0,
        "max_precipitation": round(max(precs), 2) if precs else 0.0,
        "avg_wind_speed": round(sum(winds) / len(winds), 1) if winds else None,
        "avg_precipitation_probability": round(sum(probs) / len(probs)) if probs else None,
    }
