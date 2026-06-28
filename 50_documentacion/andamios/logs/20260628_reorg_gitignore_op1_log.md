# LOG — Op.1 (reorganización) + gitignore pesados · Commit 1

- **Timestamp:** 2026-06-28
- **Secuencia corregida (sesión 6):** gitignore ANTES de mover, para que los PNG de
  exploración nunca entren al índice. Op.1 (reorg) y gitignore fusionados en **Commit 1**.
  Op.3 (purga de historial) queda separada, pendiente de su compuerta de backup.

## Patrones de .gitignore aplicados y peso que sacan de tracking
| Patrón | Archivos destrackeados | Peso |
|---|---|---|
| `/20_insumos/comunas_bcn/` | shp/dbf/shx/sbn/sbx/prj/cpg/shp.xml (8) | 61.2 MB |
| `40_salidas/afiche/*.pdf` | `…_slep_cc.pdf` (37) + `mapa….pdf` (2.7) | 39.7 MB |
| `40_salidas/afiche/*.afpub` | `…_slep_cc.afpub` | 6.4 MB |
| `40_salidas/afiche/*.html` | `mapa_establecimientos.html` | 4.6 MB |
| `40_salidas/afiche/*.png` | panel_norte, panel_vina, afiche_boceto_final | 3.6 MB |
| `40_salidas/exploraciones/**/*.png` (+pdf/afpub) | 29 renders movidos (nunca entran al índice) | ~25 MB |

**Mantenidos versionados** (no matchean): `comunas.geojson` (0.64 MB), `maestro_…xlsx`,
fuentes `.otf`, `logo-color-stacked.png` (input en design_handoff/), todos los `.R`, `.md`.
Verificado con `git check-ignore -v --no-index`.

## Movimientos (Op.1, modo real). 83/83, 0 errores. Registro: `_archivo/log_reorganizacion.csv` (83 filas)
| Destino | Cant. |
|---|---|
| `40_salidas/exploraciones/01_afiche_inset/scripts/` | 15 R |
| `40_salidas/exploraciones/01_afiche_inset/renders/` | 22 png (gitignored) |
| `40_salidas/exploraciones/02_escala_unica_posicion/{scripts,renders}/` | 2 R + 4 png |
| `40_salidas/exploraciones/03_escala_unica_tamano_pin/{scripts,renders}/` | 1 R + 3 png |
| `_archivo/20260628/` (gitignored) | 35 sobras |
| `30_procesamiento/30_preparar_comunas.R` (rescate) | 1 |

Mecánica: `cp -p` → verifica destino existe + mismo tamaño → `rm` origen. `scratchpad_afiche/`
quedó vacío y se eliminó.

## Commit 1 = `a49cf63`
`refactor: reorganizar exploraciones (solo texto) y gitignorar binarios pesados`
- 25 adds (18 .R de exploración + 30_preparar_comunas.R + 6 docs andamios), 15 deletions
  (git rm --cached: comunas_bcn ×8 + afiche products ×7), 1 modified (.gitignore).

## Auto-auditoría adversarial (Op.1 + gitignore)
- **¿Pipeline/productos cambiaron de CONTENIDO?** No. `git diff --stat` de 31/32/33/
  00_run_all/10_*/maestro = vacío. Productos afiche: solo cambió tracking, bytes en disco. ✔
- **¿Cada archivo movido en destino antes de borrar origen?** Sí (cp+verificación de
  tamaño antes de rm). 83/83. ✔
- **¿30_preparar_comunas.R íntegro?** Sí (cp -p byte-exacto; head/tail coinciden con el
  original leído en Fase A). ✔
- **¿.gitignore excluye algo liviano valioso?** No: geojson/maestro/.R/.md/.otf/logo
  intactos en tracking. ✔
- **¿`git rm --cached` borró algo del DISCO?** No: afiche products y comunas_bcn siguen en
  disco. ✔
- **¿.png de exploración trackeados?** 0. **.R de exploración trackeados:** 18. ✔
- **¿Commits separados?** Sí: Commit 1 = reorg+gitignore; Op.3 (purga) será su propio
  proceso. ✔
- **Nota:** 6 archivos de `50_documentacion/estructura/` (snapshot del escáner de las
  09:01) quedaron SIN commitear a propósito (no son parte de la reorg; se regenerarán al
  re-correr 00_escanear_proyecto.R post-Op.3).

## Op.3 — prep read-only (sin tocar nada) para la compuerta de backup
- Tamaño actual `.git`: **102.98 MiB** (objetos sueltos, sin empaquetar).
- **git-filter-repo: NO instalado** → tarea manual del titular antes de continuar
  (`brew install git-filter-repo` o `pip install git-filter-repo`).
- Pesados aún en el HISTORIAL a purgar: `comunas_bcn/comunas.shp` 61 MB,
  `…_slep_cc.pdf` 37 MB, `…_slep_cc.afpub` 6.4 MB, **múltiples versiones** de
  `mapa_establecimientos.html` (~2.3 MB × varias) y `mapa_establecimientos.pdf` 2.7 MB,
  más panel_*.png. La acumulación de versiones del HTML es parte del peso del historial.

## Estado: PARA en compuerta de Op.3 (backup). Espera OK del titular + instalación de filter-repo.
