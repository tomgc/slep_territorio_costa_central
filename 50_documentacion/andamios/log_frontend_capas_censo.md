# Log — front-end de las capas del Censo 2024 (Hito 4)

**Fecha:** 2026-07-12 · **Sesión 12, Hito 4.** Front-end de las dos capas del Censo sobre
el mapa interactivo. Archivos tocados: `docs/index.html`, `docs/assets/estilo.css`,
`docs/assets/mapa.js`. No se tocó `30_procesamiento/`, `00_run_all.R`, ni `docs/data/`.
Verificado en navegador (Chrome vía preview) sobre `docs/` servido en localhost.

---

## 1. Lo construido

- **Bloque "Capas del Censo"** en el panel, ARRIBA de la Leyenda: selector de 3 estados
  mutuamente excluyentes **Ninguna / Densidad / Asistencia**, + sub-selector (tramo de
  edad para densidad, nivel para asistencia), + leyenda propia + nota metodológica.
- **Densidad** (manzana, Costa Central): coropleta por conteo del tramo elegido (básica
  por defecto). Renderer **Canvas**. Popup con los 3 conteos por manzana.
- **Asistencia** (zona urbana ∪ localidad rural, región continental): coropleta por
  `proporcion_asistencia_<nivel>` con **tres estados visuales** (ver §3). Popup con
  conteos + proporción rotulada + advertencia por estado, sin cifra comunal del INE.
- **Carga diferida y cacheada**, indicador de carga en vuelo, encuadre automático,
  leyenda conmutable. Los 7 filtros de establecimientos NO tocan estas capas.

---

## 2. Cortes de las rampas — MEDIDOS, no inventados

Cuantiles 20/40/60/80 sobre el dato real del artefacto (`/tmp/censo_front_cortes.R`):

**Densidad — conteo > 0 por tramo:**
| Tramo | n>0 | cortes (q20/40/60/80) | max |
|---|---:|---|---:|
| `n_edad_0_5` | 3 744 | **1, 2, 4, 6** | 165 |
| `n_edad_6_13` | 4 279 | **2, 4, 6, 11** | 283 |
| `n_edad_14_17` | 3 865 | **1, 2, 4, 6** | 126 |

**Asistencia — proporción fiable (den ≥ 20) por nivel:**
| Nivel | n(fiable) | cortes | min–max |
|---|---:|---|---|
| parv | 821 | **0,449 / 0,497 / 0,533 / 0,576** | 0,192–0,731 |
| basica | 912 | **0,927 / 0,943 / 0,955 / 0,966** | 0,714–1,000 |
| media | 793 | **0,825 / 0,855 / 0,879 / 0,907** | 0,605–1,000 |

Rampa monocroma azul de baja saturación (matiz fijo, luminosidad decreciente):
`#cdd8e4 · #a7bacf · #7f9cba · #5980a4 · #33628c`, `fillOpacity 0,45`, **sin bordes**.

---

## 3. Los tres estados de la capa de asistencia (tres tratamientos distintos)

| Estado | Condición | Tratamiento visual | Entrada de leyenda |
|---|---|---|---|
| **fiable = TRUE** | den ≥ 20 | rampa azul (5 clases) | por clase de proporción |
| **fiable = FALSE** | 0 < den < 20 | **gris sólido** `#9a9488` @0,42, fuera de la rampa | "Denominador insuficiente (menos de 20 niños)" |
| **fiable = NA** | den = 0 | **hueco: solo contorno** `#b9b3a7`, sin relleno | "Sin población en edad para el nivel" |

Los tres son distintos y **ninguno es el mismo gris**: azul / gris sólido / hueco.
Verificado en el artefacto (leyenda + mapa) y en los popups (HTML leído en vivo):

- **TRUE** (`540101001`, La Ligua): den 346, asisten 338, "Proporción del grupo en edad
  oficial que asiste al nivel" **97,7%**.
- **FALSE** (`540106001`): den 11, asisten 11, **100%** + aviso "Denominador insuficiente
  (menos de 20 niños en edad básica): la proporción es ruidosa. Los conteos de arriba sí
  son exactos."
- **NA** (`540105002`): den 0, "Sin población en edad para básica".

El popup distingue `tipo_unidad`: "Zona urbana" (urbano) / "Localidad rural" (rural).

---

## 4. Panel adversarial (evidencia)

1. **¿Versión en disco o recordada?** En disco. El sidebar mide **270px**
   (`.panel-lateral { width: 270px }`). La **máscara invertida** es un solo polígono
   (anillo exterior = mundo `[[-180,-85]…]`, anillos interiores = contorno regional; regla
   par-impar → agujeros) que vela todo lo NO-región con `#EAE6DC` a opacidad **0,72**
   (`geojsonMascara` + `OPACIDAD_MASCARA`). Los filtros están en una barra horizontal, no
   en el panel; el footer fue eliminado y la atribución vive al pie del panel.
2. **¿"tasa neta" en texto visible?** `grep -rni "tasa neta" docs/` → **1 sola** línea
   (mapa.js:949), la nota de leyenda que **niega** el término: *"No es la tasa neta del
   INE; el popup de una unidad no muestra la cifra comunal."* El indicador se rotula
   siempre "proporción del grupo en edad oficial que asiste al nivel". Declarar la
   discrepancia es lo que exige el contrato §3.4.
3. **¿Tres tratamientos distintos?** Sí (§3): rampa azul / gris sólido / hueco-contorno.
   Ninguno comparte gris. Verificado en leyenda, mapa y popups.
4. **¿El cero de densidad fuera de la escala, con entrada propia?** Sí: `n_edad == 0`
   → gris neutro `#b0aaa0` @0,42, NO usa color de rampa, y tiene entrada de leyenda "Sin
   población en edad". La proporción/valor no se omite ni se marca NA de forma engañosa.
5. **¿Coropleta DEBAJO de los pines?** Sí. zIndex de panes verificado en vivo:
   **censo 330** < **mascara 350** < **frontera 370** < **pines 400** (overlayPane) <
   rótulos-comuna 420. El pane 'censo' tiene la capa (1 canvas hijo).
6. **¿Al pasar de Densidad a Ninguna/Asistencia vuelve al defecto?** Sí. Lógica verificada
   espiando `fitBounds` en las 5 transiciones: Ninguna→Densidad = Costa Central
   (−32,85,−71,49); Densidad→Asistencia = **boundsDefecto**; Asistencia→Densidad = Costa
   Central; Densidad→Ninguna = **boundsDefecto**; Ninguna↔Asistencia = **sin mover**.
   (Nota: el `fitBounds` con `animate:true` no renderiza el movimiento en el harness
   automatizado —el `fitBounds` existente de los filtros falla idéntico en el mismo
   entorno—; para usuarios reales `animate:true` funciona, como ya funciona en filtros. La
   lógica —qué bounds recibe cada transición— es la verificada.)
7. **¿Cortes del dato o inventados?** Del dato (§2), cuantiles medidos sobre el artefacto.
8. **¿Carga diferida y cacheada? ¿Indicador visible?** Sí. El fetch ocurre al primer
   encendido de cada capa; verificado que tras encender ambas el cache tiene
   `["densidad","asistencia"]` y apagar/reencender NO re-descarga. Indicador
   `censo-cargando` (píldora con spinner) mientras el fetch está en vuelo.
9. **Huecos del 0,2–4,7 % y colapsadas de Concón: ¿cómo se ven?** (descrito en §5).
10. **¿SVG sigue funcionando con una capa encendida?** Sí. Con Densidad activa,
    `construirSVG()` devuelve SVG válido (211 129 chars, empieza `<?xml`), **sin** la capa
    del Censo y **sin** "tasa neta". No hizo falta arreglarlo: `construirSVG` se arma desde
    `S.ee`/`S.frontera`/`S.rotulos`, no lee las capas del mapa, así que las excluye por
    construcción.

---

## 5. Pregunta abierta: cómo SE VEN los huecos (descripción, sin proponer solución)

**Asistencia — el 0,2–4,7 % rural no cubierto.** Observado en Quintero/Puchuncaví (z12):
la unión Zonal ∪ Localidades cubre casi todo el territorio comunal. Las grandes
localidades rurales aparecen en **gris "denominador insuficiente"** (tan-gris), y las
zonas urbanas en la rampa azul. Los huecos reales no cubiertos se ven como **slivers finos
y claros a lo largo de los bordes compartidos** entre polígonos, más algún **parche
pequeño** en los intersticios rurales — NO como agujeros blancos grandes dentro de las
comunas. **Matiz importante que debes decidir tú:** el gris de "denominador insuficiente"
(`#9a9488` @0,42) y el fondo Positron/papel entre polígonos son tonos cercanos; a veces
cuesta distinguir "gris = hay dato pero ruidoso" de "claro = no hay polígono (hueco)". No
propongo solución; lo reporto.

**Densidad — el 9,76 % de manzanas colapsadas de Concón (todas 0 niños, ya auditado).**
Observado en Concón (z16) y Viña (z15): la coropleta tesela densamente el tejido urbano.
Las colapsadas se leen como **celdas más claras interspersas** entre manzanas pobladas, no
como huecos blancos evidentes, porque son paños pequeños y no residenciales repartidos
entre bloques con población. A escala de Costa Central (z10–12) son imperceptibles. El
único vacío grande y legítimo es no-manzana (el aeródromo de Concón, sin amanzanamiento).

---

## 6. Detalles de implementación

- Pane `censo` creado en `montar()` con zIndex 330. Renderer dedicado
  `L.canvas({ pane: 'censo' })`.
- Estado en `S.censo = { modo, tramo, nivel, cache, capa, renderer }`.
- Coropleta sin bordes (`stroke:false`) salvo el estado hueco (contorno 0,6px). Opacidad
  máxima 0,45: es fondo.
- `NOMBRE_COMUNA` (CUT→nombre, 38 comunas R5) para el popup; el geojson solo trae CUT.
- La leyenda de dependencias del panel **permanece** con una capa del Censo activa (los
  pines siguen); la del Censo se agrega en su bloque propio.
