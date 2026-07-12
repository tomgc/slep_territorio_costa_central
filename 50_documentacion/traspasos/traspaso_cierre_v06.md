# Traspaso de cierre — v06

**Proyecto:** slep_georreferenciacion · **Fecha:** 2026-07-12 · **Sesión:** 6
**Entorno:** Claude (conversacional) + Claude Code (Fable) · **Repo remoto real:** `https://github.com/tomgc/slep_territorio_costa_central`
**Archivos principales modificados/creados:** README.md; 30_procesamiento/34, 35, 36; docs/ completo (mapa interactivo publicado)

---

## 1. Resumen ejecutivo

Sesión larga y de alto rendimiento: se cerraron las deudas menores del proyecto original (variantes 1 y 2, ambas awaiting director), y se construyó de punta a punta la **variante 3: mapa interactivo regional**, un producto nuevo que no reemplaza a las anteriores. Se diagnosticaron los insumos (directorio oficial nacional, histórico de matrícula 2004–2025, planilla de macrogrupos de enseñanza), se construyó el pipeline (34→35→36) con reglas de cálculo auditadas a tolerancia 0, se resolvieron tres decisiones de alcance no triviales (exclusión de territorio insular, recodificación de dependencia SLEP vigente 2026, tratamiento de EE sin registro de matrícula), y se construyó el front-end completo (Leaflet, 7 filtros acumulativos, exportación SVG/XLSX) con identidad visual del afiche. El mapa está **publicado y en producción** en GitHub Pages. Quedó pendiente el re-chequeo visual final del titular (en curso al cierre) y el diagnóstico del Censo 2024, que se aborda en sesión aparte. Se cometieron y registraron 4 errores del asistente durante la sesión, todos del mismo patrón (aceptar datos/cifras sin verificar contra el estado real).

---

## 2. Estado al cierre

**Funciona (última ejecución exitosa 2026-07-12):**
- Variantes 1 y 2 (afiches estáticos): sin cambios funcionales esta sesión; solo se cerró deuda de README. Awaiting director.
- Pipeline 34→35→36: genera `establecimientos.geojson` (1.251 pins), `sin_geo.json` (17), `metadatos.json`. Idempotente, auditado a tolerancia 0 dos veces (datos base + recodificación SLEP + fix de oferta histórica).
- Mapa web (`docs/`): publicado en `https://tomgc.github.io/slep_territorio_costa_central/`. Funcional completo: pins con paleta por dependencia/SLEP, hover con síntesis de enseñanza, click con 4 indicadores + 3 estados + sparkline, 7 filtros acumulativos con opciones dependientes, exportación SVG y XLSX, fronteras territoriales, rótulos de comuna.
- Ambas auditorías del mapa web (6.A asignación SLEP exhaustiva RBD-por-RBD, 6.B funcional adversarial) en verde.

**No funciona / pendiente:**
- Re-chequeo visual final del titular: en curso al momento del cierre (checklist entregado, resultados no reportados aún en esta sesión).
- `.gitignore` de `40_salidas/mapa_interactivo/*.rds`: instruido, no confirmado su cierre en esta sesión.
- README no menciona la variante 3 (todo lo construido hoy).
- La relación `slep_georreferenciacion` (producto) ↔ `slep_estudio_oferta_demanda` (proyecto principal) no está documentada en ningún archivo del proyecto.

**Delta respecto a v05:** v05 dejaba el proyecto con variantes 1 y 2 completas esperando director, y deuda menor documental. Esta sesión no tocó esa deuda de fondo (director sigue sin responder) pero SÍ cerró toda la deuda documental menor (#4, #5, #6, #8 de v05) y construyó la variante 3 completa desde cero.

---

## 3. Registro detallado de cambios

### 3.1 Deudas menores del proyecto original (heredadas de v05)
- README actualizado: ambas variantes documentadas, nota de locale UTF-8, nota de `comunas_bcn` (re-descargable, el pipeline usa `comunas.geojson` versionado). Commit `79bdf4e`.
- `BUFFER_VISUAL_DEG`: verificado, no existe en `33_generar_afiche.R` (falso positivo de v03; cerrado sin acción).
- Backup espejo `../slep_repo_backup_20260628.git`: borrado por el titular (comando de terminal, tarea manual).
- Decisión de no cablear `33b` a `00_run_all.R`: evaluada, rechazada (costo de tocar archivo 🔒 supera el beneficio en un proyecto ya terminado).

### 3.2 Diagnóstico de insumos para la variante 3
Categoría temática: **diagnóstico de datos**. Insumos identificados: `directorio_oficial_ee_publico.csv` (nacional, UTF-8 pese a lo asumido inicialmente — divergencia D2 del reporte de diagnóstico), `historico_matricula/Matricula-por-estudiante-YYYY` (2004–2025, matrícula por MRUN), `Matricula-Ed.-Parvularia-YYYY` (excluida del conteo, ver 3.4), `codigo_tipo_y_macrogrupo.xlsx` (planilla canónica de macrogrupos, provista por el titular), `listado_slep_2026.xlsx` (comuna→SLEP, con año de traspaso y excepciones).
Verificado (no asumido): encoding, separador, BOM, headers en case variable entre años, cobertura del join RBD, tamaño y tiempo de lectura. Documentado en `reporte_diagnostico_mapa_interactivo.md`.

### 3.3 Exclusión de territorio insular (decisión de alcance, v1)
Categoría: **decisión de diseño**. Rapa Nui (Isla de Pascua) y Juan Fernández excluidos de todo el producto v1 (no solo del mapa: tampoco en tablas ni XLSX). Criterio: geográfico-insular (territorio oceánico separado, sistema educativo propio, población muy particular que no dialoga con el propósito del mapa — entender el SLEP Costa Central y su entorno continental inmediato). Por qué: (a) argumento cartográfico inicial (3.500 km distorsionan encuadre); (b) argumento de propósito del titular, más sólido (las islas no son "entorno" del SLEP). Implementado por **comuna insular** (COD_COM_RBD 5201 Isla de Pascua, 5104 Juan Fernández), no por provincia (Valparaíso provincia 51 es mayoritariamente continental; solo se excluye la comuna insular). Universo final: 1.268 EE (de 1.274 tras solo ESTADO_ESTAB=1). **Pendiente v2:** ambos territorios son candidatos a capa/inset separado; los datos son válidos, la exclusión es de alcance, no de calidad.

### 3.4 Parvularia jardines JUNJI/Integra fuera del conteo (v1)
Categoría: **decisión de diseño**. El archivo de parvularia NO se integra al conteo de matrícula por RBD: duplicaría a los párvulos de escuelas (ya cuentan vía `Matricula-por-estudiante`, COD_ENSE=10; solape de MRUN 100% verificado). El 36% del archivo parvularia no tiene RBD (usa `ID_ESTAB`, universo JUNJI/Integra). Cortes temporales distintos (31-ago vs 30-abr) rompen comparabilidad. Consecuencia: los jardines JUNJI/Integra no aparecen en el mapa (no tienen RBD, no están en el directorio). **Pendiente v2 (explícitamente solicitado por el titular):** poblar esta capa; los datos existen (`Matricula-Ed.-Parvularia-YYYY`), requiere universo con `ID_ESTAB` y fuente de geo propia (catastro JUNJI/Integra).

### 3.5 Recodificación de dependencia SLEP vigente 2026
Categoría: **decisión de diseño / regla de negocio**. El directorio oficial (corte 30-abr-2025) antecede a varios traspasos a SLEP que ya ocurrieron o son inminentes (la mayoría el 1-ene-2026, según el titular). Se implementó en `34_preparar_directorio_region.R` una recodificación explícita (`TRASPASO_SLEP_VIGENTE_2026`): comunas con `AGNO_TRASPASO_EDUC ≤ 2026` según `listado_slep_2026.xlsx` se muestran como SLEP con su nombre, aunque el directorio las tenga como municipales. Excepciones respetadas: Zapallar (Petorca, postergada a 2027), Santo Domingo (del Litoral, postergada a 2028), del Litoral completo (2027), Quillota (2029) — todos siguen municipales. Gate compuesto (no un total único, por la lección de abajo): `N_SLEP_DEP5_DIRECTORIO=127` (Valparaíso 54 + Costa Central 73) + `N_SLEP_RECODIFICADOS=216` (Aconcagua 67, Marga Marga 58, Petorca-sin-Zapallar 55, Los Andes 36) = **343**. Declarado explícitamente en `metadatos.json` para que el usuario del mapa sepa que la dependencia no es literal del directorio 2025.
**Por qué gate compuesto y no total único:** en la primera corrida, el gate compuesto atrapó que `slep_nombre` se había asignado también a EE particulares de comunas traspasadas (un total único de 343 habría pasado igual, porque el conteo agregado seguía correcto). Regla aprendida: **verificar por partes, no solo el agregado; un total correcto puede esconder una asignación incorrecta.**

### 3.6 Tratamiento de EE sin registro de matrícula
Categoría: **decisión de diseño**. 85 EE (60 sin ningún año en la ventana 2016–2025, 25 en cierre progresivo) no tienen matrícula ni, por tanto, tipos de enseñanza derivables del crudo. Se investigó y descartó rellenar desde el directorio oficial (`ENS_01..11` es también matrícula-dependiente por definición de la glosa oficial: "códigos con al menos un alumno matriculado al 30 de abril" — no existe fuente de autorización administrativa independiente de la matrícula). Solución implementada: (a) los 25 en cierre progresivo muestran su oferta HISTÓRICA, derivada del último año con matrícula (campo `ensa` = año de procedencia; texto "Impartía hasta 20XX: [oferta]"); (b) los 60 sin ningún registro declaran explícitamente la ausencia ("Sin registros de matrícula ni enseñanza (2016–2025)" en tooltip; texto más largo en la tarjeta). **Hallazgo relevante para el titular/director:** los 85 son en su totalidad de modalidades no obligatorias (21 parvularia + 3 adultos + 1 especial en los 25; el perfil de los 60 es casi enteramente jardines particulares pagados). Sugiere que el sistema de matrícula única no captura bien la parvularia privada — no es un defecto del pipeline, es una característica de la fuente que el mapa hace visible.

### 3.7 Bug de encoding R→JS: huecos como `{}` en vez de `null`
Categoría: **bug de código, crítico**. `jsonlite` serializa `NULL` dentro de listas como `{}`, no como `null`; R trata ambos como equivalentes al releer (`read_json`), pero JavaScript no (`{} !== null`). Síntoma real: el popup de un EE en cierre progresivo (RBD 14439) decía "Registró matrícula hasta 2025" cuando su serie terminaba en 2022 — el hueco pasaba por dato. La auditoría de datos en R no lo detectó porque comparaba en R, donde el defecto es invisible. **Regla aprendida, la más importante de la sesión:** los artefactos que cruzan de R a JS deben auditarse desde el consumidor (releídos y comparados en el lenguaje que los va a usar), no solo desde el productor. Corregido en 36 (`NA_integer_` en vez de `NULL`), verificado con grep literal sobre el JSON publicado.

### 3.8 Bug hermano: `auto_unbox` desempaqueta arrays de un elemento
Categoría: **bug de código**. Un EE con un solo nivel de enseñanza se serializaba como escalar (`"Nivel Medio Mayor"`) en vez de array (`["Nivel Medio Mayor"]`), rompiendo el JS (`niv.map is not a function`). Misma familia que 3.7. Resuelto con normalización defensiva en el consumidor (JS). No se tocó el productor (no era necesario funcionalmente), pero queda anotado como tercera evidencia de la regla de auditar desde el consumidor.

### 3.9 Front-end del mapa (Leaflet)
Categoría: **construcción de producto**. Construido en 5 hitos con puntos de detención: (1) esquema + paleta con contraste calculado; (2) mapa base + pins + hover + click + sparkline; (2b/2c/2d) correcciones iterativas de paleta, fronteras territoriales, encuadre, hover orgánico, tarjeta rediseñada, síntesis de enseñanza en hover, rótulos de comuna propios; (3) 7 filtros acumulativos con opciones dependientes (arquitectura de facetas: cada filtro recalcula sus opciones sobre el subconjunto que cumple LOS DEMÁS filtros, no a sí mismo — evita el atrapamiento clásico de esta UI); (4) exportación SVG (vectorial, sin tiles raster, declarado) y XLSX (locale español vía celdas numéricas nativas, incluye los 17 sin geo).

---

## 4. Bugs de la sesión

Ver 3.7 y 3.8 (encoding R→JS). Ambos resueltos, verificados, con regla general documentada.

---

## 5. Aprendizajes y restricciones descubiertas

1. **Auditar desde el consumidor, no solo desde el productor.** R y JS tienen semánticas distintas para "ausencia de valor" (`{}` vs `null`, escalar vs array de 1). Una auditoría que solo relee en R puede dar tolerancia 0 y aun así el producto real (consumido en JS) tener un bug. Regla: todo artefacto que cruce de lenguaje debe verificarse al menos una vez desde el lenguaje consumidor.
2. **Gates compuestos, no totales únicos.** Un total agregado correcto puede esconder una asignación incorrecta en sus componentes (caso 3.5: 343 total correcto con `slep_nombre` mal asignado a particulares). Verificar por partes cuando la corrección de la asignación importa tanto como el conteo.
3. **Un dato del usuario no es un dato verificado por venir del usuario.** Tres errores de esta sesión (ver §7) comparten esta causa raíz: aceptar una cifra, ruta o URL sin contrastarla contra el estado real (el RDS, el filesystem, `git remote -v`), incluso cuando la fuente parecía autorizada.
4. **Las fuentes administrativas de "qué imparte un EE" son todas matrícula-dependientes.** No existe en los insumos disponibles una fuente de autorización de oferta educativa independiente de si hubo matrícula reportada (ni el directorio ni el histórico). Esto es una restricción de los datos MINEDUC, no del pipeline.

---

## 6. Decisiones de diseño (resumen; detalle en 3.3–3.6)

| Decisión | Alternativas consideradas | Resuelto |
|---|---|---|
| Territorio insular fuera de v1 | Incluir con encuadre ajustado; incluir sin ajuste | Excluido, por propósito (no por cartografía) |
| Parvularia jardines fuera del conteo | Integrar sumando; integrar con flag | Fuera; v2 pendiente |
| Dependencia SLEP vigente 2026 vs. literal del directorio | Mostrar solo lo del directorio 2025 | Vigente 2026, declarado en metadatos |
| EE sin matrícula: ocultar vs. mostrar con "sin dato" | Ocultar del universo | Mostrar, con texto explícito |
| Paleta pins: 8 azules vs. 2 vs. familia amplia | Opción B (1 azul para no-CC) | Familia azul amplia (Opción A), con piso de contraste 3:1 |
| SVG con/sin basemap | Incrustar tiles | Sin tiles (declarado); vectorial completo |

Decisiones arquitectónicas de peso (3.3, 3.5) recomendadas para archivo propio en `50_documentacion/activa/decisiones/` — no se generó en esta sesión por volumen; **pendiente**.

---

## 7. Errores del asistente (POLITICA 0.5 — registro obligatorio)

| # | Momento | Disparador | Qué pasó | Regla violada | Causa raíz | Salvaguarda presente | Patrón |
|---|---|---|---|---|---|---|---|
| 1 | Inicio de sesión, comandos de terminal para Claude Code | Usuario lo corrigió | Entregué comandos con rutas relativas en vez de ruta completa desde la raíz | userPreferences (rutas completas siempre) | Asumí working directory sin declararlo | userPreferences | Nuevo |
| 2 | Encargo 35+36, gate de universo SLEP | Asistente lo señaló (vía hallazgo de Claude Code) | Fijé el gate en 344 EE usando una cifra del diagnóstico previa a la exclusión insular, sin revalidar | POLITICA 1.2.6 (no operar sobre estado supuesto) | Arrastré una cifra de un reporte anterior sin recomputarla tras un cambio de universo que yo mismo había instruido | POLITICA + el propio encargo | Mismo patrón que #3 y #4 |
| 3 | Validación visual del hito 2 | Usuario lo señaló | Pedí "validación visual" sin indicar cómo levantar el servidor local para ver el mapa | Ninguna regla específica; omisión de instrucción completa | No verifiqué que la instrucción fuera accionable antes de darla | — | Nuevo (omisión, no dato incorrecto) |
| 4 | Diagnóstico de publicación en Pages | Usuario lo corrigió | Acepté sin verificar la URL de repo que el usuario dio al inicio de sesión, y luego le dije a Claude Code que SU URL (correcta) estaba mal | POLITICA 0.2 / 1.2.6 (no deducir ni inventar; verificar contra `git remote -v`) | Traté un dato del usuario como verificado por venir del usuario, en vez de contrastarlo contra el remoto real | POLITICA 0.2 | Mismo patrón que #2 |

**Patrón cruzado a vigilar en sesiones futuras (y en el análisis de cartera):** 3 de los 4 errores (#2, #4, y parcialmente el origen de #1) comparten la misma causa raíz — aceptar una cifra, ruta o URL sin verificarla contra el artefacto/comando real, incluso cuando parecía ya establecida en la conversación. Ninguno fue "no lo sabía": en los tres casos la verificación era trivial y estaba disponible (`git remote -v`, releer el RDS, confirmar el cwd). Vale la pena que si este patrón aparece en otros proyectos de la cartera, se trate como señal de que la regla "verificar contra el estado real" necesita un mecanismo más fuerte que la sola declaración de principio.

---

## 8. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `N_ANIOS` | 10 | 35 | Ventana 2016–2025, fija por disponibilidad de MRUN |
| `COMUNAS_INSULARES_EXCLUIDAS_V1` | 5201, 5104 | 34 | Isla de Pascua, Juan Fernández |
| `N_SLEP_DEP5_DIRECTORIO` | 127 | 34 | Valparaíso 54 + Costa Central 73 |
| `N_SLEP_RECODIFICADOS` | 216 | 34 | Aconcagua 67, Marga Marga 58, Petorca-sin-Zapallar 55, Los Andes 36 |
| `N_SLEP_TOTAL_ESPERADO` | 343 | 34 | Gate compuesto |
| `TRASPASO_SLEP_VIGENTE_2026` | TRUE | 34 | Constante de activación de la regla, documentada |
| `TEXTO_SIN_MATRICULA` | "Sin matrícula en 2025." | 36 | Literal exacto |
| `ETIQUETA_SIN_DATO` | "sin dato" | 36 | Literal exacto |
| Universo continental | 1.268 EE | 34 | Post-exclusión insular |
| Pins con geo | 1.251 | 34/36 | 17 sin geo (`sin_geo.json`) |
| Piso de contraste paleta | ≥3.0:1 (WCAG) | mapa.js | Sobre fondo Positron |

---

## 9. Arquitectura de archivos

Ver escáner adjunto (`estructura_actual.md`, 2026-07-12). Cambios de estructura respecto a v05: nuevos `30_procesamiento/34,35,36`; nuevo árbol completo `docs/` (mapa publicado); `20_insumos/auxiliares/` poblado (directorio nacional, planilla de macrogrupos, listado SLEP, diccionario de territorios); `40_salidas/mapa_interactivo/` (no visible en el escáner por estar en `.gitignore`, correcto). Todo conforme a la política de decenas; `34/35/36` correlativos correctos, no colisionan con `30/31/32/33/33b`.

---

## 10. Pendientes y ruta sugerida

| # | Pendiente | Tipo | Complejidad | Sugerencia |
|---|---|---|---|---|
| 1 | Re-chequeo visual del titular (checklist entregado) | Funcionalidad / QA | Baja | Primera acción de la próxima sesión si no se completó |
| 2 | `.gitignore` de `40_salidas/mapa_interactivo/*.rds` | Deuda técnica (gobernanza) | Baja | Confirmar que el commit se hizo; si no, hacerlo primero |
| 3 | README: documentar variante 3 + relación con `slep_estudio_oferta_demanda` | Documentación | Media | Antes de mostrar el repo a terceros |
| 4 | Decidir visibilidad del sitio Pages (público en repo privado) | Decisión estratégica | Baja | Definir con el titular si es aceptable o requiere GitHub Pro |
| 5 | Validación con equipo experto | Bloqueante externo | — | Depende de terceros |
| 6 | Validación del director (afiches 1 y 2) | Bloqueante externo | — | Sigue abierto desde v05 |
| 7 | Diagnóstico Censo 2024 | Exploratorio | Alta | Encargo ya escrito (`50_documentacion/andamios/`, ver §12); sesión propia recomendada |
| 8 | Capa jardines JUNJI/Integra (v2) | Funcionalidad nueva | Alta | Requiere universo `ID_ESTAB` + geo propia |
| 9 | Inset territorio insular (v2) | Funcionalidad nueva | Media | Datos ya excluidos pero disponibles |
| 10 | Archivo de decisión propio para 3.3 y 3.5 | Documentación | Baja | `50_documentacion/activa/decisiones/` |
| 11 | Auditoría de apertura próxima sesión | — | — | Ver checklist política 5.6 abajo |

**Evaluación de deuda técnica:** ninguna zona fràgil nueva detectada; el pipeline 34-35-36 está doblemente auditado. El front-end (`docs/mapa.js`, 40.87K) creció orgánicamente en 5 hitos; si crece más, evaluar modularización (hoy: simplicidad > modularidad, sin reuso real que la justifique).

**Auditoría de cierre (política 5.6):**
- ¿Pipeline corre de cero sin intervención manual? Sí para 34→35→36; el front-end requiere `sincronizar_docs.sh` manual (documentar en README — pendiente #3).
- ¿Cada transformación crítica tiene validación? Sí (gates compuestos, stopifnot).
- ¿Outputs reproducibles e idempotentes? Sí, verificado por hash en cada etapa.
- ¿Decisiones metodológicas como constantes nombradas? Sí.
- ¿Nombres sin tildes/ñ/espacios? Sí.

**Ruta sugerida próxima sesión:** (1) cerrar re-chequeo visual + gitignore rds si quedaron sueltos; (2) README + relación con proyecto padre; (3) esperar/incorporar feedback del equipo experto; (4) diagnóstico Censo como sesión BIBLIOTECA-adyacente o CONTINUATION dedicada, con contexto fresco.

---

## 11. Instrucciones específicas para la próxima sesión

- ⚠️ NO asumir que el repo remoto se llama `slep_georreferenciacion`: es `slep_territorio_costa_central`. Verificar con `git remote -v` al abrir, no repetir el error #4.
- ⚠️ NO tocar `00_run_all.R`, `33`, `33b`, `31`, `32`, `10_*`, maestro, ni `34/35/36` sin instrucción explícita: todos 🔒 y auditados.
- ✅ ANTES de cualquier cambio a los JSON de `docs/data/`: son productos de un pipeline auditado dos veces; cualquier modificación exige repetir el ciclo diagnóstico→cambio→re-auditoría, como se hizo con la recodificación SLEP y el fix de huecos.
- ✅ ANTES de fijar cualquier gate o cifra de validación: verificar contra el artefacto real (RDS/JSON), no reusar una cifra de un reporte anterior sin recomputar.
- 🔒 Territorio insular (Rapa Nui, Juan Fernández) y parvularia JUNJI/Integra: exclusiones de ALCANCE v1, no de calidad de dato. No "arreglar" reincluyéndolos sin que sea un encargo v2 explícito.
- 🔒 Máximo 2 agentes en Claude Code (instrucción del titular vigente para toda la cartera de encargos de este proyecto).

---

## 12. Fragmentos de código de referencia

**Patrón de gate compuesto (la forma correcta en este proyecto), de `34_preparar_directorio_region.R`:**
```r
N_SLEP_DEP5_DIRECTORIO <- 127L   # ya SLEP en el dato: Valparaíso 54 + Costa Central 73
N_SLEP_RECODIFICADOS   <- 216L   # municipales recodificados por traspaso <= 2026
N_SLEP_TOTAL_ESPERADO  <- 343L   # 127 + 216

stopifnot(
  sum(universo$dependencia_original == "SLEP") == N_SLEP_DEP5_DIRECTORIO,
  sum(universo$recodificado) == N_SLEP_RECODIFICADOS,
  sum(universo$dependencia == "Servicio Local de Educación") == N_SLEP_TOTAL_ESPERADO
)
```

**Patrón de serialización segura R→JSON para huecos (nunca `NULL` desnudo dentro de listas destinadas a JS):**
```r
# INCORRECTO: jsonlite serializa NULL dentro de listas como {}, no null
serie <- list(2016 = valor_o_null)  # riesgo si valor_o_null es NULL

# CORRECTO: usar NA_integer_, y toJSON(na = "null")
serie <- list(2016 = if (hay_dato) valor else NA_integer_)
jsonlite::toJSON(serie, na = "null", auto_unbox = TRUE)
```

---

## 13. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 7 (Fable)`

**Mensaje de apertura pre-armado:**
> Continuación (CONTINUATION) de `slep_georreferenciacion`. El protocolo (POLITICA_PROYECTO.md + SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior y el escáner más reciente.

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (NO adjuntar, solo verificar vigencia): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco*: si la sesión aborda el Censo, adjuntar `diccionario_variables_censo2024.xlsx` y `Ficha_metodologica_CPV2024.pdf` del proyecto padre (fuera de este repo); si se documenta la relación con el proyecto principal, no requiere adjuntos adicionales.
3. *Específicos de la sesión (SÍ adjuntar)*: este traspaso (`traspaso_cierre_v06.md`); el escáner `estructura_actual.md` re-ejecutado al abrir (el de esta sesión data de 2026-07-12 07:18, antes del cierre — re-correr); resultado del re-chequeo visual del titular si quedó pendiente de esta sesión.

**Nota final:** si el re-chequeo visual generó correcciones después de este cierre, documentarlas como sesión 6-bis o incorporarlas al inicio de la sesión 7 antes de avanzar a nuevo trabajo.
