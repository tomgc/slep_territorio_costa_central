# LOG — Fix etiquetas de comuna en 33b (escala única) · Opción 1: offset calibrado

- **Timestamp:** 2026-06-28
- **Defecto:** la etiqueta "Viña del Mar" (anclada por `e$etiquetas_pct` al centroide
  geográfico) caía sobre el cluster denso y tapaba el pin 56 (rozaba 55/58).
- **Solución:** capa aditiva `OFFSET_ETIQUETAS_PCT` en 33b (no toca 33 ni `e$etiquetas_pct`).
  Solo se reescriben HTML y PDF; el PNG de pines NO se regenera.

## Calibración (medida en código: cajas de texto vs los 97 círculos de pin, en px CSS del
contenedor 728×1520; r_pin=6.60 px, LABEL=17.6 px, halo=3 px)
- Solo **Viña** solapaba (clearance base **−6.6 px**). Las otras 3 ya despejadas:
  Puchuncaví +26.4, Quintero +58.2, Concón +13.0.
- **Puchuncaví NO se mueve:** el desplazamiento NW hacia la costa que pedía el encargo
  **choca con sus propios pines** (a −15%,−6.5% solaparía el pin 7 con −6.6 px). Su base ya
  es la mejor bolsa despejada (pin 15 a 26 px). Reportado como límite geométrico.
- **Viña → SW lo que permite el ancho del rótulo:** el rótulo mide 14.1% del ancho del panel,
  más que la franja de océano al poniente del cluster → W/SW puro no caben. Se baja bajo el
  cluster: **dx=−1.5, dy=+9.0** → final (7.9%, 88.7%).

### OFFSET_ETIQUETAS_PCT final
```r
OFFSET_ETIQUETAS_PCT <- list(
  "Puchuncaví"   = c(dx =  0.0, dy =  0.0),
  "Quintero"     = c(dx =  0.0, dy =  0.0),
  "Concón"       = c(dx =  0.0, dy =  0.0),
  "Viña del Mar" = c(dx = -1.5, dy =  9.0)
)
```

### Tabla de colisión (posición final, clearance al pin más cercano)
| Etiqueta | final (left%,top%) | clearance | pin más cercano | estado |
|---|---|---|---|---|
| Puchuncaví | (56.9, 32.5) | +26.4 px | #15 | OK |
| Quintero | (26.4, 52.2) | +58.2 px | #30 | OK |
| Concón | (28.0, 67.8) | +13.0 px | #34 | OK |
| **Viña del Mar** | (7.9, 88.7) | **+18.6 px** | #96 | OK (antes −6.6 sobre #56) |

Crops de verificación (scratchpad): `crop_ViadelMar.png` (Viña bajo pines 89/91/93/94/96,
sin solape), `crop_Puchuncav.png`, `crop_Quintero.png`, `crop_Concn.png`.

## Implementación en 33b
- Constante `OFFSET_ETIQUETAS_PCT` en la sección de overrides; aplicada tras
  `e$etiquetas_pct(...)` con clamp a [2,95]%. Las etiquetas siguen siendo TEXTO HTML.
- Añadido switch `REUSAR_PNG` (env, default FALSE): recalcula solo la geometría (b3 para las
  etiquetas) y **reutiliza** el PNG existente sin regenerarlo. Usado en esta corrida.

## Auto-auditoría adversarial
- **33/31/32/00_run_all/10_* byte-idénticos:** `git diff --stat` = vacío. ✔
- **Original `mapa_establecimientos.{html,pdf}`:** mtime **Jun 26 11:15** (intacto). ✔
- **PNG `panel_escala_unica.png` NO regenerado:** mtime **Jun 28 10:57:41** antes y después
  de esta corrida (REUSAR_PNG). ✔
- **Sin solape etiqueta-pin:** las 4 con clearance ≥ 0 (tabla). ✔
- **Etiquetas TEXTO en el PDF (extraíble) + fuentes 7/7:** confirmado. ✔
- **Render visual:** crops confirman que ninguna tarjeta pisa un pin. ✔

## Salidas regeneradas (en disco, gitignored)
- `mapa_establecimientos_escala_unica.html` (22:40), `…escala_unica.pdf` (22:41, A0).
- PNG reutilizado (no tocado).

## Estado de git: PENDIENTE OK del titular para commit/push.
```
Modificado (no commiteado): 30_procesamiento/33b_generar_afiche_escala_unica.R
Nuevo: 50_documentacion/andamios/logs/20260628_fix_etiquetas_33b_log.md
Salidas pesadas gitignored. 33/original intactos.
```
