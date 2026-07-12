# Traspaso de cierre — v09

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 9
**Entorno:** Claude (conversacional) + Claude Code · **Repo remoto:** `https://github.com/tomgc/slep_territorio_costa_central`
**Tipo de sesión:** CONTINUATION
**Archivos principales modificados:** `docs/assets/estilo.css`; `docs/assets/mapa.js`. Commiteados además: `50_documentacion/traspasos/traspaso_cierre_v08.md`, `50_documentacion/activa/ESTADO.md`, `50_documentacion/activa/backlog_acumulativo.md`, `50_documentacion/estructura/*`.

---

## 1. Resumen ejecutivo

La sesión cierra el pendiente que había definido las dos anteriores: **el re-chequeo visual del mapa interactivo, hecho y cerrado en limpio**. Arrojó cuatro hallazgos, de los cuales solo dos eran defectos reales del producto (un chip vacío que se pintaba siempre, y la ausencia de zoom-to-fit al filtrar); los otros dos resultaron no ser bugs (los cuatro RBD "sin datos" son comportamiento correcto del pipeline sobre una fuente incompleta, y el 404 de consola es el favicon ausente). Se sumó una decisión del titular no prevista en la ruta: **unificar la identidad cromática del producto**, migrando el chrome del ciruela `#4A2746` (heredado del afiche impreso) al azul institucional `#0D2E52` del SLEP Costa Central. El trabajo se publicó: tres commits separados por tipo conceptual (`9f39df5`, `119edc4`, `b7d9a8a`), push fast-forward, `origin/main` en `b7d9a8a`. **El pipeline R no se tocó; `docs/data/` no cambió.** Se registran **dos errores del asistente**, del mismo patrón matriz que domina las tablas desde v06; ambos fueron atrapados por la compuerta mecánica y ninguno llegó al repositorio. La sesión aporta un aprendizaje nuevo y concreto sobre el diseño de esas compuertas (§5.2), que es probablemente lo más valioso que deja para la cartera.

---

## 2. Estado al cierre

**Funciona (verificado contra el artefacto, no supuesto):**
- **Repositorio sincronizado.** `git log --oneline origin/main..main` vacío; `git status --short --branch` sin `[ahead N]`; working tree limpio. `origin/main` en `b7d9a8aa9af35500e60ccccd7d0d7c86c03fa61b` (`78d633b..b7d9a8a`, fast-forward, sin force).
- **Gobernanza operando:** `git check-ignore -v 40_salidas/mapa_interactivo/directorio_region5.rds` → exit 0 (`.gitignore:83`). Cero untracked. Barrido de identificadores personales sobre los tres commits: cero valores MRUN reales, cero patrones RUT (las coincidencias de "MRUN" son menciones en prosa de la regla de gobernanza).
- **Variante 3 (mapa interactivo):** publicada y **re-chequeada visualmente por el titular**. Los dos defectos hallados están corregidos y verificados en el navegador. `docs/data/` intacto (`git log -1 -- docs/data/` → `4e15c98`, anterior a esta sesión).
- **Variantes 1 y 2 (afiches A0):** sin cambios. En espera de validación del director (bloqueante externo desde v05).

**No funciona / pendiente:**
- `docs/index.html` no declara favicon → 404 en consola en cada carga. **Cosmético, sin impacto en el usuario.** Ver pendiente #2.
- Las copias de `POLITICA_PROYECTO.md` y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` en `50_documentacion/activa/` siguen siendo anteriores a las de la knowledge base (POLITICA v5.2, SETTINGS v7). Heredado de v07 y v08 sin corregir: **es tarea manual del titular.**
- `50_documentacion/activa/decisiones/diagnostico_migracion_github.R` sigue siendo un `.R` en una carpeta de `.md`. Deuda trivial heredada de v08.
- El cierre de ESTA sesión (traspaso v09, `ESTADO.md`, snapshot del escáner) queda **sin commitear**: es la primera acción mecánica de la sesión 10.

**Delta respecto a v08:** v08 dejó el re-chequeo visual sin resultado por segunda vez consecutiva, y lo declaró como "el pendiente que define la forma de la sesión 9". Esta sesión lo ejecutó, lo cerró, corrigió lo que arrojó, unificó la identidad cromática y publicó todo. **El proyecto queda sin ningún pendiente ejecutable sobre el mapa interactivo.** El único frente sustantivo abierto que no depende de terceros es el Censo 2024.

---

## 3. Registro detallado de cambios

### 3.1 Re-chequeo visual del mapa interactivo (ejecutado por el titular)
Categoría temática: **QA y validación**. Cierra el pendiente #1 de v07 y v08.

El titular recorrió un checklist de seis áreas (etiquetas de comuna, pines, tarjeta, filtros y leyenda, layout/responsive, exportación). **Etiquetas, pines y exportación: limpio.** Las etiquetas de comuna, que eran el sospechoso principal heredado de sesiones anteriores (el "Concón" al `top: 98.84%`, la posición de "Puchuncaví"), **no presentan problema**: quedan cerradas como no-defecto.

Cuatro hallazgos, de naturaleza distinta:

| # | Hallazgo | Naturaleza | Resolución |
|---|---|---|---|
| 1 | Objeto ocre bajo el input de "Establecimiento" | **Bug de CSS** | Corregido (§3.2) |
| 2 | No hay zoom-to-fit al aplicar un filtro | **Funcionalidad faltante** | Implementado (§3.3) |
| 3 | Cuatro RBD con datos ausentes o escasos | **No es bug** (§3.5) | Cerrado sin acción |
| 4 | 404 en consola | **No es bug del producto** (§3.6) | Diferido, cosmético |

### 3.2 Bug: el chip de establecimiento se pintaba estando vacío
Categoría: **corrección de front-end**.

**Síntoma observable:** una franja ocre visible bajo el input del combobox, sin ningún establecimiento seleccionado.

**Causa raíz:** `#f-ee-sel` (`index.html:39`) declara el atributo `hidden`, pero la regla `.combobox-sel` de `estilo.css` declara `display: flex`. **El `display` de una regla de autor gana sobre el `display: none` implícito del atributo `hidden`, que actúa desde la hoja de estilos del user agent.** El chip se pintaba siempre, vacío, con su fondo `#EFE9DD` y su `padding: 6px 10px`.

**Solución:** regla global en la zona de reset de `estilo.css` (inmediatamente después del `* { margin: 0; ... }`, no al final del archivo: es un reset, no un parche):

```css
[hidden] { display: none !important; }
```

**Verificado:** `#f-ee-sel` con `hidden` → `display` computado `none`. El mismo defecto latente afectaba a `#f-nivel-wrap` (`index.html:42`), que no se manifestaba porque `.filtro` no le imponía un `display`; la misma regla lo cubre.

**Patrón general aprendido:** *el atributo `hidden` no es confiable en presencia de reglas de autor que declaren `display`. Todo proyecto que use `hidden` como mecanismo de visibilidad debe incluir `[hidden] { display: none !important; }` en su reset.* No es un bug de este proyecto: es un defecto conocido de la especificación CSS que muerde a cualquiera que combine `hidden` con `flex`/`grid`/`block` en una clase.

### 3.3 Zoom-to-fit al aplicar filtros
Categoría: **funcionalidad nueva (front-end)**.

**Motivación del titular:** con la vista por defecto encuadrada en Costa Central, filtrar por (digamos) provincia de Petorca dejaba los coincidentes fuera de pantalla; había que hacer zoom-out y buscarlos a mano.

**Decisiones de diseño tomadas antes de codificar** (todas confirmadas por el titular):
- **(A)** El encuadre se aplica en TODO `aplicarFiltros()` con filtros activos y resultados, **incluida la selección de un establecimiento puntual** desde el combobox. Razón: "busqué este colegio, llévame a él" es el mismo gesto.
- **(B)** Tope `maxZoom: 14`. Sin él, `fitBounds` sobre un punto único salta a z19 (nivel calle). A z14 el establecimiento se ve en su contexto comunal.
- **(C)** `limpiarFiltros()` devuelve la vista al **encuadre por defecto**. Limpiar es un gesto distinto de filtrar.
- **(D)** Con `n === 0` la vista **no se mueve**. El mensaje `#cero-resultados` ya informa; mover el mapa a ninguna parte es peor que dejarlo quieto.

**Implementación:**
- Constantes nombradas al inicio del archivo, junto a `HOVER_EXTRA` (POLITICA 5.3.10, sin números mágicos):
  ```js
  const ZOOM_MAX_ENCUADRE = 14;
  const PAD_ENCUADRE_FILTRO = 0.12;
  ```
- `S.boundsDefecto` guardado en el montaje como **única fuente de verdad** del encuadre por defecto; el `fitBounds` inicial lo consume, y `limpiarFiltros()` vuelve a él. Antes el valor se calculaba inline en el montaje y no existía en ningún otro lado.
- En `aplicarFiltros()`, tras el bloque de cero-resultados y antes de `reconstruirOpciones()`:
  ```js
  if (activos && coincidentes.length) {
    S.mapa.fitBounds(L.featureGroup(coincidentes).getBounds().pad(PAD_ENCUADRE_FILTRO),
                     { maxZoom: ZOOM_MAX_ENCUADRE, animate: true });
  }
  ```
- En `limpiarFiltros()`, **fuera** de `aplicarFiltros()`, tras llamarla: `S.mapa.fitBounds(S.boundsDefecto, { animate: true });`

**Punto delicado, verificado:** `iniciarFiltros()` **no llama a `aplicarFiltros()`** (llama directamente a `reconstruirOpciones()`), de modo que el encuadre inicial no se altera. Aun si una sesión futura agregara esa llamada, la guarda `activos` protege (todos los `F` son `null` al arrancar). El diseño aguanta.

**Defecto menor conocido y aceptado:** el `fitBounds` de `limpiarFiltros()` se dispara también cuando el usuario aprieta "Limpiar filtros" sin haber filtrado nada, reencuadrando aunque hubiera hecho zoom manual. Se decidió dejarlo: el comportamiento es predecible y el caso es marginal; una guarda `if (huboFiltros)` añadiría estado sin ganancia real.

**Verificado en el navegador (por Claude Code y confirmado por el titular):** Comuna=Casablanca → encuadra los 22 coincidentes; RBD puntual → z14 exacto, centrado en el pin; limpiar → vista idéntica a la inicial (z10, centro `-32.866,-71.432`); cero resultados → la vista no se mueve. `grep -c "fitBounds"` = 3 (montaje, aplicar, limpiar). Cero errores de consola.

### 3.4 Unificación cromática al azul institucional
Categoría: **identidad visual**. Decisión del titular, fuera de la ruta propuesta.

**Diagnóstico:** el producto usaba **dos identidades cromáticas**. El ciruela `#4A2746` (heredado del afiche impreso) era el color del chrome (título, contador, borde de cabecera, nombre en la tarjeta, botones, sparkline, título del SVG exportado); el azul institucional `#0D2E52` (SLEP Costa Central) codificaba los pines y la frontera. **El logo del encabezado es azul.** Incoherencia visible.

**Alternativas presentadas:**
- (A) Reemplazo total: el azul institucional se vuelve el único color principal, incluido el sparkline.
- (B) Reemplazo del chrome, sparkline con color propio, para que el azul no pierda su función de codificación de dependencia en el mapa.

**Decisión del titular: (A), reemplazo total.** Justificación: el sparkline vive dentro de una tarjeta, no es un pin en el mapa; nadie lo confunde con la codificación de dependencia, y la coherencia con el logo pesa más que un riesgo teórico de ambigüedad.

**Ejecución:**
- Variable **renombrada, no solo revaluada**: `--ciruela: #4A2746` → `--azul-institucional: #0D2E52`. Dejar el nombre `--ciruela` apuntando a un azul sería mentir sobre el contenido.
- Las 8 referencias `var(--ciruela)` migradas.
- **Colores derivados** que también migraron (los sueltos, no cubiertos por la variable): hover de exportar `#5D3358` → `#1A4576`; hover de limpiar `#F6F1F4` → `#EEF2F7`; anillo de foco `#B7A6C4` → `#5E8AB4`.
- En `mapa.js`: `COLOR_CIRUELA` → `COLOR_INSTITUCIONAL`; los **hex literales del SVG exportado** (título y separador de cabecera, que no usaban la constante) pasaron a `${COLOR_INSTITUCIONAL}` (mejor que el encargo, que solo pedía sustituir el hex: eliminar el número mágico es POLITICA 5.3.10).
- `PAL_SLEP['Costa Central']` **intacto**. El punto era que el chrome convergiera a él, no que él cambiara.

**Hallazgo de accesibilidad, no buscado:** el anillo de foco que el asistente propuso (`#7FA3C7`) daba **2,64:1**, bajo el mínimo de 3,0:1 de WCAG 1.4.11 para elementos no textuales. Claude Code lo detectó al calcular los contrastes, lo oscureció un paso a `#5E8AB4` (**3,64:1**) y declaró el desvío. **De paso corrige un incumplimiento preexistente:** el `#B7A6C4` original daba **2,27:1**, o sea el anillo de foco del producto llevaba desde el hito 3 sin cumplir WCAG.

**Contrastes verificados (todos WCAG AA o superior):**

| Par | Ratio | Cumple |
|---|---|---|
| `#0D2E52` sobre `#EEF2F7` (hover limpiar) | 12,21:1 | AA ✅ |
| `#FFFFFF` sobre `#1A4576` (hover exportar) | 9,74:1 | AA ✅ |
| `#FFFFFF` sobre `#0D2E52` (exportar base) | 13,73:1 | AA ✅ |
| `#0D2E52` sobre `#FFFFFF` (papel) | 13,73:1 | AA ✅ |
| `#5E8AB4` anillo de foco (aplicado) | 3,64:1 | 1.4.11 ✅ |

**Verificado:** `grep -ic "ciruela"` = 0 y `grep -c "4A2746"` = 0 en ambos archivos, incluidos comentarios. SVG exportado (vía `__M.construirSVG()`): cero ocurrencias de `4A2746`, 78 de `0D2E52`. `node --check` sobre `mapa.js`: OK.

**Fuera de alcance, deliberadamente:** la gama beige (`--pagina`, `--linea1`, `--linea2`, el chip `#EFE9DD`) no deriva del ciruela y sigue vigente. Es la paleta "papel" del afiche, funciona como fondo neutro y no compite con el azul ni codifica nada en el mapa.

### 3.5 Los cuatro RBD reportados: NO son un bug
Categoría: **QA y validación**. Cerrado sin acción sobre el código.

El titular reportó cuatro establecimientos con datos ausentes o escasos. **Diagnosticados contra `docs/data/establecimientos.geojson` (el artefacto, no la deducción):**

| RBD | Nombre | Comuna | Dependencia | Estado real |
|---|---|---|---|---|
| 14459 | Escuela de Párvulos Campanita | Limache | Particular Pagado | `ens: []`, serie 100% vacía → **grupo de 60 sin registros** |
| 41528 | Sala Cuna y Jardín Infantil El Rincón de Matías | Concón | Particular Pagado | Idem → **grupo de 60** |
| 41549 | Jardín Infantil y Sala Cuna Macamagus | Concón | Particular Pagado | Idem → **grupo de 60** |
| 14503 | Escuela de Párvulos Korcito | Concón | Particular Pagado | **Serie COMPLETA:** 12, 4, 18, 16, 15, 13, 15, 6, 7, 3 |

Los tres primeros son exactamente el caso que el pipeline ya modela y que la tarjeta ya declara (`TEXTO_SIN_OFERTA_LARGO`: "Figura como funcionando en el directorio oficial, pero sin matrícula ni tipos de enseñanza registrados en 2016–2025"). **Korcito no tiene "pocos datos": tiene 3 párvulos matriculados en 2025.** La serie está completa; el establecimiento está en declive.

**El dato relevante:** los cuatro son **Particular Pagado**. Los jardines privados no reportan matrícula al SIGE con la consistencia de los subvencionados. **La ausencia no es un defecto del pipeline: es una característica de la fuente**, y se concentra en una dependencia específica.

**Decisión:** ninguna acción. Un posible v2 podría añadir a la tarjeta de los 60 una nota aclarando que la ausencia se concentra en particulares pagados, pero eso es **contenido, no bug**, y no se abrió en esta sesión.

### 3.6 El 404 de consola: NO es un bug del producto
Categoría: **QA y validación**. Diferido como cosmético.

Dos errores distintos en la consola, ambos capturados por el titular:

1. **`favicon.ico` 404.** El navegador pide siempre un favicon; `docs/index.html` no declara ninguno; GitHub Pages devuelve el 404 de la raíz (por eso en la primera captura el recurso aparecía como `slep_territorio_costa_central/:1` y no como el nombre del archivo). **Cosmético puro:** no rompe nada y solo lo ve quien abre la consola. Ver pendiente #2.
2. **`Unchecked runtime.lastError: Could not establish connection.`** **No es del sitio.** El propio DevTools lo explica: ocurre en desarrollo de extensiones de Chrome. Es una extensión del navegador del titular intentando hablar con un content script que no respondió. No aparece en la consola de otros usuarios. **Cero acción.**

---

## 4. Bugs de la sesión

| # | Síntoma | Causa raíz | Solución | Estado |
|---|---|---|---|---|
| 1 | Franja ocre visible bajo el input del combobox, sin selección | `.combobox-sel { display: flex }` anula el `display:none` implícito del atributo `hidden` (regla de autor > UA stylesheet) | `[hidden] { display: none !important; }` en la zona de reset de `estilo.css` | **Resuelto**, verificado en el DOM |
| 2 | Anillo de foco de los `<select>` con contraste 2,27:1 (preexistente, no reportado) | `#B7A6C4` (lila derivado del ciruela) bajo el mínimo 3,0:1 de WCAG 1.4.11 | `#5E8AB4` (3,64:1) | **Resuelto** de forma colateral en §3.4 |

**Ningún bug del pipeline R.** Ningún script de `30_procesamiento/` se tocó. `docs/data/` no cambió.

---

## 5. Aprendizajes y restricciones descubiertas

1. **El atributo `hidden` es frágil ante cualquier regla de autor que declare `display`.** No es específico de este proyecto: es un comportamiento de la cascada CSS (el `display:none` de `hidden` vive en la hoja del user agent y pierde ante cualquier clase). **Regla: todo proyecto que use `hidden` como mecanismo de visibilidad debe llevar `[hidden] { display: none !important; }` en su reset**, y esa regla va en el reset, no como parche al final del archivo. Aplicable a cualquier front-end de la cartera.

2. **Una compuerta con lista blanca es una compuerta que compara contra una cifra heredada — y por lo tanto es defectuosa.** Este es el aprendizaje nuevo de la sesión, y refina directamente el de v08 §5.2. El asistente escribió la compuerta de FASE 0 del encargo de commit enumerando los archivos que *esperaba* ver modificados. Esa lista salió del traspaso v08, no de un `git status`. Faltaba `backlog_acumulativo.md`, y la compuerta se disparó sobre trabajo legítimo. **La compuerta hizo su trabajo (detuvo y consultó), pero por la razón equivocada — exactamente el mismo defecto que v08 §5.2 identificó para los gates numéricos, en otra forma.** La lección se generaliza: *una compuerta correcta no enumera lo esperado; reporta lo que hay y detiene ante lo inesperado, sin necesidad de una lista previa.* Enumerar lo esperado convierte al asistente en la fuente de verdad, que es precisamente lo que la compuerta existe para evitar.

3. **Un subconjunto citado en un traspaso no es el inventario del conjunto.** El asistente afirmó que `docs/data/` contiene "los 3 JSON de siempre". Contiene 6 archivos. El "3 JSON" venía del traspaso v08, donde se refería a los tres que `sincronizar_docs.sh` copia — un subconjunto, no el contenido total de la carpeta. **Regla: antes de citar un inventario, correr el comando que lo lista; una cifra que aparece en un documento anterior puede estar respondiendo una pregunta distinta de la que se está haciendo ahora.**

4. **Leer el script antes de correrlo evitó una regresión real.** El titular pidió correr `sincronizar_docs.sh` antes de publicar. El asistente pidió su contenido en vez de asumirlo. El script copia los 3 JSON **desde `40_salidas/` hacia `docs/data/`** — y esta sesión no regeneró ningún dato. Correrlo habría sido, en el mejor caso, inútil (ensuciando el `git status` con timestamps); si `40_salidas/` hubiera estado desactualizado respecto a `docs/data/`, habría **sobrescrito datos publicados con una versión anterior**. **Regla: un script de sincronización tiene una dirección; verificarla antes de correrlo, siempre.**

5. **"Es cosmético" también necesita diagnóstico.** El 404 se pospuso tres turnos porque el asistente se negó a afirmar su causa sin el nombre del recurso en la pestaña Network. La hipótesis (favicon) resultó correcta, pero **la disciplina de no afirmarla sin el artefacto es lo que la volvió una conclusión y no una conjetura** — y de paso reveló un segundo error de consola (la extensión de Chrome) que la hipótesis sola no habría explicado.

---

## 6. Decisiones de diseño

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| **Identidad cromática del producto** | (B) migrar solo el chrome, dejando el sparkline con color propio para que el azul no pierda su función de codificación en el mapa | **(A) Reemplazo total.** El sparkline vive en una tarjeta, no es un pin; la coherencia con el logo pesa más que una ambigüedad teórica. Decisión del titular |
| Zoom-to-fit: ¿aplica al combobox? | (2) solo al cambiar un `<select>`, no al elegir un establecimiento puntual | **(1) Aplica siempre.** "Busqué este colegio, llévame a él" es el mismo gesto que filtrar |
| Zoom al centrar en un pin único | Sin tope (`fitBounds` saltaría a z19, nivel calle) | **`maxZoom: 14`.** El establecimiento en su contexto comunal, no la puerta de entrada |
| Vista al limpiar filtros | Dejarla donde el último filtro la dejó | **Volver al encuadre por defecto.** "Limpiar" debe revertir la vista |
| Vista con cero resultados | Encuadrar "nada" | **No mover.** El mensaje de cero ya informa; mover el mapa a ninguna parte es peor |
| Reencuadre al limpiar sin haber filtrado | Guarda `if (huboFiltros)` | **Dejarlo.** Comportamiento predecible, caso marginal; la guarda añadiría estado sin ganancia |
| Gama beige (`--linea1/2`, `--pagina`, chip) | Migrarla también al azul | **Dejarla.** No deriva del ciruela, es fondo neutro, no compite ni codifica |
| Los 4 RBD reportados | Investigar el pipeline | **Sin acción.** Verificado contra el geojson: comportamiento correcto sobre una fuente incompleta |
| Nota sobre particulares pagados en la tarjeta de los 60 | Agregarla ahora | **Diferida.** Es contenido, no bug. Candidata a v2 |

Ninguna decisión de esta sesión tiene peso arquitectónico suficiente para un archivo propio en `50_documentacion/activa/decisiones/`. La cromática es la más cercana, pero es una decisión de identidad visual sobre un producto ya definido, no una decisión de arquitectura.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Encargo de commit y push (FASE 0) | Claude Code se detuvo en la compuerta y consultó al titular | Escribí la lista blanca de la compuerta enumerando los archivos que esperaba ver modificados, **sin haber corrido `git status`**. Omití `backlog_acumulativo.md`, modificado desde la sesión 8 | POLITICA 1.2.6 (nunca operar sobre estado supuesto) | Deduje el contenido del working tree desde el traspaso v08 (que lista lo que *él* dejó pendiente, no lo que hay hoy) en vez de recomputarlo. **La lista blanca es una cifra de proceso: debía salir de un comando, no de un documento.** La regla existía y era literalmente sobre este caso | POLITICA 1.2.6 + la ⚠️ y la ✅ explícitas de v08 §11 + el propio §5.2 de v08, que yo mismo cité en el acuse de recibo | **Mismo que v08 #1 y #2; v07 #1, #2, #4; v06 #2 y #4.** Quinta sesión consecutiva |
| 2 | Panel adversarial del mismo encargo | Claude Code lo señaló al ejecutar la verificación 3 | Afirmé que `docs/data/` contiene "los 3 JSON de siempre". Contiene 6 archivos | POLITICA 1.2.6 | Arrastré el "3 JSON" del traspaso v08, donde se refería a los tres archivos que `sincronizar_docs.sh` copia — un **subconjunto**. Lo usé como si fuera el inventario completo de la carpeta. Confundí la respuesta a una pregunta con la respuesta a otra | POLITICA 1.2.6 | Variante del anterior, específica sobre **inventarios citados de traspasos previos** |

**Patrón cruzado (quinta sesión consecutiva).** Ambos errores son la misma causa raíz que domina las tablas desde v06: **afirmar algo sobre el estado real sin contrastarlo contra el artefacto**, cuando la verificación era trivial y estaba disponible. La regla existe en POLITICA, en SETTINGS, en el §11 de los dos traspasos anteriores con formato ⚠️/✅, y en los encargos que el propio asistente escribe.

**Lo que esta sesión aporta al análisis de cartera, y es lo importante:** por **segunda sesión consecutiva** el patrón se registra **desde el lado de la contención**. Ambos errores fueron atrapados antes de tocar el repositorio: el #1 por la compuerta mecánica del encargo, el #2 por el panel adversarial. Ninguno produjo un artefacto incorrecto.

**Pero hay un hallazgo nuevo y más incómodo.** El error #1 no fue atrapado *a pesar* de la compuerta: fue atrapado *por* una compuerta **que él mismo había contaminado**. La lista blanca de la compuerta era, ella misma, una cifra heredada. Esto significa que **el asistente está reproduciendo el patrón matriz dentro del propio mecanismo diseñado para contenerlo.** La conclusión para la cartera se afila:

> No basta con convertir la regla en compuerta mecánica (v07/v08). **La compuerta debe estar construida de modo que el asistente no pueda inyectar en ella una expectativa heredada.** Una compuerta que enumera lo esperado delega en el asistente la definición de lo correcto — que es exactamente la función que la compuerta existe para arrebatarle. **Una compuerta correcta reporta lo que hay y detiene ante lo inesperado, sin lista previa.**

Si este `patron` aparece en las tablas de errores de otros proyectos de la cartera, la recomendación no es reforzar el énfasis de la regla (cinco sesiones demuestran que eso no funciona), ni siquiera "poner una compuerta": es **auditar el diseño de las compuertas existentes en busca de listas blancas, cifras esperadas y expectativas enumeradas**, y reescribirlas como reportes.

---

## 8. Constantes y parámetros vigentes

Ninguna constante del pipeline R se tocó. Nuevas constantes en `docs/assets/mapa.js`:

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `ZOOM_MAX_ENCUADRE` | `14` | `docs/assets/mapa.js` | Tope al encuadrar filtrados. Sin él, un pin único salta a z19 |
| `PAD_ENCUADRE_FILTRO` | `0.12` | `docs/assets/mapa.js` | Aire alrededor del encuadre de los coincidentes |
| `COLOR_INSTITUCIONAL` | `#0D2E52` | `docs/assets/mapa.js` | **Nuevo nombre** de `COLOR_CIRUELA` (`#4A2746`). Único color principal del producto |
| `S.boundsDefecto` | `capaFrontera.getBounds().pad(0.15)` | `docs/assets/mapa.js` (montaje) | Única fuente de verdad del encuadre por defecto |
| `--azul-institucional` | `#0D2E52` | `docs/assets/estilo.css` | **Nuevo nombre** de `--ciruela` (`#4A2746`) |

Estado de la gobernanza (verificado en el remoto, no supuesto):

| Regla | Valor | Archivo | Verificación |
|---|---|---|---|
| Ignore de intermedios | `40_salidas/mapa_interactivo/*.rds` | `.gitignore:83` | `check-ignore` exit 0 |
| Ignore de sistema | `.claude/` | `.gitignore:32` | `check-ignore` exit 0 |

---

## 9. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, corrida de **2026-07-12 12:24:24**, **381 entradas (75 carpetas, 306 archivos)**. Verificado contra él, no supuesto:

- **+1 archivo** respecto al escáner de apertura (08:56:09, 380 entradas): el `traspaso_cierre_v08.md`, que en la apertura estaba sin commitear y ahora vive en `50_documentacion/traspasos/`.
- Ningún archivo movido, creado ni eliminado fuera de `50_documentacion/` y `docs/assets/`.
- `docs/data/` intacto: 6 archivos, mismo contenido, último commit `4e15c98` (anterior a esta sesión).

**Deuda estructural heredada, no corregida** (idéntica a v08):
- `50_documentacion/activa/POLITICA_PROYECTO.md` y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` son versiones anteriores a las de la knowledge base. El proyecto opera con las de la knowledge base. **Tarea manual del titular.** Ver pendiente #3.
- `50_documentacion/activa/decisiones/diagnostico_migracion_github.R` es un `.R` en la carpeta de decisiones. Ver pendiente #4.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | **Commit y push del cierre de la sesión 9** | Gobernanza | Baja | Traspaso v09, `ESTADO.md`, snapshot del escáner. **Primera acción mecánica de la sesión 10.** El remoto quedó en `b7d9a8a` |
| 2 | **Favicon del sitio** | Cosmética | Trivial | `docs/index.html` no declara favicon → 404 en consola. Cerrar con un `<link rel="icon">` apuntando a un favicon con el logo institucional (`docs/assets/logo-color-stacked.png` como base). **Agrupar con cualquier trabajo futuro sobre `docs/`; no merece sesión ni encargo propio** |
| 3 | **Sincronizar POLITICA y SETTINGS del repo con la knowledge base** | Deuda heredada | Baja | **Tarea manual del titular:** descargar ambos de la knowledge base y reemplazar los dos archivos en `50_documentacion/activa/`. Heredado de v07 y v08 sin cambios |
| 4 | Mover `diagnostico_migracion_github.R` fuera de `activa/decisiones/` | Deuda heredada | Trivial | Cosmético; agrupar con otro trabajo |
| 5 | **Diagnóstico Censo 2024** | Funcionalidad nueva / exploratorio | Alta | Encargo ya escrito (`50_documentacion/andamios/`). **Es el único frente sustantivo abierto que no depende de terceros. Sesión dedicada con contexto fresco.** |
| 6 | Nota sobre particulares pagados en la tarjeta de los 60 sin registro | Contenido / mejora | Baja | La ausencia de matrícula se concentra en Particular Pagado (§3.5). Una nota en la tarjeta lo explicitaría. Candidata a v2 |
| 7 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Abierto desde v05 |
| 8 | Validación con el equipo experto (mapa) | Bloqueante externo | — | Abierto desde v06 |
| 9 | Decidir visibilidad del sitio Pages (público en repo privado) | Decisión estratégica | Baja | Definir con el titular si es aceptable o requiere GitHub Pro |
| 10 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Requiere universo `ID_ESTAB` + fuente de geo propia |
| 11 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Datos ya excluidos pero disponibles y válidos |

**Evaluación de deuda técnica:** ninguna zona frágil. El pipeline R no se toca hace **tres sesiones consecutivas**. La deuda documental sigue en cero salvo los ítems #3 y #4, ambos triviales y ambos de tipo "archivo en el lugar equivocado". **El mapa interactivo queda sin ningún pendiente ejecutable:** el re-chequeo visual, que definió las últimas tres sesiones, está cerrado.

**Auditoría de cierre (política 5.6):**
- ¿El pipeline corre de cero sin intervención manual? **Parcial, sin cambios.** 34→36 sí; `sincronizar_docs.sh` es manual y documentado. Deuda declarada y aceptada, no nueva. (Esta sesión **no** lo corrió, correctamente: no regeneró datos.)
- ¿Cada transformación crítica tiene validación? **Sí.** No se tocó nada del pipeline.
- ¿Outputs reproducibles e idempotentes? **Sí**, verificado por hash en v06. Sin cambios.
- ¿Decisiones metodológicas como constantes nombradas? **Sí**, y esta sesión agregó tres más (`ZOOM_MAX_ENCUADRE`, `PAD_ENCUADRE_FILTRO`, `S.boundsDefecto`), extraídas como constantes en vez de embebidas.
- ¿Nombres sin tildes/ñ/espacios? **Sí** en todo lo generado.

Ninguna respuesta "no". No se agregan pendientes por auditoría.

**Ruta sugerida sesión 10:** (1) commit y push del cierre de la v09 (mecánico, primera acción); (2) **el Censo 2024, con sesión dedicada y contexto fresco.** Es el único frente sustantivo que queda y merece la sesión completa. Los pendientes #2, #3 y #4 se agrupan con cualquier trabajo; no merecen sesión propia.

---

## 11. Instrucciones específicas para la próxima sesión

- ⚠️ **Toda afirmación sobre el estado del repositorio exige el comando que la respalde, en el mismo turno.** Quinta sesión consecutiva registrando este patrón. Corre el comando antes de escribir la afirmación, no después de que te corrijan.
- ⚠️ **Una compuerta NO enumera lo esperado: reporta lo que hay y detiene ante lo inesperado.** Aprendizaje nuevo de esta sesión (error #1). Si escribes un encargo con una lista blanca de archivos, un conteo esperado, o cualquier expectativa enumerada, **estás inyectando una cifra heredada en el mecanismo diseñado para atraparlas.** Formula la compuerta como: "reporta el output literal de `git status`; DETENTE si aparece algo que este encargo no explica" — y deja que el titular decida, en vez de pre-declarar tú qué es legítimo.
- ⚠️ **Un subconjunto citado en un traspaso anterior no es el inventario del conjunto.** `docs/data/` tiene 6 archivos, no 3. El "3 JSON" de v08 se refería a los que `sincronizar_docs.sh` copia. Antes de citar un inventario, córrelo.
- ✅ **ANTES de correr cualquier script de sincronización, lee su contenido y verifica su DIRECCIÓN.** `sincronizar_docs.sh` copia **desde** `40_salidas/mapa_interactivo/web/data/` **hacia** `docs/data/`. Solo se corre **tras regenerar el 36**. Correrlo sin haber regenerado datos es inútil en el mejor caso y una regresión en el peor.
- 🔒 **`sincronizar_docs.sh` NO se corre en sesiones de front-end.** Esta sesión editó `docs/assets/` y no tocó ningún dato: correrlo habría sido incorrecto.
- 🔒 Los archivos de `40_salidas/mapa_interactivo/web/data/` y sus copias en `docs/data/` **están versionados a propósito** (son agregados sin identificador individual). No los destrackees "limpiando".
- 🔒 `00_run_all.R`, `31`, `32`, `33`, `33b`, `10_*`, maestro, y `34/35/36`: intocables sin instrucción explícita. Todos auditados. **No se tocan hace tres sesiones.**
- 🔒 **`PAL_SLEP['Costa Central']` (`#0D2E52`) es la codificación de dependencia en el mapa.** El chrome ahora converge a ese mismo azul (`COLOR_INSTITUCIONAL`, `--azul-institucional`), pero **son cosas distintas**: si alguna vez cambia la paleta de dependencias, `PAL_SLEP` cambia y el chrome NO necesariamente.
- 🔒 **`[hidden] { display: none !important; }` en `estilo.css` es estructural, no cosmético.** Sin esa regla, `#f-ee-sel` y `#f-nivel-wrap` se pintan vacíos. No la borres "limpiando el reset".
- 🔒 Exclusiones de **alcance** v1 (territorio insular, parvularia JUNJI/Integra): no son defectos. Tienen archivo de decisión propio.
- 🔒 **El backlog jamás se renumera, reescribe ni resume.** Un error se corrige con una entrada nueva.
- ✅ **ANTES de incorporar este traspaso al backlog:** el trabajo de la sesión 9 entra como **cambios 26, 27 y 28** (ver §14). El cambio 25 (push de la sesión 8) ya fue incorporado en el `backlog_acumulativo.md` commiteado en `9f39df5`.
- 🔒 Máximo 2 agentes en Claude Code.

---

## 12. Fragmentos de código de referencia

**La forma correcta de una compuerta de estado (refinada en esta sesión — NO enumera, reporta):**
```bash
# INCORRECTO (error #1 de la sesion 9): la lista blanca es una cifra heredada.
#   "DETENTE si aparece un archivo que no sea uno de: A, B, C"
#   -> el asistente define que es legitimo, desde su expectativa. La compuerta
#      se contamina con el mismo patron que existe para atrapar.
#
# CORRECTO: la compuerta REPORTA y DETIENE ante lo que el encargo no explica.
#   "Corre y reporta el output literal. DETENTE si aparece cualquier archivo
#    que este encargo no explique, y consulta antes de proceder."
#   -> el titular decide. El asistente no pre-declara nada.

git status --short --branch                # que hay realmente
git log --oneline origin/main..main        # cuantos commits van (REPORTAR)
git log --oneline main..origin/main        # divergencia? (vacio = no)
git ls-files --others --exclude-standard   # untracked
git diff --stat                            # magnitud del cambio
```

**Verificación de la dirección de un script de sincronización (aprendizaje 4):**
```bash
# ANTES de correr cualquier script que mueva archivos, leerlo:
cat sincronizar_docs.sh
# Este copia DESDE 40_salidas/mapa_interactivo/web/data/ HACIA docs/data/.
# Solo se corre TRAS regenerar el 36. En una sesion de front-end (que edita
# docs/assets/ y no toca datos), correrlo es inutil o una regresion.
```

**El reset de `hidden` (estructural, no cosmético):**
```css
* { margin: 0; padding: 0; box-sizing: border-box; }
/* Restablece la semantica del atributo hidden frente a cualquier display de
   autor (un display:flex de clase, como .combobox-sel, lo anularia). */
[hidden] { display: none !important; }
```

**Zoom-to-fit con guarda y tope (la forma correcta en este proyecto):**
```js
const ZOOM_MAX_ENCUADRE = 14;      // un pin unico no salta a z19 (nivel calle)
const PAD_ENCUADRE_FILTRO = 0.12;

// en aplicarFiltros(), tras el bloque de cero-resultados:
if (activos && coincidentes.length) {   // n===0 -> NO mover la vista
  S.mapa.fitBounds(L.featureGroup(coincidentes).getBounds().pad(PAD_ENCUADRE_FILTRO),
                   { maxZoom: ZOOM_MAX_ENCUADRE, animate: true });
}

// en limpiarFiltros(), FUERA de aplicarFiltros() y despues de llamarla:
S.mapa.fitBounds(S.boundsDefecto, { animate: true });  // limpiar != filtrar
```

---

## 13. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 10 (Censo 2024)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior y el escáner más reciente. El foco de esta sesión es el diagnóstico del Censo 2024.

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar; solo verificar que esté al día): `POLITICA_PROYECTO.md` (v5.2), `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (v7).
2. *Opcionales según el foco real*:
   - **Si la sesión aborda el Censo 2024 (lo recomendado):** `diccionario_variables_censo2024.xlsx` y `Ficha_metodologica_CPV2024.pdf` (del proyecto padre, fuera de este repo), más el encargo ya escrito en `50_documentacion/andamios/`. **Adjuntarlos: sin ellos la sesión no puede arrancar.**
   - `backlog_acumulativo.md` si la sesión va a incorporar los cambios 26–28 (archivo grande; adjuntarlo solo si se va a editar).
   - `CLAUDE.md` si la sesión correrá en Claude Code.
3. *Específicos de la sesión (SÍ adjuntar)*: este traspaso (`traspaso_cierre_v09.md`); el escáner `estructura_actual.md` **re-ejecutado al abrir**.

**Nota final:** el remoto quedó sincronizado hasta **`b7d9a8a`**. El cierre de esta sesión (traspaso v09, `ESTADO.md`, snapshot del escáner) queda **sin commitear**: es la primera acción mecánica de la sesión 10. Verificar al abrir con `git status --short --branch` y `git log --oneline origin/main..main`, **no asumirlo desde este párrafo**.

---

## 14. Delta del backlog acumulativo

**Estado del backlog al cierre:** el `backlog_acumulativo.md` commiteado en `9f39df5` ya incorpora el **cambio 25** (push de la sesión 8), tal como el §14 de v08 lo dejó declarado. La serie correlativa llega al 25 sin saltos.

**Entradas pendientes de incorporar: 3.** El trabajo de la sesión 9 son **tres solicitudes distinguibles del titular** (nota metodológica: una solicitud distinguible, no las acciones técnicas que la implementan):

| # | Cambio | Categoría temática |
|---|---|---|
| **26** | Re-chequeo visual del mapa interactivo y corrección de los dos defectos hallados (chip vacío del combobox; zoom-to-fit al filtrar). Cierra el pendiente #1 abierto desde v07 | *Corrección de front-end* |
| **27** | Unificación de la identidad cromática: el azul institucional `#0D2E52` reemplaza al ciruela `#4A2746` como único color principal del producto. Corrige de paso un incumplimiento WCAG preexistente en el anillo de foco | *Identidad visual* |
| **28** | Publicación en GitHub Pages: tres commits separados por tipo conceptual y push a `origin/main` (`78d633b..b7d9a8a`) | *Gobernanza y versionado* |

Fila del resumen estadístico a agregar: `9 | v09 | 3 (26–28) | — | Re-chequeo visual, cromática y publicación`.

**Refinamiento de taxonomía a evaluar:** el cambio 27 no cae limpiamente en ninguna de las 13 categorías vigentes (*Corrección de front-end* no lo describe: no se corrigió un defecto, se cambió una decisión de identidad). **Propuesta: nueva categoría *Identidad visual***, que también absorbería retroactivamente decisiones de paleta de sesiones anteriores si se quisiera reclasificar (aunque el backlog no se reescribe: la categoría nueva aplica desde el 27 en adelante). **Recomendación: crearla.** Si el titular prefiere no ampliar la taxonomía, el 27 cae en *Corrección de front-end* con una nota, pero la clasificación sería imprecisa.
