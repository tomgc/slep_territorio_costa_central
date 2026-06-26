# Log de cierre — Exportación a PDF A0 vertical (texto editable, mapas a resolución)

> Encargo: `50_documentacion/andamios/encargo_claude_code_export_pdf_a0_v8.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, todas las fases + panel adversarial.** Log sin commitear.

---

## 1. Resumen

Se agregó la salida **PDF A0 vertical (841×1189 mm)** para plóter, con **texto editable**
(fuentes incrustadas) para seguir afinando en Affinity Publisher, y se subió la resolución
de los PNG de los mapas para que **no salgan pixelados** al imprimirse a 841 mm. El diseño
v7 se conserva intacto: solo cambia el tamaño físico de salida y la densidad de los mapas.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `2eae033` | feat(33) | Tamaño A0 (`@page`+`zoom`) + mapas a `DPI_A0` + export PDF con `chrome_print` + `.gitignore` PDF |
| `d8f5bf7` | build(afiche) | HTML A0 regenerado con mapas a alta resolución |
| `f7e69d7` | docs | CLAUDE.md |

Sin commitear (revisión): este log y `auditoria_afiche_export_pdf_a0.R`.
**El PDF NO se versiona** (binario ~2,8 MB regenerable; `.gitignore: 40_salidas/afiche/*.pdf`).

## 3. DPI_A0 y dimensiones de los PNG

- `DPI_A0 = 200` (equilibrio calidad/peso sugerido por el encargo; mínimo aceptable 150).
- Cada panel ocupa físicamente en A0 un ancho de `MAPA_W/LIENZO$ancho × 841 mm = 493,7 mm
  = 19,44 in`. A 200 dpi → ancho de PNG = 19,44 × 200 ≈ **3887 px**.
- `ESC = DPI_A0 × A0_W_MM / (25,4 × LIENZO$ancho) = 5,34` (factor de render; antes 2 para A4).
- PNG finales: **panel_norte 3887×5041 px**, **panel_vina 3887×2990 px**.
- **DPI efectivo verificado: 200 dpi** en ambos (≥ 150). El crop del PDF a 150 dpi confirma
  costa/calles/pines/bordes nítidos, sin pixelado.

`PIN_RADIO_PX` y `PIN_GAP_PX` se redefinieron como `11·ESC` y `2·ESC` (= 22 y 4 cuando
ESC=2) para que el pin conserve su proporción respecto al panel a la nueva densidad; la
anti-colisión se mantiene (min_dist = **128 px ≥ 117** = 2·PIN_RADIO_PX, en ambos planos).

## 4. Tamaño de página A0 y reescalado

- `@page { size: 841mm 1189mm; margin: 0 }`.
- El contenedor raíz (1240×1754 px) se lleva a A0 con `zoom: ZOOM`, `ZOOM = 0,999 ×
  (1189 mm en px@96) / 1754 = 2,560`. El `zoom` escala layout **y** tipografías
  proporcionalmente; el texto sigue siendo vectorial (seleccionable), no se rasteriza.
- La proporción del lienzo (1240/1754 = 0,7070) coincide casi exactamente con A0
  (841/1189 = 0,7073); se ajusta por alto con 0,1 % de holgura para no forzar 2ª página.

## 5. Exportación y verificación de editabilidad

`pagedown::chrome_print(input = html, output = ...pdf, options = list(paperWidth, paperHeight
en pulgadas A0, márgenes 0, printBackground, preferCSSPageSize))`. Chrome headless incrusta
las fuentes y mantiene el texto como texto.

Verificado con `pdftools`:
- **`pdf_pagesize` = 2384 × 3370 pt = 841 × 1189 mm** (A0 vertical, tolerancia ±1 mm). ✓
- **`pdf_text`** devuelve 7528 caracteres: incluye el índice (p. ej. "Escuela Básica La
  Laguna" + "RBD 1874"), el título y la **nota del Área de Monitoreo**. Texto seleccionable. ✓
- **`pdf_fonts`: 7/7 incrustadas (embedded = TRUE)** — `gobCL-Heavy`, `gobCL`, `MuseoSans-300`,
  `MuseoSans-500` (las del afiche) + `LucidaGrande` (fallback del sistema, también embedded). ✓

## 6. Peso y versionado

- **PDF: 2,8 MB** → **gitignored** (`40_salidas/afiche/*.pdf`); es entregable binario
  regenerable y no diffea bien en git.
- **HTML: 4,8 MB** (lleva los 2 PNG a 200 dpi en base64) → **versionado** (sigue la
  convención del proyecto de versionar el HTML final).

## 7. Verificación de invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff c2a592a..HEAD` de 31/32 vacío. |
| **🔒-2** Diseño v7 intacto | **PASA** | Audit: 97 filas de índice, 97 RBD+nombres sin truncar, numeración N→S estricta, tile sin rótulos, 4 etiquetas de comuna azul gobCL. Solo cambia tamaño/densidad. |
| **🔒-3** Sin filtro por contención | **PASA** | No se tocó la ubicación de puntos. |
| **🔒-4** Anti-colisión y etiquetas proporcionales | **PASA** | min_dist 128 px ≥ 117 a la resolución A0; PIN_RADIO_PX/GAP escalan con ESC; posiciones de etiquetas (lon/lat) inalteradas. |

## 8. Panel adversarial (independiente del 33)

`auditoria_afiche_export_pdf_a0.R` — abre el PDF/PNGs/HTML reales:

```
[PASA] (a) pagesize = 2384 x 3370 pt (A0, tol +-1mm)
[PASA] (b) pdf_text no vacio (7528 chars)
[PASA] (b) indice editable: 'Escuela Básica La Laguna' + (RBD 1874) en el texto
[PASA] (b) nota del Area de Monitoreo en el texto
[PASA] (c) gobCL incrustada (3/3 embedded)
[PASA] (c) Museo Sans incrustada (3/3 embedded)
[PASA] (c) TODAS las fuentes incrustadas (7/7)
[PASA] (d) panel_norte.png: 3887 px / 19.44 in = 200 dpi (>= 150)
[PASA] (d) panel_vina.png: 3887 px / 19.44 in = 200 dpi (>= 150)
[PASA] (e) indice con 97 filas / 97 RBD+nombres / N->S estricta / tile sin rotulos / etiquetas
[PASA] (e) norte+vina anti-colision A0: min_dist=128 px >= 117
===== PANEL ADVERSARIAL v8: TODO PASA (0 fallas) =====
```

## 9. Notas para Affinity Publisher (qué es editable y qué no)

- **EDITABLE (texto vectorial, fuentes incrustadas):** título y bajada del encabezado, todo
  el **índice** (número + nombre + RBD), la **leyenda** de tipos, los **chips de título** de
  cada panel ("Puchuncaví · Quintero · Concón", "Viña del Mar · ampliación") y la **nota de
  fuente**. Todo eso se puede seleccionar/editar/retipografiar en Affinity.
- **NO editable (imagen rasterizada a 200 dpi):** los **dos mapas** completos — incluye el
  fondo CARTO, los límites comunales, los **pines y sus números**, y las **4 etiquetas de
  comuna** (Puchuncaví/Quintero/Concón/Viña del Mar), que se dibujan dentro del PNG con
  ggplot. Para mover/editar esos textos hay que regenerar el afiche (cambiando las
  constantes/posiciones en el 33), no se editan en Affinity.

## 10. Pendientes y notas para el revisor

- **Validación in situ:** abrir el PDF en Affinity y confirmar selección de texto + que las
  fuentes no se sustituyen (deberían estar incrustadas; gobCL y MuseoSans embedded=TRUE).
- **Si el peso molesta:** bajar `DPI_A0` a 150 reduce los PNG/PDF (~×0,56 área de píxeles)
  manteniendo el mínimo aceptable. Declarado como constante, cambio de una línea.
- **Las etiquetas de comuna van dentro del mapa** (imagen). Si se quisieran editables en
  Affinity, habría que dibujarlas como texto HTML superpuesto al PNG (cambio de diseño, otro
  encargo).
- **Locale UTF-8** obligatorio; **red** para tiles CARTO; **Chrome** requerido por
  `chrome_print`.
- Honestidad: salió directo salvo dos detalles de la verificación — `%d` en `sprintf` con
  `PIN_RADIO_PX` ahora doble (corregido a `%.0f`), y `pdf_fonts()` devuelve un data.frame (no
  lista, quité el `[[1]]`). El peso quedó cómodo (PDF 2,8 MB) porque Positron es plano y
  comprime muy bien.
