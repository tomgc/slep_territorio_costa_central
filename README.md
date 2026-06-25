# slep_georreferenciacion

Afiche cartografico estatico (A0, imprimible en plotter) con los
establecimientos educacionales del **SLEP Costa Central** (comunas de
Puchuncaví, Quintero, Concón y Viña del Mar). Reproduce con fidelidad hi-fi el
handoff de diseno e inyecta los datos reales del maestro de establecimientos.

## Que hace
1. Lee y valida el maestro (`20_insumos/maestro_establecimientos.xlsx`).
2. Proyecta lat/long al lienzo del afiche (transformacion lineal, sin basemap real).
3. Genera el afiche HTML/SVG autocontenido (fuentes y logo embebidos) y, como
   paso manual, se exporta a PDF A0 con `pagedown::chrome_print()`.

Marcadores: **Viña del Mar** se muestra como pines numerados (racimo);
**Puchuncaví, Quintero y Concón** como tarjetas con numero + nombre completo +
(RBD). Los nombres completos viven ademas en la lista lateral.

## Como correr el pipeline
```r
# Desde la raiz del proyecto, en Positron:
source("00_run_all.R")
run_all()            # pipeline completo
run_all(only = 1)    # solo leer y validar
run_all(from = 2)    # desde la proyeccion
```

Exportar a PDF (paso manual, requiere Chrome instalado):
```r
pagedown::chrome_print(
  here::here("40_salidas", "afiche", "mapa_establecimientos.html"),
  output = here::here("40_salidas", "afiche", "mapa_establecimientos.pdf")
)
```

## De donde salen los datos
El maestro lo provee el equipo SLEP. RBD y nombre de establecimiento son
publicos y se muestran completos. No hay datos personales ni de NNA: el proyecto
usa **raiz unificada** (Rama A de la politica), con `20_insumos/` y `40_salidas/`
dentro del repo.

## Estructura
Sigue `POLITICA_PROYECTO.md` (knowledge base del Project): carpetas por decenas
segun flujo de ejecucion. El handoff de diseno (`design_handoff_mapa_establecimientos/`,
con `fonts/` y `assets/`) vive en la raiz como referencia de fidelidad y fuente
de las tipografias embebidas.

## Estado
Andamiaje inicial (sesion 1). El generador del afiche (`33_generar_afiche.R`)
tiene la arquitectura y los tokens fijados; la construccion del HTML final queda
para la proxima sesion. Ver `50_documentacion/traspasos/`.
