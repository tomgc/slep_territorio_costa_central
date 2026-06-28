# LOG — Sondeo visual A vs C (escala única, baja resolución)

- **Timestamp:** 2026-06-26
- **Naturaleza:** comparación visual para decisión del titular. NO es Fase 1. No se
  creó 33b definitivo; el script de sondeo vive en `scratchpad_afiche/` (gitignored).
- **Entorno:** R 4.5.2, `LANG/LC_ALL=en_US.UTF-8`.
- **Script:** `scratchpad_afiche/preview_A_vs_C.R` (reusa 33 vía `source(local=TRUE)`).

## Parámetros del render
```
ESC_PREVIEW = 1.40  (vs 5.34 de producción; mantiene proporción radio/panel 11/1520)
Dims A y C  = 1019 x 2128 px (cada PNG)
PIN_RADIO   = 15.4 px ; sep = 33.6 px ; PIN_FONT = 4.3 mm (igual que 33)
bbox/tile/zoom = escala única, 3857, CartoDB.PositronNoLabels, zoom 12 (idénticos A y C)
```

## Salidas
- `scratchpad_afiche/preview_A_in_situ.png` — Viña separar_pines, sin leaders/ancla.
- `scratchpad_afiche/preview_C_proxy_leader.png` — Viña proxy a bloque oriente 6×10 +
  leader line a punto-ancla, asignación por latitud (abanico).

## Hallazgos del panel adversarial
1. **¿A y C idénticas salvo Viña?** Sí. Mismo bbox, mismo tile, mismos límites y los 37
   pines del norte sobre su punto con la MISMA separación (`separar_pines` sobre los 37
   solos, idéntica en ambos paneles). Confirmado visualmente: los dos tercios superiores
   son indistinguibles. ✔
2. **¿Los cruces de C son coherentes con los ~53 de Fase 0?** Sí. Recuento en código sobre
   las posiciones de este render = **53** (idéntico a Fase 0). El render muestra la maraña
   de leaders correspondiente; no esconde ni inventa cruces. ✔
3. **¿33 byte-idéntico y sin regenerar entregables?** `git diff --stat 33` = vacío.
   `mapa_establecimientos.{html,pdf}` y `panel_*.png` conservan mtime 11:15 (no tocados);
   el render corrió a las ~17:52. → `source(local=TRUE)` NO ejecutó el flujo de 33. ✔
4. **¿ESC_preview distorsiona la densidad?** No. radio/panel = 11/1520, idéntico a 33
   (PIN_RADIO=11·ESC, Hpx=1520·ESC), y PIN_FONT en mm con res=72·ESC mantiene el tamaño
   físico del número. La densidad relativa es fiel; la comparación no es engañosa. ✔

## Estado de git al cierre
```
git diff --stat 30_procesamiento/33_generar_afiche.R  -> vacío (33 intacto)
Untracked: solo docs de andamios (reporte/logs); scratchpad_afiche/ gitignored.
Sin entregables nuevos en 40_salidas/.
```
