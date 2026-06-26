# Log de cierre — Tile sin rótulos + etiquetas de comuna propias (v7)

> Encargo: `50_documentacion/andamios/encargo_claude_code_tile_etiquetas_v7.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, 3 cambios + panel adversarial.** Reancla el v5 sobre el v6. Log sin commitear.

---

## 1. Resumen

Tres cambios (lo que pedía el v5, reanclado sobre el v6 real):
1. **Tile sin rótulos**: provider `CartoDB.PositronNoLabels` (geografía sin texto horneado).
2. **Zonas de exclusión eliminadas** (ya no hay rótulos que esquivar); la **anti-colisión
   entre pines se mantiene intacta** (🔒-4).
3. **4 etiquetas de comuna propias**, azul institucional gobCL, tamaño único grande, en
   vacíos sin pines.

Todo el v6 (numeración N→S estricta, nota del Área de Monitoreo, índice a alto completo) se
conservó intacto.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `b89efb0` | feat(33) | Tile sin rótulos + elimina zonas de exclusión + etiquetas de comuna propias |
| `0319834` | build(afiche) | HTML regenerado |
| `c2a592a` | docs | CLAUDE.md |

Sin commitear (revisión): este log y `auditoria_afiche_tile_etiquetas.R`.

## 3. Provider de tile (Fase 1)

`maptiles::get_tiles(..., provider = "CartoDB.PositronNoLabels")`. Verificado que resuelve
(descarga tiles sin texto). Gate de Fase 1 superado. Los **bordes** comunales BCN
(`geom_path`) se mantienen: los dibuja el código, no el tile.

## 4. Zonas de exclusión eliminadas sin romper anti-colisión (Fase 2)

Se eliminaron `ZONAS_NORTE`, `ZONAS_VINA`, el helper `.zona` y el parámetro `Z` /rama de
obstáculos-zona de `separar_pines` y `dibujar_pines`. **La repulsión de discos entre pines
quedó intacta** (mismo bucle de separación 2D). Verificado: min_dist = **48,0 px ≥ 44**
(2·PIN_RADIO_PX) en ambos planos, igual que en v4/v6.

## 5. Etiquetas de comuna propias (Fase 3)

Constantes: `COLOR_COMUNA = "#0F69B4"` (azul institucional gobCL), `LABEL_COMUNA_FONT = 6.2`
(mm, único para las 4; mayor que el número de pin), familia gobCL. Se dibujan con `geom_text`
en `dibujar_pines` (`ETIQUETAS_COMUNA`, filtradas por panel).

**Posiciones (encargo → final afinada), lon/lat:**

| Comuna | Encargo | Final | Afinación |
|---|---|---|---|
| Puchuncaví | −71.522 / −32.747 | **−71.425 / −32.752** | al este ~0,10° (la sugerida caía sobre el clúster de Ventanas) |
| Quintero | −71.575 / −32.911 | **−71.520 / −32.860** | al este y norte (la sugerida se salía por el borde izquierdo) |
| Concón | −71.553 / −33.057 | **−71.515 / −32.945** | al norte ~0,11° (la sugerida caía **fuera del panel** por el sur) |
| Viña del Mar | −71.547 / −33.025 | **−71.573 / −33.010** | al oeste, a la franja de costa/bahía (la sugerida caía en el centro denso, lleno de pines tras la separación) |

**Anti-colisión etiqueta↔pin:** el panel adversarial verifica, por cada etiqueta, que ningún
centro de pin cae dentro de su bounding box (estimado por nº de caracteres y tamaño de
fuente) expandido por `PIN_RADIO_PX`. Resultado: **0 pines sobre cada una de las 4
etiquetas**. Confirmado también a ojo en los zooms.

## 6. Verificación de invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff 722d792..HEAD` de 31/32 vacío. |
| **🔒-2** v6 intacto | **PASA** | Audit: numeración N→S estricta (lat monótona, rangos 1-20/21-30/31-37/38-97), nota del Área de Monitoreo presente, índice 97 filas RBD+nombres sin truncar, límites BCN (4 comunas), color por tipo, inset Viña. |
| **🔒-3** Sin filtro por contención | **PASA** | El cambio es tile/etiquetas; no se introdujo filtro de polígono sobre los puntos. |
| **🔒-4** Anti-colisión entre pines | **PASA** | min_dist 48,0 px ≥ 44 en ambos planos tras quitar las zonas. |

## 7. Panel adversarial (independiente del 33)

`auditoria_afiche_tile_etiquetas.R`:

```
[PASA] tile: provider CartoDB.PositronNoLabels en el codigo
[PASA] zonas de exclusion eliminadas del codigo
[PASA] (c) norte: anti-colision min_dist=48.0 px >= 44 (intacta)
[PASA] (c) vina: anti-colision min_dist=48.0 px >= 44 (intacta)
[PASA] etiqueta: COLOR_COMUNA = #0F69B4 (azul gobCL) definido
[PASA] etiqueta: LABEL_COMUNA_FONT (tamaño unico) definido
[PASA] etiqueta: 4 comunas
[PASA] (b) 'Puchuncaví' sin pin sobre la etiqueta (pines en bbox+r: 0)
[PASA] (b) 'Quintero' sin pin sobre la etiqueta (pines en bbox+r: 0)
[PASA] (b) 'Concón' sin pin sobre la etiqueta (pines en bbox+r: 0)
[PASA] (b) 'Viña del Mar' sin pin sobre la etiqueta (pines en bbox+r: 0)
[PASA] (d) numeracion N->S estricta (lat monotona)
[PASA] (d) rangos por comuna 1-20/21-30/31-37/38-97
[PASA] (d) nota del Area de Monitoreo presente
[PASA] (d) indice 97 RBD+nombres sin truncar
[PASA] (d) limites BCN (4 comunas)
[PASA] (d) 97 filas en el indice
===== PANEL ADVERSARIAL v7: TODO PASA (0 fallas) =====
```

## 8. Confirmación visual

Render headless + zooms:
- **Tile sin texto horneado** (Maitencillo/Ventanas/Quintero/Concón/Viña ya no aparecen como
  rótulos del tile; solo geografía gris).
- **4 etiquetas de comuna grandes, azules**, en zonas despejadas, sin pin encima:
  Puchuncaví (inland este), Quintero (centro despejado), Concón (bajo su clúster),
  Viña del Mar (franja de la bahía).
- Anti-colisión de pines intacta; numeración N→S, nota e índice del v6 sin cambios.

> Nota: el chip de título del panel norte sigue diciendo "Puchuncaví · Quintero · Concón"
> (es el rótulo HTML del recuadro, distinto de las nuevas etiquetas de comuna en el mapa).

## 9. Pendientes y notas para el revisor

- **Validación in situ:** abrir `40_salidas/afiche/mapa_establecimientos.html` en navegador.
- **Posiciones de etiquetas atadas al layout actual** (bbox/zoom de cada panel y a la
  separación de pines). Si cambian márgenes, zoom o `PIN_RADIO_PX`, conviene revisar que las
  4 etiquetas sigan en vacíos (el panel adversarial lo chequea numéricamente). **# REVISAR**
  si se reescala.
- **"Puchuncaví" quedó en el inland este** (no sobre el pueblo costero) porque es la palabra
  más larga y el sector poblado está lleno de pines; es el vacío más amplio dentro de la
  comuna. Si se prefiere sobre el pueblo, habría que reducir `LABEL_COMUNA_FONT` o aceptar
  cercanía a pines. **# REVISAR** con el usuario.
- **Locale UTF-8** obligatorio; **red** solo para tiles CARTO (ahora la variante NoLabels).
- Honestidad: lo que más costó fue ubicar "Puchuncaví" y "Viña del Mar" sin pin encima —
  ambas son etiquetas anchas y sus zonas sugeridas estaban ocupadas por pines tras la
  separación; se resolvió moviéndolas al vacío inland (Puchuncaví) y a la bahía (Viña),
  validado numéricamente por el panel adversarial (bbox vs centros de pin).
