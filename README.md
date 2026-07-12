# slep_georreferenciacion

Capa cartográfica y de visualización territorial del **SLEP Costa Central**
(Servicio Local de Educación Pública que cubre Puchuncaví, Quintero, Concón y
Viña del Mar, Región de Valparaíso).

El repositorio produce **tres productos** a partir de un mismo pipeline en R:

| Producto | Qué es | Universo | Estado |
|---|---|---|---|
| **Variante 1** — afiche con inset | Afiche A0 plotter-ready: panel norte (Puchuncaví, Quintero, Concón) + inset de Viña del Mar a escala separada | 97 establecimientos del SLEP | Completo, en validación |
| **Variante 2** — afiche a escala única | Afiche A0 plotter-ready: panel continuo, las 4 comunas a la misma escala, pines in situ | 97 establecimientos del SLEP | Completo, en validación |
| **Variante 3** — mapa interactivo | Mapa web Leaflet publicado en GitHub Pages, con filtros, indicadores de matrícula y exportación | 1.268 establecimientos de la Región de Valparaíso (continental) | Publicado |

Los dos afiches tienen 97 pines, numeración N→S 1..97, fuentes incrustadas y son
aptos para plóter (A0, PDF 1.7, texto extraíble). El mapa interactivo cubre un
universo distinto y mucho más amplio: la explicación de por qué está en la
sección siguiente.

---

## Relación con `slep_estudio_oferta_demanda`

Este repositorio **no es un proyecto autónomo**, aunque nació como tal. La
historia importa para entender por qué conviven dos universos distintos (97 y
1.268 establecimientos educacionales) en un mismo repositorio:

- **Origen (sesiones 1 a 5):** el proyecto nació como un encargo acotado y
  autosuficiente, un afiche cartográfico institucional del territorio del SLEP
  Costa Central. Su universo era exactamente el del SLEP: 97 establecimientos
  educacionales en 4 comunas. Su propósito era de identidad institucional
  (mostrar el territorio del servicio), no analítico.

- **Absorción (sesión 6 en adelante):** con la construcción del mapa interactivo
  regional, el desarrollo dejó de ser un producto de identidad y pasó a ser una
  **herramienta de análisis**. El mapa excede deliberadamente el territorio del
  SLEP (cubre toda la región continental) porque la pregunta que responde ya no
  es "¿dónde están nuestros establecimientos?" sino "¿cómo se distribuye la
  oferta educativa en el territorio y su entorno?".

- **Situación actual:** `slep_georreferenciacion` es un **producto derivado** de
  `slep_estudio_oferta_demanda`. El estudio define el problema (oferta y demanda
  educativa en el territorio); este repositorio entrega la capa cartográfica que
  el estudio necesita. El desarrollo previo (el pipeline del afiche, el manejo de
  límites comunales, las convenciones de color y tipografía institucional) se
  aprovecha como recurso: no se rehizo, se reutilizó.

**Consecuencia práctica para quien lea el código:** los dos universos no son un
error ni una inconsistencia. Los scripts `31/32/33/33b` operan sobre el maestro
del SLEP (97 establecimientos); los scripts `34/35/36` operan sobre el directorio
oficial nacional filtrado a la Región de Valparaíso (1.268 establecimientos). Son
dos flujos que comparten repositorio, convenciones y activos de diseño, pero no
insumos ni universo.

---

## Estructura del pipeline

Carpetas por decenas según el flujo de ejecución (ver `POLITICA_PROYECTO.md` en
la knowledge base del Project).

```
00_run_all.R                    orquestador (afiches)
00_escanear_proyecto.R          escáner de estructura
10_utils/                       bootstrapping y configuración
20_insumos/                     datos crudos (read-only)
30_procesamiento/
  30_preparar_comunas.R         shapefile BCN -> comunas.geojson (no cableado a run_all)
  31_leer_validar.R             maestro SLEP: lectura, validación, numeración N->S
  32_proyectar_lienzo.R         proyección lat/lon -> lienzo del afiche
  33_generar_afiche.R           variante 1 (con inset)
  33b_generar_afiche_escala_unica.R   variante 2 (escala única; no cableado a run_all)
  34_preparar_directorio_region.R     variante 3: universo regional + recodificación SLEP
  35_agregar_matricula_historica.R            variante 3: indicadores de matrícula 2016-2025
  36_construir_geojson_web.R                variante 3: serialización a GeoJSON/JSON para el web
40_salidas/                     productos generados
50_documentacion/               política, decisiones, traspasos, andamios, escáner
docs/                           sitio publicado en GitHub Pages (variante 3)
```

---

## Cómo correr el pipeline

### Afiches (variantes 1 y 2)

```r
# Desde la raíz del proyecto, en Positron:
source("00_run_all.R")
run_all()            # pipeline completo (variante 1, con inset)
run_all(only = 1)    # solo leer y validar
run_all(from = 2)    # desde la proyección
```

Exportar la variante 1 a PDF (paso manual, requiere Chrome):

```r
pagedown::chrome_print(
  here::here("40_salidas", "afiche", "mapa_establecimientos.html"),
  output = here::here("40_salidas", "afiche", "mapa_establecimientos.pdf")
)
```

La variante 2 no está cableada a `00_run_all.R` (decisión consciente: el
orquestador es un archivo estable y el beneficio no justifica tocarlo). Se corre
directamente:

```r
source(here::here("30_procesamiento", "33b_generar_afiche_escala_unica.R"))
```

Para iterar sobre el HTML/PDF sin re-renderizar el mapa de pines (mucho más
rápido):

```r
Sys.setenv(REUSAR_PNG = "TRUE")
source(here::here("30_procesamiento", "33b_generar_afiche_escala_unica.R"))
```

**Nota importante sobre las etiquetas de comuna.** Si se regenera el PDF desde
`33b`, las 4 etiquetas de comuna vuelven a la posición calculada por el script
(Viña del Mar queda bajo el cluster). El pulido editorial que las lleva al océano
se hace **a mano en Affinity Publisher** sobre el PDF editable, y debe rehacerse
tras cada regeneración. Esta separación entre capa de código y capa editorial es
deliberada: la posición al océano no es reproducible por código sin que el rótulo
de Viña (que mide el 14% del ancho del panel) choque con la geometría de pines.

### Mapa interactivo (variante 3)

Los tres scripts corren en secuencia y no están cableados al orquestador:

```r
source(here::here("30_procesamiento", "34_preparar_directorio_region.R"))
source(here::here("30_procesamiento", "35_agregar_matricula_historica.R"))
source(here::here("30_procesamiento", "36_construir_geojson_web.R"))
```

Los intermedios (`.rds`) quedan en `40_salidas/mapa_interactivo/` y no se
versionan; los artefactos web agregados (`establecimientos.geojson`,
`sin_geo.json`, `metadatos.json`) se escriben en
`40_salidas/mapa_interactivo/web/data/` y sí se versionan. La gobernanza del MRUN
está declarada en la cabecera del propio script 35: el identificador se usa solo
en memoria para contar estudiantes distintos y se descarta; ninguna salida
contiene identificadores individuales.

Para publicar los datos en el sitio, se copian a `docs/data/` con el script de
sincronización (paso manual):

```bash
./sincronizar_docs.sh
```

El sitio se sirve desde `docs/` vía GitHub Pages:
`https://tomgc.github.io/slep_territorio_costa_central/`

---

## Reglas de negocio del mapa interactivo

Decisiones metodológicas que el lector del mapa **debe** conocer para
interpretarlo. Todas están declaradas también en `docs/data/metadatos.json`.

**Universo.** Región de Valparaíso, territorio continental, establecimientos con
`ESTADO_ESTAB = 1` (en funcionamiento): 1.268 establecimientos educacionales, de
los cuales 1.251 tienen coordenadas válidas y 17 no (estos últimos se listan
aparte, en `sin_geo.json`, y se incluyen en la exportación a XLSX).

**Exclusión de territorio insular.** Rapa Nui (comuna 5201) y Juan Fernández
(comuna 5104) quedan **fuera de la versión 1**, de todo el producto (no solo del
mapa: tampoco en las tablas ni en el XLSX). El criterio es de propósito, no de
calidad del dato: son territorios oceánicos separados, con sistema educativo
propio, que no constituyen el "entorno" del SLEP Costa Central. Los datos son
válidos y ambos son candidatos a una capa o inset separado en una versión futura.

**Dependencia SLEP vigente a 2026.** El directorio oficial tiene corte al 30 de
abril de 2025 y por lo tanto antecede a varios traspasos a SLEP que ya
ocurrieron. El mapa **recodifica** la dependencia: las comunas con año de
traspaso menor o igual a 2026 se muestran bajo su SLEP correspondiente, aunque el
directorio las registre como municipales. Excepciones respetadas (siguen
municipales): Zapallar (traspaso 2027), del Litoral completo (2027), Santo
Domingo (2028) y Quillota (2029). Total: 343 establecimientos bajo dependencia
SLEP (127 ya así en el directorio + 216 recodificados). **La dependencia que
muestra el mapa no es literal del directorio 2025.**

**Jardines JUNJI e Integra.** No aparecen en el mapa. No tienen RBD (usan
`ID_ESTAB`) y por lo tanto no están en el directorio oficial de establecimientos.
Integrarlos requiere una fuente de geolocalización propia (catastro JUNJI/Integra)
y queda para una versión futura.

**Matrícula.** Ventana 2016–2025, contada como `uniqueN(MRUN)` por establecimiento
y año. Los años sin registro se excluyen del cálculo; no se cuentan como cero
(contarlos como cero deflactaría los indicadores de establecimientos con historia
de matrícula escasa pero real).

**Establecimientos sin registro de matrícula.** 85 establecimientos no tienen
matrícula en la ventana. El mapa distingue dos situaciones: 25 en cierre
progresivo, que muestran su oferta **histórica** derivada del último año con
matrícula ("Impartía hasta 20XX: ..."), y 60 sin ningún registro, que declaran
explícitamente la ausencia ("Sin registros de matrícula ni enseñanza
(2016–2025)"). No existe en los datos MINEDUC una fuente de autorización de
oferta educativa independiente de la matrícula: los campos de enseñanza del
directorio oficial también se derivan de haber tenido al menos un alumno
matriculado. Los 85 son, en su totalidad, de modalidades no obligatorias
(mayoritariamente jardines particulares pagados), lo que sugiere que el sistema
de matrícula única no captura bien la parvularia privada. Esto no es un defecto
del pipeline: es una característica de la fuente que el mapa hace visible.

---

## Requisitos de entorno

**Locale UTF-8 obligatorio.** El pipeline usa nombres de comunas con tildes y ñ.
Un locale distinto provoca caídas silenciosas en `sf::st_intersection()` (las
comunas no coinciden con ningún punto). Verificar antes de correr:

```r
Sys.getlocale("LC_CTYPE")  # debe contener "UTF-8"
```

En macOS/Linux, agregar a `~/.Renviron`: `LC_ALL=en_US.UTF-8`. En Windows, usar
R >= 4.2 (UTF-8 nativo) o `Sys.setlocale("LC_ALL", "en_US.UTF-8")`.

**Otros requisitos:**
- R >= 4.1 (pipe nativo `|>`). Desarrollado en R 4.5.2.
- Chrome instalado, para `pagedown::chrome_print()`.
- Red disponible, solo para descargar los tiles CARTO al renderizar.

---

## De dónde salen los datos

**Maestro de establecimientos del SLEP** (variantes 1 y 2).
`20_insumos/maestro_establecimientos.xlsx`, provisto por el equipo SLEP. RBD y
nombre de establecimiento son públicos y se muestran completos. No contiene datos
personales ni de niños, niñas y adolescentes.

**Directorio oficial de establecimientos** (variante 3).
`20_insumos/auxiliares/directorio_oficial_ee_publico.csv`, dato público MINEDUC,
corte al 30 de abril de 2025. No se versiona en el repositorio (3,4 MB, crudo
regenerable desde la fuente).

**Histórico de matrícula por estudiante** (variante 3).
`20_insumos/historico_matricula/`, dato público MINEDUC. **No se versiona ni se
versionará jamás:** contiene MRUN (identificador individual del estudiante). El
pipeline lo agrega y descarta el identificador; los productos publicados
(`docs/data/`) contienen solo conteos agregados por establecimiento y año, sin
ningún dato individual. Los intermedios `.rds` de este flujo también quedan fuera
del repositorio (`40_salidas/mapa_interactivo/*.rds` está en `.gitignore`).

**Diccionarios canónicos** (variante 3). Sí se versionan, porque no traen dato
individual y son parte de la definición del pipeline:
`codigo_tipo_y_macrogrupo.xlsx` (mapeo de los 23 códigos de enseñanza a 6
macrogrupos), `listado_slep_2026.xlsx` (comuna → SLEP, con año de traspaso y
excepciones) y `diccionario_territorios.xlsx`.

**Límites comunales.** El pipeline usa `20_insumos/comunas.geojson` (versionado)
como fuente primaria. La carpeta `20_insumos/comunas_bcn/` contiene el shapefile
original de la Biblioteca del Congreso Nacional en alta resolución; **no está
versionada** (61 MB, binario). Si hace falta regenerar el GeoJSON, descargar la
capa "Comunas" desde `https://www.bcn.cl/siit/mapas_vectoriales` y correr
`30_procesamiento/30_preparar_comunas.R`.

### Qué se versiona y qué no

El repositorio guarda **código y documentación**; las imágenes y los PDF se
reproducen desde los scripts. Fuera del repositorio (pero en disco): el shapefile
BCN crudo, los CSV del histórico de matrícula, los PDF y PNG de salida de los
afiches, y los `.rds` intermedios del mapa interactivo. El criterio es doble:
gobernanza (nada con identificador individual entra al repositorio) y peso (nada
pesado y regenerable entra al repositorio).

---

## Activos de diseño

`design_handoff_mapa_establecimientos/` contiene las tipografías institucionales
(`fonts/`: gobCL y Museo Sans) y los activos gráficos (`assets/`) que se embeben
en los HTML finales. **Para editar los PDF en Affinity Publisher hay que instalar
antes las fuentes** desde esa carpeta, o Affinity las sustituirá.

---

## Estado

**Sesión 7 (2026-07-12).**

- **Variantes 1 y 2 (afiches):** completas, auditadas y commiteadas. En espera de
  validación del director.
- **Variante 3 (mapa interactivo):** publicada y en producción. Pipeline auditado
  a tolerancia 0. En espera de validación con el equipo experto.

Pendientes abiertos, historial de sesiones y decisiones arquitectónicas:
`50_documentacion/traspasos/`, `50_documentacion/activa/backlog_acumulativo.md` y
`50_documentacion/activa/decisiones/`.
