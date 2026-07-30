# Encargo Claude Code — capa de educación parvularia R5 (pendiente N, fase 1)

**Decisión tomada:** opción 2. Parvularia entra como **capa adicional del mapa regional
vigente**, apagada por defecto, con carga diferida, y NO como producto propio.
**Versión:** v1 · **Rama:** `main` · **Proyecto:** `slep_georreferenciacion`

---

## 0. Qué decide este encargo y qué no

Construye el dato y el toggle. **No decide identidad visual:** los dos tonos nuevos que
hacen falta (JUNJI, Integra) se proponen y se reportan, no se fijan. **No toca
`00_run_all.R`:** el registro del script nuevo en el orquestador pertenece a la decisión
del pendiente D (grupos de pasos), que está abierta. Declara esa deuda en el log y sigue.

Toda cifra que reportes viene de un conteo programático de esta corrida. Ninguna de la
documentación, de un traspaso, del log de la fase 0 ni de tu memoria.

---

## 1. Estado real declarado (verificado en la fase 0, reverificable)

Estos hechos vienen de `50_documentacion/andamios/log_diagnostico_parvularia_r5.md`,
medido en la sesión anterior. Están declarados como verdaderos; si al tocarlos encuentras
otra cosa, la contradicción va primero en tu respuesta.

- Fuente: `20_insumos/historico_matricula/Matricula-Ed.-Parvularia-2025/` , un CSV,
  **UTF-8** (no `latin1`), separador `;`, 49 columnas, nivel persona.
- Identificador individual presente: `MRUN`. **Prohibido persistirlo o reproducirlo.**
- Llave de unidad: `ID_ESTAB`, poblada al 100 % en los tres orígenes. `character` siempre.
- `LATITUD`/`LONGITUD` son del **establecimiento** (compuerta pasada: 1 par por llave,
  cero nulos), con **punto** decimal. El directorio oficial usa **coma**: no mezcles
  lecturas, y no uses el directorio, que aportó 0 unidades exclusivas.
- `ORIGEN`: 1 MINEDUC · 2 JUNJI · 3 INTEGRA (partición limpia y excluyente).
- `TIPO_ESTAB`: 1 Escuela Municipal · 2 Part. Subvencionado · 3 Part. Pagado · 4 Escuela
  SLEP · 5 JUNJI Adm. Directa · 6 JUNJI VTF · 7 INTEGRA Adm. Directa · 8 INTEGRA CAD.
- Universo continental esperado: **1.337 unidades**, de las cuales **1.329 con coordenada
  válida** y 8 sin (7 de ellas INTEGRA Adm. Directa). Si tu conteo difiere, detente.

---

## 2. Restricciones no negociables

- **Scripts bloqueados:** `00_run_all.R`, `31`–`36`, `10_*`. No los edites.
- **Solo lectura sobre `20_insumos/`.** No muevas, conviertas ni escribas nada ahí.
- **Cero microdato persistido.** Agrega en memoria; ningún artefacto en disco puede tener
  una fila por persona ni un identificador individual, ni siquiera temporal.
- **R exclusivamente.** Pipe nativo `|>`, `dplyr >= 1.1` con `.by=` (nada de
  `group_by`/`ungroup`), `here::here()` en todas las rutas. Nada de Python.
- **Insulares (5104, 5201) fuera de la capa**, como en todas las capas publicadas.
- **Sin push.** Commits sí, separados por tipo conceptual (POLITICA 9.7), un `git add` por
  ruta explícita. Prohibido `git add .` y prohibido `--force`.

---

## 3. PASO 0 — dos mediciones que se piden aparte

Ninguna bloquea el resto; las dos van al log.

1. **¿`ID_ESTAB` coincide con `RBD` para `ORIGEN == 1`?** No basta con que los conteos
   empaten (ya se sabe que ambos dan 42.344 filas): compara los **valores**, como
   `character`. Reporta cuántas unidades de origen MINEDUC tienen `ID_ESTAB == RBD`,
   cuántas difieren, y un puñado de casos discrepantes por su patrón (largo, prefijo), sin
   reproducir datos de persona. Esta cifra decide, más adelante, si unificar la llave del
   front-end es un renombre o una tabla de equivalencias.
2. **Las 4 unidades continentales con coordenada fuera del bounding box.** Repórtalas por
   comuna declarada y por coordenada observada. Determina si la coordenada cae en otra
   región de Chile, en el mar, o en un valor centinela (ceros, misma coordenada repetida).
   Trátalas como sin georreferencia en la capa, pero di qué son.

---

## 4. Hito A — la capa de dato

Script nuevo: `30_procesamiento/39_construir_capa_parvularia.R`.
Salida: `docs/data/parvularia_r5.geojson`.

### 4.1 Agregación

Una feature por unidad educativa continental con coordenada válida. Campos:

| Campo | Contenido |
|---|---|
| `id_estab` | `ID_ESTAB`, `character` |
| `nombre` | `NOM_ESTAB` |
| `cod_comuna` | `COD_COM_ESTAB`, `character`, 4 caracteres |
| `comuna` | nombre de comuna |
| `origen` | 1 / 2 / 3 |
| `tipo_estab` | 1–8 |
| `tipo_glosa` | glosa del §1, texto |
| `matricula_total` | conteo de niños de la unidad en 2025 |
| `mat_sala_cuna`, `mat_medio`, `mat_transicion` | desglose por nivel |
| `en_area_monitoreo` | `TRUE` para 5101, 5107, 5109, 5801 (Viña, Concón, Puchuncaví, Quintero); verifica los códigos contra el dato, no los asumas |

**El desglose por nivel es una medición, no un supuesto.** Localiza en el esquema de 2025
la columna que expresa el nivel (candidatas: `COD_ENSE2_M`, `COD_PROG_J`, `COD_MODAL_I`, y
lo que la glosa del ER indique). **Cada origen puede codificar el nivel en una columna
distinta.** Antes de agregar, reporta la tabla cruda de valores distintos por origen y la
regla de mapeo que vas a usar hacia las tres categorías. Si un origen no permite el
desglose, ese origen va con `NA` en los tres campos y se declara: **no lo imputes ni lo
repartas.**

### 4.2 Reglas de integridad

- CRS **EPSG:4326**. Coordenada de la matrícula, con punto decimal, normalizada por una
  función única de lectura.
- `sum(matricula_total)` de la capa debe empatar con el conteo directo de filas
  continentales con coordenada válida. Compáralos y reporta la diferencia; si no es cero,
  detente.
- **Guardia permanente** en el script, al estilo de la del script 37: si alguna unidad
  queda sin coordenada **y** con matrícula mayor que cero, `stop()` con mensaje accionable
  que nombre cuántas son y cuántos niños representan. Las 8 conocidas se manejan por una
  lista explícita de exclusión declarada en el propio script, no por tolerancia silenciosa.
- **Verifica el artefacto, no el log.** Vuelve a leer el GeoJSON escrito desde disco y
  cuenta sobre él: número de features, número de campos, tipos (`id_estab` y `cod_comuna`
  como string, no número), cero coordenadas vacías. Este proyecto ya se quemó dos veces con
  `jsonlite` serializando `NULL` como `{}` y desempaquetando arreglos de un elemento como
  escalares: audita desde el consumidor JS, no desde el productor R.

---

## 5. Hito B — el toggle en el front-end

**Gate:** no empieces el Hito B si el panel adversarial del Hito A no está completo.

- Toggle propio, **independiente** de las capas del Censo (no es mutuamente excluyente con
  ellas), **apagado por defecto**, con carga diferida y cacheada en memoria, replicando el
  patrón ya probado en el Hito 4 de la sesión 12. Léelo de `docs/assets/mapa.js` y reúsalo;
  no inventes un mecanismo nuevo.
- **Pane propio `parvularia`, zIndex 390:** bajo los pines vigentes (400) y sobre frontera
  (370). Los pines del directorio siguen mandando.
- Marcador **visiblemente secundario**: círculo de radio menor que el pin vigente, forma
  distinta, de modo que a simple vista se distinga un jardín de un establecimiento escolar
  sin leer la leyenda. Renderer Canvas si el conteo lo justifica; mídelo antes de decidir.
- **Color:** para `TIPO_ESTAB` 1–4, **reutiliza las constantes de color que ya existen en
  `mapa.js`** para municipal / SLEP / subvencionado / pagado. Léelas del archivo, no las
  redefinas. Para JUNJI (5, 6) e INTEGRA (7, 8) hacen falta dos tonos nuevos:
  **propónlos y repórtalos con su hex y su justificación, pero NO los des por
  aprobados**; déjalos en una constante única y nombrada al inicio del bloque, fácil de
  cambiar en una línea. La identidad visual la decido yo.
- Popup: nombre, glosa del tipo, comuna, matrícula total y el desglose por nivel cuando
  exista. Si el desglose es `NA` para ese origen, el popup **omite la línea**; no muestra
  "NA" ni un cero.
- Leyenda: entrada propia para la capa, coherente con el tratamiento del hachurado ya
  hecho (la leyenda muestra el símbolo real, no un cuadrito genérico).
- **No toques** la barra de filtros horizontal, la máscara invertida, el sidebar, la
  atribución ni la exportación. Si algo de eso se mueve, es un defecto.

---

## 6. Commits

Tres commits conceptuales, en este orden, con `add` por ruta explícita y `git status
--short` después de cada uno:

1. Andamios de la fase 0 que siguen sin trackear:
   `50_documentacion/andamios/diagnostico_parvularia_r5.R`,
   `50_documentacion/andamios/encargo_claude_code_parvularia_diagnostico_v1.md`,
   `50_documentacion/andamios/log_diagnostico_parvularia_r5.md`.
2. El script y la capa: `30_procesamiento/39_construir_capa_parvularia.R`,
   `docs/data/parvularia_r5.geojson`.
3. El front-end: `docs/assets/mapa.js`, `docs/assets/estilo.css`, y `docs/index.html` solo
   si el toggle necesitó markup.

Antes del primer commit, compuerta de gobernanza: lista los archivos a subir y confirma
que ninguno es de datos de origen, que ninguno contiene identificadores individuales y que
`20_insumos/` sigue sellado por `.gitignore`.

---

## 7. Log y panel adversarial

Log en `50_documentacion/andamios/log_capa_parvularia.md`, con la estructura de la fase 0,
incluidas las secciones **"Lo que no medí"** y las cifras al lado del comando que las
produjo. Declara ahí la deuda con `00_run_all.R` (script 39 sin registrar, pendiente D).

Responde en el chat:

1. ¿`ID_ESTAB == RBD` en ORIGEN 1? Cuántas coinciden, cuántas no.
2. ¿Qué son las 4 unidades fuera del bounding box?
3. ¿Qué columna codifica el nivel en cada origen, y qué origen quedó sin desglose?
4. Features escritas y suma de `matricula_total`, contadas **releyendo el GeoJSON**.
5. ¿`id_estab` y `cod_comuna` llegan al JS como string? Cómo lo comprobaste.
6. ¿Se disparó la guardia? ¿Cuántas unidades excluidas y cuántos niños representan?
7. Los dos hex propuestos para JUNJI e INTEGRA, con su razón, declarados como propuesta.
8. ¿Se movió algo de la barra, la máscara, el sidebar o la exportación? `git diff --stat`.
9. ¿Persististe alguna fila de nivel persona, aunque fuera temporal?

**Gate final:** reporta lo que efectivamente hay y detente en cualquier cosa que este
encargo no explique. Una contradicción con el §1 es el hallazgo más importante del turno y
va primero.
