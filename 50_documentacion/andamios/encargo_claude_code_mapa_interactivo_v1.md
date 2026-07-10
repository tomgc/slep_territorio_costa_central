# Encargo Claude Code — Mapa interactivo regional de establecimientos (variante 3)

> **Proyecto:** `slep_georreferenciacion`
> **Tipo de sesión:** NEW PROJECT (variante nueva sobre cimientos existentes; no reemplaza 33 ni 33b)
> **Gobernanza:** POLITICA_PROYECTO.md v5.2 + SETTINGS_Y_PROMPTS_OPERACIONALES.md v7 (knowledge base)
> **Destino de publicación:** GitHub Pages (estático)
> **Modelo de datos:** pre-agregación en R → JSON liviano; el histórico crudo NO se publica
> **Alcance geográfico:** Región de Valparaíso completa (COD_REG = 5), todas sus provincias y comunas

---

## 0. Estado real del repo declarado (verificar antes de tocar)

**No asumas este estado: verifícalo con `git status`, el escáner y lectura directa antes de empezar.**

- HEAD remoto y local en `79bdf4e` (README actualizado, sesión 6).
- Variantes existentes `33_generar_afiche.R` (con inset) y `33b_generar_afiche_escala_unica.R` (escala única) están **🔒 byte-idénticas y NO se tocan**. Esta variante es un pipeline nuevo y paralelo.
- Insumos nuevos ya en disco (NO versionados; binarios y/o con datos por estudiante):
  - `20_insumos/auxiliares/directorio_oficial_ee_publico.csv` — directorio oficial nacional (sep `;`, decimal `,`, latin1). Columnas clave: `AGNO;RBD;DGV_RBD;NOM_RBD;COD_REG_RBD;NOM_REG_RBD_A;COD_PRO_RBD;COD_COM_RBD;NOM_COM_RBD;COD_DEPROV_RBD;NOM_DEPROV_RBD;COD_DEPE;COD_DEPE2;RURAL_RBD;LATITUD;LONGITUD;ENS_01..ENS_11;MAT_ENS_1..8;MAT_TOTAL;MATRICULA;ESTADO_ESTAB;ESPE_01..11`.
  - `20_insumos/auxiliares/diccionario_territorios.xlsx` — códigos de territorio (tipo_territorio, codigo, nombre).
  - `20_insumos/auxiliares/listado_slep_2026.xlsx` — mapeo comuna→SLEP (contexto, no imprescindible).
  - `20_insumos/auxiliares/glosas_directorio_oficial_ee.pdf` — glosas de códigos (COD_DEPE, COD_ENSE, etc.). **Léela para el diccionario de decodificación.**
  - `20_insumos/historico_matricula/Matricula-por-estudiante-YYYY/` (2004–2025) — matrícula **por estudiante** (una fila por estudiante-curso). Cada carpeta trae un `*.CSV` (sep `;`, latin1, BOM). Columnas clave: `AGNO;RBD;...;COD_ENSE;COD_GRADO;...;MRUN;...`. **La matrícula de un RBD = nº de MRUN distintos, NO nº de filas** (un estudiante puede tener varias filas por grado/curso).
  - `20_insumos/historico_matricula/Matricula-Ed.-Parvularia-YYYY/` — matrícula de párvulos (estructura distinta; ver etapa 1).

- El proyecto usa **raíz unificada Rama A** (datos públicos, dentro del repo). PERO: el histórico por estudiante contiene MRUN (identificador individual). **Decisión de gobernanza obligatoria (ver §4): el crudo por estudiante NO se versiona ni se publica; solo se versiona/publica el agregado por RBD sin ningún dato individual.**

---

## 1. Contrato de interacción (POLITICA + userPreferences)

- **R es el único lenguaje de análisis.** Nada de Python. Pipe nativo `|>`, `dplyr >= 1.1` con `.by=`, `here::here()` para todas las rutas internas, `data.table::fread()` para los CSV grandes por su tamaño.
- **Rutas de terminal:** SIEMPRE completas desde la raíz del proyecto (`/Users/tomgc/Projects/slep_georreferenciacion/...`). Nunca asumir el working directory.
- **Estructura canónica por decenas.** Los scripts nuevos entran a `30_procesamiento/` con correlativos que NO colisionen con 31/32/33/33b. Usa la decena 30 para el pipeline nuevo con sufijos claros (ver §5).
- **Nombres de archivos y carpetas:** snake_case, sin tildes, sin ñ, sin espacios. El contenido (comentarios, títulos) va en español pleno.
- **Estructura canónica de cada script:** (1) header banner; (2) auto-instalación; (3) `library()`; (4) rutas centralizadas; (5) constantes nombradas; (6) funciones; (7) flujo principal. Nada de rutas/paquetes/constantes en medio del flujo.
- **Llaves como character:** RBD, códigos comunales, COD_DEPE, COD_ENSE SIEMPRE `character` en joins (un join con tipos mezclados falla en silencio).
- **Constantes nombradas, jamás números mágicos:** ventana de años, umbrales, tolerancias, códigos de región, todo como constante al inicio.
- **Escritura atómica** (write → rename) para todo artefacto que alimente otro proceso o la web.
- **Idempotencia:** correr el pipeline N veces produce el mismo JSON.
- **Autonomía máxima:** resuelve rutas rotas, warnings, tipados y refactors menores solo, reportando en una línea. Interrumpe SOLO por decisión estratégica vital o dato crítico irrecuperable.
- **Un cambio conceptual por commit** (policy 9.7). Commits separados por tipo conceptual, mensajes en español.
- **Solo texto al repo.** Binarios (CSV crudos, xlsx) quedan en disco, gitignored.
- **Registro obligatorio de errores del asistente** (POLITICA 0.5): toda desviación de una regla canónica se anota en el momento, para el traspaso de cierre.

---

## 2. Objetivo funcional (qué debe hacer el producto)

Un mapa web interactivo, estático, alojado en GitHub Pages, que muestre todos los establecimientos educacionales de la Región de Valparaíso, con:

### 2.1 Pins
- Un pin por establecimiento, posicionado por `LATITUD`/`LONGITUD` del directorio oficial.
- Establecimientos sin geo válida: excluidos del mapa pero **reportados** en el log de diagnóstico (conteo y lista de RBD). No inventar coordenadas.

### 2.2 Hover
- Agranda sutilmente el pin.
- Muestra: nombre del establecimiento, RBD entre paréntesis; en la línea siguiente, comuna y dependencia (decodificada, no el código).

### 2.3 Click
- Mantiene lo del hover y agrega 4 indicadores de matrícula (ventana móvil de los últimos 10 años disponibles):
  - **Matrícula actual:** matrícula del año más reciente disponible.
  - **Máximo 10 años:** mayor matrícula anual simultánea en la ventana.
  - **Promedio 10 años:** media de la matrícula anual en la ventana.
  - **Mínimo 10 años:** menor matrícula anual simultánea en la ventana; **estrictamente > 0** (un año con 0 o sin registro NO cuenta como mínimo; ver regla en §3.3).

### 2.4 Filtros (acumulativos, con opciones dependientes)
Al activar un filtro, los demás filtros limitan sus opciones a lo que sigue disponible. Al filtrar, el mapa **enfatiza** lo filtrado (los que cumplen se destacan; los que no, se atenúan — no se eliminan del canvas salvo que se decida lo contrario en la etapa de diseño).
- **Provincia** (COD_PRO_RBD / NOM_DEPROV o equivalente).
- **Comuna** (COD_COM_RBD / NOM_COM_RBD).
- **Dependencia** (COD_DEPE / COD_DEPE2, decodificada).
- **Establecimiento** (selector con **búsqueda tipo combobox filtrable**; ~1.700 EE en la región, un dropdown plano no sirve).
- **Tipo de enseñanza** (ENS_01..ENS_11 del directorio / COD_ENSE del histórico; decodificado).
- **Nivel:** depende del tipo de enseñanza; **solo aparece tras elegir un tipo de enseñanza**. Muestra los EE que tienen ese nivel disponible.

### 2.5 Exportación
- **SVG:** captura/exportación de la vista actual del mapa (lo que se ve en pantalla, con el filtro aplicado).
- **XLSX:** planilla con los datos (totales o filtrados según el estado de los filtros). Locale español (`;` separador, `,` decimal). Una fila por establecimiento con sus atributos e indicadores.

---

## 3. Reglas de cálculo (críticas — el diagnóstico de la etapa 1 las valida)

### 3.1 Matrícula anual por RBD
- Para cada año Y y cada RBD: **matrícula = nº de MRUN distintos** en ese RBD ese año (no nº de filas).
- Fuente primaria: `Matricula-por-estudiante-YYYY`. La parvularia tiene archivo separado con estructura distinta; la etapa 1 determina si se suma al conteo por RBD o se maneja aparte (decisión documentada, no asumida).

### 3.2 Ventana "últimos 10 años"
- Constante `N_ANIOS <- 10`. Años = los 10 más recientes con dato disponible (esperado 2016–2025; el diagnóstico confirma qué años existen y están completos).

### 3.3 Los 4 indicadores
- `matricula_actual` = matrícula del año máximo disponible.
- `max_10` = max de la serie anual en la ventana.
- `prom_10` = mean de la serie anual (redondeo solo en la exportación final, no antes).
- `min_10` = min de la serie anual **considerando solo años con matrícula > 0**. Si un RBD tiene años sin registro o con 0, esos años se excluyen del mínimo. Si tras excluir no queda ningún año > 0, el indicador es "sin dato" (no 0).
- Documentar el criterio exacto como comentario y como nota en el JSON de metadatos.

### 3.4 Join directorio ↔ histórico
- Llave `RBD` como character. Verificar cobertura: cuántos RBD del directorio (región 5) tienen histórico y cuántos no (reportar en diagnóstico).
- El directorio filtra el universo (región 5, establecimientos vigentes); el histórico aporta la serie de matrícula.

---

## 4. Gobernanza de datos (obligatorio, POLITICA §6)

- El histórico **por estudiante** contiene MRUN (dato individual). **Nunca** entra al repo ni al JSON publicado.
- El pipeline lee el crudo desde disco, agrega a nivel RBD-año (matrícula = MRUN distintos) y **descarta el MRUN** antes de escribir cualquier salida versionada.
- El JSON publicado contiene solo: identificación del EE (RBD, nombre), geo, atributos categóricos (comuna, provincia, dependencia, tipos de enseñanza, niveles) y los 4 indicadores + serie anual agregada. **Cero datos individuales.**
- Añadir `20_insumos/historico_matricula/` y `20_insumos/auxiliares/*.csv` al `.gitignore` (crudos). Generar `50_documentacion/activa/gobernanza_datos.md` documentando: qué se procesa, categoría (agregado sin dato personal en la salida), dónde vive el crudo, base legal, retención.
- Verificar con `git ls-files` (no con el escáner) que ningún crudo ni MRUN entró al control de versiones antes de cada commit.

---

## 5. Arquitectura técnica propuesta (ajustable en etapa 1)

Pipeline nuevo en `30_procesamiento/`, correlativos que no colisionan con lo existente:

```
30_procesamiento/
  34_preparar_directorio_region.R    # filtra región 5, decodifica, extrae geo + atributos + tipos/niveles
  35_agregar_matricula_historica.R   # lee histórico, MRUN distintos por RBD-año, ventana 10 años, 4 indicadores
  36_construir_geojson_web.R         # une directorio + indicadores -> JSON/GeoJSON liviano para la web
40_salidas/
  web/                               # artefactos publicables (GitHub Pages)
    data/establecimientos.json       # o .geojson; una entrada por EE
    data/metadatos.json              # ventana de años, fecha de corte, criterios de cálculo
    index.html                       # mapa (Leaflet) autocontenido salvo la data
    assets/                          # css/js locales
```

- **Librería de mapa:** Leaflet (JS, ligera, tiles CARTO Positron como en 33). Justificar en etapa 1 si se prefiere MapLibre. Recomendación por defecto: **Leaflet** (madurez, peso, familiaridad con CARTO ya usada en el proyecto).
- **Basemap:** tiles CARTO en línea (no se pueden empacar; Pages sirve el HTML, los tiles vienen del CDN de CARTO). Aceptable para un mapa online.
- **Exportación SVG:** de la vista Leaflet (evaluar `leaflet-image` o render SVG nativo; decidir en etapa 2 y documentar).
- **Exportación XLSX en el navegador:** SheetJS (`xlsx`) local, sin CDN externo si se puede (empacar el .js). Locale español en el archivo resultante.
- **Filtros dependientes:** el JSON incluye por EE todos los atributos necesarios; el filtrado y la dependencia de opciones se resuelven en JS en el cliente sobre ese JSON. No hay backend.
- **Publicación:** rama `gh-pages` o carpeta `/docs` en `main`. Recomendación: **carpeta `40_salidas/web/` publicada vía workflow que copie a `/docs`**, o configurar Pages directo sobre una carpeta. Decidir en etapa 3 según cómo esté el repo remoto.

---

## ETAPA 1 — DIAGNÓSTICO (no construir nada aún)

**Objetivo:** entender el dato real y validar todas las reglas de cálculo antes de escribir el pipeline. Entregar un informe, no código de producción.

**Tareas:**
1. Leer las glosas (`glosas_directorio_oficial_ee.pdf`) y construir el diccionario de decodificación: COD_DEPE/COD_DEPE2 → dependencia; COD_ENSE → tipo de enseñanza; COD_GRADO → nivel; relación tipo↔nivel. Documentar en una tabla.
2. Cargar el directorio, filtrar región 5. Reportar: nº de EE, nº con geo válida vs. sin geo (con RBD), distribución por provincia/comuna/dependencia, tipos de enseñanza presentes.
3. Sobre 2–3 años del histórico por estudiante (p. ej. 2016, 2020, 2025): confirmar encoding/sep/BOM; confirmar que matrícula por RBD = MRUN distintos (mostrar un RBD con varias filas por MRUN si existe); medir tamaño y tiempo de lectura de un año completo para dimensionar el pipeline.
4. Resolver la parvularia: ¿su matrícula se integra al conteo por RBD-año o va aparte? Inspeccionar su estructura y decidir con justificación.
5. Verificar la ventana de años: qué años existen, cuáles están completos, si 2016–2025 es correcto.
6. Medir cobertura del join directorio↔histórico (RBD con y sin serie).
7. Estimar el peso del JSON final (nº EE × campos) para confirmar que es liviano para Pages.

**Entregable:** `50_documentacion/andamios/reporte_diagnostico_mapa_interactivo.md` con hallazgos, decisiones tomadas (parvularia, ventana, decodificación) y cualquier desviación respecto a este encargo. **Detente aquí y reporta.** Si algo contradice los supuestos de §3, proponer ajuste antes de la etapa 2.

---

## ETAPA 2 — IMPLEMENTACIÓN

**Precondición:** etapa 1 aprobada.

**Tareas:**
1. `34_preparar_directorio_region.R`: universo región 5, decodificación, geo, atributos, tipos/niveles por EE. Validaciones: NAs en columnas clave, geo dentro de bounding box de Valparaíso, RBD únicos.
2. `35_agregar_matricula_historica.R`: lectura eficiente (`fread`), MRUN distintos por RBD-año, ventana 10 años, los 4 indicadores con la regla de min>0. Idempotente. Descarta MRUN antes de escribir. Validación: totales por año razonables, sin duplicados RBD-año.
3. `36_construir_geojson_web.R`: une directorio + indicadores + serie anual → JSON/GeoJSON liviano + `metadatos.json`. Escritura atómica.
4. `40_salidas/web/index.html` + assets: mapa Leaflet, pins, hover, click con los 4 indicadores, los 6 filtros acumulativos con opciones dependientes y el filtro Nivel condicionado a Tipo de enseñanza, combobox filtrable para Establecimiento, exportación SVG y XLSX (locale español). Sin browser storage (localStorage/sessionStorage no se usan). CSS/JS locales; minimizar dependencias externas a los tiles.
5. `.gitignore`: crudos e intermedios con dato individual fuera del repo. `gobernanza_datos.md`.
6. Cablear el pipeline nuevo a un orquestador propio o documentar cómo se corre (NO tocar `00_run_all.R` 🔒 sin decisión explícita del titular; por defecto, script de corrida separado o entradas nuevas discutidas aparte).

**Reglas:** cada script cumple la estructura canónica de 7 bloques; constantes nombradas; llaves character; un commit por script conceptual.

---

## ETAPA 3 — AUDITORÍA (verificación independiente)

**Objetivo:** comprobar que el producto quedó bien hecho, contra los artefactos reales, no contra los logs de la implementación.

**Auditoría de datos:**
1. **Recuento independiente:** para una muestra de 8–10 RBD (mezcla de comunas, dependencias y tamaños), recalcular los 4 indicadores por un camino independiente (leer el crudo del año, contar MRUN distintos a mano) y comparar con el JSON. Tolerancia 0 (deben ser idénticos). Reportar tabla RBD × indicador × (JSON vs recálculo).
2. **Regla min>0:** encontrar al menos un RBD con un año en 0 o faltante y confirmar que el mínimo lo excluye correctamente.
3. **Matrícula actual = año más reciente:** verificar contra el CSV 2025.
4. **Cobertura geo:** confirmar que el nº de pins = nº de EE con geo válida, y que los sin geo están reportados, no silenciados.
5. **Gobernanza:** `git ls-files | grep -i` para MRUN, CSV crudos, xlsx de matrícula → debe ser vacío. Inspeccionar el JSON publicado: cero MRUN, cero dato individual.

**Auditoría funcional (documentada, con capturas o pasos reproducibles):**
6. Hover muestra los campos correctos y decodificados (no códigos).
7. Click muestra los 4 indicadores con las etiquetas que responden las 4 preguntas del requerimiento.
8. Filtros acumulativos: aplicar Provincia→Comuna→Dependencia y verificar que las opciones de los demás se restringen y que Establecimiento refleja solo lo disponible.
9. Nivel aparece solo tras elegir Tipo de enseñanza y lista los niveles correctos de ese tipo.
10. Exportación SVG refleja la vista filtrada. Exportación XLSX trae los datos filtrados, en locale español, con columnas legibles y decodificadas.
11. Sin uso de localStorage/sessionStorage. Carga del JSON correcta desde ruta relativa (compatible con la subruta de GitHub Pages).

**Auditoría de estructura y política:**
12. Nombres snake_case sin tildes/ñ/espacios; scripts con los 7 bloques; llaves character; constantes nombradas; escritura atómica; idempotencia (correr dos veces = mismo JSON, verificar con hash).
13. Commits separados por tipo conceptual, mensajes en español.

**Entregable:** `50_documentacion/andamios/auditoria_mapa_interactivo.md` con cada punto, evidencia y estado (OK / hallazgo / corregido). Todo hallazgo se corrige o se documenta como pendiente en el traspaso.

---

## 6. Restricciones e invariantes (🔒 no violar)

- 🔒 `33_generar_afiche.R`, `33b_generar_afiche_escala_unica.R`, `00_run_all.R`, `10_*`, `31`, `32`, maestro: byte-idénticos, NO se tocan.
- 🔒 Salidas de las variantes anteriores (`mapa_establecimientos*.{html,pdf}`) NO se regeneran ni sobrescriben.
- 🔒 MRUN / crudo por estudiante: nunca al repo ni al JSON publicado.
- ⚠️ NO cablear el pipeline nuevo a `00_run_all.R` sin decisión explícita del titular.
- ⚠️ NO usar Python en ninguna etapa.
- ⚠️ NO usar browser storage en el HTML.
- ✅ ANTES de cada commit: `git ls-files` limpio de datos individuales y binarios crudos.
- ✅ ANTES de construir (etapa 2): etapa 1 aprobada por el titular.

---

## 7. Cierre

Al terminar las tres etapas, generar el traspaso de cierre (`traspaso_cierre_vNN.md`) con: backlog acumulativo actualizado, bugs, aprendizajes, decisiones de diseño (Leaflet, parvularia, ventana de años, publicación en Pages), constantes vigentes, pendientes y la tabla de errores del asistente (§2.2.15). Ejecutar el escáner y referenciarlo. Generar `ESTADO.md`.
