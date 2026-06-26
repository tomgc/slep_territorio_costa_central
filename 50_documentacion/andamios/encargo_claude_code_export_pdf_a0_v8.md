# Encargo autónomo — Exportación a PDF A0 (texto editable, mapas a resolución)

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 7, v8).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** exportar el afiche actual a un PDF **A0
> vertical (841×1189 mm)** para plóter, con el **texto editable** (fuentes
> incrustadas, no convertido a curvas) para seguir afinándolo en Affinity
> Publisher. Los mapas pueden quedar como imagen, pero **a resolución suficiente
> para A0** (no pixelados).

---

## Contexto y problema técnico a resolver

El afiche es un HTML autocontenido donde el texto (índice, título, etiquetas,
nota) es HTML/vectorial, y los dos mapas (panel norte + inset Viña) son **PNG
rasterizados** embebidos en base64, generados a ~1456 px de ancho (dimensionado
para A4).

**Riesgo:** si solo se escala el PDF a A0, esos PNG de 1456 px se estiran sobre
841 mm de ancho → mapas borrosos/pixelados en el plóter. El texto saldría nítido
(vectorial), pero los mapas no.

**Solución (dos partes):**
1. Regenerar los dos PNG de los mapas a la **resolución que A0 exige** (mucho
   mayor densidad de píxeles), antes de exportar.
2. Exportar el HTML a PDF declarando tamaño físico A0 y con fuentes incrustadas.

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.
**Regla de detención:** un 🔒 se vería comprometido, o la exportación no logra
incrustar fuentes / no alcanza la resolución A0 (reporta antes de entregar algo
degradado).
**Reglas heredadas:** R-only, `here::here()`, sin rutas absolutas, locale UTF-8,
commits atómicos en español.

---

## 2.2 Contexto de rutas
- Script: `30_procesamiento/33_generar_afiche.R`.
- Salida HTML actual: `40_salidas/afiche/mapa_establecimientos.html`.
- Salida PDF nueva: `40_salidas/afiche/mapa_establecimientos.pdf`.
- `run_all(from=1,to=3)`.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Se conserva TODO el contenido y diseño actual (v7): tile sin rótulos,
  4 etiquetas de comuna azules, numeración N→S estricta, nota del Área de
  Monitoreo, índice con número+nombre+RBD, límites BCN, pines grandes con
  anti-colisión, inset Viña, leyenda, colores por tipo. **Este encargo NO cambia
  el diseño; cambia el tamaño de salida y agrega el PDF.**
- **🔒-3.** Los puntos no se filtran por contención en polígono.
- **🔒-4.** La anti-colisión de pines y las posiciones de etiquetas se conservan
  proporcionalmente al re-renderizar a mayor resolución (el layout es el mismo,
  solo cambia la densidad de píxeles).

---

## 2.4 Fases

### Fase 0 — Lectura del estado real
- Lee `33_generar_afiche.R`. Localiza: dónde se fija el ancho/alto/dpi del render
  de cada PNG (panel norte e inset Viña), dónde se define el tamaño de página del
  HTML (CSS `@page` / dimensiones del contenedor), y si ya existe un paso de
  exportación a PDF.

### Fase 1 — Resolución de los mapas para A0
- A0 vertical = 841×1189 mm = 33,1×46,8 pulgadas. A 150 dpi (mínimo razonable para
  plóter de gran formato) el ancho útil del mapa ronda varios miles de px; a 200-
  300 dpi, más. Define una constante `DPI_A0` (sugerido 200 dpi como equilibrio
  calidad/peso; 150 si el peso del PDF se vuelve inmanejable) y dimensiona los PNG
  de los paneles a esa densidad para el ancho físico que ocupan en el A0.
- Cálculo: el ancho en px de cada panel = (ancho físico del panel en pulgadas) ×
  `DPI_A0`. Mantén la proporción actual de cada panel (no deformar). El layout
  (posición de pines, etiquetas, anti-colisión) se conserva: solo sube la densidad.
- **Criterio:** los PNG de los mapas salen a resolución tal que, impresos a 841 mm
  de ancho, no se ven pixelados (≥150 dpi efectivos sobre el área que ocupan).

### Fase 2 — Tamaño de página A0 en el HTML
- Ajusta el CSS del HTML para tamaño físico A0 vertical: `@page { size: 841mm
  1189mm; margin: 0; }` y el contenedor raíz a 841×1189 mm. Reescala tipografías y
  espaciados proporcionalmente para que el índice, título, etiquetas y nota
  mantengan su proporción visual en A0 (no que queden minúsculos en una hoja
  gigante). Declara las medidas como constantes.
- **Criterio:** el HTML, abierto/renderizado, ocupa una página A0 vertical con el
  contenido bien proporcionado (mapas, índice y chrome equilibrados, sin
  desbordes ni huecos enormes).

### Fase 3 — Exportar a PDF con fuentes incrustadas
- Exporta con `pagedown::chrome_print(input = <html>, output =
  "40_salidas/afiche/mapa_establecimientos.pdf")`. chrome_print usa Chrome
  headless, que **incrusta las fuentes** y mantiene el texto como texto (no
  curvas) por defecto.
- **Verificación obligatoria de editabilidad (es el objetivo del usuario):** tras
  generar el PDF, comprueba que (a) el texto es texto seleccionable, no curvas
  (extrae texto del PDF con `pdftools::pdf_text()` y confirma que devuelve el
  índice, título y nota como cadenas reales); (b) las fuentes están incrustadas
  (`pdftools::pdf_fonts()` lista gobCL / Museo Sans con `embedded = TRUE`). Si
  alguna fuente NO está incrustada, repórtalo (en Affinity se sustituiría por otra
  y el usuario lo notaría).
- **Criterio:** PDF A0 vertical; `pdf_text()` devuelve el texto del índice/nota;
  `pdf_fonts()` muestra las fuentes incrustadas.

### Fase 4 — Verificar dimensiones y entregar
- Confirma con `pdftools::pdf_pagesize()` que la página es 841×1189 mm
  (≈ 2384×3370 pt; 1 mm = 2.8346 pt). Tolerancia ±1 mm.
- Render headless del PDF a PNG de control para inspección visual (mapas nítidos,
  texto legible, proporción correcta).
- Commits atómicos: feat(33) tamaño A0 + export PDF; build(afiche) HTML y PDF
  regenerados. **El PDF (puede pesar varios MB) NO se versiona si supera el umbral
  razonable**: agrégalo al `.gitignore` si pesa mucho (es un entregable, se
  regenera); decláralo en el log.

## 2.5 Criterios de éxito
1. PDF A0 vertical (841×1189 mm, verificado con `pdf_pagesize`).
2. Texto editable: `pdf_text()` devuelve índice/título/nota; fuentes incrustadas
   (`pdf_fonts` embedded=TRUE).
3. Mapas a resolución suficiente para A0 (≥150 dpi efectivos, sin pixelado).
4. Diseño v7 intacto (🔒-2): mismo contenido, solo mayor tamaño/resolución.

## 2.6 Auto-auditoría (panel adversarial)
(a) `pdf_pagesize` = A0 vertical (841×1189 mm ± 1 mm).
(b) `pdf_text` no vacío y contiene muestras del índice (p. ej. un nombre de
    establecimiento + su RBD) y la nota del Área de Monitoreo.
(c) `pdf_fonts`: las fuentes del afiche aparecen con embedded=TRUE.
(d) Resolución de los PNG de mapas: ancho en px / ancho físico en pulgadas ≥ 150.
(e) Diseño intacto: el HTML fuente sigue teniendo numeración N→S, 97 pines,
    etiquetas de comuna, anti-colisión (min_dist en la nueva resolución ≥ umbral
    escalado).

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_export_pdf_a0_log.md`: DPI_A0 usado y por
qué, dimensiones finales de los PNG, tamaño de página del PDF verificado, resultado
de `pdf_text`/`pdf_fonts` (texto editable + fuentes incrustadas), peso del PDF y si
se versionó o no, verificación de 🔒, pendientes, notas para Affinity (qué es
editable y qué es imagen). Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial (pagesize A0, pdf_text con muestras, pdf_fonts embedded,
dpi de mapas), confirmación visual (mapas nítidos a A0), ruta del PDF y del log, y
una nota clara para el usuario de qué podrá editar en Affinity (todo el texto) y
qué no (los dos mapas, que son imagen a alta resolución).
