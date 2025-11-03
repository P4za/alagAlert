"""
Serviço para buscar bairros de uma cidade e calcular risco baseado em previsão de chuva REAL
"""

from typing import List, Dict, Optional
from datetime import datetime
import httpx

# Para demo, vamos usar alguns bairros conhecidos de São Paulo
# Em produção, você integraria com uma API de bairros real
KNOWN_NEIGHBORHOODS = {
    "São Paulo": [
        {"name": "Tatuapé", "lat": -23.5320, "lon": -46.5650},
        {"name": "Jabaquara", "lat": -23.6290, "lon": -46.6420},
        {"name": "Santana", "lat": -23.5050, "lon": -46.6290},
        {"name": "Centro", "lat": -23.5475, "lon": -46.6361},
        {"name": "Lapa", "lat": -23.5280, "lon": -46.7050},
        {"name": "Itaquera", "lat": -23.5400, "lon": -46.4560},
        {"name": "Vila Mariana", "lat": -23.5880, "lon": -46.6370},
        {"name": "Pinheiros", "lat": -23.5650, "lon": -46.6920},
        {"name": "Mooca", "lat": -23.5500, "lon": -46.5975},
        {"name": "Butantã", "lat": -23.5650, "lon": -46.7290},
    ],
    "Campinas": [
        {"name": "Cambuí", "lat": -22.9000, "lon": -47.0600},
        {"name": "Taquaral", "lat": -22.8720, "lon": -47.0520},
        {"name": "Barão Geraldo", "lat": -22.8180, "lon": -47.0890},
        {"name": "Centro", "lat": -22.9070, "lon": -47.0630},
    ],
    "Santos": [
        {"name": "Gonzaga", "lat": -23.9660, "lon": -46.3330},
        {"name": "Boqueirão", "lat": -23.9700, "lon": -46.3270},
        {"name": "Ponta da Praia", "lat": -23.9800, "lon": -46.3000},
        {"name": "Centro", "lat": -23.9608, "lon": -46.3331},
    ],
}


async def get_weather_for_location(lat: float, lon: float, forecast_days: int = 1) -> Dict:
    """
    Busca previsão de chuva do Open-Meteo para uma localização específica
    """
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "precipitation,precipitation_probability",
        "forecast_days": forecast_days,
        "timezone": "America/Sao_Paulo",
    }

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            # Calcula precipitação total e probabilidade média
            hourly = data.get("hourly", {})
            precip = hourly.get("precipitation", [])
            prob = hourly.get("precipitation_probability", [])

            total_precip = sum(precip) if precip else 0
            avg_prob = sum(prob) / len(prob) if prob else 0

            return {
                "total_precipitation_mm": round(total_precip, 1),
                "avg_probability": round(avg_prob, 1),
                "max_precipitation_mm": round(max(precip), 1) if precip else 0,
            }
    except Exception as e:
        print(f"Erro ao buscar clima: {e}")
        return {
            "total_precipitation_mm": 0,
            "avg_probability": 0,
            "max_precipitation_mm": 0,
        }


def calculate_risk_from_precipitation(precip_mm: float, probability: float) -> str:
    """
    Calcula nível de risco baseado na precipitação prevista

    Critérios:
    - Alto: > 20mm OU probabilidade > 70%
    - Médio: > 10mm OU probabilidade > 50%
    - Baixo: resto
    """
    if precip_mm > 20 or probability > 70:
        return "high"
    elif precip_mm > 10 or probability > 50:
        return "medium"
    else:
        return "low"


def create_polygon_around_point(lat: float, lon: float, size_km: float = 1.0) -> List[List[float]]:
    """
    Cria um polígono quadrado ao redor de um ponto
    size_km: tamanho do lado do quadrado em km
    """
    # 1 grau ≈ 111km
    offset = size_km / 111.0

    return [
        [lon - offset/2, lat - offset/2],  # SW
        [lon + offset/2, lat - offset/2],  # SE
        [lon + offset/2, lat + offset/2],  # NE
        [lon - offset/2, lat + offset/2],  # NW
        [lon - offset/2, lat - offset/2],  # SW (fecha)
    ]


async def get_neighborhoods_with_weather(
    city: str,
    uf: str,
    forecast_days: int = 1,
    risk_level: Optional[str] = None,
) -> Dict:
    """
    Retorna GeoJSON com bairros e suas previsões de chuva

    Args:
        city: Nome da cidade
        uf: Sigla do estado
        forecast_days: Dias de previsão (1-7)
        risk_level: Filtro opcional por nível (low/medium/high)

    Returns:
        GeoJSON FeatureCollection com polígonos de bairros
    """
    # Busca bairros conhecidos da cidade
    neighborhoods = KNOWN_NEIGHBORHOODS.get(city, [])

    if not neighborhoods:
        return {
            "type": "FeatureCollection",
            "features": [],
            "metadata": {
                "city": city,
                "uf": uf,
                "message": f"Nenhum bairro cadastrado para {city}",
                "total_features": 0,
            },
        }

    features = []

    # Para cada bairro, busca a previsão de chuva
    for neighborhood in neighborhoods:
        weather = await get_weather_for_location(
            neighborhood["lat"],
            neighborhood["lon"],
            forecast_days,
        )

        # Calcula risco baseado na precipitação
        risk = calculate_risk_from_precipitation(
            weather["total_precipitation_mm"],
            weather["avg_probability"],
        )

        # Filtra por nível de risco se especificado
        if risk_level and risk != risk_level:
            continue

        # Define cor baseada no risco
        colors = {
            "high": {"fill": "#dc2626", "stroke": "#991b1b"},
            "medium": {"fill": "#f59e0b", "stroke": "#d97706"},
            "low": {"fill": "#10b981", "stroke": "#059669"},
        }

        color = colors.get(risk, colors["low"])

        # Cria polígono ao redor do bairro
        polygon = create_polygon_around_point(
            neighborhood["lat"],
            neighborhood["lon"],
            size_km=1.5,  # Polígonos de 1.5km²
        )

        feature = {
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [polygon],
            },
            "properties": {
                "name": neighborhood["name"],
                "city": city,
                "uf": uf,
                "riskLevel": risk,
                "weather": weather,
                "fillColor": color["fill"],
                "strokeColor": color["stroke"],
                "fillOpacity": 0.4 if risk == "high" else 0.3,
            },
        }
        features.append(feature)

    return {
        "type": "FeatureCollection",
        "features": features,
        "metadata": {
            "city": city,
            "uf": uf,
            "forecast_days": forecast_days,
            "total_features": len(features),
            "filtered_by_risk": risk_level,
        },
    }
