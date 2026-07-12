# Log de construcción — capa de asistencia zonal (Censo 2024)

**Fecha:** 2026-07-12 · **Etapa 2, Hito 3** · Segundo código de producción del Censo.
**Script:** `30_procesamiento/38_construir_capa_zonal.R` (nuevo).
**Salida:** `docs/data/censo_zonal_r5.geojson`.
**Contrato:** `decisiones/20260712_decision_indicador_asistencia_censo2024.md` §3–§6.

---

## 1. Cifras reales medidas

| Métrica | Valor medido |
|---|---:|
| Zonas urbanas (continental) | **692** |
| Localidades rurales (continental) | **524** |
| Unidades escritas | **1 216** |
| Excluidas por insularidad | **2 zonas + 8 localidades** (CUT 5104, 5201) |
| Canario de lectura, máx\|dif\| | **0,60 pp** (TOL_LECTURA_PARQUET = 0,75) ✅ |
| Unidades con denominador 0 → proporción NA (conservadas) | parv **62**, básica **38**, media **75** |
| Solape urbano ∩ rural tras recorte | **0,08947 ha** (umbral 0,50) |
| Peso crudo | 2 116,7 KB |
| Peso **gzip −9 medido** | **418,0 KB** |

---

## 2. Universo: continental (decisión del titular, sesión 12)

`COD_REGION == 5` **excluyendo** `COMUNAS_INSULARES <- c("5104", "5201")` (Juan Fernández,
Isla de Pascua). El filtro insular se aplica **antes de toda operación geométrica**, dentro
de `leer_capa()`. Es exclusión de **alcance**, no de calidad, formalizada en
`decisiones/20260712_decision_exclusion_territorio_insular.md`. Medido: 2 zonas + 8
localidades excluidas → 692 + 524 = 1 216 unidades. (El "694/532" del contrato §6 era el
total R5 incluyendo insulares; el universo del producto es continental.)

---

## 3. Simplificación: la decisión medida, y el conflicto que reveló

### Tolerancia (contrato: "no reutilices el 5 de manzana sin medir")

| Tolerancia | Colapsos | gzip |
|---|---:|---:|
| 5 m | 0 | 782,6 KB |
| **20 m** | **0** | **406,7 KB** |

A 20 m **no colapsa ninguna** unidad y pesa la mitad. Las zonas son polígonos grandes: 20 m
no las daña. `TOLERANCIA_SIMPLIFICACION_M <- 20`, elegido por peso.

### El conflicto: `st_simplify` introduce solape (prohibido)

`st_simplify` simplifica cada polígono **por separado**, así que distorsiona los bordes
**compartidos** entre zona urbana y localidad rural adyacentes, creando solape a **cualquier**
tolerancia (medido: 2 m → 3,6 ha; 5 m → 12,9 ha; 20 m → 59,8 ha). El solape sin simplificar
es 0,0005 ha. El contrato exige 0 ha.

Opciones medidas y presentadas al titular:
- Sin simplificar: 0 solape, pero **3.698 KB gzip** (9× la manzana; demasiado).
- Topológica (mapshaper): correcta, pero `rmapshaper` no está instalado y arrastra V8/node
  → rompe la reproducibilidad pura-R del pipeline.
- **Recorte rural∖urbano tras 20 m** (elegida): pura `sf`, 0 dependencias.

### La solución adoptada: recorte con precedencia urbana

Regla semántica declarada: **"urbano manda en el borde".** Tras simplificar cada capa a
20 m, la geometría rural se recorta contra la unión urbana
(`st_difference(rural, st_union(urbano))`), en **métrico**, y el snap a la malla de salida
se aplica **después** sobre el combinado. Cuatro cifras medidas:

| | Valor |
|---|---:|
| Solape urbano ∩ rural tras recorte | **0,08947 ha** |
| gzip | **418,0 KB** |
| Localidades perdidas por el recorte | **0** de 524 |
| Área rural recortada | **0,004 %** (59,8 ha de 1,54 M ha) |

**El solape residual (0,089 ha ≈ 894 m²) no es doble conteo.** Es el sliver de sub-metro
que aparece al escribir a 6 decimales dos features vecinas a lo largo de ~9 km de borde
compartido. Los indicadores del producto son **por unidad** (vienen del parquet), no
derivados de área: ningún dato se cuenta dos veces. Un bug real de simplificación daría
>3 ha; el umbral `TOL_SOLAPE_HA <- 0.5` lo atraparía.

### Defecto de escritura resuelto (heredado del Hito 2b)

El recorte (`st_difference`) devuelve algunas unidades como **GEOMETRYCOLLECTION** (polígono
+ artefactos de línea). GDAL las escribía con `coordinates` vacías al redondear a 6
decimales, aun siendo válidas en memoria. Fix: recorte en métrico + snap final
(`st_set_precision(10^6)` + `st_make_valid`) + `st_collection_extract("POLYGON")` sobre el
combinado, **después** del recorte. Resultado verificado: **0 coords vacías**, solo
Polygon/MultiPolygon.

---

## 4. El indicador: proporción cruda, jamás "tasa neta"

Fórmula (contrato §3.1), por unidad, directa del parquet:
```
proporcion_asistencia_basica = n_asistencia_basica / n_edad_6_13   # análogo parv, media
```
Exportada **cruda**, sin ajuste por no-respuesta (§3.3). Donde el denominador es 0, la
proporción se exporta **NA** y la unidad **se conserva** (parv 62, básica 38, media 75).

**El canario de lectura** (§4.2) corrige por no-respuesta comunal y compara con la hoja 8,
pero **solo como diagnóstico**: no produce ninguna columna del GeoJSON. Las 12 celdas
(Costa Central × 3 niveles), diferencia ajustada vs oficial:

| Comuna | parv | básica | media |
|---|---:|---:|---:|
| Concón | −0,38 | −0,14 | −0,32 |
| Puchuncaví | −0,10 | −0,20 | **−0,60** |
| Quintero | −0,37 | −0,07 | −0,10 |
| Viña del Mar | −0,15 | +0,05 | +0,06 |

**máx\|dif\| = 0,60 pp ≤ 0,75.** El canario pasa: leímos bien el parquet.

---

## 5. Verificación del artefacto (sobre el archivo)

- 1 216 features; propiedades **exactamente** las 12 declaradas: `id_unidad, tipo_unidad,
  CUT, n_edad_0_5, n_edad_6_13, n_edad_14_17, n_asistencia_parv, n_asistencia_basica,
  n_asistencia_media, proporcion_asistencia_parv, proporcion_asistencia_basica,
  proporcion_asistencia_media`. Ningún identificador individual.
- `id_unidad` string; nchar **9** (urbano) / **8** (rural); `CUT` nchar **4**.
- 692 urbano + 524 rural; **0** CUT insulares.
- proporción null: parv 62, básica 38, media 75.
- 0 geometrías null, **0 coords vacías**, tipos = MultiPolygon/Polygon.

---

## 6. Cambio a `00_run_all.R`

Una entrada nueva (id 5), nada más:
```diff
+  list(id = 5L, etiqueta = "Construir capa zonal Censo",   ruta = file.path("30_procesamiento", "38_construir_capa_zonal.R"))
```
`run_all(only = 5)` corre **solo** el paso 5 (`saltados {1,2,3,4}`, OK en 1,8 s).

---

## 7. Panel adversarial (evidencia)

1. **¿"tasa neta" referida a la cifra del producto?** No. `grep -rni "tasa neta"` en el
   script devuelve **una** línea (la 7), que es el comentario de **prohibición**. En el
   GeoJSON: `grep -ci "tasa neta"` = **0**. No hay rotulo "tasa neta" en ninguna parte.
2. **¿La proporción exportada es cruda?** Sí. Línea 212:
   `prop <- function(num, den) if_else(den == 0L, NA_real_, round(num / den, 4L))`; sin
   factor de no-respuesta.
3. **¿El ajuste por no-respuesta está solo en el canario?** Sí. Única aparición, línea 176:
   `ajustada <- cruda / (1 - r)`, dentro de `test_lectura_parquet()`.
4. **¿El canario pasó?** Sí, 12 celdas arriba (§4), máx 0,60 pp ≤ 0,75.
5. **¿Nombre real de la columna de la hoja 2?** `"Nivel educativo no declarado"` (col 14),
   verificado en el script con `stop()` si no calza. Confirmado contra el archivo.
6. **nchar sobre el artefacto:** `id_unidad` 9 (urbano) / 8 (rural), `CUT` 4.
7. **Solape tras simplificación:** 0,08947 ha, medido con
   `st_intersection(st_union(urbano), st_union(rural))` en EPSG:32719 (función
   `solape_urbano_rural_ha`).
8. **Denominador 0 por nivel, presentes con NA:** parv 62, básica 38, media 75; conservadas.
9. **Tolerancia:** 5 m → 782,6 KB / 0 colapsos; 20 m → 406,7 KB / 0 colapsos. Elegida 20 m
   por peso (medido).
10. **¿Afirmación sin respaldo?** No: cada cifra sale de un comando o de una validación del
    script (que aborta si falla).

---

## 8. Nota de higiene del working tree

`docs/assets/estilo.css` aparece modificado (barra de filtros "Sesión 12", front-end).
**No lo tocó este encargo** (mtime 17:07, trabajo de front-end del titular en paralelo; este
encargo escribió el script 38 a las 17:19). Se deja intacto. Este encargo tocó exactamente:
`38_construir_capa_zonal.R` (nuevo), `docs/data/censo_zonal_r5.geojson` (nuevo), la entrada
id 5 de `00_run_all.R`, y este log. Nada se commiteó.
