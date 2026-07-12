# Encargo Claude Code — Mapa web interactivo (v2, reemplaza v1)

> **Proyecto:** `slep_georreferenciacion` · variante mapa interactivo regional
> **Reemplaza:** `encargo_claude_code_mapa_web_v1.md` (obsoleto: se escribió antes de la
> recodificación SLEP y de la paleta por SLEP específico).
> **Precondición:** HEAD `ad4beb4`. Datos DEFINITIVOS y congelados:
> `40_salidas/mapa_interactivo/web/data/{establecimientos.geojson, sin_geo.json, metadatos.json}`.
> **NO se tocan los scripts R ni los JSON.** Este encargo es exclusivamente front-end.
> **Máximo 2 agentes.** `00_run_all.R` 🔒. Publicación: `/docs` en `main`.

---

## 0. Verificación previa (obligatoria)

1. `git status` limpio; HEAD en `ad4beb4` o posterior con los JSON commiteados.
2. **Lee `metadatos.json` COMPLETO** y **una feature real del GeoJSON** con todas sus claves. El glosario de claves cortas está en metadatos. Todo lo que construyas lee del esquema REAL. No asumas nombres de campos.
3. Lee `33_generar_afiche.R` para extraer los tokens de identidad visual ya establecidos (paleta, tipografías, tratamiento). Fuentes en `design_handoff_mapa_establecimientos/fonts/` (gobCL, MuseoSans); logo en `assets/`.

---

## 1. Contexto del universo (para que entiendas qué estás pintando)

- **1.251 pins** (universo continental 1.268; 17 sin geo van al XLSX, no al mapa).
- **343 EE administrados por SLEP**, repartidos en **6 SLEP con establecimientos**:
  Costa Central (73) · Valparaíso (54) · Aconcagua (67) · Marga Marga (58) · Petorca (55) · Los Andes (36).
- **2 SLEP más existen institucionalmente pero aún NO administran EE** (del Litoral, traspaso 2027; Quillota, 2029). Sus establecimientos siguen municipales.
- Resto: Particular Subvencionado (~641) · Particular Pagado (~176) · Municipal no traspasado (~105: Zapallar, del Litoral, Santo Domingo, Quillota) · Corp. Administración Delegada (6).
- La dependencia del GeoJSON es la **vigente 2026** (recodificada), no la literal del directorio 2025. Está declarado en metadatos.

---

## 2. Paleta (decisión del titular; implementa exactamente esto)

**Familia azul para los SLEP, con jerarquía visual:**
- **SLEP Costa Central: azul oscuro institucional** (el protagonista; debe destacar sin ambigüedad).
- **Los otros 5 SLEP: tonalidades más claras de la misma familia azul.**

**Fuera de la familia azul:**
- **Particular Pagado:** morado.
- **Particular Subvencionado:** amarillo ocre.
- **Corp. Administración Delegada:** gris acero (solo 6 EE: deben ser *encontrables*, no ahogarse).
- **Municipal (no traspasado):** elige un color que funcione con el conjunto y que NO se confunda con la familia azul de los SLEP (la distinción municipal vs. SLEP es la más importante del mapa después de Costa Central). Justifica tu elección.

**Exigencias de la paleta (no opcionales):**
1. **Colores complementarios y armónicos entre sí**, no una colección de tonos sueltos.
2. **Contraste verificado**, no estimado: reporta los valores de contraste de cada color contra el basemap CARTO (fondo claro) y entre los azules entre sí. Los 5 azules claros deben ser distinguibles del oscuro y, en lo posible, entre ellos.
3. **Gradación con sentido, no arbitraria.** Los 5 azules claros deben ordenarse según un criterio explícito (recomendación: por año de traspaso, o por cercanía territorial a Costa Central). Aunque el ojo no distinga Aconcagua de Los Andes en un pin de 8px, la gradación debe *significar* algo. Declara el criterio que uses.
4. **Leyenda siempre visible**, con los 6 SLEP nombrados individualmente + las otras 4 categorías.
5. **Reconoce el límite perceptual en tu reporte:** si al renderizar los 6 azules no se distinguen bien, dilo con franqueza y propón una mitigación (ej. borde diferenciado, o agrupar visualmente y dejar el nombre al hover). No finjas que funciona si no funciona: el titular decide desde el render.

---

## 3. Funcionalidad (contrato; no negociable)

### 3.1 Mapa base
Leaflet + tiles CARTO (continuidad con el afiche). `preferCanvas: true`. Encuadre inicial: toda la región continental visible. Sin insulares (ya excluidos en datos).

**Densidad:** Viña/Valparaíso concentran cientos de EE. **Evalúa empíricamente sobre el render** si son legibles. Si no lo son, propón solución (clustering opcional, ajuste de radio por zoom, transparencia) con captura del antes/después. No asumas que 1.251 pins se ven bien: míralo.

### 3.2 Hover
Pin se agranda sutilmente (transición suave). Tooltip:
- Línea 1: `Nombre del establecimiento (RBD)`
- Línea 2: `Comuna · Dependencia` — y **si es SLEP, el nombre del SLEP**: `Viña del Mar · Servicio Local de Educación Costa Central`

### 3.3 Click
Panel con todo lo del hover MÁS:

**Los 4 indicadores**, con etiquetas que respondan literalmente:
- Matrícula actual (2025)
- Máximo de los últimos 10 años
- Promedio de los últimos 10 años
- Mínimo de los últimos 10 años

**Tres estados que DEBEN distinguirse visualmente:**
1. **Serie completa:** los 4 con número.
2. **En cierre progresivo (25 EE):** `Sin matrícula en 2025.` en el actual, pero máx/prom/mín REALES. El usuario debe entender que *fue* un EE con matrícula que dejó de operar. Ej. RBD 14439: máx 109, prom 74, mín 34.
3. **Sin dato en la ventana (60 EE):** `Sin matrícula en 2025.` y los otros tres en `sin dato`.

Los literales vienen del JSON tal cual: **no los reescribas en JS.**

**SPARKLINE (obligatorio, no opcional):** gráfico de línea de la serie 2016–2025 en el popup. Es lo que convierte 4 números en una trayectoria legible: el director debe *ver* la caída o el crecimiento. Requisitos:
- Los `null` de la serie son **huecos, no ceros**. No los dibujes en la línea base: interrumpe la línea o marca el hueco. Un EE con hueco 2020–2022 no cayó a cero, no hay dato.
- Eje Y desde 0 o desde el mínimo, con criterio (declara cuál y por qué).
- Debe funcionar en los 3 estados: serie completa, serie parcial (cierre), sin serie (no dibujar, mostrar el "sin dato").
- Los 6 EE con un solo año: el sparkline es un punto, no una línea. Manéjalo sin romperse.

### 3.4 Filtros — SIETE, acumulativos, con opciones dependientes

1. **Provincia** (7 continentales)
2. **Comuna** (36 → las disponibles según provincia)
3. **Dependencia** (las categorías vigentes)
4. **SLEP** — **solo los 6 que administran EE** (Costa Central, Valparaíso, Aconcagua, Marga Marga, Petorca, Los Andes). Los 2 pendientes (del Litoral 2027, Quillota 2029) **NO van en el filtro** (no filtrarían nada); menciónalos en una nota discreta o en metadatos visibles. Decisión del titular.
5. **Establecimiento** — **combobox con búsqueda por texto** (1.251 EE; un dropdown plano es inutilizable). Filtra mientras se escribe, por nombre Y por RBD.
6. **Tipo de enseñanza** — los 6 macrogrupos. Un EE puede pertenecer a varios.
7. **Nivel** — **solo aparece tras seleccionar Tipo de enseñanza**. Lista los niveles de ese tipo.

**Comportamiento exigido:**
- Opciones recalculadas dinámicamente sobre el subconjunto vigente. Si tras filtrar Provincia=Petorca no queda ningún Particular Pagado, esa opción desaparece o se deshabilita.
- El mapa **enfatiza** lo filtrado. **Tú decides atenuar vs. ocultar y lo justificas.** Consideración: atenuar (grises) conserva la lectura del territorio y muestra el contraste (dónde *no* hay lo filtrado), que suele ser el hallazgo. Pero decide con criterio y argumenta.
- **Contador visible:** `N de 1.251`.
- **Botón de limpiar filtros.**
- **Caso borde obligatorio:** si una combinación deja **cero** EE, el mapa debe decirlo con claridad (mensaje, no un mapa vacío sin explicación) y permitir deshacer.

### 3.5 Exportación

**SVG:** exporta la vista actual (con filtro aplicado). Los tiles del basemap son raster: si no pueden incrustarse, **dilo explícitamente** y exporta pins + contornos + leyenda, o propón alternativa. Documenta qué incluye y qué no.

**XLSX:** datos totales o filtrados según el estado de los filtros. Locale español (`;` separador, `,` decimal). Columnas: RBD, nombre, comuna, provincia, dependencia, **SLEP** (vacío si no aplica), macrogrupos, los 4 indicadores, serie 2016–2025. **Incluye los 17 sin geo** cuando el filtro los alcance (con "sin coordenadas"): existen aunque no se pinchen. SheetJS local, empacado, sin CDN.

### 3.6 Restricciones técnicas
- **PROHIBIDO localStorage / sessionStorage.** Estado en memoria (variables JS).
- CSS y JS locales o inline. Única dependencia externa admisible: los tiles.
- Rutas relativas (compatibles con subruta de GitHub Pages).
- Responsive razonable (notebook, no solo pantalla grande).
- Sin backend.

---

## 4. Publicación en `/docs`

```
docs/
  index.html
  assets/          (css, js, fuentes, logo)
  data/            (los 3 JSON, copiados desde 40_salidas/mapa_interactivo/web/data/)
```
Documenta cómo se sincroniza `40_salidas/` → `/docs` (script simple o instrucción de una línea; **NO toques `00_run_all.R`**). Verifica que las rutas funcionan servido desde subruta (`usuario.github.io/repo/`).

**No actives Pages tú.** Deja `/docs` listo e indica los pasos exactos al titular.

---

## 5. Puntos de detención (no los saltes)

1. **Tras leer los datos:** reporta el esquema real del GeoJSON (claves, tipos, cómo vienen macrogrupos, pares tipo-nivel y `slep`) + tu plan en 10 líneas + **la paleta propuesta con sus valores de contraste**. Espera OK.
2. **Tras mapa base + pins + hover + click + sparkline (sin filtros):** reporta con evaluación de densidad. **Hito visual crítico.** Espera revisión.
3. **Tras los 7 filtros:** reporta. Espera revisión.
4. **Tras exportación:** reporta.
5. **Auditoría (§6):** y recién entonces commits.

Si algo resulta técnicamente inviable como está especificado, **DETENTE y propón alternativa**. No lo resuelvas silenciosamente por otro camino.

---

## 6. AUDITORÍA (dos partes; ambas obligatorias)

### 6.A — AUDITORÍA DE ASIGNACIÓN SLEP (BLOQUEANTE DE PUBLICACIÓN)

**Contexto:** durante la recodificación ya ocurrió un bug de este tipo (`slep_nombre` asignado a EE particulares de comunas traspasadas; lo atrapó el gate compuesto). Es un patrón **demostrado**, no hipotético. Que un particular pagado aparezca como SLEP Costa Central en un mapa que ve un director destruye la credibilidad del producto entero.

**Verificación EXHAUSTIVA, RBD por RBD, no muestral, sobre los 1.251 del GeoJSON:**
1. Cada EE con `slep` no vacío: confirma que su `dependencia` es SLEP. **Cero excepciones.**
2. Cada EE con `dependencia` = SLEP: confirma que tiene `slep` con nombre válido de los 6.
3. **Ningún** particular (pagado o subvencionado), corporación delegada ni municipal-no-traspasado tiene `slep`. Recuento: debe ser **0**.
4. Los 343 con SLEP: confirma que el SLEP asignado corresponde a su comuna según `listado_slep_2026.xlsx`. RBD por RBD.
5. Desagregado exacto: Costa Central 73 · Valparaíso 54 · Aconcagua 67 · Marga Marga 58 · Petorca 55 · Los Andes 36 = 343.
6. Zapallar (4), Santo Domingo (6), del Litoral (48), Quillota (47): **todos municipales, ninguno con `slep`**.
7. Confirma que lo que muestra el **hover/popup del mapa** coincide con el GeoJSON (que el JS no esté reescribiendo la dependencia).

**Entregable:** `50_documentacion/andamios/auditoria_asignacion_slep_exhaustiva.md` con el recuento total y cualquier discrepancia. **Si aparece UNA sola discrepancia: DETENTE, no publiques, repórtala.**

### 6.B — AUDITORÍA FUNCIONAL ADVERSARIAL

`50_documentacion/andamios/auditoria_mapa_web.md`. Contra el artefacto real (abrir el HTML, no razonar sobre el código). **Intenta ROMPER tu propio trabajo**, no confirmar que funciona:

1. **Pins:** 1.251 contados. Colores correctos (cruza 6 EE conocidos, uno por SLEP, contra el GeoJSON).
2. **Hover:** formato exacto; decodificado; SLEP nombrado cuando corresponde; el pin se agranda.
3. **Click:** los 3 estados exhibidos con EE reales (normal: 1757 · cierre: 14439 · sin dato: 41707). Sparkline correcto en cada uno, con huecos NO dibujados como cero.
4. **Filtros — busca activamente combinaciones que rompan la lógica:**
   - Combinaciones que dejan **cero** EE (¿el mapa lo comunica o queda vacío y mudo?).
   - Cambiar Tipo de enseñanza **con un Nivel ya seleccionado** (¿el Nivel se resetea, o queda un filtro huérfano imposible?).
   - Seleccionar un EE en el combobox y **luego** aplicar un filtro que lo excluye (¿qué pasa?).
   - Filtro SLEP + Dependencia contradictorios (SLEP=Costa Central + Dependencia=Particular Pagado → cero, ¿se comunica bien?).
   - Limpiar filtros: ¿vuelve realmente al estado inicial (1.251) o quedan residuos?
   - Orden de aplicación distinto (Comuna→Provincia vs Provincia→Comuna): ¿mismo resultado?
   Documenta cada intento y su resultado. **Los que rompan se corrigen antes de cerrar.**
5. **Combobox:** búsqueda por nombre parcial, por RBD, y por texto que no matchea nada (¿degrada bien?).
6. **Contador:** N correcto tras cada filtro y tras limpiar.
7. **SVG:** refleja la vista filtrada. Qué incluye y qué no.
8. **XLSX:** abre el archivo. Locale español. Trae los filtrados (no todos) cuando hay filtro. Incluye sin-geo. Columna SLEP correcta.
9. **Sin browser storage:** grep `localStorage|sessionStorage` → 0.
10. **Rutas relativas:** funciona en subruta.
11. **Identidad visual:** fuentes gobCL/MuseoSans cargando; paleta coherente con el afiche.
12. **Accesibilidad:** contraste de los colores reportado con valores, no con adjetivos.

---

## 7. Commits (tras ambas auditorías)

1. `feat(web): mapa Leaflet con pins por SLEP, hover, detalle y sparkline`
2. `feat(web): siete filtros acumulativos con opciones dependientes y combobox`
3. `feat(web): exportacion SVG y XLSX de la vista filtrada`
4. `build(pages): estructura /docs para publicacion`
5. `docs(auditoria): auditoria exhaustiva de asignacion SLEP + auditoria funcional`

`git status` antes de cada add; nunca `git add -A`; `git ls-files` limpio.

---

## 8. Invariantes

🔒 `00_run_all`, `33`, `33b`, `31`, `32`, `10_*`, maestro, y `34`/`35`/`36` ya auditados.
🔒 Los 3 JSON: NO se regeneran ni editan en este encargo.
⚠️ No Python · No browser storage · Máximo 2 agentes · Nada de datos individuales.
🔴 **La auditoría 6.A es bloqueante: sin ella en verde, el mapa no se publica.**
