# Log de cierre — Etiquetas de comuna como texto HTML editable (v9)

> Encargo: `50_documentacion/andamios/encargo_claude_code_etiquetas_html_v9.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, todas las fases + panel adversarial.** Log sin commitear.

---

## 1. Resumen

Las 4 etiquetas de comuna (Puchuncaví, Quintero, Concón, Viña del Mar) se dibujaban con
`geom_text` DENTRO de los PNG de los mapas → en el PDF eran imagen (no editables). **Opción A:**
se sacaron del PNG y se posicionaron como **texto HTML `position:absolute`** sobre cada panel.
Ahora en el PDF A0 son **texto extraíble/editable** (y reposicionable a mano en Affinity).
Todo lo demás del mapa (pines, números, límites, tile) sigue siendo imagen.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `95e127d` | feat(33) | Etiquetas de comuna de `geom_text` (PNG) a texto HTML absoluto sobre el mapa |
| `48ecfea` | build(afiche) | HTML regenerado (PNG sin etiquetas + etiquetas HTML) + PDF |
| `c0002ba` | docs | CLAUDE.md |

Sin commitear (revisión): este log y `auditoria_afiche_etiquetas_html.R`. PDF gitignored.

## 3. Conversión coordenada → posición CSS

Cada panel se renderiza con `coord_equal` en **EPSG:3857** (Web Mercator) sobre su bbox `b3`.
Para que el texto HTML caiga EXACTO donde el render ubica el punto, se convierte lon/lat al
**mismo 3857** (no lon/lat lineal, que en latitud difiere del Mercator) y luego a %:

```
(X,Y) = proyectar(lon, lat) a 3857
left% = (X − b3_oeste)  / (b3_este − b3_oeste)  × 100
top%  = (b3_norte − Y)  / (b3_norte − b3_sur)   × 100      # y invertido (norte = arriba)
```

`b3` es el extent real que usa el render (derivado del bbox de cada panel, no inventado). En
el HTML cada etiqueta es un `<div position:absolute; left:%; top:%; transform:translate(-50%,
-50%)>` dentro del contenedor `position:relative` del panel (el `<img>` llena el contenedor con
`object-fit:cover` y el PNG tiene la misma proporción que el slot, así que el % calza 1:1).

**% resultante por etiqueta** (verificado contra recomputación: máx. diferencia 0.005 %):

| Etiqueta | Panel | lon / lat | left % | top % |
|---|---|---|---:|---:|
| Puchuncaví | norte | −71.425 / −32.752 | 50.0 | 40.6 |
| Quintero | norte | −71.520 / −32.860 | 18.8 | 73.2 |
| Concón | norte | −71.515 / −32.945 | 20.4 | 98.8 |
| Viña del Mar | inset | −71.573 / −33.010 | 26.4 | 42.3 |

(Concón queda a 98.8 % = junto al borde inferior del panel, como con el `geom_text` anterior;
visible sin recorte. Es la posición que el usuario podrá reacomodar en Affinity si quiere.)

## 4. Estilo de las etiquetas HTML

- Color `#0F69B4` (azul gobCL, mismo `COLOR_COMUNA`).
- `font-family:'gobCL'` (ya embebida como `@font-face` en el HTML), `font-weight:900` (Heavy).
- `font-size: LABEL_COMUNA_PX = LABEL_COMUNA_FONT × 72.27/25.4 ≈ 17.6 px` — equivalente visual
  exacto al `geom_text size=6.2 mm` anterior (size mm × .pt → pt; al mostrarse el PNG a escala
  y aplicar el `zoom` del afiche, el tamaño físico en A0 coincide).
- `text-shadow` blanco (halo sutil) para legibilidad sobre el mapa; `pointer-events:none`.

## 5. geom_text eliminado del PNG

Se quitó la capa `geom_text(data = et, aes(..., label = nom), color = COLOR_COMUNA, ...)` de
`dibujar_pines`. Verificado en el código (audit): no queda `geom_text(data = et` ni
`label = nom`; el único `geom_text` que persiste es el de los **números de pin** (sigue en el
PNG, como debe). Los PNG se regeneraron sin las etiquetas.

## 6. Verificación de invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff f7e69d7..HEAD` de 31/32 vacío. |
| **🔒-2** Diseño v8 intacto | **PASA** | Audit: PDF A0 (841×1189 mm), fuentes embedded, numeración N→S, índice 97 RBD+nombres, nota del Área de Monitoreo, tile sin rótulos, anti-colisión 128 ≥ 117. |
| **🔒-3** Misma posición/color/tamaño | **PASA** | Posiciones recomputadas = HTML (máx 0.005 %); color #0F69B4; tamaño px equivalente al geom_text; fuente gobCL. |
| **🔒-4** Resto del mapa sigue en el PNG | **PASA** | Solo se quitó el geom_text de etiquetas; pines, números, límites, tile siguen rasterizados. |

## 7. Panel adversarial (independiente del 33)

`auditoria_afiche_etiquetas_html.R`:

```
[PASA] (a) 4 etiquetas de comuna como texto HTML absoluto: Puchuncaví, Quintero, Concón, Viña del Mar
[PASA] (a) geom_text de etiquetas de comuna eliminado del PNG (ya no se rasteriza)
[PASA] (a) mecanismo HTML (etiquetas_pct + etiquetas_html) presente
[PASA] (b) las 4 etiquetas de comuna aparecen como texto en el PDF
[PASA] (b) el HTML aporta las 4 etiquetas como texto (no parte del PNG)
[PASA] (c) posiciones HTML = recomputadas desde lon/lat (max dif 0.005 %)
[PASA] (d) PDF A0 (841x1189 mm) / fuentes incrustadas / N->S / indice 97 / nota / tile sin rotulos
[PASA] (d) norte+vina anti-colision min_dist=128>=117
===== PANEL ADVERSARIAL v9: TODO PASA (0 fallas) =====
```

## 8. Confirmación visual

Render del PDF a PNG: las 4 etiquetas azules aparecen sobre los mapas en la misma posición
que en v8 (Puchuncaví centro-este del panel norte, Quintero centro, Concón abajo, Viña del Mar
sobre la bahía del inset), ahora como texto. `pdf_text` cuenta 5 ocurrencias de cada nombre
(subtítulo + chip de panel + encabezado de índice + un establecimiento que lo menciona + **la
nueva etiqueta de mapa**); el +1 respecto al chrome es la etiqueta HTML del mapa.

## 9. Notas para Affinity y pendientes

- **Ahora editable en Affinity:** además del título/índice/leyenda/nota, **las 4 etiquetas de
  comuna** son texto (se pueden mover, retipografiar, recolorear). En particular "Puchuncaví",
  cuyo lugar quedó pendiente, ya se puede arrastrar a gusto.
- **Sigue siendo imagen (no editable):** el resto de cada mapa — fondo CARTO, límites
  comunales, **pines y sus números**. Para moverlos hay que regenerar el afiche.
- **Validación in situ:** abrir el PDF en Affinity y confirmar que las 4 etiquetas se
  seleccionan como texto y que la fuente (gobCL) no se sustituye.
- **Render de control del PDF:** `pdf_render_page` a dpi alto (≥110) sobre A0 puede agotar
  memoria; usar dpi ≤ 60 para thumbnails (no afecta al PDF entregable, solo a la inspección).
- **Locale UTF-8** obligatorio; **Chrome** para `chrome_print`.
- Honestidad: salió directo. El único cuidado fue usar la proyección 3857 (no lon/lat lineal)
  en la conversión a %, para que las etiquetas calcen exactamente con el render; la
  verificación independiente dio 0.005 % de diferencia (esencialmente exacto).
