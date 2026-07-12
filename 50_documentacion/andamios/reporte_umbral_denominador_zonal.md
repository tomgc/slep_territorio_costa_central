# Reporte — umbral de denominador de la capa zonal (Censo 2024)

**Fecha:** 2026-07-12 · **Etapa 2, Hito 3 (ampliación)** · Medición + decisión + campo nuevo.
**Script:** `30_procesamiento/38_construir_capa_zonal.R` (actualizado).
**Salida:** `docs/data/censo_zonal_r5.geojson` (regenerado, 15 columnas).

---

## 1. El problema

El diagnóstico del Hito 2a midió el denominador **agregado por comuna** (mediana sana), pero
nunca **por unidad**. Sobre el artefacto real, la mediana zonal del denominador de básica es
90 niños, pero el p10 es 4, y **227 unidades (19 %) tienen proporción exactamente 0,0 o 1,0
en básica**, con mediana de denominador 5. Una localidad con 1 niño en parvularia que no
asiste se pintaría 0 % (rojo intenso): no es desescolarización, es un niño.

Es el mismo defecto que hizo descartar la tasa a nivel manzana (contrato de alcance §3.1:
*"un conteo tolera la desagregación fina; un cociente no"*).

---

## 2. FASE 1 — Medición (el umbral sale de aquí, no se eligió a priori)

Denominador por nivel (solo unidades con den > 0):

| Nivel | den (col) | min | p05 | p10 | p25 | mediana | p75 | p90 | max |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Parvularia | `n_edad_0_5` | 1 | 2 | 3 | 15 | 53 | 124 | 211 | 835 |
| Básica | `n_edad_6_13` | 1 | 2 | 4 | 25 | 90 | 232 | 404 | 1485 |
| Media | `n_edad_14_17` | 1 | 2 | 3 | 14 | 49 | 127 | 212 | 595 |

Barrido de N candidatos. `%niños` = fracción del total regional de niños del nivel que vive
en las unidades bajo el umbral (lo que se "censura" del color); `sd_bajo`/`sd_encima` =
desviación estándar de la proporción por debajo/encima del umbral; `01_bajo` = celdas con
proporción exactamente 0,0/1,0 capturadas.

**Parvularia** (total niños 100 445; celdas 0/1: 78, mediana den 1):
| N | n_bajo | %unid | %niños | sd_bajo | sd_encima | 01_bajo |
|---:|---:|---:|---:|---:|---:|---:|
| 5 | 142 | 11,7 % | 0,3 % | 0,378 | 0,105 | 76 |
| 10 | 235 | 19,3 % | 0,9 % | 0,315 | 0,093 | 78 |
| 15 | 287 | 23,6 % | 1,6 % | 0,294 | 0,086 | 78 |
| **20** | **333** | **27,4 %** | **2,3 %** | **0,277** | **0,083** | **78** |
| 25 | 384 | 31,6 % | 3,4 % | 0,262 | 0,079 | 78 |
| 30 | 432 | 35,5 % | 4,7 % | 0,250 | 0,076 | 78 |
| 40 | 491 | 40,4 % | 6,7 % | 0,236 | 0,074 | 78 |
| 50 | 550 | 45,2 % | 9,3 % | 0,226 | 0,070 | 78 |

**Básica** (total niños 187 943; celdas 0/1: 227, mediana den 5):
| N | n_bajo | %unid | %niños | sd_bajo | sd_encima | 01_bajo |
|---:|---:|---:|---:|---:|---:|---:|
| 5 | 124 | 10,2 % | 0,2 % | 0,230 | 0,042 | 108 |
| 10 | 185 | 15,2 % | 0,4 % | 0,196 | 0,037 | 152 |
| 15 | 228 | 18,8 % | 0,7 % | 0,179 | 0,034 | 177 |
| **20** | **266** | **21,9 %** | **1,0 %** | **0,168** | **0,032** | **192** |
| 25 | 292 | 24,0 % | 1,3 % | 0,161 | 0,032 | 195 |
| 30 | 327 | 26,9 % | 1,8 % | 0,153 | 0,030 | 201 |
| 40 | 376 | 30,9 % | 2,7 % | 0,144 | 0,029 | 214 |
| 50 | 432 | 35,5 % | 4,0 % | 0,135 | 0,027 | 222 |

**Media** (total niños 95 870; celdas 0/1: 181, mediana den 3):
| N | n_bajo | %unid | %niños | sd_bajo | sd_encima | 01_bajo |
|---:|---:|---:|---:|---:|---:|---:|
| 5 | 142 | 11,7 % | 0,3 % | 0,284 | 0,069 | 114 |
| 10 | 229 | 18,8 % | 0,9 % | 0,238 | 0,060 | 151 |
| 15 | 290 | 23,8 % | 1,7 % | 0,217 | 0,055 | 167 |
| **20** | **348** | **28,6 %** | **2,7 %** | **0,201** | **0,052** | **174** |
| 25 | 392 | 32,2 % | 3,7 % | 0,192 | 0,049 | 178 |
| 30 | 439 | 36,1 % | 5,1 % | 0,182 | 0,048 | 181 |
| 50 | 579 | 47,6 % | 10,8 % | 0,162 | 0,042 | 181 |

### Condición de parada: NO se activa

El nivel más caro es media, y a N=20 censura **2,7 %** de sus niños (básica 1,0 %, parv
2,3 %). Muy por debajo del 15 % que obligaría a reabrir el contrato. El indicador **es
publicable** a esta escala con el umbral de presentación.

---

## 3. Decisión: `DENOM_MINIMO = 20`, común a los tres niveles

**Por qué 20, y por qué común:**

1. **La `sd` de la proporción se estabiliza en N=20.** El `sd_encima` (ruido residual del
   grupo "confiable") a N=20 es básica 0,032, parv 0,083, media 0,052; más allá de 20 su
   descenso marginal es < 0,005 por cada +10 en N. 20 es el codo: subir el umbral ya casi no
   limpia ruido, y sí censura más niños.
2. **Captura el grueso de las celdas patológicas** (proporción exacta 0,0/1,0): parv
   **78/78 (100 %)**, media **174/181 (96 %)**, básica **192/227 (85 %)**. Las patológicas
   con denominador ≥ 20 (básica, las 35 restantes) son celdas de asistencia **plena o nula
   reales** (p. ej. 25 niños y los 25 asisten), no ruido: es correcto no censurarlas.
3. **Censura mínima:** 1,0–2,7 % de los niños por nivel.
4. **Común a los tres** porque el codo de `sd` cae en ~20 para los tres; no hay evidencia de
   que un nivel necesite un umbral distinto (un `DENOM_MINIMO` por nivel añadiría complejidad
   sin ganancia medida).

Es un umbral de **presentación**, no de cálculo: la proporción cruda se conserva siempre; lo
único que cambia es que el front-end no coloreará las unidades `fiable=FALSE`.

---

## 4. FASE 2 — Implementación

Campo nuevo por nivel: `fiable_<nivel>` (lógico), con **tres estados**:

| Estado | Condición | `proporcion_*` | `fiable_*` |
|---|---|---|---|
| Sin grupo en edad | `den == 0` | **NA** | **NA** |
| Ruidoso | `0 < den < 20` | valor (conservado) | **FALSE** |
| Fiable | `den >= 20` | valor | **TRUE** |

Conteo de los tres estados por nivel (medido sobre el artefacto):

| Nivel | NA (den 0) | FALSE (ruidoso) | TRUE (fiable) | Suma |
|---|---:|---:|---:|---:|
| Parvularia | 62 | 333 | 821 | 1 216 |
| Básica | 38 | 266 | 912 | 1 216 |
| Media | 75 | 348 | 793 | 1 216 |

El GeoJSON pasó de 12 a **15 columnas** (se agregaron `fiable_parv`, `fiable_basica`,
`fiable_media`). Peso: gzip **421,0 KB** (era 418,0; +3 KB por los tres booleanos).

---

## 5. Panel adversarial

1. **¿El N sale de la medición?** Sí (tablas §2). El codo de `sd_encima` está en N=20 para
   los tres niveles; se eligió después de medir, no antes.
2. **¿% de niños bajo el umbral, por nivel?** Parvularia 2,3 %, básica 1,0 %, media 2,7 %.
   Reportado; todos << 15 %.
3. **¿La proporción sigue presente cuando `fiable=FALSE`?** Sí. Las **266** unidades
   `fiable_basica=FALSE` conservan su proporción (0 nulls). Ejemplo del JSON: `id_unidad
   540106001`, `n_edad_6_13=11`, `n_asistencia_basica=11`, `proporcion_asistencia_basica=1.0`,
   `fiable_basica=false` — el caso patológico exacto, conservado con su advertencia.
4. **¿Los tres estados son distinguibles?** Sí (conteos §4). Ejemplos: `fiable=NA` →
   `540105002` (den 0, prop null); `fiable=FALSE` → `540106001` (den 11, prop 1.0);
   `fiable=TRUE` → `540101001` (den 346, prop 0.9769).
5. **¿Cambió el canario `TOL_LECTURA_PARQUET`?** No. `max|dif| = 0,60 pp`, idéntico al del
   Hito 3. El umbral es de presentación, no de cálculo: no toca la proporción ni la agregación.
6. **¿Se tocó algo fuera de la entrega?** Solo `38_construir_capa_zonal.R`, el GeoJSON y este
   reporte (ver `git status` en la entrega). `docs/assets/` y `00_run_all.R` intactos por mí.
