# Auditoría funcional adversarial — mapa web (§6.B)

- **Fecha:** 2026-07-12
- **Auditor:** Claude Code (sesión mapa web, hito auditorías)
- **Método:** contra el **artefacto real** (mapa servido y abierto en navegador; eventos de UI
  reales, popups abiertos en el DOM), no razonando sobre el código. Los valores esperados de
  series e indicadores se derivaron de un **fetch fresco del JSON crudo** con lógica propia
  independiente del `mapa.js` (regla aprendida con los bugs de `{}` vs `null` y de
  `auto_unbox`: auditar desde el consumidor, contra la fuente).
- **Consola del navegador:** 0 errores durante toda la batería (raíz y subruta).

## Veredicto

**VERDE.** Los 12 puntos del encargo pasan. Dos hallazgos menores detectados y corregidos
durante el desarrollo del hito 4 (ya en el código auditado): comillas inválidas en
`font-family` que rompían el XML del SVG, y redacción del pie del SVG que decía "cumplen el
filtro" sin filtro activo. Un desvío documentado del guion: el caso "sin dato" del punto 3.

## Resultados por punto

### 1. Pins — VERDE
`__M.S.marcadores.size == 1251` == features del GeoJSON crudo. Colores verificados para 1 EE
por SLEP contra la paleta y el `slep` del crudo: 12171 → `#0D2E52` (Costa Central), 12146 →
`#155B8F` (Valparaíso), 11191 → `#0E7CB0` (Aconcagua), 1194 → `#0995B5` (Los Andes), 11231 →
`#1A9384` (Marga Marga), 11196 → `#1F8FD0` (Petorca). 6/6 exactos.

### 2. Hover — VERDE
Formato del tooltip verificado **exhaustivamente para los 1.251 pins** contra el crudo
(nombre decodificado, `RBD n`, comuna, dependencia; "Servicio Local de Educación {slep}"
cuando corresponde): 0 discrepancias (detalle en `auditoria_asignacion_slep_exhaustiva.md`,
chequeo 7). El pin se agranda con evento real: radio 4,5 → 9,0 en hover y vuelve a 4,5.

### 3. Click (3 estados) — VERDE, con nota
| Estado | RBD | Resultado contra el crudo |
|---|---|---|
| Normal | 1757 | Indicadores 2.339 / 2.352 / 2.488 (2019) / 1.997 (2016) == recomputados de la serie cruda (máx/mín exactos; promedio a ±0,5 por redondeo). Sparkline: 10 círculos = 10 años con dato, 1 polilínea = 1 tramo contiguo, 0 ticks de hueco. |
| Cierre | 14439 | "Sin matrícula en 2025. Registró matrícula hasta **2022**" == último año con dato del crudo. Sparkline: 7 círculos = 7 datos, **3 ticks = 3 huecos (no dibujados como cero)**, 1 polilínea (serie contigua 2016–2022). Máx 109 (2017) y mín 34 (2021) recomputados ✔. |
| Sin dato | **11188** | "Sin registros de matrícula en la ventana 2016–2025", 4 indicadores en literal ("Sin matrícula en 2025." / "sin dato" ×3), **sin sparkline** (correcto: serie 100 % nula). |

**Nota:** el encargo citaba RBD 41707 como caso "sin dato", pero 41707 es uno de los 17 **sin
geo** y no tiene pin clickeable (por diseño; sí aparece en el XLSX). El estado se exhibió con
el pin 11188 (hay 43 pins en esa condición). En el crudo, los huecos son `null` reales (no
`{}`): la regeneración de hito 2 sigue sana.

### 4. Filtros adversariales — VERDE (6/6 intentos, ninguno rompe)
| Intento | Resultado |
|---|---|
| SLEP Costa Central + Dependencia Particular Pagado (contradictorio) | Contador "0 de 1.251" + mensaje "Ningún establecimiento cumple esta combinación de filtros." + botón "Limpiar filtros". Nunca mapa vacío y mudo. |
| Cambiar Tipo con Nivel ya elegido (TP + "1° medio" → Parvularia) | `F.nivel` se **resetea a null**; el select de Nivel se reconstruye con los niveles del nuevo tipo (Kínder, Nivel Medio…). Sin filtro huérfano. |
| EE del combobox (1757, Quilpué) + Comuna=Valparaíso que lo excluye | "0 de 1.251" + mensaje de cero; el chip del EE persiste; al quitar la comuna vuelve "1 de 1.251". Comportamiento comunicado, sin estado corrupto. |
| Limpiar filtros tras combinación múltiple | "1.251 de 1.251", los 5 selects en "Todas/Todos", `F` todo null, Nivel oculto, sin mensaje de cero. Sin residuos. |
| Orden de aplicación (Provincia→Comuna vs Comuna→Provincia, Casablanca) | "22 de 1.251" en ambos órdenes y **conjunto idéntico de RBD coincidentes** (comparación elemento a elemento). `cumple()` es función pura del estado. |
| Facetas (con Comuna=Casablanca) | Solo la provincia Valparaíso habilitada; las otras 6 deshabilitadas (opciones calculadas sobre el subconjunto que cumple los demás filtros). |

### 5. Combobox — VERDE
"champa" → 1 ítem (Colegio Champagnat, RBD 11176); "1757" → 1 ítem por RBD (Colegio
Aconcagua); "zzzyqx" → 0 ítems con mensaje "Sin coincidencias con los filtros vigentes.";
"escuela" → 30 visibles + "478 coincidencias más: sigue escribiendo para acotar."

### 6. Contador — VERDE
Correcto tras cada operación de la batería: 1.251 inicial, 171 (Comuna=Valparaíso), 45
(Media TP + 1° medio), 22 (Casablanca), 0 (contradictorio), 1 (EE puntual), 1.251 tras
limpiar (verificado en cada fila del punto 4).

### 7. SVG — VERDE
Refleja la vista filtrada: exporta el encuadre y zoom vigentes con coincidentes plenos
ENCIMA y no coincidentes atenuados (`#c9c4bb`), subtítulo con filtro y N ("171 de 1.251 …
Filtro — Comuna: Valparaíso"), leyenda solo con categorías presentes en la vista (+ entrada
"No cumple el filtro aplicado" cuando hay filtro). **Incluye:** pins, frontera Costa Central,
frontera regional, rótulos de comuna, leyenda, título, atribución — todo vectorial, XML
válido (verificado con parser externo y render en navegador). **NO incluye:** el fondo
raster de tiles CARTO (declarado en el pie del propio archivo) ni fuentes incrustadas (usa
Museo Sans/gobCL con fallback sans-serif). Los 17 sin-geo no figuran (el pie lo declara y
remite al XLSX).

### 8. XLSX — VERDE
Ambos archivos abiertos con parser XML independiente (zip + `sheet1.xml`) **y validados por
el titular en Excel/Numbers** (hito 4): sin filtro 1.268 filas (= contador 1.251 + 17 sin
geo); con Comuna=Valparaíso 175 filas (= contador 171 + 4 sin geo de esa comuna, RBD 41908,
41912, 42085, 42186 con "sin coordenadas"). Locale: 0 números guardados como texto; 17.844
celdas numéricas nativas (Excel/Numbers en español muestra punto de miles y coma decimal;
XLSX no guarda separadores — garantía equivalente aceptada por el titular). Literales tal
cual el JSON. Columna SLEP auditada RBD por RBD en 6.A (chequeo 8): 0 discrepancias.

### 9. Sin browser storage — VERDE
`grep -c 'localStorage|sessionStorage'` sobre `index.html`, `estilo.css`, `mapa.js`: **0, 0,
0**. Vendor (`leaflet.js/.css`, `xlsx.full.min.js`): sin coincidencias. Estado 100 % en
memoria (`S`, `F`).

### 10. Rutas relativas / subruta — VERDE
Cero rutas absolutas locales en el código propio (grep). Servido desde **subruta**
(`http://localhost:8874/docs/`, análogo a `usuario.github.io/repo/`): la página carga
completa — tiles, 1.251 pins, fuentes, JSON — con 0 errores de consola y 0 requests
fallidos.

### 11. Identidad visual — VERDE
`document.fonts.check` en el artefacto vivo: gobCL 900 ✔, gobCL 400 ✔, Museo Sans 300 ✔,
Museo Sans 500 ✔ (los 4 `.otf` locales cargando). Paleta de página idéntica a la del afiche
(papel `#FFFFFF`, página `#EAE6DC`, ciruela `#4A2746`, tintas), pins con paleta azul SLEP +
dependencias del hito 2b.

### 12. Contraste con valores (WCAG 2.x, ratio de luminancia) — VERDE
Pins (relleno) contra borde blanco del pin y contra el tono de suelo del tile Positron
(`#F2F0EB`); umbral no-texto WCAG 1.4.11 = 3,0:1:

| Categoría | Hex | vs blanco | vs tile |
|---|---|---|---|
| SLEP Costa Central | `#0D2E52` | 13,73:1 | 12,05:1 |
| SLEP Valparaíso | `#155B8F` | 7,18:1 | 6,30:1 |
| SLEP Aconcagua | `#0E7CB0` | 4,64:1 | 4,07:1 |
| SLEP Los Andes | `#0995B5` | 3,51:1 | 3,08:1 |
| SLEP Marga Marga | `#1A9384` | 3,78:1 | 3,32:1 |
| SLEP Petorca | `#1F8FD0` | 3,56:1 | 3,13:1 |
| Municipal | `#496524` | 6,62:1 | 5,82:1 |
| Particular Subvencionado | `#A6741C` | 4,09:1 | 3,59:1 |
| Particular Pagado | `#7A4A8A` | 6,62:1 | 5,81:1 |
| Corp. Adm. Delegada | `#B08122` | 3,49:1 | 3,07:1 |

Todos ≥ 3,0:1 en ambos fondos. Textos: tinta 18,35:1 y ciruela 12,58:1 (AAA), bajada 7,21:1
(AA texto normal); muted 3,01:1 reservado a notas auxiliares. Distancia perceptual mínima
entre los 6 azules SLEP: ΔE(CIE76) = 10,1 (Aconcagua vs Petorca, que además nunca conviven
en una misma comuna); la separación fina por ΔE2000 quedó verificada en el reporte de la
paleta 2b. La similitud deliberada subvencionado/corporación (`#A6741C`/`#B08122`) está
documentada en el código como decisión.

## Extras fuera del guion

- **Cero resultados en la exportación:** con filtro contradictorio, el XLSX genera solo la
  cabecera (`A1:W1`) y el SVG sigue siendo válido; nombre de archivo refleja el filtro.
- **Carga diferida de SheetJS:** no se descarga en la carga inicial; primer clic en XLSX la
  trae del vendor local (`200 OK`, nunca CDN).
- **Botones de exportación:** clicks reales sin errores; el botón XLSX se deshabilita
  durante la generación.
