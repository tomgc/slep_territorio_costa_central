# LOG — Reorganización scratchpad_afiche/ · FASE A (diagnóstico, sin mover nada)

- **Timestamp:** 2026-06-28
- **Naturaleza:** diagnóstico y propuesta de mapeo. NO se movió ni borró ningún archivo.
  Compuerta: tabla revisada por el titular ANTES de Fase B (DRY_RUN).
- **Entorno:** working tree limpio salvo docs de andamios (untracked).

## Inventario
- `scratchpad_afiche/` = **83 archivos** (63 png, 19 R, 1 rds), carpeta plana.
- Tamaño total ≈ 42 MB. Reparto por destino propuesto: 01 ≈ 20.1 MB · 02 ≈ 3.0 MB ·
  03 ≈ 2.1 MB · _archivo ≈ 17 MB · pipeline 4 KB.

## Lectura de los dos scripts mandados (LEÍDOS, no juzgados por nombre)

### preparar_bcn.R → **RECOMENDACIÓN: RESCATAR A PIPELINE** (ejecución diferida)
- Qué hace: lee `20_insumos/comunas_bcn/comunas.shp` (BCN crudo), filtra las 4 comunas,
  `st_make_valid`, mide solape entre pares, reproyecta a 4326, simplifica si > 3.5 MB, y
  **escribe `20_insumos/comunas.geojson`** — que ES el insumo que consume `33` vía
  `cargar_comunas()`. Cierra con verificación (relee y cuenta vértices).
- Juicio: **código reproducible que el producto necesita** (genera un insumo del pipeline),
  no andamiaje de un solo uso. Documenta cómo se produjo `comunas.geojson`.
- Destino recomendado: `30_procesamiento/30_preparar_comunas.R` (prefijo 30, corre antes
  de 31). Alternativa válida: rango 20 por ser preparación de insumo; el titular decide.
- **Caveats (importantes):**
  1. El insumo crudo `comunas_bcn/` está **gitignored** (sesión 5) y presente solo local →
     reproducible en esta máquina, NO desde un clon limpio. El `.geojson` resultante SÍ está
     versionado.
  2. Integrarlo a `00_run_all.R` requeriría tocar el orquestador (🔒 este encargo). El
     rescate efectivo es una tarea aparte; aquí solo se recomienda y se difiere.

### dev_render.R → **RECOMENDACIÓN: EXPLORACIÓN 01 (archivo histórico), NO pipeline**
- Qué hace: header propio dice *"Desarrollo iterativo del render cartográfico (scratch).
  No es entregable."* Usa enfoque SUPERADO: `CartoDB.Positron` (CON rótulos; v7 cambió a
  PositronNoLabels), numeración por `comuna_f/tipo_f` (NO la N→S estricta por latitud,
  oficial v6), etiquetas ggrepel al mar + leader lines. Escribe `panel_norte.png`,
  `zoom_top.png`, `zoom_bottom.png` en scratchpad.
- Juicio: **andamiaje de un solo uso**, enteramente superado por `33`. Valor de evidencia
  histórica del afiche original → exploración 01. No reproducible-necesario.

## Tabla de mapeo (archivo → destino). 83/83 cubiertos.

### → 40_salidas/exploraciones/01_afiche_inset_v2_v7/scripts/  (15 R)
auditoria.R, auditoria_v2.R, auditoria_v3.R, auditoria_v4.R, auditoria_v6.R,
auditoria_v7.R, auditoria_v8.R, auditoria_v9.R (paneles adversariales del afiche con inset,
v2→v9), dbg_idx.R (debug índice, sourcea 33), dev_render.R, dev_v4_calib.R, dev_v4_render.R,
dev_v4_zones.R, dev_v4_zones_vina.R, dev_vina.R (prototipos del afiche original).

### → 40_salidas/exploraciones/01_afiche_inset_v2_v7/renders/  (28 png)
v2_idx, v2_norte, v2_norte_zoom, v2_vina, v3_norte, v3_norte_zoom, v3_vina, v4_concon,
v4_quintero, v4_norte, v4_vina, v4_ventanas, v6_colbot, v6_idx, v6_norte, v6_pie, v7_puch,
v7_conc, v7_norte, v7_norte_full, v7_vina, v7_vlabel  (renders por versión);
afiche_v2, afiche_v3, afiche_v6, afiche_v7  (póster completo por versión, sin "_full");
panel_norte, panel_vina  (salidas de dev_render/dev_vina).  [3 últimos grupos = AMBIGUOS, ver abajo]

### → 40_salidas/exploraciones/02_escala_unica_posicion/  (scripts/ + renders/)
scripts/: preview_A_vs_C.R, preview_D_vs_E.R
renders/: preview_A_in_situ.png, preview_C_proxy_leader.png, preview_D_arco_descarga.png,
preview_E_circulo_compacto.png

### → 40_salidas/exploraciones/03_escala_unica_tamano_pin/  (scripts/ + renders/)
scripts/: preview_tamano_pin.R
renders/: preview_T1_r75.png, preview_T2_r60.png, preview_T3_r45.png

### → _archivo/20260628/  (29 sobras; gitignored, se mueve fuera del repo versionado)
b3.rds (objeto intermedio); thumbs: c_poster_thumb, pdf_thumb, v2_thumb, v4_thumb,
v7_thumb, v9_thumb; smoke_carto (prueba de humo de tiles); pdf_mapcrop (recorte de prueba);
calib_norte, calib_vina (calibración v4 sin pines); c_idx_bot, c_idx_full, c_idx_top,
c_norte, c_vina (familia "c_" antigua del índice/paneles); zn_concon, zn_top (zonas
antiguas); zones_norte, zones_norte_zoom, zones_vina (zonas de exclusión, eliminadas en v7);
zoom_top, zoom_bottom (zooms de dev_render); zv_zoom; v_sea_bot, v_sea_top (etiquetas al mar
antiguas); panel_norte_base (base sin pines); afiche_full, afiche_v4_full (renders agregados
antiguos, superados).
*Justificación:* todos son intermedios/calibraciones/pruebas de humo/duplicados de baja res
sin valor de evidencia por versión (ya cubierta por los renders v*_ y afiche_v* en 01).

### → pipeline (RECOMENDADO, ejecución diferida)
preparar_bcn.R  →  `30_procesamiento/30_preparar_comunas.R` (decide el titular).

## Archivos AMBIGUOS señalados al titular (no se adivina)
1. **Nombre de la carpeta 01:** el encargo la llama `01_afiche_inset_v2_v7`, pero hay
   `auditoria_v8.R` (PDF A0) y `auditoria_v9.R` (etiquetas HTML) del MISMO afiche con inset.
   El contenido abarca v2→v9. ¿Renombrar a `01_afiche_inset` o `01_afiche_inset_v2_v9`?
2. **afiche_v2/v3/v6/v7.png** (póster completo por versión, ~2.5 MB c/u): los puse en 01
   renders por valor de evidencia (no matchean el patrón de archivo `afiche_*_full`). Pero
   pesan 10 MB. ¿Confirmas 01, o prefieres archivarlos y dejar solo los renders v*_ por panel?
3. **panel_norte.png / panel_vina.png** (salidas de dev): los puse en 01 renders. No son los
   productos finales (esos viven en `40_salidas/afiche/`, intactos). ¿01 o _archivo?
4. **Numeración del rescate de preparar_bcn.R:** recomiendo `30_preparar_comunas.R`; la
   alternativa rango-20 también es válida. Decisión del titular.

## Auto-auditoría adversarial (Fase A)
- ¿Cambió algún producto final o script de pipeline? **No.** `git diff --stat` de 31, 32,
  33, 00_run_all, 10_*, maestro, 40_salidas/afiche/* = vacío (no se tocó nada; solo lectura).
- ¿`.gitignore` deja versionadas las exploraciones? **Sí**: `40_salidas/` se versiona y
  ningún patrón excluye `40_salidas/exploraciones/`. `_archivo/` SÍ está gitignored (el
  archivo queda local, correcto). Nota: mover ~25 MB de PNG a 40_salidas/exploraciones/ los
  hará trackeados (decisión asumida por el titular).
- ¿La numeración del script rescatado respeta decenas? Sí: 30 (pre-31). Se difiere wiring a
  00_run_all (🔒).
- ¿`preparar_bcn.R` se LEYÓ? Sí, completo (52 líneas); recomendación basada en su contenido,
  no en el nombre.

## Estado de git al cierre de Fase A
```
git diff --stat (pipeline + productos) -> vacío.  Nada movido. Compuerta: espera OK del titular.
```
