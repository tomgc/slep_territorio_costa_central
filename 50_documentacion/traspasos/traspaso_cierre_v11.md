# Traspaso de cierre — v11

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 11
**Entorno:** Claude (conversacional) + Claude Code · **Repo remoto:** `https://github.com/tomgc/slep_territorio_costa_central`
**Tipo de sesión:** CONTINUATION
**Foco:** Etapa 2 del Censo 2024 — cierre del riesgo de render, diagnóstico de la capa zonal, y decisión del indicador de asistencia.
**Archivos principales generados:** `50_documentacion/andamios/reporte_render_manzana_censo2024.md`; `50_documentacion/andamios/reporte_diagnostico_zonal_censo2024.md`; `50_documentacion/activa/decisiones/20260712_decision_indicador_asistencia_censo2024.md`; nota de superseción en `20260712_decision_alcance_censo2024.md`; `.gitignore` (bloque del Censo).
**Código de producto tocado:** ninguno todavía. El encargo del Hito 2b (`37_construir_capa_manzana.R`) quedó **entregado a Claude Code y corriendo al cierre**; su resultado no está verificado en este traspaso.

---

## 1. Resumen ejecutivo

Sesión de gobernanza, medición y decisión, con el primer encargo de código de producción entregado (pero **no verificado**) al cierre. Se cerró el pendiente #1 heredado (cierre v09+v10 commiteado y pusheado: `b7d9a8a` → `a508b98`, cinco commits separados por tipo conceptual). Se selló la gobernanza de los 309 MB de geoparquet del Censo (doble sello en `.gitignore`: ruta + extensión), verificado con `git check-ignore` y con `size-pack` sin variación tras el push. Se cerró el **riesgo abierto #1** del contrato (render de ~6.000 polígonos): medido en un navegador real con GPU, la capa de manzana es viable con renderer **Canvas**. Y el hallazgo que reordena el producto: **la tasa de asistencia calculada desde el parquet NO es la tasa neta del INE** — la subestima entre 0,53 y 1,35 pp, las 12 celdas del mismo lado, porque el INE excluye la no-respuesta del denominador y ese dato **no existe a escala sub-comunal**. La capa se construye igual, con el indicador rotulado honestamente y la discrepancia declarada. Se decidió **no corregir** la cifra para que calce: sería inventar precisión. Se registran **dos errores del asistente**, ambos del mismo patrón, ambos señalados por el titular.

---

## 2. Estado al cierre

**Funciona (verificado contra el artefacto, no contra el log):**

- **Repositorio:** `origin/main` en `a508b98`. Cierre de las sesiones 9 y 10 commiteado y pusheado en cinco commits separados por tipo conceptual (POLITICA 9.7). El pendiente #1 del traspaso v10 queda **cerrado**.
- **Gobernanza de los insumos del Censo:** los cuatro archivos (309 MB de parquet + `P7_Educacion.xlsx`) están en `20_insumos/censo_2024/`, **sellados** por `.gitignore:94`. Verificado con `git check-ignore -v` (exit 0 en los cuatro) y con `git count-objects -vH`: `size-pack` = 1,05 MiB antes y después del push. **Ningún parquet tocó el historial.**
- **Riesgo #1 del contrato (render), CERRADO.** Chrome 149 headful con GPU real, medido con `puppeteer-core`. Canvas: carga 37 ms, pan FPS mín **57,1** (fluido), zoom FPS mín **23,9** (usable), heap ~30 MB. SVG viable pero peor en todas las métricas (zoom FPS mín 17,2, al borde de la banda).
- **Anatomía de la capa zonal, medida.** Localidades es **MULTIPOLYGON** (no puntual: el rediseño que ese riesgo habría forzado no es necesario), llave real **`ID_LOCALIDAD`** (8 díg., no `ID_ZONA`), indicadores incrustados con 0 NA. Solape urbano ∩ rural = **0,0 ha** (sin doble conteo). Cobertura de área comunal 95,3–99,8 %.
- **Variantes 1, 2 y 3:** sin cambios. El pipeline R (31–36) lleva **cinco sesiones** sin tocarse.

**No funciona / pendiente:**

- **El Hito 2b no está verificado.** El encargo de `37_construir_capa_manzana.R` se entregó a Claude Code y quedó corriendo al cerrar. **La sesión 12 NO debe asumir que corrió bien.** Verificar contra el artefacto (§11).
- **La capa zonal no está construida.** Su decisión está escrita; su script (`38_construir_capa_zonal.R`) no existe.
- **El backlog no se pudo incorporar.** `backlog_acumulativo.md` no estuvo disponible en esta sesión. El delta queda en §14 con la instrucción exacta; la consolidación es la primera acción de la sesión 12.
- Deuda heredada sin cambio (v07, v08, v09, v10): copias desactualizadas de POLITICA/SETTINGS en `activa/`; `diagnostico_migracion_github.R` en carpeta de decisiones.

**Delta respecto a v10:** v10 dejó el Censo "especificado y listo para construir". Esta sesión descubrió que **la especificación estaba mal en su núcleo**: el indicador de la capa zonal no era construible como se había escrito. El contrato se corrigió por medición, no por opinión. Y el riesgo de render, que v10 dejó abierto y sin cifra, quedó cerrado con cifra.

---

## 3. Registro detallado de cambios

### 3.1 Commit y push del cierre acumulado (sesiones 9 y 10)
Categoría temática: **Gobernanza y versionado**.

Cinco commits separados por tipo conceptual, nunca `git add .`, cada uno verificado con `git status --short` antes de commitear:

| Commit | Contenido |
|---|---|
| `35d88e5` | `docs(traspasos)`: cierres v09 y v10 |
| `ff19a5c` | `docs(decisiones)`: alcance de la capa censal |
| `a094840` | `docs(andamios)`: diagnóstico y viabilidad del Censo |
| `691d2a1` | `chore(gobernanza)`: `.gitignore` del Censo + `ESTADO.md` |
| `a508b98` | `chore(estructura)`: snapshots del escáner y poda de retención 2 |

**Observación no corregida (cosmética):** el commit 5 quedó registrado por Git como **4 renames**, no como 4 bajas + 4 altas. Git emparejó los snapshots podados con los nuevos por similitud de contenido (son escaneos del mismo árbol a horas distintas). El árbol resultante es correcto; el historial dice "renombré 084250 → 133656", que no es lo que pasó (la poda borró, el escáner creó). No amerita un rewrite. Se registra para que nadie lo lea como evidencia de un rename deliberado.

### 3.2 Sellado de los insumos del Censo en `.gitignore`
Categoría temática: **Gobernanza y versionado**.

Bloque nuevo con **doble sello deliberado**: por ruta (`20_insumos/censo_2024/`, robusto si el árbol cambia) y por extensión (`*.parquet`, robusto si un parquet aparece en otro lado). El `.gitignore` de este proyecto es de Rama A y sella por ruta, no por tipo: **`*.parquet` no estaba cubierto por ninguna regla previa**. Sin este bloque, un `git add .` distraído habría metido 309 MB al historial (la purga de historial ya se sufrió en la sesión 8, `20260628_purga_historial_op3_log.md`).

### 3.3 Hito 1 — Prueba de humo de render (riesgo #1, CERRADO)
Categoría temática: **Diagnóstico y exploración de datos**.

Archivo: `50_documentacion/andamios/reporte_render_manzana_censo2024.md`.

**Es la primera vez en varias sesiones que una afirmación de rendimiento llega con una medición detrás y no con una deducción.** Se midió en navegador real (Chrome 149 headful, GPU de macOS, `puppeteer-core` sobre el Chrome del sistema), no en headless por software, para que los FPS reflejen la ruta de render real.

| Métrica | SVG | **Canvas** |
|---|---:|---:|
| Carga hasta primer pintado (ms) | 63 | **37** |
| Pan — FPS mínimo | 38,6 | **57,1** |
| Zoom — FPS mínimo | 17,2 | **23,9** |
| Δ heap por la capa (MB) | 31,6 | **30,0** |

Fase 1 (medido): 5.983 features filtrados, **230 colapsadas** (3,84 %) por la simplificación a 5 m, 5.753 escritas, **412,7 KB gzip** medido.

**Veredicto:** viable con **Canvas**. El zoom queda en banda "degradado pero usable" en **ambos** renderers; Canvas no lo saca de la banda, solo lo aleja del borde. El estrés de zoom es sintético y peor que el uso real (zoom fraccional continuo con `zoomSnap:0` y `animate:false` reproyecta todos los vértices en cada frame), pero **eso es una hipótesis, no una medición**: el zoom real no se midió.

**Caveat que decidió el producto:** una sola máquina, la del titular, con GPU de macOS. Un notebook institucional o un móvil rinde por debajo. La cifra es un techo, no un piso, en la dimensión que más importa (el cliente real).

### 3.4 Decisión: carga bajo demanda de la capa de manzana
Categoría temática: **Decisión de diseño / arquitectura de producto**.

La capa de manzana se compromete, con Canvas, **apagada por defecto y activable por toggle explícito**. El GeoJSON no se descarga ni se pinta hasta que alguien la enciende (carga diferida: el `fetch` ocurre al primer encendido, no al cargar la página). Quien no la pide no paga el costo.

**Razón:** el zoom quedó en banda "usable", no "fluido", y solo se midió en una máquina. El toggle convierte un riesgo de dispositivo desconocido en una elección del usuario, sin comprometer la decisión de alcance.

**Evolución condicionada:** si el rendimiento se valida en varias máquinas (notebooks institucionales, no solo la del titular), el toggle puede evolucionar a **activación por umbral de zoom** (la capa aparece sola al acercarse). Queda como pendiente de v2, **condicionado a evidencia de más dispositivos**. No se construye ahora.

**Nota de diseño:** la capa **zonal** no queda sujeta a este toggle (126 K gzip, 692 features, sin problema de render). Se trata como capa normal, con su propio control, sin diferir.

### 3.5 Hito 2a — Diagnóstico de la capa zonal
Categoría temática: **Diagnóstico y exploración de datos**.

Archivo: `50_documentacion/andamios/reporte_diagnostico_zonal_censo2024.md`.

**Este encargo existió para responder una pregunta, y la respuesta cambió el producto.**

Anatomía (todo medido, nada deducido del diccionario del INE, que ya mintió tres veces):

| Hallazgo | Valor medido |
|---|---|
| Tipo de geometría de Localidades | **MULTIPOLYGON** (no puntual → no hay rediseño) |
| Llave de Localidades | **`ID_LOCALIDAD`** (8 díg., única 532/532). **No** `ID_ZONA` |
| Localidades R5 / Costa Central | 532 / **37** |
| Zonas R5 / Costa Central | 694 / **159** |
| Indicadores incrustados en ambas | **Sí**, 0 NA en R5 y en Costa Central |
| Solape urbano ∩ rural | **0,0 ha** (58 pares comparten solo borde) → **sin doble conteo** |
| Cobertura de área comunal | Concón 95,3 %; Viña 98,8 %; Quintero 99,8 %; Puchuncaví 99,8 % |

**LA PRUEBA DECISIVA — la tasa NO converge, y la razón está identificada:**

Las **12 celdas** (4 comunas × 3 niveles) caen del mismo lado: la proporción del parquet subestima la tasa neta del INE entre **0,53 y 1,35 pp** (media 0,89). No es ruido: es sistemático.

**Causa medida:** el INE **excluye del denominador** a quienes no declararon. La fórmula directa divide por la población en edad oficial completa, que los incluye. Prueba: la no-respuesta *implícita* (`1 − calculada/oficial`) reproduce casi exactamente la columna "Nivel educativo no declarado" (hoja 2). Al corregir por ese factor, la diferencia máxima cae de **1,35 pp a 0,60 pp** y los residuos se centran.

**Consecuencia semántica (la buena noticia):** las columnas del parquet **miden lo que creíamos**. `n_asistencia_basica` cuenta asistencia actual a básica de la población en edad 6–13. El universo y los tramos son correctos; el único delta es el denominador. **Esto verifica empíricamente la semántica que el reporte de viabilidad §8.3 había dejado explícitamente sin verificar.**

**La restricción dura:** la columna de no-respuesta existe **solo a nivel comuna**. El parquet no la trae por zona ni por localidad. **La tasa neta del INE no es reconstruible a escala sub-comunal.** No es una limitación del pipeline: es una limitación del dato publicado.

**Corrección del artefacto sobre el encargo:** la columna se llama **"Nivel educativo no declarado"**, no "Asistencia o nivel educativo no declarado" como decía mi encargo. Claude Code lo señaló. El archivo manda.

### 3.6 Decisión del indicador de asistencia
Categoría temática: **Decisión de diseño / arquitectura de producto**.

Archivo nuevo: `50_documentacion/activa/decisiones/20260712_decision_indicador_asistencia_censo2024.md`. **Supersede** el contrato de alcance en §3 (indicador), §6 (validación) y §10 (criterio de éxito, puntos 1 y 3).

Núcleo, en §6 y §7 de este traspaso. Se optó por **no editar el contrato original**, sino escribir una decisión nueva que lo supersede, más una **nota de trazabilidad** al inicio del original. El original queda como registro de lo que se creía en la Etapa 1b: **el cambio de diseño lo produjo una medición, y esa trazabilidad es el aprendizaje**. Editarlo in situ lo habría borrado.

### 3.7 Encargo del Hito 2b (entregado, NO verificado)
Categoría temática: **Funcionalidad nueva**.

Encargo de `30_procesamiento/37_construir_capa_manzana.R`: primer código de producción del Censo. Entregado a Claude Code y **corriendo al cierre de esta sesión**. Su resultado **no está verificado en este traspaso**.

Decisión de diseño incluida: la capa zonal va en un script **separado** (`38_construir_capa_zonal.R`), no en el mismo. Dos scripts, dos entradas en el orquestador, dos validaciones (un cambio conceptual por intervención). Meter ambas en un encargo mezclaría riesgo cero (manzana, completamente medida) con riesgo alto (zonal, decisión recién escrita).

---

## 4. Bugs de la sesión

**Ninguno.** No se ejecutó código de producto verificado. El pipeline R (31–36) lleva **cinco sesiones consecutivas** sin modificarse.

---

## 5. Aprendizajes y restricciones descubiertas

### 5.1 Una corrección que hace calzar un indicador con la cifra oficial no es, por eso, una corrección correcta

**El aprendizaje más transferible de la sesión, y es de método, no de este proyecto.**

Al descubrir que la proporción del parquet subestima la tasa del INE en ~0,9 pp, existía una corrección disponible que hacía converger la cifra (≤ 0,60 pp): ajustar cada unidad por el factor de no-respuesta de **su comuna**. La tentación es fuerte: el número calza, la validación pasa, el mapa concuerda con la fuente oficial.

**Se descartó.** Ese ajuste asume que la no-respuesta se distribuye **uniformemente dentro de la comuna**, y no existe evidencia de eso. Haría que cada zona afirmara una cifra que nadie midió, con apariencia de precisión.

**Regla: un sesgo conocido y declarado es preferible a una precisión inventada.** Si una corrección se apoya en un supuesto de homogeneidad que no se midió, introduce precisión falsa donde antes había un sesgo honesto. Aplicable a cualquier proyecto de la cartera que reconcilie un cálculo propio con una cifra oficial.

### 5.2 Un test calibrado para tolerar el error conocido no es un test

El reporte del Hito 2a propuso `TOL_VALIDACION_TASA = 1,5 pp` para "envolver" el sesgo sistemático de 1,35 pp ya medido.

**Se rechazó, y con él, el criterio de éxito completo.** Una tolerancia que envuelve el error que ya conocemos **no valida nada**: certifica que el error cabe dentro del umbral. Un test diseñado para pasar no es un test.

**El error de fondo era otro:** se estaba tratando la convergencia con el INE como criterio de éxito **del indicador publicado**, cuando ya se había establecido que ese indicador **no es** el del INE. No tiene por qué converger.

**Regla: antes de fijar la tolerancia de un test, verificar que el test compare dos cosas que deban ser iguales.** Si no lo son, la tolerancia no arregla el test: lo disfraza.

En su lugar se creó `TOL_LECTURA_PARQUET = 0,75 pp`, que valida algo distinto y genuino: **que leímos bien el parquet** (agregar a comuna, corregir por no-respuesta, comparar con la hoja 8). Es un canario de integridad de lectura, no una tolerancia del producto. La corrección se usa **solo** ahí, como instrumento de diagnóstico, y **no entra al producto**.

### 5.3 Dos números de distinta unidad geográfica no se yuxtaponen, aunque las etiquetas sean correctas

El popup de una zona **no** muestra la tasa oficial de su comuna junto a la cifra de la zona. La cifra del INE es comunal; la del mapa es zonal. Ponerlas lado a lado invita a una comparación inválida: una zona con 88 % no está "por debajo" del 95,6 % de su comuna en ningún sentido interpretable, porque el 95,6 % **contiene** a esa zona y la promedia con las demás.

**Regla: el etiquetado correcto no neutraliza la yuxtaposición. Dos números juntos comunican comparación aunque el texto diga otra cosa.** El contraste vive donde sí es legítimo: mismo territorio, misma unidad geográfica.

### 5.4 La medición protege el diagnóstico; el encargo debe estar diseñado para poder fallar

v10 §7 concluyó que *"las compuertas protegen el ESTADO, no el DIAGNÓSTICO"*. Esta sesión aporta el corolario constructivo, y es la razón de que la sesión funcionara:

El encargo del Hito 2a **estaba diseñado para poder invalidar el diseño**. Contenía una condición de parada explícita ("si Localidades son puntos, DETENTE y no sigas") y una prueba decisiva cuyo resultado negativo estaba anticipado y era aceptable ("el encargo PREFIERE un 'no converge' honesto a un 'converge con matices'"). El resultado fue, efectivamente, un "no converge" — y el encargo lo absorbió sin colapsar.

**Regla: un encargo de diagnóstico cuyo único desenlace previsto es la confirmación de la hipótesis no es un diagnóstico: es una ceremonia.** Debe declarar por anticipado qué resultado lo haría fracasar, y qué se haría en ese caso.

### 5.5 Ordenar los hitos por riesgo, no por dependencia

La ruta original (propuesta por el asistente) metía la inspección de Localidades como "fase 0" del encargo de construcción. El titular pidió revisarla. **Estaba mal.**

Mezclar en un encargo una **medición** (resultado incierto) con una **construcción** (que asume ese resultado) contamina la medición: la deducción entra como premisa en vez de como hipótesis. Si Localidades hubiera resultado puntual, el script entero se botaba.

**Regla: la medición cuyo resultado puede invalidar el diseño va en su propio encargo, antes, y sola.** El costo es una vuelta de encargo; el beneficio es no escribir código contra una especificación que puede caer.

---

## 6. Decisiones de diseño

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| **Indicador de la capa zonal** | (a) publicar como "tasa neta INE"; (c) ajustar por no-respuesta para que converja | **(b) Publicar la proporción cruda, rotulada "proporción del grupo en edad oficial que asiste al nivel".** (a) afirma una equivalencia que la medición desmiente; (c) inventa precisión (asume no-respuesta uniforme intra-comuna, no medida) |
| **La discrepancia con el INE** | (a) publicar y no mencionarla; (b) corregirla | **(c) Declararla:** nota metodológica con la magnitud medida (0,53–1,35 pp, siempre a la baja) y su causa. Convierte una discrepancia que el lector va a descubrir en información defendible |
| **Popup de zona/localidad** | (a) mostrar la cifra INE de la comuna junto a la de la zona; (c) solo en hover comunal | **(b) Solo la proporción de la unidad.** El contraste con el INE vive en la nota metodológica y (si existe) en la vista comunal. Ver §5.3 |
| **`TOL_VALIDACION_TASA`** | Fijarla en 1,5 pp (envolvería el sesgo de 1,35) o en 0,75 pp (con ajuste comunal, circular) | **Eliminada.** El indicador publicado no es el del INE: no debe converger. Ver §5.2 |
| **`TOL_LECTURA_PARQUET`** | — | **Creada, 0,75 pp.** Test de integridad de lectura, derivado de la diferencia máxima medida (0,60 pp) más margen de redondeo |
| **Carga de la capa de manzana** | (a) siempre visible; (c) medir en un segundo dispositivo antes de decidir | **(b) Toggle explícito, apagada por defecto, carga diferida.** El zoom quedó en banda "usable" y solo se midió en una máquina |
| **Renderer** | SVG (defecto de Leaflet) | **Canvas (`L.canvas()`).** Gana en las cuatro métricas medidas |
| **Estructura de los scripts** | Un solo `37_construir_capa_censal.R` con ambas capas | **Dos scripts: `37_construir_capa_manzana.R` y `38_construir_capa_zonal.R`.** Un cambio conceptual por intervención; no mezclar riesgo cero con riesgo alto |
| **Cómo documentar el cambio de indicador** | Editar el contrato de alcance in situ | **Decisión nueva que lo supersede + nota de trazabilidad en el original.** Editarlo borraría la evidencia de que el diseño cambió por una medición |

**Decisión con peso arquitectónico:** la primera. Replicada como archivo en `50_documentacion/activa/decisiones/20260712_decision_indicador_asistencia_censo2024.md`.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Turno 3, entrega del bloque de `.gitignore` | **El titular lo corrigió:** *"yo no pego cosas a archivos lo haces tu"* | Entregué un fragmento de `.gitignore` para que el titular lo pegara al final del archivo, en vez del archivo completo actualizado | `userPreferences`, "Code edits — never deliver fragments": entregar el archivo COMPLETO; nunca "pega esto en la línea X" | Traté el `.gitignore` como si no fuera "código", una categoría implícita que la regla no contempla (dice "file", no "script R"). El archivo estaba en mi contexto: no había obstáculo para entregarlo completo | `userPreferences` | Variante del patrón matriz: aplicar una regla al ámbito donde la aprendí, en vez de a su alcance real |
| 2 | Turno 4, entrega del `.gitignore` "completo" | **El titular lo corrigió:** *"me das descargables yo no copio codigo"* | Entregué el archivo completo como bloque de código en el chat, en vez de como archivo descargable | `userPreferences` + POLITICA 0.4: los archivos se entregan para descarga; el titular no copia ni pega contenido | Corregí solo la dimensión que el titular nombró explícitamente ("no pego" → dejé de fragmentar) y no releí la regla completa, que cubre también el **medio de entrega**. Corregí el síntoma nombrado, no la regla | `userPreferences`, POLITICA 0.4 | **Variante inmediata del #1, en el mismo turno en que lo registraba.** Sub-patrón nuevo: *corregir el síntoma señalado en vez de releer la regla que lo contiene* |

**Además, una autocorrección que el titular no tuvo que pedir** (se registra por el disparador exhaustivo de POLITICA 0.5, aunque no llegó a artefacto): en el acuse de recibo afirmé que existía una "discrepancia estructural" entre la decisión de alcance (§8, que dice `<DATA_ROOT>/20_insumos/censo_2024/`) y la arquitectura real del proyecto, concluyendo que el contrato usaba nomenclatura de dos raíces "por inercia". **Era falso.** Este proyecto es de raíz unificada, y en un proyecto de raíz unificada "la raíz de datos del proyecto" **es** `20_insumos/`. El contrato no estaba equivocado; yo le atribuí una arquitectura que no afirma. Causa raíz: afirmé una discrepancia sin leer `10_configuracion.R` ni `.Renviron.example`, que no consulté. **Mismo patrón matriz, séptima sesión consecutiva.**

### Patrón cruzado — séptima sesión consecutiva

Los tres son la misma causa raíz: **afirmar algo sobre el estado real sin contrastarlo contra el artefacto, cuando la verificación era posible.** Los dos primeros son una variante específica y nueva: no leer completa una regla que estaba disponible, y actuar sobre la parte que recordaba.

**Lo que esta sesión aporta al análisis de cartera:** los errores #1 y #2 fueron **corregidos por el titular, no por ninguna salvaguarda del sistema**. Ni el panel adversarial ni la compuerta los habrían atrapado: son errores de **forma de entrega al usuario**, y ningún artefacto los desmiente. Es una clase distinta de los errores de v10 (que un encargo bien diseñado sí atrapó, §5.4). **Los errores de diagnóstico se pueden atrapar con medición; los errores de protocolo de interacción, no: solo los atrapa el titular.** Eso los hace más caros de detectar y más fáciles de repetir.

---

## 8. Constantes y parámetros vigentes

Ninguna constante del pipeline R existente se tocó. Constantes **definidas en esta sesión**, aún no implementadas en código:

| Constante | Valor | Destino | Nota |
|---|---|---|---|
| `TOL_LECTURA_PARQUET` | `0.75` | `38_construir_capa_zonal.R` | Puntos porcentuales. **Derivada de la medición** (máx observado 0,60 pp + margen de redondeo). Test de **integridad de lectura**, NO del indicador |
| ~~`TOL_VALIDACION_TASA`~~ | — | — | **ELIMINADA.** El indicador publicado no es el del INE: no debe converger. Ver §5.2 |
| `PRECISION_COORDENADAS` | `6` | `37_construir_capa_manzana.R` | Decimales del GeoJSON (~0,1 m) |

Constantes heredadas de v10, sin cambio, ahora **confirmadas en producción**:

| Constante | Valor | Nota |
|---|---|---|
| `CRS_ORIGEN` | `4674` | SIRGAS 2000, grados. Verificado en las tres capas (Manzanas, Zonal, Localidades) |
| `CRS_METRICO` | `32719` | UTM 19S. Solo operaciones métricas |
| `CRS_WEB` | `4326` | Obligatorio para Leaflet |
| `TOLERANCIA_SIMPLIFICACION_M` | `5` | Colapsa 230 de 5.983 (3,84 %), **medido dos veces** (Etapa 1b y Hito 1) |
| `COMUNAS_COSTA_CENTRAL` | `c("5103","5105","5107","5109")` | Como `character` |

Constantes de gobernanza:

| Regla | Valor | Archivo |
|---|---|---|
| Sello del Censo (ruta) | `20_insumos/censo_2024/` | `.gitignore:94` |
| Sello del Censo (extensión) | `*.parquet` | `.gitignore:95` |
| Ignore de intermedios | `40_salidas/mapa_interactivo/*.rds` | `.gitignore:83` |

---

## 9. Arquitectura de archivos

**Escáner:** `estructura_actual.md`, corrida de **2026-07-12 14:32:16**, **395 entradas / 77 carpetas / 318 archivos**. Re-ejecutado al cierre.

**Verificado contra el escáner (no contra el log):**
- Las dos decisiones están en disco: `20260712_decision_indicador_asistencia_censo2024.md` (12,39 K, nueva) y `20260712_decision_alcance_censo2024.md` (13,85 K, con la nota de superseción — creció desde 12,39 K).
- Los tres reportes de andamios del Censo están: `reporte_render_manzana_censo2024.md` (6,57 K), `reporte_diagnostico_zonal_censo2024.md` (12,03 K), más los dos de v10.
- Los cuatro insumos del Censo están en `20_insumos/censo_2024/` (309 MB de parquet + `P7_Educacion.xlsx`), sellados.
- **`37_construir_capa_manzana.R` NO existe** en el escáner de cierre. **`docs/data/censo_manzanas_cc.geojson` NO existe.** El Hito 2b estaba corriendo al cerrar; su resultado no está en este snapshot. **La sesión 12 debe verificar su estado real, no asumirlo desde este traspaso.**

**Deuda estructural heredada, no corregida** (idéntica a v08, v09, v10): copias desactualizadas de POLITICA/SETTINGS en `activa/`; `diagnostico_migracion_github.R` en carpeta de decisiones.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | **Verificar el resultado del Hito 2b** (`37_construir_capa_manzana.R`) | Bug activo potencial | Baja | **PRIMERA ACCIÓN DE LA SESIÓN 12.** El encargo quedó corriendo al cierre; su resultado NO está verificado. Auditar contra el artefacto: el script existe, el GeoJSON existe, `MANZENT` es string en el JSON, las manzanas con cero están presentes con valor 0 (esperado ~1.474), el peso gzip es el medido. **No asumir que corrió bien** |
| 2 | **Incorporar el backlog** (cambios 26–34) | Gobernanza | Baja | `backlog_acumulativo.md` no estuvo disponible en esta sesión. **Adjuntarlo al abrir la 12.** El delta completo está en §14, con las dos categorías nuevas aprobadas por el titular |
| 3 | **Commit del trabajo de esta sesión** | Gobernanza | Baja | Sin commitear al cierre: `.gitignore` (bloque Censo), 2 reportes de andamios, 2 decisiones, traspaso v11, `ESTADO.md`, snapshots. Más lo que haya producido el Hito 2b. Commits separados por tipo conceptual (POLITICA 9.7) |
| 4 | **Hito 3: `38_construir_capa_zonal.R`** | Funcionalidad nueva | **Alta** | Decisión escrita (`20260712_decision_indicador_asistencia_censo2024.md`). Unión Zonal ∪ Localidades por llaves distintas (`ID_ZONA` / `ID_LOCALIDAD`). Test `TOL_LECTURA_PARQUET = 0,75 pp`. Rotulado: "proporción del grupo en edad oficial que asiste al nivel", **nunca "tasa neta"** |
| 5 | **Hito 4: front-end de las dos capas** | Funcionalidad nueva | **Alta** | `docs/assets/mapa.js`: capa de manzana con **Canvas**, **toggle apagado por defecto**, **carga diferida** (el `fetch` al primer encendido), indicador de carga visible (~400 KB viajando). Capa zonal como capa normal. Leyenda con entrada propia para el cero (gris neutro, fuera de escala). Popup **sin** la cifra comunal del INE |
| 6 | **Nota metodológica del producto** (pública, en `docs/`) | Contenido | Media | **La escribe el asistente conversacional, no Claude Code:** es prosa editorial y de voz institucional. Debe declarar: la discrepancia con el INE (0,53–1,35 pp, siempre a la baja) y su causa; el 3,84 % de manzanas colapsadas por simplificación; el 0,79 % de indeterminadas; el 0,2–4,7 % de área comunal no cubierta por la unión zonal (rural disperso) |
| 7 | **Validación en un segundo dispositivo** (notebook institucional) | QA / validación | Baja | Condición para evolucionar el toggle a **activación por umbral de zoom**. Sin esa evidencia, el toggle se queda como está |
| 8 | Sincronizar POLITICA y SETTINGS del repo con la knowledge base | Deuda heredada | Baja | **Tarea manual del titular.** Heredado de v07, v08, v09, v10 |
| 9 | Mover `diagnostico_migracion_github.R` fuera de `activa/decisiones/` | Deuda heredada | Trivial | Agrupar con otro trabajo |
| 10 | Favicon del sitio | Cosmética | Trivial | Heredado de v09 |
| 11 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Abierto desde v05 |
| 12 | Validación con el equipo experto (mapa) | Bloqueante externo | — | Abierto desde v06 |
| 13 | Decidir visibilidad del sitio Pages | Decisión estratégica | Baja | Heredado |
| 14 | Escolaridad del jefe de hogar como capa (v2) | Funcionalidad nueva | Media | Diferida por riesgo editorial (estigmatización territorial) |
| 15 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Heredado |
| 16 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Heredado |

**Evaluación de deuda técnica:** ninguna zona frágil en el código (el pipeline no se toca hace cinco sesiones). **Deuda de proceso emergente:** los dos errores del asistente de esta sesión son de **protocolo de interacción**, no de diagnóstico, y ninguna salvaguarda automática los detecta (§7). Es una clase de error que solo el titular atrapa.

**Auditoría de cierre (política 5.6):**
- ¿El pipeline corre de cero sin intervención manual? **Parcial, sin cambios.** `sincronizar_docs.sh` sigue manual y documentado. Deuda declarada y aceptada. Esta sesión no lo corrió (correctamente).
- ¿Cada transformación crítica tiene validación? **Pendiente de verificar:** el encargo del Hito 2b la exige (`stopifnot` de `nchar`, CUT en el universo, 0 NA, `st_is_valid`), pero **no está verificado** que se haya implementado. Va como pendiente #1.
- ¿Outputs reproducibles e idempotentes? **Pendiente de verificar** (escritura atómica exigida en el encargo del Hito 2b, no verificada).
- ¿Decisiones metodológicas como constantes nombradas? **Sí**, y esta sesión **eliminó** una constante que habría sido un número mágico disfrazado (`TOL_VALIDACION_TASA`) y **derivó** la que la reemplaza de una medición, no de una elección.
- ¿Nombres sin tildes/ñ/espacios? **Sí** en todo lo generado.

Las respuestas "pendiente de verificar" se convierten en el pendiente #1.

**Ruta sugerida sesión 12:** (1) verificar el Hito 2b contra el artefacto; (2) incorporar el backlog (adjuntar el archivo); (3) commitear el acumulado; (4) **Hito 3: capa zonal**; (5) Hito 4: front-end. Los pendientes #8, #9 y #10 se agrupan con cualquier trabajo.

---

## 11. Instrucciones específicas para la próxima sesión

- ⚠️ **EL HITO 2b NO ESTÁ VERIFICADO.** El encargo quedó corriendo al cerrar esta sesión. **NO asumas que `37_construir_capa_manzana.R` existe, ni que corrió bien, ni que el GeoJSON está escrito.** Verifícalo contra el artefacto (escáner + `git status` + inspección del JSON) **antes de construir encima**. Este traspaso NO afirma su estado: lo declara desconocido.
- ⚠️ **Toda afirmación sobre el estado del repositorio exige el comando que la respalde, en el mismo turno.** Séptima sesión consecutiva registrando este patrón.
- ⚠️ **Toda afirmación de DIAGNÓSTICO exige la medición que la respalde, antes de convertirse en recomendación.** Heredado de v10 y **validado**: el encargo del Hito 2a existía para poder fallar, y falló, y por eso el producto es correcto.
- ⚠️ **NUEVO — antes de aplicar una regla del protocolo, RELEERLA COMPLETA.** Los dos errores de esta sesión (§7) son de no leer entera una regla disponible y actuar sobre la parte recordada. Ninguna salvaguarda automática los detecta: solo el titular.
- ✅ **ANTES de todo join o filtro sobre datos del INE, castear TODO geocódigo a `character`.** `MANZENT` 13 díg., `ID_ZONA` 9, `ID_LOCALIDAD` 8, `CUT` 4. `arrow` los lee como `double`/`int32`. Verificar con `nchar()` constante y **fallar con `stop()`** si no lo es.
- ✅ **ANTES de simplificar geometría, proyectar a EPSG:32719.** El origen es 4674 (grados) en las **tres** capas.
- ✅ **ANTES de escribir a `docs/data/`, verificar que no entre ningún identificador individual.**
- 🔒 **El indicador de asistencia NO se rotula "tasa neta".** Es la **"proporción del grupo en edad oficial que asiste al nivel"**. Subestima la tasa del INE 0,53–1,35 pp, siempre a la baja, y esa diferencia **no es corregible a escala sub-comunal**. La regla aplica a leyenda, popups, exportaciones (XLSX/CSV) y prosa. **No la levantes "porque el número casi calza".**
- 🔒 **NO se ajusta la proporción por no-respuesta para hacerla converger con el INE.** Sería asumir no-respuesta uniforme intra-comuna, que nadie midió: precisión inventada. La corrección se usa **solo** en el test de lectura (`TOL_LECTURA_PARQUET`), **nunca** en el producto.
- 🔒 **El popup de una zona NO muestra la cifra comunal del INE.** Distinta unidad geográfica. Ver §5.3.
- 🔒 **La tasa de asistencia NO se mapea a nivel manzana.** Mediana de 3 niños por manzana: el cociente sería ruido. Los conteos sí. **No es una restricción técnica sino de honestidad del producto.**
- 🔒 **Las manzanas con cero niños se EXPORTAN con valor 0.** El cero es dato real, no ausencia. Gris neutro, fuera de la escala cromática, con entrada propia en la leyenda. **No las filtres.**
- 🔒 **El microdato de personas del Censo NO se usa y NO entra al proyecto** (Ley 21.719).
- 🔒 **Los parquet del Censo están sellados en `.gitignore` (líneas 94–95).** No los desellen. `size-pack` debe seguir en ~1 MiB.
- 🔒 `31`, `32`, `33`, `33b`, `34`, `35`, `36`, `10_*`, maestro: intocables sin instrucción explícita.
- 🔒 `00_run_all.R`: el encargo del Hito 2b lo autoriza **exclusivamente** para agregar una entrada a `PASOS`. Ninguna otra modificación.
- 🔒 `sincronizar_docs.sh` NO se corre en sesiones que no regeneren datos.
- 🔒 `[hidden] { display: none !important; }` en `estilo.css` es estructural.
- 🔒 El backlog jamás se renumera, reescribe ni resume.
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
    # sprintf evita la notacion cientifica de los double de 13 digitos.
    MANZENT      = sprintf("%.0f", MANZENT),
    ID_ZONA      = sprintf("%.0f", ID_ZONA),
    ID_LOCALIDAD = sprintf("%.0f", ID_LOCALIDAD),
    CUT          = sprintf("%.0f", CUT)
  ) |>
  st_as_sf(geometry = st_as_sfc(SHAPE, EWKB = TRUE), crs = CRS_ORIGEN)

# Verificacion obligatoria del casteo (no confiar: comprobar). FALLA, no advierte:
stopifnot(length(unique(nchar(capa$MANZENT))) == 1)
stopifnot(unique(nchar(capa$CUT)) == 4)
```

**Simplificación: se mide en metros, se dibuja en grados.**
```r
CRS_ORIGEN  <- 4674   # SIRGAS 2000 (grados) - VERIFICADO en las tres capas
CRS_METRICO <- 32719  # UTM 19S - solo para operaciones metricas
CRS_WEB     <- 4326   # obligatorio para Leaflet
TOLERANCIA_SIMPLIFICACION_M <- 5   # a 20 m colapsan 14% de las manzanas; a 5 m, 3,8%

capa_web <- capa |>
  st_transform(CRS_METRICO) |>                          # a metros
  st_simplify(dTolerance = TOLERANCIA_SIMPLIFICACION_M) |>
  st_transform(CRS_WEB)                                 # a grados, para el navegador

# El 3,84% que colapsa a geometria vacia SE DECLARA, no se oculta:
n_vacias <- sum(st_is_empty(capa_web))
message("Geometrias colapsadas por simplificacion: ", n_vacias, " de ", nrow(capa_web))
capa_web <- capa_web[!st_is_empty(capa_web), ]
```

**El indicador de asistencia, y cómo NO se calcula:**
```r
# CORRECTO — la proporcion reproducible desde el parquet:
proporcion_asistencia_basica <- n_asistencia_basica / n_edad_6_13
# Se rotula: "proporcion del grupo en edad oficial que asiste al nivel".
# NO es la "tasa neta INE": la subestima 0,53-1,35 pp (medido, 12/12 celdas).

# PROHIBIDO — el ajuste que hace converger la cifra con el INE:
#   proporcion_ajustada <- proporcion / (1 - no_respuesta_comunal)
# Asume que la no-respuesta se distribuye UNIFORMEMENTE dentro de la comuna.
# Nadie lo midio. Hace calzar el numero a costa de inventar precision.
# Se usa SOLO en el test de lectura (TOL_LECTURA_PARQUET), NUNCA en el producto.
```

**El test que valida la lectura, no el indicador:**
```r
TOL_LECTURA_PARQUET <- 0.75   # pp. Derivado de la medicion (max 0,60), no elegido.

# Agregar a comuna -> corregir por no-respuesta (hoja 2) -> comparar con la hoja 8.
# Si la diferencia supera 0,75 pp, ALGO SE LEYO MAL (filtro, casteo, unidad perdida).
# Es un canario de integridad, NO una tolerancia del producto.
stopifnot(max(abs(dif_pp)) <= TOL_LECTURA_PARQUET)
```

**La forma correcta de una compuerta (validada en v10, reconfirmada aquí):**
```bash
# NO enumera lo esperado. REPORTA lo que hay y DETIENE ante lo inesperado.
# El titular decide que es legitimo. El asistente no pre-declara nada.
git status --short --branch
git log --oneline origin/main..main
git log --oneline main..origin/main

# Y la verificacion de gobernanza que esta sesion agrego al repertorio:
git check-ignore -v <ruta_del_dato_pesado>   # exit 0 = sellado. Vacio = DETENTE.
git count-objects -vH                        # size-pack no debe moverse tras el push.
```

---

## 13. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 12 (Capa zonal y front-end)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior, el escáner re-ejecutado al abrir, el backlog acumulativo y las dos decisiones del Censo. **Advertencia del traspaso: el Hito 2b quedó corriendo al cierre de la sesión 11 y su resultado NO está verificado — la primera acción es auditarlo contra el artefacto.** El foco de esta sesión es la capa zonal (Hito 3) y el front-end (Hito 4).

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar; solo verificar que esté al día): `POLITICA_PROYECTO.md` (v5.2), `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (v7).
2. *Específicos de la sesión (SÍ adjuntar)*:
   - `traspaso_cierre_v11.md` (este documento).
   - `estructura_actual.md` **re-ejecutado al abrir** (el de este cierre, 14:32:16, es anterior al resultado del Hito 2b: **está desactualizado por diseño**).
   - `50_documentacion/activa/backlog_acumulativo.md` — **IMPRESCINDIBLE.** No estuvo disponible en la sesión 11 y el backlog quedó sin incorporar desde la sesión 9. Son **9 entradas pendientes** (26–34).
   - `50_documentacion/activa/decisiones/20260712_decision_indicador_asistencia_censo2024.md` — **imprescindible**: el contrato de la capa zonal.
   - `50_documentacion/activa/decisiones/20260712_decision_alcance_censo2024.md` — **imprescindible**: el contrato de la capa de manzana (leer la nota de superseción del inicio).
   - `50_documentacion/andamios/reporte_diagnostico_zonal_censo2024.md` — todas las cifras que fundan la decisión del indicador.
   - `50_documentacion/andamios/log_construccion_capa_manzana.md` — **si el Hito 2b lo produjo.** Si no existe, es señal de que el encargo no terminó.
   - `30_procesamiento/37_construir_capa_manzana.R` — **si existe.** Es el artefacto a auditar.
3. *Opcionales según el foco real*:
   - `CLAUDE.md` si la sesión correrá en Claude Code (**lo hará**).
   - `docs/assets/mapa.js` y `docs/assets/estilo.css` — **necesarios para el Hito 4** (voluminosos: adjuntar cuando se llegue a ese hito).
   - `50_documentacion/andamios/reporte_render_manzana_censo2024.md` si se revisa la decisión del renderer o del toggle.

**Nota final:** el remoto quedó en **`a508b98`**. El trabajo de la sesión 11 (dos decisiones, dos reportes, `.gitignore`, este traspaso) **quedó sin commitear**, más lo que haya producido el Hito 2b. Verificar al abrir con `git status --short --branch`, **no asumirlo desde este párrafo**.

**Advertencia crítica de reapertura:** este traspaso **NO afirma** el estado del Hito 2b. Lo declara **desconocido**. Cualquier afirmación de la sesión 12 sobre `37_construir_capa_manzana.R` o `docs/data/censo_manzanas_cc.geojson` debe salir de una verificación contra el artefacto, no de este documento.

---

## 14. Delta del backlog acumulativo

**Estado del backlog:** el `backlog_acumulativo.md` commiteado en `9f39df5` llega al **cambio 25**. **No estuvo disponible en esta sesión** (no se adjuntó): no se pudo incorporar, y **no se reconstruyó de memoria** (POLITICA: el backlog jamás se reescribe ni se resume; sin el archivo no se puede verificar que 25 sea el último ni cómo están redactadas las categorías vigentes).

**Entradas pendientes de incorporar: 9** (3 de la sesión 9 + 3 de la sesión 10 + 3 de la sesión 11).

**Refinamientos de taxonomía: APROBADOS POR EL TITULAR en esta sesión.** Crear ambas categorías:

1. **`Identidad visual`** — propuesta en v09 para el cambio 27. **Aprobada.**
2. **`Diagnóstico y exploración de datos`** — propuesta en v10 para los cambios 29–30. **Aprobada.** Cubre además los cambios 32 y 33 de esta sesión. Es trabajo de **investigación previa a la construcción**: averiguar si se puede construir es distinto de construir, y el proyecto va a producir más (jardines JUNJI/Integra, territorio insular).

De la **sesión 9** (declarados en v09 §14, aún no incorporados):

| # | Cambio | Categoría temática |
|---|---|---|
| 26 | Re-chequeo visual del mapa interactivo y corrección de los dos defectos hallados | *Corrección de front-end* |
| 27 | Unificación de la identidad cromática al azul institucional `#0D2E52` | *Identidad visual* |
| 28 | Publicación en GitHub Pages: tres commits y push a `origin/main` | *Gobernanza y versionado* |

De la **sesión 10** (declarados en v10 §14, aún no incorporados):

| # | Cambio | Categoría temática |
|---|---|---|
| 29 | Diagnóstico del Censo 2024, Etapa 1: inventario de datos disponibles, estructura de las bases agregadas, universo de la Región de Valparaíso, supresión estadística. Confirma que los indicadores de asistencia existen hasta nivel manzana con supresión 0 % | *Diagnóstico y exploración de datos* |
| 30 | Diagnóstico del Censo 2024, Etapa 1b: medición empírica de viabilidad a nivel manzana (peso, joins, indeterminación, densidad del indicador). Establece que el peso no es obstáculo y que la mediana de 3 niños por manzana invalida la tasa a esa escala | *Diagnóstico y exploración de datos* |
| 31 | Decisión de alcance de la capa censal: dos capas, dos indicadores, dos escalas (densidad a nivel manzana en Costa Central; tasa de asistencia a nivel zona/localidad en la región). Archivo de decisión formal | *Decisión de diseño / arquitectura de producto* |

De la **sesión 11** (esta):

| # | Cambio | Categoría temática |
|---|---|---|
| **32** | Prueba de humo de render (Hito 1): medición de FPS, carga y memoria en navegador real (Chrome headful con GPU) con 5.753 polígonos de manzana, comparando renderer SVG contra Canvas. Cierra el riesgo abierto #1 del contrato de alcance. Deriva la decisión de usar Canvas y de cargar la capa bajo demanda (toggle apagado por defecto) | *Diagnóstico y exploración de datos* |
| **33** | Diagnóstico de la capa zonal (Hito 2a): anatomía del parquet de Localidades (MULTIPOLYGON, llave `ID_LOCALIDAD`, indicadores incrustados), viabilidad de la unión urbano+rural (solape 0,0 ha, cobertura 95–99,8 %), y la prueba decisiva de convergencia. **Establece que la proporción del parquet NO es la tasa neta del INE** (subestima 0,53–1,35 pp, 12/12 celdas) porque el INE excluye la no-respuesta del denominador, dato inexistente a escala sub-comunal | *Diagnóstico y exploración de datos* |
| **34** | Decisión del indicador de asistencia: publicar la proporción cruda con rotulado honesto ("proporción del grupo en edad oficial que asiste al nivel"), **sin** ajustarla para que converja con el INE (sería inventar precisión); declarar la discrepancia en la nota metodológica; no yuxtaponer la cifra comunal del INE en el popup de una zona. Elimina `TOL_VALIDACION_TASA` y crea `TOL_LECTURA_PARQUET` (test de integridad de lectura, no del indicador). Supersede el contrato de alcance en §3, §6 y §10 | *Decisión de diseño / arquitectura de producto* |

Filas del resumen estadístico a agregar:
`9  | v09 | 3 (26–28) | — | Re-chequeo visual, identidad cromática y publicación`
`10 | v10 | 3 (29–31) | — | Diagnóstico Censo 2024 y decisión de alcance`
`11 | v11 | 3 (32–34) | — | Render, capa zonal y decisión del indicador`

**Nota para quien incorpore:** el commit y el sellado del `.gitignore` de esta sesión (§3.1 y §3.2) son trabajo de gobernanza que resuelve pendientes previos, no cambios nuevos solicitados por el titular. Según la nota metodológica del backlog (un cambio = una solicitud distinguible del usuario), **no cuentan como entradas**. Si el criterio del proyecto ha sido otro en sesiones anteriores, ese criterio manda: verificarlo contra el archivo, no contra este párrafo.
