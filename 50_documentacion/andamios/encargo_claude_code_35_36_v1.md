# Encargo Claude Code — Etapa 2 (parte B): scripts 35 y 36 + auditoría de datos

> **Proyecto:** `slep_georreferenciacion` · variante mapa interactivo regional
> **Precondición:** `34_preparar_directorio_region.R` aprobado y commiteado. Su salida
> `40_salidas/mapa_interactivo/directorio_region5.rds` es el universo continental (1.268 EE,
> 1.251 con geo, 17 sin geo, territorio insular excluido).
> **Modelo:** Fable. **Máximo 2 agentes.** `00_run_all.R` 🔒 intacto (pipeline corre aparte).
> **Alcance de este encargo:** SOLO 35 y 36 + auditoría de datos. El HTML (parte 4) es otro encargo.

---

## 0. Estado real a verificar antes de empezar

- `git status` limpio, HEAD con el 34 ya commiteado. Si el 34 no está commiteado, DETENTE y avísame.
- Lee `directorio_region5.rds` y confirma su forma antes de usarlo: 1.268 filas, RBD character único, columnas de geo/territorio/dependencia/macrogrupos. No asumas su esquema: verifícalo.
- Relee del reporte de diagnóstico las reglas §7 aprobadas (ventana 2016–2025, matrícula = `uniqueN(MRUN)`, min>0, parvularia jardines fuera).

---

## 1. Contrato (POLITICA + userPreferences) — resumen operativo

R único lenguaje; pipe nativo; `data.table::fread` para los CSV grandes; `here::here()`; llaves **character** en todo join; UTF-8 explícito en lectura (D2/D4 del diagnóstico: los CSV son UTF-8 con BOM, headers en case variable → `toupper(names())`); constantes nombradas, cero números mágicos; escritura atómica (tmp→rename); idempotencia con verificación por hash; 7 bloques canónicos por script; un commit por script conceptual; nunca `git add -A`; `git ls-files` limpio de MRUN/crudos antes de cada commit; máximo 2 agentes; autonomía con reporte de una línea en decisiones menores; detente ante decisión estratégica o dato crítico faltante.

---

## 2. Script `35_agregar_matricula_historica.R`

**Objetivo:** para cada RBD del universo continental, calcular la serie anual de matrícula 2016–2025 y los 4 indicadores, leyendo el histórico por estudiante SIN que ningún MRUN sobreviva a la salida.

**Constantes nombradas:**
- `N_ANIOS <- 10`, `ANIO_MIN <- 2016`, `ANIO_MAX <- 2025` (verifica que hay 10 archivos).
- Rutas a `20_insumos/historico_matricula/Matricula-por-estudiante-YYYY/` (resuelve el CSV de cada carpeta por patrón; los nombres varían año a año, ver diagnóstico).
- `TEXTO_SIN_MATRICULA <- "Sin matrícula en 2025."` (literal, para 36).
- `ETIQUETA_SIN_DATO <- "sin dato"` (para min>0 sin años válidos).

**Flujo:**
1. Carga `directorio_region5.rds`; extrae el vector de RBD del universo (character). Este universo FILTRA el histórico: solo se agregan RBD que están en él (los insulares y no-región-5 se descartan en el join).
2. Por cada año 2016–2025: `fread` con `select` de solo las columnas necesarias (RBD, MRUN) para no cargar 38 columnas × 3,5M filas. Normaliza case de headers. RBD y MRUN a character. Filtra al universo. Calcula matrícula del año = `uniqueN(MRUN)` por RBD (`.by = RBD`). Libera el objeto grande antes del siguiente año (no acumular 10 × 550 MB en memoria).
3. Ensambla la matriz RBD × año (formato largo recomendado: RBD, anio, matricula). RBD-años sin registro quedan ausentes (no como 0 — distinción crítica para min>0).
4. Calcula los 4 indicadores por RBD:
   - `matricula_actual` = matrícula de `ANIO_MAX` (2025); si el RBD no tiene fila 2025 → marca para `TEXTO_SIN_MATRICULA` (son los 85 esperados; confirma el conteo).
   - `max_10` = max de la serie observada.
   - `prom_10` = mean de la serie observada (sin redondear aún; redondeo solo en 36 al exportar).
   - `min_10` = min de los años con matrícula **> 0**; si no hay ninguno → `ETIQUETA_SIN_DATO`, nunca 0.
5. **Descarta MRUN**: la salida contiene solo RBD + serie agregada + indicadores. Ningún identificador individual.
6. Validaciones (C.8): sin RBD duplicados; nº de RBD con matrícula 2025 coherente con el directorio (1.184 con flag MATRICULA=1); totales anuales regionales en rango razonable (no saltos > X% año a año sin explicación); reporta RBD del universo SIN ninguna matrícula en la ventana (candidatos a "sin dato").
7. Salida atómica: `40_salidas/mapa_interactivo/matricula_historica_r5.rds` (intermedio, sin dato individual, no trackeado). Idempotencia por hash en 2 corridas.

**Entregable de 35:** el .rds + reporte en el log: universo cubierto, nº con/sin matrícula 2025, distribución de los 4 indicadores (min/max/mediana de cada uno), lista de RBD "sin dato", tiempo total de corrida.

---

## 3. Script `36_construir_geojson_web.R`

**Objetivo:** unir directorio + indicadores + serie en un único artefacto liviano para la web, más metadatos.

**Flujo:**
1. Une `directorio_region5.rds` (universo, geo, atributos, macrogrupos, niveles-fuente) con `matricula_historica_r5.rds` por RBD (character, left join desde el directorio: todos los EE del universo aparecen, tengan o no histórico).
2. Los EE sin matrícula 2025 llevan `matricula_actual = TEXTO_SIN_MATRICULA` literal; los sin dato en min → `ETIQUETA_SIN_DATO`. Redondeo de `prom_10` a entero SOLO aquí.
3. Estructura de cada EE en el JSON (claves cortas para peso, documentadas en metadatos):
   - identificación: rbd, nombre
   - geo: lat, lon (solo los 1.251 con geo; los 17 sin geo NO van al JSON de pins pero SÍ a un bloque `sin_geo` separado para el XLSX, con sus atributos y "sin coordenadas")
   - territorio: comuna, provincia (7 continentales), dependencia (COD_DEPE2 decodificada)
   - enseñanza: macrogrupos (de la planilla canónica), y los pares (tipo, nivel) observados para el filtro Nivel dependiente
   - matrícula: los 4 indicadores + serie anual 2016–2025 (array de 10, con null donde no hubo registro)
4. Genera `metadatos.json`: ventana de años, fecha de corte, criterios de cálculo (matrícula = MRUN distintos; min>0; parvularia jardines fuera; territorio insular fuera de v1 con nota de v2), universo (1.268), pins (1.251), sin geo (17), fuente de datos, glosa de dependencias y macrogrupos.
5. Salidas atómicas en `40_salidas/mapa_interactivo/web/data/`: `establecimientos.json` (o `.geojson` si conviene para Leaflet — decide y documenta), `metadatos.json`. Estos SÍ se versionan (agregados, sin dato individual) y serán la data del HTML.
6. Verifica peso final (esperado < 1 MB) y reporta.

**Decisión abierta (resuélvela con criterio y documenta):** JSON plano vs. GeoJSON FeatureCollection. GeoJSON es más directo para Leaflet pero más verboso; JSON plano es más liviano y se convierte a capa en JS. Recomendación por defecto: **GeoJSON** por integración directa con Leaflet, salvo que el peso lo desaconseje.

---

## 4. AUDITORÍA DE DATOS (obligatoria, en el mismo encargo)

Verificación independiente contra el crudo, no contra los logs de 35/36. Entregable: `50_documentacion/andamios/auditoria_35_36_datos.md`.

1. **Recuento independiente de 8–10 RBD** (mezcla de comunas, dependencias, tamaños, incluyendo al menos uno "sin matrícula 2025" y uno con año en 0 en la serie): releer el crudo del año directamente, `uniqueN(MRUN)` a mano, recomputar los 4 indicadores por un camino separado del de 35, y comparar con el JSON de 36. **Tolerancia 0.** Tabla RBD × indicador × (36 vs recálculo).
2. **Regla min>0:** exhibir un RBD con un año en 0 o ausente y confirmar que min lo excluye; exhibir (si existe) un RBD sin ningún año válido y confirmar `ETIQUETA_SIN_DATO`, no 0.
3. **matricula_actual = 2025:** verificar contra el CSV 2025 en muestra.
4. **Universo y geo:** pins del JSON = 1.251; bloque sin_geo = 17; insulares ausentes (0 en todo el JSON); provincias = 7.
5. **Gobernanza (crítica):** `git ls-files` sin MRUN/crudos; inspección del JSON publicado y de los .rds intermedios: grep de MRUN, de nombres de estudiante, de cualquier columna individual → 0. Confirmar que los .rds intermedios NO están trackeados y el JSON agregado SÍ.
6. **Idempotencia:** hash de `establecimientos.json` idéntico en 2 corridas completas de 35→36.
7. **Coherencia de totales:** matrícula regional total 2025 del JSON vs. suma directa del crudo 2025 filtrado al universo. Deben coincidir.

Todo hallazgo se corrige antes de cerrar el encargo, o se documenta como pendiente si excede el alcance.

---

## 5. Commits (separados, tras aprobación de cada revisión)

1. `feat(pipeline): 35_agregar_matricula_historica — serie 2016-2025 e indicadores por RBD (sin dato individual)`
2. `feat(pipeline): 36_construir_geojson_web — JSON agregado + metadatos para el mapa`
3. `data(web): establecimientos y metadatos agregados del mapa interactivo` (los JSON versionables)
4. `docs(auditoria): auditoria de datos 35-36 (recuento independiente, min>0, gobernanza)`

Verifica `git status` antes de cada add; nunca `git add -A`; `git ls-files` limpio de crudos antes de cada commit.

---

## 6. Puntos de detención (reporta y espera revisión del titular)

- Tras 35: reporta antes de seguir con 36.
- Tras 36: reporta antes de la auditoría.
- Tras la auditoría: reporta antes de cualquier commit de los JSON.
- Ante cualquier divergencia con el diagnóstico, o si un recuento de auditoría no cuadra con tolerancia 0: DETENTE y reporta, no "ajustes" para que cuadre.

Invariantes: 🔒 `00_run_all`, `33`, `33b`, `31`, `32`, `10_*`, maestro. ⚠️ MRUN nunca al repo. ⚠️ no Python. ⚠️ máximo 2 agentes.
