# Reporte Fase 0 — Variante "escala única" del afiche A0

**Fecha:** 2026-06-26 · **Naturaleza:** sondeo geométrico (medir, reportar y PARAR).
No se renderizó el afiche, no se escribió 33b, no se tocó ningún script del pipeline.
`30_procesamiento/33_generar_afiche.R` queda **byte-idéntico** (`git diff --stat` = 0;
working tree limpio). Todas las cifras de este reporte se calcularon en código
(scripts en scratchpad; log crudo en
[`logs/20260626_escala_unica_fase0_log.md`](logs/20260626_escala_unica_fase0_log.md)).

> **Hallazgo que cambia el marco de la decisión (leer primero).**
> El encargo asume que, a escala única, el GATE de `dibujar_pines` se dispararía por
> el cluster denso de Viña y que por eso hace falta proxy+leader line. **Medido en
> código, el GATE NO se dispara.** `separar_pines` resuelve los 60 pines de Viña (y los
> 97 juntos) con no-solape garantizado, sin sacar pines del marco, desplazando como
> máximo 175 px PNG (≈ 32.7 px lienzo ≈ 23 mm en A0). La densidad discos/huella es 0.40.
> El diseño proxy+leader sigue siendo una **opción estética válida**, pero su premisa
> técnica (cluster que no cabe) es falsa a esta escala. Esto abre una alternativa más
> simple y limpia que recomiendo evaluar. Detalle en §1, §2 y §5.

---

## 1. Mediciones geométricas

### Lienzo y escala (recalculados idénticos a 33)
| Magnitud | Valor |
|---|---|
| ESC | 5.3404 |
| PIN_RADIO_PX | 58.74 px PNG (11 px lienzo) |
| sep mínima (2r+gap) | 128.17 px PNG |
| Panel único MAPA_W × UNICO_H | 728 × **1520** px lienzo |
| PNG Wpx × Hpx | 3888 × **8117** px |
| Escala terreno | 1 px PNG ≈ 6.30 m |

El panel único ocupa **todo el body** (1520 px lienzo), que es exactamente
`NORTE_H 944 + GAP 16 + VINA_H 560`. Es decir, al eliminar el segundo slot del inset se
libera el alto del inset + el gap.

### bbox a escala única
Construido con el mismo patrón que `render_panel_norte/vina` (bbox de los 97 puntos,
pad ±0.020 lon / ±0.015 lat, a 3857, `fit_bbox_3857` al aspect del panel 0.4789). El fit
**creció en ALTO (N-S)**: el ancho de datos se conserva, no se inyecta margen E-O
artificial. Los márgenes de descarga provienen de la geografía real, no de relleno.

### Huella de Viña y del Norte (px PNG)
| Cluster | x | y | tamaño |
|---|---|---|---|
| **Viña (60)** | 250 .. 1473 | 5934 .. 7255 | 1223 × 1322 px |
| Norte (37) | 782 .. 3638 | 861 .. 5337 | — |

Viña cae al **poniente** (comuna costera/SO) y en el **tercio inferior**. El Norte ocupa
los dos tercios superiores y **no solapa en latitud** con la banda de Viña
(norte y ≤ 5337 < Viña y ≥ 5934). Por tanto la banda horizontal a la **derecha** de Viña
está totalmente libre de pines del norte.

### Márgenes libres y capacidad de discos (radio full, sep 128.2 px)
| Lado | Ancho útil | Capacidad en banda Viña | Capacidad marco completo |
|---|---|---|---|
| **Oriente** (interior) | **2356 px** | **18 col × 10 fil = 180** | 18 × 62 = 1116 |
| Poniente (océano) | 191 px | 1 × 10 = 10 | 1 × 62 = 62 |

**Lectura:** los 60 discos de Viña caben **holgados a radio full en el oriente**
(180 de capacidad, necesitamos 60). El poniente es el lado océano (191 px ≈ 1 columna)
y además el encargo lo veta. → La zona de descarga es **100% oriente**; no hay reparto.
**No se requiere reducir el radio** (la tabla de reducción está en el log por completitud,
pero no es necesaria).

---

## 2. Opciones de tratamiento de Viña, cuantificadas

Las tres comunas del norte van **sobre su punto** (sin cambios). Para Viña:

### Opción A — In situ con `separar_pines` (sin leader lines)
Correr `separar_pines` sobre los 97 a escala única. El GATE pasa.
- Desplazamiento: **medio 67 px (12.5 px lienzo), máx 175 px (32.7 px lienzo ≈ 23 mm A0)**.
- Cruces de leader: **0** (no hay leaders).
- Código nuevo: prácticamente nulo (bbox único + llamar a la maquinaria existente).
- Costo: el disco se separa hasta ~23 mm de su punto real sin marcar el ancla; 57/60
  pines se mueven algo, 4/60 se mueven > 2 radios.
- **Recomendación:** es la más simple y limpia, pero pierde el marcado explícito del ancla.

### Opción B — In situ + leader corto al ancla real (HÍBRIDA)
Usar la posición de `separar_pines` como centro del disco y dibujar un **punto-ancla
pequeño** en la coordenada exacta + leader corto, **solo para los 4 pines** cuyo
desplazamiento supera 2 radios (los demás quedan prácticamente sobre su punto).
- Desplazamiento: idéntico a A (medio 12.5 px lienzo, máx 32.7 px lienzo).
- Cruces de leader: **3** (medido).
- Leader medio: ~13 px lienzo (≈ 1 radio de pin).
- Código nuevo: punto-ancla + leader (el conector visual que el encargo pide construir),
  pero disparado por umbral, no para los 60.
- **Recomendación: ESTA es mi recomendación principal.** Conserva la fidelidad al ancla
  que motiva el diseño del titular, con desplazamiento mínimo y solo 3 cruces, reutilizando
  `separar_pines` tal cual. Es el mejor compromiso medido.

### Opción C — Proxy desplazado a bloque de descarga oriente + leader (diseño aprobado)
Desplazar los 60 a un bloque-grilla al oriente, leader line de cada disco a su ancla.
Mejor geometría de bloque medida = **6×10 en la banda de Viña**:
- Cruces de leader: **53** (mínimo entre bloques; 4×15→116, 3×20→156, 2×30→241, 1×60→596).
- Desplazamiento: **medio 1001 px (187 px lienzo), máx 1774 px (332 px lienzo)**.
- Código nuevo: grilla de descarga + asignación por latitud + 60 leaders.
- **Recomendación:** es el diseño que el titular aprobó y es factible (los discos no se
  solapan, caben de sobra). Pero geométricamente es el más costoso: 53 cruces de leader
  inevitables (el cluster es una nube ancha de 1223 px y los leaders de las anclas del
  poniente cruzan sobre las del oriente) y desplazamientos grandes (~14 cm en A0). Lo
  cuantifico completo porque se pidió, pero quedó dominado por A y B en cada métrica.

### Tabla comparativa
| Opción | Cruces leader | Desp. medio (lienzo) | Desp. máx (lienzo) | Código nuevo | Marca ancla |
|---|---|---|---|---|---|
| A in situ | 0 | 12.5 px | 32.7 px | mínimo | no |
| **B in situ + leader umbral** | **3** | **12.5 px** | **32.7 px** | bajo | sí (4 pines) |
| C proxy+bloque (aprobado) | 53 | 187 px | 332 px | medio | sí (60 pines) |

---

## 3. Arquitectura propuesta de la bifurcación

**Propuesta: script nuevo `33b_generar_afiche_escala_unica.R` que reutiliza las funciones
de 33 vía `source(here::here("30_procesamiento","33_generar_afiche.R"), local = TRUE)`.**

### Por qué `local = TRUE` (verificado en código, no asumido)
El guard de 33 es `if (sys.nframe()==0 || identical(environment(), globalenv()))`.
Probado empíricamente:
- `source(33, local = FALSE)` (el default) → **el flujo principal CORRERÍA**, porque al
  evaluarse en globalenv `identical(environment(), globalenv())` es `TRUE` y el `||` lo
  dispara (regenera el afiche con inset, no lo que queremos).
- `source(33, local = TRUE)` → **el flujo NO corre**; solo se definen las funciones y
  constantes en un entorno local. `sys.nframe()>0` y `environment()` ≠ globalenv ⇒ guard
  falso.

Entonces 33b hace `e <- new.env(); source(33, local = e)` y consume
`e$numerar`, `e$cargar_comunas`, `e$dibujar_pines`/`e$separar_pines`, `e$circulos`,
`e$comuna_paths`, `e$get_carto_3857`, `e$fit_bbox_3857`, `e$generar_html` y todo el chrome,
redefiniendo SOLO lo propio de la variante (bbox único, panel único, y el conector
ancla+leader de la opción elegida). **33 no se edita: queda byte-idéntico.**

### Alternativas descartadas
- **Extraer funciones comunes a un `34_comun.R`** que ambos sourcen: obligaría a EDITAR 33
  (cambiar definiciones inline por un source) → viola el invariante byte-idéntico. Descartada.
- **Copiar/pegar funciones en 33b**: duplicación y deriva futura. Descartada.

`source(local=TRUE)` es además el sesgo declarado del titular y resulta el único que
satisface el invariante. **Recomendación: adoptarla.**

### Nota de implementación para Fase 1
- Las funciones de 33 cierran sobre constantes definidas en 33 (`ESC`, `PIN_RADIO_PX`,
  `MAPA_W`, `NORTE_H`, `VINA_H`…). Al sourcear en `e`, esas constantes viven en `e` y las
  funciones las ven. La variante necesita su propio `UNICO_H`/aspect; se resuelve
  definiendo en 33b una función de render de panel único que llama a `e$dibujar_pines`
  con el bbox y alto nuevos, **sin** depender de `e$render_panel_vina` (🔒-2, autorizado
  desviarse solo en la variante).
- Salidas con nombre distinto: `mapa_establecimientos_escala_unica.{html,pdf}` y
  `panel_unico.png`. No se sobrescribe el producto actual.

---

## 4. Riesgo de cruce de leader lines y orden de asignación

- **Si se elige B (recomendada):** solo 4 pines llevan leader visible; cruces medidos = 3,
  longitudes ~1 radio. Riesgo de maraña: **bajo**. Orden de asignación irrelevante (cada
  leader es local a su disco separado).
- **Si se elige C (aprobada):** el riesgo es **real y no eliminable por reordenamiento**.
  La nube de anclas mide 1223 px de ancho; al descargar a un bloque a un costado, los
  leaders de anclas del poniente cruzan sobre los del oriente. La **asignación por latitud
  (abanico)**, fila por fila N→S, baja los cruces de 733 (orden por nombre) a 53 — mejora
  14×, pero **no a 0**. Geometría de bloque que minimiza cruces: **6×10 pegado a la banda
  de Viña** (más compacto ⇒ menos inversiones). Recomendación de orden si se va por C:
  ordenar anclas por `py` (latitud), llenar la grilla fila-por-fila izquierda→derecha.

---

## 5. Hallazgos del panel adversarial y su resolución

1. **¿Márgenes reales o asumidos?** Reales. Se proyectaron los 97 puntos al bbox 3857 del
   panel único (misma Mercator que el render) y se midieron huella y márgenes en px PNG.
   Ningún margen es supuesto. ✔
2. **¿La propuesta garantiza no-solape de discos Y de leaders, o solo lo primero?** Solo lo
   primero en la opción C: discos sin solape garantizado por `separar_pines`/grilla, pero
   **leaders con 53 cruces** (medido). Se documenta explícitamente; no se vende como limpio.
   En la opción B los leaders quedan en 3 cruces. ✔
3. **¿La arquitectura deja 33 byte-idéntico? ¿`source(33)` ejecutaría su flujo?** Verificado
   en código: con el default `local=FALSE` **SÍ** correría (el `||` del guard via
   `identical(environment(),globalenv())`). Con `local=TRUE` **NO**. 33b debe usar
   `local=TRUE`; 33 no se edita. ✔
4. **¿Algún número clave reportado sin calcular?** No. Alto de panel (1520/8117 px),
   px/grado (~17628 lat), capacidad (180 oriente), cruces (53/3), desplazamientos y el
   disparo del GATE: **todos calculados en código**. ✔
5. **Hallazgo adicional del panel:** la premisa del encargo (GATE se dispara) es falsa a
   escala única. El cluster cabe in situ (densidad 0.40, min_dist 128.2 ≥ 117 req). Esto no
   invalida el diseño aprobado, pero sí ofrece B/A como caminos medibles superiores. Se
   eleva a la decisión del titular en §6.

---

## 6. Qué espera esta Fase 0 de la decisión del titular (antes de Fase 1)

1. **Tratamiento de Viña — decisión principal.** El GATE no se dispara; el cluster cabe in
   situ. Elegir entre:
   - **B (recomendada):** in situ + punto-ancla y leader corto solo para los ~4 pines más
     desplazados. 3 cruces, desplazamiento ≤ 23 mm, reúso máximo, marca el ancla.
   - **A:** in situ puro, sin leaders (lo más simple; no marca ancla).
   - **C (lo aprobado):** proxy a bloque oriente 6×10 + 60 leaders. Factible pero 53 cruces
     y ~14 cm de desplazamiento medio. Lo construyo si el titular lo confirma pese a la
     comparación.

   > Necesito confirmación explícita aquí porque la medición contradice la premisa del
   > encargo. No avanzo a Fase 1 sin esta decisión.

2. **Zona de descarga (solo si C):** confirmo **100% oriente** (poniente es océano/veto y
   solo cabe 1 columna). Reparto O/P = no aplica.

3. **Radio:** confirmo **radio full sin reducción** en todas las opciones.

4. **Arquitectura:** aprobar `33b` con `source(33, local=TRUE)`, 33 intacto.

5. **Nombres de salida:** `mapa_establecimientos_escala_unica.{html,pdf}` (no sobrescribe).

Con esas respuestas detallo y ejecuto la Fase 1.
