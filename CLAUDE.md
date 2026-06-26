# CLAUDE.md — slep_georreferenciacion

## Descripción
Pipeline en R que georreferencia los 97 establecimientos educacionales del SLEP Costa
Central (Puchuncaví, Quintero, Concón, Viña del Mar) y genera un **afiche cartográfico**
(HTML autocontenido) sobre fondo CARTO Positron real.

## Stack
- R. Pipe nativo `|>`, `dplyr` con `.by=`, `here::here()` para toda ruta.
- Geo/render: `sf`, `maptiles` (CARTO Positron), `terra`, `ggplot2` + `ragg`, `ggrepel`.
- Lectura: `readxl`, `janitor`. Salida HTML: `glue`, `base64enc`. PDF: `pagedown`.
- **Requiere locale UTF-8** (`LANG/LC_ALL=en_US.UTF-8`) para mapear tipos con tilde en 31.

## Estructura relevante
- `00_run_all.R` — orquestador. `run_all(from, to, only, skip)`.
- `10_utils/10_utils.R` (bootstrapping), `10_configuracion.R` (RUTAS, TIPOS, TOKENS, LIENZO).
- `30_procesamiento/31_leer_validar.R` → `establecimientos_validados.rds`.
- `30_procesamiento/32_proyectar_lienzo.R` → `establecimientos_proyectados.rds`.
- `30_procesamiento/33_generar_afiche.R` → `40_salidas/afiche/mapa_establecimientos.html`.
- `20_insumos/maestro_establecimientos.xlsx` (8 col), `20_insumos/comunas.geojson` (campo `Comuna`).
- `50_documentacion/andamios/` — encargos, logs y auditorías.

## Convenciones
- Commits atómicos temáticos, mensajes en español. Comentarios de código en español.
- snake_case sin tildes/ñ/espacios en nombres de archivo.
- Numeración oficial N→S (comuna por latitud media → tipo → nombre alfabético), 1..97,
  compartida por mapa, inset e índice. Verificada con `stopifnot` y panel adversarial.
- Los PNG de paneles del afiche se regeneran y van incrustados (base64) en el HTML; el
  HTML final SÍ se versiona, los PNG y `*.rds` no.

## Últimos cambios (más recientes primero)
1. **Poda v2 del afiche** (`33_generar_afiche.R`): mapa con SOLO pines numerados sobre
   CARTO Positron + límites comunales visibles (geom_path). Se quitaron etiquetas al mar,
   en tierra, ggrepel, leader lines y la lógica de apretado/NN. Colores de pin v2.
2. Índice (izquierda) ahora lleva **número + nombre + RBD**; leyenda con colores v2.
3. Reescrito antes como paradigma D (etiquetas al mar); v2 simplifica a pines (el titular
   pondrá los nombres a mano sobre el mapa).
4. Fix data-masking en índice (`filter(comuna_chr == comuna)` → `.env$comuna_nom`).
5. Insumo `20_insumos/comunas.geojson` (límites comunales) usado para contornos y carga.
