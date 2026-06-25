# Traspaso de cierre v01 — slep_georreferenciacion

## 1. Identificacion
- **Proyecto:** slep_georreferenciacion (afiche cartografico A0, SLEP Costa Central)
- **Version:** v01
- **Fecha:** 2026-06-25
- **Sesion 1, foco:** inicializacion NEW PROJECT (Rama A) y decision de densidad
  de marcadores con prototipos sobre datos reales.
- **Entorno:** Positron / R; salida HTML/SVG estatico, PDF via pagedown.
- **Archivos principales creados:** estructura canonica completa, 10_utils,
  10_configuracion, 31/32 funcionales, 33 stub con arquitectura, orquestador,
  escaner, README, decision de densidad.

## 2. Resumen ejecutivo
Se inicializo el proyecto como Rama A (publico, raiz unificada): el maestro de
establecimientos contiene solo datos publicos (RBD, nombre, tipo, coordenadas
del recinto), sin datos personales ni de NNA. Se leyo el handoff hi-fi completo
y el maestro real (97 establecimientos, no los 17 de muestra). La decision
critica de la sesion fue el tratamiento de marcadores por densidad: con 60 de 97
en Vina del Mar, el esquema de muestra no escala. Se renderizaron tres opciones a
tamano real y el titular eligio la opcion C: Vina = pines numerados; las otras
tres comunas = tarjeta con numero + nombre + (RBD). Se dejaron funcionales los
pasos 1 (leer/validar) y 2 (proyectar al lienzo), validados sobre el Excel real;
el paso 3 (generar afiche) queda como stub con la arquitectura, tokens y API
fijados. Pendiente unico de fondo: construir el HTML del afiche en la sesion 2.

## 3. Estado al cierre
- **Funciona:** estructura canonica; 10_utils (bootstrapping); 10_configuracion
  (rutas, MAPEO_TIPO, TIPOS, TOKENS, LIENZO); 31_leer_validar y
  32_proyectar_lienzo (logica verificada: 97 registros, 37 tarjetas, 60 pines,
  proyeccion en rango, 0 NAs, 0 duplicados, 0 tipos sin mapear); orquestador con
  run_all(from/to/only/skip); escaner con poda 2; .gitignore Rama A; README.
- **No funciona aun:** 33_generar_afiche es stub (llama stop() en generar_afiche).
  El HTML final del afiche no se ha construido.
- **Delta vs v00:** proyecto nuevo; no hay version anterior.

## 4. Registro detallado de cambios
1. Inicializacion Rama A: arbol canonico con 20_insumos/ y 40_salidas/ en el repo.
2. 10_utils.R: instalar_si_falta() y log_msg() sin dependencias externas.
3. 10_configuracion.R: rutas via here::here(); MAPEO_TIPO (Excel->key); TIPOS
   (orden leyenda menor a mayor edad); TOKENS hi-fi del README; LIENZO con margen
   de proyeccion; helpers ruta_insumos/ruta_salidas.
4. 31_leer_validar.R: lectura con clean_names(), RBD como character, validacion
   (NAs, tipos, bounding box, duplicados), numeracion norte->sur, escritura
   atomica a .rds.
5. 32_proyectar_lienzo.R: transformacion lineal lon/lat -> x/y% con bounding box
   fijo; marcador pin (Vina) / tarjeta (resto).
6. 33_generar_afiche.R: stub con arquitectura lista (data_uri, bloque_fontface,
   separar_tarjetas anti-colision, svg_costa); generar_afiche() pendiente.
7. 00_run_all.R: orquestador segun politica seccion 4.
8. 00_escanear_proyecto.R: escaner con retencion 2 atomica.
9. Decision documentada: 20260625_decision_densidad_marcadores.md.

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

### Clasificacion tematica (inicial, a refinar)
| Categoria | N | % | Descripcion |
|---|---|---|---|
| Infraestructura/scaffolding | 9 | 90 | Estructura, utils, config, orquestador, escaner, docs |
| Bugfix capa orquestacion | 1 | 10 | id de PASOS a integer (1L) |

(Taxonomia organica: se refina cuando entren cambios de otras categorias como
capa de datos, render del afiche, fidelidad visual, exportacion.)

### Resumen estadistico por sesion
| Sesion | Traspasos | Cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 | 10 | Opus 4.8 | Init Rama A + decision densidad + bugfix id |
| | | **10** | | **Total** |

### Detalle cronologico
Sesion 1 (cambios 1-9): ver seccion 4.
Cambio 10: fix id de PASOS a integer (1L) en 00_run_all.R; ver bug 1, seccion 6.

### Delta del backlog
Primera version: 10 entradas nuevas, taxonomia inicial propuesta.

## 6. Bugs de la sesion
- **Bug 1 — run_all() abortaba con "values must be type 'integer'".**
  - **Sintoma observable:** `run_all(to = 2)` fallaba en
    `vapply(PASOS, function(p) p$id, integer(1))` con
    "result is type 'double'".
  - **Causa raiz:** los `id` de PASOS se escribieron como literales numericos
    `1, 2, 3`, que en R son **double**, no integer. `vapply(..., integer(1))`
    exige integer estricto.
  - **Solucion exacta:** 00_run_all.R L24-26, `id = 1/2/3` -> `id = 1L/2L/3L`.
  - **Criterio de verificacion:** `run_all(to = 2)` corre y deja los dos .rds.
    Verificado en maquina (R 4.5.2): 97 leidos, 60 pines + 37 tarjetas, 0 warnings.
  - **Patron general aprendido:** en R, todo literal numerico que vaya a un
    contenedor tipado con `vapply(..., integer(1))` (o comparaciones de tipo
    estricto) debe llevar sufijo `L`. La regla aplica a cualquier `id`, indice o
    contador definido como constante en estructuras.
  - **Principios:** C.6 (rigor de tipado).
  - **Estado:** resuelto y commiteado.

## 7. Aprendizajes y restricciones descubiertas
- **El handoff es de muestra (17); el maestro real es 97.** Regla: nunca asumir
  que los datos de muestra del diseno definen el volumen real; el README ya
  advertia "~97, recalcular posiciones". Principio B.1.
- **60/97 en Vina obliga a repensar densidad.** Regla: una decision de diseno
  visual debe validarse con los datos reales renderizados, no con la descripcion
  (se renderizaron 3 opciones a tamano real antes de decidir).
- **RBD viene como integer en el Excel.** Regla: forzar a character al leer (es
  llave). Principio C.6.
- **El nombre de la carpeta lleva tilde en la captura ("georreferenciacion").**
  Regla: carpetas/archivos sin tildes (politica seccion 2); la raiz es
  slep_georreferenciacion.

## 8. Decisiones de diseno
- **Bifurcacion de sensibilidad:** Rama A (publico). Alternativa: Rama B. Se
  descarto porque no hay datos personales. Implicancia: 20_insumos/ y 40_salidas/
  dentro del repo.
- **Motor:** R genera HTML autocontenido + pagedown::chrome_print() a PDF.
  Alternativa: R solo produce JSON y la plantilla es HTML pura. Se eligio la
  primera para una sola fuente de verdad en el pipeline R.
- **Densidad de marcadores:** opcion C (ver decision dedicada en activa/decisiones).

## 9. Constantes y parametros vigentes
| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| LIENZO$ancho/alto | 1240/1754 | 10_configuracion.R | hi-fi README |
| margen_pct | x 6..94, y 5..95 | 10_configuracion.R | proyeccion al marco |
| COMUNA_PIN | "Viña del Mar" | 32_proyectar_lienzo.R | unica comuna con pin |
| COLISION_DY | 3.0 | 33_generar_afiche.R | anti-colision tarjetas (% viewBox) |
| MAPEO_TIPO | 5 entradas | 10_configuracion.R | Excel -> key |

## 10. Arquitectura de archivos
Ver escaner al cierre (estructura_actual.md). Estructura canonica Rama A; el
handoff de diseno vive en la raiz como referencia y fuente de fuentes/logo.

## 11. Pendientes y ruta sugerida

### Inventario
- **P1 — Construir generar_afiche() en 33.** Tipo: funcionalidad. Impacto: alto
  (es el entregable). Dependencias: 31 y 32 (listos). Complejidad: alta.
  Principios: B.3, C.7, C.10. Precaucion: fidelidad hi-fi al .dc.html; no truncar
  nombres; anti-colision real en Quintero/Concon. Criterio de exito: HTML 1240x1754
  que reproduce header/lista/mapa/footer con tokens exactos, 37 tarjetas sin
  solape grave y 60 pines en Vina, exportable a PDF con pagedown.
- **P2 — Validacion de fidelidad.** Tipo: deuda tecnica/QA. Render a PNG/PDF y
  comparar contra el handoff; checklist de reglas no negociables.
- **P3 — Resolver leader lines si el anti-colision vertical no basta.** Tipo:
  mejora visual. Solo si P1 muestra solapes residuales.

### Auditoria de cierre (politica 5.6, preguntas "Cierre")
- Pipeline corre de cero sin intervencion manual: 31-32 verificados en maquina;
  33 es stub -> pendiente P1.
- Outputs reproducibles e idempotentes: si (escritura atomica, sin estado).
- Decisiones metodologicas como constantes nombradas: si.
- Nombres sin tildes/enie/espacios: si.

### Ruta sugerida sesion 2
P1 primero (construir el afiche), luego P2 (validar fidelidad). P3 solo si hace
falta. Diferir cualquier feature fuera del afiche.

## 12. Instrucciones especificas para la proxima sesion
- ⚠️ NO implementar generar_afiche() sin releer el README del handoff y ambos
  .dc.html: los tokens y medidas mandan sobre el criterio estetico.
- ✅ ANTES de construir, verificar que 31 y 32 corren en la maquina (run_all(to=2))
  y que existen los .rds en 40_salidas/.
- 🔒 No truncar nombres de establecimientos en ningun marcador (regla 1 README).
- 🔒 Vina del Mar va solo con pines numerados; las otras 3 comunas con tarjeta
  numero + nombre + (RBD). Decision del titular, no reabrir sin pedido explicito.
- ✅ ANTES de commitear cualquier archivo nuevo, verificar nombre sin '-', ' ',
  ni tildes.

## 13. Fragmentos de codigo de referencia
```r
# Forma correcta de exportar el afiche a PDF A0 (paso manual):
pagedown::chrome_print(
  here::here("40_salidas", "afiche", "mapa_establecimientos.html"),
  output = here::here("40_salidas", "afiche", "mapa_establecimientos.pdf")
)
```

## 14. Reapertura

- **Nombre del chat:** `slep_georreferenciacion, sesion 2 (Opus 4.8)`
- **Mensaje de apertura pre-armado:** tipo CONTINUATION. El protocolo
  (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la
  knowledge base del Project y se lee desde ahi. Adjunto el traspaso v01, el
  escaner estructura_actual.md, y los scripts 31/32/33 + 10_configuracion.R como
  archivos criticos para construir el afiche.
- **Documentos para la proxima sesion:**
  1. Protocolo en knowledge base (NO adjuntar, solo verificar al dia):
     POLITICA_PROYECTO.md, SETTINGS_Y_PROMPTS_OPERACIONALES.md.
  2. Opcionales segun foco: README del handoff y los dos .dc.html (fidelidad del
     afiche); CLAUDE.md si corre en Claude Code.
  3. Especificos de la sesion (SI adjuntar): traspaso_cierre_v01.md;
     estructura_actual.md; 33_generar_afiche.R, 32_proyectar_lienzo.R,
     31_leer_validar.R, 10_configuracion.R.
- **Nota final:** si algun archivo cambio entre sesiones, adjuntar la version mas
  reciente y avisarlo en la apertura.
