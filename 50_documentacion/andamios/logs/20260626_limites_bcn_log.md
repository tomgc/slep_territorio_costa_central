# Log de cierre — Reemplazo de límites comunales por BCN (alta resolución)

> Encargo: `50_documentacion/andamios/encargo_claude_code_limites_bcn_v3_1.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-26.
> Estado: **completo, todas las fases + panel adversarial.** Log sin commitear (revisión previa).

---

## 1. Resumen

Se reemplazó la fuente de los límites comunales: de `comunas.geojson` (fcortes,
generalizado, con comunas que se solapaban y contornos cruzados) a los límites del **BCN
de alta resolución**, ya descomprimidos por el usuario en `20_insumos/comunas_bcn/`. El
shapefile crudo (61 MB) se recortó a las 4 comunas, se reproyectó a WGS84 y se guardó como
`comunas.geojson` liviano (0.67 MB). El cruce Quintero/Concón que reportó el usuario
desapareció. Todo el afiche simplificado se conservó intacto; solo cambió la fuente de los
límites y se agregó la atribución BCN.

## 2. Commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `728f7e6` | feat(insumos) | Reemplaza `comunas.geojson` por límites BCN recortados (4 comunas, 4326) + `.gitignore comunas_bcn/` |
| `8387656` | feat(33) | Atribución BCN en la nota de fuente (`cargar_comunas()` sin cambios) |
| `e80c55e` | build(afiche) | HTML regenerado con límites BCN |
| `ae7286f` | docs | CLAUDE.md actualizado |

Sin commitear (revisión): este log y `auditoria_limites_bcn.R`.

## 3. Shapefile BCN: campo, CRS, resolución

- Archivo: `20_insumos/comunas_bcn/comunas.shp` (61 MB; + .dbf/.prj/.shx/.sbn/.sbx/.cpg/.shp.xml).
- **Campo de nombre comunal:** `Comuna` (detectado con `names()`; candidatos: COMUNA/NOM_COMUNA/
  Comuna/nombre → `Comuna`). Es el MISMO campo que usaba fcortes, por eso `cargar_comunas()`
  no necesitó cambios (Fase 3 quirúrgica: 0 cambios de lógica).
- **CRS:** EPSG:3857 (Web Mercator; del `.prj`: "WGS_1984_Web_Mercator_Auxiliary_Sphere").
- **346 comunas** en el país; se filtraron 4 por nombre normalizado (ASCII/minúsculas), igual
  que el resto del proyecto. Las 4 presentes: Puchuncaví, Quintero, Concón, Viña del Mar.

## 4. Verificación de no-solape (números antes/después)

Áreas de intersección entre comunas adyacentes (m², en proyección métrica 3857):

| Par adyacente | fcortes (antes) | BCN (después) |
|---|---:|---:|
| Puchuncaví ∩ Quintero | 4.308.344,6 | 9,10 |
| Quintero ∩ Concón | 1.708.617,6 | 4,16 |
| Concón ∩ Viña del Mar | 4.895.200,1 | 0,00 |

Las astillas residuales (<10 m²) provienen del redondeo de coordenadas a 6 decimales
(~0,1 m) al escribir el GeoJSON, no de un solape real de la fuente; son 5–6 órdenes de
magnitud menores que fcortes. Criterio (<100 m²) cumplido.

Vértices por comuna (resolución): **8564/7931/3470/4248** (BCN) vs **24/32/6/11** (fcortes).
Confirma el salto de resolución (≫ 6/12/14).

## 5. Insumo liviano y TOL

- Recorte a 4 comunas, reproyección a 4326, columnas `Comuna, cod_comuna, Provincia, Region`.
- Escrito con `COORDINATE_PRECISION=6` → **0.67 MB**. Por debajo del umbral (`TOPE_MB = 3.5`),
  así que **NO se aplicó `st_simplify`** (`TOL_SIMPLIFY_M = 20` quedó declarado pero sin usar):
  se preserva la geometría BCN completa, sin riesgo de reintroducir cruces.
- `.gitignore`: `20_insumos/comunas_bcn/` ignorado (🔒-4). `git ls-files comunas_bcn/` = 0.

## 6. Verificación de los invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No tocar 31/32 | **PASA** | `git diff d82f367..HEAD` de 31/32 vacío. |
| **🔒-2** Afiche simplificado intacto | **PASA** | Audit: numeración N→S 1..97 (rangos correctos), índice con 97 RBD + 97 nombres, sin etiquetas/leader lines (poda v2 intacta). Único cambio en 33: string de atribución. |
| **🔒-3** Sin filtro por contención | **PASA** | `comuna_paths()` solo dibuja contornos; no se introdujo ningún `st_within/filter` sobre los puntos. |
| **🔒-4** `.shp` de 61 MB fuera de Git | **PASA** | `comunas_bcn/` en `.gitignore`; `git ls-files comunas_bcn/` = 0 archivos. |

## 7. Panel adversarial (independiente, fcortes desde `git show HEAD`)

`auditoria_limites_bcn.R` — lee el geojson nuevo (BCN) y el viejo (fcortes, vía
`git show HEAD:...`) para comparar antes/después sin reusar el 33:

```
[PASA] las 4 comunas presentes en el nuevo geojson (4): Viña del Mar | Concón | Quintero | Puchuncaví
[PASA] BCN: solapes ~0 (max 9.10 m2 < 100)
[PASA] fcortes (antes) SI solapaba (min 1708618 m2)
[PASA] BCN: vertices >> fcortes (alta resolucion) en las 4 comunas
[PASA] afiche: numeracion N->S 1..97, rangos 1-20/21-30/31-37/38-97
[PASA] afiche: indice con 97 RBD y 97 nombres completos
[PASA] afiche: sin etiquetas ni leader lines en el mapa (poda v2 intacta)
[PASA] afiche: los puntos no se filtran por contencion en poligono (🔒-3)
[PASA] atribucion BCN presente en el HTML
[PASA] comunas_bcn/ NO trackeado en git (0 archivos)
===== PANEL ADVERSARIAL v3: TODO PASA (0 fallas) =====
```

## 8. Confirmación visual

Render headless (pagedown/Chrome) + zooms. Confirmado a ojo:
- Los 4 contornos siguen la **geografía real** (costa detallada, fronteras interiores
  irregulares), SIN líneas rectas en diagonal, SIN cruces ni dobleces.
- El cruce **Quintero/Concón** que reportó el usuario **desapareció**.
- El afiche (pines numerados, inset Viña, índice con RBD) se ve idéntico salvo los contornos.

## 9. Pendientes y notas para el revisor

- **Validación in situ:** abrir `40_salidas/afiche/mapa_establecimientos.html` en navegador.
- **`TOL_SIMPLIFY_M`** queda declarado en `scratchpad_afiche/preparar_bcn.R` pero no se usó
  (el geojson pesó 0.67 MB). El script de preparación vive en scratch (gitignored); si se
  quiere reproducible/versionado, moverlo a `30_procesamiento/` o `50_documentacion/`.
- **fcortes vs BCN comparten estructura** (objectid, cod_comuna, Region, Comuna, Provincia):
  el geojson anterior era una generalización del mismo dataset BCN. Por eso el campo no cambió.
- **Locale UTF-8 obligatorio**; **red** solo para tiles CARTO (los límites ya son locales).
- Honestidad: el reemplazo fue limpio y directo (el campo coincidía, el peso fue bajo). El
  único matiz fue confirmar que las astillas de solape <10 m² son redondeo, no un defecto BCN.
