# LOG — Sondeo visual D y E (variantes circulares de Viña, escala única)

- **Timestamp:** 2026-06-26
- **Naturaleza:** comparación visual para decisión del titular. NO es Fase 1. No se creó
  33b definitivo. Script y PNG en `scratchpad_afiche/` (gitignored).
- **Entorno:** R 4.5.2, `LANG/LC_ALL=en_US.UTF-8`.
- **Script:** `scratchpad_afiche/preview_D_vs_E.R` (reusa 33 vía `source(local=TRUE)`).

## Parámetros (idénticos al sondeo A/C, para comparar lado a lado)
```
ESC_PREVIEW = 1.40   Dims D y E = 1019 x 2128 px (cada PNG)
PIN_RADIO = 15.4 px  sep = 33.6 px  PIN_FONT = 4.3 mm
bbox/tile/zoom = escala única, 3857, PositronNoLabels z12 (idénticos a A y C)
Norte = 37 pines separados igual que en A/C (sobre su zona, sin cambio)
```

## Salidas
- `scratchpad_afiche/preview_D_arco_descarga.png` — Viña en arco (anillo) + leader radial.
- `scratchpad_afiche/preview_E_circulo_compacto.png` — Viña empaquetada en círculo compacto
  sobre el centroide real (separar_pines con frontera circular).

## Métricas (medidas en código)
- **D (arco):** cruces de leader = **96** (vs **53** de la grilla C). Desplazamiento medio
  = 151 px lienzo, máx = 191 px lienzo. Radio de arco R=278 px preview (clampeado para no
  salir del marco).
  → **El arco NO reduce cruces: los aumenta (96 > 53).** El anillo, además, asoma al
  poniente sobre el océano. La asignación por ángulo evita inversiones locales, pero como
  las anclas rodean el centroide en 360° y el arco solo cabe abierto al poniente con R
  reducido, las anclas del lado oeste cruzan el cluster. Variante dominada por C, A y E.
- **E (círculo compacto):** desplazamiento medio = 26 px lienzo (17.9 mm A0), máx = 69 px
  lienzo (47.1 mm A0). min_dist = 33.4 px ≥ 31 req (sin solape). fuera_marco = 0.
  min_dist a pines del norte = 204 px ≥ 34 sep → **SIN solape con el norte**.
  Discos que superarían el umbral de leader (>2·radio) = **37/60**.
  → Silueta circular limpia y legible; los leaders (cuando se dibujan por umbral) son
  cortos y quedan bajo la mancha, por lo que E se lee mejor SIN leaders. Costo: 37/60
  discos quedan a >2 radios de su ancla (hasta 47 mm en A0); más desplazamiento que el
  in-situ puro de A (≈12.5 px lienzo medio), a cambio de una forma intencional compacta.

### Tabla comparativa (Viña; resto idéntico)
| Variante | Cruces leader | Desp. medio (lienzo) | Desp. máx (lienzo) | Notas |
|---|---|---|---|---|
| A in situ | 0 | ~12.5 px | ~33 px | sin forma impuesta |
| C grilla 6×10 | 53 | 187 px | 332 px | descarga oriente |
| **D arco** | **96** | 151 px | 191 px | peor en cruces; asoma al océano |
| **E círculo compacto** | 0 visibles (37 >umbral) | 26 px | 69 px | mancha limpia, +desp que A |

## Hallazgos del panel adversarial
1. **¿D y E idénticas a A salvo Viña?** Sí: mismo bbox, tile, límites y los 37 pines del
   norte con la misma separación. Confirmado visual y en código. ✔
2. **¿El arco de D reduce cruces vs la grilla (53) o solo reordena?** **No reduce: 96 cruces
   medidos** (peor que 53). Reportado sin adornar. ✔
3. **¿La silueta de E mantiene 60 discos sin solape y sin salir del marco/norte?** Sí:
   min_dist 33.4 ≥ 31 (verificado con mindist), fuera_marco = 0, min_dist a norte 204 ≥ 34. ✔
4. **¿33 byte-idéntico y entregables no regenerados?** `git diff --stat 33` = vacío;
   `mapa_establecimientos.{html,pdf}` con mtime 11:15 (intactos), render ~18:58. ✔
5. **¿ESC_preview mantiene proporción de pin?** Sí: 11/1520 idéntico a 33; PIN_FONT mm con
   res=72·ESC. Comparación fiel a las tres imágenes previas. ✔

## Estado de git al cierre
```
git diff --stat 30_procesamiento/33_generar_afiche.R -> vacío (33 intacto)
Untracked: solo docs de andamios; scratchpad_afiche/ gitignored. Sin entregables nuevos.
```
