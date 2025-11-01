"""
Serviço para fornecer áreas de risco de alagamento em formato GeoJSON.
Por enquanto usa dados mock focados em São Paulo/SP.
"""

from typing import Optional, Dict, List
from datetime import datetime, timedelta
import random

# Mock: áreas de risco conhecidas em São Paulo (coordenadas aproximadas)
# Cada área tem um polígono e um nível de risco base
MOCK_RISK_AREAS = [
    {
        "name": "Zona Leste - Tatuapé",
        "base_risk": "medium",
        "polygon": [
            [-46.5650, -23.5320],
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
    {
        "name": "Zona Norte - Santana",
        "base_risk": "low",
        "polygon": [
            [-46.6290, -23.5050],
            [-46.6190, -23.5050],
            [-46.6190, -23.5150],
            [-46.6290, -23.5150],
            [-46.6290, -23.5050],
        ],
    },
    {
        "name": "Centro - Anhangabaú",
        "base_risk": "high",
        "polygon": [
            [-46.6360, -23.5450],
            [-46.6310, -23.5450],
            [-46.6310, -23.5500],
            [-46.6360, -23.5500],
            [-46.6360, -23.5450],
        ],
    },
    {
        "name": "Zona Oeste - Lapa",
        "base_risk": "medium",
        "polygon": [
            [-46.7050, -23.5280],
            [-46.6950, -23.5280],
            [-46.6950, -23.5380],
            [-46.7050, -23.5380],
            [-46.7050, -23.5280],
        ],
    },
    {
        "name": "Zona Sul - Campo Limpo",
        "base_risk": "high",
        "polygon": [
            [-46.7680, -23.6550],
            [-46.7580, -23.6550],
            [-46.7580, -23.6650],
            [-46.7680, -23.6650],
            [-46.7680, -23.6550],
        ],
    },
    {
        "name": "Zona Leste - Itaquera",
        "base_risk": "medium",
        "polygon": [
            [-46.4560, -23.5400],
            [-46.4460, -23.5400],
            [-46.4460, -23.5500],
            [-46.4560, -23.5500],
            [-46.4560, -23.5400],
        ],
    },
]


def _adjust_risk_by_day(base_risk: str, days_from_today: int) -> str:
    """
    Ajusta o nível de risco baseado no dia
    Simula que o risco aumenta nos próximos dias por previsão de chuva
    """
    if days_from_today == 0:
        return base_risk

    # Simula variação baseada no dia
    risk_levels = ["low", "medium", "high"]
    base_idx = risk_levels.index(base_risk)

    # Adiciona aleatoriedade baseada no dia
    random.seed(days_from_today * 1000)  # seed determinístico
    variation = random.choice([-1, 0, 1])
    new_idx = max(0, min(2, base_idx + variation))

    return risk_levels[new_idx]


def _risk_level_to_properties(level: str) -> Dict:
    """
    Retorna propriedades visuais baseadas no nível de risco
    """
    if level == "high":
        return {
            "fillColor": "#dc2626",
            "fillOpacity": 0.4,
            "strokeColor": "#991b1b",
            "strokeWeight": 2,
        }
    elif level == "medium":
        return {
            "fillColor": "#f59e0b",
            "fillOpacity": 0.3,
            "strokeColor": "#d97706",
            "strokeWeight": 2,
        }
    else:  # low
        return {
            "fillColor": "#10b981",
            "fillOpacity": 0.2,
            "strokeColor": "#059669",
            "strokeWeight": 1,
        }


def get_risk_areas_geojson(
    lat: float,
    lon: float,
    radius_km: float = 10.0,
    risk_level: Optional[str] = None,
    date: Optional[str] = None,
) -> Dict:
    """
    Retorna GeoJSON com áreas de risco filtradas por:
    - lat/lon: centro da busca
    - radius_km: raio em km (padrão: 10km)
    - risk_level: filtro opcional por nível (low/medium/high)
    - date: data de previsão (YYYY-MM-DD), afeta o risco calculado

    Retorna FeatureCollection em formato GeoJSON
    """
    # Calcula dias desde hoje se date for fornecido
    days_from_today = 0
    if date:
        try:
            target = datetime.strptime(date, "%Y-%m-%d").date()
            today = datetime.now().date()
            days_from_today = (target - today).days
        except ValueError:
            pass

    features = []

    # TODO: Implementar filtro por distância real (lat/lon vs radius_km)
    # Por enquanto, retorna todas as áreas de São Paulo

    for area in MOCK_RISK_AREAS:
        # Ajusta risco baseado no dia
        adjusted_risk = _adjust_risk_by_day(area["base_risk"], days_from_today)

        # Filtra por nível de risco se especificado
        if risk_level and adjusted_risk != risk_level:
            continue

        # Cria Feature GeoJSON
        visual_props = _risk_level_to_properties(adjusted_risk)

        feature = {
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [area["polygon"]],
            },
            "properties": {
                "name": area["name"],
                "riskLevel": adjusted_risk,
                "riskScore": {"low": 0.3, "medium": 0.6, "high": 0.85}[adjusted_risk],
                "date": date or datetime.now().strftime("%Y-%m-%d"),
                **visual_props,
            },
        }
        features.append(feature)

    return {
        "type": "FeatureCollection",
        "features": features,
        "metadata": {
            "center": {"lat": lat, "lon": lon},
            "radius_km": radius_km,
            "filter_risk_level": risk_level,
            "date": date or datetime.now().strftime("%Y-%m-%d"),
            "total_features": len(features),
        },
    }


def get_simplified_risk_areas(
    lat: float,
    lon: float,
    zoom_level: int = 10,
) -> Dict:
    """
    Retorna áreas de risco simplificadas baseadas no nível de zoom
    Para zoom < 12, agrupa polígonos próximos
    """
    if zoom_level >= 12:
        # Zoom alto: retorna polígonos completos
        return get_risk_areas_geojson(lat, lon)

    # Zoom baixo: retorna apenas centroides como pontos
    features = []
    for area in MOCK_RISK_AREAS:
        polygon = area["polygon"]
        # Calcula centroide simples
        avg_lon = sum(p[0] for p in polygon) / len(polygon)
        avg_lat = sum(p[1] for p in polygon) / len(polygon)

        feature = {
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [avg_lon, avg_lat],
            },
            "properties": {
                "name": area["name"],
                "riskLevel": area["base_risk"],
            },
        }
        features.append(feature)

    return {
        "type": "FeatureCollection",
        "features": features,
        "metadata": {
            "simplified": True,
            "zoom_level": zoom_level,
        },
    }
