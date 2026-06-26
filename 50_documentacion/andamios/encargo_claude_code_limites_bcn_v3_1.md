# Encargo autónomo — Reemplazo de límites comunales (BCN ya en disco)

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 2, v3.1).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** reemplazar el GeoJSON comunal actual
> (`fcortes`, generalizado, sus comunas se solapan y los contornos se cruzan)
> por los límites comunales oficiales del BCN (alta resolución), **ya
> descomprimidos por el usuario en `20_insumos/comunas_bcn/`**.

---

## Diagnóstico (causa raíz, verificada por el redactor)

Los límites cruzados que el usuario observó (zona Quintero/Concón) vienen del
dato, no del render:
- `20_insumos/comunas.geojson` (fcortes) está groseramente generalizado: Concón
  **6 vértices**, Quintero 12, Puchuncaví 14 → fronteras rectas que cortan el
  territorio en diagonal.
- Las comunas se **solapan entre sí** (Quintero ∩ Concón con área no nula,
  distancia 0), porque cada una se generalizó por separado y sus fronteras
  compartidas no calzan → se dibujan dobles/cruzadas.

Solución: cambiar la fuente por la del BCN (alta resolución). Claude Code dibujó
el dato fielmente; el dato era malo.

---

## Cambio respecto a la v3

**El usuario YA descargó y descomprimió el shapefile BCN.** No hay descarga: el
shapefile vive en `20_insumos/comunas_bcn/comunas.shp` (+ .dbf .prj .shx .sbn
.sbx .cpg .shp.xml). La Fase 0 ahora es **leer del disco**, no de la red.

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.

**Regla de detención (PARA solo si):**
1. El shapefile no contiene las 4 comunas objetivo con nombre reconocible
   (reporta el campo y los valores que sí trae).
2. Tras el reemplazo, los contornos SIGUEN cruzándose (entonces el problema no
   era la fuente; reporta, no fuerces).

**Reglas heredadas:** R-only, `sf` para leer shapefile, `here::here()`, sin rutas
absolutas en código, locale UTF-8 obligatorio, commits atómicos en español.

---

## 2.2 Contexto

**Rutas (raíz `slep_georreferenciacion`):**
- **Shapefile BCN (nuevo insumo, ya en disco):**
  `20_insumos/comunas_bcn/comunas.shp` (61 MB, + subarchivos .dbf/.prj/.shx/...).
  Fuente: BCN, División comunal de Chile. CRS probable: el `.prj` lo confirma
  (BCN suele venir en SIRGAS/UTM o WGS84; léelo, no asumas).
- GeoJSON a reemplazar: `20_insumos/comunas.geojson` (fcortes, generalizado).
- Script consumidor: `30_procesamiento/33_generar_afiche.R` (`cargar_comunas()` /
  `comuna_paths()`).
- Salida: `40_salidas/afiche/mapa_establecimientos.html`.

**Atribución obligatoria (condición de uso BCN):** "Fuente: Biblioteca del
Congreso Nacional de Chile". Agrégala a la nota de fuente del afiche.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Todo el afiche simplificado se conserva intacto: pines numerados sin
  etiquetas ni líneas, numeración N→S (1-20/21-30/31-37/38-97), inset de Viña,
  índice a la izquierda con número+nombre+RBD, autocontención. **Este encargo
  cambia SOLO la fuente de los límites comunales.**
- **🔒-3.** Los puntos se ubican por coordenadas; el cambio de fuente NO debe
  introducir ningún filtro por contención en polígono.
- **🔒-4.** **El `.shp` crudo de 61 MB NO se versiona.** Se recorta a las 4
  comunas y se guarda liviano (ver Fase 2); `20_insumos/comunas_bcn/` entra al
  `.gitignore`.

---

## 2.4 Fases

### Fase 0 — Leer el shapefile del disco e identificar el campo comuna
- `sf::st_read("20_insumos/comunas_bcn/comunas.shp")`.
- Detecta el campo de nombre comunal con `names(x)` (candidatos probables:
  `COMUNA`, `NOM_COMUNA`, `Comuna`, `nombre`). NO asumas; léelo.
- Confirma que existen las 4: Puchuncaví, Quintero, Concón, Viña del Mar. El BCN
  suele traer nombres en MAYÚSCULAS y a veces sin tilde ("VINA DEL MAR",
  "CONCON"): **normaliza (ASCII, minúsculas) para el match**, igual que el resto
  del proyecto ya hace con fcortes.
- Lee el `.prj` para el CRS real. Reporta: campo de nombre, CRS, y nº de vértices
  del contorno de cada una de las 4 comunas (debe ser ≫ 6/12/14; eso confirma la
  mejora de resolución).

### Fase 1 — Verificar que las 4 comunas NO se solapan
- Filtra las 4 comunas. Comprueba que las fronteras compartidas calzan:
  intersección de áreas entre pares adyacentes (Puchuncaví-Quintero,
  Quintero-Concón, Concón-Viña) ≈ 0.
- **Criterio de éxito:** sin solapes groseros como los de fcortes. Si el BCN
  también solapara (improbable), reporta.

### Fase 2 — Generar el insumo liviano y versionar correcto
- Recorta a las 4 comunas, reproyecta a WGS84 (EPSG:4326), conserva el campo de
  nombre, y **sobrescribe `20_insumos/comunas.geojson`** (mismo nombre y formato,
  para que el resto del pipeline no cambie).
- Si el GeoJSON de 4 comunas a alta resolución pesa demasiado (> ~3-4 MB),
  simplifica levemente con `st_simplify(dTolerance = TOL)` con `TOL` pequeño
  (orden 10-50 m en proyección métrica) que **preserve la costa** sin reintroducir
  cruces. Declara `TOL` como constante nombrada y documenta el valor.
- **`.gitignore`:** agrega `20_insumos/comunas_bcn/` (el shapefile crudo de 61 MB
  no se versiona, 🔒-4). El nuevo `comunas.geojson` liviano sí se versiona.

### Fase 3 — Ajustar `cargar_comunas()` solo si el campo cambió
- Si el campo de nombre del nuevo geojson es distinto al que `cargar_comunas()`
  espera (`Comuna`), ajústalo. Si quedó igual (`Comuna`), no toques el 33.
  Cambio quirúrgico: solo lo necesario.

### Fase 4 — Regenerar y verificar visualmente
- `run_all(from=1, to=3)`. Render headless a PNG.
- **Verifica a ojo (es el objetivo):** los 4 contornos siguen la geografía real
  (costa, fronteras), SIN líneas que se crucen en el interior, SIN dobleces. El
  cruce Quintero/Concón que reportó el usuario debe haber desaparecido.
- Agrega la atribución BCN a la nota de fuente.
- Commits atómicos: feat(insumos) geojson BCN recortado + .gitignore;
  fix(33) ajuste cargar_comunas si aplicó; build(afiche) HTML regenerado.

## 2.5 Criterios de éxito
1. Límites de las 4 comunas desde BCN, alta resolución (vértices ≫ 6/12/14).
2. Contornos sin cruces ni solapes en el render (defecto resuelto).
3. Afiche simplificado intacto (🔒-2).
4. `.shp` de 61 MB fuera de Git; geojson liviano versionado.
5. Atribución BCN presente.

## 2.6 Auto-auditoría (panel adversarial)
(a) Las 4 comunas presentes en el nuevo geojson con nombre correcto.
(b) Intersección de áreas entre comunas adyacentes ≈ 0 (no se solapan) — reporta
    los números, antes (fcortes) vs después (BCN).
(c) Vértices por comuna ≫ los de fcortes (6/12/14) — reporta el conteo.
(d) Afiche intacto: 97 pines, numeración N→S, índice con RBD 97/97, sin etiquetas
    ni líneas en el mapa.
(e) `git ls-files` confirma que `comunas_bcn/*.shp` NO está trackeado.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_limites_bcn_log.md`: resumen, commits,
campo/CRS del shapefile BCN, verificación de no-solape con números antes/después,
TOL de simplificación si se aplicó, verificación de 🔒, confirmación de que el
.shp no se versionó, pendientes, notas para el revisor. Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial (vértices antes/después, área de solape antes/después,
git ls-files del shp), confirmación visual de que los contornos ya no se cruzan,
atribución agregada, ruta del log.
