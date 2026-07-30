# Traspaso de cierre — sesión 12

**Fecha:** 2026-07-30 · **Tipo:** CONTINUATION · **Proyecto:** `slep_georreferenciacion`
**Sucede a:** `traspaso_cierre_v11.md` · **Rama:** `main` · **Remoto:** `tomgc/slep_territorio_costa_central`

> **Estado del working tree al escribir este traspaso: NO verificado en esta sesión de cierre.**
> Un encargo (corrección de hachurado, pendiente K) quedó CORRIENDO en Claude Code al momento
> de cerrar. La primera acción de la sesión 13 es correr `git status --short --branch` y
> `git log --oneline origin/main..main`, y reconciliar contra lo que este traspaso declara.
> (hipotesis, verificar con: `git status --short --branch`)

---

## 1. Qué se hizo en la sesión 12

Sesión larga. Cerró la construcción de las dos capas del Censo 2024 (densidad y asistencia),
las auditó contra el artefacto, blindó el pipeline, rehízo el front-end, y pusheó dos
sesiones de trabajo acumulado. Detalle por hito:

### Hito 2b (capa de manzana) — auditado y CERRADO
- El script `37_construir_capa_manzana.R` y `censo_manzanas_cc.geojson` (5.753 features,
  1.474 ceros, gzip ~426 KB) quedaron verificados **contra el artefacto**, no contra el log.
  `MANZENT` string, CUT nchar 4, 0 coords vacías, md5 `0a2cc82a…` determinista.
- **Discrepancia del backlog detectada, NO resuelta:** el `backlog_acumulativo.md` disponible
  hoy llega al cambio 24; v09/v10 afirman que el commiteado en `9f39df5` llega al 25. Hay
  una versión desactualizada en circulación. (pendiente G)

### Hito 3 (capa de asistencia zonal) — construido, auditado, ampliado
- `38_construir_capa_zonal.R` + `censo_zonal_r5.geojson`: 1.216 features (692 urbanas + 524
  rurales), región continental (excluye insulares 5104/5201). Indicador crudo, jamás "tasa
  neta". Canario 0,60 pp ≤ 0,75.
- **Tres decisiones/defectos resueltos en Claude Code** (todos medidos): simplificación →
  solape (recorte rural∖urbano, "urbano manda en el borde", 0,089 ha residual); universo
  continental (524/692, no 532/694); defecto de escritura GDAL (GeometryCollection vacía,
  fix con `st_collection_extract`).
- **Umbral de fiabilidad (pendiente A) — CERRADO.** El diagnóstico del Hito 2a midió el
  denominador AGREGADO POR COMUNA y nunca por unidad; a nivel de unidad, el p10 de básica es
  4 y ~19 % de unidades daban proporción 0/1 con denominador mediano de 5. Se añadió
  `DENOM_MINIMO = 20` (medido: codo de la sd, censura ≤ 2,7 % de los niños) y campo
  `fiable_<nivel>` con TRES estados (NA / FALSE / TRUE). GeoJSON regenerado a 15 columnas.
  Verificado sobre el artefacto: 0 unidades con den≥20 y proporción 0,0 (el caso patológico
  temido no existe); las 42 patológicas que sobreviven son todas asistencia plena (1,0), que
  es real.

### Hito 4 (front-end de las dos capas) — construido
- Bloque "Capas del Censo" (Ninguna / Densidad / Asistencia, mutuamente excluyentes), arriba
  de la Leyenda. Sub-selector de tramo (densidad) / nivel (asistencia).
- Coropleta sutil: rampa monocroma azul de baja saturación, fillOpacity 0,45, sin bordes,
  pane `censo` zIndex 330 (bajo máscara 350, frontera 370, pines 400). Los pines mandan.
- Carga diferida y cacheada, con indicador en vuelo. Canvas para densidad (medido Hito 1).
- Densidad: cero fuera de la escala (gris propio). Asistencia: tres estados, tres
  tratamientos (rampa / gris / hueco-contorno). Cortes MEDIDOS sobre el dato.
- Popup sin cifra comunal del INE (§3.5). Rotulado correcto ("proporción del grupo en edad
  oficial que asiste al nivel"). Verificado: "tasa neta" solo aparece en la frase que la NIEGA.

### Front-end (mío, en paralelo a Claude Code)
Barra de filtros horizontal de una fila bajo la cabecera; Provincia oculto (no eliminado,
`F.prov` = null); botón limpiar → ícono sutil; SLEP en vez de "Servicio Local de Educación";
"Nombre del establecimiento"; botones de exportar en una fila con texto corto; sidebar 330 →
270px; footer eliminado, atribución al pie del panel; máscara invertida (todo lo que no es
Región de Valparaíso continental se vela, #EAE6DC @0,72, pane 350, incluida en el SVG).

### Auditorías de calidad (patrón matriz de la sesión)
- **Pendiente B — CERRADO.** Las 230 manzanas colapsadas del script 37 se auditaron: **0
  niños** en los tres tramos (medido; las sumas del GeoJSON igualan los totales de Costa
  Central, confirmación independiente). Se instaló una **guardia permanente** (`stop()` con
  umbral CERO) que aborta si una tolerancia futura o un dato nuevo empiezan a colapsar
  manzanas con población. La guardia **se vio disparar** (tolerancia 300 m → 33.901 niños).

---

## 2. Push realizado (con un defecto de proceso — pendiente M)

Se pushearon dos sesiones de trabajo acumulado: `a508b98..0159dfc`. El sello del `.gitignore`
de los parquet (309 MB) resistió; `size-pack` quedó en 1,05 MiB (sano, nada pesado entró).

**DEFECTO DE PROCESO (pendiente M):** los comandos de commit se entregaron en un bloque con
comentarios `#` y saltos de línea que zsh interpretó como comandos. El primer `git add`
colapsó los 7 commits planificados en UNO SOLO: `0159dfc` se llama
`chore(gobernanza): sella los insumos del Censo` pero contiene **25 archivos** (scripts,
GeoJSON, andamios, front-end, traspaso). **Es un `git add .` disfrazado, contra POLITICA 9.7.**
No se corrige (ya está en el remoto). Se declara aquí para que nadie lea ese commit como
evidencia de que sólo se tocó el `.gitignore`. (fuente: salida de terminal de la sesión 12)

---

## 3. Errores registrados esta sesión (patrón recurrente)

| # | Error | Causa raíz | Patrón |
|---|---|---|---|
| 1 | Afirmé que `mapa.js` "no llegó a mi contexto" y pedí re-adjuntarlo; estaba en disco y era legible | Confundí "no renderizado como texto" con "no existe". No verifiqué el disco | Afirmar estado sin contrastar contra el artefacto (8ª sesión del mismo patrón matriz) |
| 2 | Entregué comandos de terminal con `#` y saltos que zsh ejecutó como comandos → 7 commits colapsaron en 1 | Entregué un bloque *legible* en vez de *ejecutable*; no verifiqué que sobreviviera a copy-paste en zsh | Forma de entrega, no contenido |

**Aprendizaje de la sesión (más grande que los bugs):** una regla escrita no es una regla
aplicada. El contrato del indicador zonal derivó "mirar la distribución del denominador antes
de mapear una tasa" y aun así la capa se construyó sin aplicarla a la escala de publicación
(pendiente A). El mismo patrón en el pendiente B (contar colapsadas sin mirar su contenido).
Las gatechecks de gobernanza protegen el estado del repo; NO protegen las afirmaciones
diagnósticas sobre el dato. Cada aserción diagnóstica debe volverse medición antes de volverse
recomendación.

---

## 4. Pendientes acumulados (para la sesión 13)

| # | Pendiente | Prioridad |
|---|---|---|
| **C** | `TOL_SOLAPE_HA = 0.5` en el script 38 se fijó DESPUÉS de medir 0,089 ha. Mismo patrón que v11 §5.2 rechazó ("un test calibrado para tolerar el error conocido no valida nada"). Menor, pero anotado | Baja |
| **D** | `run_all()` sin argumentos corre los pasos 4 y 5 (Censo), que dependen de 309 MB de parquet gitignored. En máquina nueva FALLA aunque el afiche esté perfecto. Decidir: grupos de pasos, o salto con mensaje claro | **Alta** |
| **E** | La unión zonal cubre 95,3–99,8 % del área comunal; el resto aparece como huecos. Reportado en el render como slivers finos, no agujeros grandes. Decidir tratamiento | Media |
| **F** | Cobertura POBLACIONAL de la unión zonal nunca medida (solo área). Barato: sumar `n_edad_*` vs total comunal INE | Media |
| **G** | Versión del `backlog_acumulativo.md`: el disponible llega al 24, el repo (`9f39df5`) al 25. Traer `git show 9f39df5:…backlog_acumulativo.md` y reconciliar. Además van 9+ entradas sin incorporar (26–34) | **Alta** |
| **H** | La nota metodológica pública debe declarar el umbral de denominador: 22–29 % de las unidades quedan sin color por denominador insuficiente. Es visible; hay que explicarlo | Media |
| **I** | Concón pierde 9,76 % de sus manzanas por simplificación (todas 0 niños). En el render se leen como celdas más claras, no huecos. Verificado, sin acción pendiente salvo mención en nota | Baja |
| **J** | El SVG exportado NO incluye las capas del Censo. Decisión de alcance, no defecto. Diferido | Baja |
| **K** | El gris "denominador insuficiente" se confunde con el fondo entre polígonos. **Encargo de hachurado CORRIENDO al cierre.** Verificar su resultado es la 2ª acción de la sesión 13 | **Alta (en vuelo)** |
| **L** | `GRIS_CENSO_CERO` y `GRIS_CENSO_RUIDOSO` a 22 pts de luminancia, ambos @0,42. No colisionan (capas excluyentes) pero el nombre confunde. Se renombra dentro del encargo K | Baja |
| **M** | El commit `0159dfc` es un `git add .` disfrazado (ver §2). No se corrige; se declara | Cerrada (registro) |
| **N** | **Incorporar todos los jardines infantiles de la región al proyecto.** Nuevo eje de trabajo (fuente: matrícula/directorio de educación parvularia — JUNJI / Integra / VTF, a definir). Alcance, fuente de datos y granularidad por decidir | **Nueva, a planificar** |

---

## 5. Primeras acciones de la sesión 13 (en orden)

1. Committear los artefactos de cierre de la sesión 12 (este traspaso, ESTADO.md, escáner).
2. `git status` + `git log origin/main..main`: reconciliar el working tree real contra lo que
   el §1 de este traspaso declara (el hachurado quedó en vuelo).
3. Verificar el resultado del encargo de hachurado (pendiente K) contra el artefacto.
4. Traer el `backlog_acumulativo.md` real del repo y reconciliar (pendiente G).
5. Decidir el pendiente D (`run_all()` en máquina nueva) antes de que alguien clone en limpio.

---

## 6. Estado invariante del proyecto (no cambió esta sesión)

- Arquitectura dual-agente: Claude (planificación/auditoría/documentos) + Claude Code
  (filesystem/git). Máximo 2 agentes Claude Code simultáneos.
- Protocolo en la knowledge base: `POLITICA_PROYECTO.md` (v5.2),
  `SETTINGS_Y_PROMPTS_OPERACIONALES.md` (v7).
- Insulares (5104, 5201) excluidas de todas las capas. Microdato de personas NO entra al
  proyecto. `docs/data/` solo agregados sin identificador individual.
- Scripts locked sin instrucción explícita: `00_run_all.R`, `31`–`36`, `10_*`. El backlog no
  se renumera ni reescribe retroactivamente.
- Tomás descarga y reemplaza los archivos él mismo. El asistente entrega el archivo, no genera
  comandos para moverlo.
