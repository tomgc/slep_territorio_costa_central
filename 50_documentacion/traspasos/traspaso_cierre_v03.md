# Traspaso de cierre v03 — slep_georreferenciacion

## 1. Identificación
- **Proyecto:** slep_georreferenciacion (afiche cartográfico A0, SLEP Costa Central)
- **Versión:** v03
- **Fecha:** 2026-06-26
- **Sesión 3, foco:** completar el afiche (P1 pendiente de v02) y llevarlo a
  entregable final en dos formatos (HTML autocontenido + PDF A0 editable). Cierre
  **con entregable aprobado y auditado**: el afiche está terminado y cumple todo lo
  acordado a lo largo de las tres sesiones.
- **Entorno:** Positron / R 4.5.2; salida HTML/SVG estático, PDF vía
  `pagedown::chrome_print()`. Locale UTF-8 obligatorio. Red solo para tiles CARTO.
- **Tipo de sesión:** CONTINUATION.

## 2. Resumen ejecutivo
La sesión 2 cerró sin diseño aprobado (el nudo de marcadores no convencía). La
sesión 3 resolvió el paradigma visual y completó el afiche mediante **ocho ciclos
de encargo formal** al protocolo dual-Claude (conversacional redacta encargos y
audita; Claude Code ejecuta R/git/render con panel adversarial obligatorio). El
resultado es un afiche A0 vertical de 97 establecimientos, sobre tile CARTO
Positron sin rótulos, con límites comunales BCN de alta resolución, pines grandes
coloreados por tipo con anti-colisión 2D garantizada, numeración geográfica
estricta N→S, etiquetas de comuna en azul institucional como **texto HTML
editable**, índice lateral con número+nombre+RBD, y exportación a **PDF A0 con
texto y fuentes editables en Affinity**.

Cada entrega de Claude Code fue **verificada de forma independiente** por Claude
conversacional sobre el HTML/PNG/PDF reales (no se confió en el log de Claude
Code como única fuente de calidad).

## 3. Cadena real de versiones ejecutadas (sesión 3)
Importante para la trazabilidad: **el v5 se redactó pero el titular se lo saltó**;
el v6 se redactó asumiendo erróneamente que el v5 estaba aplicado (error de Claude
conversacional al encadenar sin verificar estado). Claude Code lo detectó y lo
señaló honestamente. El v5 se reancló después como **v7**.

| Encargo | Qué hizo | Estado |
|---|---|---|
| **v1** — paradigma D | Etiquetas al mar con leader lines sobre CARTO Positron real. Bug data-masking cazado por panel adversarial (índice ×4 oculto por overflow). | SUPERSEDED |
| **v2** — simplificado | Quita etiquetas y leader lines del mapa; solo pines + índice. | SUPERSEDED |
| **v3.1** — límites BCN | Reemplaza GeoJSON fcortes (groseramente generalizado, comunas solapadas) por shapefile BCN alta resolución. | DONE |
| **v4** — pines grandes | Anti-colisión 2D real (repulsión de discos, min_dist ≥ 2·PIN_RADIO_PX) + zonas de exclusión para rótulos de ciudad del tile. | DONE |
| **v5** — tile sin rótulos + etiquetas comuna | Redactado. **SALTADO por el titular** (no ejecutado). | SKIPPED |
| **v6** — numeración N→S + nota + índice | Numeración estricta por latitud; nota del Área de Monitoreo; índice a alto completo (fuente 10,3 px, tope por no-overflow). Ejecutado sobre v4 real. | DONE |
| **v7** — tile sin rótulos + etiquetas comuna | Reancla el v5 sobre el v6. Tile PositronNoLabels, zonas de exclusión eliminadas, 4 etiquetas de comuna azul gobCL. | DONE |
| **v8** — export PDF A0 | PDF A0 vertical (841×1189 mm), texto editable, fuentes incrustadas, mapas regenerados a resolución A0. | DONE |
| **v9** — etiquetas como texto HTML | Las 4 etiquetas de comuna salen del PNG (geom_text) y pasan a texto HTML position:absolute sobre el mapa → editables en Affinity. | DONE |

## 4. Estado final del afiche (diseño consolidado, NO re-litigar sin instrucción)
- **Formato doble:** `40_salidas/afiche/mapa_establecimientos.html` (autocontenido)
  y `40_salidas/afiche/mapa_establecimientos.pdf` (A0 vertical, 841×1189 mm).
- **Mapa principal** (panel norte: Puchuncaví/Quintero/Concón) + **inset Viña del
  Mar** (60 pines).
- **Tile:** CARTO Positron **sin rótulos** (PositronNoLabels).
- **Límites comunales:** shapefile BCN alta resolución
  (`20_insumos/comunas_bcn/comunas.shp`).
- **Pines:** grandes (PIN_RADIO_PX=22), coloreados por tipo (jardín verde #6a8a3a,
  escuela azul #2d5f8a, liceo naranja #c8732e, especial morado #7a4a8a, adultos
  gris #555), anti-colisión 2D garantizada (min_dist ≥ 44 px verificado).
- **Numeración:** estrictamente N→S por latitud (1 = más al norte, 97 = más al
  sur), sin agrupar por tipo. Rangos por comuna: Puchuncaví 1-20, Quintero 21-30,
  Concón 31-37, Viña 38-97 (se mantienen porque las comunas no se solapan en
  latitud).
- **Etiquetas de comuna:** 4, azul institucional gobCL #0F69B4, como **texto HTML
  editable** sobre el mapa. Posiciones finales (left%/top%): Puchuncaví
  50,02/40,59 · Quintero 18,79/73,17 · Concón 20,43/98,84 · Viña 26,37/42,32.
- **Índice lateral:** número+nombre+RBD, agrupado por comuna, color por tipo,
  leyenda de tipos, fuente 10,3 px, a alto completo.
- **Nota de pie:** texto del Área de Monitoreo (de elaboración propia).
- **Editable en Affinity:** todo el texto (índice, título, nota, leyenda, las 4
  etiquetas de comuna). **No editable (imagen):** tile, límites, pines y sus
  números.

## 5. Verificaciones independientes acumuladas (Claude conversacional)
Sobre los artefactos reales, no sobre el log de Claude Code:
- Numeración N→S: latitud monótona decreciente, 0 violaciones, 97/97.
- Anti-colisión pines: min_dist 47,4–47,8 px ≥ 44, 0 solapes, ambos planos.
- Índice: 97 nombres + 97 RBD, cada uno exactamente 1 vez, sin truncar.
- Etiquetas de comuna: 4 presentes, azul gobCL, 0 pines encima, 1 sola vez c/u.
- PDF: A0 exacto (841,0×1188,9 mm), texto extraíble (4960 chars), fuentes
  gobCL/MuseoSans incrustadas (Type 3), acentos correctos sin mojibake.
- v9: las 4 etiquetas son texto editable en el PDF, posiciones geográficamente
  coherentes (norte→sur = top% creciente).

## 6. Pendientes vivos (para la próxima sesión)
1. **Validación in situ en Affinity Publisher** (headless render ≠ pantalla real):
   - Confirmar que las 4 etiquetas de comuna se seleccionan como texto.
   - Confirmar que gobCL no se sustituye (requiere fuentes instaladas, ver #2).
2. **Posición de Concón** (top 98,84%, pegada al borde inferior del panel con
   `overflow:hidden`): riesgo de recorte. Verificar en Affinity; si está cortada,
   arrastrarla a mano (ahora es texto). **# REVISAR**
3. **Posición de Puchuncaví**: quedó en el inland este (no sobre el pueblo
   costero), por ser la palabra más larga y estar el sector poblado lleno de
   pines. Ajustable a mano en Affinity si se desea. **# REVISAR**
4. **Instalar fuentes gobCL y Museo Sans** en el equipo antes de editar en
   Affinity (los .otf están en `design_handoff_mapa_establecimientos/fonts/`).
   Tarea manual del titular.
5. **Deuda de reproducibilidad:** los scripts `preparar_bcn.R`, `dev_render.R` y
   los de calibración v4 (zonas, render) viven en `scratchpad_afiche/`
   (gitignored). El pipeline canónico (31/32/33 + run_all) es reproducible, pero
   la preparación del shapefile BCN y la calibración no están en el repo versionado.
   Decidir si se promueven a `30_procesamiento/` o se documenta su carácter de
   andamiaje desechable.
6. **Constantes muertas:** `BUFFER_VISUAL_DEG` (y según versión `TOL_SIMPLIFY_M`,
   `COLOR_TIPO` si quedó huérfana) declaradas sin uso. Marcar `# REVISAR` o
   eliminar.
7. **Documentar dependencia de locale UTF-8** en el README (el mapeo de tipos con
   tilde en el 31 lo exige).
8. **Limpieza opcional de salidas:** `40_salidas/afiche/` tiene dos PDF
   (`mapa_establecimientos.pdf` 2,71 MB y `mapa_establecimientos_slep_cc.pdf`
   36,98 MB) y un `afiche_boceto_final.png`. Revisar cuál es el vigente y si el de
   37 MB (probable export antiguo de alta resolución) debe conservarse.

## 7. Aprendizajes de proceso (sesión 3)
- **Verificación independiente sistemática:** Claude conversacional auditó cada
  entrega sobre el artefacto real (extracción de PNG, detección de pines por color,
  medición de anti-colisión, extracción de texto/fuentes del PDF). Esto cazó
  matices que el log no mostraba (p. ej. fuentes Type 3 que un parser ingenuo
  reporta como "no incrustadas").
- **Estado verificado, no supuesto:** el error v5/v6 (encadenar un encargo sobre un
  estado asumido no confirmado) llevó a la regla de que **cada encargo declara
  explícitamente el estado real verificado**. El v7 en adelante lo hace.
- **Claude Code señaló honestamente la discrepancia** del "v5 inexistente" en vez
  de fingir que el estado calzaba: comportamiento correcto del protocolo.
- **Distinción raster vs vector como tema recurrente:** los rótulos del tile y las
  etiquetas geom_text son imagen; solo el texto HTML es editable. Esta distinción
  guió los v7 (tile sin rótulos) y v9 (etiquetas a HTML).

## 8. Invariantes del proyecto (heredados, vigentes)
- 🔒 No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R` sin instrucción.
- 🔒 Los puntos no se filtran por contención en polígono (2 falsos positivos del
  GeoJSON costero son válidos: RBD 1699 Concón, RBD 33476 Quintero).
- 🔒 Tarjetas-sobre-punto es geométricamente imposible para Puchuncaví (20 en
  franja insuficiente): settled, no re-litigar.
- 🔒 Diseño "Boceto D" consolidado: no revisar sin instrucción explícita del titular.
- `chilemapas` no disponible en R 4.5 → shapefile BCN local es el fallback fijado.
- `COMUNAS_ORDEN` en `10_configuracion.R` usa Latin-1/unknown: normalizar a ASCII
  antes de comparar con factores UTF-8.

## 9. Reglas de colaboración (heredadas, vigentes)
- El titular reemplaza archivos él mismo manualmente. Claude **nunca** genera
  comandos de terminal para mover/copiar/renombrar/reemplazar archivos.
- Claude **no** inicia cierre de sesión ni genera traspaso sin que el titular lo
  pida explícitamente.
- Diseño primero, código después: ningún código R antes de boceto aprobado.
- Cada encargo a Claude Code incluye panel de auto-auditoría adversarial.
- Mensajes a Claude Code en bloque "→ Claude Code:".
- Honestidad directa ante fallos: sin excusas ni explicaciones largas.

## 10. Artefactos clave (rutas)
- Pipeline: `00_run_all.R`, `30_procesamiento/{31,32,33}*.R`.
- Insumos: `20_insumos/maestro_establecimientos.xlsx` (hoja "maestro transporte"),
  `20_insumos/comunas_bcn/comunas.shp`.
- Salidas: `40_salidas/afiche/mapa_establecimientos.{html,pdf}`,
  `40_salidas/establecimientos_{validados,proyectados}.rds`.
- Encargos: `50_documentacion/andamios/encargo_claude_code_*.md` (v1, v2, v3.1, v4,
  v6, v7, v8, v9).
- Logs de Claude Code: `50_documentacion/andamios/logs/*_log.md` (8 logs,
  integrados a este traspaso por referencia).
- Auditorías re-ejecutables: `50_documentacion/andamios/auditoria_*.R`.
- Fuentes y logo: `design_handoff_mapa_establecimientos/{fonts,assets}/`.
- Traspasos previos: `50_documentacion/traspasos/traspaso_cierre_v0{1,2}.md`.

## 11. Estado de git
Repo en `main`. Último ciclo (v9): commits 95e127d (feat 33), 48ecfea (build),
c0002ba (docs). PDF gitignored (es entregable regenerable). 31/32 intactos
(verificado por git diff en cada encargo).
