# Traspaso de cierre v04 — slep_georreferenciacion

## 1. Identificación
- **Proyecto:** slep_georreferenciacion (afiche cartográfico A0, SLEP Costa Central)
- **Versión:** v04
- **Fecha:** 2026-06-28
- **Sesión 4, foco:** (a) migrar el proyecto a GitHub privado; (b) reorganizar el
  desorden de `scratchpad_afiche/` en exploraciones; (c) adelgazar el repo purgando
  pesados del historial; (d) explorar una variante paralela del afiche a "escala única"
  (sin inset de Viña) mediante una larga cadena de sondeos visuales. Cierre **con la
  variante diseñada y su Fase 1 encargada pero NO ejecutada ni auditada**.
- **Entorno:** Positron / R 4.5.2. Locale UTF-8 obligatorio. Red solo para tiles CARTO.
  Git + GitHub privado. `git-filter-repo` 2.47.0 instalado vía Homebrew.
- **Tipo de sesión:** CONTINUATION.
- **Repo remoto:** `https://github.com/tomgc/slep_territorio_costa_central.git` (privado).
  Nombre del repo ≠ nombre de carpeta local (`slep_georreferenciacion`); divergencia
  aceptada y consciente.

## 2. Resumen ejecutivo
La sesión migró el proyecto a GitHub privado como **Rama A** (datos públicos del
directorio MINEDUC; se versionan), tras confirmar que el maestro no contiene datos
protegidos de NNA. La auditoría de seguridad pre-migración no arrojó hallazgos
bloqueantes. Luego se reorganizó la "ensalada" de `scratchpad_afiche/` (83 archivos
planos) en `40_salidas/exploraciones/{01,02,03}/{renders,scripts}/`, versionando **solo
texto** (scripts y docs) y dejando los PNG/binarios en disco fuera del repo. Se rescató
`preparar_bcn.R` al pipeline como `30_preparar_comunas.R`. Finalmente se purgó el
historial con `git filter-repo` (102.98 MiB → 1.05 MiB, ~99%), eliminando el shapefile
crudo y los productos pesados del afiche del historial de git, con backup espejo previo y
force-push al único clon. En paralelo se exploró una **variante a escala única** (sin
inset de Viña) con cinco sondeos visuales sucesivos; se decidió **A (in situ puro) + pin
al 60% (T2)** y se **encargó la Fase 1 (33b), que queda pendiente de ejecución y
auditoría** para la próxima sesión. El producto original (con inset) permanece intacto y
es la opción preferida del titular.

## 3. Estado al cierre
**Funciona / hecho:**
- Repo privado en GitHub, `main` sincronizado con remoto en `359c367`.
- Repo adelgazado (~1 MB de historial). Estructura ordenada (verificado por escáner
  20260628_104224).
- Producto original `mapa_establecimientos.{html,pdf}` byte-idéntico en disco (NO tocado
  en toda la sesión; mtime 11:15 conservado en cada verificación).
- `30_preparar_comunas.R` rescatado al pipeline (no cableado a `00_run_all`).
- Decisión de diseño de la variante tomada: **A in situ + T2 (radio 60%)**.

**No hecho / pendiente:**
- La **Fase 1 de la variante (33b) NO se ejecutó**: solo se redactó el encargo. No existe
  aún `33b_generar_afiche_escala_unica.R` ni sus salidas
  `mapa_establecimientos_escala_unica.{html,pdf}`. **Primera tarea de la próxima sesión:
  ejecutar y auditar.**

**Delta respecto a v03:**
- v03 cerró con el afiche original terminado. v04 añade: versionado en GitHub, repo
  limpio y liviano, exploraciones ordenadas, y el diseño (no la construcción) de la
  variante escala única.

## 4. Registro detallado de cambios (sesión 4)

### Migración a GitHub (Rama A)
- Confirmado con el titular que el maestro solo tiene RBD/nombre/tipo/comuna/coordenadas
  (todo público MINEDUC) → Rama A (raíz unificada, datos versionados), NO Rama B.
- Adaptado el script de diagnóstico de migración (de otro proyecto, era Rama A pública
  pero con premisa contraria) a este proyecto. Corrido: 12 hallazgos, ninguno bloqueante
  (7 falsos positivos OneDrive = el propio regex auto-detectándose; 1 naming heredado en
  `design_handoff/`; 4 archivos de datos REVISAR confirmados públicos).
- `.gitignore` Rama A; primer commit sobre repo preexistente; push inicial (104 MB).

### Reorganización de scratchpad (Operación 1)
- `scratchpad_afiche/` (83 archivos planos, anti-patrón política 1.6) → reorganizado.
- Destino: `40_salidas/exploraciones/01_afiche_inset/{renders,scripts}/` (histórico
  sesiones 1-3), `02_escala_unica_posicion/`, `03_escala_unica_tamano_pin/`.
- **Solo texto versionado** (18 .R de exploración); PNG en disco, gitignored.
- Sobras (35) → `_archivo/20260628/` (gitignored). `scratchpad_afiche/` eliminado.
- `preparar_bcn.R` → `30_procesamiento/30_preparar_comunas.R` (rescate, byte-idéntico,
  NO cableado a `00_run_all`).

### Gitignore de pesados + destrackeo (Operación 2, fusionada en 1 por orden)
- Patrones aplicados ANTES de mover (para que los PNG nunca entren al índice).
- Destrackeados ~115 MB (comunas_bcn/ 61 MB, afiche *.pdf 39.7 MB, *.afpub 6.4 MB,
  *.html 4.6 MB, *.png 3.6 MB), todos conservados en disco.
- Mantenidos versionados: comunas.geojson (0.64 MB), maestro .xlsx, fuentes .otf,
  scripts, docs.

### Purga de historial (Operación 3, DESTRUCTIVA)
- Backup espejo `../slep_repo_backup_20260628.git` (verificado 32==32 commits, HEAD
  a49cf63) ANTES de tocar nada.
- `git filter-repo --invert-paths` sobre comunas_bcn/ + afiche *.pdf/*.afpub/*.html/*.png.
- `.git` 102.98 MiB → 1.05 MiB (~99%). Hashes reescritos (a49cf63 → c3e983b).
- Verificado: purgados = 0 ocurrencias en historial; comunas.geojson/maestro/scripts/.otf
  conservados; .shp y productos siguen en disco.
- Force-push autorizado (único clon): 8240557 → c3e983b. Commit final 359c367 (snapshot
  post-purga + logs), push fast-forward. Remoto consistente en 359c367.

### Exploración de la variante escala única (cadena de sondeos)
- **Fase 0 (geométrica):** medido que a escala única el GATE de anti-colisión NO se
  dispara: separar_pines resuelve los 60 de Viña sin proxy (desp máx ~23 mm A0, densidad
  0.40). La premisa del encargo original (cluster que no cabe) era falsa.
- **Sondeo A/C:** A (in situ puro) vs C (proxy+leader a grilla, el mockup del titular).
  Visto: C genera telaraña de 53 leaders que tapa la costa; A más limpio. A gana.
- **Sondeo D/E:** D (arco descarga) = 96 cruces, peor; E (círculo compacto) desplaza sin
  beneficio. Ambas peores que A.
- **Sondeo T1/T2/T3 (tamaño de pin):** reducir radio mejora congestión Y fidelidad. T2
  (60%) = balance legibilidad/densidad. Decisión final: **A + T2**.
- Fase 1 (33b) **encargada, no ejecutada**.

## 5. Backlog acumulativo
*(Nota: este traspaso hereda el backlog conceptual de v01-v03; aquí se registran los
cambios de v04. La taxonomía formal de backlog del protocolo 2.2.5 no se mantuvo
explícitamente en v01-v03; se recomienda formalizarla si el proyecto continúa, pero NO se
inventa retroactivamente aquí — B.1.)*

Cambios v04 por categoría:
- **Gobernanza/versionado:** migración Rama A, .gitignore, purga de historial, backup.
- **Reorganización estructural:** scratchpad → exploraciones, rescate 30_preparar_comunas.
- **Diseño (exploración):** 5 sondeos de la variante escala única, decisión A+T2.

## 6. Bugs de la sesión
- **No hubo bugs de código.** Un punto de proceso notable: el orden Op.1/Op.2 (mover vs
  gitignorar) se corrigió ANTES de ejecutar — gitignorar primero evitó meter ~25 MB de
  PNG al índice para sacarlos dos commits después. **Regla aprendida:** al reorganizar +
  gitignorar, aplicar el ignore ANTES del movimiento, no después.

## 7. Aprendizajes y restricciones descubiertas
- **Un `.gitignore` no destrackea lo ya commiteado.** Para sacar pesados del historial
  hace falta `git rm --cached` (futuro) o `filter-repo` (pasado, destructivo). Regla: si
  un pesado YA está en el historial, gitignorarlo no adelgaza el repo.
- **filter-repo reescribe TODOS los hashes y exige force-push.** Solo seguro si no hay
  otros clones. Regla: confirmar clones únicos antes de reescribir historial; backup
  espejo obligatorio ANTES.
- **filter-repo elimina el remoto `origin` por seguridad.** Hay que re-agregarlo tras la
  purga, antes del push.
- **El escáner ve el disco; `git ls-files` ve el repo.** Tras purgar, el escáner sigue
  mostrando los pesados (están en disco) aunque ya no estén versionados. No confundir.
- **comunas_bcn/ es dato fuente externo no regenerable por script.** Purgado del repo +
  gitignored: el pipeline normal corre (usa comunas.geojson versionado), pero regenerar
  el .geojson desde cero exige recolocar el .shp a mano (re-descargable de BCN). Es
  reproducibilidad parcial, asumida.
- **El mockup del titular (proxy+leader) era válido para 1 pin, no para 60.** Escalado a
  60, las leader lines colapsan en telaraña. Los sondeos visuales existían para descubrir
  esto; la métrica sola no convencía, la imagen sí.
- **A escala única la densidad de Viña no se "arregla" reposicionando.** 60 en poca
  superficie se ven densos siempre; solo el tamaño de pin (no la posición) alivia sin
  costo. Reducir radio mejora congestión Y fidelidad a la vez.

## 8. Decisiones de diseño
- **Rama A (no B):** maestro sin datos protegidos → datos públicos versionables. Alterna:
  Rama B (dos raíces). Justificación: el directorio MINEDUC es público; no hay NNA.
- **Versionar solo texto, gitignorar pesados:** el repo guarda código y documentación; las
  imágenes se reproducen desde scripts. El titular se retractó de versionar pesados a
  mitad de sesión (mejor gestión a largo plazo). Excepción consciente registrada:
  exploraciones en `40_salidas/` (no write-only puro) por ser producto estático de pocas
  variantes.
- **Purgar historial (no solo gitignorar futuro):** adelgazamiento real del repo, asumiendo
  la reescritura destructiva. Alterna: solo gitignore (deja el pasado pesado). Justificación:
  proyecto de meses; repo liviano facilita gestión.
- **Variante escala única: A (in situ) + T2 (60%):** tras 5 sondeos. Alternas exploradas y
  descartadas: C (proxy+leader, telaraña), D (arco, peor), E (círculo, desplaza sin ganar),
  T1 (poco alivio), T3 (números ilegibles a distancia). Justificación: balance
  legibilidad/densidad/fidelidad geográfica.
- **33b vía source(33, local=TRUE):** reusar funciones de 33 sin editarlo. Verificado que
  local=FALSE dispararía el flujo de 33 por accidente. Alternas descartadas: extraer a
  34_comun.R (rompe byte-idéntico de 33), copiar/pegar (duplicación).

## 9. Constantes y parámetros vigentes
| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| PIN_RADIO_PX (producción) | 11·ESC = 58.74 px PNG | 33 | original con inset |
| PIN_RADIO variante | 0.60 × producción | 33b (pendiente) | decisión T2 |
| ESC | 5.3404 | 33 | 200·841/(25.4·1240) |
| ratio glifo/diámetro | ≈ 0.72 | sondeo tamaño_pin | fuente al máximo |
| Numeración | N→S 1..97 por latitud | 33 (numerar()) | 🔒 oficial |
| Colores tipo | jardín #6a8a3a, escuela #2d5f8a, liceo #c8732e, especial #7a4a8a, adultos #555 | 33 | |
| Azul institucional comuna | #0F69B4 | 33 | etiquetas HTML |

## 10. Arquitectura de archivos
- Escáner al cierre: `50_documentacion/estructura/20260628_104224_estructura.{md,txt}`
  (post-purga). Estructura conforme a política tras la reorganización.
- Cambio estructural mayor: scratchpad eliminado; `40_salidas/exploraciones/` creado;
  `30_preparar_comunas.R` añadido al pipeline.
- `.gitignore` actualizado: excluye pesados (comunas_bcn/, afiche *.pdf/*.afpub/*.html/
  *.png, exploraciones **/*.png), el diagnóstico de migración, scratchpad (ya inexistente),
  _archivo/.

## 11. Pendientes y ruta sugerida

### Inventario de pendientes
1. **[bloqueante para la variante] Ejecutar y auditar la Fase 1 (33b).** El encargo está
   redactado (ver §13). Construir `33b_generar_afiche_escala_unica.R`, render full-res,
   HTML panel único, PDF A0 `_escala_unica`. Auditar: 33 intacto, numeración 1..97, índice
   completo, PDF A0 editable, pines radio 60% sin solape, "97" legible. Complejidad: Media.
   Criterio éxito: variante generada + auditada + original intacto.
2. **Validación in situ del original en Affinity** (heredado v03 #1-4): confirmar etiquetas
   de comuna editables, fuentes gobCL no sustituidas (instalar las .otf antes), posición de
   Concón (top 98.84%, riesgo de recorte) y Puchuncaví. Tarea del titular.
3. **Cablear 30_preparar_comunas.R a 00_run_all** (opcional; toca el orquestador 🔒).
   Decidir si la variante 33b también entra al orquestador o queda como script
   independiente.
4. **Borrar el backup espejo** `../slep_repo_backup_20260628.git` cuando el titular valide
   el remoto a gusto. Tarea del titular.
5. **Constantes muertas** (heredado v03 #6): `BUFFER_VISUAL_DEG` no aparece en config/32/33
   (ya eliminada de facto); `COLOR_TIPO` SÍ se usa. Deuda menor de lo anotado; cerrar
   verificando en 33.
6. **Documentar locale UTF-8 en README** (heredado v03 #7).
7. **Reproducibilidad de comunas_bcn:** documentar en README que el .shp crudo es local/
   re-descargable de BCN (no versionado tras la purga); el pipeline usa comunas.geojson.

### Auditoría de cierre (política 5.6, preguntas "Cierre")
- ¿Pipeline corre de cero sin intervención manual? **Parcial:** 30_preparar_comunas.R y
  33b no están en run_all; comunas_bcn no viaja al repo. Deuda documentada.
- ¿Outputs reproducibles e idempotentes? Sí para el original; la variante aún no existe.
- ¿Decisiones metodológicas como constantes nombradas? Sí (radio, ratio glifo).
- ¿Nombres sin tildes/ñ/espacios? Sí, salvo `Prototipo Mapa Establecimientos.dc.html`
  (handoff externo, excepción declarada).

### Ruta sugerida próxima sesión
1. **Verificar productos** (lo pidió el titular): confirmar estado del original y del
   repo remoto tras la purga.
2. **Ejecutar Fase 1 (33b)** y auditar (pendiente #1).
3. Cierre menor de deudas (#5, #6, #7) si queda tiempo.

## 12. Instrucciones específicas para la próxima sesión
- 🔒 Producto original `mapa_establecimientos.{html,pdf}` y `33_generar_afiche.R`:
  NO tocar. La variante es 33b adicional.
- 🔒 `31`, `32`, `00_run_all`, `10_*`, maestro: no tocar sin instrucción.
- 🔒 Numeración N→S 1..97 oficial y colores por tipo: invariantes.
- 🔒 No filtrar puntos por contención (RBD 1699, 33476 son falsos positivos válidos).
- ✅ ANTES de ejecutar 33b, confirmar la API real de 33 (nombres de funciones/constantes)
  leyéndolo, no de memoria.
- ✅ ANTES de borrar el backup espejo, validar el remoto.
- ⚠️ NO cablear 30_preparar_comunas.R ni 33b a 00_run_all sin decisión explícita (🔒
  orquestador).
- ⚠️ NO versionar pesados (PNG/PDF/afpub/shp): el criterio es solo-texto al repo.

## 13. Fragmentos de código de referencia
- **El encargo completo de la Fase 1 (33b)** está en el historial de esta conversación
  (último mensaje del asistente antes del cierre). Contiene: contrato, invariantes,
  Paso 0 (confirmar API de 33), construcción de 33b vía source(local=TRUE), salidas
  `_escala_unica`, panel adversarial y formato de log. Reproducirlo tal cual en la próxima
  sesión.
- **Patrón source seguro:** `e <- new.env(); source(here::here("30_procesamiento",
  "33_generar_afiche.R"), local = e)` — local=TRUE (vía env) NO dispara el flujo principal
  de 33; local=FALSE SÍ lo dispararía (verificado empíricamente en Fase 0).

## 14. Reapertura

**Nombre del chat:** `slep_georreferenciacion, sesión 5 (Opus 4.8)`

**Mensaje de apertura pre-armado:**
> Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md y
> SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se lee
> desde ahí. Adjunto el traspaso v04, el escáner actual, y los archivos críticos para
> retomar (33_generar_afiche.R para confirmar su API antes de construir 33b). Foco
> propuesto: verificar productos y ejecutar/auditar la Fase 1 de la variante escala única.

**Documentos para la próxima sesión:**
1. *Protocolo (en knowledge base, NO adjuntar, solo verificar que esté al día):*
   `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco:* `CLAUDE.md` (si corre en Claude Code).
3. *Específicos de la sesión (SÍ adjuntar):* este traspaso `traspaso_cierre_v04.md`; el
   escáner `estructura_actual.md`; `30_procesamiento/33_generar_afiche.R` (crítico: la
   Fase 1 debe confirmar su API real antes de construir 33b); `10_configuracion.R` y
   `32_proyectar_lienzo.R` si se quiere contexto del lienzo. Los renders de los sondeos
   (T1/T2/T3, A/C/D/E) están en `40_salidas/exploraciones/` en disco si se quieren revisar.

**Nota final:** si algún archivo listado cambió entre sesiones, adjuntar la versión más
actualizada al abrir y avisarlo en el mensaje de apertura.
