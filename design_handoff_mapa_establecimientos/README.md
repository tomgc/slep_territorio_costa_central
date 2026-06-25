# Handoff: Mapa de establecimientos — SLEP Costa Central

## Overview
Pieza **impresa, estática** (no interactiva) que mapea los establecimientos educacionales
administrados por el **Servicio Local de Educación Pública (SLEP) Costa Central**, sobre el
litoral de cuatro comunas de la Región de Valparaíso: **Puchuncaví, Quintero, Concón y
Viña del Mar** (orden norte → sur).

Es un afiche en formato **vertical (retrato)** pensado para imprimirse en grande. Cada
establecimiento tiene un **número de referencia** que aparece tanto en una **lista lateral**
(izquierda) como sobre el **mapa** (derecha). La lista segmenta los establecimientos por tipo
de enseñanza con un código de color. Está diseñada con criterio de **bajo consumo de tinta**:
papel blanco, sin grandes fondos de color, y el color saturado vive solo en los pequeños
números de referencia.

Diferenciación clave del mapa:
- En las zonas **dispersas** (Puchuncaví, Quintero, Concón) cada punto se rotula con una
  **tarjeta**: número + nombre completo + **(RBD)**.
- En **Viña del Mar**, que es el clúster más denso, los puntos se muestran como un **racimo de
  números** sin tarjeta; se identifican por la lista lateral.

## About the Design Files
Los archivos de este bundle son **referencias de diseño hechas en HTML** — prototipos que
muestran el aspecto y comportamiento buscados, **no código de producción** para copiar
directamente. La tarea es **recrear este diseño en el entorno del codebase destino** (React,
Vue, etc.) usando sus patrones y librerías establecidos. Si no existe un entorno aún, elegir
el framework más apropiado e implementarlo ahí.

Los `.dc.html` son "Design Components": HTML con plantilla declarativa (`{{ }}`, `<sc-for>`,
`<dc-import>`) más una clase de lógica JS. **Ignora esa sintaxis de framework propietario** —
úsala solo para leer estructura, estilos y datos. Toda la presentación está en estilos en línea
con valores literales (ver Design Tokens).

## Fidelity
**Alta fidelidad (hifi).** Colores, tipografía, espaciado y medidas son finales. El afiche está
pensado a un tamaño de lienzo fijo de **1240 × 1754 px** (proporción ~A-series retrato). Recréalo
con fidelidad de píxel. Como es para impresión, la salida ideal es **PDF a ese tamaño** (o
escalado proporcional a A2/A1).

## Screens / Views

### Vista única — Afiche "Mapa de establecimientos"
- **Propósito**: documento impreso de referencia territorial; ubicar y listar los establecimientos
  del SLEP por comuna y tipo.
- **Lienzo**: `1240 × 1754 px`, fondo `#FFFFFF`, centrado sobre un fondo de página `#EAE6DC`.
  Layout en **columna** (flex-direction: column): header / cuerpo / footer.

**1. Header** (altura `190px`, `flex:none`)
- `display:flex; align-items:center; gap:34px; padding:0 56px;`
- Borde inferior `2px solid #4A2746` (ciruela).
- Logo a color (`assets/logo-color-stacked.png`), `height:134px; width:auto`.
- Divisor vertical: `1px × 104px`, color `#E2D9C4`.
- Título: "Mapa de establecimientos" — gobCL 900, `37px`, `letter-spacing:-.01em`,
  color `#4A2746`, `line-height:1.02`.

**2. Cuerpo** (`flex:1; display:flex; min-height:0`)

  **2a. Lista lateral / leyenda** (`<aside>`, ancho `468px`, `flex:none`)
  - `border-right:1px solid #E7DFC9; padding:30px 40px 26px; display:flex; flex-direction:column`.
  - Título "Lista de establecimientos": gobCL 900, `25px`, color `#1C1212`,
    `letter-spacing:-.01em`, `margin-bottom:11px`.
  - Bajada: Museo Sans 300, `14px`, `line-height:1.55`, color `#5d5650`, `margin-bottom:20px`.
    Texto exacto: "Cada número del mapa corresponde a un establecimiento. La lista los segmenta
    por tipo de establecimiento."
  - Luego **5 grupos** (uno por tipo, en orden de menor a mayor edad). Cada grupo
    (`margin-bottom:18px`):
    - **Encabezado de grupo** (`display:flex; align-items:baseline; gap:9px;
      padding-bottom:9px; margin-bottom:11px; border-bottom:1px solid #ECE2C6`):
      - Punto de color del tipo: `13×13px`, `border-radius:50%`, `background: <color del tipo>`,
        `align-self:center`.
      - Etiqueta del tipo: gobCL **400** (regular, no negrita), `16.5px`, color `#2E2A28`.
      - Conteo entre paréntesis "(N)": gobCL **400**, `16.5px`, color **`#3A3A3A` (gris marengo)**.
        (Importante: el conteo es gris marengo, NO el color del tipo.)
      - Subtítulo del tipo a la derecha (`margin-left:auto`): Museo Sans 300, `12.5px`, color `#9a9488`.
    - **Filas de establecimiento** (`display:flex; align-items:center; gap:12px; padding:4px 0`):
      - Insignia numerada: `29×29px`, `border-radius:50%`, `background:<color del tipo>`,
        texto `#fff`, gobCL 900, `13px`, centrado.
      - Contenedor (`flex:1; display:flex; align-items:baseline; justify-content:space-between;
        gap:10px`):
        - Nombre **completo** del establecimiento: Museo Sans 500, `14px`, color `#2E2230`,
          `line-height:1.25`. (Nunca abreviar ni truncar — ver Reglas.)
        - Comuna: Museo Sans 300, `12px`, color `#9a9488`, `white-space:nowrap`.

  **2b. Mapa** (`flex:1; position:relative; min-width:0; padding:28px 30px`)
  - Marco interior: `position:relative; width:100%; height:100%;
    border:1px solid #E2D9C4; border-radius:8px; overflow:hidden`.
  - Contenido del mapa (ver "Componente Mapa" abajo).

**3. Footer** (altura `72px`, `flex:none`)
- `border-top:1px solid #E7DFC9; display:flex; align-items:center; justify-content:space-between;
  padding:0 56px`.
- Izquierda: "**17 establecimientos** · 4 comunas" — el número en gobCL 900 color `#1C1212`,
  el resto Museo Sans 300, `15px`, color `#5d5650`.
- Derecha: "Puchuncaví · Quintero · Concón · Viña del Mar" — gobCL 900, `15px`,
  `letter-spacing:.02em`, color `#4A2746`; los separadores "·" en color `#C9A7BC`.

### Componente Mapa (`Mapa.dc.html`)
Mapa **estilizado/abstracto** (no cartografía real) que evoca el litoral vertical norte-sur con
una bahía a la altura de Quintero. Fondo blanco, océano a la izquierda en tinte muy claro.

- **Fondo**: `background:#FFFFFF`.
- **SVG** a `viewBox="0 0 100 100"`, `preserveAspectRatio="none"` (se estira al alto del
  contenedor):
  - Océano (banda izquierda con bahía): relleno `#EAF3F8`, contorno de costa
    `stroke:#C7DCEA; stroke-width:0.7`.
  - Separadores de comuna (líneas horizontales punteadas): `stroke:#EDE7DA; stroke-width:0.5;
    stroke-dasharray:2.2 2.4`, a `y=27`, `y=52`, `y=76`.
  - Rutas internas tenues: trazos `stroke:#F1EADC` / `#F4EFE3`.
- **Rótulo "Océano Pacífico"**: rotado -90°, gobCL 400, `12px`, `letter-spacing:.22em`,
  color `#AECBDB`.
- **Rótulos de comuna** (Puchuncaví, Quintero, Concón, Viña del Mar): gobCL 400, `14px`,
  `letter-spacing:.03em`, color `#B6A294`, posicionados en %.
- **Marcadores**: dos tratamientos según densidad —
  - **Tarjetas** (establecimientos fuera de Viña del Mar): caja blanca
    `background:#fff; border:1px solid #E2D9C4; border-radius:8px;
    box-shadow:0 2px 7px rgba(74,39,70,.14); white-space:nowrap`, posicionada `position:absolute`
    en `left:x%; top:y%`. Dentro: insignia `28×28px` redonda con el color del tipo y el número
    en blanco (gobCL 900, `12.5px`), seguida del **nombre completo** (Museo Sans 500, `12.5px`,
    `#2E2230`) y el **(RBD)** (Museo Sans 300, `#9a9488`).
    - **Apertura direccional para no recortar**: si `x ≤ 46` la tarjeta abre a la derecha
      (`transform:translateY(-50%)`, badge a la izquierda, `padding:4px 13px 4px 4px`).
      Si `x > 46` abre a la izquierda (`transform:translate(-100%,-50%);
      flex-direction:row-reverse; padding:4px 4px 4px 13px`) — así la insignia queda sobre el
      punto y el texto se extiende hacia la izquierda sin salir del marco.
  - **Pines** (establecimientos de Viña del Mar): círculo `30×30px`, `border-radius:50%`,
    `border:2.5px solid #fff`, `box-shadow:0 2px 5px rgba(74,39,70,.22)`, color del tipo,
    número en blanco (gobCL 900, `13px`), centrado en el punto (`transform:translate(-50%,-50%)`).

## Interactions & Behavior
**Ninguna.** Es una pieza impresa, estática: sin filtros, sin búsqueda, sin zoom, sin hover, sin
navegación. Cualquier "interacción" se descarta en la implementación.

## State Management
No requiere estado de UI. Solo **datos**: la lista de establecimientos y la tabla de tipos.
En un codebase real, estos datos vendrían de una fuente (API/CSV/base de datos) y se renderizarían
estáticamente.

### Modelo de datos
Cada establecimiento:
```
{
  n:       Number,   // número de referencia (1..17), correlativo norte→sur
  nombre:  String,   // nombre completo, sin abreviaturas
  tipo:    'jardin' | 'basica' | 'liceo' | 'especial' | 'adultos',
  comuna:  'Puchuncaví' | 'Quintero' | 'Concón' | 'Viña del Mar',
  rbd:     String,   // Rol Base de Datos del establecimiento, ej. '1601-8'
  x:       Number,   // posición en el mapa, % horizontal (0..100)
  y:       Number,   // posición en el mapa, % vertical (0..100)
}
```
Derivaciones en render:
- `color` del marcador = color del `tipo` (tabla TIPOS).
- Agrupación de la leyenda: filtrar por `tipo`, ordenar por `n`, y `count = items.length`.
- Mapa: `comuna === 'Viña del Mar'` → pin; en otro caso → tarjeta. Tarjeta abre a la izquierda
  si `x > 46`.

> Los datos incluidos son **de muestra** (17 establecimientos / RBDs ficticios). El territorio
> real del SLEP Costa Central tiene ~97 establecimientos; al implementar, reemplazar por el
> listado oficial (nombre · comuna · tipo · RBD) y recalcular posiciones x/y.

## Design Tokens

### Colores por tipo de establecimiento (código de la leyenda y los marcadores)
| Tipo | Etiqueta | Color |
|---|---|---|
| jardin | Jardines infantiles | `#75924E` (olivo) |
| basica | Escuelas básicas | `#0062A0` (azul océano) |
| liceo | Liceos | `#E88663` (coral) |
| especial | Educación especial | `#A6741C` (ocre / mostaza) |
| adultos | Educación de adultos (CEIA) | `#4A2746` (ciruela) |

Orden de los grupos en la leyenda: **menor a mayor edad** → jardin, basica, liceo, especial, adultos.

### Colores de marca / UI
- Ciruela (plum): `#4A2746` — título, borde header, footer derecho.
- Tinta texto: `#1C1212` (fuerte), `#2E2230` / `#2E2A28` (medio), `#5d5650` (bajada), `#9a9488` (muted).
- Gris marengo (conteo "(N)"): `#3A3A3A`.
- Página exterior: `#EAE6DC`. Papel: `#FFFFFF`.
- Líneas/bordes: `#E7DFC9`, `#E2D9C4`, `#ECE2C6`.
- Mapa: océano `#EAF3F8`, costa `#C7DCEA`, separadores `#EDE7DA`, rótulos comuna `#B6A294`,
  rótulo océano `#AECBDB`.
- Separador "·" del footer: `#C9A7BC`.
- Sombras (tintadas en ciruela, no gris): tarjeta `0 2px 7px rgba(74,39,70,.14)`,
  pin `0 2px 5px rgba(74,39,70,.22)`.

### Tipografía
- **Display/títulos**: `gobCL` (tipografía del Gobierno de Chile). Pesos usados: 900 (Heavy),
  400 (Regular).
- **Cuerpo/UI**: `Museo Sans`. Pesos: 300, 500, 700.
- Escala usada: título header 37px/900 · título lista 25px/900 · etiquetas de grupo 16.5px/400 ·
  filas 14px/500 · comuna 12px/300 · bajada 14px/300 · footer 15px.
- **Regla de mayúsculas**: solo en **siglas** (SLEP, CEIA, RBD). Todo lo demás en caja baja
  (sentence case). No usar ALL CAPS en títulos ni rótulos.

### Tamaños / medidas clave
- Lienzo: `1240 × 1754 px`. Header `190px`, footer `72px`, columna lista `468px`.
- Radios: insignias/pines `50%`; marco del mapa y tarjetas `8px`.
- Insignia leyenda `29px`, insignia tarjeta `28px`, pin `30px`, punto de grupo `13px`.

## Reglas (no negociables)
1. **Nombres completos siempre.** Nunca abreviar ("Jardín Infantil", no "J.I.") ni truncar con
   ellipsis. En la leyenda el nombre debe caber en una línea; en el mapa la tarjeta se ensancha
   y, si está cerca del borde derecho, abre hacia la izquierda para no recortarse.
2. **Bajo consumo de tinta.** Papel blanco, sin grandes fondos de color; el color saturado solo
   en los números de referencia.
3. **Estático.** Sin filtros, búsqueda, zoom ni hover.
4. **Mayúsculas solo en siglas.**

## Assets
- `assets/logo-color-stacked.png` — logotipo a color de SLEP Costa Central (versión apilada).
  Incluye la firma "Servicio Local de Educación Pública / Costa Central" y la línea de comunas.
  Úsalo como provisto. En un codebase con sistema de marca propio, usar su versión oficial del logo.
- Tipografías **gobCL** (Heavy/Regular) y **Museo Sans** (300/500/700): son fuentes de marca
  (Gobierno de Chile / Museo Sans). No se incluyen en este bundle por licencia; obtenerlas de la
  fuente oficial del organismo e instalarlas vía `@font-face`. Si no están disponibles, sustituir
  por equivalentes (display geométrica condensada para gobCL; humanista redonda para Museo Sans)
  y ajustar métricas.
- El "mapa" es un SVG estilizado dibujado a mano (no GeoJSON). Si se requiere geografía real,
  reemplazar por un mapa real (las coordenadas x/y de muestra deberán mapearse a lat/long).

## Files
- `Prototipo Mapa Establecimientos.dc.html` — afiche principal (header, lista lateral, footer) y
  los datos (`est`, `TIPOS`).
- `Mapa.dc.html` — componente del mapa: SVG de costa, rótulos, tarjetas (con apertura
  direccional) y pines.
- `assets/logo-color-stacked.png` — logo.

> Nota: ambos `.dc.html` son design components con sintaxis de plantilla propietaria. Léelos por
> su estructura/estilos/datos; no portes la sintaxis `{{ }}`, `<sc-for>`, `<dc-import>` ni la
> clase `Component extends DCLogic` al codebase destino.
