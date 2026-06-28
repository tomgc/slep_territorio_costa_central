# LOG — Fase 1: variante escala única definitiva (33b)

- **Timestamp:** 2026-06-28
- **Producto:** segunda versión del afiche (adicional, no destructiva). 4 comunas en UN
  panel a escala única continua, Viña in situ puro, pin global a 60%, fuente al máximo.

## Paso 0 — API real de 33 confirmada (leída, no asumida)
| Lo que el encargo asume | Realidad en 33 | Resolución |
|---|---|---|
| `separar_pines`, `circulos`, `comuna_paths`, `get_carto_3857`, `fit_bbox_3857`, `bbox_a_3857`, `numerar`, `cargar_comunas`, `mindist`, `etiquetas_pct`, `etiquetas_html`, `construir_indice/leyenda`, `bloque_fontface`, `data_uri` | Existen con esas firmas | Reutilizadas vía `e$` |
| anti-colisión radio = `PIN_RADIO_PX` | `PIN_RADIO_PX <- 11*ESC` es GLOBAL; `dibujar_pines` lo toma del entorno y **aborta** con un GATE | Render propio `render_panel_unico` con radio=0.60·PIN_RADIO_PX, **sin** gate (a 60% no se dispara) |
| `generar_html` reutilizable | Es de **dos paneles** (norte+inset), firma `(est, etq_norte, etq_vina)` | `generar_html_unico` propio que reutiliza los sub-componentes (índice, leyenda, fontface, etiquetas, data_uri) con UN slot |
| fuente del número | `PIN_FONT <- 4.3` fijo (no max-fit) | `fit_font_size()` (métrica de glifo, ratio 0.72) como el sondeo |
| export PDF | inline en el flujo de 33 (no función) | replicado inline en 33b |
| constantes lienzo | `ESC, MAPA_W=728, ALTO_BODY=1520, NORTE_H=944, VINA_H=560, ZOOM, A0_*` | reutilizadas de `e$` |

## Parámetros de la variante
- `FRAC_RADIO=0.60` → radio = **35.2 px** PNG a producción (ESC=5.34); gap = `PIN_GAP_PX` (=2·ESC).
- `RATIO_GLIFO=0.72`; `fit_font_size` → `size` geom_text = **2.92** (max que cabe).
- `UNICO_H = ALTO_BODY = 1520` (panel único ocupa todo el body); bbox fit a aspect 728/1520.
- Tiles: `CartoDB.PositronNoLabels` zoom 12 (vía `get_carto_3857`).

## Mediciones del render real (sobre el PNG `panel_escala_unica.png`, 3888×8117)
- 97 pines. **min_dist = 81.2 px ≥ 70.4 (=2·radio)** → sin solape. **fuera_marco = 0.**
  desp_max = 72 px PNG (≈13.5 px lienzo ≈ 9 mm A0). `stopifnot` pasó.
- Numeración N→S 1..97 vía `numerar()` de 33, sin cambios (verificada por sus stopifnot).
- Etiquetas de comuna **recalculadas** para el bbox único (no copiadas):
  Puchuncaví(56.9%,32.5%) Quintero(26.4%,52.2%) Concón(28.0%,67.8%) Viña del Mar(9.4%,79.7%).

## PDF A0
- pagesize **2384 × 3370 pt = A0 exacto** (841×1189 mm). 2.6 MB.
- Texto extraíble: 8001 chars. Las 4 comunas presentes como **texto** (editable). "97" y
  "RBD" presentes. Fuentes incrustadas **7/7** (gobCL-Heavy, gobCL, MuseoSans-300/500,
  + fallback LucidaGrande embebido por Chrome).
- Índice lateral: **97 entradas "RBD nnn"** (una por establecimiento, sin truncar).

## Arquitectura y ubicación
- `30_procesamiento/33b_generar_afiche_escala_unica.R`. Sufijo **`33b_`**: marca variante de
  33 (no una etapa nueva del pipeline). **NO cableado a `00_run_all`** (orquestador 🔒):
  script ejecutable independiente, como `30_preparar_comunas.R`.
- `source(33, local=TRUE)` en `new.env()`: reutiliza sin editar ni ejecutar el flujo de 33.

## Salidas (nombre distinto; el original NO se sobrescribe)
- `40_salidas/afiche/mapa_establecimientos_escala_unica.html` (4.3 MB)
- `40_salidas/afiche/mapa_establecimientos_escala_unica.pdf` (2.6 MB)
- `40_salidas/afiche/panel_escala_unica.png` (intermedio)
- Las tres caen en el patrón gitignore de pesados → quedan en disco, no se versionan.
  Lo versionado es **33b** (el script).

## Auto-auditoría adversarial
- **¿33 byte-idéntico?** Sí. `git diff --stat` de 33/31/32/00_run_all = vacío. ✔
- **¿source(33) disparó su flujo?** No. El original `mapa_establecimientos.{html,pdf}`
  conserva mtime **11:15** (el render de 33b fue 10:57); no se regeneró. ✔
- **¿97 pines sin solape y dentro del marco?** Sí: min_dist 81.2 ≥ 70.4, fuera=0 (medido). ✔
- **¿"97" legible al tamaño A0?** Ratio glifo/diámetro 0.72 confirmado; radio 60% ≈ 4.48 mm,
  "97" ≈ 6.45 mm A0 (sondeo T2). ✔
- **¿Numeración N→S 1..97 intacta?** Sí, `numerar()` reutilizado, sus stopifnot pasan. ✔
- **¿PDF A0 exacto, texto extraíble, fuentes incrustadas, etiquetas editables?** Sí (todo
  arriba). ✔
- **¿Índice 97 número+nombre+RBD, 1 vez c/u, sin truncar?** Sí: 97 ocurrencias RBD. ✔

## Estado de git
```
git diff --stat 33/31/32/00_run_all -> vacío.  Original intacto (mtime 11:15).
Nuevo versionable: 30_procesamiento/33b_generar_afiche_escala_unica.R (+ este log).
Salidas pesadas gitignored (en disco).
```
