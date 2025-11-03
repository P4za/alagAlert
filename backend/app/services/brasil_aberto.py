"""
Serviço para integração com a API Brasil Aberto
Busca bairros (districts) de cidades brasileiras
"""

import os
import httpx
from typing import List, Dict, Optional


class BrasilAbertoService:
    """
    Cliente para API Brasil Aberto

    Documentação: https://brasilaberto.com/docs/v1/districts
    """

    BASE_URL = "https://api.brasilaberto.com/v1"

    def __init__(self, api_key: Optional[str] = None):
        """
        Inicializa o serviço

        Args:
            api_key: Chave da API Brasil Aberto (lê de BRASIL_ABERTO_API_KEY se não fornecida)
        """
        self.api_key = api_key or os.getenv("BRASIL_ABERTO_API_KEY", "")

        if not self.api_key:
            print("⚠️  AVISO: BRASIL_ABERTO_API_KEY não configurada. Usando apenas bairros hardcoded.")

    async def get_city_ibge_code(self, city_name: str, uf: str) -> Optional[str]:
        """
        Busca o código IBGE de uma cidade

        Args:
            city_name: Nome da cidade (ex: "São Paulo")
            uf: Sigla do estado (ex: "SP")

        Returns:
            Código IBGE da cidade ou None se não encontrado
        """
        url = f"https://servicodados.ibge.gov.br/api/v1/localidades/estados/{uf.upper()}/municipios"

        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(url)
                response.raise_for_status()
                cities = response.json()

                # Busca exata ou similar
                for city in cities:
                    if city.get("nome", "").lower() == city_name.lower():
                        return str(city.get("id"))

                # Se não encontrou exato, busca parcial
                for city in cities:
                    if city_name.lower() in city.get("nome", "").lower():
                        return str(city.get("id"))

                return None
        except Exception as e:
            print(f"Erro ao buscar código IBGE: {e}")
            return None

    async def get_districts_by_ibge_code(self, ibge_code: str) -> List[Dict]:
        """
        Busca bairros de uma cidade pelo código IBGE

        Args:
            ibge_code: Código IBGE da cidade (ex: "3550308" para São Paulo)

        Returns:
            Lista de bairros com id e nome
            Formato: [{"id": "...", "name": "Tatuapé"}, ...]
        """
        if not self.api_key:
            return []

        url = f"{self.BASE_URL}/districts-by-ibge-code/{ibge_code}"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
        }

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                response = await client.get(url, headers=headers)
                response.raise_for_status()
                data = response.json()

                # A API retorna algo como:
                # {
                #   "results": [
                #     {"id": "123", "name": "Tatuapé"},
                #     {"id": "124", "name": "Jabaquara"}
                #   ],
                #   "metadata": { ... }
                # }

                results = data.get("results", [])
                return results
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 401:
                print("❌ Erro 401: Chave da API Brasil Aberto inválida ou expirada")
            elif e.response.status_code == 404:
                print(f"❌ Erro 404: Cidade com código IBGE {ibge_code} não encontrada")
            else:
                print(f"Erro HTTP ao buscar bairros: {e}")
            return []
        except Exception as e:
            print(f"Erro ao buscar bairros da API Brasil Aberto: {e}")
            return []

    async def get_districts_with_coordinates(
        self,
        city_name: str,
        uf: str
    ) -> List[Dict[str, any]]:
        """
        Busca bairros com coordenadas aproximadas

        IMPORTANTE: A API Brasil Aberto retorna apenas nomes de bairros, não coordenadas.
        Precisamos usar Nominatim para geocodificar cada bairro.

        Args:
            city_name: Nome da cidade
            uf: Sigla do estado

        Returns:
            Lista de bairros com name, lat, lon
            Formato: [{"name": "Tatuapé", "lat": -23.532, "lon": -46.565}, ...]
        """
        # 1. Busca código IBGE da cidade
        ibge_code = await self.get_city_ibge_code(city_name, uf)
        if not ibge_code:
            print(f"⚠️  Código IBGE não encontrado para {city_name}/{uf}")
            return []

        # 2. Busca bairros da API Brasil Aberto
        districts = await self.get_districts_by_ibge_code(ibge_code)
        if not districts:
            return []

        # 3. Geocodifica cada bairro usando Nominatim
        results = []

        async with httpx.AsyncClient(timeout=10) as client:
            for district in districts[:15]:  # Limita a 15 bairros para não sobrecarregar
                district_name = district.get("name", "")
                if not district_name:
                    continue

                # Geocode usando Nominatim
                try:
                    nominatim_url = "https://nominatim.openstreetmap.org/search"
                    params = {
                        "q": f"{district_name}, {city_name}, {uf}, Brasil",
                        "format": "json",
                        "limit": 1,
                        "addressdetails": 1,
                    }
                    headers = {
                        "User-Agent": "AlagAlert/1.0",
                    }

                    response = await client.get(nominatim_url, params=params, headers=headers)

                    if response.status_code == 200:
                        data = response.json()
                        if data and len(data) > 0:
                            lat = float(data[0].get("lat", 0))
                            lon = float(data[0].get("lon", 0))

                            if lat != 0 and lon != 0:
                                results.append({
                                    "name": district_name,
                                    "lat": lat,
                                    "lon": lon,
                                })

                    # Rate limiting: Nominatim permite 1 req/segundo
                    import asyncio
                    await asyncio.sleep(1.1)

                except Exception as e:
                    print(f"Erro ao geocodificar bairro {district_name}: {e}")
                    continue

        return results
