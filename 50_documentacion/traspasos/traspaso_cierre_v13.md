# Traspaso de cierre — sesión 13

## 1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `slep_georreferenciacion` |
| Versión | v13 · sucede a `traspaso_cierre_v12.md` |
| Fecha | 2026-07-30 |
| Tipo de sesión | CONTINUATION |
| Rama / remoto | `main` · `tomgc/slep_territorio_costa_central` (privado) |
| Entorno | R 4.5.2 · Positron · arquitectura dual-agente (Claude conversacional + Claude Code) |
| Protocolo usado | `POLITICA_PROYECTO.md` v5.2 · `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v14 (knowledge base). **En disco hay una v15 sin commitear, ajena a esta sesión: ver §9 y pendiente R.** |

**Foco:** cerrar la deuda en vuelo de la sesión 12 (hachurado) y levantar el eje nuevo
de educación parvularia desde cero hasta capa publicada.

**Archivos principales modificados:** `30_procesamiento/39_construir_capa_parvularia.R`
(nuevo), `docs/data/parvularia_r5.geojson` (nuevo), `docs/assets/mapa.js`,
`docs/assets/estilo.css`, `docs/index.html`, `CLAUDE.md`, y cinco andamios en
`50_documentacion/andamios/`.

---

## 2. Resumen ejecutivo

La sesión abrió reconciliando el working tree contra lo que el traspaso v12 declaraba,
porque un encargo de hachurado había quedado corriendo al cerrar. El hachurado resultó
completo y correcto (912 / 266 / 38 = 1.216 unidades zonales, reparto idéntico al recuento
en R sobre el GeoJSON), y su auditoría destapó que la captura que respaldaba el juicio
visual a z10 se había tomado con un alfa `.58` que nunca llegó a archivo, mientras el
vigente es `.60`: quedó anotado en el log en vez de dejarse pasar. El pendiente L se cerró
sin acción, porque el código ya había sido renombrado con mejor criterio que el que yo
propuse. **El pendiente G, arrastrado como "alta prioridad" durante cuatro traspasos, no
existía:** el `backlog_acumulativo.md` de `HEAD` y el de `9f39df5` son el mismo archivo
byte a byte, ambos hasta la entrada 24, y la afirmación de que el repo llegaba al 25 nació
en v09 y se copió sin verificarse nunca. El grueso de la sesión fue el pendiente N: se
midió el universo parvulario regional (1.345 unidades, 65.771 niños en 2025), se comprobó
que JUNJI, Integra y VTF son separables con dos columnas del propio archivo, que la
georreferencia viene dentro de la matrícula y coincide con el directorio oficial al metro
en el 100 % de los casos comparables, y con eso se decidió incorporarlo como capa adicional
del mapa vigente (no como producto propio) y se construyó: script 39, GeoJSON de 1.329
features y toggle con carga diferida, apagado por defecto. Quedan abiertos el pendiente D
(`run_all()` en máquina limpia), la reconstrucción real del backlog desde la entrada 25, y
la nota metodológica.

---

## 3. Estado al cierre

**Qué funciona.** El pipeline del afiche y del mapa regional, sin cambios respecto de v12.
Las dos capas del Censo 2024 (densidad de manzana y asistencia zonal) con su hachurado de
"denominador insuficiente" ya distinguible del vacío. La capa nueva de parvularia, con su
toggle independiente. Última ejecución exitosa verificada: relectura del GeoJSON escrito
desde disco, 1.329 features y suma de `matricula_total` = 65.258, cuadratura 0 contra el
conteo directo de filas (fuente: reporte de Claude Code de esta sesión).

**Qué no funciona.** `run_all()` sin argumentos sigue corriendo los pasos del Censo, que
dependen de 309 MB de parquet gitignored: en máquina limpia falla aunque el afiche esté
perfecto (pendiente D, sin cambio desde v12). El script 39 **no está registrado** en
`00_run_all.R`, que es un archivo bloqueado y cuyo tratamiento pertenece a esa misma
decisión.

**Delta respecto de v12.** Tres pendientes cerrados (K, K', L), uno refutado (G), uno
registrado sin corrección (M), y el eje N pasó de "a planificar" a capa construida y
publicada. Se agregó un script al pipeline (39), un archivo a `docs/data/` y un toggle al
front-end. El SVG exportado sigue sin incluir capas del Censo ni de parvularia.

---

## 4. Registro detallado de cambios

### 4.1 Hachurado de "denominador insuficiente" (cierre del pendiente K)

- **Archivos:** `docs/assets/mapa.js`, `docs/assets/estilo.css`.
- **Categoría temática:** identidad visual / legibilidad del dato.
- **Qué:** el gris de denominador insuficiente se confundía con el fondo entre polígonos.
  Se reemplazó por una trama diagonal implementada como `CanvasPattern` asignado a
  `fillColor`, aprovechando que el renderer de Leaflet lo traslada tal cual a
  `ctx.fillStyle`. La leyenda muestra la trama real, no un cuadrito de color.
- **Por qué:** la distinción tenía que ser de **textura contra liso**, no de tono contra
  tono, porque el problema era precisamente que dos tonos cercanos colapsaban contra el
  papel.
- **Cómo se verificó:** reparto sobre la capa montada 912 rampa / 266 trama / 38 contorno
  = 1.216, idéntico al recuento en R sobre el GeoJSON. Sobrecosto de `_redraw()` medido:
  mediana 0,60 ms con trama contra 0,50 ms sin ella, 40 repeticiones a z10.
- **Tensión resuelta:** la trama a `.82` de alfa le ganaba a la rampa azul y rompía "la
  coropleta es fondo". Se bajó a `.60`, que mantiene la trama inequívoca sin quitarle
  protagonismo a los pines.
- **Registro de ejecución detallado:** `50_documentacion/andamios/log_correccion_hachurado_zonal.md`.

### 4.2 Anotación de precisión sobre el alfa de la trama (pendiente K')

- **Archivo:** `50_documentacion/andamios/log_correccion_hachurado_zonal.md`.
- **Categoría temática:** integridad del registro.
- **Qué:** el valor vigente en los dos archivos es `.60`
  (`HACHURA.tinta = 'rgba(96,89,74,.60)'` en `mapa.js`, mismo valor en `estilo.css`), y el
  log ya lo declaraba correctamente. Lo que sí se corrigió es que la captura a z10 que
  sostenía el juicio "la trama ya no domina la vista" se tomó con `.58`, un valor probado
  en vivo desde la consola que nunca llegó a archivo.
- **Por qué:** dos puntos de alfa no se distinguen a ojo, pero la afirmación se apoyaba en
  un artefacto que no existe en disco, y eso es exactamente la clase de premisa que este
  proyecto viene arrastrando.
- **Cómo se verificó:** `grep` sobre los dos archivos, corregido tras notar que el alfa se
  escribe sin cero inicial (`.60`) y que `0\.6` no lo matchea.

### 4.3 Cierre del pendiente L sin acción

- **Archivos:** ninguno.
- **Categoría temática:** deuda técnica cerrada.
- **Qué:** el renombre pedido (`GRIS_CENSO_CERO` → `GRIS_DENSIDAD_CERO`,
  `GRIS_CENSO_RUIDOSO` → `GRIS_ASISTENCIA_NO_FIABLE`) no aplicaba: el código ya se había
  renombrado en el encargo del hachurado a `COLOR_SIN_POBLACION`, `OPACIDAD_SIN_POBLACION`
  y `HACHURA` + `crearPatronHachura`, y `GRIS_CENSO_RUIDOSO` había desaparecido absorbido
  por la trama.
- **Por qué no se aplicó el mapeo propuesto:** los nombres vigentes describen **qué es** la
  cosa; los que yo propuse describían **de qué color** es. El criterio del código es mejor
  y se conserva.

### 4.4 Refutación del pendiente G (backlog)

- **Archivos:** ninguno (lectura pura).
- **Categoría temática:** deuda heredada / integridad documental.
- **Qué:** `git show 9f39df5:50_documentacion/activa/backlog_acumulativo.md` y la copia en
  `HEAD` son **idénticos byte a byte**: mismo md5, 432 líneas ambos, entrada numerada
  máxima 24 en ambos, serie 1–24 completa y sin saltos.
- **Por qué importa:** v09 afirmó que el repo llegaba al 25; v10, v11 y v12 lo copiaron.
  Cuatro traspasos propagaron una premisa que un `diff` refutaba.
- **Cómo se verificó:** `diff` con salida vacía y exit 0, más md5 de ambos.
- **Efecto colateral:** la afirmación de "9+ entradas sin incorporar (26–34)" tampoco está
  verificada. Si la serie nunca pasó de 24, esas entradas existen solo como texto dentro de
  los traspasos y **reconstruirlas es redacción, no reconciliación de archivos**. Ver
  pendiente P y §11.

### 4.5 Diagnóstico del universo parvulario regional (pendiente N, fase 0)

- **Archivos:** `50_documentacion/andamios/diagnostico_parvularia_r5.R`,
  `50_documentacion/andamios/log_diagnostico_parvularia_r5.md`.
- **Categoría temática:** diagnóstico y exploración de datos.
- **Qué:** medición completa del universo de educación parvularia de la Región de
  Valparaíso sobre la matrícula 2025 ya presente en el repositorio, sin descargar nada.
- **Cifras principales** (todas de conteo programático; fuente: el log citado):
  1.345 unidades y 65.771 niños en R5; 1.337 unidades y 65.435 niños continentales;
  234 unidades y 13.704 niños en el área de monitoreo; 99,40 % de unidades y 99,73 % de
  niños georreferenciables sin fuentes nuevas.
- **Cómo se verificó:** ver §6 (dos bugs propios detectados y corregidos durante la
  medición) y §7 (compuerta de gobernanza sobre las coordenadas).
- **Registro de ejecución detallado:** `50_documentacion/andamios/log_diagnostico_parvularia_r5.md`.

### 4.6 Capa de parvularia (pendiente N, fase 1, hito A)

- **Archivos:** `30_procesamiento/39_construir_capa_parvularia.R` (nuevo),
  `docs/data/parvularia_r5.geojson` (nuevo).
- **Categoría temática:** construcción de capa.
- **Qué:** una feature por unidad educativa continental con coordenada válida, 12 campos,
  con desglose de matrícula por nivel y marca de área de monitoreo.
- **Cómo se verificó:** relectura del GeoJSON escrito **desde disco** con
  `jsonlite::fromJSON(simplifyVector = FALSE)`, comprobando 1.329 features, `id_estab` y
  `cod_comuna` como `character` en todas ellas, 12 campos idénticos por feature, 0
  coordenadas vacías y 0 campos `NULL`/`{}`. Auditoría desde el consumidor JS, no desde el
  productor R.
- **Guardias instaladas:** cinco. La principal aborta si alguna unidad queda sin coordenada
  **y** con matrícula mayor que cero; las ocho exclusiones conocidas viven en una lista
  explícita (`UNIDADES_SIN_GEO_CONOCIDAS`) con su motivo, no en una tolerancia silenciosa.
  Ninguna se disparó.
- **Dependencias afectadas:** `00_run_all.R` **debería** registrar el paso 39 y no lo hace;
  es archivo bloqueado y el registro pertenece a la decisión del pendiente D.

### 4.7 Toggle de parvularia en el front-end (pendiente N, fase 1, hito B)

- **Archivos:** `docs/assets/mapa.js`, `docs/assets/estilo.css`, `docs/index.html`.
- **Categoría temática:** front-end / identidad visual.
- **Qué:** toggle propio, independiente de las capas del Censo, apagado por defecto, con
  carga diferida y cacheada; pane `parvularia` en zIndex 390 (bajo los pines en 400);
  marcador de anillo de radio menor que el pin vigente; popup que omite la línea de nivel
  cuando el valor es nulo o cero; entrada propia en la leyenda con el símbolo real.
- **Cómo se verificó:** `git diff --numstat` da 158/0, 12/0 y 13/0 en los tres archivos:
  **cero líneas eliminadas, todo adición**, lo que confirma que ni la barra de filtros ni
  la máscara ni el sidebar ni la exportación se movieron.
- **Tensión resuelta:** el primer marcador usaba relleno translúcido del mismo color; a z14
  el agujero del anillo medía ~1,5 px y volvía a leerse como disco pálido. Se invirtió a
  centro blanco tras mirarlo renderizado, no tras razonarlo.

### 4.8 Oscurecimiento del terracota de JUNJI

- **Archivo:** `docs/assets/mapa.js` (una línea).
- **Categoría temática:** identidad visual.
- **Qué:** `#C2552F` → `#9E3F1E` en la constante de color de JUNJI.
- **Por qué:** el par original se separaba del ocre del particular subvencionado por tono
  (ΔE2000 = 20,3) pero casi nada por valor (ΔL\* = 2,9). Este proyecto tiene dos afiches A0
  impresos y una exportación SVG en el alcance: un par que solo separa por tono es frágil
  en escala de grises y para daltonismo rojo-verde. El nuevo sube a ΔE2000 = 23,1 y
  ΔL\* = 13,2.
- **Cómo se verificó:** `grep -rn "C2552F" docs/ -i` con exit 1 (cero ocurrencias);
  `git diff --numstat` = `1 1`; leyenda computando `rgb(158,63,30)`; 295 marcadores JUNJI
  (121 Adm. Directa + 174 VTF) con el valor nuevo e INTEGRA intacto.
- **Nota:** `estilo.css` no requirió cambio porque la leyenda toma el color inline desde JS
  (`style="border-color:${g.color}"`) y hereda el valor nuevo.

---

## 5. Backlog acumulativo

**Archivo canónico:** `50_documentacion/activa/backlog_acumulativo.md`.

**Estado real medido en esta sesión:** entrada numerada máxima **24**, en `HEAD` y en
`9f39df5` por igual, archivos idénticos byte a byte (§4.4).

**Esta sesión NO incorporó entradas nuevas, y esa omisión es deliberada.** La numeración
es correlativa, global y permanente, y jamás se renumera. Si los cambios de las sesiones
9 a 12 nunca se incorporaron, escribir ahora los de la sesión 13 como entrada 25 clausura
para siempre la posibilidad de ubicar los anteriores en su lugar cronológico. La decisión
de cómo resolverlo pertenece al titular y está planteada en §11 (pendiente P), con
recomendación.

**Delta del backlog respecto de v12:** ninguno en el archivo. El cambio real es de
diagnóstico: se refutó la premisa de que existía una divergencia entre disco y repo.

---

## 6. Bugs de la sesión

| # | Síntoma observable | Causa raíz | Solución | Verificación | Patrón aprendido | Estado |
|---|---|---|---|---|---|---|
| 1 | Cobertura de coordenadas 0 % en **las dos** fuentes a la vez | Las dos fuentes usan separador decimal distinto (matrícula punto, directorio coma). Forzar un `dec=` único devuelve la otra como `character` en silencio, y toda comparación numérica da falso | Lectura de ambas coordenadas como texto y normalización por una función única (`num_coord()`) | Rangos plausibles tras el fix; longitud −109,44 identificada como Isla de Pascua | Un 0 % simultáneo en dos fuentes independientes es implausible por construcción: la implausibilidad es la alarma, porque el código no avisó | Resuelto |
| 2 | Expresiones posteriores de un `summarise` indexando un escalar | Se redefinió `ninos` antes de usarlo para indexar, y `dplyr` evalúa en orden dentro del verbo | Reordenar la definición | Recuento contra el conteo directo | No reutilizar el nombre de una variable dentro del mismo verbo en que se la redefine | Resuelto |
| 3 | Los 1.329 marcadores de parvularia caían en `overlayPane` (400), mezclados con los pines; el zIndex 390 del diseño no se cumplía | Las capas que devuelve `pointToLayer` **no heredan** `pane` ni `renderer` del `L.geoJSON` que las contiene | Pasar `pane` y `renderer` explícitamente en las opciones de cada `circleMarker` | `getPane('parvularia').children.length` pasó de 0 a 1 | **El síntoma es invisible en pantalla:** la capa se dibuja bien y solo el orden z está mal, y el orden z casi nunca se nota. Se detecta contando hijos del pane, no mirando. Documentado como patrón en `log_capa_parvularia.md` §5 | Resuelto |
| 4 | El recorte de la comparación de color salía desalineado | Leaflet reposiciona el canvas al hacer zoom y al hacer resize | Tomar el offset real del canvas antes de recortar | Comparación a 8× sobre píxeles ya rasterizados, no redibujados | Al medir sobre un render, medir sobre los píxeles efectivamente rasterizados y no sobre coordenadas asumidas | Resuelto |

---

## 7. Aprendizajes y restricciones descubiertas

1. **Una coordenada en un archivo de nivel persona es culpable hasta que se demuestre lo
   contrario.** Antes de usar `LATITUD`/`LONGITUD` hubo que probar que no eran domicilio
   del niño: conteo de pares distintos por llave de establecimiento, 1.345 llaves con
   exactamente 1 par, máximo 1, cero nulos. *Si se viola:* se publica el domicilio de
   menores de edad. La compuerta es barata y va antes, no después.
2. **Verificar un renombre contra el código, no contra el pendiente que lo pidió.** El
   pendiente L describía un estado del código que ya no era cierto. El encargo pudo haber
   "renombrado" constantes inexistentes o, peor, revertido un criterio mejor.
3. **Una premisa fáctica dentro de un encargo tiene el mismo estatus que una cifra
   publicada.** Los códigos de comuna del encargo de la capa estaban mal (§15, error 1) y
   solo los salvó que el agente los contrastara contra el dato.
4. **El comentario que justifica una constante caduca con la constante.** Al cambiar el
   hex del terracota, el comentario que explicaba por qué ese valor quedaba mintiendo. Se
   actualizó en la misma línea.
5. **Los códigos de programa de un archivo multi-origen no son la variable de nivel.**
   `COD_ENSE2_M`, `COD_PROG_J` y `COD_MODAL_I` están poblados en exclusiva por origen; la
   variable armonizada de los tres es `NIVEL2`. Buscar la columna correcta es medición, no
   inferencia por nombre.

---

## 8. Decisiones de diseño

### 8.1 Parvularia entra como capa adicional, no como producto propio

- **Alternativas consideradas:** (a) producto propio, un mapa parvulario aparte;
  (b) capa con toggle en el mapa vigente, apagada por defecto; (c) filtro de nivel
  educativo sobre un universo unificado.
- **Decisión:** (b), con (c) declarado como destino sin fecha.
- **Justificación:** (a) duplica máscara, cascada de filtros, exportación y atribución para
  ganar solo separación visual, que un toggle ya entrega. (c) es la más limpia
  conceptualmente y exige migrar la llave del front-end de `RBD` a `ID_ESTAB`; no debe
  bloquear la publicación.
- **Dato que acota la decisión:** el universo parvulario son 1.345 unidades contra los
  1.251 establecimientos que el mapa ya publica, es decir, más que duplica los pines si se
  muestran juntos; de ahí el "apagado por defecto" y el marcador secundario.
- **Hallazgo que abarata (c):** `ID_ESTAB == RBD` en **938 de 938** unidades de origen
  MINEDUC, comparando valores y no conteos. Unificar la llave del front-end es un renombre,
  no una tabla de equivalencias.

### 8.2 Las unidades sin coordenada se excluyen por lista explícita, no por tolerancia

- **Alternativas:** filtrar con un umbral silencioso, o declarar las ocho una a una.
- **Decisión:** lista explícita con motivo por unidad, más una guardia que aborta si
  aparece una novena con matrícula mayor que cero.
- **Justificación:** este proyecto ya rechazó en v11 la figura del test calibrado para
  tolerar el error conocido. Una tolerancia que absorbe ocho casos absorbería también el
  noveno sin avisar.

### 8.3 El terracota se oscurece para separar por luminancia, no solo por tono

- Ver §4.8. **Implicancia:** cualquier color futuro del proyecto que deba coexistir con la
  banda cálida (ocre del subvencionado, CAD) tiene que declarar su ΔL\*, no solo su ΔE2000,
  porque el proyecto imprime y exporta a SVG.

---

## 9. Constantes y parámetros

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| Color JUNJI | `#C2552F` | `#9E3F1E` | `docs/assets/mapa.js` | Separación por luminancia contra el ocre (§4.8) |
| Color INTEGRA | — | `#A32C58` | `docs/assets/mapa.js` | Tono nuevo, aprobado esta sesión |
| `DENOM_MINIMO` | 20 | 20 | script 38 | Sin cambio |
| `HACHURA.tinta` alfa | — | `.60` | `mapa.js`, `estilo.css` | Vigente y verificado (§4.2) |

Fuente canónica de las vigentes: las constantes de color y de capa viven declaradas al
inicio del bloque correspondiente de `docs/assets/mapa.js`; las del pipeline, en el script
que las declara.

**Constantes decididas y aún no aterrizadas:** ninguna.

**Ajuste propuesto y no aplicado:** `#8F3A1C` como variante más agresiva del terracota
(ΔE2000 24,4 · ΔL\* 16,7). Se descartó por ahora: `#9E3F1E` ya resuelve el caso.

---

## 10. Arquitectura de archivos

Escáner de referencia: `estructura_actual.md`, ejecutado al abrir la sesión.
**Debe re-ejecutarse al cerrar**, porque la sesión agregó un script, un GeoJSON y cinco
andamios.

Cambios estructurales: `30_procesamiento/` gana el script `39_construir_capa_parvularia.R`
(respeta la numeración por sub-etapa); `docs/data/` gana `parvularia_r5.geojson`;
`50_documentacion/andamios/` gana cinco archivos entre encargos y logs. Ninguna carpeta
nueva, ninguna desviación respecto de la estructura canónica de la política.

**Registro de ejecución detallado:** `50_documentacion/andamios/log_correccion_hachurado_zonal.md`,
`50_documentacion/andamios/log_diagnostico_parvularia_r5.md`,
`50_documentacion/andamios/log_capa_parvularia.md`.

---

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

| # | Pendiente | Tipo | Impacto | Dependencias | Complejidad | Criterio de éxito |
|---|---|---|---|---|---|---|
| **D** | `run_all()` sin argumentos corre los pasos del Censo, que dependen de 309 MB de parquet gitignored. Falla en máquina limpia. Arrastra además el registro del script 39 | Bloqueante | Un tercero que clone el repo no puede reproducir nada | Ninguna | Media | Clon limpio simulado que corre el afiche completo sin parquet y salta los pasos de Censo con mensaje accionable |
| **P** | Reconstrucción del backlog desde la entrada 25. La serie está completa hasta 24; los cambios de las sesiones 9 a 13 nunca se incorporaron | Deuda heredada | El backlog es la memoria de largo plazo del proyecto y lleva cinco sesiones sin crecer | Requiere `traspaso_cierre_v09.md`, `v10.md` y `v11.md`, que no estuvieron en esta sesión | Media | Serie 25+ escrita en orden cronológico, marcada como reconstrucción, sin renumerar nada anterior |
| **H** | La nota metodológica pública debe declarar el umbral de denominador (22–29 % de unidades sin color) y ahora también las 8 unidades parvularias excluidas y las 4 con coordenada errónea | Documentación | El hachurado hizo visualmente prominente algo que no está explicado | F (para la cifra de cobertura) | Baja | Nota publicada que un lector externo puede contrastar contra el mapa |
| **F** | Cobertura POBLACIONAL de la unión zonal nunca medida (solo área) | Deuda técnica | Condiciona el texto de H | Ninguna | Baja | `n_edad_*` sumado contra el total comunal INE |
| **E** | La unión zonal cubre 95,3–99,8 % del área comunal; el resto son slivers | Mejora visual | Menor | Ninguna | Baja | Decisión tomada y aplicada o declarada |
| **Q** | Serie histórica de parvularia 2011–2025 (fase 2 de N) | Funcionalidad | Alto valor, sin consumidor todavía | La capa 2025 ya publicada | Media | Serie por unidad con la reserva de panel no balanceado declarada |
| **R** | `SETTINGS_Y_PROMPTS_OPERACIONALES.md` en disco trae un cambio sin commitear ajeno a esta sesión (v14 → v15, `PAT-01..PAT-13`, catálogo v2 → v3). La fila `gatillo_observable` quedó rezagada citando el catálogo v2 | Documentación | La knowledge base y el disco divergen | Ninguna | Baja | Decidido: entra, se descarta o se sincroniza con la knowledge base |
| **S** | Unificar la llave del front-end de `RBD` a `ID_ESTAB` (opción 3 de §8.1) | Deuda técnica | Habilita el filtro de nivel educativo sobre universo unificado | Medido: es un renombre (938/938) | Media | Front-end operando con `ID_ESTAB` sin regresión en filtros |
| **C** | `TOL_SOLAPE_HA = 0.5` fijado después de medir 0,089 ha | Deuda técnica | Bajo | Ninguna | Baja | Recalibrado sobre la distribución o eliminado |
| **I** | Concón pierde 9,76 % de sus manzanas por simplificación (todas con 0 niños) | Documentación | Bajo | H | Baja | Mencionado en la nota |
| **J** | El SVG exportado no incluye las capas del Censo ni la de parvularia | Decisión de alcance | Bajo | Ninguna | Media | Decidido explícitamente |
| **M** | Commit `0159dfc` es un `git add .` disfrazado | Registro | Ninguno | — | — | Cerrado, solo declarado |

### 11.2 Evaluación de deuda técnica

**Zona frágil principal:** el orquestador. `00_run_all.R` está bloqueado, no registra el
script 39 y ya no representa el pipeline real. Cada capa nueva agranda la brecha entre lo
que el repositorio contiene y lo que el orquestador sabe correr. El pendiente D dejó de ser
"molesto para un tercero" y pasó a ser deuda estructural.

**Segunda zona:** el front-end tiene ahora tres familias de capas (pines, Censo,
parvularia) con tres patrones de carga y tres criterios de color, y `mapa.js` creció 158
líneas en una sola sesión sin refactor.

**Oportunidad:** el hallazgo `ID_ESTAB == RBD` (938/938) hace barato un cambio que parecía
caro. Conviene tomarlo antes de que el front-end crezca más.

### 11.3 Auditoría de cierre (POLITICA 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Toda cifra publicada esta sesión proviene de un conteo programático? | Sí |
| ¿Se auditaron los artefactos R→JS desde el consumidor? | Sí (§4.6) |
| ¿Quedó microdato de personas persistido, aunque sea temporal? | No |
| ¿Los commits están separados por tipo conceptual? | Sí, 10 commits |
| ¿Se usó `git add .` o `--force`? | No |
| ¿El escáner se re-ejecutó al cierre? | **No** → se agrega como primera acción de la sesión 14 |
| ¿El backlog se actualizó? | **No**, deliberadamente → pendiente P |
| ¿Quedó algún archivo sin commitear? | Sí, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` → pendiente R |

### 11.4 Ruta sugerida para la sesión 14

1. **Pendiente D.** Es el único bloqueante y ahora arrastra el registro del script 39.
   *Criterio de éxito:* clon limpio simulado que corre el afiche sin parquet.
2. **Pendiente P**, con los traspasos v09–v11 adjuntos. *Criterio:* serie 25+ escrita y
   marcada como reconstrucción.
3. **Pendiente F**, medición de una corrida, cuyo resultado condiciona H.
4. **Pendiente H**, con la cifra de F ya en mano.

**Diferir:** Q (serie histórica de parvularia, sin consumidor todavía), S (unificación de
llave, medida y barata pero no urgente), E, C, I, J.

---

## 12. Instrucciones específicas para la sesión 14

- ⚠️ **NO** escribir la entrada 25 del backlog sin haber decidido antes cómo se ubican
  cronológicamente los cambios de las sesiones 9 a 12. La numeración no se renumera.
- ⚠️ **NO** dar por buena ninguna afirmación heredada sobre el estado del backlog, del
  working tree o de una cifra sin recomputarla en la sesión. Cuatro traspasos consecutivos
  propagaron una divergencia inexistente.
- ⚠️ **NO** registrar el script 39 en `00_run_all.R` fuera de la decisión del pendiente D.
- ✅ **ANTES de** cualquier encargo, verificar que las premisas fácticas que declara
  (códigos de comuna, rutas, encodings, conteos) provengan de una lectura de esta sesión y
  lleven su marcador de fuente.
- ✅ **ANTES de** cerrar, re-ejecutar `00_escanear_proyecto.R`: esta sesión no lo hizo.
- 🔒 `00_run_all.R`, scripts `31`–`36`, `10_*`: intocables sin instrucción explícita.
- 🔒 Insulares 5104 y 5201: fuera de todas las capas publicadas.
- 🔒 Microdato de personas (`MRUN`) no entra al proyecto, ni siquiera como temporal.
- 🔒 `20_insumos/` sellado por `.gitignore` en tres reglas; los parquet y los CSV de
  matrícula no se commitean jamás.
- 🔒 El backlog no se renumera ni se reescribe retroactivamente.

---

## 13. Fragmentos de código de referencia

**Patrón nuevo 1 — una capa creada con `pointToLayer` no hereda su pane ni su renderer.**
El síntoma es invisible: la capa se dibuja bien y solo el orden z queda mal.

```js
// MAL: los circleMarker caen en overlayPane, no en el pane pedido
L.geoJSON(datos, {
  pane: 'parvularia',
  renderer: rendererParv,
  pointToLayer: (f, latlng) => L.circleMarker(latlng, { radius: r })
});

// BIEN: pane y renderer van en CADA marcador
L.geoJSON(datos, {
  pointToLayer: (f, latlng) => L.circleMarker(latlng, {
    radius: r,
    pane: 'parvularia',
    renderer: rendererParv
  })
});

// COMPROBACIÓN de una línea: debe ser 1, no 0
map.getPane('parvularia').children.length;
```

**Patrón nuevo 2 — normalizar coordenadas de fuentes con separador decimal distinto.**
Forzar un `dec=` único devuelve la otra fuente como `character` en silencio.

```r
num_coord <- \(x) as.numeric(gsub(",", ".", trimws(as.character(x)), fixed = TRUE))
```

Los patrones estables del proyecto viven en `CLAUDE.md` y no se re-copian aquí.

---

## 14. Reapertura

### Mensaje de apertura pre-armado

> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo
> (`POLITICA_PROYECTO.md` + `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge
> base del Project y se lee desde ahí.
>
> Deuda que arrastra esta sesión:
>
> 1. **Pendiente D (bloqueante).** `run_all()` sin argumentos corre los pasos del Censo,
>    que dependen de 309 MB de parquet gitignored: en máquina limpia falla. Arrastra además
>    el registro del script nuevo 39 (parvularia), que hoy no está en el orquestador.
> 2. **Pendiente P.** El backlog está completo hasta la entrada 24 y no crece desde la
>    sesión 8. La supuesta divergencia entre disco y repo se refutó en la sesión 13: son el
>    mismo archivo byte a byte. Reconstruir la serie 25+ es redacción a partir de los
>    traspasos v09 a v13, no reconciliación de archivos, y por eso van adjuntos.
> 3. **Pendiente R.** `SETTINGS_Y_PROMPTS_OPERACIONALES.md` en disco trae un cambio sin
>    commitear ajeno a la sesión 13 (v14 → v15). Hay que decidir si entra, se descarta o se
>    sincroniza con la knowledge base.
> 4. El escáner **no** se re-ejecutó al cerrar la sesión 13. El adjunto es el de la
>    apertura y no incluye el script 39, el GeoJSON de parvularia ni los cinco andamios
>    nuevos.
>
> **Foco propuesto:** pendiente D, y con él la decisión de cómo se agrupan los pasos del
> orquestador.

### Documentos para la próxima sesión

**1. Protocolo en knowledge base (NO se adjuntan; verificar que estén al día).**
`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.

**2. Opcionales según el foco real.**
`CLAUDE.md` si correrá Claude Code; `auditoria_codigo_proyecto_md_v1.md` si habrá auditoría
de cifras.

**3. Específicos de la sesión (SÍ se adjuntan).**
- `traspaso_cierre_v13.md` (este documento).
- `estructura_actual.md`, **re-ejecutado al abrir** (el de este cierre es anterior a los
  artefactos de la sesión 13).
- `50_documentacion/traspasos/traspaso_cierre_v09.md`, `v10.md` y `v11.md` — necesarios
  para el pendiente P y **no disponibles en la sesión 13**.
- `50_documentacion/activa/backlog_acumulativo.md` — la copia de disco sirve: se verificó
  idéntica a la del repo.
- `00_run_all.R` — es el archivo del pendiente D y está bloqueado, así que la sesión debe
  verlo antes de proponer nada.

**Nota final obligatoria.** El escáner cambió respecto de este cierre y debe adjuntarse
re-ejecutado. `mapa.js` creció 158 líneas y `CLAUDE.md` fue actualizado: si la sesión 14
toca front-end, adjuntar ambos en su versión vigente.

---

## 15. Errores del asistente

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Redacción del encargo de la capa de parvularia, §4.1 | Necesidad de marcar las cuatro comunas del área de monitoreo | Se declararon los códigos 5101, 5107, 5109 y 5801 como Viña, Concón, Puchuncaví y Quintero. 5101 es Valparaíso y 5801 es Quilpué; los correctos son 5103 y 5105. Con los códigos literales la capa habría marcado Valparaíso y Quilpué y excluido Concón y Puchuncaví | Marcador de fuente obligatorio en toda premisa fáctica de un encargo | Se escribieron de memoria, con los nombres correctos al lado, lo que dio apariencia de verificación | El propio encargo pedía "verifica los códigos contra el dato, no los asumas", y el agente los contrastó contra `COMUNAS_COSTA_CENTRAL` del script 37 | Afirmar estado sin contrastar contra el artefacto (9ª sesión del mismo patrón matriz) |
| 2 | Redacción del encargo de diagnóstico, §1 | Declaración de supuestos de lectura | Se afirmó que los CSV de MINEDUC vienen en `latin1`. Son UTF-8, y el propio pipeline ya los leía así en tres scripts | Igual que arriba | Generalización de un patrón de proveedor, no lectura del archivo | El §1 estaba marcado como "supuestos NO verificados" y el PASO 1 obligaba a comprobarlos | Igual que 1 |
| 3 | Ruta de sesión, turnos 2 a 8 | Herencia del traspaso v12 | Se planificó el pendiente G como alta prioridad y se ordenó trabajo alrededor de él durante seis turnos, cuando un `diff` lo refutaba | Toda cifra o estado comunicado lleva marcador de fuente; una figura heredada de un documento anterior no es fuente | Se trató una afirmación de v12 como estado verificado | El encargo del PASO 4 sí exigió el `diff` y ahí se cayó | Igual que 1, en la capa de gobernanza |
| 4 | Encargo de la capa de parvularia, §6 | Lista cerrada de tres commits | La lista no cubría los propios entregables del §7 (encargo y log de la fase 1). El agente tuvo que abrir un cuarto commit y pedir autorización | Un encargo no debe contradecirse entre secciones | Se escribió el §6 antes que el §7 y no se releyó el conjunto | Ninguna | Inconsistencia interna de artefacto propio |
| 5 | Instrucción de la compuerta de gobernanza | Reporte del agente detenido en el PASO 1 | Se emitió el bloque de la compuerta hacia un agente que estaba detenido y no lo recibió; hubo que reemitirlo un turno después | Ninguna regla canónica | Se asumió que el agente seguía en línea | Ninguna | Menor, de flujo |

**Lectura de conjunto.** Tres de los cinco errores son el mismo: una afirmación fáctica
emitida sin recomputarla, y en los tres casos lo que la atajó fue una gatecheck escrita
dentro del propio encargo, no el juicio del asistente. La conclusión operativa es que la
gatecheck adversarial funciona y debe seguir siendo obligatoria en todo encargo, **incluida
la verificación de las premisas que el propio encargo declara**, porque el encargo es hoy
la superficie con mayor tasa de error del sistema.
