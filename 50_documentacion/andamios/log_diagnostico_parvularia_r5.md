# Log — diagnóstico del universo de educación parvularia (R5)

**Pendiente N (fase 0) · v1 · 2026-07-30.** Encargo:
`50_documentacion/andamios/encargo_claude_code_parvularia_diagnostico_v1.md`.
Código de medición: `50_documentacion/andamios/diagnostico_parvularia_r5.R` (andamio, no
pipeline). Toda cifra de este log viene de un conteo programático corrido en esta sesión
sobre los archivos en disco; ninguna viene de documentación, traspaso ni glosa recordada.

Sin commits, sin stage, sin push. No se escribió, movió ni renombró nada bajo
`20_insumos/`.

---

## 1. Supuestos del §1 del encargo, verificados

### Corrección de encoding (el §1 se equivocó)

**El §1 declara que los CSV vienen en `latin1`. Son UTF-8.** Evidencia a nivel de bytes
sobre los primeros 20 MB de cada archivo (`readBin` + `validUTF8`):

| Año | bytes ≥ 0x80 | secuencia UTF-8 válida | veredicto |
|---|---:|---|---|
| 2011 | 76.875 | sí | UTF-8 |
| 2018 | 142.679 | sí | UTF-8 |
| 2025 | 337.451 | sí | UTF-8 |

Leídas como `latin1`, 200 filas de 2025 producen 201 celdas de texto rotas; como UTF-8,
cero. El pipeline de este repo ya leía estos CSV como UTF-8
(`30_procesamiento/34_preparar_directorio_region.R:132`,
`35_agregar_matricula_historica.R:74`, `36_construir_geojson_web.R:126`), así que la
afirmación del §1 contradecía también al código que ya funciona. **La corrección va en
este log; el encargo no se editó.**

### Los cinco supuestos

| # | Supuesto | Resultado | Comando |
|---|---|---|---|
| 1 | Parvularia 2011–2025, un CSV por año en `Matricula-Ed.-Parvularia-<AÑO>/` | **Verdadero** | `ls -1 20_insumos/historico_matricula/ \| grep -i parvularia` → 15 dirs; `find … -iname "*.csv"` → 1 CSV/año, 106–207 MB |
| 2 | Año más reciente 2025, corte 31-08-2025 | **Verdadero** | archivo `…_2025_20250831_WEB.csv`; `count(AGNO, MES)` → 2025 / 8 |
| 3 | `20_insumos/auxiliares/directorio_oficial_ee_publico.csv` existe | **Verdadero** | `ls -l` → 3.584.331 bytes |
| 4 | `latin1` + separador `;` | **Separador `;` verdadero; encoding FALSO (UTF-8)** | conteo de delimitadores en cabecera (`;`=48, `,`=0 en 2025) + prueba de bytes de arriba |
| 5 | La fuente cubre JUNJI, Integra y reconocidos | **Verdadero, y son separables** | ver §3.4 |

---

## 2. Esquema real

**2025:** 49 columnas, separador `;`. Identificador individual presente: **`MRUN`**
(columna 3). Declarado por nombre y no reproducido en ningún ejemplo de este log.

Familias exigidas por el GATE del PASO 1, todas presentes: id de establecimiento
(`ID_ESTAB`, `RBD`, `ID_ESTAB_J`, `ID_ESTAB_I`), nombre (`NOM_ESTAB`), comuna
(`COD_COM_ESTAB`), administrador (`ORIGEN`, `DEPENDENCIA`, `COD_DEPE1_M`,
`TIPO_SOSTENEDOR`). **GATE: PASA.**

El archivo trae además **`LATITUD` y `LONGITUD` propias**, que el encargo no anticipaba y
que cambian el PASO 3 de "cruzar contra el directorio" a "comparar dos fuentes".

**Delta de esquema** (nombres normalizados a mayúscula: 2011 usa minúscula y 2018/2025
mayúscula; comparar sin normalizar reporta "49 columnas nuevas", que es artefacto de la
caja, no cambio de esquema):

| Comparación | Δ | columnas |
|---|---:|---|
| en 2025 y no en 2011 | 26 | MES, GEN_ALU, RBD, ID_ESTAB_J, ID_ESTAB_I, COD_MAC_ESTAB, NOM_REG_A_ESTAB, COD_DEPROV_ESTAB, NOM_DEPROV_ESTAB, **LATITUD, LONGITUD**, TIPO_ESTAB, NOMBRE_SLEP, LET_CUR_M, COD_TIP_CUR_M, COD_ENSE2_M, ESTADO_ESTAB_M, CORR_GRU_J, COD_PROG_J, COD_JOR_J, COD_PROG_I, COD_MODAL_I, COD_JOR_I, TIPO_SOSTENEDOR, FEC_ING_ESTAB, FORMAL |
| en 2011 y no en 2025 | 11 | SEXO_ALU, DESC_PROG_J, DESC_MODAL_J, ASIS_REAL_J, ASIS_POTEN_J, POR_ASIS_J, DIAS_TRAB_GRUPO_J, DESC_MOD_I, ASIS_REAL_I, ASIS_POT_I, POR_ASIS_I |
| en 2025 y no en 2018 | 11 | COD_MAC_ESTAB, NOM_REG_A_ESTAB, TIPO_ESTAB, NOMBRE_SLEP, COD_TIP_CUR_M, COD_PROG_I, COD_MODAL_I, COD_JOR_I, TIPO_SOSTENEDOR, FEC_ING_ESTAB, FORMAL |
| en 2018 y no en 2025 | 14 | EDAD_30_06, COD_NAC_ALU, INT_ALU_M, COD_INT_ALU_M, LET_GRU_J, DESC_PROG_J, DESC_NIVEL_J, DESC_MODAL_J, ASIS_REAL_J, ASIS_POTEN_J, NOM_JOR_J, DIAS_TRAB_GRUPO_J, DESC_MOD_I, DESC_NIV_I |

Consecuencia para la serie: **`LATITUD`/`LONGITUD` y `TIPO_ESTAB` no existen en 2011 ni en
2018.** La georreferenciación desde el propio archivo de matrícula solo es posible en los
años que traen esas columnas.

---

## 3. Compuerta de gobernanza y PASO 2

### 3.1 Compuerta: ¿la coordenada es del establecimiento o de la persona?

El archivo es de nivel persona, así que antes de usar `LATITUD`/`LONGITUD` hubo que
demostrar que no son domicilio del niño. Conteo de pares `(LATITUD, LONGITUD)` distintos
por `ID_ESTAB` sobre las 65.771 filas de R5 en 2025:

| Medida | Valor |
|---|---:|
| filas con coordenada nula | **0** (0,00 %) |
| llaves `ID_ESTAB` con coordenada | 1.345 |
| llaves con **exactamente 1** par distinto | **1.345 (100,00 %)** |
| llaves con 2 o más pares | 0 (0,00 %) |
| máximo de pares en una llave | **1** |

`r5 |> distinct(ID_ESTAB, LATITUD, LONGITUD) |> count(ID_ESTAB)`

**Veredicto: coordenada de ESTABLECIMIENTO.** No hay variación intra-establecimiento, que
es lo que habría delatado un domicilio. Compuerta pasada, se siguió al PASO 3.

*Caveat del proveedor:* el ER oficial que acompaña al archivo declara en su nota al pie 7
que la localización en `LATITUD`/`LONGITUD` **"es solo referencial"**. Este diagnóstico
mide cobertura y concordancia, no exactitud contra terreno.

### 3.2 Universo regional 2025

| Medida | Valor | Cómo |
|---|---:|---|
| niños matriculados en R5 | **65.771** | `nrow(r5)` tras `filter(COD_REG_ESTAB == 5)` |
| de ellos en comunas insulares (5104, 5201) | 336 | `sum(COD_COM_ESTAB %in% c(5104,5201))` |
| niños continentales | 65.435 | 65.771 − 336 |
| unidades educativas distintas | **1.345** | `n_distinct(ID_ESTAB)` |
| unidades continentales | 1.337 | `n_distinct(ID_ESTAB[!insular])` |
| unidades insulares | 8 | idem |

**Llave usada: `ID_ESTAB`, como `character` en todo el flujo.** Es la única poblada en el
100 % de las filas y en los tres orígenes; `RBD`, `ID_ESTAB_J` e `ID_ESTAB_I` son parciales
por construcción (ver 3.3).

### 3.3 Cobertura de cada llave candidata, cruzada con ORIGEN

Filas de R5 2025. "Poblada" = no nula, no vacía, distinta de `"0"`.

| Llave | ORIGEN 1 | ORIGEN 2 | ORIGEN 3 |
|---|---:|---:|---:|
| `ID_ESTAB` | 42.344 pobladas | 16.533 pobladas | 6.894 pobladas |
| `RBD` | **42.344 pobladas** | 0 | 0 |
| `ID_ESTAB_J` | 0 | **16.533 pobladas** | 0 |
| `ID_ESTAB_I` | 0 | 0 | **6.894 pobladas** |

La partición es **perfecta y mutuamente excluyente**: `ID_ESTAB_J` e `ID_ESTAB_I` sí son
los identificadores de JUNJI e Integra respectivamente, y `RBD` existe solo para el origen
MINEDUC. Ninguna fila tiene dos de las tres pobladas.

### 3.4 ¿Se pueden separar JUNJI, Integra y VTF? — Sí

`ORIGEN` separa las tres fuentes; `TIPO_ESTAB` desagrega VTF dentro de JUNJI. Glosa tomada
del ER oficial en disco
(`20_insumos/historico_matricula/Matricula-Ed.-Parvularia-2025/ER_Educacion_parvularia_Oficial_WEB.pdf`,
pág. 3), no de memoria.

| ORIGEN | TIPO_ESTAB | Glosa | Unidades | Niños |
|---:|---:|---|---:|---:|
| 1 (MINEDUC) | 1 | Escuela Municipal | 239 | 6.985 |
| 1 | 2 | Escuela Particular Subvencionado | 521 | 27.538 |
| 1 | 3 | Escuela Particular Pagado | 74 | 4.732 |
| 1 | 4 | Escuela Servicio Local de Educación | 104 | 3.089 |
| 2 (JUNJI) | 5 | JUNJI Administración Directa | 125 | 6.577 |
| 2 | 6 | **JUNJI VTF** | **174** | **9.956** |
| 3 (INTEGRA) | 7 | INTEGRA Administración Directa | 105 | 6.749 |
| 3 | 8 | INTEGRA CAD | 3 | 145 |

Suma: 1.345 unidades / 65.771 niños. **VTF es `TIPO_ESTAB == 6`**, y vive dentro de
`ORIGEN == 2` (JUNJI), no dentro del origen MINEDUC. `DEPENDENCIA` replica `ORIGEN` con
más detalle (4 = JUNJI, 5 = INTEGRA, 1/2/3/6 = MINEDUC) pero **no** distingue VTF.

*Limitación de la serie:* `TIPO_ESTAB` no existe en 2011 ni en 2018, así que VTF **no es
separable hacia atrás** con este campo.

### 3.5 Unidades por comuna (38 comunas; las cuatro del área de monitoreo marcadas)

| Comuna | Unidades | Niños | |
|---|---:|---:|---|
| Valparaíso | 171 | 8.393 | |
| **Viña del Mar** | **170** | **9.708** | ← área de monitoreo |
| Quilpué | 118 | 5.186 | |
| San Antonio | 79 | 3.422 | |
| Villa Alemana | 78 | 4.462 | |
| Quillota | 72 | 3.897 | |
| San Felipe | 65 | 3.145 | |
| Calera | 51 | 2.190 | |
| Los Andes | 48 | 2.369 | |
| Limache | 38 | 2.102 | |
| La Ligua | 35 | 1.564 | |
| Llaillay | 30 | 1.266 | |
| Putaendo | 24 | 565 | |
| **Concón** | **23** | **1.800** | ← área de monitoreo |
| Casablanca | 22 | 1.186 | |
| **Puchuncaví** | **22** | **937** | ← área de monitoreo |
| Cabildo | 22 | 736 | |
| **Quintero** | **19** | **1.259** | ← área de monitoreo |
| Petorca | 19 | 491 | |
| Nogales | 19 | 887 | |
| Hijuelas | 18 | 799 | |
| Cartagena | 18 | 1.142 | |
| Santa María | 18 | 774 | |
| Catemu | 17 | 676 | |
| Olmué | 16 | 628 | |
| San Esteban | 15 | 739 | |
| La Cruz | 15 | 564 | |
| Calle Larga | 14 | 598 | |
| Panquehue | 14 | 575 | |
| El Quisco | 12 | 809 | |
| Santo Domingo | 12 | 681 | |
| Zapallar | 11 | 493 | |
| Algarrobo | 11 | 472 | |
| El Tabo | 8 | 317 | |
| Rinconada | 7 | 379 | |
| Isla de Pascua | 6 | 287 | ← insular |
| Papudo | 6 | 224 | |
| Juan Fernández | 2 | 49 | ← insular |

Área de monitoreo (Costa Central): **234 unidades, 13.704 niños**.

---

## 4. PASO 3 — georreferenciación, dos fuentes

### 4.0 Hallazgo de lectura: las dos fuentes usan separador decimal distinto

| Fuente | Separador decimal en `LATITUD`/`LONGITUD` |
|---|---|
| matrícula parvularia 2025 | **punto** (0 celdas con coma, 65.713 con punto) |
| directorio oficial | **coma** (1.381 con coma, 0 con punto, sobre 1.765 filas de R5) |

Forzar un único `dec=` en `fread` devuelve la otra fuente como `character` **sin avisar**,
y toda comparación numérica posterior da falso en silencio. El andamio ahora lee ambas
coordenadas como texto y las normaliza con una función única (`num_coord()`). Este bug
apareció en la primera corrida —dio 0 % de cobertura en las dos fuentes, que es
exactamente el aspecto de un hallazgo grave— y se detectó porque un 0 % simultáneo en dos
fuentes independientes es implausible, no porque el código avisara.

### 4.1 (a) Coordenadas del propio archivo de matrícula

| Medida | Valor |
|---|---:|
| unidades con coordenada presente | 1.341 / 1.345 |
| presentes pero fuera del bbox continental | 12 |
| — de ellas insulares (esperado) | 8 |
| — continentales fuera de rango (anómalas) | **4** |

Bounding box continental tomado de `docs/data/frontera_region.geojson`:
`xmin −71,84314 · ymin −33,95601 · xmax −69,98893 · ymax −32,02092`.

Cobertura de coordenada válida, **unidades continentales**, por ORIGEN:

| ORIGEN | Unidades | Con coord. | % unidades | Niños | Niños con coord. | % niños |
|---:|---:|---:|---:|---:|---:|---:|
| 1 (MINEDUC) | 934 | 934 | **100,0 %** | 42.112 | 42.112 | **100,0 %** |
| 2 (JUNJI) | 296 | 295 | 99,7 % | 16.444 | 16.432 | 99,9 % |
| 3 (INTEGRA) | 107 | 100 | 93,5 % | 6.879 | 6.714 | 97,6 % |

Por `TIPO_ESTAB` (continental), el déficit se localiza:

| TIPO_ESTAB | Glosa | Unidades | Con coord. | % |
|---:|---|---:|---:|---:|
| 1 | Escuela Municipal | 238 | 238 | 100,0 % |
| 2 | Escuela Part. Subvencionado | 519 | 519 | 100,0 % |
| 3 | Escuela Part. Pagado | 74 | 74 | 100,0 % |
| 4 | Escuela SLEP | 103 | 103 | 100,0 % |
| 5 | JUNJI Adm. Directa | 122 | 121 | 99,2 % |
| 6 | **JUNJI VTF** | 174 | 174 | **100,0 %** |
| 7 | **INTEGRA Adm. Directa** | 104 | 97 | **93,3 %** |
| 8 | INTEGRA CAD | 3 | 3 | 100,0 % |

### 4.2 (b) Cruce contra el directorio oficial, por RBD (`character` en ambos lados)

Directorio: 16.768 RBD únicos.

| ORIGEN | Unidades | Con RBD | Matchean | Con coord. válida del directorio |
|---:|---:|---:|---:|---:|
| 1 | 938 | 938 | **938 (100 %)** | 934 |
| 2 | 299 | **0** | 0 | 0 |
| 3 | 108 | **0** | 0 | 0 |

**La hipótesis del encargo se confirma exactamente:** las unidades reconocidas
oficialmente matchean el directorio al 100 %, y las de JUNJI e Integra no matchean
**ninguna**, porque no tienen RBD. No es que el cruce falle: la llave no existe para ellas.

### 4.3 (c) Distancia entre las dos fuentes

| Medida | Valor |
|---|---:|
| unidades con coordenada válida en ambas | 934 |
| distancia mediana | **0,0 m** |
| p95 | **0,0 m** |
| máximo | **0,0 m** |
| idénticas (< 1 m) | **934 (100,0 %)** |
| a más de 100 m | 0 |

`sf::st_distance(..., by_element = TRUE)` sobre EPSG:4326.

Las dos fuentes **no discrepan en un solo caso**: son la misma coordenada. El directorio
oficial no aporta ninguna unidad que la matrícula no traiga ya (**aporte exclusivo del
directorio: 0 unidades**). Para este universo, el cruce contra el directorio es
redundante.

### 4.4 (d) Georreferenciable hoy, sin fuentes nuevas (continental)

| Corte | Unidades | % | Niños | % |
|---|---:|---:|---:|---:|
| **Total continental** | **1.329 / 1.337** | **99,40 %** | **65.258 / 65.435** | **99,73 %** |
| ORIGEN 1 (MINEDUC) | 934 / 934 | 100,0 % | 42.112 / 42.112 | 100,0 % |
| ORIGEN 2 (JUNJI) | 295 / 296 | 99,7 % | 16.432 / 16.444 | 99,9 % |
| ORIGEN 3 (INTEGRA) | 100 / 107 | 93,5 % | 6.714 / 6.879 | 97,6 % |

**Sin georreferencia por ninguna vía: 8 unidades continentales, que representan 177
niños** (0,27 % de la matrícula continental). Siete de esas ocho son INTEGRA
Administración Directa.

---

## 5. PASO 4 — viabilidad de la serie histórica

| Año | Niños (filas R5) | Unidades | `ID_ESTAB` nchar | Clase | ORIGEN presentes |
|---|---:|---:|---|---|---|
| 2011 | 67.139 | 1.310 | 4–7 | character | 1, 2, 3 |
| 2018 | 79.311 | 1.363 | 4–7 | character | 1, 2, 3 |
| 2025 | 65.771 | 1.345 | 4–7 | character | 1, 2, 3 |

Estabilidad de la llave `ID_ESTAB`:

| Comparación | Presentes | % |
|---|---:|---:|
| llaves 2011 que siguen en 2025 | 1.089 / 1.310 | **83,1 %** |
| llaves 2018 que siguen en 2025 | 1.246 / 1.363 | **91,4 %** |
| llaves 2025 que ya estaban en 2011 | 1.089 / 1.345 | 81,0 % |

**El formato de la llave no cambió** (mismo rango de largo, mismo tipo, mismos tres
orígenes en los tres cortes).

**Juicio: la serie por unidad es VIABLE, con la reserva de que el panel no es balanceado.**
La cifra que lo sostiene es el 91,4 % de supervivencia a 7 años y 83,1 % a 14. Ese ~17 %
de rotación en catorce años es compatible con apertura y cierre real de jardines; este
diagnóstico **no midió** si además hubo reasignación de llave a una misma unidad física, y
esa distinción decide si una serie por unidad admite lectura longitudinal estricta o solo
agregada.

---

## 6. Lo que no medí

1. **Los doce años restantes de la serie.** Solo 2011, 2018 y 2025, como pide el encargo.
2. **El encoding de los doce años no sondeados.** La prueba de bytes cubre 2011, 2018 y
   2025; los demás se asumen UTF-8 por continuidad del proveedor, sin verificar.
3. **Qué son las 4 unidades continentales con coordenada fuera del bounding box.** Sé que
   son 4 y que no son insulares; no distinguí error de captura de establecimiento
   efectivamente ubicado fuera de la región.
4. **Si la rotación de `ID_ESTAB` es cierre real o reasignación de llave.** Medí presencia
   de la llave, no continuidad de la unidad física. Es la reserva del §5.
5. **Exactitud de las coordenadas contra terreno.** El ER del proveedor las declara "solo
   referencial"; medí cobertura y concordancia entre fuentes, no veracidad posicional.
6. **Matrícula por nivel** (`NIVEL1`/`NIVEL2`, sala cuna / medio / transición). El encargo
   no lo pedía y no lo conté.
7. **Coordenadas de JUNJI e Integra en el directorio oficial.** No es que no las midiera:
   no existe cruce posible, porque esas unidades no tienen RBD (§4.2).
8. **Las comunas insulares en las cifras de georreferenciación.** Están contadas en el
   universo (§3.2) y marcadas aparte, pero quedaron fuera de los porcentajes de cobertura,
   que son sobre el continente.

---

## 7. Lo que el dato permite y lo que no

**¿Es georreferenciable con lo que ya hay en el repositorio?** Sí, y sin fuente externa:
**99,40 % de las unidades continentales y 99,73 % de los niños**. El hallazgo que cambia el
plan es que la georreferencia ya viene **dentro del propio archivo de matrícula**
(`LATITUD`/`LONGITUD`, columnas que el encargo no anticipaba), y que para las 934 unidades
comparables coincide con el directorio oficial **al metro, en el 100 % de los casos**. El
cruce contra el directorio, que el encargo planteaba como el paso decisivo, resulta
redundante: aporta 0 unidades nuevas. El déficit remanente son 8 unidades / 177 niños, y
está concentrado en INTEGRA Administración Directa (7 de las 8).

**¿Son distinguibles JUNJI, Integra y VTF?** Sí, con dos columnas y sin directorio aparte.
`ORIGEN` separa las tres fuentes de forma limpia y mutuamente excluyente (1 MINEDUC / 2
JUNJI / 3 INTEGRA), verificado además por la partición perfecta de `RBD`, `ID_ESTAB_J` e
`ID_ESTAB_I`. `TIPO_ESTAB` desagrega **VTF como el valor 6** (174 unidades, 9.956 niños),
dentro de JUNJI y no dentro del origen MINEDUC. La reserva es temporal, no de campo:
`TIPO_ESTAB` no existe en 2011 ni en 2018, así que VTF no es separable hacia atrás.

**¿Capa del mapa regional o producto propio?** El dato no decide esto por sí solo, y lo
digo en vez de opinar. Lo que sí acota la decisión: el universo parvulario regional son
1.345 unidades y 65.771 niños, contra los 1.251 establecimientos que el mapa actual ya
publica — es decir, **agregarlo como capa más que duplica el número de pines**, y 407 de
esas unidades (JUNJI + Integra) no tienen RBD, que es la llave sobre la que está construido
todo el front-end vigente. Ese par de cifras es lo que el turno siguiente tiene que pesar;
este diagnóstico no lo resuelve.
