# LOG — Sondeo de tamaño de pin (escala única, Viña in situ)

- **Timestamp:** 2026-06-26
- **Naturaleza:** comparación visual para decisión del titular. NO es Fase 1. No se creó
  33b definitivo. Script y PNG en `scratchpad_afiche/` (gitignored).
- **Entorno:** R 4.5.2, `LANG/LC_ALL=en_US.UTF-8`.
- **Script:** `scratchpad_afiche/preview_tamano_pin.R` (reusa 33 vía `source(local=TRUE)`).

## Diseño del sondeo
- Panel único escala única, Viña **in situ puro** (separar_pines, sin leaders). Pin
  **global**: norte y Viña al MISMO radio en cada variante.
- Varía SOLO el radio (sobre PIN_RADIO prod = 11 px lienzo): T1=75%, T2=60%, T3=45%.
- **Fuente al máximo que cabe**: el ancho de "97" se fija en **0.72 × diámetro** del disco
  en las tres (NO proporcional al radio de producción). Medido con métrica de glifo
  (`grid::grobWidth` de "97" en gobCL Heavy) y resuelto el `size` de `geom_text` por
  variante. Ratio glifo/diámetro **alcanzado = 0.72 en T1/T2/T3** (verificado).
- Mismo bbox/proyección/tile (PositronNoLabels z12)/límites/ESC_PREVIEW=1.40, dims
  1019×2128 px, que los sondeos A/C/D/E.

## Métricas (medidas en código; mm a tamaño A0 real, ESC prod=5.34)
| Var | Radio (px lienzo / mm A0) | "97" ancho (mm A0) | ratio glifo/diám | min_dist vs req | desp medio / máx (mm A0) | % Viña <1 radio |
|---|---|---|---|---|---|---|
| **T1 75%** | 8.25 / 5.60 | 8.06 | 0.72 | 25.9 ≥ 23 | 4.1 / 13.5 | 65% |
| **T2 60%** | 6.60 / 4.48 | 6.45 | 0.72 | 21.3 ≥ 18 | 2.8 / 9.1 | 73% |
| **T3 45%** | 4.95 / 3.36 | 4.83 | 0.72 | 16.7 ≥ 14 | 1.7 / 6.0 | 78% |

`fuera_marco = 0` en las tres. (Referencia: producción = 11 px lienzo = 7.46 mm radio.)

## Lectura
- A menor radio: **menos congestión del cluster de Viña Y mayor fidelidad geográfica**
  (desplazamiento cae 4.1→1.7 mm medio; % de pines de Viña sobre su lugar real sube
  65→73→78%). El radio pequeño mejora ambos ejes a la vez.
- **Legibilidad del "97":** la fuente llena el 72% del disco en las tres (máximo fijado).
  - T1 (8 mm): número holgado, muy legible.
  - T2 (6.5 mm): legible, buen balance densidad/lectura; el cluster de Viña respira.
  - **T3 (4.8 mm): es el piso.** El "97" sigue cabiendo al 72% del disco pero a 4.8 mm en
    A0 los discos empiezan a leerse casi como puntos; legible de cerca, exigente a
    distancia de pared. No se rompe (cabe), pero es el límite práctico.
- **Juicio honesto:** T2 (60%) es el mejor balance; T1 si se prioriza lectura a distancia;
  T3 solo si se prioriza máxima fidelidad/mínima congestión aceptando números pequeños.

## Hallazgos del panel adversarial
1. **¿Las tres idénticas salvo el radio?** Sí: mismo bbox, tile, límites; el norte se
   reduce al mismo radio que Viña en cada variante (pin global). ✔
2. **¿Fuente al máximo o proporcional?** Al máximo: ratio glifo/diámetro = **0.72 fijo**
   en las tres (si fuese proporcional al radio de producción el "97" se vería mucho menor
   en T2/T3). Verificado por métrica de glifo. ✔
3. **¿"97" legible en T3?** Cabe al 72% del disco pero a 4.8 mm A0 es el **piso**: legible
   de cerca, pequeño a distancia. Reportado sin adornar. ✔
4. **¿33 byte-idéntico y entregables no regenerados?** `git diff --stat 33` = vacío;
   `mapa_establecimientos.{html,pdf}` con mtime 11:15 (intactos). ✔
5. **¿ESC_preview mantiene la relación radio/panel?** Sí: radio = frac·11·ESC; el tamaño
   físico A0 se deriva de px lienzo × 0.678 mm. Reporte fiel. ✔

## Estado de git al cierre
```
git diff --stat 30_procesamiento/33_generar_afiche.R -> vacío (33 intacto)
Untracked: solo docs de andamios; scratchpad_afiche/ gitignored. Sin entregables nuevos.
```
