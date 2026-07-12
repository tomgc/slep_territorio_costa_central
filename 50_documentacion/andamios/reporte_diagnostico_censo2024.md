# Reporte de diagnóstico — Censo 2024 (CPV24) para capa censal subcomunal

**Fecha:** 2026-07-12
**Naturaleza:** Etapa 1, solo lectura. Ningún archivo del Censo se copió, movió ni
modificó. El único artefacto producido es este reporte.
**Ruta base leída (read-only):**
`/Users/tomgc/Library/CloudStorage/OneDrive-SLEP/Proyectos/slep_estudio_oferta_demanda/20_insumos/censo_2024`

Todas las cifras provienen de comandos ejecutados en la sesión de diagnóstico
(`file`, `wc -l`, `awk`, y R/`data.table` sobre las bases). Ninguna es deducida ni
tomada de documentos previos.

---

## 1. Inventario físico (Fase 1)

### `censo_2024/bases/`
| Archivo | Peso | Tipo real (`file`) |
|---|---|---|
| `Base_aldeas_CPV24.csv` | 417 K | Unicode text, **UTF-8 (with BOM)**, CRLF |
| `Base_manzana_entidad_CPV24.csv` | 111 M | Unicode text, **UTF-8 (with BOM)**, CRLF |
| `Base_zona_localidad_CPV24.csv` | 8.3 M | Unicode text, **UTF-8 (with BOM)**, CRLF |
| `hogares_censo2024.csv` | 299 M | ASCII text |
| `personas_censo2024.csv` | 2.3 G | ASCII text |
| `viviendas_censo2024.csv` | 426 M | ASCII text |
| `viv_hog_per_censo2024/*.parquet` | 39 M / 297 M / 61 M | microdatos (hogares/personas/viviendas) |

### `censo_2024/documentacion/`
37 archivos (PDF de glosarios, manuales, notas técnicas, presentaciones) + 3 XLSX
(`diccionario_variables_censo2024.xlsx`, `diccionario_variables_glosas_censo2024.xlsx`,
`P7_Educacion.xlsx`) + `reporte_de_entidades_cpv2024.html`. Incluye
`N5_Nota Tecnica_indeterminacion_geografica_CPV2024.pdf` y
`Presentacion_cartografia_base manzana_entidad_CPV2024.pdf` (documentación, **no** la
cartografía en sí).

> **Nota de encoding:** el encargo sugería `encoding = "Latin-1"`. `file` muestra que
> las tres bases agregadas son **UTF-8 con BOM**. Toda la lectura se hizo con
> `encoding = "UTF-8"` en consecuencia.

---

## 2. Estructura de las bases agregadas (Fase 2)

| Base | N columnas | N filas de datos* | Separador | Encoding |
|---|---|---|---|---|
| `Base_manzana_entidad_CPV24.csv` | **212** | 197 032 | `;` | UTF-8 con BOM |
| `Base_zona_localidad_CPV24.csv` | **205** | 15 006 | `;` | UTF-8 con BOM |
| `Base_aldeas_CPV24.csv` | **199** | 725 | `;` | UTF-8 con BOM |

*N filas de datos = `wc -l` menos la cabecera (`wc -l` reportó 197033 / 15007 / 726
respectivamente; los archivos terminan sin salto final, por lo que el conteo de datos
es `wc -l − 1`).

El conteo con `FS=','` dio 1 columna en las tres → el separador **no** es coma. Con
`FS=';'` dio 212/205/199 → el separador es **punto y coma**.

### (d) Columnas de geocódigo
- **Manzana:** `CONTENEDOR_COMUNAL`, `COD_REGION`, `REGION`, `PROVINCIA`, `CUT`,
  `COMUNA`, `AREA_C`, `MANZENT`, `DISTRITO`, `COD_DISTRITO`, `COD_LOCALIDAD`,
  `COD_ZONA`, `LOCALIDAD`, `COD_ENTIDAD`, `COD_MANZANA`, `ENTIDAD`, `TIPO_MZ`,
  `COD_CATEGORIA`, `CATEGORIA`, `ID_ENTIDAD`, `ID_LOCALIDAD`, `ID_DISTRITO`, `ID_ZONA`.
- **Zona:** las mismas menos `MANZENT`, `COD_ENTIDAD`, `COD_MANZANA`, `ENTIDAD`,
  `TIPO_MZ`, `COD_CATEGORIA`, `CATEGORIA` (la base de zona **no** trae
  `COD_CATEGORIA`/`CATEGORIA`).
- **Aldeas:** `COD_REGION`, `REGION`, `PROVINCIA`, `CUT`, `COMUNA`, `AREA_C`,
  `ENTIDAD`, `COD_CATEGORIA`, `CATEGORIA`, `ID_ENTIDAD`.

### (b) Tramos etarios — **presentes en las tres bases**
`n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17`, `n_edad_18_24`, `n_edad_25_44`,
`n_edad_45_59`, `n_edad_60_mas` (+ `prom_edad`).

### (c) Nivel educativo alcanzado — **presente en las tres bases**
`prom_escolaridad18`, `n_cine_nunca_curso_primera_infancia`, `n_cine_primaria`,
`n_cine_secundaria`, `n_cine_terciaria_maestria_doctorado`, `n_cine_especial_diferencial`,
`n_analfabet`.

---

## 3. VEREDICTO SOBRE ASISTENCIA — la conclusión más importante

**SÍ EXISTE asistencia a educación formal, a nivel manzana, zona y aldea.**

Las tres bases agregadas contienen, con estos nombres exactos:

| Columna | Manzana | Zona | Aldeas |
|---|:--:|:--:|:--:|
| `n_asistencia_parv` (parvularia) | ✅ | ✅ | ✅ |
| `n_asistencia_basica` (básica) | ✅ | ✅ | ✅ |
| `n_asistencia_media` (media) | ✅ | ✅ | ✅ |
| `n_asistencia_superior` (superior) | ✅ | ✅ | ✅ |

No son columnas de matrícula administrativa, sino de **asistencia declarada** en el
censo, agregadas por unidad territorial. La granularidad llega hasta la **manzana**
(la unidad más fina disponible), lo que es directamente compatible con una capa
subcomunal.

Complementariamente hay conteos por tramo etario escolar (`n_edad_0_5`, `n_edad_6_13`,
`n_edad_14_17`), que permiten estimar población en edad escolar por manzana con
independencia de la asistencia.

---

## 4. Universo Región de Valparaíso (Fase 3)

Columna de región: **`COD_REGION`** (valores `"1"`…`"16"`); Valparaíso = **`"5"`**.

| Nivel | Filas totales (país) | Filas Región 5 |
|---|---|---|
| Manzana/entidad | 197 032 | **23 742** |
| Zona/localidad | 15 006 | **1 263** |

**Comunas:** 38 CUT distintos en la Región 5, de los cuales **2 son insulares**
(`5104` Juan Fernández — 20 manzanas / 3 zonas; `5201` Isla de Pascua — 62 manzanas /
9 zonas) → **36 comunas continentales**. (El encargo mencionaba "38 comunas
continentales"; el dato observado es 38 totales = 36 continentales + 2 insulares. El
proyecto excluye el territorio insular.)

**Desglose urbano/rural** (`AREA_C`; mapeo confirmado con crosstab `AREA_C`×`CATEGORIA`,
no inferido):
- `AREA_C = 1` (urbano: Ciudad + Pueblo) — manzana **20 871**, zona **727**.
- `AREA_C = 2` (rural: Aldea, Caserío, Fundo, Parcela, Indeterminada, etc.) — manzana
  **2 871**, zona **536**.
- No existe un código `AREA_C` separado para "aldea": las aldeas son categoría rural y
  además tienen su propia base agregada (`Base_aldeas_CPV24.csv`, 725 filas país).

### Costa Central (4 comunas)
| CUT | Comuna | Manzanas R5 | Zonas R5 |
|---|---|---:|---:|
| 5103 | Concón | 506 | 19 |
| 5105 | Puchuncaví | 433 | 33 |
| 5107 | Quintero | 633 | 30 |
| 5109 | Viña del Mar | 3 338 | 119 |
| **Total** | | **4 910** | **201** |

Desglose por las 38 comunas de la Región 5 (manzanas / zonas), del comando de Fase 3:
Valparaíso 3299/176, Casablanca 365/53, Concón 506/19, Juan Fernández 20/3,
Puchuncaví 433/33, Quintero 633/30, Viña del Mar 3338/119, Isla de Pascua 62/9,
Los Andes 832/39, Calle Larga 202/26, Rinconada 143/20, San Esteban 263/30,
La Ligua 730/31, Cabildo 274/28, Papudo 140/11, Petorca 287/31, Zapallar 213/13,
Quillota 1076/39, Calera 499/23, Hijuelas 178/21, La Cruz 246/11, Nogales 274/13,
San Antonio 1429/51, Algarrobo 436/24, Cartagena 639/28, El Quisco 585/15,
El Tabo 471/22, Santo Domingo 196/26, San Felipe 935/53, Catemu 224/23,
Llaillay 297/19, Panquehue 88/15, Putaendo 241/19, Santa María 228/29,
Quilpué 1793/64, Limache 519/33, Olmué 302/18, Villa Alemana 1346/46.

---

## 5. Supresión estadística (Fase 4)

**Marcador de supresión del INE:** el string **`*`** (asterisco). Verificado por
sanity check: en la Región 5 la manzana lo usa masivamente en variables sensibles
(`n_pueblos_orig` = 8 702 celdas `*`, `n_afrodescendencia` = 4 015, `n_religion` = 267),
lo que confirma que la detección funciona. **No** se hallaron otros códigos especiales
(`9`, `99`, `-99`) ni `NA`/vacío en las columnas escolares. Denominador de todos los
porcentajes = filas de la Región 5 (23 742 manzanas / 1 263 zonas), no del país.

| Columna | Manzana (n / % supr.) | Zona (n / % supr.) |
|---|---|---|
| `n_edad_0_5` | 0 / 0.00 % | 0 / 0.00 % |
| `n_edad_6_13` | 0 / 0.00 % | 0 / 0.00 % |
| `n_edad_14_17` | 0 / 0.00 % | 0 / 0.00 % |
| `n_asistencia_parv` | 0 / 0.00 % | 0 / 0.00 % |
| `n_asistencia_basica` | 0 / 0.00 % | 0 / 0.00 % |
| `n_asistencia_media` | 0 / 0.00 % | 0 / 0.00 % |
| `n_asistencia_superior` | 1 / 0.00 % | 1 / 0.08 % |

**La data fina prácticamente no está mordida en las variables escolares.** La supresión
del INE se concentra en variables de identidad (pueblos originarios, afrodescendencia,
religión), no en edad ni asistencia.

**Distribución de `n_per` (personas por unidad, Región 5):**
| | min | p10 | p25 | mediana | p75 | max |
|---|---|---|---|---|---|---|
| Manzana | 0 | 14 | 26 | 47 | 81 | 6 178 |
| Zona | 0 | 39 | 191 | 894 | 2 442.5 | 10 186 |

Las manzanas son chicas (mediana 47 personas) pero **no** vienen suprimidas en lo escolar.

**`n_edad_6_13` (población en edad de básica), Región 5:**
- Manzana: **21 075** con valor válido > 0; 2 667 con valor válido = 0; **0 suprimidas**.
- Zona: **1 223** con valor válido > 0; 40 con valor = 0; **0 suprimidas**.

**Indeterminación geográfica** (`COD_CATEGORIA == "15"` / `CATEGORIA == "Indeterminada"`,
solo existe en la base de manzana): **374 manzanas (1.58 %)** en la Región 5, más 39
manzanas (0.16 %) con `COD_CATEGORIA` vacío. Estas 374 + 39 son manzanas sin
localización determinada; carecen además de `ID_ZONA` (ver Fase 6).

---

## 6. Veredicto de viabilidad

| Nivel | Indicador | ¿Viable? | Razón (con cifra) |
|---|---|:--:|---|
| **Comuna** | Población escolar | **SÍ** | Suma directa de `n_edad_*` sobre 4 910 manzanas / 201 zonas de Costa Central; unión por `CUT` sin cartografía. |
| **Comuna** | Asistencia | **SÍ** | `n_asistencia_*` agregable por `CUT`, 0 % supresión. |
| **Zona** | Población escolar | **SÍ** | 1 263 zonas R5; `n_edad_6_13` válido en 1 223, 0 suprimidas. Requiere cartografía zonal para mapear. |
| **Zona** | Asistencia | **SÍ** | `n_asistencia_*` con supresión 0 %–0.08 % (1 celda). Requiere cartografía zonal. |
| **Manzana** | Población escolar | **SÍ (dato)** | 23 742 manzanas R5, 0 % supresión en `n_edad_*`; 21 075 con básica > 0. **Bloqueado el mapeo por falta de cartografía de manzanas** (Fase 5). |
| **Manzana** | Asistencia | **SÍ (dato)** | `n_asistencia_*` con supresión ~0 %. Mismo bloqueo cartográfico. |

**Conclusión:** la capa es viable **a nivel manzana en cuanto a la data** (contra la
hipótesis de que la supresión la haría inviable). El factor limitante **no** es la
supresión estadística, sino la **ausencia de la cartografía censal** para dibujar los
polígonos y ejecutar el spatial join. A nivel comuna la capa es construible ya (unión
por código, sin cartografía).

---

## 7. Estado de la cartografía (Fase 5)

`find` de `*.gpkg` / `*.gdb` / `*.parquet` / `*.shp` bajo `$CENSO`: los únicos aciertos
son los tres `.parquet` de microdatos (`viv_hog_per_censo2024/`). **No existe
cartografía censal** (ni GeoPackage, ni File Geodatabase, ni Shapefile) en la ruta.

**La cartografía FALTA.** No se descargó (el titular la baja). Sin ella no se pueden
mapear las capas de zona ni de manzana, ni ejecutar el spatial join
establecimiento→polígono.

---

## 8. Llave de unión, con tipos (Fase 6)

### Base agregada ↔ cartografía (pendiente de la cartografía)
- **Manzana:** campo `MANZENT` (character, **13 caracteres**, ej. `5101011001001`).
  Es la llave natural contra la capa cartográfica de manzanas.
- **Zona:** campo `ID_ZONA` (character, **9 caracteres**, ej. `510108011`). En la base
  de manzana el mismo `ID_ZONA` de 9 caracteres permite agregar manzana→zona.
  **Ojo:** 374+39 manzanas indeterminadas de la R5 tienen `ID_ZONA` vacío (`nchar 0`).
- No se puede confirmar el nombre del campo del lado cartográfico porque **la
  cartografía no está descargada**.

### Base agregada ↔ nuestro directorio de establecimientos
- Nuestro directorio (`docs/data/establecimientos.geojson`, 1 251 features) trae
  `geometry: Point` (coordenadas) y la comuna como **nombre** en el campo `com`
  (ej. `"VILLA ALEMANA"`); **no** trae un `COD_COM` numérico en esa versión web.
- **A nivel comuna:** unión directa por código comunal. Lado censo = `CUT` (character,
  **4 caracteres**, ej. `5101`, `5109`). Requiere derivar/confirmar el CUT en nuestro
  directorio (hoy solo tenemos el nombre de comuna en el geojson web; el pipeline
  fuente puede tener el código).
- **A nivel zona/manzana:** requiere **spatial join** — el punto del establecimiento
  dentro del polígono de la zona/manzana. Nuestros establecimientos ya son puntos, así
  que el join es factible **en cuanto exista la cartografía**. Hoy **no se puede
  ejecutar** porque falta la capa de polígonos.

### ADVERTENCIA DE TIPADO (Política 5.3.6)
`fread`, **por defecto (sin `colClasses`)**, lee los geocódigos como numéricos:

| Campo | Clase por defecto | Riesgo |
|---|---|---|
| `CUT` | `integer` | pierde cero a la izquierda en regiones 1–9 (no en R5, que empieza en 5) |
| `MANZENT` | `integer64` | deja de ser texto; frágil para join/leading zeros |
| `COD_ZONA` | `integer` | idem |
| `ID_ZONA` | `integer` | idem; además colapsa el vacío |

**Todo geocódigo debe leerse como `character`** (`colClasses = "character"`), como se
hizo en este diagnóstico. Leídos así, `CUT`=4 char, `MANZENT`=13 char, `ID_ZONA`=9 char.

---

## 9. Lo que NO se pudo determinar y por qué

1. **Campo de unión del lado cartográfico** y número de features de las capas zonal y
   de manzanas para la R5 (Fase 5/6): **la cartografía no está descargada**. Bloqueo
   duro para todo lo subcomunal mapeado.
2. **CUT en nuestro directorio de establecimientos:** el geojson web solo trae el
   **nombre** de comuna (`com`), no el código. La unión por código a nivel comuna
   requiere confirmar/derivar `CUT` desde el pipeline fuente (no auditado en este
   encargo por ser de solo lectura sobre el Censo).
3. **Semántica exacta de cada `n_asistencia_*`** (rango etario cubierto, tratamiento de
   asistencia previa vs. actual): está en los glosarios PDF de `documentacion/`, no
   abiertos en este diagnóstico. No afecta el veredicto de existencia/disponibilidad.
4. **Discrepancia de conteo de comunas:** el encargo asume "38 comunas continentales";
   lo observado son 38 CUT totales (36 continentales + 2 insulares). Reportado como se
   ve, sin corregir el supuesto.

---

## Panel adversarial (verificación previa a la entrega)

- **¿Cada cifra sale de un comando de esta sesión?** Sí. Inventario ← `ls`/`file`;
  columnas y conteos ← `wc`/`awk`/R; universo, supresión, tipado ← R/`data.table`.
  Ninguna cifra deducida.
- **¿Geocódigos leídos como character?** Sí, todo el análisis forzó
  `colClasses = "character"`. Se documenta aparte el tipado **por defecto** (numérico)
  solo para dejar registrada la advertencia 5.3.6.
- **¿% de supresión sobre el denominador correcto?** Sí: 23 742 (manzanas R5) y 1 263
  (zonas R5), no el país. Filtro `COD_REGION == "5"` verificado (valores únicos
  `"1"`…`"16"`).
- **¿Alguna afirmación contradice el output literal?** No. El veredicto de viabilidad
  de manzana distingue explícitamente "viable en dato" de "bloqueado en mapeo por falta
  de cartografía", que es justo lo que muestran Fases 4 y 5.
- **¿Se escribió algo fuera de `50_documentacion/andamios/`?** No. Verificado con
  `git status --short` (ver más abajo). El único archivo nuevo de este encargo es este
  reporte. Los demás cambios del working tree son preexistentes (cierre v09, ajenos a
  este encargo).
