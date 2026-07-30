# Log — capa de educación parvularia R5 (pendiente N, fase 1)

**v1 · 2026-07-30.** Encargo: `50_documentacion/andamios/encargo_claude_code_parvularia_capa_v1.md`.
Decisión aplicada: **opción 2**, capa adicional del mapa regional vigente, apagada por
defecto, con carga diferida. Artefactos: `30_procesamiento/39_construir_capa_parvularia.R`,
`docs/data/parvularia_r5.geojson`, y el bloque de parvularia en `docs/assets/mapa.js`,
`docs/assets/estilo.css`, `docs/index.html`.

Toda cifra viene de un conteo programático de esta corrida: del script 39, del andamio
`diagnostico_parvularia_r5.R`, o del navegador sobre la capa montada.

---

## 0. Corrección al encargo: los códigos del área de monitoreo del §4.1 son erróneos

El §4.1 pide `en_area_monitoreo = TRUE` para **5101, 5107, 5109, 5801**, glosándolos como
"Viña, Concón, Puchuncaví, Quintero", y ordena verificarlos contra el dato. Verificados
(`distinct(COD_COM_ESTAB, NOM_COM_ESTAB)` sobre el CSV 2025):

| Código | Nombre en el dato | ¿Costa Central? |
|---|---|---|
| 5101 | VALPARAÍSO | **no** |
| 5103 | CONCÓN | sí |
| 5105 | PUCHUNCAVÍ | sí |
| 5107 | QUINTERO | sí |
| 5109 | VIÑA DEL MAR | sí |
| 5801 | QUILPUÉ | **no** |

Los **nombres** del encargo son los correctos; los **códigos** no. La capa usa
`c("5103","5105","5107","5109")`, que es el conjunto que corresponde a esos nombres y el
mismo que ya declara `COMUNAS_COSTA_CENTRAL` en `30_procesamiento/37_construir_capa_manzana.R`.
Con los códigos del encargo la marca habría incluido Valparaíso y Quilpué y excluido Concón
y Puchuncaví.

El §1 (universo esperado) **no** presentó contradicción: se reprodujo exacto (ver §3).

---

## 1. PASO 0.1 — ¿`ID_ESTAB` coincide con `RBD` en ORIGEN 1?

| Medida | Valor |
|---|---:|
| unidades de ORIGEN 1 | 938 |
| con `ID_ESTAB == RBD` (character, comparación exacta de valores) | **938** |
| que difieren | **0** |

`o1 <- r5 |> filter(ORIGEN == 1) |> distinct(ID_ESTAB, RBD); sum(o1$ID_ESTAB == o1$RBD)`

No se comparan conteos sino valores, uno a uno, ambos `character`. **Coinciden todos.**
Consecuencia para el front-end: unificar la llave es un **renombre**, no una tabla de
equivalencias. La reserva es que esto vale para ORIGEN 1; JUNJI e INTEGRA no tienen `RBD`
en absoluto, así que la llave común sigue siendo `ID_ESTAB`.

---

## 2. PASO 0.2 — las 4 unidades continentales fuera del bounding box

Point-in-polygon contra la cobertura comunal **nacional** de BCN (346 comunas,
`20_insumos/comunas_bcn/comunas.shp`), para distinguir "otra región" de "en el mar" sin
suponer:

| Comuna declarada | Origen / tipo | Niños | Coordenada observada | Dónde cae realmente |
|---|---|---:|---|---|
| LOS ANDES (5301) | 3 / 7 INTEGRA Adm. Directa | 26 | −30,39362 / −70,86971 | **Río Hurtado, Región de Coquimbo** |
| LOS ANDES (5301) | 3 / 7 INTEGRA Adm. Directa | 66 | −27,16129 / −109,43822 | **Isla de Pascua, Región de Valparaíso** |
| CALLE LARGA (5302) | 3 / 7 INTEGRA Adm. Directa | 15 | −30,38284 / −70,84556 | **Río Hurtado, Región de Coquimbo** |
| SAN FELIPE (5701) | 2 / 5 JUNJI Adm. Directa | 12 | −35,76134 / −70,72657 | **San Clemente, Región del Maule** |

| Descarte | Resultado |
|---|---:|
| ceros exactos (centinela) | 0 |
| coordenadas repetidas entre ellas (centinela) | 0 |
| en el mar (sin comuna que las contenga) | 0 |

**Las cuatro caen en tierra firme, en comunas reales, a cientos de kilómetros de la comuna
declarada.** No son centinelas ni caídas al mar: son **coordenadas erróneas** (o comuna
errónea; el dato no permite decidir cuál de las dos está mal). Se tratan como sin
georreferencia y quedan fuera de la capa, declaradas una a una en el script.

---

## 3. Hito A — la capa de dato

`30_procesamiento/39_construir_capa_parvularia.R` → `docs/data/parvularia_r5.geojson`.

### 3.1 Universo y cuadratura

| Medida | Valor | Origen de la cifra |
|---|---:|---|
| filas R5 (nivel persona, solo en memoria) | 65.771 | log del script 39 |
| continentales (insulares descartadas) | 65.435 | idem (336 insulares) |
| unidades continentales | 1.337 | §1 del encargo, **reproducido** |
| excluidas por falta de coordenada usable | **8** (177 niños) | idem, **reproducido** |
| **features escritas** | **1.329** | idem, **reproducido** |
| suma de `matricula_total` | **65.258** | idem |
| conteo directo de filas (sin pasar por la agregación) | **65.258** | idem |
| **diferencia** | **0** | guardia de cuadratura del script |
| unidades con `en_area_monitoreo = TRUE` | 233 | idem |

Las 233 del área de monitoreo son las 234 medidas en la fase 0 **menos una**: una unidad de
Viña del Mar (INTEGRA Adm. Directa, coordenada ausente, 15 niños) está entre las 8
excluidas. Verificado, no es descuadre.

### 3.2 Desglose por nivel — es una medición

Columna elegida: **`NIVEL2`**. Es la clasificación **armonizada** en 3 niveles que MINEDUC
publica para los tres orígenes (ER oficial pág. 3: 1 Sala Cuna · 2 Medio · 3 Transición).

| Columna candidata | origen 1 | origen 2 | origen 3 | Sirve |
|---|---:|---:|---:|---|
| **`NIVEL2`** | 42.344 | 16.533 | 6.894 | **sí, los tres** |
| `COD_ENSE2_M` | 42.344 | 0 (NA) | 0 (NA) | no, solo MINEDUC |
| `COD_PROG_J` | 0 (NA) | 16.533 | 0 (NA) | no, solo JUNJI |
| `COD_MODAL_I` | 0 (NA) | 0 (NA) | 6.894 | no, solo INTEGRA |

NA en `NIVEL2`: **0 en los tres orígenes** (0,000 %). Las tres candidatas que proponía el
encargo son códigos de **programa/modalidad** propios de cada origen, no de nivel: cada una
existe solo en su propio origen y no permite el desglose transversal.

Regla de mapeo: `mat_sala_cuna = sum(NIVEL2 == 1)`, `mat_medio = sum(NIVEL2 == 2)`,
`mat_transicion = sum(NIVEL2 == 3)`. **Ningún origen quedó sin desglose**, así que no hubo
que poner `NA` ni imputar nada. El script incluye una guardia que aborta si el desglose no
reconstituye `matricula_total` en alguna unidad (medido: 0 unidades descuadradas).

### 3.3 Guardias permanentes del script

1. **Atributos no constantes dentro de una llave** (`NOM_ESTAB`/`TIPO_ESTAB`): aborta, porque
   `first()` elegiría un valor arbitrario. No se disparó.
2. **Desglose que no suma el total**: aborta. No se disparó.
3. **`TIPO_ESTAB` fuera de la glosa {1..8}**: aborta, señal de que el ER quedó desactualizado.
   No se disparó.
4. **Unidad sin coordenada y con matrícula > 0 que no esté en la lista declarada**: aborta
   nombrando cuántas son y cuántos niños representan. **No se disparó**: las 8 conocidas
   están en `UNIDADES_SIN_GEO_CONOCIDAS`, una a una y con el motivo al lado.
5. **Cuadratura** contra el conteo directo de filas: aborta si difiere. Diferencia 0.

### 3.4 Auditoría del artefacto, releído desde disco

No se audita el objeto en memoria: se **relee el GeoJSON con `jsonlite`**, como lo verá el
JS. El proyecto ya se quemó dos veces con `jsonlite` (NULL serializado como `{}`, arreglos
de un elemento desempaquetados a escalar).

| Comprobación | Resultado |
|---|---|
| features | **1.329** |
| campos por feature | **12**, idénticos en todas (ninguna con campos faltantes) |
| campos | cod_comuna, comuna, en_area_monitoreo, id_estab, mat_medio, mat_sala_cuna, mat_transicion, matricula_total, nombre, origen, tipo_estab, tipo_glosa |
| clase de `id_estab` | **character** |
| clase de `cod_comuna` | **character** |
| clase de `matricula_total` | integer |
| clase de `en_area_monitoreo` | logical |
| suma `matricula_total` | **65.258** |
| coordenadas vacías | **0** |
| features con algún campo `NULL`/`{}` | **0** |
| tipo de geometría | Point (único) |
| CRS | ninguno declarado ⇒ RFC7946, WGS84 implícito (EPSG:4326) |

---

## 4. Hito B — el toggle en el front-end

### 4.1 Lo construido

- **Toggle propio e independiente** del selector del Censo, apagado por defecto, con carga
  diferida y cacheada en memoria (`S.parvularia.cache`), reusando el patrón del hito 4
  (mismo indicador de carga `indicadorCargaCenso`). Verificado en vivo: con parvularia
  encendida se puede encender además la capa de asistencia del Censo, y ambas conviven.
- **Pane `parvularia`, zIndex 390.** Verificado en vivo: censo 330 < máscara 350 <
  frontera 370 < **parvularia 390** < pines 400.
- **Renderer Canvas.** 1.329 marcadores, el mismo orden de magnitud que los 1.251 pines que
  ya corren en Canvas. Costo de dibujo medido en el Chrome del preview: `_redraw()` completo
  **mediana 0,10 ms, p90 0,20 ms, máximo 0,50 ms** (50 repeticiones).
- **Popup** con nombre, glosa del tipo, comuna, matrícula total y desglose por nivel.
- **Leyenda propia** con el símbolo real (el anillo), no un cuadrito.

### 4.2 El marcador: anillo, no disco

El encargo pide radio menor **y forma distinta**. Radio: `radioBase(z) − 1,6` con piso 2,4
(a z14: **3,9 px** contra **5,5 px** del pin), y sigue el mismo escalado por zoom para que la
jerarquía no dependa de la escala. Forma: **anillo de centro blanco** contra el **disco pleno
con aro blanco** de los establecimientos escolares.

La primera versión usaba relleno translúcido del mismo color (`fillOpacity 0,20`). Mirado
renderizado a z14, el agujero medía ~1,5 px de diámetro y el anillo volvía a leerse como un
disco pálido, que es exactamente lo que había que evitar. El centro blanco abre el anillo de
verdad y además reusa el aro blanco que ya llevan los pines, así que no introduce un
elemento visual ajeno.

### 4.3 Color — PROPUESTA, no aprobada

Para `TIPO_ESTAB` 1–4 se **reutilizan las constantes vigentes**, leídas de `mapa.js`:

| Tipo | Constante reusada | Hex |
|---|---|---|
| 1 Escuela Municipal | `PAL_DEP['Municipal']` | `#496524` |
| 2 Escuela Part. Subvencionado | `PAL_DEP['Particular Subvencionado']` | `#A6741C` |
| 3 Escuela Part. Pagado | `PAL_DEP['Particular Pagado']` | `#7A4A8A` |
| 4 Escuela SLEP | `COLOR_INSTITUCIONAL` | `#0D2E52` |

Para JUNJI (5, 6) e INTEGRA (7, 8) **no existe constante previa**, porque no están en el
directorio escolar. Los dos tonos son **propuesta a decidir por el titular**, y viven en dos
constantes nombradas al inicio del bloque (`COLOR_PROPUESTO_JUNJI`,
`COLOR_PROPUESTO_INTEGRA`), cambiables en una línea:

| Institución | Hex propuesto | Razón |
|---|---|---|
| JUNJI (5, 6) | **`#C2552F`** | terracota. La paleta vigente ocupa verde, ocre, violeta y toda la banda azul-cian-turquesa de los SLEP; la banda rojo-naranja está libre y no colisiona con ninguna constante existente. |
| INTEGRA (7, 8) | **`#A32C58`** | carmín. Más rojo y más oscuro que el violeta `#7A4A8A` del particular pagado, que es el vecino más cercano en la paleta. |

El color codifica **institución**, no subtipo: 5 y 6 comparten tono (JUNJI), 7 y 8 comparten
tono (INTEGRA). La leyenda los agrupa así.

**Salvedad sobre el tipo 4.** `COLOR_INSTITUCIONAL` (`#0D2E52`) es el mismo valor al que
resuelve `PAL_SLEP['Costa Central']`. Es decir: un jardín de escuela SLEP de cualquier SLEP
se pinta con el azul que en la leyenda de pines significa *SLEP Costa Central*. La fuente
trae `NOMBRE_SLEP` y permitiría colorear por SLEP como hacen los pines, pero eso excede el
esquema de campos que fija el §4.1 del encargo. Lo dejo declarado, no resuelto.

### 4.4 Regla de omisión del popup

El encargo pide que el popup omita la línea del desglose y que no muestre "NA" **ni un
cero**. Implementado literal: se omite la línea cuando el valor es `null` (origen sin
desglose) **y también cuando es 0** (la unidad no imparte ese nivel). No se oculta
información: la cifra de arriba es el total, y la guardia del script garantiza que los tres
niveles suman ese total, así que con `matricula_total > 0` siempre queda al menos una línea.
Verificado en vivo sobre la función pura: una escuela municipal con solo transición muestra
una sola línea; forzando los tres a `null`, el bloque desaparece entero.

---

## 5. Defecto encontrado y corregido durante el Hito B

**Las capas devueltas por `pointToLayer` no heredan `pane` ni `renderer` del `L.geoJSON`.**
La primera versión pasaba ambos como opciones del `L.geoJSON`, que es lo que uno esperaría,
y los 1.329 `circleMarker` terminaron en el `overlayPane` (400), mezclados con los pines del
directorio: el orden z que el encargo exige no se cumplía. No se veía en la pantalla —los
marcadores se dibujaban igual— y la comprobación que lo delató fue contar los hijos del pane:
`getPane('parvularia').children` devolvía **0**. Corregido pasando `pane` y `renderer` en las
opciones de cada `circleMarker`. Verificado después: 1 `<canvas>` en el pane, y los 1.329
marcadores con `options.pane === 'parvularia'` y el renderer propio.

Es el mismo tipo de defecto que el encargo advierte para `jsonlite`: lo que se ve bien no
prueba que sea correcto, y hay que auditar desde donde se consume.

---

## 6. Deuda declarada

**El script 39 NO está registrado en `00_run_all.R`.** El encargo lo prohíbe explícitamente
porque el registro pertenece a la decisión del **pendiente D** (grupos de pasos del
orquestador), que sigue abierta. Mientras tanto la capa se regenera a mano:

```
Rscript 30_procesamiento/39_construir_capa_parvularia.R
```

La cabecera del propio script lleva esa deuda escrita, para que no dependa de que alguien
lea este log.

---

## 7. Lo que no medí

1. **FPS reales del pan y el zoom con la capa encendida.** El panel del navegador corre
   oculto en esta sesión (`document.visibilityState === "hidden"`) y Chrome estrangula
   `requestAnimationFrame` ahí. Medí el costo sincrónico de `_redraw()` (0,10 ms de mediana),
   que no incluye la rasterización GPU. La decisión de renderer no dependía de esa cifra:
   1.329 marcadores es el mismo orden que los 1.251 pines que ya corren en Canvas.
2. **Comportamiento de los 7 filtros sobre la capa nueva.** Los filtros no la tocan, igual
   que no tocan las capas del Censo. No verifiqué qué debería pasar si el usuario filtra por
   comuna con la capa encendida: hoy la capa no reacciona. No está pedido, pero es una
   asimetría visible.
3. **Exportación SVG y XLSX con la capa encendida.** No las probé. `construirSVG()` se arma
   desde `S.ee`/`S.frontera`/`S.rotulos` y no lee las capas del mapa, así que por
   construcción excluye parvularia, pero eso es lectura de código, no medición.
4. **Rendimiento con parvularia y una capa del Censo encendidas a la vez.** Verifiqué que
   conviven y se dibujan; no medí el costo combinado.
5. **Si la coordenada errónea de las 4 unidades del §2 está en la coordenada o en la comuna
   declarada.** El dato no permite decidirlo sin una fuente externa.
6. **Años distintos de 2025.** La capa es un corte, no una serie. `LATITUD`/`LONGITUD` y
   `TIPO_ESTAB` no existen antes de 2019 y 2019 respectivamente, así que una serie
   georreferenciada hacia atrás no es una extensión trivial de este script.
7. **Accesibilidad del par de colores propuesto** (contraste y distinguibilidad para daltonismo).
   La paleta vigente del proyecto sí tiene ese trabajo hecho (reporte de la sesión 2b); los
   dos tonos nuevos son propuesta y no lo tienen.
