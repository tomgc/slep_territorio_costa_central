# Log de cierre — Pines grandes, sin solape, sin tapar nombres de ciudad (v4)

> Encargo: `50_documentacion/andamios/encargo_claude_code_pines_grandes_v4.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, todas las fases + panel adversarial.** Gate NO alcanzado. Log sin commitear.

---

## 1. Resumen

Tres cambios sobre el afiche, sin tocar nada más (🔒-2):
1. **Pines más grandes, tamaño y fuente únicos.** Pin circular de radio fijo en píxeles
   del PNG (mismo tamaño visual en ambos planos), dibujado como **círculo real en
   coordenadas de datos** (no `geom_point`, cuyo `size` en mm no garantiza el radio).
2. **Anti-colisión 2D real**: repulsión de discos en espacio de píxeles que **garantiza**
   distancia entre centros ≥ `2·PIN_RADIO_PX + PIN_GAP_PX`. Reemplaza el declustering leve.
3. **Zonas de exclusión** alrededor de los rótulos de ciudad horneados en el tile CARTO:
   tratadas como obstáculos fijos; ningún pin entra → ningún nombre de ciudad queda tapado.

Prioridad no-solape sobre posición exacta (decisión del usuario): el pin es marcador
aproximado, el dato exacto vive en el índice.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `eee6cb7` | feat(33) | Pines grandes + anti-colisión 2D garantizada + zonas de exclusión + gate |
| `bea594f` | build(afiche) | HTML regenerado |
| `7b4cec9` | docs | CLAUDE.md |

Sin commitear (revisión): este log y `auditoria_afiche_pines_grandes.R`.

## 3. Constantes usadas

| Constante | Valor | Significado |
|---|---|---|
| `PIN_RADIO_PX` | 22 | Radio del pin en px del PNG (Ø 44 px; antes ~13 px) |
| `PIN_GAP_PX` | 4 | Separación mínima visible entre bordes (→ sep centros = 48 px) |
| `PIN_FONT` | 4.3 | Tamaño único del número (geom_text, mm); antes 2.5/2.7 |

El radio se fija en px y se convierte a radio de datos por panel
(`rdat = PIN_RADIO_PX · Xr/Wpx`), de modo que el círculo dibujado mide exactamente
`PIN_RADIO_PX` y coincide con lo que verifica la anti-colisión. Tamaño visual idéntico en
ambos planos (mismo px ⁄ dpi).

## 4. Algoritmo de separación (y por qué)

Repulsión iterativa de discos en **espacio de píxeles del PNG** (no en grados ni metros):
el `size` de los pines es relativo al dispositivo, así que la única métrica que garantiza
no-solape visual es el píxel. En cada iteración: (1) para cada par a <2·R+gap, se empujan
ambos la mitad del solape en dirección opuesta; (2) cada pin dentro de una zona de
exclusión (±R) se expulsa al borde más cercano; (3) clamp al marco. Itera hasta que no hay
movimientos o 1200 iteraciones. Parte de la posición real y desplaza lo mínimo
(minimización implícita por el empuje proporcional al solape).

Se eligió repulsión propia (no `packcircles`/`ggrepel`) porque: necesitaba obstáculos
fijos (zonas) + clamp al marco + verificación numérica exacta, y la repulsión de discos es
trivial de auditar y determinista.

## 5. Zonas de exclusión (px del PNG, origen arriba-izquierda)

Calibradas inspeccionando el render (overlay de rectángulos rojos sobre el tile).
Formato: centro (cx,cy) ± (hw,hh).

**Panel norte** (1456×1888 px): Maitencillo (700,122,100,32) · Puchuncaví (815,588,105,34)
· Campiche (601,624,85,32) · Ventanas (441,681,95,32) · Quintero (233,941,95,32) ·
Concón (293,1735,78,32).
**Inset Viña** (1456×1120 px): Viña del Mar (492,618,182,78).

## 6. Distancia mínima y desplazamiento (antes/después)

| Plano | min_dist antes | min_dist después | requerido | desp. medio | desp. máx |
|---|---:|---:|---:|---:|---:|
| Norte (37) | 0,9 px | **48,0 px** | 44 px | 26 px | 71 px |
| Viña (60) | 0,5 px | **48,0 px** | 44 px | 23 px | 111 px |

Antes los pines estaban prácticamente encimados (0,5–0,9 px = densidad real de 5–17 m).
Después, todos los pares ≥ 48 px (> 44 = 2·PIN_RADIO). Verificado numéricamente.

## 7. Gate estratégico — NO alcanzado

Métricas que vigila el gate (en `dibujar_pines`, con `stop()` si se violan):
- **Pines fuera de marco:** 0 en ambos planos.
- **No-solape logrado:** sí (min_dist 48 ≥ 44).
- Desplazamiento máximo: 111 px (Viña) sobre 1456 px de ancho ≈ 7,6 %. El clúster
  Viña-centro se expandió de forma acotada, sin invadir media ciudad ni perder
  correspondencia geográfica. No fue necesario bajar `PIN_RADIO_PX` ni mini-inset.

## 8. Verificación de invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff ae7286f..HEAD` de 31/32 vacío. |
| **🔒-2** Todo lo demás intacto | **PASA** | Audit: numeración N→S 1..97, índice 97 RBD+nombres, límites BCN (24.224 vért.), sin etiquetas/leader lines, atribución BCN. Único cambio: dibujo de pines. |
| **🔒-3** Sin filtro por contención | **PASA** | La separación opera sobre posiciones proyectadas; no hay `st_within/filter`. Los 97 puntos se conservan. |
| **🔒-4** Numeración consistente tras reposicionar | **PASA** | Cada pin conserva su `num` (el círculo y el número se dibujan en la posición desplazada con el mismo `num`); audit cruza índice 1:1. |

## 9. Panel adversarial (independiente del 33)

`auditoria_afiche_pines_grandes.R` — re-implementa proyección y separación 2D (no hace
`source()` del 33) y verifica la propiedad sobre las posiciones re-derivadas:

```
[PASA] norte (37): min_dist=48.0 px >= 44 (2*PIN_RADIO)
[PASA] norte (37): 0 centros dentro de zonas de exclusion (0)
[PASA] vina (60): min_dist=48.0 px >= 44 (2*PIN_RADIO)
[PASA] vina (60): 0 centros dentro de zonas de exclusion (0)
[PASA] afiche: numeracion N->S 1..97 (rangos 1-20/21-30/31-37/38-97)
[PASA] afiche: indice con 97 RBD y 97 nombres completos
[PASA] afiche: sin etiquetas/leader lines en el mapa
[PASA] afiche: atribucion BCN presente
[PASA] afiche: limites BCN alta resolucion (4 comunas, 24224 vertices)
===== PANEL ADVERSARIAL v4: TODO PASA (0 fallas) =====
```

## 10. Confirmación visual

Render headless + zooms de Quintero, Concón, Ventanas/Campiche/Puchuncaví y Viña-centro:
- Pines y números **claramente más grandes** que antes.
- **Ningún par de pines se toca** en los clústeres.
- **"Quintero" (caso reportado), "Concón", "Ventanas", "Campiche", "Puchuncaví" y
  "VIÑA DEL MAR" quedan legibles**, con los pines dispuestos alrededor, sin tapar el texto.

## 11. Pendientes y notas para el revisor

- **Validación in situ:** abrir `40_salidas/afiche/mapa_establecimientos.html` en navegador.
- **Calibración de zonas atada al bbox/zoom:** las `ZONAS_*` están en px y son válidas para
  el bbox/zoom actual (deterministas). Si se cambian márgenes del bbox o el zoom de los
  tiles, hay que recalibrar las zonas (recomendado: re-correr el overlay de
  `scratchpad_afiche/dev_v4_zones*.R`). **# REVISAR** si se reescala el afiche.
- **`b3.rds`** (bbox por panel) lo usa solo el panel adversarial de scratch; el 33 lo
  recomputa. Si se versiona el audit, generar `b3` dentro de él.
- **Densidad de Viña:** con `PIN_RADIO_PX=22` el clúster centro se expandió ~111 px máx.
  Si el usuario quisiera pines aún mayores, podría acercarse al gate; el `stop()` lo avisará.
- **Locale UTF-8** obligatorio; **red** solo para tiles CARTO.
- Honestidad: lo que más costó fue calibrar las zonas de exclusión, porque el downscale del
  visor engaña en la posición exacta del texto; se resolvió con overlays de rectángulos
  rojos sobre el tile e iteración, y haciendo las cajas algo generosas (sobre-cubrir es
  inocuo para exclusión). La anti-colisión salió a la primera con PIN_RADIO_PX=22.
