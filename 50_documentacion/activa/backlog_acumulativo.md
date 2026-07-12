# backlog_acumulativo.md — slep_georreferenciacion

> **Archivo canónico** del backlog acumulativo del proyecto
> (POLITICA_PROYECTO.md §10; SETTINGS_Y_PROMPTS_OPERACIONALES.md §2.2.5).
> Ubicación canónica: `50_documentacion/activa/backlog_acumulativo.md`.
> Creado en la sesión 7 (2026-07-12), reconstruido desde los traspasos v01–v06.
> Registro histórico vivo: en cada cierre se copia íntegro y se agregan las
> entradas nuevas al final. Jamás se reescriben, resumen ni renumeran las
> entradas anteriores; un error se corrige con una entrada nueva.

---

## 1. Objetivo del proyecto

Producir productos cartográficos y de visualización de datos para el **SLEP Costa
Central** (Servicio Local de Educación Pública que cubre Puchuncaví, Quintero,
Concón y Viña del Mar, Región de Valparaíso). El proyecto nació en junio de 2026
como un afiche cartográfico estático imprimible en plóter (A0, 841×1189 mm) que
georreferencia los 97 establecimientos educacionales del territorio del SLEP, y
creció hasta abarcar tres productos:

- **Variante 1 (afiche con inset):** panel norte (Puchuncaví, Quintero, Concón)
  más inset de Viña del Mar a escala separada. Completada en las sesiones 1–3.
- **Variante 2 (afiche a escala única):** panel continuo con las 4 comunas a la
  misma escala, sin inset, con los pines colocados in situ. Completada en la
  sesión 5.
- **Variante 3 (mapa interactivo regional):** mapa web Leaflet publicado en
  GitHub Pages, con el universo continental completo de la Región de Valparaíso
  (1.268 establecimientos educacionales), indicadores de matrícula 2016–2025,
  siete filtros acumulativos y exportación a SVG y XLSX. Construida en la
  sesión 6.

El pipeline está íntegramente en R (`ggplot2`, `sf`, `pagedown`, `jsonlite`);
el pulido editorial de los afiches se hace en Affinity Publisher como capa
explícitamente separada del código; el front-end del mapa interactivo es
HTML/CSS/JS autocontenido. La audiencia es institucional: el director del SLEP
Costa Central y, para el mapa web, el público general y el equipo experto.
El proyecto es de raíz unificada (Rama A de la política): los datos que versiona
son públicos (directorio oficial MINEDUC); los crudos con identificador
individual (MRUN) y los binarios pesados no entran al repositorio.

---

## 2. Nota metodológica

Un **"cambio"** es una solicitud distinguible del titular, no las acciones
técnicas que la implementan: si el titular pide "que los pines sean más chicos"
y eso implica tocar tres funciones y re-renderizar, es **un** cambio, no tres.

**No cuentan** como cambio los errores del asistente corregidos de inmediato
dentro del mismo turno (esos viven en la tabla de errores del asistente de cada
traspaso, §2.2.15). **Sí cuentan** los bugfixes reportados por el titular y los
bugs de código detectados por auditoría que exigieron una corrección real.

La clasificación es por **intención primaria**: un cambio que toca el render pero
cuya intención es corregir un dato se clasifica en la categoría del dato.

**Fuentes del conteo:** los traspasos `traspaso_cierre_v01.md` a
`traspaso_cierre_v06.md` y los siguientes.

### 2.1 Discontinuidad histórica de la numeración (declaración obligatoria)

Este archivo se crea en la sesión 7, en el séptimo cierre del proyecto, no en el
segundo como manda el protocolo. La reconstrucción retroactiva encontró un hecho
que se declara aquí en vez de disimularlo:

- **Sesiones 1 y 2 (v01, v02):** mantuvieron la taxonomía formal del protocolo,
  con **numeración correlativa global** (cambios 1 a 19). Esas entradas se
  transcriben literalmente en el detalle cronológico de abajo.
- **Sesión 3 (v03):** abandonó la taxonomía formal del backlog. El traspaso
  registra el trabajo por **encargo a Claude Code** (v1 a v9), no por cambio
  numerado.
- **Sesión 4 (v04):** declaró explícitamente la brecha
  (*"la taxonomía formal de backlog del protocolo 2.2.5 no se mantuvo
  explícitamente en v01-v03; se recomienda formalizarla si el proyecto continúa,
  pero NO se inventa retroactivamente aquí — B.1"*) y registró los cambios
  agrupados por categoría, sin numerar.
- **Sesión 5 (v05):** reintrodujo una clasificación temática, pero con
  **porcentajes aproximados y sin numeración correlativa**, incompatible con la
  serie 1–19 de v02.
- **Sesión 6 (v06):** no incluyó sección de backlog.

**Decisión de la sesión 7 (opción B):** no se renumera retroactivamente el
trabajo de las sesiones 3 a 6. Fabricar los cortes entre "cambios" de sesiones
que nunca los registraron con ese criterio significaría inventar una granularidad
que no existió, violando B.1 (sin supuestos implícitos), tal como v04 ya lo había
razonado correctamente. En su lugar:

1. La **serie histórica 1–19** se conserva íntegra y literal (sesiones 1–2).
2. Las **sesiones 3 a 6** se registran con la granularidad que cada traspaso sí
   documentó (por encargo, por operación, por decisión), **sin numeración
   correlativa**, marcadas con el prefijo de sesión.
3. La **numeración correlativa se reanuda como serie nueva desde la sesión 7**,
   partiendo en el número 20. La discontinuidad entre el cambio 19 (sesión 2) y
   el cambio 20 (sesión 7) es un hecho histórico del proyecto, documentado aquí,
   no un error de conteo.

---

## 3. Clasificación temática

Taxonomía orgánica del proyecto, consolidada en la sesión 7 a partir de las
propuestas parciales de v01, v02 y v05. Categorías mutuamente excluyentes por
intención primaria.

| Categoría | Descripción | Ejemplos concretos del proyecto |
|---|---|---|
| **Infraestructura y scaffolding** | Estructura canónica, utils, configuración, orquestador, escáner | Init Rama A; `10_utils.R`; `00_run_all.R` con `from/to/only/skip`; escáner con poda de retención 2 |
| **Capa de datos y validación** | Lectura, validación, tipado, integridad del maestro y del directorio | RBD forzado a `character`; validación de NAs y duplicados; gates compuestos de universo SLEP |
| **Arquitectura de datos geográficos** | Fuentes de límites comunales, proyecciones, CRS | Descarte de `chilemapas`; GeoJSON fcortes; shapefile BCN alta resolución; reproyección UTM 19S |
| **Renderizado y layout del mapa** | Colocación de marcadores, anti-colisión, escala, encuadre, tamaño de pin | Las ~7 variantes de anti-colisión de la sesión 2; `separar_pines`; radio al 60% (T2); panel único vs. inset |
| **Etiquetas y texto editable** | Etiquetas de comuna, índice lateral, leyenda, distinción raster/vector | Etiquetas de comuna a texto HTML (v9); `OFFSET_ETIQUETAS_PCT`; índice con número+nombre+RBD |
| **Exportación y formato de salida** | PDF A0, fuentes incrustadas, `chrome_print`, exportación SVG/XLSX | PDF A0 con texto extraíble; fuentes gobCL/MuseoSans incrustadas; exportación XLSX en locale español |
| **Front-end web (mapa interactivo)** | Leaflet, filtros, tarjetas, interacción, paleta | Siete filtros acumulativos con opciones dependientes; sparkline; hover con síntesis de enseñanza |
| **Reglas de negocio y decisiones de alcance** | Universo, recodificaciones, exclusiones, definiciones metodológicas | Exclusión de territorio insular; recodificación SLEP vigente 2026; tratamiento de EE sin matrícula |
| **Gobernanza y versionado** | GitHub, `.gitignore`, purga de historial, sensibilidad de datos | Migración a repo privado; purga con `filter-repo` (103 MB → 1 MB); sellado de crudos con MRUN |
| **Reorganización estructural** | Movimientos de carpetas, rescate de scripts, conformidad con la política | `scratchpad_afiche/` → `40_salidas/exploraciones/`; rescate de `30_preparar_comunas.R` |
| **Exploración y sondeos visuales** | Renders comparativos previos a una decisión de diseño | Sondeos A/C, D/E, T1/T2/T3 de la variante escala única; tres opciones de densidad de la sesión 1 |
| **Bugfix** | Corrección de defectos de código reportados o detectados por auditoría | `id` de PASOS a integer; mismatch de encoding en `COMUNAS_ORDEN`; `NULL` → `{}` en el JSON de JS |
| **Documentación y deuda** | README, decisiones, traspasos, backlog, constantes muertas | Nota de locale UTF-8; documentación de `comunas_bcn`; este archivo |

**Nota sobre porcentajes:** el protocolo pide una columna de N° y %. Dado el corte
declarado en §2.1, un porcentaje sobre el total sería engañoso (mezclaría entradas
numeradas con entradas sin numerar). Se omite deliberadamente hasta que la serie
nueva (desde el cambio 20) acumule suficientes entradas para que el porcentaje sea
una afirmación verificable y no una estimación.

---

## 4. Resumen estadístico por sesión

| Sesión | Traspaso | Cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 | 10 (1–10) | Opus 4.8 | Init Rama A; decisión de densidad de marcadores; bugfix de tipado |
| 2 | v02 | 9 (11–19) | Opus 4.8 | Construcción del afiche (rechazada); rediseño a mapa real georreferenciado |
| 3 | v03 | s/n (8 encargos) | Opus 4.8 | Paradigma visual resuelto; afiche terminado y auditado |
| 4 | v04 | s/n (4 operaciones) | Opus 4.8 | Migración a GitHub; purga de historial; diseño de la variante escala única |
| 5 | v05 | s/n (3 bloques) | Opus 4.8 | Construcción y auditoría de la variante escala única; pulido en Affinity |
| 6 | v06 | s/n (9 bloques) | Fable | Variante 3 completa: pipeline 34→35→36 y mapa interactivo publicado |
| 7 | v07 | (en curso) | Fable | Cierre de deuda de gobernanza y documental |

`s/n` = sin numeración correlativa, por la discontinuidad declarada en §2.1.

---

## 5. Detalle cronológico

### Sesión 1 (2026-06-25) — cambios 1 a 10

Transcripción literal de la serie numerada de `traspaso_cierre_v01.md`.

1. **Inicialización Rama A:** árbol canónico con `20_insumos/` y `40_salidas/`
   dentro del repo, tras confirmar que el maestro no contiene datos personales ni
   de NNA. *(Infraestructura)*
2. **`10_utils.R`:** `instalar_si_falta()` y `log_msg()` sin dependencias
   externas (bootstrapping). *(Infraestructura)*
3. **`10_configuracion.R`:** rutas vía `here::here()`; `MAPEO_TIPO` (Excel→key);
   `TIPOS` (orden de leyenda de menor a mayor edad); `TOKENS` hi-fi del handoff;
   `LIENZO` con margen de proyección; helpers `ruta_insumos`/`ruta_salidas`.
   *(Infraestructura)*
4. **`31_leer_validar.R`:** lectura con `clean_names()`, RBD como `character`,
   validación (NAs, tipos, bounding box, duplicados), numeración norte→sur,
   escritura atómica a `.rds`. *(Capa de datos)*
5. **`32_proyectar_lienzo.R`:** transformación lineal lon/lat → x/y% con bounding
   box fijo; marcador pin (Viña) / tarjeta (resto). *(Renderizado)*
6. **`33_generar_afiche.R`:** stub con la arquitectura lista (`data_uri`,
   `bloque_fontface`, `separar_tarjetas` anti-colisión, `svg_costa`);
   `generar_afiche()` pendiente. *(Renderizado)*
7. **`00_run_all.R`:** orquestador según la política §4. *(Infraestructura)*
8. **`00_escanear_proyecto.R`:** escáner con retención 2 atómica.
   *(Infraestructura)*
9. **Decisión de densidad de marcadores documentada:**
   `20260625_decision_densidad_marcadores.md`. Con 60 de 97 establecimientos en
   Viña del Mar, el esquema del handoff de muestra no escala. Se renderizaron tres
   opciones a tamaño real y el titular eligió la opción C: Viña con pines
   numerados; las otras tres comunas con tarjeta de número + nombre + (RBD).
   *(Exploración y sondeos)*
10. **Bugfix:** `id` de `PASOS` a integer (`1L`) en `00_run_all.R`. `run_all(to = 2)`
    abortaba en `vapply(..., integer(1))` porque los literales numéricos de R son
    `double`. *(Bugfix)*

### Sesión 2 (2026-06-25) — cambios 11 a 19

Transcripción literal de la serie numerada de `traspaso_cierre_v02.md`.

11. **`33` fiel al handoff** (tarjetas sobre el punto, apertura izquierda/derecha
    por x, Viña en pines). Render: solapes masivos (94 pares tarjeta-tarjeta).
    *(Renderizado)*
12. **Anti-colisión vertical + clamp al marco.** Reduce el desborde pero no el
    solape horizontal. *(Renderizado)*
13. **Anti-colisión por banda de comuna** (separadores SVG y=27/52/76). Incluye el
    fix del bug de encoding: `COMUNAS_ORDEN` (Latin-1) vs. factor del `.rds`
    (UTF-8); `intersect()` fallaba y se perdían comunas. Corregido ordenando por
    geografía (y mínima). *(Renderizado / Bugfix)*
14. **Bandas proporcionales** al número de tarjetas por comuna. *(Renderizado)*
15. **Colisión 2D real** (solapa en x e y). Baja los solapes a 47, pero Puchuncaví
    sigue saturada (20 tarjetas no caben en su franja). *(Renderizado)*
16. **Columna lateral con leader lines** (paradigma distinto). Rechazado por el
    titular. *(Renderizado)*
17. **Vuelta a tarjetas sobre el punto** por pedido del titular. Confirma la
    inviabilidad geométrica en Puchuncaví. *(Renderizado)*
18. **Rediseño mayor a mapa real georreferenciado** (petición del titular):
    límites comunales desde GeoJSON local + calles de OSM vía `osmdata` +
    reproyección con `sf` a UTM 19S (EPSG:32719); footer eliminado; tarjetas
    semitransparentes; marcadores en columna lateral con leader lines. Render en
    la máquina del titular: malo (calles de OSM como manchas marrones, etiquetas
    de barrios encimadas). *(Arquitectura geo)*
19. **Fallback de límites por GeoJSON local** con filtrado por nombre normalizado,
    tras descartar `chilemapas` por falta de binario para R 4.5.
    *(Arquitectura geo)*

### Sesión 3 (2026-06-26) — sin numeración correlativa

Registrada por **encargo formal a Claude Code** (protocolo dual-Claude), tal como
`traspaso_cierre_v03.md` la documentó. Cierre con entregable aprobado: la variante 1
del afiche quedó terminada y auditada.

- **[s3-a] Encargo v1 — paradigma D:** etiquetas al mar con leader lines sobre
  CARTO Positron real. El panel adversarial cazó un bug de data-masking (índice
  ×4 oculto por `overflow`). *SUPERSEDED.* *(Renderizado)*
- **[s3-b] Encargo v2 — simplificado:** quita etiquetas y leader lines del mapa;
  solo pines + índice. *SUPERSEDED.* *(Renderizado)*
- **[s3-c] Encargo v3.1 — límites BCN:** reemplaza el GeoJSON de fcortes
  (groseramente generalizado, comunas solapadas) por el shapefile BCN de alta
  resolución. *(Arquitectura geo)*
- **[s3-d] Encargo v4 — pines grandes:** anti-colisión 2D real (repulsión de
  discos, `min_dist ≥ 2·PIN_RADIO_PX`) más zonas de exclusión para los rótulos de
  ciudad del tile. *(Renderizado)*
- **[s3-e] Encargo v5 — tile sin rótulos + etiquetas de comuna:** redactado y
  **saltado por el titular** (no ejecutado). Reanclado después como v7. *SKIPPED.*
- **[s3-f] Encargo v6 — numeración N→S + nota + índice:** numeración estricta por
  latitud; nota del Área de Monitoreo; índice a alto completo (fuente 10,3 px,
  tope por no-overflow). *(Etiquetas y texto)*
- **[s3-g] Encargo v7 — tile sin rótulos + etiquetas de comuna:** reancla el v5
  sobre el v6. Tile PositronNoLabels, zonas de exclusión eliminadas, 4 etiquetas
  de comuna en azul gobCL. *(Renderizado / Etiquetas)*
- **[s3-h] Encargo v8 — exportación PDF A0:** PDF A0 vertical (841×1189 mm), texto
  editable, fuentes incrustadas, mapas regenerados a resolución A0.
  *(Exportación)*
- **[s3-i] Encargo v9 — etiquetas como texto HTML:** las 4 etiquetas de comuna
  salen del PNG (`geom_text`) y pasan a texto HTML `position:absolute` sobre el
  mapa, para ser editables en Affinity Publisher. *(Etiquetas y texto)*

**Nota histórica:** el incidente v5/v6 (encadenar un encargo sobre un estado
asumido no confirmado, que Claude Code detectó y señaló) es el origen de la regla
de que todo encargo declara explícitamente su estado real verificado.

### Sesión 4 (2026-06-28) — sin numeración correlativa

Registrada por **operación**, tal como `traspaso_cierre_v04.md` la documentó.

- **[s4-a] Migración a GitHub privado (Rama A):** confirmado con el titular que el
  maestro solo tiene RBD/nombre/tipo/comuna/coordenadas (todo público MINEDUC).
  Auditoría de seguridad pre-migración: 12 hallazgos, ninguno bloqueante.
  `.gitignore` Rama A; primer commit; push inicial (104 MB). Repo:
  `slep_territorio_costa_central` (nombre ≠ carpeta local; divergencia aceptada).
  *(Gobernanza)*
- **[s4-b] Reorganización de `scratchpad_afiche/`:** 83 archivos planos
  (anti-patrón, política §1.6) → `40_salidas/exploraciones/{01,02,03}/{renders,scripts}/`.
  Solo texto versionado (18 `.R`); PNG en disco, gitignored. Sobras a
  `_archivo/20260628/`. Rescate de `preparar_bcn.R` al pipeline como
  `30_preparar_comunas.R`. *(Reorganización estructural)*
- **[s4-c] Gitignore de pesados y destrackeo:** ~115 MB destrackeados
  (`comunas_bcn/` 61 MB, afiche `.pdf` 39,7 MB, `.afpub` 6,4 MB, `.html` 4,6 MB,
  `.png` 3,6 MB), todos conservados en disco. Los patrones se aplicaron **antes**
  de mover, para que los PNG nunca entraran al índice. *(Gobernanza)*
- **[s4-d] Purga de historial (operación destructiva):** backup espejo verificado
  antes de tocar nada; `git filter-repo --invert-paths`; `.git` de 102,98 MiB a
  1,05 MiB (~99%); hashes reescritos; force-push al único clon. *(Gobernanza)*
- **[s4-e] Exploración de la variante a escala única:** Fase 0 geométrica (medido
  que `separar_pines` resuelve los 60 de Viña sin proxy: la premisa del encargo
  original era falsa); sondeo A/C (in situ puro vs. proxy+leader del mockup del
  titular: C genera una telaraña de 53 leaders que tapa la costa); sondeo D/E
  (arco de descarga = 96 cruces; círculo compacto desplaza sin beneficio); sondeo
  T1/T2/T3 de tamaño de pin. **Decisión: A (in situ) + T2 (radio al 60%).** La
  Fase 1 (33b) quedó encargada pero **no ejecutada**. *(Exploración y sondeos)*

### Sesión 5 (2026-06-28) — sin numeración correlativa

Registrada por **bloque**, tal como `traspaso_cierre_v05.md` la documentó.

- **[s5-a] Verificación de estado post-purga:** invariantes confirmadas (`git diff
  --stat` vacío para 33/31/32/00_run_all; original con mtime intacto).
  *(Gobernanza)*
- **[s5-b] Construcción y auditoría de 33b (Fase 1, encargo heredado de v04):**
  `33b_generar_afiche_escala_unica.R` construido reusando funciones de 33 vía
  `source(local = TRUE)` sin editarlo. Mediciones reales: 97 pines, radio 35,2 px,
  `min_dist` 81,2 ≥ 70,4, fuera = 0, PDF A0 2384×3370 pt, fuentes 7/7, 97 entradas
  de RBD en el índice. *(Renderizado / Exportación)*
- **[s5-c] Fix de la regresión de etiquetas de comuna:** la etiqueta "Viña del Mar"
  tapaba el pin 56, porque `etiquetas_pct` las ancla al centroide geográfico y en
  el panel único el centroide de Viña cae sobre el cluster denso. Corregido con
  `OFFSET_ETIQUETAS_PCT` (constante aditiva en 33b, que no toca 33): solo Viña se
  mueve (dy +9%). Añadido el switch `REUSAR_PNG` para regenerar HTML+PDF sin
  re-renderizar el mapa de pines. *(Etiquetas y texto / Bugfix)*
- **[s5-d] Pulido editorial en Affinity Publisher:** las 4 etiquetas al océano son
  posición editorial no reproducible por código (el ancho del rótulo de Viña
  excede la franja de océano disponible). El titular las reposicionó a mano sobre
  el PDF editable y exportó el PDF plotter-ready (300 DPI, PDF 1.7, fuentes
  incrustadas). La separación pipeline/editorial queda explícita y consciente.
  *(Exportación)*

### Sesión 6 (2026-07-12) — sin numeración correlativa

Registrada por **bloque**, tal como `traspaso_cierre_v06.md` la documentó. Sesión
larga: cerró las deudas menores del proyecto original y construyó la variante 3
completa.

- **[s6-a] Cierre de deudas menores heredadas de v05:** README actualizado (ambas
  variantes documentadas, nota de locale UTF-8, nota de `comunas_bcn`);
  `BUFFER_VISUAL_DEG` verificado como inexistente (falso positivo de v03, cerrado
  sin acción); backup espejo borrado por el titular; decisión de no cablear 33b a
  `00_run_all` evaluada y rechazada. *(Documentación y deuda)*
- **[s6-b] Diagnóstico de insumos para la variante 3:** directorio oficial nacional
  (UTF-8, pese a lo asumido inicialmente); histórico de matrícula por MRUN
  2004–2025; planilla canónica de macrogrupos de enseñanza; listado SLEP 2026 con
  año de traspaso y excepciones. Encoding, separador, BOM, headers y cobertura del
  join verificados, no asumidos. *(Capa de datos)*
- **[s6-c] Exclusión del territorio insular (decisión de alcance v1):** Rapa Nui
  (comuna 5201) y Juan Fernández (comuna 5104) excluidos de **todo** el producto
  v1, no solo del mapa. Criterio: las islas no son "entorno" del SLEP Costa
  Central (argumento de propósito, más sólido que el cartográfico). Implementado
  por comuna insular, no por provincia. Universo final: 1.268 establecimientos.
  *(Reglas de negocio y alcance)*
- **[s6-d] Parvularia JUNJI/Integra fuera del conteo (decisión de alcance v1):** el
  archivo de parvularia no se integra al conteo por RBD (duplicaría a los párvulos
  de escuelas, que ya cuentan vía `Matricula-por-estudiante` con COD_ENSE=10;
  solape de MRUN del 100% verificado). El 36% del archivo no tiene RBD (usa
  `ID_ESTAB`, universo JUNJI/Integra) y los cortes temporales difieren (31-ago vs.
  30-abr). Consecuencia: los jardines JUNJI/Integra no aparecen en el mapa.
  *(Reglas de negocio y alcance)*
- **[s6-e] Recodificación de dependencia SLEP vigente 2026:** el directorio oficial
  (corte 30-abr-2025) antecede a traspasos que ya ocurrieron. Se implementó
  `TRASPASO_SLEP_VIGENTE_2026` en el script 34: las comunas con
  `AGNO_TRASPASO_EDUC ≤ 2026` se muestran como SLEP con su nombre, aunque el
  directorio las tenga como municipales. Excepciones respetadas: Zapallar (2027),
  Santo Domingo (2028), del Litoral (2027), Quillota (2029). Gate compuesto:
  127 nativos + 216 recodificados = 343. Declarado en `metadatos.json`.
  *(Reglas de negocio y alcance)*
- **[s6-f] Tratamiento de establecimientos sin registro de matrícula:** 85
  establecimientos (60 sin ningún año en la ventana 2016–2025, 25 en cierre
  progresivo) no tienen matrícula ni, por tanto, tipos de enseñanza derivables. Se
  investigó y descartó rellenar desde el directorio oficial (sus campos `ENS_01..11`
  son también matrícula-dependientes por definición de la glosa). Solución: los 25
  en cierre muestran su oferta histórica derivada del último año con matrícula; los
  60 sin registro declaran explícitamente la ausencia. Hallazgo relevante: los 85
  son en su totalidad de modalidades no obligatorias, lo que sugiere que el sistema
  de matrícula única no captura bien la parvularia privada.
  *(Reglas de negocio y alcance)*
- **[s6-g] Bugfix de encoding R→JS (huecos como `{}` en vez de `null`):**
  `jsonlite` serializa `NULL` dentro de listas como `{}`; R trata ambos como
  equivalentes al releer, pero JavaScript no. Síntoma real: el popup de un
  establecimiento en cierre progresivo (RBD 14439) decía "hasta 2025" cuando su
  serie terminaba en 2022. La auditoría en R no lo detectó porque comparaba en R.
  Corregido en el script 36 (`NA_integer_` en vez de `NULL`). *(Bugfix)*
- **[s6-h] Bugfix hermano (`auto_unbox` desempaqueta arrays de un elemento):** un
  establecimiento con un solo nivel de enseñanza se serializaba como escalar en vez
  de array, rompiendo el JS. Resuelto con normalización defensiva en el consumidor.
  *(Bugfix)*
- **[s6-i] Front-end del mapa interactivo (Leaflet):** construido en 5 hitos con
  puntos de detención: esquema y paleta con contraste calculado; mapa base con
  pines, hover, click y sparkline; correcciones iterativas de paleta, fronteras
  territoriales, encuadre y tarjeta; siete filtros acumulativos con opciones
  dependientes (arquitectura de facetas: cada filtro recalcula sus opciones sobre
  el subconjunto que cumple **los demás** filtros, no a sí mismo, lo que evita el
  atrapamiento clásico de esta UI); exportación a SVG vectorial y a XLSX en locale
  español. Publicado en GitHub Pages. *(Front-end web)*

### Sesión 7 (2026-07-12) — la numeración correlativa se reanuda en 20

20. **Creación del backlog acumulativo canónico.** Este archivo. Cierra la brecha
    de gobernanza señalada por POLITICA §10 y SETTINGS §2.2.5 (obligatorio a
    partir del segundo cierre; el proyecto llegó al séptimo sin él). Incluye la
    declaración explícita de la discontinuidad de numeración (§2.1) en vez de una
    renumeración retroactiva inventada. *(Documentación y deuda)*

*(Las entradas siguientes de la sesión 7 se agregan a continuación conforme
avance el trabajo.)*

---

## 6. Delta del backlog

**vs. v06:** primera versión del archivo canónico. Reconstruye el histórico
completo de las sesiones 1 a 6 desde los seis traspasos; conserva literal la serie
numerada 1–19 (sesiones 1–2); registra las sesiones 3–6 sin numeración
correlativa, con la granularidad que cada traspaso documentó; consolida la
taxonomía temática en 13 categorías (unifica las propuestas parciales de v01, v02
y v05); declara la discontinuidad de numeración como hecho histórico; reanuda la
serie correlativa en el cambio 20.
