# Log de construcción — capa de densidad a nivel manzana (Censo 2024)

**Fecha:** 2026-07-12 · **Etapa 2, Hito 2b** · Primer código de producción del Censo.
**Script:** `30_procesamiento/37_construir_capa_manzana.R` (nuevo).
**Salida:** `docs/data/censo_manzanas_cc.geojson`.
**Contrato:** `decisiones/20260712_decision_alcance_censo2024.md` §3, §3.1, §3.2, §3.4, §9
(capa de manzana **no** supersedida; la supersesión afecta solo a la capa zonal).

---

## 1. Cifras reales medidas

| Métrica | Valor medido | Esperado (Etapa 1b) | ¿Coincide? |
|---|---:|---:|---|
| Features tras filtro Costa Central | **5 983** | 5 983 | ✅ exacto |
| Geometrías colapsadas por simplificación (5 m) | **230 (3,84 %)** | 230 | ✅ exacto |
| Features escritos al GeoJSON | **5 753** | 5 753 | ✅ exacto |
| Manzanas con `n_edad_6_13 == 0` (cero real, presentes) | **1 474** | ~1 474 | ✅ |
| Peso crudo | **2 843,5 KB** (2 911 694 B) | — | — |
| Peso **gzip −9 medido** | **426,1 KB** (436 276 B) | ~412 KB | ⚠️ +13,4 KB (medido abajo) |

### La diferencia de peso (426 vs ~412 KB): medida, no atribuida a ruido

La geometría y el conteo de features son **idénticos** al Hito 1 (misma tolerancia 5 m,
mismas 5 753 features). La diferencia es del **conjunto de atributos**:

- Este producto lleva los **tres** conteos de edad que exige el contrato §3
  (`n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17`).
- El GeoJSON de humo del Hito 1 llevaba solo `n_edad_6_13` (más `COMUNA` y `COD_REGION`).

Control medido, misma geometría (5 753):
- Solo `n_edad_6_13`: **388,7 KB** gzip.
- Tres columnas de edad + `MANZENT` + `CUT`: **426,1 KB** gzip.

El delta lo explican las columnas de conteo, no la geometría. 426 KB gzip sigue siendo
trivial para Leaflet (el render se validó en el Hito 1 con esta misma capa).

---

## 2. Output de las validaciones (todas pasaron; el script aborta si alguna falla)

- **Tipado de geocódigos:** `nchar(MANZENT)` constante = **13**; `nchar(CUT)` constante
  = **4**. `stopifnot` no disparó. (Casteo con `sprintf("%.0f")` sobre el `double`.)
- **Todas las CUT en Costa Central:** `{5103, 5105, 5107, 5109}`, verificado.
- **0 NA** en `n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17`.
- **Sin geometrías vacías** y **todas POLYGON/MULTIPOLYGON** en lo escrito.
- **`st_is_valid` TRUE** en todas las geometrías.

### Defecto encontrado y corregido (escritura de slivers)

La primera corrida escribió **3 features con `coordinates` vacías** (tipo
`GeometryCollection`), pese a que en memoria las 5 753 geometrías eran POLYGON/
MULTIPOLYGON válidas y no vacías (`st_is_empty` = FALSE). Diagnóstico medido: **no** es
`RFC7946`; es el **redondeo a 6 decimales de GDAL en la escritura**, que degenera 3
slivers muy delgados a `GeometryCollection` vacía (variante con solo
`COORDINATE_PRECISION=6`, sin RFC7946: 3 vacías igual).

**Corrección:** alinear la geometría a la malla de precisión de salida **antes** de
escribir — `st_set_precision(x, 10^6)` + `st_make_valid()` — de modo que lo que se valida
en memoria es exactamente lo que GDAL escribe. Resultado tras el fix: **0 vacías, 0
GeometryCollection**, 5 753 features conservadas. Añadido `stopifnot` que exige 0 vacías
y solo geometría poligonal.

---

## 3. Verificación del artefacto (sobre el archivo, no el log)

Medido con `jq` sobre `docs/data/censo_manzanas_cc.geojson`:
- `.features | length` → **5 753**.
- Propiedades (únicas sobre todos los features): **exactamente** `CUT, MANZENT,
  n_edad_0_5, n_edad_6_13, n_edad_14_17` (las 5 declaradas, nada más).
- `MANZENT` es **string** en el JSON (ej. `"5103023005001"`) — el casteo sobrevivió a la
  escritura.
- `n_edad_6_13` es número entero (ej. 15).
- Geometrías: **0 null, 0 vacías**; tipos = `MultiPolygon, Polygon`.
- Manzanas con `n_edad_6_13 == 0`: **1 474**, presentes con valor 0 (contrato §3.4).
- Peso gzip −9 medido sobre el archivo: **436 276 B (426,1 KB)**.

---

## 4. Cambio a `00_run_all.R` (FASE 3)

Se agregó **una** entrada a `PASOS` (id 4). Nada más: sin reordenar, sin refactorizar,
sin tocar otros pasos.

```diff
   list(id = 3L, etiqueta = "Generar afiche HTML/SVG",     ruta = file.path("30_procesamiento", "33_generar_afiche.R"))
+  list(id = 3L, etiqueta = "Generar afiche HTML/SVG",     ruta = file.path("30_procesamiento", "33_generar_afiche.R")),
+  list(id = 4L, etiqueta = "Construir capa manzana Censo", ruta = file.path("30_procesamiento", "37_construir_capa_manzana.R"))
 )
```

Verificado: `run_all(only = 4)` corre **solo** el paso 4 (`saltados {1,2,3}`, OK en 1,4 s).

---

## 5. Nota de higiene del working tree

Durante el encargo aparecieron cambios en `50_documentacion/activa/ESTADO.md`
(`sesion_actual: v10 → v11`) y podas de snapshots de `50_documentacion/estructura/`,
**posteriores** a la compuerta FASE 0 y **no realizados por este encargo**: son de la
herramienta de sesión/escáner del titular. No son scripts del pipeline y se dejan
intactos. Este encargo tocó exactamente tres archivos: el script nuevo, el GeoJSON, y la
entrada en `00_run_all.R`. Nada se commiteó.
