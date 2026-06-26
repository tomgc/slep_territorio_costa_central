# Traspaso de cierre v02 — slep_georreferenciacion

## 1. Identificacion
- **Proyecto:** slep_georreferenciacion (afiche cartografico A0, SLEP Costa Central)
- **Version:** v02
- **Fecha:** 2026-06-25
- **Sesion 2, foco:** construir el afiche (P1 de v01). Multiples reescrituras del
  motor de marcadores y un rediseno mayor a mapa real georreferenciado. Cierre
  sin entregable aprobado: el diseno no convence al titular.
- **Entorno:** Positron / R 4.5.2; salida HTML/SVG estatico, PDF via pagedown.
- **Archivos principales modificados:** 30_procesamiento/33_generar_afiche.R
  (reescrito por completo varias veces). Nuevo insumo: 20_insumos/comunas.geojson.

## 2. Resumen ejecutivo
Se intento construir el afiche (P1) y se itero muchas veces sin llegar a una
version aprobada. Primero con el diseno del handoff (tarjetas sobre el punto):
funciona para Quintero (10) y Concon (7) pero es imposible sin solape para
Puchuncavi (20 tarjetas en una franja corta) y Vina (60, ya resuelta como
pines). Se probaron variantes (anti-colision vertical, por banda de comuna,
bandas proporcionales, colision 2D, columna lateral con leader lines) y ninguna
satisfizo. A peticion del titular se rediseno a **mapa real georreferenciado**
(limites comunales de un GeoJSON local + calles de OSM via osmdata, reproyeccion
con sf), eliminando el footer y usando tarjetas semitransparentes. El resultado
en la maquina del titular salio malo: las calles de OSM se renderizan como
manchas marrones (no calles limpias tipo visor), las etiquetas de barrios se
enciman, el racimo de Vina sigue ilegible y la columna lateral desperdicia
espacio. Se cierra la sesion sin entregable aprobado, por degradacion del
proceso (muchas iteraciones, cada una rompiendo algo distinto) y porque el
asistente no pudo renderizar las calles de OSM en su entorno (red restringida),
entregando a ciegas. **El afiche NO esta terminado.**

## 3. Estado al cierre
- **Funciona:** 31 y 32 intactos (no se tocaron); leen y proyectan los 97 al
  lienzo (60 pines, 37 tarjetas), verificado por run_all(to=2). La capa de datos
  geo nueva (lectura de 20_insumos/comunas.geojson, filtrado por nombre
  normalizado de las 4 comunas, proyeccion UTM 19S) corre sin error: el HTML se
  genera con el mapa real (limites comunales reales y calles de OSM).
- **No funciona / no aprobado:** el diseno del mapa. Calles de OSM como manchas;
  etiquetas de barrios encimadas; racimo de Vina (60 pines) ilegible; columna
  lateral de 37 tarjetas con leader lines deja medio mapa vacio. Ninguna de las
  ~7 variantes de colocacion de marcadores fue aprobada.
- **Delta vs v01:** 33 reescrito de stub a multiples versiones funcionales pero
  rechazadas; nuevo insumo comunas.geojson; nuevas dependencias (sf, osmdata);
  footer eliminado del layout; proyeccion de puntos movida del 32 al 33 (la del
  mapa real sustituye la lineal del 32 en la version actual del 33).

## 4. Registro detallado de cambios
1. 33: implementacion inicial de generar_afiche() fiel al handoff (tarjetas sobre
   el punto, apertura izq/der por x, Vina en pines). Render: solapes masivos en
   zonas densas (94 pares tarjeta-tarjeta).
2. 33: anti-colision vertical + clamp al marco. Reduce desborde pero no el solape
   horizontal.
3. 33: anti-colision por banda de comuna (separadores SVG y=27/52/76). Bug de
   encoding: COMUNAS_ORDEN (Latin-1) vs factor del .rds (UTF-8) -> intersect
   fallaba y se perdian comunas. Corregido ordenando por geografia (y minima).
4. 33: bandas proporcionales al numero de tarjetas por comuna.
5. 33: colision 2D real (solapa en x e y). Baja solapes a 47 pero Puchuncavi
   sigue saturada (20 tarjetas no caben en su franja).
6. 33: columna lateral con leader lines (paradigma distinto). Rechazado por el
   titular ("horrible").
7. 33: vuelta al handoff (tarjetas sobre el punto) por pedido del titular.
   Confirma que Puchuncavi no cabe.
8. **Rediseno mayor (peticion del titular):** mapa real georreferenciado.
   - chilemapas descartado (sin binario para R 4.5).
   - Fuente de limites: GeoJSON local 20_insumos/comunas.geojson
     (fcortes/Chile-GeoJSON, campo "Comuna"), filtrado por nombre normalizado.
   - Calles/barrios: osmdata (descarga + cache en 40_salidas/afiche/cache_mapa_base.rds).
   - Reproyeccion: sf a UTM 19S (EPSG:32719), normalizacion a viewBox 0..100.
   - Footer eliminado; tarjetas semitransparentes (rgba .85); numero solo en badge.
   - Marcadores: columna lateral derecha con leader lines en L; Vina en racimo.
   - Render en maquina del titular: malo (manchas OSM, etiquetas encimadas).

## 5. Backlog acumulativo

### Objetivo del proyecto
Producir un afiche cartografico estatico imprimible (A0) con los ~97
establecimientos educacionales del SLEP Costa Central (Puchuncavi, Quintero,
Concon, Vina del Mar), reproduciendo con fidelidad hi-fi un handoff de diseno
(HTML/SVG) e inyectando los datos reales del maestro. R cubre la capa de datos
(leer, validar, proyectar lat/long al lienzo); la salida es HTML autocontenido
exportable a PDF. Para el equipo SLEP, desde junio 2026.

### Nota metodologica
Un "cambio" es una solicitud distinguible del titular, no las acciones tecnicas
que la implementan. No cuentan los errores del asistente corregidos de inmediato;
si cuentan los bugfixes reportados por el titular. Clasificacion por intencion
primaria. Fuentes del conteo: este traspaso y los siguientes.

### Clasificacion tematica (refinada en sesion 2)
| Categoria | N | % | Descripcion |
|---|---|---|---|
| Infraestructura/scaffolding | 9 | 47 | Estructura, utils, config, orquestador, escaner, docs |
| Bugfix capa orquestacion | 1 | 5 | id de PASOS a integer (1L) |
| Render del afiche (colocacion marcadores) | 7 | 37 | Variantes de anti-colision y layout del mapa (cambios 11-17) |
| Arquitectura de datos geo | 2 | 11 | Rediseno a mapa real: GeoJSON local + osmdata + sf (cambios 18-19) |

### Resumen estadistico por sesion
| Sesion | Traspasos | Cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 | 10 | Opus 4.8 | Init Rama A + decision densidad + bugfix id |
| 2 | v02 | 9 | Opus 4.8 | Construccion del afiche (rechazada) + rediseno a mapa real |
| | | **19** | | **Total** |

### Detalle cronologico
Sesion 1 (cambios 1-10): ver traspaso v01.
Sesion 2:
- Cambio 11: 33 fiel al handoff (tarjetas sobre punto). Solapes masivos.
- Cambio 12: anti-colision vertical + clamp.
- Cambio 13: anti-colision por banda de comuna; fix bug encoding (orden por geografia).
- Cambio 14: bandas proporcionales por n de tarjetas.
- Cambio 15: colision 2D real.
- Cambio 16: columna lateral con leader lines (rechazado).
- Cambio 17: vuelta a tarjetas sobre punto (confirma inviabilidad en Puchuncavi).
- Cambio 18: rediseno a mapa real (GeoJSON local + osmdata + sf; footer fuera;
  tarjetas semitransparentes; reproyeccion en el 33).
- Cambio 19: fallback de limites por GeoJSON local con filtrado por nombre
  normalizado (tras descartar chilemapas por falta de binario en R 4.5).

### Delta del backlog
9 entradas nuevas (11-19). Taxonomia refinada: se anadieron "Render del afiche"
y "Arquitectura de datos geo" (antes inexistentes; la sesion 2 fue casi toda de
esas dos categorias).

## 6. Bugs de la sesion
- **Bug 2 — Comunas perdidas por mismatch de encoding.**
  - **Sintoma:** al filtrar comunas por nombre, solo "Quintero" (sin tilde)
    matcheaba; Puchuncavi/Concon/Vina se perdian.
  - **Causa raiz:** COMUNAS_ORDEN en 10_configuracion.R tiene Encoding=unknown
    (Latin-1) y el factor del .rds esta en UTF-8; intersect/match por igualdad
    de strings con acento falla. Agravado por locale "C".
  - **Solucion:** no comparar strings con acento. En el motor de marcadores se
    ordeno por geografia (y minima de cada comuna); en el fallback de GeoJSON se
    filtra por nombre NORMALIZADO (tolower + iconv ASCII//TRANSLIT + [^a-z ]).
  - **Patron aprendido (C.6/C.7):** nunca filtrar/unir por strings con tildes
    entre fuentes de distinto origen. Normalizar (sin tildes, minusculas) o usar
    codigos. DEUDA: blindar COMUNAS_ORDEN en 10_configuracion.R con enc2utf8().
  - **Estado:** resuelto en el 33; pendiente blindar la config.
- **Bug 3 — chilemapas sin binario para R 4.5.**
  - **Sintoma:** install.packages("chilemapas") -> "not available for this
    version of R"; el 33 abortaba en preparar_mapa_base.
  - **Causa raiz:** el binario de chilemapas no esta publicado para R 4.5 en CRAN.
  - **Solucion:** eliminar la dependencia; leer limites desde un GeoJSON local
    (20_insumos/comunas.geojson).
  - **Estado:** resuelto.

## 7. Aprendizajes y restricciones descubiertas
- **El handoff (17 puntos) no escala a 97.** Tarjetas-sobre-el-punto es inviable
  donde hay densidad (Puchuncavi 20, Vina 60). Regla: un diseno de muestra no
  define la solucion para el volumen real; validar con datos reales renderizados.
- **No entregar disenos sin verlos.** El asistente no pudo renderizar OSM/sf en
  su entorno (red restringida a unos dominios; sf no compilaba; overpass/CARTO
  bloqueados). Entregar "primer borrador a ciegas" costo varias corridas y
  decepciones al titular. Regla: si no se puede ver el resultado, decirlo
  explicitamente ANTES y no presentar como entregable algo no visto. En sesion 2
  el asistente construyo al final un renderizador propio (Python + headless
  Chromium con el GeoJSON real y el Excel real) para validar el layout antes de
  portar a R; esa via SI permite ver, pero NO cubre las calles de OSM (que solo
  aparecen en la maquina del titular).
- **Las calles de OSM crudas no se ven como el visor.** osmdata trae todas las
  vias sin jerarquia ni estilo; renderizadas como paths simples salen como
  manana/manchas. El visor (captura del titular) usa tiles estilizados (CARTO),
  no vias crudas. Para parecerse al visor hay que: filtrar por jerarquia
  (motorway/primary aparte de residential), estilos distintos por clase, NO
  imprimir todas las etiquetas de barrios, y posiblemente simplificar geometrias.
- **chilemapas archivado / sin binario R 4.5** -> usar GeoJSON local.
- **GeoJSON de fcortes** tiene campo "Comuna" (con tildes) y "cod_comuna" SIN
  cero inicial y con codigos DISTINTOS a los INE de chilemapas (Puchuncavi=5105
  ahi, no 05601). Filtrar por nombre normalizado, no por codigo.
- **El bbox de las 4 comunas** es lon[-71.59,-71.28] lat[-33.10,-32.63]; los 97
  puntos caen dentro (verificado). Vina concentra sus 60 en x[5,34] y[71,88] del
  viewBox (esquina inferior izquierda); las tarjetas ocupan el norte/centro.

## 8. Decisiones de diseno
- **Mapa real en vez del SVG dibujado (peticion del titular).** Alternativa:
  mantener el mapa esquematico del handoff. Se eligio mapa real georreferenciado.
  Implicancia: dependencias sf/osmdata; el mapa esquematico del handoff queda
  obsoleto.
- **Vectorial SVG y no raster para A0.** Un raster de tiles a A0 pesaria cientos
  de MB y se pixelaria; el vector escala nitido. (Sigue vigente.)
- **Limites desde GeoJSON local, no chilemapas.** Por falta de binario R 4.5.
- **PENDIENTE DE DECISION (no resuelta): colocacion de marcadores.** Ninguna de
  las ~7 variantes fue aprobada. Es la decision critica abierta para sesion 3.

## 9. Constantes y parametros vigentes (version actual del 33)
| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| LIENZO$ancho/alto | 1240/1754 | 10_configuracion.R | hi-fi README |
| MAPA_W_PX/MAPA_H_PX | calculados sin footer | 33 | footer eliminado |
| MAPA_PAD | 0.04 | 33 | padding del bbox |
| COLUMNA_X / Y0 / Y1 | 99 / 3 / 97 | 33 | columna lateral de tarjetas |
| LEADER_CODO_DX | 3 | 33 | codo de la leader line |
| PIN_PEQUENO_PX / PIN_VINA_PX | 15 / 24 | 33 | pines |
| CRS metrico | EPSG:32719 (UTM 19S) | 33 | reproyeccion |
| GeoJSON comunas | 20_insumos/comunas.geojson | insumo | fcortes/Chile-GeoJSON, campo "Comuna" |

## 10. Arquitectura de archivos
- 31, 32, 10_utils, 10_configuracion: SIN cambios respecto a v01.
- 33_generar_afiche.R: reescrito (mapa real). La version actual NO esta aprobada.
- Nuevo insumo: 20_insumos/comunas.geojson (1.7 MB).
- Nuevo cache generado: 40_salidas/afiche/cache_mapa_base.rds.
- Respaldo del 33 anterior (tarjetas sobre punto) quedo en el entorno del
  asistente, NO en el repo. Si se quiere recuperar esa via, esta documentada en
  el cambio 11/17 de este traspaso.

## 11. Pendientes y ruta sugerida

### Inventario
- **P1 (sigue abierto) — Colocacion de marcadores aprobada.** Tipo: bug de diseno
  bloqueante. Es LA decision critica. Ninguna variante convencio. Antes de
  codificar mas, ACORDAR con el titular el paradigma exacto (sobre el punto /
  columna lateral / etiquetas al mar / hibrido) viendo bocetos, no implementando.
  Criterio de exito: el titular aprueba un boceto ANTES de portar a R.
- **P2 — Estilo del mapa OSM tipo visor.** Tipo: funcionalidad/fidelidad. Las
  calles crudas salen como manchas. Filtrar vias por jerarquia, estilos por
  clase, NO imprimir todas las etiquetas de barrios (o ninguna), simplificar
  geometrias. Considerar: usar tiles raster estilizados (CARTO Positron) como
  imagen de fondo en vez de vias vectoriales crudas, si la nitidez A0 lo permite;
  o un set reducido de vias mayores. Criterio: el fondo se parece al visor.
- **P3 — Legibilidad del racimo de Vina (60 pines).** Sigue ilegible amontonado.
  Evaluar: numeros mas chicos, leve dispersion, o apoyarse 100%% en la lista.
- **P4 — Blindar encoding en 10_configuracion.R.** enc2utf8() sobre COMUNAS_ORDEN
  (bug 2). Tipo: deuda tecnica. Bajo esfuerzo.
- **P5 — Reconsiderar donde vive la proyeccion.** Hoy el 33 reproyecta con el
  mapa real, duplicando/ignorando la del 32. Decidir si el 32 debe producir
  lat/lon crudos y el 33 proyectar, o si el 32 proyecta al mapa real. Tipo: deuda
  arquitectonica.

### Auditoria de cierre (politica 5.6, preguntas "Cierre")
- Pipeline corre de cero sin intervencion manual: SI (run_all 1-3 corre), pero el
  output no es aceptable -> P1/P2.
- Outputs reproducibles e idempotentes: SI (escritura atomica; cache de mapa).
- Decisiones metodologicas como constantes nombradas: SI.
- Nombres sin tildes/enie/espacios: SI (archivos); el GeoJSON usa "Comuna" con
  tildes pero es dato, no nombre de archivo.

### Ruta sugerida sesion 3
1. NO codificar hasta acordar el diseno (P1). Presentar 2-3 bocetos del mapa
   (renderizados, no descritos) y que el titular elija. El asistente DEBE poder
   renderizar lo que propone (usar el renderizador Python/headless con el GeoJSON
   y el Excel reales, que en sesion 2 si funciono para el layout).
2. Resolver el estilo del mapa (P2) en paralelo: decidir tiles vs. vias filtradas.
3. Recien con diseno aprobado, portar a R.
4. Cerrar P4 (encoding) de paso.

## 12. Instrucciones especificas para la proxima sesion
- 🔒 El titular descarga y reemplaza archivos EL MISMO. NUNCA generar comandos de
  terminal/Claude Code para mover, renombrar o reemplazar archivos. Solo entregar
  el archivo y decir "descargalo y reemplazalo tu en <ruta>".
- ⚠️ NO entregar disenos sin haberlos renderizado y visto. Si el entorno no
  permite ver (p. ej. OSM/sf), decirlo ANTES y usar el renderizador propio
  (Python + headless Chromium con datos reales) para validar el layout.
- ⚠️ NO seguir iterando el codigo del afiche sin un diseno aprobado por el
  titular. Primero boceto aprobado, despues codigo.
- ✅ ANTES de tocar el 33, confirmar que existe 20_insumos/comunas.geojson y, si
  hay calles, que el estilo OSM esta resuelto (P2).
- 🔒 Vina del Mar va con pines (no tarjetas). Las otras 3 comunas, formato por
  acordar en P1.
- ✅ Mantener 31 y 32 intactos salvo decision explicita (P5).
- 🔒 33 NO truncar nombres de establecimientos en ningun marcador.

## 13. Fragmentos de codigo de referencia
```r
# Filtrado robusto de comunas por nombre normalizado (sin tildes), patron a
# reutilizar siempre que se crucen strings con acento entre fuentes:
norm <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- iconv(x, to = "ASCII//TRANSLIT")
  gsub("[^a-z ]", "", x)
}
objetivo <- c("puchuncavi", "quintero", "concon", "vina del mar")
comunas_sf <- todo[norm(todo[["Comuna"]]) %in% objetivo, ]
```
```r
# Exportar el afiche a PDF A0 (paso manual del titular):
pagedown::chrome_print(
  here::here("40_salidas", "afiche", "mapa_establecimientos.html"),
  output = here::here("40_salidas", "afiche", "mapa_establecimientos.pdf")
)
```

## 14. Reapertura

- **Nombre del chat:** `slep_georreferenciacion, sesion 3 (Opus 4.8)`
- **Mensaje de apertura pre-armado:** tipo CONTINUATION. El protocolo
  (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la
  knowledge base del Project y se lee desde ahi. Adjunto el traspaso v02, el
  escaner estructura_actual.md, el maestro o el .rds proyectado (para poder
  renderizar bocetos), y el comunas.geojson (o su ruta) para el mapa.
- **Documentos para la proxima sesion:**
  1. Protocolo en knowledge base (NO adjuntar, solo verificar al dia):
     POLITICA_PROYECTO.md, SETTINGS_Y_PROMPTS_OPERACIONALES.md.
  2. Opcionales segun foco: README del handoff y los .dc.html (referencia de
     estilo visual: colores, tipografia, leyenda); capturas del visor que el
     titular quiere imitar.
  3. Especificos de la sesion (SI adjuntar): traspaso_cierre_v02.md;
     estructura_actual.md; maestro_establecimientos.xlsx o
     establecimientos_proyectados.rds (con lat/lon, para renderizar bocetos);
     20_insumos/comunas.geojson; 33_generar_afiche.R (version actual, rechazada,
     como punto de partida o para descartar).
- **Nota final:** si algun archivo cambio entre sesiones, adjuntar la version mas
  reciente y avisarlo en la apertura. PRIORIDAD de sesion 3: acordar el diseno
  (P1) con bocetos renderizados ANTES de escribir codigo. No repetir el ciclo de
  iterar a ciegas.
