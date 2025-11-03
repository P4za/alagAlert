"""
Serviço para integração com a API Brasil Aberto
Busca bairros (districts) de cidades brasileiras
"""

import os
import httpx
from typing import List, Dict, Optional
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env
load_dotenv()


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

        # Debug: mostra se a chave foi carregada (primeiros 10 caracteres apenas por segurança)
        if self.api_key:
            print(f"✅ API Key Brasil Aberto carregada: {self.api_key[:10]}...")
        else:
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

                # Busca exata
                for city in cities:
                    if city.get("nome", "").lower() == city_name.lower():
                        # O IBGE retorna o id como número inteiro
                        ibge_code = str(city.get("id"))
                        print(f"✅ Código IBGE encontrado: {ibge_code} para {city.get('nome')}/{uf}")
                        return ibge_code

                # Se não encontrou exato, busca parcial
                for city in cities:
                    if city_name.lower() in city.get("nome", "").lower():
                        ibge_code = str(city.get("id"))
                        print(f"✅ Código IBGE encontrado (busca parcial): {ibge_code} para {city.get('nome')}/{uf}")
                        return ibge_code

                print(f"❌ Cidade '{city_name}' não encontrada no estado {uf}")
                return None
        except Exception as e:
            print(f"❌ Erro ao buscar código IBGE: {e}")
            return None

    async def get_districts_by_ibge_code(self, ibge_code: str) -> List[Dict]:
        """
        Busca bairros de uma cidade pelo código IBGE

        Args:
            ibge_code: Código IBGE da cidade (ex: "3550308" para São Paulo)

        Returns:
            Lista de bairros com id e nome
            Formato: [{"id": "20379", "name": "Centro"}, ...]
        """
        if not self.api_key:
            print("❌ API Key não configurada. Não é possível buscar bairros.")
            return []

        # Garante que o código IBGE seja string
        ibge_code_str = str(ibge_code)
        
        url = f"{self.BASE_URL}/districts-by-ibge-code/{ibge_code_str}"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
        }

        print(f"🔍 Buscando bairros na URL: {url}")
        print(f"🔑 Usando API Key: {self.api_key[:10]}...")

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                response = await client.get(url, headers=headers)
                
                print(f"📡 Status da resposta: {response.status_code}")
                
                response.raise_for_status()
                data = response.json()

                # A API retorna:
                # {
                #   "meta": {
                #     "currentPage": 1,
                #     "itemsPerPage": 280,
                #     "totalOfItems": 280,
                #     "totalOfPages": 1
                #   },
                #   "result": [
                #     {"id": "20379", "name": "Centro"},
                #     {"id": "20380", "name": "Vila Jesus"}
                #   ]
                # }

                # IMPORTANTE: A chave é "result", não "results"!
                results = data.get("result", [])
                meta = data.get("meta", {})
                
                total_items = meta.get("totalOfItems", len(results))
                print(f"✅ Encontrados {total_items} bairros para código IBGE {ibge_code_str}")
                
                # Mostra os primeiros 5 bairros encontrados
                if results:
                    sample = ', '.join([d.get('name', '') for d in results[:5]])
                    print(f"📋 Primeiros bairros: {sample}...")
                
                return results
        except httpx.HTTPStatusError as e:
            print(f"❌ Erro HTTP {e.response.status_code}")
            print(f"📄 Resposta: {e.response.text[:500]}")
            
            if e.response.status_code == 401:
                print("💡 Dica: Verifique se a API Key está correta e válida")
            elif e.response.status_code == 404:
                print(f"💡 Dica: Código IBGE {ibge_code_str} não encontrado na API Brasil Aberto")
            elif e.response.status_code == 403:
                print("💡 Dica: Acesso negado. Verifique as permissões da API Key")
            
            return []
        except httpx.RequestError as e:
            print(f"❌ Erro de conexão: {e}")
            return []
        except Exception as e:
            print(f"❌ Erro inesperado ao buscar bairros: {type(e).__name__}: {e}")
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
        print(f"\n{'='*60}")
        print(f"🌎 Iniciando busca de bairros com coordenadas")
        print(f"📍 Cidade: {city_name}/{uf}")
        print(f"{'='*60}\n")

        # 1. Busca código IBGE da cidade
        print("ETAPA 1: Buscando código IBGE...")
        ibge_code = await self.get_city_ibge_code(city_name, uf)
        if not ibge_code:
            print(f"⚠️  Não foi possível encontrar o código IBGE para {city_name}/{uf}")
            return []

        # 2. Busca bairros da API Brasil Aberto
        print(f"\nETAPA 2: Buscando bairros na API Brasil Aberto...")
        districts = await self.get_districts_by_ibge_code(ibge_code)
        if not districts:
            print(f"⚠️  Nenhum bairro encontrado na API Brasil Aberto")
            return []

        # 3. Geocodifica cada bairro usando Nominatim
        print(f"\nETAPA 3: Geocodificando {min(15, len(districts))} bairros...")
        print(f"⏱️  Isso pode levar alguns minutos devido ao rate limit do Nominatim...\n")
        
        results = []

        async with httpx.AsyncClient(timeout=10) as client:
            for idx, district in enumerate(districts[:15], 1):  # Limita a 15 bairros
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
                                print(f"  ✓ [{idx}/{min(15, len(districts))}] {district_name}: ({lat:.4f}, {lon:.4f})")
                            else:
                                print(f"  ✗ [{idx}/{min(15, len(districts))}] {district_name}: coordenadas inválidas")
                        else:
                            print(f"  ✗ [{idx}/{min(15, len(districts))}] {district_name}: não encontrado")
                    else:
                        print(f"  ✗ [{idx}/{min(15, len(districts))}] {district_name}: erro {response.status_code}")

                    # Rate limiting: Nominatim permite 1 req/segundo
                    import asyncio
                    await asyncio.sleep(1.1)

                except Exception as e:
                    print(f"  ✗ [{idx}/{min(15, len(districts))}] {district_name}: {type(e).__name__}")
                    continue

        print(f"\n{'='*60}")
        print(f"✅ Concluído: {len(results)} bairros geocodificados com sucesso")
        print(f"{'='*60}\n")
        
        return results