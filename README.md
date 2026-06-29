# slep_georreferenciacion

Afiche cartografico estatico (A0, imprimible en plotter) con los
establecimientos educacionales del **SLEP Costa Central** (comunas de
Puchuncaví, Quintero, Concón y Viña del Mar). Reproduce con fidelidad hi-fi el
handoff de diseno e inyecta los datos reales del maestro de establecimientos.

Existen dos variantes del afiche:

- **Con inset** (`mapa_establecimientos.{html,pdf}`): panel norte (Puchuncaví,
  Quintero, Concón) + inset de Viña del Mar a escala separada.
- **Escala única** (`mapa_establecimientos_escala_unica.{html,pdf}`): panel
  continuo que muestra las 4 comunas a la misma escala, sin inset.

Ambas variantes tienen 97 pins, numeración N→S 1..97, fuentes incrustadas y son
aptas para plotter (A0, PDF 1.7, texto extraíble).

## Que hace

1. Lee y valida el maestro (`20_insumos/maestro_establecimientos.xlsx`).
2. Proyecta las coordenadas al lienzo del afiche (transformacion lineal con
   tiles CARTO como basemap).
3. Genera el afiche HTML autocontenido (fuentes y logo embebidos).
4. Exporta a PDF A0 con `pagedown::chrome_print()`.

El handoff de diseno (`design_handoff_mapa_establecimientos/`) contiene las
tipografias (`fonts/`) y activos (`assets/`) embebidos en el HTML final.

## Como correr el pipeline

```r
# Desde la raiz del proyecto, en Positron:
source("00_run_all.R")
run_all()            # pipeline completo (variante con inset)
run_all(only = 1)    # solo leer y validar
run_all(from = 2)    # desde la proyeccion
```

**Variante con inset** — exportar a PDF (paso manual, requiere Chrome):

```r
pagedown::chrome_print(
  here::here("40_salidas", "afiche", "mapa_establecimientos.html"),
  output = here::here("40_salidas", "afiche", "mapa_establecimientos.pdf")
)
```

**Variante escala única** — correr directamente (no está cableada a `00_run_all`):

```r
source(here::here("30_procesamiento", "33b_generar_afiche_escala_unica.R"))
```

Para reutilizar el PNG renderizado sin regenerarlo (iteracion rapida de HTML/PDF):

```r
REUSAR_PNG=TRUE Rscript 30_procesamiento/33b_generar_afiche_escala_unica.R
# o bien, desde Positron, definir antes de hacer source():
Sys.setenv(REUSAR_PNG = "TRUE")
source(here::here("30_procesamiento", "33b_generar_afiche_escala_unica.R"))
```

Nota: si se regenera el PDF desde `33b`, las etiquetas de comuna vuelven a la
posicion calculada por el script (Viña del Mar bajo el cluster). El pulido
editorial al oceano debe rehacerse en Affinity Publisher sobre el PDF editable.

## Requisitos de entorno

- **Locale UTF-8 obligatorio.** El pipeline usa nombres de comunas con tildes
  y ñ. Un locale distinto provoca caidas silenciosas en `sf::st_intersection()`
  (las comunas no coinciden con ningun punto). Verificar antes de correr:

  ```r
  Sys.getlocale("LC_CTYPE")  # debe contener "UTF-8"
  ```

  En macOS/Linux, agregar a `~/.Renviron`: `LC_ALL=en_US.UTF-8`
  En Windows, usar R >= 4.2 (UTF-8 nativo) o `Sys.setlocale("LC_ALL", "en_US.UTF-8")`.

- **Chrome instalado** para `pagedown::chrome_print()`.
- **R >= 4.1** (pipe nativo `|>`).

## De donde salen los datos

### Maestro de establecimientos

Lo provee el equipo SLEP (`20_insumos/maestro_establecimientos.xlsx`). RBD y
nombre de establecimiento son publicos y se muestran completos. No hay datos
personales ni de NNA: el proyecto usa **raiz unificada** (Rama A de la
politica), con `20_insumos/` y `40_salidas/` dentro del repo.

### Datos geograficos de comunas

El pipeline usa `20_insumos/comunas.geojson` (versionado en el repo) como fuente
primaria de limites comunales. La carpeta `20_insumos/comunas_bcn/` contiene el
shapefile original de la **Biblioteca del Congreso Nacional (BCN)** en alta
resolucion; **no esta versionada en Git** (61 MB, binario). Si se necesita
regenerar el GeoJSON de respaldo, descargarlo desde:
<https://www.bcn.cl/siit/mapas_vectoriales> (capa "Comunas") y correr
`30_procesamiento/30_preparar_comunas.R`.

## Estructura

Sigue `POLITICA_PROYECTO.md` (knowledge base del Project): carpetas por decenas
segun flujo de ejecucion. Ver `50_documentacion/traspasos/` para el historial
de sesiones y `50_documentacion/activa/decisiones/` para las decisiones
arquitectonicas.

## Estado

Sesion 5 (2026-06-28). Ambas variantes completadas, auditadas y commiteadas.
Pendiente: validacion con el director. Ver `50_documentacion/traspasos/traspaso_cierre_v05.md`.
