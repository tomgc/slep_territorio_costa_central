# Log de cierre — Afiche simplificado (pines numerados, sin etiquetas)

> Encargo: `50_documentacion/andamios/encargo_claude_code_afiche_v2_simplificado.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, todas las fases + panel adversarial.** Log sin commitear (revisión previa).

---

## 1. Resumen

**Poda** del `33_generar_afiche.R` (no reescritura). El mapa principal pasó de *paradigma D*
(etiquetas al mar + leader lines) a **solo pines numerados** sobre CARTO Positron, con los
**límites comunales dibujados**. Se conservaron numeración N→S, inset de Viña, índice y
autocontención. Al índice se le agregó el **RBD** y se aplicaron los colores de pin del
encargo v2. El usuario colocará los nombres sobre el mapa a mano.

Se genera de cero con `run_all(from = 1, to = 3)` en ~6–13 s (según descarga de tiles).

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `868cd65` | feat(33) | Poda a afiche simplificado: pines numerados, sin etiquetas; límites comunales; RBD e índice; colores v2 |
| `8b76c51` | build(afiche) | HTML regenerado (37 + 60 = 97 pines, 4 límites, índice con RBD) |
| `d82f367` | docs | CLAUDE.md actualizado con la poda v2 |

Sin commitear (para revisión): este log y `auditoria_afiche_simplificado.R`. Lo demás no
commiteado es de sesiones previas (estructura, traspaso, bocetos, encargos).

## 3. Qué se podó (con causa)

Causa raíz común: el encargo v2 simplifica deliberadamente el mapa para que el titular
ponga los nombres a mano; toda la maquinaria de etiquetado automático sobra.

Eliminado del render del panel norte:
- **Etiquetas al mar** (columna oceánica `geom_label` + `x_sea` + anti-colisión 1D `gap`/`y_et`).
- **Etiquetas en tierra** (`ggrepel::geom_label_repel`).
- **Leader lines** (`geom_segment`).
- **Cálculo de apretado** (vecino más cercano en UTM 19S, `UMBRAL_APRETADO_M = 450`).
- Constantes/funciones huérfanas: `COL_LEADER`, `COL_TINTA`, `BUFFER_VISUAL_DEG`,
  `wrap_nombre()`, e import muerto `library(ggrepel)` + su entrada en `instalar_si_falta`.

Agregado:
- `cargar_comunas()` + `comuna_paths()` → contornos comunales (`geom_path`, gris `#7a7a7a`,
  lw 0.5, alpha 0.85) en ambos planos.
- `COLOR_TIPO` (colores de pin v2) usado por pines, índice y leyenda.
- RBD en `fila_indice` (número + nombre + `(RBD …)`).
- bbox del panel norte recentrado (margen simétrico, sin reservar franja oceánica;
  `fit_bbox_3857(..., grow_west = FALSE)`).

## 4. Verificación de los 6 invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff 421c2b9..HEAD` de 31/32 vacío. La poda es solo sobre 33. |
| **🔒-2** Numeración N→S intacta | **PASA** | `numerar()` sin cambios; audit: rangos 1-20/21-30/31-37/38-97, sin huecos; mapa/inset/índice usan el mismo `num`. |
| **🔒-3** No filtrar por contención en polígono | **PASA** | Audit: «el 33 NO filtra (grep sin `st_within/contains/intersection/join`)». `comuna_paths()` solo dibuja contornos, no filtra puntos. Partición 37+60=97. |
| **🔒-4** Viña en inset con zoom | **PASA** | `render_panel_vina()` (zoom 13), 60 pines numerados; no se dispersan en el plano principal. |
| **🔒-5** Índice con número + nombre + RBD, sin truncar | **PASA** | Audit: 97 RBD presentes (97/97), 97 nombres completos (97/97), índice 1:1 num→(nombre,RBD) vs maestro independiente (97/97). |
| **🔒-6** HTML autocontenido | **PASA** | PNGs en base64, fuentes/CSS embebidos; 0 referencias de red en el HTML. |

## 5. Límites comunales — confirmación visual

Render headless (pagedown/Chrome) a 1240×1754 @2× y zoom a la franja costera. Confirmado a
ojo: los **3 contornos del panel norte** (Puchuncaví, Quintero, Concón) y el **contorno de
Viña en el inset** se distinguen como línea gris sutil sobre el CARTO, sin tapar calles.
(El geojson está generalizado: los contornos no calzan al pixel con la costa de CARTO, pero
delimitan las comunas con claridad.)

## 6. Panel adversarial (independiente del 33)

`auditoria_afiche_simplificado.R` — re-deriva desde el maestro crudo, no hace `source()` del 33:

```
[PASA] numeracion 1..97 sin huecos ni duplicados
[PASA] rangos por comuna = 1-20 / 21-30 / 31-37 / 38-97
[PASA] el 33 NO filtra puntos por contencion en poligono (🔒-3)
[PASA] particion render: norte=37 + vina=60 = 97 (sin perdidas)
[PASA] los 97 RBD aparecen en el HTML (97/97)
[PASA] los 97 nombres completos aparecen en el HTML (97/97)
[PASA] el indice tiene 97 filas num+nombre+RBD (encontradas=97)
[PASA] indice 1:1 num->(nombre,RBD) vs maestro independiente (97/97)
[PASA] poda efectiva: sin constructos de etiqueta/linea en el 33 (ninguno)
===== PANEL ADVERSARIAL v2: TODO PASA (0 fallas) =====
```

Check (d) «poda efectiva»: se verifica en el código (el mapa es PNG, no SVG grepeable) que
no quedan `geom_label/geom_text_repel/geom_label_repel/geom_segment` ni la lógica
`x_sea/apretado/UMBRAL_APRETADO/y_et`. El único texto en el mapa es el número del pin.

## 7. Pendientes y notas para el revisor

- **Validación in situ:** abrir `40_salidas/afiche/mapa_establecimientos.html` en navegador.
  Mi verificación fue por captura headless.
- **Espacio inland (este) en el panel norte:** al incluir los establecimientos rurales del
  este (p. ej. Pucalán, La Laguna) y ajustar al aspect del slot, el mapa muestra bastante
  territorio interior con pocos pines. Es geográficamente honesto y los contornos comunales
  lo llenan de contexto; si se prefiere más zoom a la franja costera, recortar el bbox
  (a costa de sacar del marco esos pines del este). **# REVISAR** con el titular.
- **Colores v2 locales:** `COLOR_TIPO` vive en el 33 (no en `10_configuracion.R$TIPOS$color`,
  que quedó sin uso). Si se quiere palette única, mover a configuración. **# REVISAR**.
- **Locale UTF-8 obligatorio** para correr el pipeline (mapeo de tipos con tilde en 31).
- **Red** en la primera corrida (tiles CARTO; `maptiles` cachea en `tempdir()`, no persiste).
- Honestidad: lo más caro fue el check (d) del panel adversarial, que primero marcó FALLA
  por `ggrepel`/`leader` residuales — eran un import muerto y comentarios; se limpió el
  import y se acotó el check a constructos de código. Buen recordatorio de que «poda» incluye
  los imports, no solo las llamadas.
