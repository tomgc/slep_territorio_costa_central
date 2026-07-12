# Reporte — prueba de humo de render (Censo 2024, capa de manzana)

**Fecha:** 2026-07-12 · **Etapa 2, Hito 1** · Naturaleza: medición desechable. No
construye la capa. Artefactos en `/tmp/censo_render/` (mueren ahí). El único archivo que
entra al repo es este reporte.

**Pregunta única:** ¿Leaflet renderiza ~5.983 polígonos de manzana de Costa Central con
fluidez aceptable? — respondida con cifra medida, no con impresión.

---

## Método

- **Navegador:** Google Chrome **149.0.7827.201**, conducido con `puppeteer-core` 25.3.0
  apuntando al Chrome del sistema (no se descargó navegador).
- **Modo:** **headful** (ventana visible, compositing GPU real de macOS) — elegido sobre
  headless para que los FPS reflejen la ruta de render real, no SwiftShader por software.
- **Viewport:** 1440×900. Fondo **CARTO Positron** (mismo del producto).
- **Memoria:** `performance.memory.usedJSHeapSize` con flag
  `--enable-precise-memory-info` (valores reales, no cuantizados). Soportado: sí.
- **Carga:** `performance.now()` alrededor de `L.geoJSON(...).addTo(map)`, cerrado en el
  primer `requestAnimationFrame` posterior (incluye layout + primer pintado).
- **FPS:** bucle `requestAnimationFrame` contando frames y midiendo el mayor hueco
  entre frames (`maxGap`) durante 4 s de animación programática por cada gesto:
  - **Pan:** `map.panBy` oscilante `animate:false` cada frame (fuerza re-render de la
    capa vectorial en cada frame).
  - **Zoom:** `map.setZoom` fraccional (`zoomSnap:0`) oscilante `animate:false` cada
    frame (fuerza **reproyección de todos los vértices** en cada frame).
  - `FPS_medio = (frames−1)·1000 / duración`; `FPS_min = 1000 / maxGap`.
- Cada variante en su propio archivo (`render_svg.html`, `render_canvas.html`), idénticos
  salvo el renderer. Se midieron **las dos**.

**Criterio de lectura (declarado a priori, la decisión de producto es del titular):**
FPS_min ≥ 30 → *fluido* · 15–30 → *degradado pero usable* · < 15 → *inaceptable*.

---

## Insumo medido (Fase 1)

| Métrica | Valor (medido) |
|---|---|
| Features tras filtro (CUT ∈ Costa Central) | **5 983** |
| `nchar(unique(MANZENT))` | **13** (constante) |
| `nchar(unique(CUT))` | **4** (constante) |
| Geometrías colapsadas a vacío por simplificación (5 m) | **230 (3,84 %)** |
| Features escritos al GeoJSON (5 983 − 230) | **5 753** |
| Peso crudo GeoJSON (`COORDINATE_PRECISION=6`) | 2 891,0 KB |
| Peso **gzip −9 medido** (`gzip -9 -c … \| wc -c`) | **412,7 KB** (422 571 B) |
| `n_edad_6_13` == 0 (gris neutro) / > 0 (rampa) | 1 474 / 4 279 |

Simplificación aplicada **después** de proyectar a métrico:
`st_transform(32719)` → `st_simplify(dTolerance=5)` → `st_transform(4326)`.

---

## Resultado de la medición (Fase 3)

| Métrica | **SVG** (defecto) | **Canvas** (`L.canvas()`) |
|---|---:|---:|
| Carga hasta primer pintado (ms) | 63 | **37** |
| Pan — FPS medio | 81,9 | **118,6** |
| **Pan — FPS mínimo** | **38,6** | **57,1** |
| Zoom — FPS medio | 22,7 | **42,1** |
| **Zoom — FPS mínimo** | **17,2** | **23,9** |
| Heap antes de la capa (MB) | 2,09 | 2,11 |
| Heap después de la capa (MB) | 33,64 | 32,12 |
| Δ heap por la capa (MB) | 31,56 | 30,01 |

Lectura contra el criterio:

| Gesto | SVG | Canvas |
|---|---|---|
| Pan | FPS_min 38,6 → **fluido** | FPS_min 57,1 → **fluido** |
| Zoom (estrés sintético agresivo) | FPS_min 17,2 → **degradado pero usable** | FPS_min 23,9 → **degradado pero usable** |

El gesto de zoom es el más caro (reproyecta los ~5 753 polígonos completos en cada
frame, con `zoomSnap:0` y sin animación de Leaflet): es un **piso conservador**. El zoom
real de un usuario es escalonado y animado por Leaflet, más liviano que este estrés
continuo. El pan, más cercano al uso real, es fluido en ambos renderers.

---

## Veredicto

**La capa de manzana ES viable en Leaflet, con el renderer Canvas (`L.canvas()`).**
Lo sostiene la cifra: con Canvas el pan tiene FPS mínimo **57,1** (fluido) y el zoom
—en el estrés más agresivo posible— FPS mínimo **23,9** (usable), con carga de **37 ms**
y **~30 MB** de heap. Canvas gana a SVG en **todas** las métricas: carga (37 vs 63 ms),
pan (min 57 vs 39), zoom (min 24 vs 17). SVG también es viable pero deja el zoom pegado
al borde inferior de la banda usable (17,2).

**Recomendación:** Canvas (`L.canvas()`) — es viable en las dos, pero Canvas rinde
mejor en todas las métricas y saca el zoom del borde de lo aceptable (24 vs 17 FPS min).

---

## Lo que NO se pudo medir / caveats

1. **Fidelidad de un solo dispositivo.** Los FPS se midieron en la máquina del titular
   (Chrome 149 headful, GPU de macOS). Un cliente de gama baja o un móvil puede rendir
   por debajo de estas cifras; esta prueba **no** es un barrido de dispositivos.
2. **El estrés de zoom es sintético y peor que el uso real** (fracción continua cada
   frame vs. zoom escalonado animado). La cifra de zoom es un piso, no el caso típico.
3. **Ruido de tiles.** Se dejó asentar el fondo 1,5 s antes de estresar, pero la red de
   tiles puede introducir jitter marginal en `maxGap`; el FPS_min es por ello un límite
   inferior, no un promedio suavizado.
4. No se midió rendimiento con **interacción de hover/click por feature** (tooltips,
   resaltado): esta prueba mide pintado y navegación, no la capa de interacción del
   producto.

---

## Panel adversarial

1. **¿Los FPS se midieron en un navegador real?** **Sí, medidos** en Chrome 149 headful
   vía puppeteer-core sobre el Chrome del sistema. No estimados, no deducidos del peso.
2. **`nchar(unique(...))`:** MANZENT → `13` (único valor); CUT → `4` (único valor).
   Ambos constantes; el `stopifnot` del script no disparó.
3. **¿Simplificación después de proyectar a 32719?** Sí. Líneas del script:
   `m_metrico <- st_transform(m, CRS_METRICO)` → `m_simpl <- st_simplify(m_metrico,
   dTolerance = TOLERANCIA_SIMPLIFICACION_M)` → `m_web <- st_transform(m_simpl, CRS_WEB)`
   (`CRS_METRICO=32719`, `CRS_WEB=4326`).
4. **¿Cuántas geometrías colapsaron realmente?** **230** (esperado 230). 3,84 %.
5. **¿Cuántos features tiene el GeoJSON final?** Filtradas **5 983**; escritas tras
   descartar vacías **5 753** (`n_features` reportado por la página = 5 753, coincide).
6. **¿El peso gzip se midió?** **Medido** con `gzip -9 -c … | wc -c` = 422 571 B
   (412,7 KB).
7. **¿Se escribió algo fuera de `/tmp/censo_render/` y del reporte?** No (ver `git
   status` en la entrega). `docs/` intacto.
8. **¿Alguna afirmación sin comando/medición que la respalde?** No: carga, FPS, memoria
   salen del runner; features, colapsadas, gzip salen del script R de Fase 1.
