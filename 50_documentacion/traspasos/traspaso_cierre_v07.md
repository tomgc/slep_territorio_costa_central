# Traspaso de cierre — v07

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 7
**Entorno:** Claude (conversacional) + Claude Code (Fable) · **Repo remoto real:** `https://github.com/tomgc/slep_territorio_costa_central`
**Tipo de sesión:** CONTINUATION
**Archivos principales modificados/creados:** `.gitignore`; `README.md`; `50_documentacion/activa/backlog_acumulativo.md` (nuevo); `50_documentacion/activa/ESTADO.md`; `50_documentacion/activa/decisiones/20260712_decision_exclusion_territorio_insular.md` (nuevo); `50_documentacion/activa/decisiones/20260712_decision_recodificacion_slep_2026.md` (nuevo)

---

## 1. Resumen ejecutivo

Sesión de cierre de deuda, no de construcción. Con las validaciones del director y del equipo experto pendientes de terceros, y el re-chequeo visual del mapa en manos del titular, el trabajo ejecutable era documental y de gobernanza. Se cerraron cuatro brechas: (a) el `.gitignore` no cubría los intermedios `.rds` derivados del histórico por MRUN, que quedaban untracked y a un `git add .` de entrar al repositorio; (b) el proyecto llegó al séptimo cierre sin `backlog_acumulativo.md`, obligatorio desde el segundo (POLITICA §10); (c) el README documentaba solo las dos variantes de afiche y no la variante 3 ni la relación con el proyecto padre; (d) las dos reglas de negocio de mayor peso del mapa interactivo (exclusión insular y recodificación SLEP 2026) no tenían archivo de decisión propio, y el `ESTADO.md` estaba desactualizado en dos sesiones con el semáforo mal puesto en "cerrado". Todo quedó cerrado y verificado contra el escáner real. Se registraron **cuatro errores del asistente**, tres de ellos del mismo patrón heredado de la sesión 6 (afirmar sobre el estado del repositorio sin contrastarlo contra el artefacto). El hallazgo metodológico de la sesión no es un producto: es que la compuerta adversarial de Claude Code atrapó dos de esos errores, mientras la regla declarativa que el propio asistente había propuesto no evitó ninguno.

---

## 2. Estado al cierre

**Funciona:**
- **Variantes 1 y 2 (afiches A0):** sin cambios funcionales. Completas, auditadas, en espera de validación del director (bloqueante externo abierto desde v05).
- **Variante 3 (mapa interactivo):** sin cambios funcionales. Publicada en `https://tomgc.github.io/slep_territorio_costa_central/`. Pipeline 34→35→36 auditado a tolerancia 0.
- **Gobernanza del repositorio:** los dos `.rds` derivados del histórico por MRUN (`directorio_region5.rds`, `matricula_historica_r5.rds`) quedan sellados por `.gitignore:83` (`40_salidas/mapa_interactivo/*.rds`). `.claude/` ignorado. Los tres JSON agregados de `web/data/` siguen versionados a propósito.
- **Documentación canónica:** `backlog_acumulativo.md` existe en su ruta canónica con las cinco secciones; `README.md` documenta los tres productos y la relación con el proyecto padre; dos archivos de decisión formalizados; `ESTADO.md` al día.

**No funciona / pendiente:**
- Re-chequeo visual del mapa interactivo: en curso por el titular al momento del cierre, resultado no reportado.
- Las copias de `POLITICA_PROYECTO.md` (34,61K) y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (57,28K) en `50_documentacion/activa/` son **versiones anteriores** a las de la knowledge base (POLITICA v5.2, SETTINGS v7). Detectado por el escáner al cierre; no corregido en esta sesión.
- Ningún push al remoto: todos los commits de la sesión son locales.

**Delta respecto a v06:** v06 dejó el proyecto con los tres productos construidos y una deuda documental y de gobernanza acumulada durante siete sesiones. v07 no tocó ningún producto: cerró esa deuda íntegramente.

---

## 3. Registro detallado de cambios

### 3.1 Sellado de los intermedios derivados de MRUN en `.gitignore`
Categoría temática: **gobernanza y versionado**.

El traspaso v06 daba este ítem como "instruido, no confirmado su cierre". La verificación contra el artefacto (`git check-ignore -v`) lo desmintió: **ninguna regla del `.gitignore` cubría `40_salidas/mapa_interactivo/`**. Los dos `.rds` aparecían como untracked (`??`), no como ignorados. Riesgo activo: un `git add .` los habría subido a un repositorio remoto.

**Iteración correctiva (ver §7, error #2).** La primera regla propuesta fue un paraguas sobre la carpeta completa (`40_salidas/mapa_interactivo/`). La compuerta adversarial de Claude Code la detuvo antes de commitear: `git ls-files` reveló **tres JSON trackeados históricamente** bajo esa ruta (`web/data/{establecimientos.geojson, metadatos.json, sin_geo.json}`), commiteados a propósito en `5256389`, `1c640cf` y `32e2276` como producto canónico del pipeline. No son fuga de gobernanza (son agregados sin identificador individual; el MRUN se descarta tras agregar), pero la regla paraguas los habría dejado en el estado trampa "trackeado bajo ruta ignorada": funcional, pero una trampa de mantenimiento.

**Regla final (opción A, acotar):**
```
# Intermedios .rds del mapa interactivo: derivados del historico por estudiante (MRUN).
# Regenerables por 30_procesamiento/34 y 35. Nunca entran al repo.
# Los JSON agregados de web/data/ SI se versionan: son producto canonico del pipeline,
# auditados, sin identificador individual (el MRUN se descarta tras agregar).
40_salidas/mapa_interactivo/*.rds
```
Más `.claude/` en el bloque de sistema.

Alternativa descartada (opción B): mantener el paraguas y `git rm --cached` los tres JSON. Habría eliminado una duplicación real (los mismos JSON viven en `docs/data/`), pero esa duplicación es intencional (`sincronizar_docs.sh` copia de uno a otro) y romperla habría convertido `docs/data/` en la única fuente versionada de un artefacto que el pipeline escribe en otra ruta. Peor trazabilidad.

**Barrido adversarial de Claude Code, en verde:** los 29 CSV de `historico_matricula/` ignorados; `directorio_oficial_ee_publico.csv` ignorado; los únicos `.rds` trackeados son `40_salidas/establecimientos_{validados,proyectados}.rds`, del flujo del afiche (maestro de 97 EE, sin MRUN, versionados por diseño).

### 3.2 Creación del `backlog_acumulativo.md` canónico
Categoría: **documentación y deuda**.

POLITICA §10 y SETTINGS §2.2.5 lo declaran obligatorio como archivo independiente a partir del **segundo** cierre. El proyecto llegó al séptimo sin él.

**Hallazgo de la reconstrucción: la numeración correlativa global está rota.**

| Traspaso | Estado del backlog |
|---|---|
| v01, v02 | Taxonomía formal con numeración correlativa (cambios 1–19) |
| v03 | Abandonada. El trabajo se registra por encargo a Claude Code (v1–v9) |
| v04 | Declaró explícitamente la brecha y **se negó a inventar retroactivamente** (B.1) |
| v05 | Reintrodujo una taxonomía con porcentajes aproximados, **sin numeración**, incompatible con la serie 1–19 |
| v06 | Sin sección de backlog |

**Decisión (opción B, corte declarado).** Tres opciones sobre la mesa: (A) reconstrucción completa retroactiva, numerando 20–N a partir de traspasos que nunca registraron esos cortes; (B) corte declarado: conservar literal la serie 1–19, registrar las sesiones 3–6 con la granularidad que cada traspaso sí documentó (sin numerar), y reanudar la serie correlativa en el cambio 20 desde la sesión 7; (C) backlog prospectivo puro, arrancando el detalle en la sesión 7.

Se eligió **B**. La opción A habría fabricado una granularidad que nunca existió, decidiendo el asistente dónde termina un "cambio" y empieza otro en sesiones que no lo registraron con ese criterio: exactamente lo que v04 había rechazado con razón. La discontinuidad entre el cambio 19 (sesión 2) y el cambio 20 (sesión 7) queda documentada en §2.1 del propio backlog como **hecho histórico del proyecto**, no como error de conteo.

**Omisión deliberada:** el protocolo pide columna de N° y % en la clasificación temática. Se omite el %, declarándolo en el archivo: con la serie partida en dos, cualquier porcentaje mezclaría entradas numeradas con entradas sin numerar, produciendo una estimación disfrazada de dato. Se reintroducirá cuando la serie nueva acumule entradas suficientes para que el porcentaje sea verificable.

**Taxonomía consolidada:** 13 categorías (dentro del rango 8–15 del protocolo), unificando las propuestas incompatibles de v01, v02 y v05.

### 3.3 README reescrito
Categoría: **documentación y deuda**.

El README anterior (4,27K) describía solo las dos variantes de afiche y cerraba en "Sesión 5". El nuevo (13,87K) documenta:
- Los **tres productos** en tabla comparativa, con sus universos distintos (97 vs. 1.268 establecimientos).
- La **relación con `slep_estudio_oferta_demanda`** (ver 3.4).
- El pipeline completo por decenas, incluidos 34/35/36 y `sincronizar_docs.sh`.
- Las **reglas de negocio del mapa interactivo** en prosa comprensible: universo, exclusión insular, recodificación SLEP 2026, ausencia de jardines JUNJI/Integra, ventana de matrícula y regla min>0, tratamiento de los 85 establecimientos sin registro.
- Qué se versiona y qué no, con el criterio doble (gobernanza + peso).

**Bug de formato corregido de paso:** el README anterior tenía un bloque de código con la triple comilla de apertura sin cerrar, lo que colapsaba todo el resto del documento en un único bloque de código al renderizar en GitHub.

### 3.4 Relación con el proyecto padre (decisión de encuadre)
Categoría: **documentación y deuda**.

El pendiente #3 de v06 pedía documentar la relación `slep_georreferenciacion` ↔ `slep_estudio_oferta_demanda`, pero ningún artefacto la definía. Se planteó al titular como decisión estratégica (no inferible). Su respuesta, ahora canónica:

> El proyecto **empezó autónomo** (el afiche, producto de identidad institucional, universo = 97 EE del SLEP) y **fue absorbido** como componente del estudio cuando llegó la variante 3 (el mapa regional excede el territorio del SLEP y es una herramienta de análisis, no de identidad). Hoy `slep_georreferenciacion` es un **producto derivado** de `slep_estudio_oferta_demanda`: el estudio define el problema (oferta y demanda educativa en el territorio) y este repositorio entrega la capa cartográfica. El desarrollo previo se aprovecha como recurso: no se rehizo, se reutilizó.

**Por qué importa técnicamente:** es la única explicación honesta de por qué conviven dos universos (97 y 1.268) en un mismo repositorio. Los scripts 31/32/33/33b operan sobre el maestro del SLEP; los scripts 34/35/36 sobre el directorio nacional filtrado a la región. No es una inconsistencia: son dos flujos que comparten repositorio, convenciones y activos de diseño, pero no insumos ni universo. Sin esta sección, un tercero que lea el código concluiría que hay un bug.

### 3.5 Archivos de decisión formalizados
Categoría: **documentación y deuda**. Cierra el pendiente #10 de v06.

- **`20260712_decision_exclusion_territorio_insular.md`:** contexto, decisión (comunas 5201 y 5104 fuera del producto completo en v1), alternativas (incluir con encuadre ajustado; incluir sin ajustar; excluir por provincia, que era un error porque la provincia 51 es mayoritariamente continental), y la distinción entre los dos argumentos: el cartográfico (débil, es sobre la implementación) y el de propósito (decisivo: las islas no son "entorno" del SLEP). Deja explícito que es exclusión de **alcance, no de calidad**, con la consecuencia operativa de que nadie debe "arreglarla" reincluyéndolas.
- **`20260712_decision_recodificacion_slep_2026.md`:** contexto (directorio con corte 30-abr-2025 vs. traspasos de 1-ene-2026), decisión, excepciones, el gate compuesto, y la **regla técnica aprendida** que es el aporte duradero: verificar por partes, no solo el agregado. Documenta el caso concreto (el gate compuesto atrapó que `slep_nombre` se asignaba también a establecimientos particulares de comunas traspasadas, algo que un gate de total único habría dejado pasar porque el conteo agregado seguía siendo correcto). Deja explícito que la regla es **temporal por naturaleza** y que la constante `TRASPASO_SLEP_VIGENTE_2026` está nombrada para que su obsolescencia sea visible.

### 3.6 `ESTADO.md` actualizado
Categoría: **documentación y deuda**.

El archivo existía (contra lo que el asistente afirmó al abrir; ver §7, error #1) pero estaba desactualizado en dos sesiones: `sesion_actual: v05`, `ultima_actividad: 2026-06-28`, `tipo_pendiente: ninguno`, y `semaforo: cerrado`.

**El semáforo estaba mal.** El criterio de SETTINGS §2.1bis es: *¿hay trabajo ejecutable por el titular ahora mismo, aunque sea parcial?* Lo hay (deuda documental, pendientes de v2, el propio re-chequeo). Los bloqueantes externos (director, equipo experto) son ítems puntuales del backlog, no el proyecto completo detenido. Corregido a `activo`.

**`tipo_pendiente` corregido tras un error propio** (ver §7, error #3): el primer intento usó el valor inventado `documentacion`, que no pertenece al enum de §1.2.4. Valor final: `nuevo` (el diagnóstico del Censo es funcionalidad exploratoria nueva), como default conservador declarado, ya que el resultado del re-chequeo visual (que podría convertirlo en `bug`) no se conocía al cierre.

---

## 4. Bugs de la sesión

**Ninguno de código.** Ningún script del pipeline se tocó. Los defectos corregidos fueron de configuración (`.gitignore`) y de documentación.

---

## 5. Aprendizajes y restricciones descubiertas

1. **Una compuerta vale más que una regla declarada.** La evidencia es directa: el asistente propuso, a media sesión, la salvaguarda "ninguna afirmación sobre el estado del repositorio entra a un documento sin un comando que la respalde", y **cometió el mismo error dos veces más después de proponerla**. Lo que sí funcionó fue la compuerta adversarial de Claude Code (`git ls-files` antes de commitear, verificación de rutas del README contra el filesystem): atrapó dos de los cuatro errores antes de que llegaran al repositorio. Regla: una salvaguarda que depende de que el asistente se acuerde de aplicarla no es una salvaguarda; una que es un paso obligatorio del procedimiento, sí.

2. **`git status` no es `git ls-files`.** Un archivo puede estar trackeado históricamente y no aparecer en `git status` (porque no tiene cambios). Escribir una regla de `.gitignore` mirando solo el `status` produce el estado trampa "trackeado bajo ruta ignorada": el `.gitignore` no destrackea lo ya commiteado, así que la regla parece aplicada pero no hace nada sobre esos archivos. **Antes de escribir cualquier regla de `.gitignore` sobre una ruta, correr `git ls-files <ruta>`.**

3. **No inventar retroactivamente vale también para el backlog.** v04 ya lo había razonado y aplicado correctamente; v07 lo confirma. Reconstruir una numeración correlativa a partir de traspasos que no la llevaban significa que el asistente decide dónde estaban los cortes entre solicitudes del titular. Eso no es memoria: es ficción con formato de registro. Declarar el corte es más honesto y más útil.

4. **El enum de `tipo_pendiente` no se amplía, se traduce.** SETTINGS §2.1bis lo dice de forma explícita ("no lo copies literal y no amplíes el enum para acomodarlo") y aun así el asistente inventó un valor. La taxonomía temática del backlog (orgánica, libre por proyecto) y el enum de prioridad de sesión (fijo, compartido por la cartera) son dos cosas distintas y es fácil confundirlas precisamente porque ambas viven en el mismo cierre.

---

## 6. Decisiones de diseño

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| Regla de `.gitignore` para `mapa_interactivo/` | Paraguas sobre la carpeta + `git rm --cached` de los 3 JSON | Acotar a `*.rds`; los JSON canónicos siguen versionados donde el pipeline los escribe |
| Reconstrucción del backlog | (A) renumerar retroactivamente 20–N; (C) backlog prospectivo puro | (B) corte declarado: serie 1–19 literal, sesiones 3–6 sin numerar, serie nueva desde el 20 |
| Columna de % en la clasificación temática | Calcularla sobre el total mezclado | Omitirla y declarar por qué (sería una estimación disfrazada de dato) |
| Relación con el proyecto padre | (B) proyectos hermanos que comparten insumos | (C+A) origen autónomo → absorción; hoy producto derivado del estudio |
| `semaforo` en `ESTADO.md` | Mantener `cerrado`; usar `pausa` por los bloqueantes externos | `activo`: hay trabajo ejecutable por el titular ahora mismo |

Las dos decisiones arquitectónicas de peso de la sesión 6 (exclusión insular, recodificación SLEP) quedaron formalizadas como archivo propio en esta sesión. Las de esta sesión son de gobernanza documental, no arquitectónicas: no requieren archivo propio.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Acuse de recibo, auditoría de apertura | Verificación posterior lo desmintió | Declaré `ESTADO.md` inexistente como deuda heredada; existía desde 2026-07-02 | POLITICA 0.2 / SETTINGS 1.2.6 (no deducir; no operar sobre estado supuesto) | Inferí la ausencia desde el escáner adjunto, que yo mismo había declarado en el párrafo anterior como anterior al cierre de la sesión 6 y por tanto no confiable | POLITICA 0.2 + la instrucción ⚠️ explícita del traspaso v06 | Mismo que v06 #2 y #4 |
| 2 | Encargo del `.gitignore` | Claude Code lo detuvo en la compuerta adversarial | Escribí una regla paraguas (`40_salidas/mapa_interactivo/`) sin correr `git ls-files` sobre esa ruta; habría dejado 3 JSON versionados a propósito en el estado trampa "trackeado bajo ruta ignorada" | POLITICA 1.2.6 (no operar sobre estado supuesto) | Asumí que la carpeta contenía solo los 2 `.rds` que el `git status` mostraba como untracked, sin verificar qué más había trackeado bajo ella | POLITICA + la salvaguarda que yo mismo había declarado 20 minutos antes en esta sesión | Mismo que #1 |
| 3 | `ESTADO.md` | Lo detecté al releer SETTINGS tras entregar el archivo | Usé `tipo_pendiente: documentacion`, un valor inventado que no pertenece al enum de §1.2.4 | SETTINGS §2.1bis (traducir al enum por significado; no ampliarlo) | Copié la categoría temática del backlog en vez de traducirla al enum de prioridad de sesión, precisamente el error que la regla anticipa y prohíbe de forma nominal | SETTINGS §2.1bis | **Nuevo** (no es "no verificar el estado real"; es "no releer la regla que estoy aplicando") |
| 4 | README (nombres de scripts) | El titular subió los archivos reales | Inventé los nombres de los scripts 35 y 36 (`35_matricula_historica.R`, `36_generar_geojson.R`; los reales son `35_agregar_matricula_historica.R` y `36_construir_geojson_web.R`) y entregué el README para reemplazar | POLITICA 1.2.6 | Solo tenía el nombre literal del 34 en el traspaso; inferí los otros dos por analogía. Declaré la asunción **al entregar**, lo que no la corrige: la regla es verificar antes de entregar, no confesar después | POLITICA + mi propia salvaguarda declarada | Mismo que #1 y #2 |

**Patrón cruzado (tercera sesión consecutiva).** Tres de los cuatro errores (#1, #2, #4) son la misma causa raíz que ya dominaba la tabla de v06: **afirmar sobre el estado real sin contrastarlo contra el artefacto**, cuando la verificación era trivial y estaba disponible (`git ls-files`, `ls`, leer el archivo). La novedad de esta sesión es negativa y vale registrarla con precisión: el asistente **propuso explícitamente una salvaguarda contra este patrón a media sesión** ("ninguna afirmación sobre el estado del repo entra a un documento sin un comando que la respalde") **y luego cometió el mismo error dos veces más**. Lo que sí lo contuvo fue la compuerta adversarial de Claude Code, que es un paso obligatorio del procedimiento y no depende de que el asistente recuerde aplicarla.

**Consecuencia para el análisis de cartera:** este es el caso más limpio disponible de que la regla declarativa "verificar contra el estado real" **no funciona como salvaguarda**, ni siquiera cuando el propio asistente la formula, la escribe y se compromete con ella en la misma conversación. Si el patrón aparece en otros proyectos (v06 ya anticipaba que podría), la conclusión no debería ser reforzar el énfasis de la regla, sino **convertirla en compuerta**: un paso mecánico obligatorio (correr el comando de verificación) antes de que cualquier afirmación de estado entre a un artefacto o a un encargo.

---

## 8. Constantes y parámetros vigentes

Sin cambios respecto a v06. Ninguna constante del pipeline se tocó.

Único cambio de configuración:

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| Regla de ignore de intermedios | `40_salidas/mapa_interactivo/*.rds` | `.gitignore:83` | Acotada a `.rds`; los JSON de `web/data/` siguen versionados |
| Regla de ignore de sistema | `.claude/` | `.gitignore:32` | Nuevo |

---

## 9. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/` (corrida de 2026-07-12 08:23:05, 375+ entradas). Verificado contra él, no supuesto:

- `50_documentacion/activa/backlog_acumulativo.md` (24,62K) — **nuevo**, ruta canónica correcta.
- `50_documentacion/activa/decisiones/20260712_decision_exclusion_territorio_insular.md` (4,31K) — **nuevo**.
- `50_documentacion/activa/decisiones/20260712_decision_recodificacion_slep_2026.md` (4,99K) — **nuevo**.
- `50_documentacion/activa/ESTADO.md` (1,77K) — actualizado.
- `README.md` (13,87K, antes 4,27K) — reescrito.
- Scripts 34/35/36 confirmados con sus nombres reales: `34_preparar_directorio_region.R` (16,79K), `35_agregar_matricula_historica.R` (8,45K), `36_construir_geojson_web.R` (18,36K).

**Deuda detectada por el escáner, no corregida:** `50_documentacion/activa/POLITICA_PROYECTO.md` (34,61K) y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (57,28K) son versiones **anteriores** a las vigentes en la knowledge base (POLITICA v5.2, SETTINGS v7). El proyecto opera con las de la knowledge base; las copias del repo están desactualizadas. Ver pendiente #4.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | **Re-chequeo visual del mapa interactivo** (en curso al cierre) | Bug / QA | Baja | Primera acción de la sesión 8. Si arroja correcciones, encabezan todo y el ciclo diagnóstico→cambio→re-auditoría sobre `docs/data/` es obligatorio |
| 2 | **Push al remoto** | Gobernanza | Baja | Todos los commits de la sesión 7 son locales. Verificar `git log origin/main..main` y pushear |
| 3 | **Diagnóstico Censo 2024** | Funcionalidad nueva / exploratorio | Alta | Encargo ya escrito (`50_documentacion/andamios/`). **Sesión dedicada con contexto fresco**; no mezclar |
| 4 | **Sincronizar POLITICA y SETTINGS del repo con la knowledge base** | Deuda heredada | Baja | Las copias de `50_documentacion/activa/` son versiones anteriores. Tarea manual del titular (descargar de la knowledge base y reemplazar) |
| 5 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Abierto desde v05 |
| 6 | Validación con el equipo experto (mapa) | Bloqueante externo | — | Abierto desde v06 |
| 7 | Decidir visibilidad del sitio Pages (público en repo privado) | Decisión estratégica | Baja | Definir con el titular si es aceptable o requiere GitHub Pro |
| 8 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Requiere universo `ID_ESTAB` + fuente de geo propia |
| 9 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Datos ya excluidos pero disponibles y válidos |

**Evaluación de deuda técnica:** ninguna zona frágil nueva. El pipeline no se tocó. La deuda documental que se arrastraba desde la sesión 2 (backlog) quedó cerrada; la única deuda documental viva es la #4, que es trivial.

**Auditoría de cierre (política 5.6):**
- ¿Pipeline corre de cero sin intervención manual? Parcial, sin cambios: 34→35→36 sí; `sincronizar_docs.sh` es manual (ahora **documentado** en el README, que era la deuda real).
- ¿Cada transformación crítica tiene validación? Sí (gates compuestos, `stopifnot`).
- ¿Outputs reproducibles e idempotentes? Sí, verificado por hash en v06.
- ¿Decisiones metodológicas como constantes nombradas? Sí, y ahora además con archivo de decisión propio.
- ¿Nombres sin tildes/ñ/espacios? Sí en todo lo generado esta sesión. Las excepciones (crudos MINEDUC con tildes, `Prototipo Mapa Establecimientos.dc.html`) son heredadas de fuentes externas, declaradas.

**Ruta sugerida sesión 8:** (1) incorporar el re-chequeo visual y el resultado de los commits pendientes; (2) push; (3) sincronizar POLITICA/SETTINGS del repo; (4) si no hay correcciones al mapa, el Censo merece su propia sesión, no la cola de esta.

---

## 11. Instrucciones específicas para la próxima sesión

- 🔒 **Antes de escribir cualquier regla de `.gitignore` sobre una ruta, correr `git ls-files <ruta>`.** `git status` no muestra lo trackeado sin cambios. Esta sesión casi produce el estado trampa "trackeado bajo ruta ignorada" por saltarse este paso.
- 🔒 Los tres JSON de `40_salidas/mapa_interactivo/web/data/` **están versionados a propósito**. No son fuga de gobernanza (son agregados sin identificador). No los destrackees "limpiando".
- 🔒 `00_run_all.R`, `31`, `32`, `33`, `33b`, `10_*`, maestro, y `34/35/36`: intocables sin instrucción explícita. Todos auditados.
- 🔒 Exclusiones de **alcance** v1 (territorio insular, parvularia JUNJI/Integra): no son defectos. No "arreglarlas" reincluyéndolas sin encargo v2 explícito. Ahora con archivo de decisión propio que lo documenta.
- ⚠️ **Toda afirmación sobre el estado del repositorio exige el comando que la respalde, en el mismo turno.** Cuatro errores en esta sesión, tres de este patrón, en la tercera sesión consecutiva que lo registra. La regla declarativa demostró no bastar: trátala como compuerta mecánica, no como principio.
- ⚠️ `tipo_pendiente` de `ESTADO.md` usa el enum de SETTINGS §1.2.4 (`bug | bloqueante | deuda_heredada | deuda_tecnica | nuevo | cosmetica | ninguno`), **no** la taxonomía temática del backlog. Traducir por significado; nunca ampliar el enum.
- ✅ ANTES de cualquier cambio a `docs/data/`: ciclo diagnóstico→cambio→re-auditoría completo. Son productos de un pipeline auditado dos veces.
- ✅ ANTES de fijar cualquier gate o cifra: recomputar contra el artefacto real (RDS/JSON), nunca reusar una cifra de un reporte anterior.
- 🔒 Máximo 2 agentes en Claude Code.

---

## 12. Fragmentos de código de referencia

**Verificación obligatoria antes de escribir una regla de `.gitignore` (la lección de esta sesión):**
```bash
# INSUFICIENTE: git status solo muestra untracked y modificados
git status --short

# CORRECTO: git ls-files revela lo trackeado historicamente, aunque no tenga cambios
git ls-files 40_salidas/mapa_interactivo/
# Si devuelve algo, esos archivos NO se ignoran al agregar la regla:
# quedan "trackeados bajo ruta ignorada" (funcional, pero trampa de mantenimiento).
# Decidir explicitamente: acotar la regla, o `git rm --cached` los archivos.

# Verificar el resultado, siempre:
git check-ignore -v <ruta>   # exit 0 = ignorado; exit 1 = NO ignorado
```

**Patrón de gate compuesto (heredado de v06, sigue siendo la forma correcta):**
```r
N_SLEP_DEP5_DIRECTORIO <- 127L   # ya SLEP en el dato
N_SLEP_RECODIFICADOS   <- 216L   # municipales recodificados por traspaso <= 2026
N_SLEP_TOTAL_ESPERADO  <- 343L   # 127 + 216

stopifnot(
  sum(universo$dependencia_original == "SLEP") == N_SLEP_DEP5_DIRECTORIO,
  sum(universo$recodificado) == N_SLEP_RECODIFICADOS,
  sum(universo$dependencia == "Servicio Local de Educación") == N_SLEP_TOTAL_ESPERADO
)
# Un total unico (343) habria pasado igual con slep_nombre mal asignado a
# establecimientos particulares. Verificar por partes, no solo el agregado.
```

---

## 13. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 8 (Fable)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior y el escáner más reciente.

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar; solo verificar que esté al día): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según el foco real*:
   - Si la sesión aborda el **Censo 2024**: `diccionario_variables_censo2024.xlsx` y `Ficha_metodologica_CPV2024.pdf` (del proyecto padre, fuera de este repo), más el encargo ya escrito en `50_documentacion/andamios/`.
   - Si el **re-chequeo visual arrojó correcciones**: los archivos de `docs/` afectados (`mapa.js`, `estilo.css`, `index.html`) y los JSON de `docs/data/` involucrados.
   - `CLAUDE.md` si la sesión correrá en Claude Code.
3. *Específicos de la sesión (SÍ adjuntar)*: este traspaso (`traspaso_cierre_v07.md`); el escáner `estructura_actual.md` **re-ejecutado al abrir** (el de esta sesión data de 2026-07-12 08:23, antes de los commits finales); el **resultado del re-chequeo visual** del mapa interactivo.

**Nota final:** los commits de la sesión 7 quedaron **locales, sin push**. Verificar al abrir con `git log origin/main..main` y `git remote -v` (el repo remoto es `slep_territorio_costa_central`, no `slep_georreferenciacion`). Si el re-chequeo visual generó correcciones después de este cierre, documentarlas al inicio de la sesión 8 antes de avanzar a trabajo nuevo.

---

## 14. Delta del backlog acumulativo

**Entradas nuevas:** 1 (cambio 20: creación del `backlog_acumulativo.md` canónico).

**Nota:** las entradas de esta sesión posteriores al cambio 20 (sellado del `.gitignore`, reescritura del README, archivos de decisión, actualización de `ESTADO.md`) deben agregarse al detalle cronológico del backlog como cambios 21 a 24 al incorporar este traspaso. La numeración correlativa quedó reanudada en el 20; la serie continúa sin interrupciones desde aquí.
