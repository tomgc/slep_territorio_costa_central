# Traspaso de cierre — v10

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 10
**Entorno:** Claude (conversacional) + Claude Code · **Repo remoto:** `https://github.com/tomgc/slep_territorio_costa_central`
**Tipo de sesión:** CONTINUATION
**Foco:** Diagnóstico del Censo 2024 y decisión de alcance de la capa censal.
**Archivos principales generados:** `50_documentacion/andamios/reporte_diagnostico_censo2024.md`; `50_documentacion/andamios/reporte_viabilidad_manzana_censo2024.md`; `50_documentacion/activa/decisiones/20260712_decision_alcance_censo2024.md`.
**Código tocado:** ninguno. **Pipeline R:** intacto (cuarta sesión consecutiva). **`docs/`:** intacto.

---

## 1. Resumen ejecutivo

Sesión íntegramente de diagnóstico y diseño: **no se escribió una línea de código de producto**. Se ejecutaron dos encargos de medición (Etapa 1 y Etapa 1b) sobre los datos del Censo de Población y Vivienda 2024, que viven en la raíz de datos de otro proyecto (`slep_estudio_oferta_demanda`). El resultado reordena por completo lo que se creía posible: **los indicadores de asistencia escolar existen hasta nivel manzana, sin supresión estadística, y con la geometría ya descargada**. El peso no es obstáculo (Costa Central a nivel manzana: 372–504 KB gzip). El obstáculo real es otro y no es técnico: **la mediana de niños en edad básica por manzana es 3**, lo que hace que una *tasa* a esa escala sea ruido, aunque un *conteo* siga siendo válido. De ahí la decisión estructural de la sesión: **dos capas, dos indicadores, dos escalas** (densidad de NNA a nivel manzana en Costa Central; tasa de asistencia a nivel zona/localidad en la región). Se registran **cinco errores del asistente**, todos del mismo patrón matriz que domina las tablas desde v06, y **todos detectados por el artefacto, no por el asistente**. La sesión deja el proyecto listo para construir, con la decisión de alcance escrita y el criterio de éxito definido.

---

## 2. Estado al cierre

**Funciona (verificado contra el artefacto):**
- **Repositorio:** sin divergencia con el remoto, sin commits pendientes (`git log --oneline origin/main..main` vacío en ambos encargos). `origin/main` sigue en `b7d9a8a`.
- **Variante 3 (mapa interactivo):** publicada y sin pendientes ejecutables. **No se tocó en esta sesión.**
- **Variantes 1 y 2 (afiches A0):** sin cambios. Bloqueante externo (validación del director) desde v05.
- **Datos del Censo:** microdato + bases agregadas + **cartografía geoparquet completa** (10 capas nacionales), todo verificado presente en la raíz de datos del proyecto padre.

**No funciona / pendiente:**
- **El cierre de la sesión 9 sigue sin commitear** (8 archivos: `ESTADO.md`, snapshots del escáner, `traspaso_cierre_v09.md`). La compuerta de FASE 0 lo detectó en ambos encargos y se detuvo correctamente. **Es la primera acción mecánica de la sesión 11**, ahora acumulando también el cierre de esta sesión.
- Las copias de `POLITICA_PROYECTO.md` y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` en `50_documentacion/activa/` siguen desactualizadas respecto de la knowledge base (POLITICA v5.2, SETTINGS v7). Heredado de v07, v08 y v09 sin corregir: **tarea manual del titular.**
- `50_documentacion/activa/decisiones/diagnostico_migracion_github.R` sigue siendo un `.R` en carpeta de `.md`. Deuda trivial heredada de v08.
- **La capa censal no está construida.** Esta sesión decidió qué construir, no lo construyó.

**Delta respecto a v09:** v09 dejó el mapa interactivo sin pendientes ejecutables y declaró el Censo 2024 como "el único frente sustantivo abierto que no depende de terceros". Esta sesión lo abrió, lo diagnosticó a fondo y lo dejó **especificado y listo para construir**, con una decisión de alcance formal y un criterio de éxito verificable. **La ruta v09 asumía que existía un encargo del Censo ya escrito en `andamios/`. No existía** (ver §7, error #1). El diagnóstico partió de cero.

---

## 3. Registro detallado de cambios

### 3.1 Diagnóstico del Censo 2024 — Etapa 1 (datos disponibles)
Categoría temática: **Diagnóstico y exploración de datos**.

Encargo de solo lectura sobre la raíz de datos del proyecto padre. Seis fases: inventario físico, estructura de las bases agregadas, universo de la Región de Valparaíso, supresión estadística, cartografía, llave de unión.

**Resultados que decidieron la sesión:**

| Hallazgo | Valor medido |
|---|---|
| **Asistencia escolar en las bases agregadas** | **SÍ existe, hasta nivel manzana:** `n_asistencia_parv`, `n_asistencia_basica`, `n_asistencia_media`, `n_asistencia_superior`, en las tres bases |
| Tramos etarios | `n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17` — **calzan exactamente con parvularia / básica / media** |
| Supresión en variables escolares (R5) | **0 %.** Una sola celda (`n_asistencia_superior`) |
| Marcador de supresión del INE | `*` — confirmado empíricamente: 8.702 celdas en `n_pueblos_orig` de la R5 |
| Universo R5 | 23.742 manzanas / 1.263 zonas-localidades. Costa Central: 4.910 manzanas / 201 zonas |
| Encoding | UTF-8 **con BOM**, separador `;` |
| Cartografía | **Ausente en ese momento.** Único bloqueo de la Etapa 1 |

**La compuerta de FASE 0 operó como debe** (ver §5.1): detectó los 8 archivos del cierre v09 sin commitear, **reportó y preguntó**, sin declarar nada legítimo por su cuenta.

### 3.2 Diagnóstico del Censo 2024 — Etapa 1b (viabilidad de la manzana)
Categoría temática: **Diagnóstico y exploración de datos**.

Tras la descarga de la cartografía por el titular, encargo de medición empírica: peso, joins, indeterminación, densidad del indicador. Artefactos de prueba escritos a `/tmp/censo_diag/`, **fuera del repo**.

**Resultados:**

| Dimensión | Valor medido |
|---|---|
| **CRS de origen** | **EPSG:4674 (SIRGAS 2000), en grados.** No es UTM |
| Driver Parquet en GDAL | **Ausente.** Lectura vía `arrow` + reconstrucción desde WKB (columna `SHAPE`) |
| Manzanas en el país | **216.341** (la presentación del INE dice 168.295) |
| Manzanas R5 (cartografía) | 26.662 features |
| **Peso Costa Central, manzana, gzip** | **372–504 KB** (5.983 polígonos) |
| **Peso región continental, manzana, gzip** | **1,6 MB** |
| Colapso por simplificación (Costa Central) | 20 m → 835 de 5.983 (**14 %**); **5 m → 230 (3,8 %)** |
| **Indeterminación en Costa Central** | **0,79 %** en el dato (39 manzanas), **0 % dibujadas.** Muy por debajo del 13,1 % regional de la Nota Técnica n°5 |
| **Mediana de `n_edad_6_13` por manzana** | **3 niños** |
| **Manzanas con cero niños en edad básica (CC)** | **28,5 %** |
| Indicador calculable a nivel zona | **99,4 %** |
| Joins CSV ↔ cartografía | **No 1:1** — pero **falso problema**: la cartografía ya trae los indicadores incrustados, con 0 NA en Costa Central |
| Capa zonal | **Solo urbana** (694 polígonos en R5). 536 localidades rurales tienen dato sin geometría zonal |

### 3.3 Decisión de alcance
Categoría temática: **Decisión de diseño / arquitectura de producto**.

Archivo generado: `50_documentacion/activa/decisiones/20260712_decision_alcance_censo2024.md`. Contenido completo ahí; el núcleo se reproduce en §6.

---

## 4. Bugs de la sesión

**Ninguno.** No se tocó código de producto. El pipeline R lleva **cuatro sesiones consecutivas** sin modificarse.

**Incidencia menor reportada por Claude Code, no un bug del producto:** su primer intento de la función de gzip (con `system2()` mal citado) dejó un archivo basura llamado `-c` (99 bytes, solo un mensaje de error de bash, sin datos sensibles) en la raíz del repo. Lo detectó **su propio panel adversarial**, lo inspeccionó antes de borrar, y lo eliminó. El working tree quedó limpio. **Se registra porque el mecanismo funcionó, no porque el archivo importara.**

---

## 5. Aprendizajes y restricciones descubiertas

### 5.1 La compuerta rediseñada en v09 funcionó, y esta es su primera evidencia

v09 (§5.2) concluyó que *"una compuerta correcta no enumera lo esperado; reporta lo que hay y detiene ante lo inesperado, sin lista previa"*. Los dos encargos de esta sesión fueron los primeros escritos con ese diseño.

**Resultado:** en ambos, Claude Code se detuvo ante los 8 archivos del cierre v09, **reportó el output literal y preguntó**, con la frase exacta *"No los declaro legítimos — te los reporto"*. No hubo lista blanca que contaminar, porque no había lista. **La corrección de v09 se valida empíricamente.** Es el primer aprendizaje de la cartera que se confirma en la sesión siguiente a su formulación.

### 5.2 Un conteo tolera la desagregación fina; un cociente no

**Este es el aprendizaje más transferible de la sesión, y es de método, no de este proyecto.**

Los datos de asistencia existen a nivel manzana y no están suprimidos. La tentación (y el pedido inicial del titular) era mapear la **tasa de asistencia** a esa escala. La medición lo impide: con una mediana de 3 niños por manzana, una tasa salta de 67 % a 100 % **por un solo niño**. El mapa mostraría ruido con apariencia de precisión, invitando a leer un patrón inexistente. **Es peor que no tener el mapa.**

El mismo dato, expresado como **conteo** (`n_edad_6_13 = 3`), es perfectamente válido: 3 niños son 3 niños.

**Regla: antes de mapear una tasa a una escala fina, mirar la distribución del DENOMINADOR, no solo la disponibilidad del numerador.** La disponibilidad del dato no implica la validez del indicador. Aplicable a cualquier proyecto de la cartera que construya indicadores territoriales.

### 5.3 El folleto no es el dato

Tres cifras de la documentación oficial del INE resultaron falsas al contrastarlas:

- La presentación declara **168.295 manzanas**; el parquet tiene **216.341**.
- La Nota Técnica n°5 declara **13,1 % de indeterminación** en Valparaíso; en Costa Central es **0,79 %** (la cifra regional no describe el subterritorio).
- El diccionario y las presentaciones sugerían que la asistencia **no estaba** en las bases agregadas; **sí está**, en las tres.

**Regla: la documentación de una fuente externa es una hipótesis sobre el dato, no el dato. Se verifica contra el archivo, siempre.** Esto es una variante del patrón matriz del asistente (§7), pero aplicada a fuentes de terceros, y merece registro propio porque el reflejo de confiar en el PDF oficial es fuerte.

### 5.4 CRS: se mide en metros, se dibuja en grados

El parquet del INE viene en **EPSG:4674 (SIRGAS 2000)**, ya en grados. El supuesto de que vendría en UTM era falso.

**Regla operativa:** todo procesamiento espacial métrico (buffers, áreas, distancias, `st_simplify()` con tolerancia en metros) exige proyectar a un CRS métrico (EPSG:32719, UTM 19S para Chile central); el último paso antes de escribir el GeoJSON para Leaflet es `st_transform(4326)`. **Simplificar en grados con una tolerancia pensada para metros colapsaría la región a un punto** (una tolerancia de 10 en grados son ~1.100 km).

### 5.5 Los geocódigos del INE son un campo minado de tipado

El diccionario geográfico declara `MANZENT` como `Double` (13 dígitos), `ID_ZONA` como `Double`, `CUT` como `Integer`. `arrow` los lee así por defecto.

Un `double` de 13 dígitos está en zona de riesgo de pérdida de precisión. Un `CUT` como `integer` pierde ceros a la izquierda. **Un join con tipos mezclados no falla: devuelve filas equivocadas en silencio.**

**Regla (POLITICA 5.3.6, reafirmada con caso concreto): todo geocódigo se castea a `character` INMEDIATAMENTE después de leer, antes de cualquier join o filtro.** La verificación es `nchar()` constante contra el ejemplo del diccionario. Claude Code lo hizo y lo reportó: `MANZENT` constante en 13 dígitos, casteo sin pérdida.

### 5.6 Dos APIs de lectura del mismo parquet dieron tipos distintos

`arrow::read_parquet()` devolvió `COD_REGION` como `string`; `arrow::open_dataset()` lo devolvió como `int32`. Claude Code resolvió consultando el schema autoritativo a nivel de archivo (`ParquetFileReader`), en vez de elegir una de las dos.

**Regla: ante discrepancia entre dos lecturas del mismo artefacto, no se elige la conveniente: se consulta la fuente autoritativa.**

---

## 6. Decisiones de diseño

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| **Escala e indicador de la capa censal** | (a) todo a nivel comuna; (b) tasa a nivel manzana; (c) todo a nivel manzana en la región | **Dos capas: densidad de NNA (conteos) a nivel MANZANA en Costa Central; tasa de asistencia a nivel ZONA/LOCALIDAD en la región continental.** Razón: un conteo tolera `n` pequeño, un cociente no (§5.2) |
| **Territorio rural en la capa de asistencia** | (a) solo urbano, rural en blanco; (c) rural cae a comuna | **(b) Zona urbana + localidad rural en una sola capa.** La base agregada del INE (`Base_zona_localidad_CPV24.csv`) las trata como la misma unidad; separarlas contradiría la fuente |
| **Manzanas con cero niños (28,5 % en CC)** | (a) color más claro de la escala; (c) no dibujarlas | **(b) Gris neutro, fuera de la escala, con leyenda propia.** El cero es información, no ausencia; (a) lo disfrazaría de "poco" y (c) borraría el 28,5 % del territorio |
| **Tolerancia de simplificación** | 20 m (14 % de colapso); 10 m | **5 m** (3,8 % de colapso). El residuo se declara, no se oculta |
| **Uso del microdato de personas (18,5 M registros)** | Procesarlo para construir los indicadores | **No se usa.** La cartografía ya trae los indicadores incrustados. Evita además tratar datos personales sensibles de NNA innecesariamente |
| **Ubicación de los insumos del Censo** | (a) leer de la raíz de datos del proyecto padre vía 2ª variable de entorno; (c) construir el producto en el proyecto padre | **(b) Copiar solo lo necesario a la raíz de datos de este proyecto.** (a) acopla dos raíces (POLITICA §6.2 no lo contempla y rompe la reproducibilidad en máquina nueva); (c) parte en dos una sola capa del mapa |
| **Alcance de la manzana** | Región completa (viable: 1,6 MB gzip) | **Acotada a Costa Central.** No por peso, sino por pertinencia (es la herramienta de gestión del territorio propio) y por render no verificado |
| Flujos origen-destino (`p44_lug_trab`) | Incorporarlos como capa | **Descartados de v1.** El Censo no pregunta dónde ESTUDIA el NNA, solo si asiste. `p44_lug_trab` es del adulto trabajador |
| Escolaridad del jefe de hogar como capa | Incorporarla | **Diferida a v2.** Viable, pero alto riesgo de estigmatizar territorios en producto público. Requiere decisión editorial propia |

**Decisión con peso arquitectónico:** la primera. Replicada como archivo en `50_documentacion/activa/decisiones/20260712_decision_alcance_censo2024.md`.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Acuse de recibo (apertura) | El asistente lo detectó al contrastar el traspaso contra el escáner | El traspaso **v09** afirma en dos lugares (§10 pendiente #5, §13) que el encargo del Censo "ya está escrito en `50_documentacion/andamios/`". **No existe.** El escáner lista 24 archivos en `andamios/`, ninguno del Censo | POLITICA 1.2.6 (no operar sobre estado supuesto) | Error cometido **en la sesión 9** al escribir el traspaso: se afirmó la existencia de un artefacto sin verificarla contra el escáner. Es el patrón matriz, cometido *dentro del documento diseñado para transmitir el estado real* | POLITICA 1.2.6 + §11 de v08 y v09 | **Mismo que v09 #1 y #2; v08 #1 y #2; v07 #1, #2, #4; v06 #2 y #4.** Sexta sesión consecutiva |
| 2 | Diagnóstico de granularidad (turno 3) | El artefacto lo desmintió (Etapa 1) | Afirmé que **"la geografía máxima del microdato público es la comuna"** y que por tanto la capa sería comunal. Existen bases agregadas a nivel manzana, zona, localidad y aldea | POLITICA 1.2.6 | Deduje la granularidad del **diccionario del microdato** (que sí es comunal) y la extendí al conjunto de la publicación del Censo, sin haber inventariado los archivos disponibles. Confundí la respuesta a una pregunta con la respuesta a otra | POLITICA 1.2.6 | Variante de v09 #2 (subconjunto tomado por inventario) |
| 3 | Recomendación de nivel (turno 6) | El artefacto lo desmintió (Etapa 1) | Afirmé que **"la supresión estadística muerde fuerte a nivel manzana"** y recomendé zona por esa razón. La supresión en variables escolares de la R5 es **0 %** | POLITICA 1.2.6 | Deduje el efecto de la regla de frecuencia mínima (que existe y está documentada) **razonando sobre el tamaño típico de una manzana**, en vez de medirla. La regla existe; su efecto sobre ESTAS columnas era una pregunta empírica que no hice | POLITICA 1.2.6 | Mismo patrón matriz |
| 4 | Recomendación de nivel (turno 6) | El artefacto lo desmintió (Etapa 1b) | Afirmé que la indeterminación del **13,1 %** de Valparaíso haría las manzanas "no comparables en superficie" en Costa Central. En Costa Central es **0,79 %** | POLITICA 1.2.6 | Apliqué una cifra **regional** a un **subterritorio**, sin verificar que la distribución fuera homogénea. Una cifra agregada no describe a sus partes | POLITICA 1.2.6 | Variante del #2: una cifra que responde una pregunta usada para responder otra |
| 5 | Explicación de CRS (turno 11) | El artefacto lo desmintió (Etapa 1b) | Afirmé que el parquet vendría **"probablemente en UTM (EPSG:32719)"** y construí sobre eso la explicación de la simplificación. Viene en **EPSG:4674 (SIRGAS 2000)**, en grados | POLITICA 1.2.6 | Supuse el CRS desde la convención del INE en otros productos. **Lo marqué como "probablemente", pero razoné después como si fuera un hecho** | POLITICA 1.2.6 | Mismo patrón matriz. Agravante: el propio encargo que yo escribí decía *"reporta el CRS. NO lo asumas"* |
| 6 | Petición de insumos (turno 5) | **El titular lo señaló:** *"es 3era vez que te envío este mapeo"* | Pedí el mapeo de la raíz de datos del Censo que el titular ya había compartido **dos veces antes** | POLITICA 1.2.6 + `userPreferences` (autonomía: pedir solo lo irrecuperable) | No busqué en el historial de la conversación antes de pedir. El dato estaba disponible y era recuperable | POLITICA 1.2.6, `userPreferences` | Nuevo en su forma (pedir lo ya entregado), mismo en su raíz: no verificar antes de afirmar/pedir |

### Patrón cruzado — sexta sesión consecutiva

Los seis errores son **la misma causa raíz**: *afirmar algo sobre el estado real sin contrastarlo contra el artefacto, cuando la verificación era posible*. La regla existe en POLITICA 1.2.6, en SETTINGS, y en el §11 de los tres traspasos anteriores con formato ⚠️/✅.

**Lo que esta sesión aporta al análisis de cartera, y es incómodo:**

Los errores #2, #3, #4 y #5 **no fueron atrapados por una compuerta ni por un panel adversarial.** Fueron atrapados porque **la sesión entera estaba diseñada como medición**: el encargo obligaba a medir precisamente aquello que yo había afirmado. Si el encargo no hubiera exigido reportar el CRS, la supresión y la indeterminación **con la cifra**, los cuatro errores habrían sobrevivido hasta el producto.

Esto refina la conclusión de v09. v09 dijo: *"la compuerta debe estar construida de modo que el asistente no pueda inyectar en ella una expectativa heredada"*. Esta sesión agrega:

> **Las compuertas protegen el ESTADO (¿qué hay en el repo?), pero no protegen el DIAGNÓSTICO (¿qué es cierto sobre el dato?).** Un asistente puede pasar todas las compuertas de gobernanza y aun así construir un producto entero sobre cinco supuestos falsos. La única defensa contra eso es **exigir que cada afirmación de diagnóstico se convierta en una medición antes de convertirse en una decisión**.
>
> Operativamente: **toda cifra que sostiene una recomendación debe tener un comando que la produzca.** Si la recomendación se sostiene en una deducción ("una manzana típica tiene pocos habitantes, luego la supresión morderá"), la deducción **es la hipótesis del encargo, no su premisa**.

**Nota metodológica sobre este registro:** los errores #2 a #5 se cometieron y se corrigieron **dentro de la misma sesión**, y ninguno llegó a un artefacto. Se registran igual, porque POLITICA 0.5 tiene disparador exhaustivo: *cualquier desviación de una regla canónica, se haya nombrado como error o no*. Omitirlos porque "el proceso los atrapó" sería exactamente la clase de filtro que hace invisible el patrón.

---

## 8. Constantes y parámetros vigentes

Ninguna constante del pipeline R se tocó. Constantes **definidas en la decisión de alcance**, aún no implementadas en código:

| Constante | Valor | Destino | Nota |
|---|---|---|---|
| `TOLERANCIA_SIMPLIFICACION_M` | `5` | Script de construcción de la capa (Etapa 2) | En metros, aplicada en CRS proyectado. A 20 m colapsan 14 % de las manzanas; a 5 m, 3,8 % |
| `CRS_ORIGEN` | `4674` | Idem | SIRGAS 2000, grados. **Verificado, no asumido** |
| `CRS_METRICO` | `32719` | Idem | UTM 19S. Solo para operaciones métricas (simplificar, buffers, áreas) |
| `CRS_WEB` | `4326` | Idem | Obligatorio para Leaflet |
| `COMUNAS_COSTA_CENTRAL` | `c("5103", "5105", "5107", "5109")` | Idem | Concón, Puchuncaví, Quintero, Viña del Mar. **Como `character`** |
| `TOL_VALIDACION_TASA` | por definir | Idem | Tolerancia de convergencia entre la tasa agregada desde zonas y la cifra oficial de `P7_Educacion.xlsx` hoja 8 |

Constantes de gobernanza (verificadas, sin cambios respecto de v09):

| Regla | Valor | Archivo |
|---|---|---|
| Ignore de intermedios | `40_salidas/mapa_interactivo/*.rds` | `.gitignore:83` |
| Ignore de sistema | `.claude/` | `.gitignore:32` |

---

## 9. Arquitectura de archivos

**Escáner:** el de apertura (`estructura_actual.md`, corrida de 2026-07-12 12:24:24, **381 entradas / 75 carpetas / 306 archivos**) sigue vigente en lo estructural. **No se re-ejecutó al cierre de esta sesión.**

**Archivos nuevos generados por esta sesión** (todos en `50_documentacion/`, ninguno commiteado):
- `andamios/reporte_diagnostico_censo2024.md` (Etapa 1)
- `andamios/reporte_viabilidad_manzana_censo2024.md` (Etapa 1b)
- `activa/decisiones/20260712_decision_alcance_censo2024.md`
- `traspasos/traspaso_cierre_v10.md` (este documento)

**Nada más se tocó.** Verificado por Claude Code en ambos paneles adversariales: `docs/` intacto, ningún script del pipeline modificado, nada escrito en la raíz de datos del proyecto padre. Los artefactos de medición viven en `/tmp/censo_diag/`, fuera del repo.

**Deuda estructural heredada, no corregida** (idéntica a v08 y v09): copias desactualizadas de POLITICA/SETTINGS en `activa/`; `diagnostico_migracion_github.R` en carpeta de decisiones.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | **Commit y push del cierre de las sesiones 9 y 10** | Gobernanza | Baja | Acumula: `ESTADO.md`, snapshots del escáner, `traspaso_cierre_v09.md`, más los cuatro archivos nuevos de esta sesión. **Primera acción mecánica de la sesión 11.** Commits separados por tipo conceptual (POLITICA 9.7). El remoto está en `b7d9a8a` |
| 2 | **Copiar los insumos del Censo a la raíz de datos de este proyecto** | Bloqueante de la Etapa 2 | Baja | **Tarea manual del titular.** Cuatro archivos (ver decisión de alcance §8): los tres parquet (Zonal, Manzanas, Localidades) y `P7_Educacion.xlsx`. Sin esto la Etapa 2 no arranca |
| 3 | **Etapa 2: construcción de la capa censal** | Funcionalidad nueva | **Alta** | El frente principal. Decisión de alcance escrita; criterio de éxito definido. Sesión dedicada. Ver §11 |
| 4 | **Prueba de humo de render en Leaflet** | Riesgo abierto | Media | ~6.000 polígonos. La Etapa 1b midió transferencia (KB), **no FPS de pintado**. Debe verificarse **antes** de comprometer la capa de manzana, no después |
| 5 | **Validación contra `P7_Educacion.xlsx` hoja 8** | QA / validación | Media | La tasa agregada por comuna desde las zonas debe converger a la cifra oficial del INE. **Criterio de éxito #1 de la decisión de alcance** |
| 6 | Nota metodológica de la capa censal | Contenido | Baja | Debe declarar: 3,8 % de manzanas colapsadas por simplificación; 0,79 % de indeterminadas; la exclusión del denominador de la tasa neta (no-respuesta a preguntas 33 y 34) |
| 7 | Sincronizar POLITICA y SETTINGS del repo con la knowledge base | Deuda heredada | Baja | **Tarea manual del titular.** Heredado de v07, v08, v09 |
| 8 | Mover `diagnostico_migracion_github.R` fuera de `activa/decisiones/` | Deuda heredada | Trivial | Agrupar con otro trabajo |
| 9 | Favicon del sitio | Cosmética | Trivial | Heredado de v09. Agrupar con cualquier trabajo sobre `docs/` |
| 10 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Abierto desde v05 |
| 11 | Validación con el equipo experto (mapa) | Bloqueante externo | — | Abierto desde v06 |
| 12 | Decidir visibilidad del sitio Pages | Decisión estratégica | Baja | Heredado |
| 13 | Escolaridad del jefe de hogar como capa (v2) | Funcionalidad nueva | Media | Diferida por riesgo editorial (estigmatización territorial) |
| 14 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Heredado |
| 15 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Heredado |

**Evaluación de deuda técnica:** ninguna zona frágil. El pipeline R no se toca hace **cuatro sesiones consecutivas**. La deuda documental sigue en los mismos dos ítems triviales (#7, #8), ambos heredados sin cambio desde v07/v08.

**Auditoría de cierre (política 5.6):**
- ¿El pipeline corre de cero sin intervención manual? **Parcial, sin cambios.** `sincronizar_docs.sh` sigue siendo manual y documentado. Deuda declarada y aceptada. Esta sesión **no** lo corrió (correctamente: no regeneró datos).
- ¿Cada transformación crítica tiene validación? **Sí.** No se tocó nada del pipeline.
- ¿Outputs reproducibles e idempotentes? **Sí**, sin cambios.
- ¿Decisiones metodológicas como constantes nombradas? **Sí**, y esta sesión definió seis constantes nuevas (§8) **antes** de escribir el código que las usará, no después.
- ¿Nombres sin tildes/ñ/espacios? **Sí** en todo lo generado.

Ninguna respuesta "no". No se agregan pendientes por auditoría.

**Ruta sugerida sesión 11:** (1) commit y push del cierre acumulado de v09 + v10 (mecánico); (2) copia de insumos por el titular (manual); (3) **Etapa 2: construcción de la capa censal**, con la prueba de humo de render como primer hito, no como último. Los pendientes #7, #8 y #9 se agrupan con cualquier trabajo.

---

## 11. Instrucciones específicas para la próxima sesión

- ⚠️ **Toda afirmación sobre el estado del repositorio exige el comando que la respalde, en el mismo turno.** Sexta sesión consecutiva registrando este patrón.
- ⚠️ **NUEVO Y CRÍTICO — toda afirmación de DIAGNÓSTICO exige la medición que la respalde, antes de convertirse en recomendación.** Las compuertas protegen el estado del repo, **no protegen el diagnóstico del dato**. Cuatro de los seis errores de esta sesión (§7 #2–#5) pasaron todas las compuertas de gobernanza y solo murieron porque el encargo obligaba a medir lo que yo había afirmado. **Si una recomendación se apoya en una deducción sobre el dato, esa deducción es la hipótesis del encargo, no su premisa.**
- ⚠️ **La documentación de una fuente externa es una hipótesis, no el dato.** Tres cifras oficiales del INE resultaron falsas contra el archivo (manzanas del país, indeterminación de Costa Central, disponibilidad de asistencia en las bases agregadas). Verificar contra el artefacto, siempre.
- ✅ **ANTES de cualquier join o filtro sobre datos del INE, castear TODO geocódigo a `character`** (`MANZENT`, `ID_ZONA`, `CUT`, `ID_ENTIDAD`, `COD_*`). `arrow` los lee como `double`/`int32`. `MANZENT` tiene 13 dígitos. **Un join con tipos mezclados devuelve filas equivocadas en silencio.** Verificar con `nchar()` constante.
- ✅ **ANTES de simplificar geometría, proyectar a EPSG:32719.** El origen es **EPSG:4674 (grados)**, no UTM. Una tolerancia de 5 aplicada en grados son ~550 km.
- ✅ **ANTES de comprometer la capa de manzana, correr la prueba de humo de render.** Se midió transferencia, no FPS.
- 🔒 **El microdato de personas del Censo NO se usa y NO entra al proyecto.** La cartografía ya trae los indicadores agregados. Usarlo significaría tratar datos personales sensibles de NNA sin necesidad (Ley 21.719).
- 🔒 **`docs/data/` solo recibe agregados sin identificador individual.** La capa censal no cambia esta regla.
- 🔒 **La tasa de asistencia NO se mapea a nivel manzana.** Mediana de 3 niños por manzana: el cociente sería ruido. Los conteos sí. Ver §5.2. **Esta no es una restricción técnica sino de honestidad del producto: no la levantes "porque el dato existe".**
- 🔒 `00_run_all.R`, `31`, `32`, `33`, `33b`, `34`, `35`, `36`, `10_*`, maestro: intocables sin instrucción explícita. **No se tocan hace cuatro sesiones.**
- 🔒 `sincronizar_docs.sh` NO se corre en sesiones que no regeneren datos. Verificar su dirección antes de correrlo.
- 🔒 `[hidden] { display: none !important; }` en `estilo.css` es estructural.
- 🔒 El backlog jamás se renumera, reescribe ni resume.
- ✅ **ANTES de incorporar este traspaso al backlog:** el trabajo de la sesión 10 entra como **cambios 29, 30 y 31** (ver §14). Los cambios 26–28 (sesión 9) **siguen pendientes de incorporar**.
- 🔒 Máximo 2 agentes en Claude Code.

---

## 12. Fragmentos de código de referencia

**Lectura de geoparquet del INE (GDAL no trae driver Parquet — vía `arrow` + WKB):**
```r
library(arrow)
library(sf)
library(dplyr)

# El schema autoritativo se consulta a nivel de archivo, no de API:
# read_parquet() y open_dataset() dieron TIPOS DISTINTOS para COD_REGION.
# Ante discrepancia, manda ParquetFileReader.

capa <- arrow::open_dataset(ruta_parquet) |>
  filter(COD_REGION == 5) |>          # filtrar ANTES de reconstruir geometría (memoria)
  collect() |>
  mutate(
    # POLITICA 5.3.6: geocodigos SIEMPRE character, INMEDIATAMENTE tras leer.
    # MANZENT es double de 13 digitos: zona de riesgo de perdida de precision.
    MANZENT = as.character(MANZENT),
    ID_ZONA = as.character(ID_ZONA),
    CUT     = as.character(CUT)
  ) |>
  st_as_sf(geometry = st_as_sfc(SHAPE, EWKB = TRUE), crs = 4674)

# Verificacion obligatoria del casteo (no confiar: comprobar):
stopifnot(length(unique(nchar(capa$MANZENT))) == 1)
```

**Simplificación: se mide en metros, se dibuja en grados.**
```r
CRS_ORIGEN  <- 4674   # SIRGAS 2000 (grados) - VERIFICADO, no asumido
CRS_METRICO <- 32719  # UTM 19S - solo para operaciones metricas
CRS_WEB     <- 4326   # obligatorio para Leaflet
TOLERANCIA_SIMPLIFICACION_M <- 5   # a 20 m colapsan 14% de las manzanas; a 5 m, 3,8%

capa_web <- capa |>
  st_transform(CRS_METRICO) |>                          # a metros
  st_simplify(dTolerance = TOLERANCIA_SIMPLIFICACION_M) |>
  st_transform(CRS_WEB)                                 # a grados, para el navegador

# El 3,8% que colapsa a geometria vacia SE DECLARA, no se oculta:
n_vacias <- sum(st_is_empty(capa_web))
message("Geometrias colapsadas por simplificacion: ", n_vacias, " de ", nrow(capa_web))
```

**La forma correcta de una compuerta (validada empíricamente en esta sesión):**
```bash
# NO enumera lo esperado. REPORTA lo que hay y DETIENE ante lo inesperado.
# "Corre y reporta el output literal. DETENTE si aparece cualquier archivo que este
#  encargo no explique, y consulta antes de proceder."
# -> El titular decide que es legitimo. El asistente no pre-declara nada.

git status --short --branch
git log --oneline origin/main..main
git log --oneline main..origin/main
```

**El check que ninguna compuerta hace, y que esta sesión demostró necesario:**
```r
# Antes de mapear CUALQUIER tasa a escala fina: mirar el DENOMINADOR.
# La disponibilidad del numerador no implica la validez del indicador.
summary(datos$n_edad_6_13)        # mediana = 3 -> una tasa aqui es RUIDO
mean(datos$n_edad_6_13 == 0)      # 28,5% -> celdas vacias, no dato faltante
```

---

## 13. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 11 (Construcción capa Censo)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior, el escáner re-ejecutado al abrir, y la decisión de alcance del Censo 2024. El foco de esta sesión es la construcción de la capa censal (Etapa 2).

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar; solo verificar que esté al día): `POLITICA_PROYECTO.md` (v5.2), `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (v7).
2. *Específicos de la sesión (SÍ adjuntar)*:
   - `traspaso_cierre_v10.md` (este documento).
   - `estructura_actual.md` **re-ejecutado al abrir** (el de esta sesión quedó desactualizado: se generaron cuatro archivos nuevos).
   - `50_documentacion/activa/decisiones/20260712_decision_alcance_censo2024.md` — **imprescindible**: es el contrato de lo que se va a construir.
   - `50_documentacion/andamios/reporte_viabilidad_manzana_censo2024.md` — **imprescindible**: todas las cifras que fundan la decisión.
3. *Opcionales según el foco real*:
   - `50_documentacion/andamios/reporte_diagnostico_censo2024.md` (Etapa 1) si se necesita el detalle de las bases agregadas.
   - `CLAUDE.md` si la sesión correrá en Claude Code (**lo hará**).
   - `docs/assets/mapa.js` y `docs/assets/estilo.css` cuando se llegue al hito de front-end (voluminosos: adjuntar solo en ese momento).
   - `backlog_acumulativo.md` si se van a incorporar los cambios 26–31 (**pendientes: los de v09 y los de v10**).

**Nota final:** el remoto quedó sincronizado hasta **`b7d9a8a`**. El cierre de las sesiones 9 **y** 10 queda **sin commitear**: es la primera acción mecánica de la sesión 11. Verificar al abrir con `git status --short --branch` y `git log --oneline origin/main..main`, **no asumirlo desde este párrafo**.

**Bloqueante para arrancar la Etapa 2:** el titular debe copiar cuatro archivos del Censo a la raíz de datos de este proyecto (pendiente #2). Sin eso, la sesión 11 no puede construir.

---

## 14. Delta del backlog acumulativo

**Estado del backlog al cierre:** el `backlog_acumulativo.md` commiteado en `9f39df5` llega al **cambio 25** sin saltos. **Los cambios 26–28 (sesión 9) siguen pendientes de incorporar.**

**Entradas pendientes de incorporar: 6** (3 de la sesión 9 + 3 de la sesión 10).

De la **sesión 9** (declarados en v09 §14, aún no incorporados):

| # | Cambio | Categoría temática |
|---|---|---|
| 26 | Re-chequeo visual del mapa interactivo y corrección de los dos defectos hallados | *Corrección de front-end* |
| 27 | Unificación de la identidad cromática al azul institucional `#0D2E52` | *Identidad visual* (categoría propuesta en v09) |
| 28 | Publicación en GitHub Pages: tres commits y push a `origin/main` | *Gobernanza y versionado* |

De la **sesión 10** (esta):

| # | Cambio | Categoría temática |
|---|---|---|
| **29** | Diagnóstico del Censo 2024, Etapa 1: inventario de datos disponibles, estructura de las bases agregadas, universo de la Región de Valparaíso, supresión estadística. Confirma que los indicadores de asistencia existen hasta nivel manzana con supresión 0 % | *Diagnóstico y exploración de datos* |
| **30** | Diagnóstico del Censo 2024, Etapa 1b: medición empírica de viabilidad a nivel manzana (peso, joins, indeterminación, densidad del indicador). Establece que el peso no es obstáculo y que la mediana de 3 niños por manzana invalida la tasa a esa escala | *Diagnóstico y exploración de datos* |
| **31** | Decisión de alcance de la capa censal: dos capas, dos indicadores, dos escalas (densidad a nivel manzana en Costa Central; tasa de asistencia a nivel zona/localidad en la región). Archivo de decisión formal | *Decisión de diseño / arquitectura de producto* |

Fila del resumen estadístico a agregar: `10 | v10 | 3 (29–31) | — | Diagnóstico Censo 2024 y decisión de alcance`.

**Refinamientos de taxonomía a evaluar (dos):**

1. **`Identidad visual`** — propuesta en v09 para el cambio 27. **Sigue pendiente de decisión del titular.**
2. **`Diagnóstico y exploración de datos`** — **propuesta nueva.** Los cambios 29 y 30 no caen en ninguna de las 13 categorías vigentes: no son *corrección*, ni *funcionalidad nueva*, ni *QA y validación* (que valida un producto existente contra un criterio, no explora una fuente nueva para decidir si hay producto). Son trabajo de **investigación previa a la construcción**, y el proyecto va a producir más de ellos (jardines JUNJI/Integra, territorio insular). **Recomendación: crearla.** Si el titular prefiere no ampliar la taxonomía, caen en *funcionalidad nueva* con una nota, pero la clasificación sería imprecisa y perdería la distinción entre "construí algo" y "averigüé si se podía construir".
