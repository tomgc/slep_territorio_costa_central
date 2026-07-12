# Reporte de viabilidad — capa censal a nivel MANZANA (Etapa 1b)

**Fecha:** 2026-07-12
**Naturaleza:** solo medición empírica. No construye la capa, no toca el front-end, no
publica. Read-only sobre la raíz de datos del proyecto padre. Artefactos de prueba
escritos únicamente en `/tmp/censo_diag/`; el único archivo que entra al repo es este
reporte.

**Cartografía leída (read-only):**
`…/slep_estudio_oferta_demanda/20_insumos/censo_2024/cartografia/`
(`Cartografia_censo2024_Pais_Zonal.parquet` 23 M, `…_Pais_Manzanas.parquet` 194 M).

**Método de lectura:** `sf` 1.1.0 / GDAL 3.8.5 **no** tiene driver Parquet, y `sfarrow`
no está instalado. La geometría se leyó con `arrow` 23.0 (columna WKB `SHAPE`) y se
reconstruyó con `sf::st_as_sfc(…, EWKB=TRUE)`. Todo el filtrado por región se hizo en
Arrow **antes** de materializar geometría (memoria segura: nunca se cargaron las 216.341
manzanas del país a la vez).

Todas las cifras provienen de comandos ejecutados en esta sesión.

---

## 1. CRS, tipos por defecto y verificación de tipado

**CRS de origen (ambas capas):** **EPSG:4674 — SIRGAS 2000** (geográfico, grados).
Confirmado en `geo` metadata del parquet (`"authority":"EPSG","code":4674`,
`"name":"SIRGAS 2000"`). **No** vienen en proyección métrica.

**Geometría:** columna `SHAPE` (binary WKB), tipo `MULTIPOLYGON`.

**Features y columnas:**
| Capa | Features | Columnas | Peso disco |
|---|---|---|---|
| Zonal | **4 911** | 214 | 23 M |
| Manzanas | **216 341** | 218 | 194 M |

> El encargo mencionaba 168.295 manzanas país; el conteo real del parquet es **216 341**.

**Tipos con los que Arrow/parquet leen por defecto** (esquema autoritativo vía
`ParquetFileReader$GetSchema()`):

| Campo | Tipo por defecto | Riesgo |
|---|---|---|
| `OBJECTID` | int64 | — |
| `CUT` | **int32** | pierde ceros a la izquierda en regiones 1–9 |
| `COD_REGION` | **int32** | idem |
| `REGION` | string | — |
| `MANZENT` | **double** | 13 díg. cabe en double (< 2⁵³) pero al castear da notación científica / sin ceros |
| `ID_ZONA` | **double** | 9 díg.; mismo riesgo |
| `COD_ZONA` | int32 | — |

**Casteo a character inmediato tras leer** (Política 5.3.6), con `sprintf("%.0f", …)`
para los `double` (evita notación científica). **Verificación de que no se perdió
ningún dígito** — `nchar()` constante y coincidente con el diccionario INE:

- `MANZENT`: nchar **= 13** (único valor), ej. `5401023012001` ✅ (diccionario ~13)
- `ID_ZONA`: nchar **= 9** (único valor), ej. `540101001` ✅ (diccionario ~9)
- `CUT`: nchar **= 4** (único valor), ej. `5401` ✅

Ningún geocódigo perdió dígitos. Todos los joins y filtros de este reporte se hicieron
sobre las versiones **character**.

---

## 2. Peso por universo y tolerancia (Fase 2)

**Camino de simplificación (declarado):** se reproyectó 4674 → **EPSG:32719 (UTM 19S)**,
se aplicó `st_simplify(dTolerance = 5/10/20 m)` en metros, y se reproyectó a **EPSG:4326**
para escribir. Motivo: `dTolerance` es una distancia; en grados (4674/4326) no es
interpretable en metros. Todos los GeoJSON se escribieron con **`COORDINATE_PRECISION=6`**
(≈0,1 m, estándar web) constante, de modo que la tabla aísla el efecto de la
simplificación de vértices, no de la precisión decimal. `peso_gzip_mejor` = `gzip -9`
**medido** (no estimado) sobre la variante más liviana (tol 20 m). GitHub Pages sirve
gzipeado: es el peso que viaja al navegador.

**Universo U4:** 254 establecimientos de Costa Central (Concón, Puchuncaví, Quintero,
Viña del Mar), buffer de 1 km unido en UTM 19S, intersección con las manzanas de la R5.

| universo | n_features | peso_crudo | peso_tol5m | peso_tol10m | peso_tol20m | gzip_mejor | geom_inválidas | geom_colapsadas (5/10/20 m) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| **U1** zonas R5 continental | 692 | 9.0 M | 1.2 M | 947 K | 763.8 K | **126.4 K** | 0 | 0 / 0 / 0 |
| **U2** manzanas R5 continental | 26 569 | 64.1 M | 20.0 M | 18.8 M | 17.7 M | **1.6 M** | 0 | 1030 / 1792 / 3121 |
| **U3** manzanas Costa Central | 5 983 | 13.6 M | 4.5 M | 4.2 M | 4.0 M | **371.7 K** | 0 | 230 / 478 / 835 |
| **U4** manzanas buffer 1 km | 6 496 | 14.2 M | 4.9 M | 4.6 M | 4.3 M | **401.0 K** | 0 | 220 / 432 / 802 |

**Detalle gzip (crudo | tol5 | tol10 | tol20):**
- U1: 1.7 M | 219.4 K | 165.6 K | 126.4 K
- U2: 9.7 M | 2.2 M | 1.9 M | 1.6 M
- U3: 2.1 M | 504.1 K | 431.9 K | 371.7 K
- U4: 2.2 M | 543.0 K | 467.4 K | 401.0 K

**Lecturas:**
- Ninguna geometría quedó **inválida** (`st_is_valid` = TRUE en todos los casos).
- La simplificación sí **colapsa manzanas chicas a geometría vacía**: en Costa Central,
  230 vacías a 5 m (3.8 %), 478 a 10 m (8.0 %), **835 a 20 m (14.0 %)**. Es el
  verdadero costo de simplificar agresivamente: no rompe polígonos, los **desaparece**.
- El peso NO es el cuello de botella: Costa Central pesa **372–504 K gzip** según
  tolerancia; incluso la región continental completa a nivel manzana son **1.6 M gzip**.
  Todo manejable en Leaflet.

---

## 3. Validación de joins (Fase 3) — **el join NO es 1:1**

### Manzana (`Base_manzana` ↔ capa de manzanas, por `MANZENT` character)
| | valor |
|---|---:|
| Cartografía manzanas R5 | 26 662 |
| CSV manzanas R5 | 23 742 |
| **Match en ambos** | **21 876** |
| Cartografía sin dato CSV (geometría sin fila) | 4 786 |
| CSV sin geometría (fila sin polígono) | 1 866 |

- Ejemplos carto sin dato: `5401073065003`, `5401083030032` (manzanas dibujadas que la
  base agregada no reporta — típicamente sin población o no agregadas).
- Ejemplos CSV sin geometría: `5101991999999`, `5101102002011` (incluye el patrón
  `…99…999999` = distrito/manzana **indeterminada**, que por definición no tiene
  polígono).
- Tras el join, `n_edad_6_13`, `n_asistencia_basica`, `n_asistencia_media` llegan
  **pobladas en las 21 876 filas con match** (no todas NA). ✅

### Zona (`Base_zona_localidad` ↔ capa zonal, por `ID_ZONA` character)
| | valor |
|---|---:|
| Cartografía zonal R5 | 694 |
| CSV zona/localidad R5 | 1 263 |
| **Match en ambos** | **693** |
| Cartografía sin dato | 1 |
| CSV sin geometría zonal | 570 |

- De las 1 263 filas CSV de la R5, **536 son `AREA_C=2` (localidades rurales) con
  `ID_ZONA` vacío**: son *localidades*, no *zonas*, y la capa zonal (urbana) no las
  contiene. Los otros 34 sin match son urbanos. Ejemplos CSV sin geometría:
  `510199999`, `510299999` (indeterminadas).

### Conclusión crítica del join
El join **no es 1:1** en ninguno de los dos niveles. **Pero** — hallazgo central —
**la cartografía ya trae sus propias columnas agregadas** (`n_asistencia_*`, `n_edad_*`,
etc. vienen incrustadas en el parquet, es un producto pre-unido por el INE). No se
necesita adjuntar el CSV externo para construir la capa. En Costa Central la cartografía
tiene **0 NA** en los indicadores (ver Fase 5). El desajuste del join solo importa si
alguien intentara pegar el CSV independiente; para el producto, la geometría es
autosuficiente.

---

## 4. Indeterminación en Costa Central (Fase 4)

La Nota Técnica n5 del INE cita 13,1 % de manzanas urbanas indeterminadas en Valparaíso
(máximo nacional). **En Costa Central el fenómeno es mucho menor.**

**Lado CSV (base agregada), `COD_CATEGORIA == "15"` / `CATEGORIA == "Indeterminada"`:**
| Comuna | Manzanas | Indeterminadas | % |
|---|---:|---:|---:|
| Concón (5103) | 506 | 5 | 0.99 % |
| Puchuncaví (5105) | 433 | 13 | 3.00 % |
| Quintero (5107) | 633 | 18 | 2.84 % |
| Viña del Mar (5109) | 3 338 | 3 | 0.09 % |
| **Total** | **4 910** | **39** | **0.79 %** |

**Lado cartografía:** las manzanas de Costa Central tienen `COD_CATEGORIA` ∈ {1,2,3}
(Ciudad 5 693, Pueblo 220, Aldea 70) y **cero** con código 15. Es decir, las
indeterminadas **no se dibujan** como polígonos separados en la cartografía de CC → **no
distorsionan el mapa**. Superficie de las manzanas CC (todas no-indeterminadas): media
**18 333 m²**, mediana **5 141 m²**. (No se puede comparar área indet vs no-indet porque
la cartografía CC no contiene indeterminadas.)

Indeterminación en Costa Central = **0,79 % (dato) / 0 % (dibujadas)**: muy por debajo
del máximo regional; no es un obstáculo para la capa.

---

## 5. Densidad del indicador: manzana vs zona (Fase 5)

Sobre la cartografía de Costa Central (columnas propias del parquet):

| | Manzana CC (n=5 983) | Zona CC urbana (n=159) |
|---|---:|---:|
| `n_edad_6_13` > 0 | 4 279 | 158 |
| `n_edad_6_13` = 0 | 1 704 | 1 |
| `n_edad_14_17` > 0 | 3 865 | 158 |
| `n_edad_0_5` > 0 | 3 744 | 158 |
| NA (sin dato) | 0 | 0 |
| **Indicador calculable** *(asistencia_básica válida Y 6-13 > 0)* | **4 279 (71.5 %)** | **158 (99.4 %)** |

Distribución `n_edad_6_13`:
- **Manzana CC:** min 0, p25 **0**, mediana **3**, p75 **7**, máx 283.
- **Zona CC:** min 0, p25 115, mediana 211, p75 318, máx 944.

**Lectura:** a nivel manzana, el **28,5 %** de las celdas de Costa Central tiene **cero**
niños en edad de básica (p25 = 0, mediana = 3): el mapa a manzana tendrá una fracción
importante de celdas vacías o de tasa no calculable. A nivel zona, prácticamente todas
(99,4 %) son calculables, pero la unidad es mucho más gruesa (mediana 211 niños/zona vs
3/manzana). Es el clásico trade-off resolución ↔ densidad de señal.

---

## 6. Veredicto de viabilidad

| Universo | Viable en Leaflet | Indicador calculable | Razón (con cifra) |
|---|:--:|:--:|---|
| **U1** zonas R5 continental | **SÍ** | ~99 % | 692 features; **126 K gzip**; 0 colapsos; casi toda zona con niños. |
| **U2** manzanas R5 continental | **SÍ (con reservas)** | 71.5 % | 26 569 features; **1.6 M gzip** (tol 20 m) — pesado pero cargable; 3 121 colapsos (11.7 %) a 20 m. |
| **U3** manzanas Costa Central | **SÍ** | 71.5 % | 5 983 features; **372–504 K gzip**; a 5 m solo 3.8 % colapsos. |
| **U4** manzanas buffer 1 km | **SÍ** | 71.5 % | 6 496 features; **401–543 K gzip**; footprint ajustado al producto. |

La geometría a nivel manzana **es manejable en Leaflet** (contra la duda que motivó este
encargo). El peso NO es el problema. Los dos límites reales son: (a) la simplificación
agresiva **desaparece** manzanas chicas (14 % a 20 m en CC) → usar tolerancia baja
(5 m); (b) el **28,5 %** de las manzanas de CC no tiene niños en edad básica → muchas
celdas vacías.

---

## 7. Recomendación explícita (Política 0.1)

**Recomiendo construir la capa a nivel MANZANA acotada a Costa Central (universo U3, o
U4 si se quiere incluir el borde de 1 km), simplificada a `dTolerance = 5 m`, sirviendo
la geometría directa del parquet (sin join externo al CSV).**
Justificación en una línea: pesa **~504 K gzip** (trivial para Leaflet), conserva el
96,2 % de las manzanas (solo 3,8 % colapsan a 5 m) y el indicador es calculable en el
71,5 % de las celdas; para el 28,5 % restante y las zonas rurales sin manzana, **usar la
capa ZONAL como complemento/fallback** (126 K gzip, 99,4 % calculable).

---

## 8. Lo que no se pudo determinar y por qué

1. **Reconciliación fina carto vs CSV.** La cartografía CC tiene 5 983 manzanas y el CSV
   4 910; la cartografía trae más polígonos (con datos propios, 0 NA). No se auditó
   celda por celda si los valores del parquet son idénticos a los del CSV; se asumió el
   parquet como fuente (es el producto pre-unido del INE). Queda como verificación
   pendiente si se decide usar el CSV en vez de las columnas del parquet.
2. **Área indeterminada vs no-indeterminada en CC:** no calculable porque la cartografía
   CC no contiene manzanas indeterminadas (0 con `COD_CATEGORIA=15`).
3. **Semántica exacta de `n_asistencia_*`** (rango etario, asistencia actual vs previa):
   está en los glosarios PDF del INE, no abiertos aquí. No afecta el veredicto de peso
   ni de densidad.
4. **Comportamiento de render real en el navegador** (FPS, memoria del cliente con 6 000
   polígonos): este encargo mide peso de transferencia, no rendimiento de pintado. Se
   recomienda una prueba de humo en Leaflet antes de comprometer el nivel manzana para
   toda la región (U2).

---

## Panel adversarial

- **¿Geocódigos leídos/comparados como character?** Sí. `MANZENT` nchar=13 constante,
  `ID_ZONA` nchar=9, `CUT` nchar=4 — ningún dígito perdido. `double`→character vía
  `sprintf("%.0f")` para evitar notación científica. Todos los joins sobre versiones
  character.
- **¿El join se validó contra la cifra de features, no contra expectativa?** Sí:
  26 662 / 23 742 / 21 876 (manzana) y 694 / 1 263 / 693 (zona) son conteos medidos con
  `%in%` sobre las llaves reales, reportados en ambas direcciones.
- **¿El peso gzip se midió o se estimó?** Se **midió** con `gzip -9 -c archivo | wc -c`
  sobre cada GeoJSON escrito en `/tmp/censo_diag/`.
- **¿Se escribió algo fuera de `/tmp/censo_diag/` y `50_documentacion/andamios/`?**
  No (verificado con `git status --short`; ver entrega). `docs/` intacto.
- **¿Alguna afirmación contradice el output?** No. El veredicto separa explícitamente
  "peso viable" (medido) de "indicador calculable 71,5 %" (medido) y de "colapso por
  simplificación" (medido), sin colapsarlos en una sola conclusión optimista.
