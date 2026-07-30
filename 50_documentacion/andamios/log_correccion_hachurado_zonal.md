# Log — hachurado de "denominador insuficiente" (capa zonal de asistencia)

**Fecha:** 2026-07-30 · **Sesión 12.** Corrige el defecto que el §5 de
`log_frontend_capas_censo.md` levantó y dejó sin resolver: el gris plano de
`fiable = FALSE` y el fondo de papel entre polígonos eran tonos vecinos, así que el
mapa decía casi igual dos cosas distintas ("hay dato, pero es ruidoso" y "no hay
polígono aquí"). Archivos tocados: `docs/assets/mapa.js`, `docs/assets/estilo.css`.
**No** se tocó `docs/index.html`, `30_procesamiento/`, `docs/data/` ni `00_run_all.R`.
Verificado en el Chrome del preview sobre `docs/` servido en `localhost:8873`.

---

## 1. La decisión: opción (a), Canvas con `CanvasPattern`

**No hizo falta cambiar de renderer.** Canvas 2D acepta un `CanvasPattern` en
`fillStyle`, y el renderer de Leaflet asigna `options.fillColor` a `fillStyle` sin
transformarlo:

```
_fillStroke:function(t,e){var i=e.options;i.fill&&(t.globalAlpha=i.fillOpacity,
  t.fillStyle=i.fillColor||i.color,t.fill(i.fillRule||"evenodd")),...
```
(fuente: `grep` sobre `docs/assets/vendor/leaflet.js`)

Es decir: la trama **es un `fillColor` más**. Cero parches al renderer, cero
post-proceso del canvas, cero renderer SVG. La opción (b) quedó descartada por
innecesaria antes de medirla: cambiar de renderer solo se justificaría si Canvas no
pudiera dibujar el patrón, y sí puede.

Dos detalles que la implementación tuvo que resolver:

- **Retina.** Leaflet escala el ctx del canvas por un factor **fijo de 2** (no por
  `devicePixelRatio`): `n=b.retina?2:1` … `b.retina&&this._ctx.scale(2,2)` (fuente:
  bloque `_update` de `Canvas` en `docs/assets/vendor/leaflet.js`). El mosaico se
  dibuja a esa resolución y el patrón se contra-escala con `setTransform`, para que
  la trama mida 8 px CSS en retina y en no-retina por igual.
- **Anclaje.** El mismo `_update` hace `this._ctx.translate(-t.min.x,-t.min.y)`, así
  que el origen del patrón coincide con el origen en coordenadas de capa: la trama
  queda anclada al **mapa**, no a la pantalla, y no se desliza sobre los polígonos
  al hacer pan.
- **`fillOpacity: 1`.** Leaflet aplica `globalAlpha = fillOpacity` antes del `fill()`.
  Si la trama heredara el 0,42 del gris anterior, la línea se destiñe y vuelve a
  acercarse al papel: exactamente el defecto que se está corrigiendo. La
  transparencia va horneada en el mosaico.

**Constantes** (`HACHURA` en `mapa.js`): mosaico de 8 px CSS ⇒ separación
perpendicular 8/√2 = 5,7 px; línea de 1,5 px, `rgba(96,89,74,.60)`; velo de fondo
`rgba(181,174,159,.22)`. La primera versión usaba tinta `.82`: es inequívoca pero le
gana a la rampa azul y rompe el principio "la coropleta es fondo, los pines mandan".
A `.60` sigue leyéndose la textura sin competir (lo que distingue es la **textura**,
no el tono, así que basta el contraste que la deja leer).

*Anotación de precisión (auditoría de cifra).* El valor vigente en el código es `.60`
en los dos archivos: `HACHURA.tinta = 'rgba(96,89,74,.60)'` en `mapa.js:796` y
`rgba(96,89,74,.60)` en `estilo.css:296`. Entremedio probé `.58` en vivo desde la
consola, sin escribirlo nunca a archivo, y la captura a z10 que respalda el juicio
"la trama ya no domina la vista" (§4, último punto) se tomó a ese `.58`. La captura a
z12 sí se tomó con `.60` ya en disco y recargado. Dos puntos de alfa no son
distinguibles a ojo, pero la afirmación de z10 se apoya en `.58`, no en `.60`, y
corresponde decirlo.

---

## 2. La cifra

No cambió el renderer, así que la medición del Hito 1 (Canvas, pan 57 FPS mín) sigue
vigente **por construcción**: misma geometría, mismo renderer, misma cantidad de
llamadas a `fill()`. Lo único que había que medir es el sobrecosto de la trama.

`renderer._redraw()` completo (`_redrawBounds = null` ⇒ dibuja las 1.216 features),
40 repeticiones por condición tras 10 de calentamiento, Chrome del preview, z10,
`devicePixelRatio` 2:

| Relleno de `fiable = FALSE` | mediana | p90 | máx |
|---|---:|---:|---:|
| **trama diagonal (nuevo)** | 0,60 ms | 0,90 ms | 1,10 ms |
| gris plano (anterior) | 0,50 ms | 0,60 ms | 0,70 ms |

+0,1 ms de mediana sobre un presupuesto de 16,7 ms por cuadro a 60 FPS: 0,6 % del
cuadro. A z12 (67 unidades en pantalla) ambas condiciones dan 0,1 ms y no se
distinguen.

**Limitación declarada:** no pude medir FPS con `requestAnimationFrame` porque el
panel del navegador corre **oculto** en esta sesión (`document.visibilityState`
devuelve `"hidden"`) y Chrome estrangula rAF y los timers en pestañas ocultas. Por eso
medí el costo sincrónico de `_redraw()`, que es una comparación válida entre las dos
condiciones —geometría, renderer y número de `fill()` idénticos, solo cambia
`fillStyle`— pero **no incluye la rasterización GPU**. La cifra sostiene "la trama no
cambia la categoría de costo del dibujo"; no es una medición de FPS, y no la presento
como tal. La medición de FPS con el panel visible queda disponible para validación
in situ.

---

## 3. Los tres estados de la capa de asistencia (siguen siendo tres)

| Estado | Condición | Tratamiento visual | Leyenda |
|---|---|---|---|
| **fiable = TRUE** | den ≥ 20 | rampa azul (5 clases), relleno liso | cuadro por clase de proporción |
| **fiable = FALSE** | 0 < den < 20 | **trama diagonal "/"**, 8 px, sobre velo tan | **cuadro con la trama** (CSS `.ly-cuadro.hachurado`) |
| **fiable = NA** | den = 0 | hueco: solo contorno `#b9b3a7` 0,6 px, sin relleno | cuadro vacío con borde (`.ly-cuadro.hueco`) |

Ahora los tres se separan por **canales distintos**: color (rampa), textura (trama) y
ausencia de relleno con contorno (hueco). El defecto anterior era que dos de ellos se
separaban solo por tono, y por poco tono.

Reparto verificado en el navegador sobre la capa montada, nivel básica:
**912 rampa / 266 trama / 38 hueco**, total 1.216 (fuente: recuento sobre
`S.censo.capa._layers` en el Chrome del preview). Coincide con el recuento sobre el
artefacto en disco: `TRUE 912 / FALSE 266 / NA 38` (fuente: `Rscript` sobre
`docs/data/censo_zonal_r5.geojson` en esta sesión).

La leyenda del cuadro hachurado replica la geometría del mapa desde CSS
(`repeating-linear-gradient(-45deg, …)`, banda 1,5 px, período 5,66 px, misma tinta y
mismo velo). Computado en vivo: `background-color: rgba(181, 174, 159, 0.22)`,
`background-image: repeating-linear-gradient(-45deg, rgba(96, 89, 74, 0.6) 0px …)`.

---

## 4. Cómo se ve (condición de éxito)

Vista de Quintero/Puchuncaví, z12, centro (−32,83; −71,47):

- Las localidades rurales de denominador insuficiente aparecen **rayadas**: líneas
  paralelas a 45° ascendentes ("/"), separadas ~5,7 px, de un tan oscuro sobre un
  velo tan claro. Al este de la ciudad de Quintero y al sureste de Santa Adela hay
  dos cuñas grandes claramente rayadas.
- El territorio **no cubierto** por ningún polígono (los slivers y parches del
  0,2–4,7 % rural) es **liso**: el papel de Positron, sin ninguna línea encima.
- La diferencia no es de tono sino de **presencia o ausencia de líneas**. Un polígono
  rayado no puede leerse como hueco por muy cercanos que sean los tonos, que era
  precisamente el problema: el ojo detecta una trama periódica mucho antes que una
  diferencia de luminancia de unos pocos puntos.
- A z10 (región completa) la trama sigue siendo legible y ya no domina la vista: los
  pines y la rampa azul vuelven a mandar.

No queda duda al mirarlo. Si la hubiera, esta sección lo diría.

---

## 5. Renombre de constantes (defecto menor del encargo)

| Antes | Ahora |
|---|---|
| `GRIS_CENSO_CERO` | `COLOR_SIN_POBLACION` (densidad: `n_edad == 0`) |
| `OPACIDAD_CENSO_GRIS` | `OPACIDAD_SIN_POBLACION` |
| `GRIS_CENSO_RUIDOSO` | **desaparece**, lo reemplaza `HACHURA` + `crearPatronHachura()` |

`grep -n "GRIS_CENSO\|OPACIDAD_CENSO_GRIS" docs/assets/mapa.js` no devuelve nada.
Los nombres ya dicen qué son, no de qué color son, y no queda ninguna pareja de
grises separada por 22 puntos de luminancia invitando a confundirse.

---

## 6. Panel adversarial

1. **¿Qué opción y con qué cifra?** (a) Canvas con `CanvasPattern`. La cifra es el
   sobrecosto: `_redraw()` de las 1.216 features, 0,60 ms de mediana con trama vs
   0,50 ms con el plano anterior (40 repeticiones, Chrome del preview, z10). No medí
   FPS de SVG porque no cambié de renderer: (b) resultó innecesaria, no descartada
   por lenta. Declaro que no pude medir FPS con rAF porque el panel corre oculto
   (`visibilityState === "hidden"`) y Chrome estrangula rAF ahí; ver §2.
2. **¿La densidad sigue en Canvas?** Sí. Ambas capas comparten el mismo
   `L.canvas({ pane: 'censo' })`. Verificado con la capa de densidad montada:
   `renderer instanceof L.Canvas` ⇒ `true`, 5.753 features, el pane `censo` tiene un
   solo hijo `<canvas class="leaflet-zoom-animated">`, y **0** de esas features usa el
   patrón (1.474 usan `COLOR_SIN_POBLACION` en el tramo básica).
3. **¿Se distingue un ruidoso de un hueco?** Sí, descrito en §4. La separación es
   textura contra liso, no tono contra tono.
4. **¿Siguen siendo tres tratamientos distintos?** Sí: rampa azul lisa / trama
   diagonal / contorno sin relleno. Tabla y recuento en §3.
5. **¿La leyenda muestra el patrón?** Sí, `.ly-cuadro.hachurado` con
   `repeating-linear-gradient`, no un cuadrito gris. Estilo computado leído en vivo
   (§3). El orden de la leyenda es: 5 clases de la rampa, trama, hueco.
6. **¿Toqué la barra de filtros, la máscara, el sidebar o la atribución?** No.
   `git diff docs/assets/mapa.js` toca solo el bloque del Censo (constantes,
   `estiloDensidad`, `estiloAsistencia`, `leyendaCenso`, `iniciarCenso`) y
   `git diff docs/assets/estilo.css` agrega 9 líneas, todas dentro de la regla nueva
   `.ly-cuadro.hachurado`. `docs/index.html` no aparece en el diff: la trama no
   necesitó markup nuevo, se pinta desde el canvas y desde CSS.
   *Nota:* el working tree muestra además cambios en
   `50_documentacion/estructura/` que **yo no hice**: los generó el escáner al
   dispararse tras las ediciones. No commiteé nada (el encargo lo prohíbe).
7. **¿Alguna afirmación sin comando o sin render detrás?** No. Las cifras de features
   y de estados vienen de recuentos programáticos de esta sesión (uno en R sobre el
   geojson, otro en el navegador sobre la capa montada); las citas del renderer de
   Leaflet vienen de `grep` sobre el archivo vendorizado; los tiempos son de 40
   repeticiones medidas en el Chrome del preview; la descripción visual viene de
   capturas tomadas en esta sesión a z10 y z12. Lo único que **no** puedo respaldar
   con medición es el FPS con el panel visible, y está declarado como tal en §2.

---

## 7. Verificaciones de no-regresión

- Consola del navegador: sin errores (`read_console_messages` con `onlyErrors`).
- Popup de una unidad ruidosa: intacto. Unidad `540106001` (La Ligua), den 11,
  asisten 11, 100 % + el aviso "Denominador insuficiente (menos de 20 niños en edad
  básica): la proporción es ruidosa. Los conteos de arriba sí son exactos." El patrón
  como `fillStyle` no afecta el hit-testing (Leaflet usa `isPointInPath`).
- Exportación SVG con la capa encendida: sigue devolviendo SVG válido (85.445 chars,
  empieza `<?xml`), sin la capa del Censo y sin rastro del patrón, como corresponde:
  `construirSVG()` se arma desde `S.ee`/`S.frontera`/`S.rotulos`.
- Cambio de nivel educativo (parvularia/básica/media) reconstruye la capa desde el
  cache y vuelve a aplicar la trama: el patrón vive en `S.censo.patron`, creado una
  vez en `iniciarCenso()`.
