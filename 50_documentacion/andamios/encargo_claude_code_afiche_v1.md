# Encargo autónomo — Afiche cartográfico de establecimientos (paradigma D)

> Proyecto: `slep_georreferenciacion`. Sesión 3.
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> Meta aprobada por el usuario: implementar el afiche según el **paradigma D**
> (validado en bocetos esta sesión) sobre un **fondo CARTO Positron real**,
> resolviendo el nudo de leader lines de Quintero/Concón que el redactor no
> pudo resolver sobre placeholder (su entorno no renderiza CARTO/sf).

---

## 2.1 Encabezado de contrato

**Modo y disciplina:** modo autónomo, secuencial. Ejecuta todas las fases en
este turno. No pidas confirmación de pasos mecánicos cubiertos por esta meta.

**Regla de detención (PARA y reporta solo si):**
1. Un invariante 🔒 te obligaría a violar el contrato de datos/gobernanza.
2. Un dato real contradice un supuesto de la meta (p. ej. el maestro no tiene
   las columnas declaradas, o el conteo no da 97).
3. Un gate estratégico marcado abajo como decisión del usuario.

Fuera de esos tres casos, decide con autonomía y reporta en una línea.

**Reglas canónicas heredadas** (referenciadas, no reexplicadas):
- R-only. Pipe nativo `|>`, `dplyr >= 1.1` con `.by=`, `here::here()` para toda
  ruta dentro de scripts. Sin rutas absolutas en código (POLITICA sección 5.3.7).
- snake_case sin tildes/ñ/espacios en nombres de archivo (POLITICA sección 2).
- Commits atómicos temáticos, mensajes en español (POLITICA sección 3).
- No asumas `cd` previo: usa rutas completas desde la raíz del repo en comandos.
- Estructura canónica de script (POLITICA sección 5.4): header, auto-instalación,
  library(), rutas, constantes, funciones, flujo.

---

## 2.2 Contexto mínimo suficiente

**Qué es:** afiche cartográfico estático (HTML/SVG de archivo único, idealmente
exportable a PDF A0) que ubica los 97 establecimientos educacionales del SLEP en
4 comunas: Puchuncaví (20), Quintero (10), Concón (7), Viña del Mar (60).

**Rutas clave (raíz del repo `slep_georreferenciacion`):**
- Insumos: `20_insumos/maestro_establecimientos.xlsx` (hoja "maestro transporte",
  columnas: RBD, Nombre del establecimiento, RBD visualización, Comuna, Latitud,
  Longitud, Tipo establecimiento, Nivel de enseñanza).
- Límites: `20_insumos/comunas.geojson` (campo `Comuna` con tildes; está
  **generalizado**: la línea de costa recorta tierra real, ver invariante 🔒-3).
- Pipeline: `30_procesamiento/31_leer_validar.R`, `32_proyectar_lienzo.R`,
  `33_generar_afiche.R` (este es el que se reescribe).
- Salida actual: `40_salidas/afiche/mapa_establecimientos.html`.
- Orquestador: `00_run_all.R`.

**Qué se hizo antes:** 31 y 32 funcionan y producen los .rds validados. El 33 se
reescribió ~7 veces sin diseño aprobado y todas las versiones fallaron (tarjetas
encimadas, racimo de Viña ilegible, OSM crudo). Esta sesión se canceló esa vía:
se aprobó el paradigma D con bocetos. **Tú implementas D, no rediseñas.**

**Auditoría de coordenadas (hecha por el redactor, no la repitas):** las 97
coordenadas son válidas. 95/97 caen dentro del polígono de su comuna; las 2
excepciones (RBD 1699 Concón a 8 m de la costa, RBD 33476 Quintero a 322 m) son
falsos positivos del GeoJSON generalizado, NO errores de datos. Ver 🔒-3.

---

## 2.3 Invariantes (🔒 intocables)

- **🔒-1. No truncar nombres.** Ningún nombre de establecimiento se corta en
  ningún marcador, etiqueta o índice. Si no cabe, se reubica o se ajusta tamaño,
  nunca se trunca.
- **🔒-2. Viña del Mar va en ampliación (inset) con zoom**, no dispersa en el
  mapa principal. Sus 60 puntos van numerados y legibles dentro del recuadro.
  Decisión del usuario, no negociable.
- **🔒-3. Los puntos se ubican por sus coordenadas; NUNCA se filtran por
  contención en el polígono comunal.** El GeoJSON está generalizado y dejaría
  fuera a RBD 1699 y 33476. Si necesitas que esos 2 caigan "en tierra"
  visualmente, aplica un buffer pequeño (~0.004°) al polígono SOLO para el fondo
  visual, jamás para filtrar puntos.
- **🔒-4. No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`** salvo que un
  dato real lo exija; en ese caso, PARA y reporta. El trabajo es sobre el 33.
- **🔒-5. Numeración oficial N→S** (ver Fase 1). Mapa, inset e índice comparten
  la MISMA numeración. Una discrepancia entre ellos es un fallo.
- **🔒-6. Proyecto 100% público (Rama A):** sin datos personales sensibles
  (son establecimientos, no personas). No aplica gobernanza de NNA aquí, pero
  igual: el afiche identifica establecimientos por nombre, lo cual es el
  propósito declarado y está permitido para este universo.

---

## 2.4 Fases en orden estricto

### Fase 0 — Lectura del estado real (no modificar sin leer)
- Lee `33_generar_afiche.R` completo, `10_utils/10_configuracion.R` (rutas),
  `31` y `32` (para entender qué .rds producen y con qué columnas).
- Confirma que `maestro_establecimientos.xlsx` tiene las 8 columnas declaradas y
  que el conteo es 97 (20+10+7+60). Si no, PARA (regla de detención 2).
- Commit: ninguno (solo lectura).

### Fase 1 — Numeración oficial N→S (determinista, va primero)
Asigna el número 1–97 con este criterio EXACTO (es verificable, hazlo bien):
1. Orden de comunas por latitud media, norte→sur:
   **Puchuncaví (1–20) → Quintero (21–30) → Concón (31–37) → Viña (38–97).**
2. Dentro de cada comuna, por tipo en este orden: Jardín infantil → Escuela
   básica → Liceo → Escuela especial → Centro de educación de adultos.
3. Dentro de cada tipo, por nombre alfabético.

Esta numeración es un objeto de datos reproducible (genérala con código, no a
mano). El índice, el mapa y el inset la consumen idéntica (🔒-5).

**Criterio de éxito:** una tabla `establecimientos` con columna `num` 1–97,
sin huecos ni repeticiones, y los rangos por comuna exactamente 1-20/21-30/31-37/
38-97. Verifícalo con un `stopifnot()`.

### Fase 2 — Fondo CARTO Positron real (lo que el redactor NO pudo hacer)
- Monta el mapa base con tiles **CARTO Positron** (estilo claro, sin etiquetas
  invasivas), cubriendo el bbox de las 4 comunas
  (lon[-71.62,-71.28] lat[-33.10,-32.63], ajusta con margen).
- Stack sugerido (decide tú según lo que compile en la máquina): `leaflet` con
  `providers$CartoDB.Positron` para HTML interactivo, o `ggplot2`+`ggsptiles`/
  `maptiles` (`get_tiles(provider="CartoDB.Positron")`) + `geom_sf` para SVG/PDF
  estático. **Recomendación:** si el entregable final es afiche imprimible A0,
  usa la vía estática (maptiles + ggplot2 + sf), porque controla mejor la
  tipografía y la exportación a PDF vectorial. Si el usuario prioriza
  interactividad, leaflet. Ante duda, estático.
- Reproyecta a UTM 19S (EPSG:32719) para que las distancias en metros (umbral de
  450 m de la Fase 3) sean correctas.
- **Criterio de éxito:** el fondo renderiza sin error, se ve como el visor
  (calles suaves, sin manchas marrones OSM crudas, sin topónimos de barrio
  encimados), y los 97 puntos caen sobre tierra visible (con buffer 🔒-3 si hace
  falta).

### Fase 3 — Colocación de marcadores: paradigma D (el corazón del encargo)
Para las 3 comunas chicas (Puchuncaví, Quintero, Concón):
- Calcula, por comuna, la distancia de cada punto a su vecino más cercano.
- **Apretado = vecino a < 450 m.** Esos van con **etiqueta al mar** (al oeste,
  sobre el agua del tile). Los no-apretados van con **nombre en tierra** junto
  al punto.
- **Etiquetas al mar con anti-colisión y SIN nudo** (este es el fallo que vienes
  a resolver): cada etiqueta sale al mar a una latitud cercana a su punto, con
  leader line fina, y las cajas se apilan verticalmente sin solaparse.
- **Resolución del nudo Quintero/Concón** (lo que el redactor no pudo sobre
  placeholder): Quintero y Concón están apiñadas en el centro-sur y sus
  etiquetas convergían. Con el mar real a la vista, tienes dos caminos:
  (a) usar el mar al **oeste** para Quintero y el mar al **suroeste/sur** para
  Concón (que está más al sur, su agua natural es la desembocadura del
  Aconcagua); (b) si el mar disponible no basta sin cruces, un mini-inset para
  Concón como el de Viña. **Recomendación:** intenta (a) primero (un solo plano
  es más legible que dos insets); si las leader lines siguen cruzándose con el
  mar real, cae a (b). Es decisión tuya con el render a la vista, NO un gate.
- Marcadores: punto coloreado por tipo (jardín verde, escuela azul, liceo
  naranja, especial morado, adultos gris) con su número en blanco encima.

Para Viña (38–97): inset con zoom (🔒-2), puntos numerados, dispersión leve solo
si dos puntos quedan literalmente encimados (mantén posición real lo más posible).

**Criterio de éxito (verificable en navegador/PDF):**
- Cero etiquetas solapadas (revísalo en el render, no en supuesto).
- Cero leader lines que crucen el mapa de lado a lado.
- Racimo de Viña legible en el inset.
- Ningún nombre truncado (🔒-1).

### Fase 4 — Índice secundario + leyenda + chrome del afiche
- Índice lateral N→S agrupado por comuna, coloreado por tipo, Viña en 2 columnas.
  Es índice de respaldo: el mapa manda.
- Leyenda de colores por tipo. Título. Nota de fuente. Logo institucional
  (`design_handoff_mapa_establecimientos/assets/logo-color-stacked.png`) y
  tipografía gobCL/MuseoSans si el formato lo permite.
- **Criterio de éxito:** afiche completo, legible, autocontenido.

### Fase 5 — Regenerar vía orquestador y verificar end-to-end
- Corre `run_all(from = 1, to = 3)` (o el subconjunto que regenere el afiche).
- Abre el HTML/PDF resultante y verifícalo visualmente (Fase 3 criterios).
- Commit atómico por fase (feat: numeración; feat: fondo CARTO; feat: marcadores
  paradigma D; feat: índice y chrome; o agrupa con criterio).

---

## 2.5 Criterios de éxito globales (B.4)
1. El afiche se genera de cero con el orquestador, sin intervención manual.
2. Numeración N→S consistente entre mapa, inset e índice (`stopifnot`).
3. Etiquetas al mar sin solape ni nudo, verificado en el render real.
4. Viña legible en inset. Nombres nunca truncados.
5. Fondo CARTO Positron, sin ruido OSM.

## 2.6 Auto-auditoría antes de reportar
Tras terminar, lanza un **panel adversarial** de solo-lectura que re-derive
independientemente: (a) que la numeración 1–97 cumple los 4 criterios de orden
sin huecos; (b) que los 97 puntos del render corresponden 1:1 a las 97 filas del
maestro (ningún punto perdido por filtro de polígono, 🔒-3); (c) que ningún
nombre quedó truncado en el HTML/SVG (grep de nombres completos contra el
maestro). Un check escrito por el mismo flujo que generó el afiche hereda sus
puntos ciegos; el panel los rompe.

## 2.7 Mandato del log y cierre
Escribe el log en `50_documentacion/andamios/logs/YYYYMMDD_afiche_paradigma_d_log.md`
según la plantilla fija (encargo v1 sección 4): resumen, inventario de commits,
cambios sustantivos con causa raíz, verificación de los 6 invariantes 🔒 con
PASA/FALLA y evidencia, decisión registrada del nudo Quintero/Concón (camino a o
b y por qué), pendientes y marcas `# REVISAR`, notas para el revisor. Honesto:
incluye lo que costó. El log puede quedar sin commitear para revisión previa.

## 2.8 Reporte final al chat
Devuelve: hashes de los commits, resultado del panel adversarial (los 3 checks
con evidencia), confirmación visual de los criterios de Fase 3, qué camino
tomaste para el nudo Quintero/Concón, pendientes, y la ruta del log.

---

**Gate estratégico único (decisión del usuario, marca y reporta si lo alcanzas):**
si descubres que el mar disponible NO basta para colocar las etiquetas de
Quintero+Concón sin cruces NI con mini-inset (caso improbable), PARA: la
alternativa sería cambiar el paradigma (p. ej. todas las comunas chicas a inset),
y eso lo decide el usuario, no tú.
