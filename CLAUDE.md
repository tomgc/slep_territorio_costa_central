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
1. **Mapa web — hito 4: exportación SVG + XLSX** (`docs/assets/mapa.js`): SVG vectorial de la
   vista vigente (pins plenos/atenuados, fronteras CC y regional, rótulos, leyenda por vista,
   título con filtro y N, atribución; tiles raster NO incrustados y declarado en el pie);
   XLSX con SheetJS 0.20.3 LOCAL (`docs/assets/vendor/xlsx.full.min.js`, carga diferida),
   filas = filtrados incluyendo sin-geo alcanzados, celdas numéricas nativas (locale lo
   resuelve Excel/Numbers), literales tal cual JSON, hoja `Notas` con criterios. Nombre de
   archivo = filtro aplicado o fecha. Botones en panel (`iniciarExportacion`).
2. **Mapa web — hito 3: 7 filtros acumulativos** estilo faceta (opciones sobre el subconjunto
   que cumple los DEMÁS filtros); `match()` función pura del estado `F`.
3. **Etiquetas de comuna como texto HTML** (v9 afiche): editables en Affinity; pines,
   números y límites siguen en el PNG.
4. **Exportación a PDF A0 vertical** (v8 afiche): texto vectorial, fuentes incrustadas.
5. **Numeración N→S estricta** (v6); pines grandes + anti-colisión (v4); límites BCN (v3).
