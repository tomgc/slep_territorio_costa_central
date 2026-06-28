# LOG — Op.3 Purga de historial (filter-repo) · hasta Compuerta 4

- **Timestamp:** 2026-06-28
- **Naturaleza:** reescritura de historial DESTRUCTIVA con backup. Ejecutada hasta la
  Compuerta 4 (ANTES del force-push). El force-push NO se ha hecho.

## Precondición
- `git-filter-repo` instalado (`/opt/homebrew/bin/git-filter-repo`, funcional). Nota: su
  `--version` imprime el hash de build (homebrew); es la 2.47.0 instalada por el titular.

## Backup (gate de seguridad)
- `git clone --mirror . ../slep_repo_backup_20260628.git` (creado en sesión previa).
- Verificación inmediata ANTES de filter-repo: commits repo=32 == backup=32. backup HEAD
  = `a49cf63` (pre-purga). `.shp` presente en disco (61M). → GATE OK, se procedió.

## Comando filter-repo exacto
```
git filter-repo --force --invert-paths \
  --path 20_insumos/comunas_bcn/ \
  --path-glob '40_salidas/afiche/*.pdf' \
  --path-glob '40_salidas/afiche/*.afpub' \
  --path-glob '40_salidas/afiche/*.html' \
  --path-glob '40_salidas/afiche/*.png'
```
- `--force` porque se corre sobre el repo de trabajo (no un clon fresco); el backup espejo
  es la red de seguridad.
- filter-repo eliminó el remoto `origin` por seguridad (URL registrada:
  `https://github.com/tomgc/slep_territorio_costa_central.git`). Se **re-agregó**.

## Tamaño .git: antes / después
| | size-pack | total |
|---|---|---|
| ANTES | (sin empaquetar) | **102.98 MiB** |
| DESPUÉS (tras gc) | **1.05 MiB** | ~1.05 MiB |
**Reducción ≈ 99%** (101.9 MiB liberados del historial).

## Hashes pre/post (todos reescritos)
- PRE  HEAD (backup): `a49cf63efd8732e1c772877e6dde2e4ad049f695`
- POST HEAD:          `c3e983bb482d95ee21cbbf97b9e2e0004cc0e071`
- 32 commits reescritos, mismos mensajes/estructura, nuevos hashes.

## Verificación de la purga
**Ausentes del historial completo (`git rev-list --objects --all`), 0 ocurrencias c/u:**
`comunas_bcn`, `afiche/*.pdf`, `afiche/*.afpub`, `afiche/*.html`, `afiche/*.png`. ✔

**Blobs más grandes restantes** (ninguno es un pesado purgado):
`comunas.geojson` 1.6 MB (full-res) y 0.64 MB (simplificada), `logo-color-stacked.png`
126 KB, fuentes `.otf` ~60 KB, `33_generar_afiche.R` ~27 KB. ✔

**Valiosos que SIGUEN en el historial:** comunas.geojson (2 versiones),
maestro_establecimientos.xlsx (1), 33_generar_afiche.R (9 versiones), 30_preparar_comunas.R
(1), fuentes .otf. → nada valioso se purgó por error. ✔

## Auto-auditoría adversarial
- ¿Backup restaurable y verificado ANTES de filter-repo? Sí (32==32, HEAD a49cf63). ✔
- ¿`.shp` sigue en disco tras la purga? Sí, 61M (filter-repo no toca untracked/working). ✔
- ¿Algún valioso (.geojson/.xlsx/.R/.md/.otf) cayó en los globs? No: solo se purgaron
  comunas_bcn y los binarios del afiche. ✔
- ¿Remoto re-agregado a la URL correcta? Sí:
  `https://github.com/tomgc/slep_territorio_costa_central.git`. ✔
- Productos afiche siguen en disco (pdf/afpub presentes). ✔

## Estado: COMPUERTA 4 — PARA. Pendiente OK del titular para el force-push.
Comandos que se ejecutarán tras OK:
```
git push origin --force --all
git push origin --force --tags
```
Luego: re-correr 00_escanear_proyecto.R (snapshot post-purga) y commitearlo.
```
git status --porcelain (sin contar estructura/ ni logs andamios): limpio.
```
