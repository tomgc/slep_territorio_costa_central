# Log de cierre — Numeración N→S estricta + nota de fuente + índice ajustado (v6)

> Encargo: `50_documentacion/andamios/encargo_claude_code_numeracion_ns_v6.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, 3 cambios + panel adversarial.** Log sin commitear (revisión previa).

---

## 1. Resumen

Tres cambios sobre el afiche:
1. **Numeración 1-97 estrictamente por latitud N→S** (más al norte = 1), sin agrupar por
   tipo. El número pasa a ser geográfico puro; el tipo solo define el color del pin.
2. **Nota de fuente** reemplazada por el texto exacto del usuario (Área de Monitoreo).
3. **Índice** redistribuido para llenar el alto disponible (sin hueco antes de la firma) con
   fuente ligeramente mayor, sin truncar.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `dc508e2` | feat(33) | Numeración N→S estricta + nota nueva + índice a alto completo |
| `cbee299` | build(afiche) | HTML regenerado |
| `722d792` | docs | CLAUDE.md |

Sin commitear (revisión): este log y `auditoria_afiche_numeracion_ns.R`.

## 3. Criterio de orden nuevo (Fase 1)

`arrange(desc(latitud), desc(longitud), nombre)` → `num = row_number()`. El tipo ya **no**
participa en el orden (antes era comuna→tipo→nombre). Verificado en `numerar()` con
`stopifnot`:
- `diff(latitud) <= 0` (latitud monótona decreciente).
- 1..97 sin huecos ni duplicados.
- **Rangos por comuna mantenidos** (las comunas no se solapan en latitud):
  Puchuncaví 1-20 · Quintero 21-30 · Concón 31-37 · Viña 38-97.
- **Puchuncaví 1-20 == `PUCHUNCAVI_REF`** (la lista del encargo), calza exacto.

## 4. Nota de fuente (Fase 2)

Texto nuevo (literal): *"Desarrollado por el Área de Monitoreo a partir de datos de
OpenStreetMap, CARTO (Positron), los límites comunales publicados por la Biblioteca del
Congreso Nacional de Chile (BCN) y el maestro de establecimientos del SLEP Costa Central,
de elaboración propia."* Verificado: nuevo presente, viejo ausente. Estilo conservado
(pie, 9px, color tenue).

## 5. Índice: alto completo + fuente (Fase 3)

| Parámetro | Antes (v5) | Después (v6) |
|---|---|---|
| Fuente fila (núm/nombre/RBD) | 10 px | **`INDICE_FONT` = 10,3 px** |
| Encabezado de comuna | 12,5 px | **`INDICE_FONT_HDR` = 13 px** |
| Distribución vertical | flujo normal (hueco abajo) | `display:flex; justify-content:space-between` (llena el alto) |

Para llenar el alto sin hueco se usó `space-between` en el contenedor del índice (reparte el
sobrante entre las 4 secciones). Para ganar alto y subir la fuente: intro acortado a una
línea y padding del aside 18→14 px.

**Tope de fuente por no-overflow:** las secciones de 1 columna (Puchuncaví 20 + Quintero 10
+ Concón 7 = 37 filas apiladas) son el límite de alto. Probé 11,5 / 11 / 10,5 px: **todas
desbordaban** y `overflow:hidden` recortaba las últimas entradas de Viña (58-67 / 88-97) —
inaceptable (perder filas). **10,3 px es el máximo que muestra los 97 sin recorte**
(verificado a ojo: filas 66 y 97 completas con espacio antes de la nota). Es "ligeramente
mayor" que 10; el llenado del alto lo aporta `space-between`, no una fuente más grande.

## 6. Verificación de invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff 7b4cec9..HEAD` de 31/32 vacío. |
| **🔒-2** Conservar el resto | **PASA** (con matiz, ver §8) | Audit: anti-colisión min_dist 48 ≥ 44 (ambos planos), índice 97 RBD+nombres sin truncar, límites BCN (4 comunas), sin etiquetas/leader lines, color por tipo, inset Viña. |
| **🔒-3** Sin filtro por contención | **PASA** | El cambio es de orden/estilo; no se tocó la ubicación ni se introdujo filtro de polígono. |
| **🔒-4** Numeración consistente mapa/inset/índice | **PASA** | Mapa, inset e índice consumen el mismo `est$num`; audit: índice num→nombre 1:1 con la numeración geográfica (97/97). El mapa muestra 1 al norte → 97 al sur. |

## 7. Panel adversarial (independiente del 33)

`auditoria_afiche_numeracion_ns.R`:

```
[PASA] numeracion estricta: lat[i] >= lat[i+1] para todo i
[PASA] 1..97 sin huecos ni duplicados
[PASA] rangos por comuna 1-20/21-30/31-37/38-97 (se mantienen)
[PASA] Puchuncaví 1-20 = referencia del encargo
[PASA] indice: 97 filas num+nombre+RBD (97)
[PASA] indice num->nombre 1:1 con numeracion geografica (97/97)
[PASA] nota: texto NUEVO presente literal
[PASA] nota: texto VIEJO ausente
[PASA] norte: anti-colision min_dist=48.0 px >= 44
[PASA] vina: anti-colision min_dist=48.0 px >= 44
[PASA] indice: 97 RBD y 97 nombres completos (sin truncar)
[PASA] limites BCN: 4 comunas en el geojson
[PASA] afiche: sin etiquetas de establecimiento ni leader lines
===== PANEL ADVERSARIAL v6: TODO PASA (0 fallas) =====
```

## 8. Discrepancia importante (estado "v5" del encargo)

El encargo v6 describe el **estado actual como "v5": "tile sin rótulos, etiquetas de comuna
propias"**. **Eso no coincide con el afiche real.** En esta sesión se ejecutaron v1, v2,
v3.1 y v4; **no hubo un v5**. El afiche actual (v4):
- usa `provider = "CartoDB.Positron"` — tile **CON** rótulos de ciudad horneados (por eso
  existen las **zonas de exclusión** de v4, que evitan que los pines los tapen);
- dibuja **bordes** comunales (`geom_path`), **no** "etiquetas de comuna propias"; los
  nombres de comuna que se ven los pone el tile.

Los 3 cambios de v6 (numeración, nota, índice) son **independientes** de la fuente de los
rótulos, así que se implementaron sin problema y se conservó el estado real. **No se
"convirtió" el tile a sin-rótulos ni se agregaron etiquetas propias**, porque eso no estaba
pedido en v6 (sería otro encargo). **# REVISAR con el usuario:** si lo que se quería era un
tile sin rótulos + etiquetas de comuna dibujadas por código (lo que el encargo asume como
ya hecho), es un cambio aparte por definir.

## 9. Pendientes y notas para el revisor

- **Validación in situ:** abrir `40_salidas/afiche/mapa_establecimientos.html` en navegador.
- **Fuente del índice acotada a 10,3 px** por no-overflow con las secciones de 1 columna. Si
  se quisiera una fuente notoriamente mayor, habría que dar 2 columnas también a Puchuncaví
  (20) — reduce el alto del stack y libera espacio — pero el encargo solo pidió 2 columnas
  para Viña; **# REVISAR** si se desea.
- **Locale UTF-8** obligatorio; **red** solo para tiles CARTO.
- Honestidad: lo que más costó fue calibrar la fuente del índice — varios intentos (11,5 /
  11 / 10,5) desbordaban y recortaban filas de Viña; el límite real es 10,3 px. El llenado
  del alto se logró con `space-between`, no con una fuente grande. La numeración y la nota
  salieron directas.
