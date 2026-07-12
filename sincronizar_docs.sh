#!/usr/bin/env bash
# Sincroniza la data publicable del pipeline R hacia /docs (GitHub Pages).
# Uso: bash sincronizar_docs.sh   (correr tras regenerar 36; NO toca 00_run_all.R)
cp 40_salidas/mapa_interactivo/web/data/establecimientos.geojson \
   40_salidas/mapa_interactivo/web/data/sin_geo.json \
   40_salidas/mapa_interactivo/web/data/metadatos.json docs/data/
echo "docs/data sincronizado desde 40_salidas/mapa_interactivo/web/data/"
