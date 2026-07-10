# Traspaso de cierre v05 — slep_georreferenciacion

## 1. Identificación
- **Proyecto:** slep_georreferenciacion (afiche cartográfico A0, SLEP Costa Central)
- **Versión:** v05
- **Fecha:** 2026-06-28
- **Sesión 5, foco:** (a) verificar estado del repo y productos tras la purga de v04;
  (b) ejecutar y auditar la Fase 1 de la variante escala única (33b); (c) corregir
  regresión de etiquetas de comuna (Viña del Mar tapaba el pin 56); (d) pulido editorial
  de posición de etiquetas en Affinity Publisher; (e) exportación PDF plotter-ready.
  Cierre con la **variante escala única completada, auditada y commiteada**. El producto
  con inset (variante original) permanece byte-idéntico.
- **Entorno:** Positron / R 4.5.2. Locale UTF-8 obligatorio. Git + GitHub privado.
  Affinity Publisher para pulido editorial final.
- **Tipo de sesión:** CONTINUATION.
- **Repo remoto:** `https://github.com/tomgc/slep_territorio_costa_central.git` (privado).
  HEAD local y remoto: `dac5dd1` al cierre.

## 2. Resumen ejecutivo
La sesión verificó el estado del repo (remoto consistente en `359c367` al abrirse;
`dac5dd1` al cierre), confirmó byte-idénticos los archivos 🔒 y el original
`mapa_establecimientos.{html,pdf}` con mtime Jun 26 11:15 (intacto). Se ejecutó y
auditó la Fase 1 de 33b (encargo que venía de v04): 97 pines, numeración N→S, sin solape,
PDF A0 exacto, fuentes 7/7, texto extraíble, índice 97 entradas. Se detectó una regresión
de posicionamiento (etiqueta "Viña del Mar" tapaba el pin 56 por ancla en centroide
geográfico del cluster denso) y se corrigió con la Opción 1: offset aditivo calibrado por
código en 33b (`OFFSET_ETIQUETAS_PCT`), moviendo Viña bajo el cluster (dy +9%). Se añadió
el switch `REUSAR_PNG` para regenerar solo HTML+PDF sin re-renderizar el mapa de pines.
El pulido de las 4 etiquetas al océano (al costado del cluster, posición más convencional)
se delegó a Affinity Publisher como capa editorial: el titular las reposicionó a mano sobre
el PDF editable y exportó el PDF plotter-ready con calidad 100% (6.67 MB estimado, 300 DPI,
PDF 1.7, fuentes incrustadas). La variante queda lista para validación con el director.

## 3. Estado al cierre
**Funciona / hecho:**
- Variante escala única `mapa_establecimientos_escala_unica.{html,pdf}` generada, auditada
  y en disco. Apta para plotter (A0, fuentes incrustadas, texto extraíble).
- `33b_generar_afiche_escala_unica.R` commiteado y pusheado (commit `b342abb`).
- Log del fix de etiquetas commiteado (`dac5dd1`). Repo remoto consistente.
- Producto original `mapa_establecimientos.{html,pdf}` byte-idéntico, mtime Jun 26 11:15.
- 4 etiquetas de comuna reposicionadas al océano por el titular en Affinity; PDF exportado
  con "PDF (for print)", 300 DPI, calidad JPEG 100, fuentes incrustadas.
- Invariante 🔒 confirmada: 33/31/32/00_run_all git diff --stat vacío en el repo real.

**Pendientes heredados (sin cambios):**
- Validación in situ del original en Affinity: confirmar etiquetas editables, fuentes gobCL
  no sustituidas, posición de Concón (top 98.84%) y Puchuncaví. Tarea del titular.
- Cablear 30_preparar_comunas.R y 33b a 00_run_all (opcional; orquestador 🔒).
- Borrar backup espejo `../slep_repo_backup_20260628.git` cuando el titular valide el
  remoto. Tarea del titular.
- Constantes muertas: verificar `BUFFER_VISUAL_DEG` en 33 (anotado como posiblemente muerta).
- Documentar locale UTF-8 en README.
- Documentar en README que comunas_bcn/ es re-descargable de BCN (no versionado).

**Delta respecto a v04:**
- v04 cerró con 33b encargado pero no construido. v05 añade: 33b construido, auditado,
  fix de etiquetas (OFFSET + REUSAR_PNG), pulido editorial en Affinity, PDF plotter-ready
  de la variante.

## 4. Registro detallado de cambios (sesión 5)

### Verificación de estado post-purga
- `git diff --stat` corrido desde `~` → falló (no era el repo). Corregido: cd al proyecto
  antes del comando. Lección operacional registrada.
- Invariantes confirmadas desde la raíz correcta: diff vacío, original con mtime Jun 26 11:15.

### Fase 1 — Construcción de 33b (encargo de v04)
- Claude Code leyó `33_generar_afiche.R`, confirmó API real (ver tabla de divergencias en
  log `20260628_fase1_escala_unica_33b_log.md`) y construyó `33b_generar_afiche_escala_unica.R`.
- Divergencias resueltas según el código real: `generar_html` era de dos paneles →
  `generar_html_unico` propio; `dibujar_pines` tenía GATE → render propio sin gate;
  export PDF era inline → replicado.
- Mediciones reales: 97 pines, radio 35.2px, min_dist 81.2 ≥ 70.4, fuera=0, PDF A0
  2384×3370 pt, fuentes 7/7, 97 entradas RBD en índice. Commit `f26b791` (local en ese
  momento; luego sustituido por la rama con el fix de etiquetas).

### Fix regresión etiquetas de comuna (Opción 1: offset calibrado)
- **Causa raíz:** `e$etiquetas_pct` ancla las etiquetas al centroide geográfico de cada
  comuna. En el panel único, el centroide de Viña cae sobre el cluster denso (pines 55–97),
  y la tarjeta blanca HTML tapaba el pin 56.
- **Solución:** constante aditiva `OFFSET_ETIQUETAS_PCT` en 33b (no toca 33). Solo Viña
  necesitaba moverse (clearance base −6.6px; las otras tres: +26, +58, +13 → ya despejadas).
- **Hallazgos honestos de Claude Code:** (a) Puchuncaví NW hacia la costa: bloqueado por su
  propio pin 7 (colisión −6.6px); se dejó en base (ya despejada). (b) Viña SW puro: rótulo
  mide 14% del ancho del panel, más que la franja de océano → no cabía. Se bajó bajo el
  cluster (dy +9%).
- **Switch REUSAR_PNG** añadido: recalcula geometría (b3/etq) y reutiliza el PNG existente
  sin re-renderizar. El PNG no se regeneró (mtime 10:57:41 antes y después).
- Commits: `b342abb` (33b con fix) + `dac5dd1` (log), ambos pusheados.

### Pulido editorial en Affinity Publisher
- Las 4 etiquetas al océano (destino solicitado por el titular con flechas) son posición
  editorial no reproducible por código (la geometría de pines bloquea el ocean placement
  automático). Se delegó a Affinity Publisher como capa editorial final.
- Titular reposicionó las 4 etiquetas a mano sobre el PDF editable (texto + fuentes
  incrustadas; vectorial, no raster).
- Exportación: "PDF (for print)", Raster DPI 300, JPEG quality 100, PDF 1.7, fuentes
  incrustadas, sin sangrado (plóter institucional corta a A0 exacto).
- Configuración validada por el asistente; resultado aceptado por el titular.

## 5. Backlog acumulativo

### Objetivo del proyecto
Afiche cartográfico plotter-ready A0 (841×1189 mm) que georreferencia los 97 establecimientos
educacionales del SLEP Costa Central en 4 comunas costeras (Puchuncaví, Quintero, Concón,
Viña del Mar). Dos variantes: (a) con inset de Viña (original, completada en sesiones 1-3);
(b) escala única continua (completada en sesión 5). Entregable institucional para el director.
Pipeline en R vía `ggplot2`/`sf`/`pagedown`; pulido en Affinity Publisher.

### Nota metodológica
Un "cambio" es una solicitud distinguible del titular, no las acciones técnicas que la
implementan. Los errores del asistente corregidos de inmediato no cuentan; los bugfixes
reportados por el titular sí. Clasificación por intención primaria.

### Clasificación temática
| Categoría | N° aprox. | Descripción |
|---|---|---|
| Renderizado / layout del mapa | ~30% | Pines, radio, anti-colisión, panel único vs inset |
| Exportación / formato | ~15% | PDF A0, fuentes incrustadas, chrome_print |
| Etiquetas y texto HTML | ~15% | Etiquetas de comuna, índice, leyenda, editabilidad |
| Numeración y datos | ~10% | N→S 1..97, colores por tipo, índice RBD |
| Gobernanza / repo | ~15% | GitHub, gitignore, purga, backup |
| Exploración / sondeos | ~10% | Variantes A/C/D/E, T1/T2/T3, decisiones de diseño |
| Documentación / deuda | ~5% | README, constantes muertas, locale |

### Resumen estadístico por sesión
| Sesión | Traspaso | Foco |
|---|---|---|
| 1 | v01 | Datos, pipeline base, primer render |
| 2 | v02 | Refinamiento visual, numeración N→S, PDF A0 |
| 3 | v03 | Etiquetas HTML editables, fuentes, producto final con inset |
| 4 | v04 | GitHub, reorganización, purga historial, diseño variante |
| 5 | v05 | Construcción y auditoría variante escala única, fix etiquetas, pulido Affinity |

### Detalle cronológico (sesión 5)
**S5-01** Verificación de repo y productos post-purga (desde el directorio correcto).
**S5-02** Construcción y ejecución de `33b_generar_afiche_escala_unica.R` (Fase 1 del encargo
de v04): panel único, Viña in situ, radio 60%, fuente al máximo (ratio 0.72).
**S5-03** Auditoría independiente de 33b: 97 pines, numeración, no-solape, PDF A0, fuentes,
índice. Identificación de la regresión de etiquetas (Viña sobre pin 56).
**S5-04** Fix de regresión: `OFFSET_ETIQUETAS_PCT` en 33b + switch `REUSAR_PNG`. Calibración
por código (cajas de texto vs círculos de pin). Solo Viña movida (dy +9%).
**S5-05** Decisión de diseño: posición final de Viña "bajo el cluster" aceptada como base
reproducible; pulido de las 4 al océano delegado a Affinity (capa editorial, no pipeline).
**S5-06** Pulido editorial en Affinity: titular reposicionó las 4 etiquetas al océano.
**S5-07** Exportación PDF plotter-ready con configuración validada (300 DPI, calidad 100,
fuentes incrustadas, sin sangrado).
**S5-08** Commit y push de 33b (fix + log), dos commits separados (política 9.7).

## 6. Bugs de la sesión
- **Bug S5-01 — `git diff` desde directorio incorrecto.** Síntoma: "Not a git repository".
  Causa raíz: el comando se corrió desde `~` en vez de la raíz del proyecto. Solución: `cd
  ~/Projects/slep_georreferenciacion` antes del diff. Regla: siempre especificar la ruta
  completa desde la raíz del proyecto, o anteponer `cd <raíz> &&`.
- **Bug S5-02 — Regresión de etiquetas (Viña sobre pines).** Síntoma: tarjeta blanca
  "Viña del Mar" pisaba el pin 56 en la variante escala única. Causa raíz: `e$etiquetas_pct`
  ancla al centroide geográfico; en el panel único ese centroide cae sobre el cluster denso.
  El problema no ocurría en el producto con inset porque Viña tenía su propio panel ampliado.
  Solución: `OFFSET_ETIQUETAS_PCT` aditivo en 33b. Regla: al cambiar de layout (dos paneles
  → uno), las posiciones de etiquetas derivadas de centroides geográficos deben re-verificarse
  contra la distribución real de pines en el nuevo espacio.

## 7. Aprendizajes y restricciones descubiertas
- **El centroide geográfico no es la posición óptima de etiqueta cuando el cluster es denso.**
  En el panel único, anclar al centroide de Viña = aterrizar en el medio de 60 pines. Para
  futuros layouts, calcular la posición de etiqueta como el punto más cercano al centroide
  que esté libre de pines (no como el centroide mismo).
- **El ancho del rótulo impone un mínimo de franja libre.** "Viña del Mar" mide 14% del ancho
  del panel; la franja de océano al poniente del cluster es más angosta. Mover la etiqueta al
  océano SW requiere o bien achicar el rótulo o aceptar que se salga del agua. Para el pulido
  editorial en Affinity el usuario puede hacer esto a ojo; el código no puede calibrarlo sin
  iterar renders.
- **`REUSAR_PNG` es un patrón útil:** separar "recalcular geometría" de "re-renderizar el
  mapa de pines" acelera el ciclo de iteración de Chrome/HTML sin re-fetchear tiles.
- **Hereda de v04:** todo lo listado en §7 del traspaso v04.

## 8. Decisiones de diseño
- **Opción 1 (offset en código) para Viña, Opción 2 (Affinity) para el resto:** el offset
  de Viña elimina la colisión de forma reproducible (punto de partida limpio para el PDF
  editable); el reposicionamiento al océano de las 4 etiquetas es editorial, asimetría
  consciente entre lo que el pipeline puede garantizar y lo que es pulido de diseño.
- **Viña "bajo el cluster" como posición base en 33b:** geográficamente inusual (el rótulo
  queda al sur de los pines que nombra), pero sin colisión y reproducible. Si se regenera
  el PDF desde el script, el rótulo aparece ahí; el titular puede volver a moverlo en
  Affinity. Alternativa descartada: dejar en centroide (colisión) o intentar ocean placement
  automático (el ancho no cabía).
- **Pulido editorial en Affinity, no en pipeline:** las 4 etiquetas al océano requieren
  criterio visual y no son reproducibles por código sin riesgo de chocar con el ancho del
  rótulo. La separación pipeline/editorial es explícita y consciente.
- **Hereda de v04:** Rama A (datos públicos), solo texto al repo, purga de historial, A+T2.

## 9. Constantes y parámetros vigentes
| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| PIN_RADIO_PX (producción) | 11·ESC = 58.74 px PNG | 33 | original con inset |
| FRAC_RADIO (variante) | 0.60 | 33b | decisión T2 |
| PIN_RADIO variante | 35.2 px PNG | 33b (calculado) | 0.60 × 58.74 |
| ESC | 5.3404 | 33 | 200·841/(25.4·1240) |
| RATIO_GLIFO | 0.72 | 33b | fuente al máximo |
| fit_font_size resultado | 2.92 (geom_text size) | 33b | max que cabe en el disco |
| UNICO_H | = ALTO_BODY = 1520 | 33b | panel único ocupa todo el body |
| ZOOM_TILE | 12L | 33b | tiles CARTO para panel único |
| OFFSET_ETIQUETAS_PCT | Puch/Quint/Conc: (0,0); Viña: (−1.5, +9.0) | 33b | offset aditivo sobre etiquetas_pct |
| Posición final Viña (left%, top%) | (7.9, 88.7) | 33b | bajo el cluster; pulido al océano en Affinity |
| Numeración | N→S 1..97 por latitud | 33 (numerar()) | 🔒 oficial |
| Colores tipo | jardín #6a8a3a, escuela #2d5f8a, liceo #c8732e, especial #7a4a8a, adultos #555 | 33 | |
| Azul institucional comuna | #0F69B4 | 33 | etiquetas HTML |

## 10. Arquitectura de archivos
- Escáner al cierre: `50_documentacion/estructura/20260628_104224_estructura.{md,txt}` (el
  escáner no se re-corrió en esta sesión; sigue siendo el de post-purga de v04, que es el
  estado correcto — 33b y el log del fix fueron los únicos archivos nuevos versionados).
- Cambios estructurales v05: `30_procesamiento/33b_generar_afiche_escala_unica.R` añadido;
  `50_documentacion/andamios/logs/20260628_fix_etiquetas_33b_log.md` añadido. Sin otros
  cambios estructurales.
- HEAD remoto al cierre: `dac5dd1`.

## 11. Pendientes y ruta sugerida

### Inventario de pendientes
1. **Validación con el director** (bloqueante para publicar). El titular presentará las dos
   variantes. Hasta ese momento el proyecto está en espera de aprobación externa.
   Complejidad: Baja (no requiere código). Criterio de éxito: aprobación del director.
2. **Validación in situ en Affinity del original** (heredado v03/v04 #2): confirmar etiquetas
   editables, fuentes gobCL instaladas (desde `design_handoff_mapa_establecimientos/fonts/`),
   posición de Concón (top 98.84%, riesgo de recorte), Puchuncaví (landed inland east en el
   original). Tarea del titular; no requiere código.
3. **Borrar backup espejo** `../slep_repo_backup_20260628.git` cuando el titular valide el
   remoto. Tarea del titular (una línea: `rm -rf ../slep_repo_backup_20260628.git`).
4. **Constantes muertas:** verificar si `BUFFER_VISUAL_DEG` sigue en 33 (anotado como
   posiblemente muerta en v03). Deuda menor. Complejidad: Baja.
5. **Documentar locale UTF-8 en README** (heredado v03/v04). Deuda menor.
6. **Documentar en README** que `comunas_bcn/` es re-descargable de BCN (no versionado tras
   la purga; el pipeline normal usa `comunas.geojson` versionado). Deuda menor.
7. **Cablear 30_preparar_comunas.R y 33b a 00_run_all** (opcional; orquestador 🔒). Requiere
   decisión explícita del titular.
8. **Re-correr el escáner y commitear el snapshot actualizado.** El escáner sigue mostrando
   el estado post-purga (v04); el snapshot no incluye 33b ni el log del fix. Deuda menor.

### Auditoría de cierre (política 5.6, preguntas "Cierre")
- ¿Pipeline corre de cero sin intervención manual? **Parcial:** 30_preparar_comunas.R y 33b
  no están en 00_run_all; comunas_bcn no viaja al repo. Deuda documentada (pendiente #7).
- ¿Outputs reproducibles e idempotentes? Sí para ambas variantes desde el script; el pulido
  editorial de etiquetas en Affinity no es reproducible por diseño (capa editorial explícita).
- ¿Decisiones metodológicas como constantes nombradas? Sí (FRAC_RADIO, RATIO_GLIFO,
  OFFSET_ETIQUETAS_PCT).
- ¿Nombres sin tildes/ñ/espacios? Sí, salvo `Prototipo Mapa Establecimientos.dc.html`
  (handoff externo, excepción declarada).

### Ruta sugerida próxima sesión
Depende del resultado de la validación con el director:
- **Si aprueba:** cierre de deudas menores (#4, #5, #6, #8), potencialmente cablear a
  00_run_all (#7).
- **Si pide cambios:** nueva iteración de diseño según feedback; prioridad sobre las deudas.

## 12. Instrucciones específicas para la próxima sesión
- 🔒 `33_generar_afiche.R`, `31`, `32`, `00_run_all`, `10_*`, maestro: byte-idénticos.
  NO tocar sin instrucción explícita.
- 🔒 Producto original `mapa_establecimientos.{html,pdf}`: NO regenerar ni sobrescribir.
- 🔒 Numeración N→S 1..97 y colores por tipo: invariantes.
- 🔒 No filtrar puntos por contención (RBD 1699, 33476 son falsos positivos válidos).
- ✅ ANTES de cualquier cambio a 33b, leerlo completo (el archivo actual tiene OFFSET y
  REUSAR_PNG que deben preservarse o modificarse conscientemente).
- ✅ Si se regenera el PDF desde 33b, las etiquetas vuelven a la posición del script (Viña
  bajo el cluster); el pulido al océano debe rehacerse en Affinity. Documentarlo en el
  encargo si aplica.
- ⚠️ NO cablear 30_preparar_comunas.R ni 33b a 00_run_all sin decisión explícita del titular.
- ⚠️ NO versionar pesados (PNG/PDF/afpub/shp): solo texto al repo.
- ⚠️ El escáner está desactualizado (no incluye 33b ni el log del fix). Re-correrlo antes de
  tomar decisiones de estructura.

## 13. Fragmentos de código de referencia

```r
# Patrón source seguro (reusar funciones de 33 sin disparar su flujo):
e <- new.env()
source(here::here("30_procesamiento", "33_generar_afiche.R"), local = e)
# local=TRUE (vía env) → identical(environment(), globalenv()) == FALSE → guard de 33 NO corre.

# OFFSET_ETIQUETAS_PCT (capa aditiva sobre e$etiquetas_pct; solo Viña mueve):
OFFSET_ETIQUETAS_PCT <- list(
  "Puchuncaví"   = c(dx =  0.0, dy =  0.0),
  "Quintero"     = c(dx =  0.0, dy =  0.0),
  "Concón"       = c(dx =  0.0, dy =  0.0),
  "Viña del Mar" = c(dx = -1.5, dy =  9.0)
)
# Aplicar tras etiquetas_pct, con clamp a [2, 95]:
etq <- e$etiquetas_pct(e$ETIQUETAS_COMUNA, ru$b3)
for (nm in names(OFFSET_ETIQUETAS_PCT)) {
  idx <- which(etq$nom == nm)
  if (length(idx) == 1L) {
    etq$left[idx] <- max(2, min(95, etq$left[idx] + OFFSET_ETIQUETAS_PCT[[nm]]["dx"]))
    etq$top[idx]  <- max(2, min(95, etq$top[idx]  + OFFSET_ETIQUETAS_PCT[[nm]]["dy"]))
  }
}

# REUSAR_PNG (evitar re-render del mapa de pines al iterar HTML/PDF):
REUSAR_PNG <- as.logical(Sys.getenv("REUSAR_PNG", "FALSE"))
# En render_panel_unico: if (!REUSAR_PNG) { ... renderizar ... } else { ... solo geometría ... }
```

## 14. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 6 (Claude Sonnet 4.6)`

**Mensaje de apertura pre-armado:**
> Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md y SETTINGS_Y_PROMPTS_OPERACIONALES.md)
> vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso v05 y el
> escáner actualizado. Foco: [según resultado de la validación con el director].

**Documentos para la próxima sesión:**
1. *Protocolo (en knowledge base, NO adjuntar):* `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco:* `CLAUDE.md` (si corre en Claude Code); `33b_generar_afiche_escala_unica.R`
   si hay cambios a la variante; `33_generar_afiche.R` si hay cambios al original.
3. *Específicos (SÍ adjuntar):* `traspaso_cierre_v05.md`; `estructura_actual.md` (re-correr
   el escáner antes de adjuntar, el actual está desactualizado).

**Nota final:** el escáner debe re-correrse antes de abrir la próxima sesión (pendiente #8).
Si el director pide cambios, adjuntar también los archivos afectados por su feedback.
