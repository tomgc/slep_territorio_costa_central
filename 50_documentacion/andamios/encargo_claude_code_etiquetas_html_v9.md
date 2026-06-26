# Encargo autónomo — Etiquetas de comuna como texto HTML editable (no rasterizadas)

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 8, v9).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** las 4 etiquetas de comuna (Puchuncaví,
> Quintero, Concón, Viña del Mar) hoy se dibujan con `geom_text` DENTRO de los PNG
> de los mapas, por lo que en el PDF son imagen (no editables en Affinity).
> Convertirlas en **texto HTML posicionado sobre el mapa**, para que en el PDF
> sean texto editable. Todo lo demás del mapa sigue siendo imagen.

---

## Por qué este cambio

El usuario exportó el PDF A0 y comprobó que no puede editar los títulos de comuna
en Affinity Publisher. Causa: esas etiquetas las dibuja R con `geom_text` y quedan
rasterizadas dentro del PNG del panel. El índice/título/nota sí son editables
(texto HTML), pero las etiquetas de comuna no. Solución (Opción A elegida por el
usuario): sacarlas del PNG y ponerlas como **texto HTML absoluto sobre la imagen
del mapa**, conservando posición, color y tamaño. Beneficio extra: el usuario
podrá reposicionarlas a mano en Affinity (incluida "Puchuncaví", cuyo lugar quedó
pendiente).

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.
**Regla de detención:** un 🔒 se vería comprometido, o la conversión de
coordenadas no cuadra (las etiquetas HTML no caen sobre el punto correcto del
mapa) — en ese caso reporta el desajuste, no entregues etiquetas descolocadas.
**Reglas heredadas:** R-only para el render; el posicionamiento HTML es
CSS/HTML dentro del mismo `33`; `here::here()`, sin rutas absolutas, locale UTF-8,
commits atómicos.

---

## 2.2 Contexto

**Estado actual (v7/v8):** el `33_generar_afiche.R` dibuja las 4 etiquetas de
comuna con `geom_text` (constantes `ETIQUETAS_COMUNA`, `COLOR_COMUNA = #0F69B4`,
`LABEL_COMUNA_FONT = 6.2`) dentro de cada panel PNG. El HTML compone: panel norte
(PNG) + inset Viña (PNG) + índice + chrome. Exporta a PDF A0 con `chrome_print`.

**Posiciones finales actuales de las etiquetas (lon/lat, del log v7):**
- Puchuncaví: −71.425 / −32.752 (panel norte)
- Quintero: −71.520 / −32.860 (panel norte)
- Concón: −71.515 / −32.945 (panel norte)
- Viña del Mar: −71.573 / −33.010 (inset Viña)

**Rutas:** `30_procesamiento/33_generar_afiche.R`; salidas HTML y PDF en
`40_salidas/afiche/`.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Se conserva TODO el diseño v8: tile sin rótulos, numeración N→S
  estricta, nota del Área de Monitoreo, índice con número+nombre+RBD, límites BCN,
  pines grandes con anti-colisión, inset Viña, leyenda, export PDF A0, texto del
  índice/título/nota editable. **Este encargo SOLO cambia cómo se dibujan las 4
  etiquetas de comuna: de geom_text (PNG) a texto HTML sobre el mapa.**
- **🔒-3.** Las etiquetas HTML deben caer en la MISMA posición visual que tienen
  ahora (mismo punto del mapa), con el MISMO color (#0F69B4), tamaño grande y
  fuente gobCL. No es un rediseño, es un cambio de capa (raster → HTML).
- **🔒-4.** Los pines, números, límites y todo lo demás del mapa siguen en el PNG
  (siguen siendo imagen). Solo las 4 etiquetas de comuna salen del PNG.

---

## 2.4 Fases

### Fase 0 — Lectura del estado real
- Lee `33_generar_afiche.R`. Localiza: el `geom_text` de `ETIQUETAS_COMUNA` en
  `dibujar_pines` (o donde esté), el bbox/extent que usa cada panel para proyectar
  (lo necesitas para la conversión), y el bloque HTML que compone cada panel
  (el `<img>`/contenedor del PNG).

### Fase 1 — Quitar las etiquetas del render PNG
- Elimina el `geom_text` que dibuja las 4 etiquetas de comuna dentro de los
  paneles. Los PNG se regeneran SIN esas etiquetas (pines, límites, tile intactos).
- Conserva las constantes de posición/color/tamaño (`ETIQUETAS_COMUNA`,
  `COLOR_COMUNA`, `LABEL_COMUNA_FONT`): se reutilizan en Fase 2.

### Fase 2 — Posicionar las etiquetas como texto HTML sobre el mapa
- Cada panel se muestra en el HTML como una imagen dentro de un contenedor. Envuelve
  cada panel en un contenedor `position: relative` y coloca, encima, las etiquetas
  de comuna como `<span>`/`<div>` con `position: absolute`.
- **Conversión coordenada → posición CSS** (determinista; calcúlala en R y
  escríbela en el HTML, o pásala como % al CSS):
  - `x% = (lon − bbox_oeste) / (bbox_este − bbox_oeste) × 100`
  - `y% = (bbox_norte − lat) / (bbox_norte − bbox_sur) × 100`
  donde el bbox es el extent real del panel (el MISMO que usa el render para
  proyectar; derívalo del objeto de tiles/proyección, no lo inventes). Aplica
  `transform: translate(-50%,-50%)` para centrar la etiqueta en el punto.
  - Panel norte: Puchuncaví, Quintero, Concón con sus lon/lat.
  - Inset Viña: Viña del Mar con su lon/lat, usando el bbox del inset.
- **Estilo:** color `#0F69B4`, font-family gobCL (ya embebida como @font-face en el
  HTML), tamaño grande equivalente al actual `LABEL_COMUNA_FONT` (conviértelo a px/
  pt para A0; que se vea del mismo tamaño visual que ahora), peso bold, sin fondo o
  con halo blanco sutil (`text-shadow`) para legibilidad sobre el mapa.
- **Criterio de éxito:** las 4 etiquetas aparecen en la misma posición visual que
  antes, mismo color y tamaño, pero ahora son texto HTML (no parte del PNG).

### Fase 3 — Regenerar HTML + PDF y verificar editabilidad
- `run_all(from=1,to=3)` para regenerar PNG (sin etiquetas) y HTML (con etiquetas
  HTML). Re-exporta el PDF A0 con `chrome_print`.
- **Verificación (el objetivo del usuario):** en el PDF, las 4 etiquetas de comuna
  ahora deben ser texto extraíble. Comprueba con `pdftools::pdf_text()` que
  "Puchuncaví", "Quintero", "Concón", "Viña del Mar" aparecen como texto del
  documento (además de en el índice). Confirma que su posición visual sobre el mapa
  es la correcta (render del PDF a PNG, inspección).
- Commits atómicos.

## 2.5 Criterios de éxito
1. Las 4 etiquetas de comuna son texto HTML/PDF editable (no parte del PNG).
2. Caen en la misma posición visual sobre el mapa, mismo color #0F69B4, tamaño
   grande, fuente gobCL.
3. Pines, números, límites y todo lo demás del mapa siguen en el PNG (imagen).
4. Todo el resto del afiche v8 intacto (🔒-2): numeración N→S, índice, nota, PDF A0
   con texto editable, fuentes incrustadas.

## 2.6 Auto-auditoría (panel adversarial)
(a) En el HTML, las 4 etiquetas de comuna están como elementos de texto
    (`position:absolute`), NO dentro del PNG (el PNG ya no las contiene: verifica
    que el `geom_text` se eliminó del render).
(b) En el PDF, `pdf_text()` contiene las 4 etiquetas como texto.
(c) Posición: las coordenadas % calculadas corresponden a las lon/lat correctas
    (recalcula y compara).
(d) Resto intacto: numeración N→S, 97 pines con anti-colisión, índice 97 RBD+
    nombres, nota del Área de Monitoreo, PDF A0 (841×1189 mm), fuentes incrustadas.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_etiquetas_html_log.md`: cómo se hizo la
conversión coordenada→CSS (bbox usado por panel, fórmula, % resultante por
etiqueta), confirmación de que el geom_text se eliminó del PNG, verificación de que
las etiquetas son texto en el PDF, verificación de 🔒, pendientes, notas para
Affinity (ahora las 4 etiquetas se pueden mover/editar). Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial (etiquetas como texto en HTML y PDF, posición correcta,
resto intacto), confirmación visual (4 etiquetas bien ubicadas sobre el mapa),
ruta del PDF y del log, y nota al usuario: ahora puede editar y reposicionar las 4
etiquetas de comuna en Affinity (incluida Puchuncaví).
