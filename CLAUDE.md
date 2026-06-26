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
- Numeración oficial N→S **estricta por latitud** (más al norte = 1, más al sur = 97;
  el tipo NO influye en el orden, solo en el color), 1..97, compartida por mapa, inset e
  índice. Rangos por comuna 1-20/21-30/31-37/38-97. Verificada con `stopifnot` + panel adversarial.
- Los PNG de paneles del afiche se regeneran y van incrustados (base64) en el HTML; el
  HTML final SÍ se versiona, los PNG y `*.rds` no.

## Últimos cambios (más recientes primero)
1. **Etiquetas de comuna como texto HTML** (v9): las 4 etiquetas (`ETIQUETAS_COMUNA`) salieron
   del PNG (`geom_text`) y se posicionan como texto HTML `position:absolute` sobre cada panel
   (`etiquetas_pct` lon/lat→% vía bbox 3857; `etiquetas_html`), `LABEL_COMUNA_PX`. Ahora son
   editables/reposicionables en Affinity (verificado: texto extraíble en el PDF). Pines,
   números, límites siguen en el PNG.
2. **Exportación a PDF A0 vertical** (v8): `@page` 841×1189 mm + `zoom` (texto vectorial),
   PNG de mapas a `DPI_A0`=200 (`ESC` derivado; `PIN_RADIO_PX`/`PIN_GAP_PX` escalan con ESC).
   `chrome_print` → PDF, fuentes incrustadas (pdftools: pagesize A0, gobCL+MuseoSans embedded).
   PDF (~3 MB) gitignored; HTML versionado.
2. **Tile sin rótulos + etiquetas de comuna propias** (v7): `CartoDB.PositronNoLabels`; 4
   etiquetas azul gobCL (`ETIQUETAS_COMUNA`, `COLOR_COMUNA`); zonas de exclusión eliminadas.
3. **Numeración N→S estricta + nota + índice a alto completo** (v6): 1-97 por latitud pura.
4. **Pines grandes + anti-colisión 2D garantizada** (v4); **límites BCN** (v3); índice con RBD.
5. `.gitignore`: ignora `comunas_bcn/` (shp crudo), `panel_*.png`, `scratchpad_afiche/`.
