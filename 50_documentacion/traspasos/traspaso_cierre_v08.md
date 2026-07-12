# Traspaso de cierre — v08

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 8
**Entorno:** Claude (conversacional) + Claude Code (Fable) · **Repo remoto real:** `https://github.com/tomgc/slep_territorio_costa_central`
**Tipo de sesión:** CONTINUATION
**Archivos principales modificados/creados:** `50_documentacion/activa/backlog_acumulativo.md` (actualizado: 24,62K → 27,83K); `50_documentacion/traspasos/traspaso_cierre_v07.md` (commiteado); `50_documentacion/estructura/*` (snapshots); `50_documentacion/activa/ESTADO.md` (actualizado); `50_documentacion/traspasos/traspaso_cierre_v08.md` (nuevo)

---

## 1. Resumen ejecutivo

Sesión corta y de una sola naturaleza: cerrar el borde entre el trabajo hecho y el trabajo publicado. Se ejecutaron dos de las tres prioridades propuestas (la tercera, el re-chequeo visual del mapa, quedó sin insumo: el titular no lo tenía disponible). Se llevó al remoto la totalidad de la sesión 7 (10 commits, `42c24ff..78d633b`), que hasta entonces vivía solo en el disco del titular (incluido el `.gitignore` que sella los `.rds` derivados del histórico por MRUN, es decir, la regla de gobernanza no protegía nada fuera de la máquina local). Se incorporaron al `backlog_acumulativo.md` las cuatro entradas que el §14 de v07 dejó declaradas como deuda (cambios 21 a 24), dejando la serie correlativa íntegra y sin saltos desde el 20. **Ningún script del pipeline se tocó; ningún producto cambió.** El hallazgo de la sesión no es un producto: es la confirmación, por tercera vez consecutiva, de que la compuerta mecánica funciona donde la regla declarativa falla. Se registran **dos errores del asistente**, ambos del mismo patrón matriz que domina las tablas de v06 y v07 (afirmar o fijar cifras sobre el estado del repositorio sin recomputarlas contra el artefacto), y ambos fueron atrapados: uno por el reporte de Claude Code, otro por la compuerta explícita del encargo. Ninguno llegó al repositorio.

---

## 2. Estado al cierre

**Funciona:**
- **Variantes 1 y 2 (afiches A0):** sin cambios. Completas, auditadas, en espera de validación del director (bloqueante externo abierto desde v05).
- **Variante 3 (mapa interactivo):** sin cambios. Publicada en `https://tomgc.github.io/slep_territorio_costa_central/`. Pipeline 34→35→36 auditado a tolerancia 0.
- **Repositorio remoto sincronizado.** `git log origin/main..main` vacío; `git status --short --branch` sin `[ahead N]`; working tree limpio. Los 10 commits de la sesión 7 viajaron al remoto en un push fast-forward (`42c24ff..78d633b`, sin force).
- **Gobernanza operando en el remoto, verificada contra el artefacto:** `git check-ignore -v 40_salidas/mapa_interactivo/directorio_region5.rds` → exit 0 (`.gitignore:83`). Los tres JSON de `web/data/` siguen siendo lo único trackeado bajo `40_salidas/mapa_interactivo/` (`git ls-files`, ni más ni menos). Cero untracked (`git ls-files --others --exclude-standard` vacío).
- **`backlog_acumulativo.md` al día:** 27,83K, con la serie correlativa completa del 20 al 24. La serie histórica 1–19 quedó intacta (verificada por `diff`: solo cambiaron las tres zonas previstas).

**No funciona / pendiente:**
- **Re-chequeo visual del mapa interactivo: sigue sin resultado.** Era el pendiente #1 de v07 y la prioridad 1 de esta sesión. El titular no lo tenía disponible al abrir ni al cerrar. **Es el pendiente que define la forma de la sesión 9.**
- Las copias de `POLITICA_PROYECTO.md` (34,61K) y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (57,28K) en `50_documentacion/activa/` siguen siendo versiones **anteriores** a las de la knowledge base (POLITICA v5.2, SETTINGS v7). Heredado de v07, no corregido: es tarea manual del titular.
- El traspaso v08, el `ESTADO.md` y el snapshot del escáner de este cierre quedan **sin commitear y sin push** al momento de escribir esto (es el estado normal de todo cierre: el commit del cierre es la primera acción de la sesión siguiente, o del propio titular).

**Delta respecto a v07:** v07 cerró la deuda documental pero dejó todo su trabajo sin commitear (11 archivos en `git status`) y sin push, cosa que el propio traspaso v07 describía imprecisamente como "commits locales" (implicando que existían). v08 creó esos commits, los pusheó, y cerró la deuda del backlog que v07 declaró en su §14. El proyecto no tiene, por primera vez desde la sesión 4, ninguna deuda de gobernanza ni documental pendiente de ejecución.

---

## 3. Registro detallado de cambios

### 3.1 Commit y push de la sesión 7 completa
Categoría temática: **gobernanza y versionado**. Cierra el pendiente #2 de v07.

El traspaso v07 afirmaba en su §2 que "todos los commits de la sesión son locales". La verificación contra el artefacto lo matizó: el trabajo de v07 estaba **sin commitear**, no solo sin pushear (11 archivos en `git status --short`). Los commits se crearon en esta sesión.

**Commits creados en la sesión 8**, separados por tipo conceptual (POLITICA 9.7):

| Commit | Hash | Contenido |
|---|---|---|
| A–E | `6656167` … `4425cac` | Backlog canónico, README, decisiones, `ESTADO.md`, snapshots del escáner (5 commits) |
| F | `4973465` | `docs(traspaso): traspaso de cierre v07` |
| G | `78d633b` | `chore(escaner): snapshot 08:42:50 y poda de retencion` |

Los tres commits previos ya existentes en local (`6321541` gitignore, `974ec4d` traspaso v06, `6656167` snapshot) eran trabajo de la sesión 7 que también había quedado sin pushear.

**Push:** `git push origin main` → `42c24ff..78d633b`, fast-forward, sin force. **10 commits** viajaron al remoto (cifra recomputada con `wc -l` sobre `git log --oneline origin/main..main`, no heredada de ningún reporte previo).

**Verificaciones adversariales de Claude Code, en verde (todas contra el artefacto, con output literal):**
- Sin divergencia: `git log --oneline main..origin/main` vacío, exit 0.
- Los 3 JSON de `web/data/` intactos y son lo único trackeado bajo `40_salidas/mapa_interactivo/`.
- `check-ignore` exit 0 sobre los dos `.rds` (`.gitignore:83`) y sobre `.claude/` (`.gitignore:32`).
- Cero untracked; ningún `.rds`/`.csv`/`.xlsx` ni dato crudo entre lo pusheado.
- Barrido de identificadores personales sobre los 5 documentos commiteados: cero coincidencias (MRUN, formato RUT). Los únicos RBD concretos (14439, 2009) son identificadores institucionales públicos del directorio MINEDUC, sin asociación a persona.
- 36/36 rutas citadas en el README verificadas con `ls` contra el filesystem.

**El `git add -u` acotado a `50_documentacion/estructura/`** registró las dos eliminaciones producidas por la poda de retención 2 del escáner. Git las comprimió como rename al 97% de similitud: es compresión del delta, no pérdida.

**Nota de convención, no bloqueante:** los mensajes de commit llevan un trailer `Co-Authored-By` que añade el entorno de Claude Code. No está en ninguna regla del proyecto (ni POLITICA §2 ni los traspasos), pero ya está en el historial de todas las sesiones anteriores. Se decidió dejarlo: la consistencia con el historial existente vale más que la pureza del formato, y no viola ninguna regla escrita.

### 3.2 Incorporación de los cambios 21–24 al `backlog_acumulativo.md`
Categoría: **documentación y deuda**. Cierra la deuda declarada en el §14 de v07.

El §14 de v07 dejó explícito que las cuatro entradas posteriores al cambio 20 (sellado del `.gitignore`, reescritura del README, archivos de decisión, actualización de `ESTADO.md`) debían agregarse al detalle cronológico al incorporar ese traspaso. Se agregaron como **cambios 21 a 24**.

**Tres zonas modificadas, ninguna más** (verificado por `diff` contra el archivo original, no de memoria):
- Resumen estadístico, fila de la sesión 7: `(en curso)` → `5 (20–24)`.
- Detalle cronológico: entradas 21–24 agregadas; eliminada la nota provisional "*(Las entradas siguientes de la sesión 7 se agregan a continuación conforme avance el trabajo.)*".
- Sección 6 (Delta del backlog): se conserva el delta vs. v06 como registro histórico y se agrega el delta de la sesión 7 (5 entradas, sin refinamientos de taxonomía).

**La serie histórica 1–19 quedó intacta** (conteo verificado = 19). La serie nueva llega del 20 al 24 sin saltos. Ninguna entrada anterior se reescribió, resumió ni renumeró (SETTINGS §2.2.5).

**Decisión de alcance:** se registraron solo las cuatro entradas de la sesión 7. El push de la sesión 8 (un cambio registrable, según la nota metodológica) se difiere al cierre y entra como **cambio 25** al incorporar este traspaso. Alternativa descartada: abrir la sección de la sesión 8 a media sesión, lo que habría obligado a volver a tocar el mismo archivo al cerrar.

**Categorización:** las cuatro entradas cayeron en categorías existentes (21 en *Gobernanza y versionado*; 22–24 en *Documentación y deuda*). Sin refinamientos de taxonomía; las 13 categorías consolidadas en v07 las absorbieron sin ajuste.

---

## 4. Bugs de la sesión

**Ninguno de código.** Ningún script del pipeline se tocó. Los productos no cambiaron.

---

## 5. Aprendizajes y restricciones descubiertas

1. **La compuerta mecánica funciona; la regla declarativa no. Tercera confirmación consecutiva.** v07 ya lo había establecido con precisión (el asistente propuso una salvaguarda contra este patrón y cometió el mismo error dos veces más *después* de proponerla). La sesión 8 lo confirma desde el otro lado: los dos errores del asistente fueron **atrapados**, uno por el reporte de Claude Code y otro por una compuerta explícita del encargo (`DETENTE si el working tree no está limpio`). Ninguno llegó al repositorio. La diferencia operativa no es que el asistente se esfuerce más: es que el procedimiento contenga un paso obligatorio que no dependa de que el asistente lo recuerde.

2. **Una compuerta que fija una cifra heredada es una compuerta defectuosa.** El encargo de push fijó la condición verde en "5 commits adelante", cifra tomada del reporte del turno anterior. El delta real eran 8. La compuerta se disparó correctamente (hizo su trabajo), pero por la razón equivocada: detuvo trabajo legítimo. **Regla: una compuerta debe *recomputar* el estado, no *comparar contra una cifra heredada*.** El encargo correctivo lo aplicó (reportar la cifra sin compuerta numérica sobre ella) y pasó en verde. Esta es una refinación concreta de la instrucción ✅ de v07 §11 ("recomputar contra el artefacto real, nunca reusar una cifra de un reporte anterior"): la regla ya existía y aun así se violó, porque estaba formulada para las cifras del *producto* (gates de datos) y no se aplicó a las cifras del *proceso* (estado del repositorio). Ahora cubre ambas.

3. **"Commits locales" y "trabajo sin commitear" no son lo mismo, y el traspaso v07 los confundió.** El §2 de v07 afirmaba que los commits eran locales, implicando que existían. En realidad el trabajo estaba en el working tree. Un traspaso que describe el estado del repositorio con imprecisión propaga esa imprecisión a la sesión siguiente, que construye su plan sobre ella. **Regla: la sección "Estado al cierre" de un traspaso, cuando afirma algo sobre el repositorio, debe citar el comando que lo respalda.** Este traspaso lo hace (§2).

4. **Distinguir el estado del artefacto del estado del reporte sobre el artefacto.** El escáner adjunto al cerrar parecía, por su nombre, ser el mismo que ya estaba en contexto. No lo era (08:56:09 vs. 08:42:50) y ya reflejaba el backlog actualizado. La verificación costó un comando. La sospecha, sin verificación, habría producido un traspaso apoyado en un escáner obsoleto.

---

## 6. Decisiones de diseño

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| Alcance del backlog en esta sesión | (B) registrar también el push de la sesión 8 como cambio 25 a media sesión | (A) solo 21–24; el cambio 25 entra al incorporar este traspaso. Evita tocar dos veces el mismo archivo |
| Trailer `Co-Authored-By` en los commits | Quitarlo por pureza de formato | Dejarlo: ya está en todo el historial; quitarlo ahora crearía inconsistencia sin ganancia. No viola ninguna regla escrita |
| Columna de % en la clasificación temática | Reintroducirla ahora que la serie nueva tiene 5 entradas | Mantenerla omitida (v07). Cinco entradas no bastan para que el porcentaje sea verificable y no una estimación |
| Regla paraguas vs. acotada en `.gitignore` (heredada de v07) | — | Confirmada en el remoto: `check-ignore` exit 0 sobre los `.rds`, los 3 JSON intactos |

Ninguna decisión de esta sesión tiene peso arquitectónico. No se replica ninguna a `50_documentacion/activa/decisiones/`.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Encargo de prioridad 2 (primera versión) | El reporte de Claude Code lo evidenció | Redacté el encargo asumiendo que los commits de v07 ya existían y que solo faltaba el push; en realidad el trabajo estaba sin commitear (11 archivos en `git status`) | POLITICA 1.2.6 (no operar sobre estado supuesto) | Tomé por buena la afirmación del §2 del traspaso v07 ("todos los commits de la sesión son locales") en vez de tratarla como una afirmación de estado que exige verificación al abrir. El propio v07 registra que sus afirmaciones sobre el repositorio fueron poco confiables: era, de todas las fuentes disponibles, la que menos crédito merecía | POLITICA 1.2.6 + la ⚠️ explícita de v07 §11 | Mismo que v07 #1, #2, #4 y v06 #2, #4 |
| 2 | Encargo de prioridad 2 (continuación) | Claude Code lo detuvo en la compuerta de Fase 2 | Fijé la condición verde de la compuerta en "5 commits adelante", cifra tomada del reporte de Claude Code del turno anterior, sin recomputarla contra `git log origin/main..main`; el delta real era 8 | SETTINGS/v07 §11 ✅ ("ANTES de fijar cualquier gate o cifra: recomputar contra el artefacto real, nunca reusar una cifra de un reporte anterior") | Reusé una cifra derivada de un reporte de *proceso* (los 5 commits que Claude Code acababa de crear) como si fuera el estado *total* del delta con el remoto. Son dos cosas distintas: lo que se creó en ese turno vs. lo que separa `main` de `origin/main`. La regla existía y era nominalmente sobre este caso exacto | v07 §11 (instrucción ✅ literal) + la regla de oro que yo mismo escribí en el encargo | Variante del anterior, específica sobre **cifras de gate** |

**Patrón cruzado (cuarta sesión consecutiva).** Ambos errores son la misma causa raíz que domina las tablas de v06 y v07: **afirmar o fijar cifras sobre el estado real sin contrastarlas contra el artefacto**, cuando la verificación era trivial y estaba disponible. La regla existe en POLITICA, en SETTINGS, en el §11 del traspaso anterior con formato ⚠️/✅, y en los propios encargos que el asistente escribe.

**Novedad de esta sesión, y es la que importa para el análisis de cartera:** por primera vez el patrón se registra desde el lado del *contención*, no del daño. Los dos errores fueron **atrapados antes de tocar el repositorio**: el #1 por el reporte de Claude Code (que ejecutó `git status` y mostró la realidad), el #2 por una compuerta explícita del encargo. Ninguno produjo un artefacto incorrecto. Esto refuerza, con evidencia de signo contrario, la conclusión que v07 dejó planteada: la regla declarativa no previene el error (cuatro sesiones consecutivas lo demuestran), pero **la compuerta mecánica sí lo contiene**. La recomendación para la cartera se mantiene y se robustece: donde el patrón aparezca, no reforzar el énfasis de la regla; convertirla en un paso obligatorio del procedimiento, y **hacer que ese paso recompute, no que compare contra una cifra heredada** (aprendizaje 2 de esta sesión).

---

## 8. Constantes y parámetros vigentes

Sin cambios respecto a v07. Ninguna constante del pipeline se tocó. Ningún archivo de configuración se modificó.

Estado vigente de las reglas de gobernanza (verificado en el remoto, no supuesto):

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| Regla de ignore de intermedios | `40_salidas/mapa_interactivo/*.rds` | `.gitignore:83` | `check-ignore` exit 0 sobre ambos `.rds` |
| Regla de ignore de sistema | `.claude/` | `.gitignore:32` | `check-ignore` exit 0 |

---

## 9. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, corrida de **2026-07-12 08:56:09**, 380 entradas (75 carpetas, 305 archivos). Verificado contra él, no supuesto:

- `50_documentacion/activa/backlog_acumulativo.md` — **27,83K** (antes 24,62K), reflejando las entradas 21–24.
- `50_documentacion/traspasos/traspaso_cierre_v07.md` (29,62K) — commiteado en `4973465`.
- Estructura sin cambios respecto a v07: ningún archivo movido, creado ni eliminado fuera de `50_documentacion/`.

**Deuda estructural heredada, no corregida** (idéntica a v07):
- `50_documentacion/activa/POLITICA_PROYECTO.md` (34,61K) y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (57,28K) son versiones anteriores a las de la knowledge base (POLITICA v5.2, SETTINGS v7). El proyecto opera con las de la knowledge base. Ver pendiente #3.
- `50_documentacion/activa/decisiones/diagnostico_migracion_github.R` es un `.R` en la carpeta de decisiones (residuo del protocolo 4.3, que pedía mover el `.md` de diagnóstico, no el script). Deuda menor, nueva en el inventario: detectada en la auditoría de apertura de esta sesión. Ver pendiente #4.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | **Re-chequeo visual del mapa interactivo** | Bug / QA | Baja (o Media–Alta si arroja correcciones) | **Sin resultado desde v07.** Primera acción de la sesión 9. Si arroja correcciones, encabezan todo y el ciclo diagnóstico→cambio→re-auditoría sobre `docs/data/` es obligatorio. Si sale limpio, se cierra y la sesión pivota al Censo |
| 2 | **Commit y push del cierre de la sesión 8** | Gobernanza | Baja | Traspaso v08, `ESTADO.md` y snapshot del escáner. Primera acción mecánica de la sesión 9 (o del titular). El remoto quedó sincronizado hasta `78d633b` |
| 3 | **Sincronizar POLITICA y SETTINGS del repo con la knowledge base** | Deuda heredada | Baja | **Tarea manual del titular:** descargar ambos de la knowledge base y reemplazar los dos archivos en `50_documentacion/activa/`. Heredado de v07 sin cambios |
| 4 | Mover `diagnostico_migracion_github.R` fuera de `activa/decisiones/` | Deuda heredada | Trivial | Es un `.R` en una carpeta de decisiones (`.md`). Cosmético; agrupar con otro trabajo, no merece sesión |
| 5 | **Diagnóstico Censo 2024** | Funcionalidad nueva / exploratorio | Alta | Encargo ya escrito (`50_documentacion/andamios/`). **Sesión dedicada con contexto fresco.** No mezclar con correcciones del mapa |
| 6 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Abierto desde v05 |
| 7 | Validación con el equipo experto (mapa) | Bloqueante externo | — | Abierto desde v06 |
| 8 | Decidir visibilidad del sitio Pages (público en repo privado) | Decisión estratégica | Baja | Definir con el titular si es aceptable o requiere GitHub Pro |
| 9 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Requiere universo `ID_ESTAB` + fuente de geo propia |
| 10 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Datos ya excluidos pero disponibles y válidos |

**Evaluación de deuda técnica:** ninguna zona frágil. El pipeline no se tocó en dos sesiones consecutivas. La deuda documental está en cero salvo los ítems #3 y #4, ambos triviales y ambos de tipo "archivo en el lugar equivocado", no de contenido. **El proyecto está, por primera vez desde la sesión 4, sin deuda de gobernanza ni documental pendiente de ejecución.**

**Auditoría de cierre (política 5.6):**
- ¿El pipeline corre de cero sin intervención manual? **Parcial, sin cambios.** 34→35→36 sí; `sincronizar_docs.sh` es manual, documentado en el README. Deuda declarada y aceptada, no nueva.
- ¿Cada transformación crítica tiene validación? **Sí** (gates compuestos, `stopifnot`). No se tocó nada.
- ¿Outputs reproducibles e idempotentes? **Sí**, verificado por hash en v06. Sin cambios.
- ¿Decisiones metodológicas como constantes nombradas? **Sí**, con archivo de decisión propio desde v07.
- ¿Nombres sin tildes/ñ/espacios? **Sí** en todo lo generado. Las excepciones son heredadas de fuentes externas, declaradas.

Ninguna respuesta "no". No se agregan pendientes por auditoría.

**Ruta sugerida sesión 9:** (1) commit y push del cierre de la v08 (mecánico); (2) el re-chequeo visual, que sigue siendo la incógnita que define la sesión; (3) si el re-chequeo sale limpio, **el Censo 2024 con sesión dedicada y contexto fresco**, que es el único frente sustantivo abierto. Los pendientes #3 y #4 se agrupan con cualquier trabajo, no merecen sesión.

---

## 11. Instrucciones específicas para la próxima sesión

- ⚠️ **Toda afirmación sobre el estado del repositorio exige el comando que la respalde, en el mismo turno.** Cuarta sesión consecutiva registrando este patrón. La regla declarativa no funciona: trátala como **compuerta mecánica**, no como principio. Corre el comando antes de escribir la afirmación, no después de que te corrijan.
- ⚠️ **Una compuerta recomputa; no compara contra una cifra heredada.** Si un encargo fija un gate numérico, ese número debe salir de un comando corrido *en ese encargo*, no de un reporte anterior. Aprendizaje nuevo de esta sesión (error #2).
- ⚠️ **No confíes en las afirmaciones del traspaso sobre el estado del repositorio sin verificarlas.** El §2 de v07 decía "commits locales" cuando el trabajo estaba sin commitear. Este traspaso cita los comandos que respaldan su §2; aun así, corre `git status --short --branch` y `git log --oneline origin/main..main` al abrir.
- 🔒 Los tres JSON de `40_salidas/mapa_interactivo/web/data/` **están versionados a propósito**. No son fuga de gobernanza (son agregados sin identificador individual; el MRUN se descarta tras agregar). No los destrackees "limpiando".
- 🔒 **Antes de escribir cualquier regla de `.gitignore` sobre una ruta, correr `git ls-files <ruta>`.** `git status` no muestra lo trackeado sin cambios.
- 🔒 `00_run_all.R`, `31`, `32`, `33`, `33b`, `10_*`, maestro, y `34/35/36`: intocables sin instrucción explícita. Todos auditados.
- 🔒 Exclusiones de **alcance** v1 (territorio insular, parvularia JUNJI/Integra): no son defectos. No "arreglarlas" reincluyéndolas sin encargo v2 explícito. Tienen archivo de decisión propio que lo documenta.
- 🔒 **El backlog jamás se renumera, reescribe ni resume.** Un error se corrige con una entrada nueva. La discontinuidad entre el cambio 19 y el 20 es un hecho histórico declarado (§2.1 del backlog), no un error de conteo.
- ⚠️ `tipo_pendiente` de `ESTADO.md` usa el enum de SETTINGS §1.2.4 (`bug | bloqueante | deuda_heredada | deuda_tecnica | nuevo | cosmetica | ninguno`), **no** la taxonomía temática del backlog. Traducir por significado; nunca ampliar el enum.
- ✅ ANTES de cualquier cambio a `docs/data/`: ciclo diagnóstico→cambio→re-auditoría completo. Son productos de un pipeline auditado dos veces.
- ✅ ANTES de fijar cualquier gate o cifra (de datos **o de proceso**): recomputar contra el artefacto real, nunca reusar una cifra de un reporte anterior.
- ✅ ANTES de incorporar este traspaso al backlog: el push de la sesión 8 entra como **cambio 25** (decisión declarada en §3.2).
- 🔒 Máximo 2 agentes en Claude Code.

---

## 12. Fragmentos de código de referencia

**Compuerta de verificación de estado del repositorio (la forma correcta, refinada en esta sesión):**
```bash
# La compuerta RECOMPUTA el estado. No compara contra una cifra heredada
# de un reporte anterior: ese fue el error #2 de la sesion 8.

git remote -v                              # el remoto es slep_territorio_costa_central
git status --short --branch                # working tree limpio? [ahead N]?
git log --oneline main..origin/main        # divergencia? (vacio = no)
git log --oneline origin/main..main        # cuantos commits van al remoto (REPORTAR, no comparar)
git ls-files --others --exclude-standard   # untracked: algun .rds/.csv/.xlsx?

# Verificar las reglas de gobernanza contra el artefacto, siempre:
git check-ignore -v 40_salidas/mapa_interactivo/directorio_region5.rds  # exit 0 = ignorado
git ls-files 40_salidas/mapa_interactivo/  # debe devolver EXACTAMENTE los 3 JSON de web/data/
```

**Verificación obligatoria antes de escribir una regla de `.gitignore` (heredado de v07, sigue vigente):**
```bash
# INSUFICIENTE: git status solo muestra untracked y modificados
git status --short

# CORRECTO: git ls-files revela lo trackeado historicamente, aunque no tenga cambios
git ls-files 40_salidas/mapa_interactivo/
# Si devuelve algo, esos archivos NO se ignoran al agregar la regla:
# quedan "trackeados bajo ruta ignorada" (funcional, pero trampa de mantenimiento).
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

**Nombre del chat:** `slep_georreferenciacion, sesión 9 (Fable)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior y el escáner más reciente.

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar; solo verificar que esté al día): `POLITICA_PROYECTO.md` (v5.2), `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (v7).
2. *Opcionales según el foco real*:
   - Si la sesión aborda el **Censo 2024**: `diccionario_variables_censo2024.xlsx` y `Ficha_metodologica_CPV2024.pdf` (del proyecto padre, fuera de este repo), más el encargo ya escrito en `50_documentacion/andamios/`.
   - Si el **re-chequeo visual arrojó correcciones**: los archivos de `docs/` afectados (`mapa.js`, `estilo.css`, `index.html`) y los JSON de `docs/data/` involucrados.
   - `backlog_acumulativo.md` si la sesión va a incorporar el cambio 25 (es un archivo de 27,83K; adjuntarlo solo si se va a editar).
   - `CLAUDE.md` si la sesión correrá en Claude Code.
3. *Específicos de la sesión (SÍ adjuntar)*: este traspaso (`traspaso_cierre_v08.md`); el escáner `estructura_actual.md` **re-ejecutado al abrir**; el **resultado del re-chequeo visual** del mapa interactivo, si existe.

**Nota final:** el remoto quedó sincronizado hasta `78d633b`. El cierre de esta sesión (traspaso v08, `ESTADO.md`, snapshot del escáner) queda **sin commitear**: es la primera acción mecánica de la sesión 9. Verificar al abrir con `git status --short --branch` y `git log --oneline origin/main..main`, **no asumirlo desde este párrafo** (el §2 de v07 se equivocó exactamente así).

---

## 14. Delta del backlog acumulativo

**Entradas incorporadas en esta sesión:** 4 (cambios 21 a 24 de la sesión 7), más el cierre de la fila de la sesión 7 en el resumen estadístico y la actualización de la sección 6.

**Entradas pendientes de incorporar:** 1. El trabajo de la sesión 8 (commit y push de la sesión 7 completa, más la incorporación del propio backlog) es **un** cambio registrable según la nota metodológica (una solicitud distinguible del titular: "prioridad 2" y "prioridad 3" fueron dos, pero conceptualmente son el mismo cierre de borde). Se registra como **cambio 25** al incorporar este traspaso, con la fila de la sesión 8 en el resumen estadístico: `8 | v08 | 1 (25) | Fable | Push de la sesión 7 y cierre del backlog`.

**Sin refinamientos de taxonomía.** Las 13 categorías siguen vigentes. El cambio 25 cae en *Gobernanza y versionado*.
