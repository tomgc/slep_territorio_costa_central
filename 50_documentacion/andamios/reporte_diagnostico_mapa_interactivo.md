# Reporte de diagnóstico — Mapa interactivo regional (Etapa 1)

> **Fecha:** 2026-07-10 · **Encargo:** `encargo_claude_code_mapa_interactivo_v1.md`
> **Naturaleza:** solo diagnóstico. No se escribió código de producción, no se movió ningún
> archivo, no se commiteó nada. Scripts de sondeo en scratchpad (no versionados).
> **Estado verificado del repo:** 33/33b/31/32/00_run_all/10_* **byte-idénticos** (git diff
> vacío). Working tree: solo untracked nuevos (insumos + docs de gobernanza + este encargo).

---

## 0. Divergencias respecto a lo declarado en el encargo (verificado ≠ asumido)

| # | El encargo dice | La realidad | Impacto |
|---|---|---|---|
| D1 | HEAD en `79bdf4e` | HEAD local y remoto en `9cbd5fd` (commits de docs posteriores: traspasos v04/v05, ESTADO.md) | Ninguno; los 🔒 están intactos |
| D2 | Directorio CSV "latin1" | **UTF-8** (verificado con `file` y lectura; la glosa lo confirma: UTF-8 desde 2018, "entorno local" solo hasta 2017) | Leer con `encoding="UTF-8"`; leerlo como latin1 produce mojibake en NOM_DEPROV |
| D3 | "matrícula = MRUN distintos, NO filas (un estudiante puede tener varias filas)" | En los 10 años de la ventana, región 5: **filas = MRUN distintos, dup = 0 en todos los años** (el archivo "Matrícula única" ya viene desduplicado, una fila por estudiante) | La regla `uniqueN(MRUN)` se mantiene como escudo (es la definición correcta y robusta), pero la advertencia no se materializa en estos archivos |
| D4 | Columnas del histórico como en §0 | Los nombres de columna van en **minúsculas hasta ~2016 y MAYÚSCULAS después** | El pipeline debe normalizar `toupper(names())` |

Todos los CSV del histórico traen **BOM UTF-8** (`efbbbf`) y separador `;` — `data.table::fread` los resuelve solo. El 2016 leído como UTF-8 no muestra mojibake.

---

## 1. Diccionario de decodificación (de `glosas_directorio_oficial_ee.pdf`, 12 pp., leído completo)

### COD_DEPE (dependencia, 6 valores) y COD_DEPE2 (agrupada, 5 valores — recomendada para el filtro)
| COD_DEPE2 | Glosa |
|---|---|
| 1 | Municipal |
| 2 | Particular Subvencionado |
| 3 | Particular Pagado |
| 4 | Corp. de Administración Delegada (DL 3166) |
| 5 | Servicio Local de Educación |

(COD_DEPE desagrega Municipal en Corporación/DAEM y numera distinto; para el mapa basta COD_DEPE2.)

### ESTADO_ESTAB: 1 Funcionando · 2 En receso · 3 Cerrado · 4 Autorizado sin matrícula

### COD_ENSE (tipo de enseñanza; Anexo II) — presentes en región 5:
| Código | Glosa (abreviada) | EE reg.5 |
|---|---|---|
| 10 | Educación Parvularia | 751 |
| 110 | Enseñanza Básica | 792 |
| 165/167 | Básica Adultos (sin/con oficios) | 48/12 |
| 211–217, 299 | Educación Especial (auditiva/intelectual/visual/TEL/motores/autismo/relación-comunicación; opción 4 PIE) | 267 |
| 310 | Media H-C niños y jóvenes | 372 |
| 363 | Media H-C Adultos (D.1000/2009) | 82 |
| 410/510/610/710/810 | Media T-P (Comercial/Industrial/Técnica/Agrícola/Marítima) jóvenes | 42/55/38/10/7 |
| 463/563/663/763 | Media T-P Adultos (D.1000/2009) | 2/6/6/1 |

**Agrupación para el filtro "Tipo de enseñanza": la fuente ÚNICA es la planilla canónica del
titular** `20_insumos/auxiliares/codigo_tipo_y_macrogrupo.xlsx` (18 códigos → 6 macrogrupos:
Educación Parvularia · Enseñanza Básica · Enseñanza Media HC · Enseñanza Media TP ·
Educación de Adultos · Educación Especial). Reemplaza la agrupación tentativa que este
diagnóstico había propuesto. Los códigos presentes en el dato y ausentes de la planilla van
a un grupo **"Sin clasificar" visible** (no se inventa su macrogrupo); ver §1-bis.

### COD_GRADO (nivel; Anexo V del `ER_Matrícula_por_alumno_PUBL_WEB.pdf`, en la carpeta del histórico)
Relación **tipo↔nivel = (COD_ENSE × COD_GRADO)**, con dos versiones (hasta 2018 / desde 2019).
Ejemplos: ENSE 110 → grados 1..8 (1º–8º Básico); ENSE 10 → 1..5 (Sala Cuna…Kínder); ENSE 310/410+ → 1..4 (medias); adultos → niveles 1..3. El filtro dependiente "Nivel" se deriva de los pares (COD_ENSE, COD_GRADO) **observados por RBD en el año más reciente**, decodificados con esta tabla. Extraerla completa a un CSV de diccionario es tarea de Etapa 2.

### Anexo I: regiones/provincias (región 5 = VALPO; provincias 51–58). Anexo III: especialidades TP (no se usa en el mapa v1).

---

## 1-bis. Cruce planilla de macrogrupos × COD_ENSE región 5 (adenda 2026-07-10)

Planilla canónica: `codigo_tipo_y_macrogrupo.xlsx` — **18 códigos** (el encargo verbal decía
19; el archivo trae 18) → 6 macrogrupos. Los 18 existen todos en el dato región 5.

### Códigos EN EL DATO y AUSENTES de la planilla → "Sin clasificar" (5, no 4)
| COD_ENSE | Glosa oficial (Anexo II) | EE reg.5 |
|---|---|---|
| 215 | Educación Especial Trastornos Motores | 1 |
| 299 | Opción 4 Programa Integración Escolar | 6 |
| 463 | Educación Media T-P Comercial Adultos (D.1000/2009) | 2 |
| 563 | Educación Media T-P Industrial Adultos (D.1000/2009) | 6 |
| 763 | Educación Media T-P Agrícola Adultos (D.1000/2009) | 1 |

Impacto: **16 EE** tienen ≥1 código sin clasificar; solo **1 EE (RBD 14946)** tiene como
ÚNICO código uno sin clasificar (quedaría íntegramente en "Sin clasificar" hasta que el
titular asigne). NO se inventa macrogrupo: pendiente de decisión del titular.

### Asimetría Adultos — confirmada TAL CUAL el archivo (sin corregir)
| Código | Descripción (de la planilla) | Macrogrupo (de la planilla) |
|---|---|---|
| 663 | Educación Media T-P Técnica Adultos | **Enseñanza Media TP** |
| 710 | Enseñanza Media T-P Agrícola Adultos | **Enseñanza Media TP** |
| 165 | Educación Básica Adultos Sin Oficios | Educación de Adultos |
| 363 | Educación Media H-C Adultos | Educación de Adultos |
| 167 | Educación de Adultos con Oficios | Educación de Adultos |

Observación factual (se reporta, NO se corrige): la planilla describe 710 como "Agrícola
**Adultos**", pero el Anexo II oficial define 710 = "Media T-P Agrícola **Niños y Jóvenes**"
(los agrícola-adultos oficiales son 760/761/763). Relevante porque 763 quedó justamente en
"Sin clasificar". Decisión del titular.

---

## 2. Directorio región 5 (AGNO 2025; 16.768 filas nacionales)

| Métrica | Valor |
|---|---|
| EE región 5 (todas las filas) | 1.765 (RBD únicos: 1.765) |
| ESTADO_ESTAB | 1: **1.274** · 2: 76 · 3: 413 · 4: 2 |
| Funcionando con MATRICULA=1 | 1.189 |
| **Geo válida** (parseable + bbox Chile) | **1.251 de 1.274** funcionando |
| Sin geo (a reportar, no inventar) | **23 RBD**: 2009, 2101, 14675, 14860, 14881, 41707, 41835, 41908, 41912, 41926, 41948, 41957, 41968, 42085, 42088, 42186, 42187, 42209, 42235, 42283, 42291, 42312, 42332 |
| bbox geo real | lat [−33.909, −32.092] · lon [−71.780, −70.304] |
| Comunas | 38 |
| Dependencia (COD_DEPE2) | 1: 323 · 2: 641 · 3: 176 · 4: 6 · 5: 128 |

Provincias (COD_PRO): 51 Valparaíso 457 · 52 Isla de Pascua 5 · 53 Los Andes 82 · 54 Petorca 87 · 55 Quillota 145 · 56 San Antonio 122 · 57 San Felipe 130 · 58 Marga Marga 246.
Nota: `NOM_DEPROV_RBD` es el **Departamento Provincial de Educación** (4 valores), NO la provincia. Para el filtro "Provincia" usar `COD_PRO_RBD` decodificado con el Anexo I (8 provincias), no NOM_DEPROV.

**Decisión propuesta de universo:** `ESTADO_ESTAB == 1` (funcionando), 1.274 EE; los 85 sin matrícula 2025 se muestran con indicadores "sin dato" o se excluyen — propongo **incluirlos** (existen y funcionan) con matrícula actual "s/d". El titular confirma.

---

## 3. Histórico por estudiante — validación de reglas de cálculo

### 3.1 Años muestra (2016, 2020, 2025) — lectura profunda
| Año | Archivo | Lectura (fread, columnas clave) | Filas nac. | Filas reg.5 | MRUN dist. reg.5 | RBD reg.5 |
|---|---|---|---|---|---|---|
| 2016 | 540 MB | ~2,0 s | 3.550.949 | 355.263 | 355.263 | 1.259 |
| 2020 | 575 MB | ~0,9 s | 3.608.786 | 364.289 | 364.289 | 1.209 |
| 2025 | 594 MB | ~0,9 s | 3.541.840 | 357.245 | 357.245 | 1.189 |

- **filas = MRUN distintos** en los tres (y en los 7 años restantes de la ventana: dup = 0 en todos). Ver D3. MRUN vacíos: 0.
- Dimensionamiento: leer los 10 años con `fread(select=…)` toma **< 1 minuto total**. El pipeline es liviano; no se necesita paralelización ni caché intermedio obligatorio (un RDS intermedio agregado igualmente se recomienda por idempotencia y para no releer 6 GB en cada corrida).

### 3.2 Ventana de años (§3.2 del encargo) — CONFIRMADA: 2016–2025
Los 22 años 2004–2025 existen en disco (~500–594 MB c/u). Los 10 más recientes (2016–2025) están completos y consistentes (filas reg.5 entre 355k y 372k, sin saltos anómalos). `N_ANIOS <- 10` → ventana **2016–2025**. Bonus: MRUN existe solo desde 2016 (glosa p.5), así que 2016 es además el primer año contable con la regla MRUN-distintos — la ventana no puede extenderse hacia atrás con esta metodología.

### 3.3 Cobertura del join directorio↔histórico (RBD como character en ambos lados)
| Métrica | Valor |
|---|---|
| RBD directorio-funcionando | 1.274 |
| con matrícula 2025 | 1.189 |
| con matrícula en ≥1 de {2016,2020,2025} | 1.208 |
| sin matrícula en ninguno de los 3 muestreados | 66 (la cifra exacta sobre los 10 años la dará el pipeline; serán los "sin dato") |
| RBD del histórico 2025 que NO están en directorio-funcionando | **0** (join limpio) |

---

## 4. Decisión parvularia (§ETAPA 1.4) — con evidencia

**Decisión propuesta: NO integrar el archivo de parvularia al conteo por RBD-año. El conteo usa SOLO `Matricula-por-estudiante` (que ya incluye a los párvulos de escuelas con RBD como COD_ENSE=10).**

Evidencia (2025, región 5):
1. **Doble conteo comprobado:** matrícula-única ya trae 29.828 párvulos (ENSE=10) en 751 RBD; **los 29.828 aparecen también** en el archivo de parvularia (solape MRUN 100% de ese subconjunto). Sumar ambos duplicaría a todos los NT1/NT2 de escuelas.
2. **36% del archivo parvularia no tiene RBD** (23.427 de 65.771 filas reg.5: JUNJI e Integra usan `ID_ESTAB`, no RBD) → no puede unirse al universo del directorio (que es RBD-céntrico) ni al mapa.
3. **Cortes distintos:** parvularia corta al 31-ago (MES=8); matrícula única al 30-abr. Mezclarlos rompe la comparabilidad interanual.
4. Cobertura temporal distinta (parvularia 2011–2025 vs 2004–2025).

Consecuencia visible: los jardines JUNJI/Integra **no aparecen en el mapa** (tampoco están en el directorio de EE con RBD); los párvulos de escuelas regulares SÍ cuentan en la matrícula de su RBD. Esto se documentará en `metadatos.json`. Si el titular quisiera un futuro "capa jardines", sería un producto aparte con `ID_ESTAB`.

---

## 5. Peso estimado del JSON (§ETAPA 1.7)

1.251 pins × ~250 bytes/EE (JSON compacto con claves cortas: rbd, nombre, lat/lon, comuna, provincia, dependencia, tipos, niveles, 4 indicadores + serie de 10 enteros) ≈ **0,31 MB sin comprimir** (~0,1 MB con gzip automático de Pages). Incluso triplicando campos queda ≪ 1 MB. **Liviano confirmado**; cabe incluso la serie anual completa por EE sin problema.

---

## 6. Arquitectura (validación de §5 del encargo)

- Leaflet + CARTO Positron: **sin objeción técnica** tras el diagnóstico; 1.251 pins es poco para Leaflet sin clustering (aunque conviene `preferCanvas: true`). MapLibre no aporta nada necesario aquí. **Recomendación: Leaflet**, como propone el encargo.
- La numeración 34/35/36 en `30_procesamiento/` no colisiona con 30/31/32/33/33b existentes. OK.
- Nota de gobernanza adicional detectada: el directorio trae `MRUN` **del sostenedor** (persona natural) — cuidado con no confundirlo con el MRUN de estudiantes; no se publica ninguno de los dos.
- `.gitignore`: hoy `20_insumos/auxiliares/` y `20_insumos/historico_matricula/` están **untracked pero NO ignorados** → riesgo de `git add -A` accidental (6 GB + MRUN). **Debe añadirse el patrón en el primer commit de la Etapa 2** (o antes, si el titular prefiere sellarlo ya).

---

## 7. Decisiones que la Etapa 2 asume (aprobar u objetar sobre este reporte)

1. **Universo:** ESTADO_ESTAB=1 (1.274 EE), pins = 1.251 con geo; 23 sin geo reportados en log.
2. **Ventana:** 2016–2025 (`N_ANIOS <- 10`), fija por disponibilidad de MRUN.
3. **Matrícula RBD-año = `uniqueN(MRUN)`** sobre matrícula-única (equivale a filas hoy, robusto si cambia).
4. **Parvularia:** fuera del conteo (evidencia §4); JUNJI/Integra fuera del mapa v1.
5. **min_10:** solo años con matrícula > 0; si no hay ninguno → "sin dato" (nunca 0). Los años sin registro del RBD no cuentan como 0.
6. **Filtros:** Provincia = COD_PRO_RBD (Anexo I, 8 provincias — no NOM_DEPROV); Dependencia = COD_DEPE2 (5 glosas); Tipo de enseñanza = **macrogrupos de la planilla canónica** (§1-bis; 5 códigos en "Sin clasificar" a la espera de asignación del titular); Nivel = pares (COD_ENSE, COD_GRADO) observados, decodificados con Anexo V.
7. **Encoding:** todos los insumos se leen como UTF-8 (D2/D4); llaves character en todos los joins.

## 8. Registro de errores del asistente (POLITICA 0.5)
- Sin desviaciones de reglas canónicas en esta etapa. Un reintento técnico menor (escape de `\\.` en `Rscript -e` vía bash; resuelto con script en archivo). Subagentes usados: **0 de 2 autorizados**.

---

**FIN DE ETAPA 1. Detenido a la espera de revisión del titular.** Si se aprueban §7.1–7.7, la Etapa 2 arranca con `34_preparar_directorio_region.R`.
