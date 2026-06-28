# LOG — Fase 0 variante "escala única" (sondeo geométrico)

- **Timestamp:** 2026-06-26
- **Encargo:** variante adicional del afiche A0 con las 4 comunas en UN mapa a escala
  única continua (proxy + leader line para Viña). Bifurcación NO destructiva.
- **Naturaleza de la corrida:** SOLO medición y propuesta. No se renderizó el afiche,
  no se escribió 33b, no se tocó ningún script del pipeline.
- **Entorno:** R 4.5.2, `LANG/LC_ALL=en_US.UTF-8`. Datos: `establecimientos_proyectados.rds`
  (97 filas; 60 Viña, 37 norte). Scripts de medición en scratchpad (no versionados):
  `fase0_medir.R`, `fase0_gate_leader.R`, `fase0_descarga.R`.

## Estado de git (confirmación de invariante 🔒)
- `git diff --stat 30_procesamiento/33_generar_afiche.R` → **vacío (0 cambios)**.
- `git status --porcelain` → **WORKING TREE CLEAN** al inicio y al cierre de la Fase 0.
- 33 queda **byte-idéntico**. No se editó 31 ni 32. No se tocó el maestro.

## Constantes derivadas (recalculadas idénticas a 33, no importadas)
```
ESC = 200*841/(25.4*1240)            = 5.3404
PIN_RADIO_PX = 11*ESC                = 58.74 px (PNG)   = 11 px lienzo
PIN_GAP_PX   = 2*ESC                 = 10.68 px (PNG)
sep_min = 2r+gap                     = 128.17 px (PNG)
MAPA_W  = 1240-468-44                = 728 px lienzo
UNICO_H = 1754-190-44                = 1520 px lienzo (= NORTE_H 944 + GAP 16 + VINA_H 560)
Wpx = 728*ESC                        = 3888 px (PNG)
Hpx = 1520*ESC                       = 8117 px (PNG)
1 px PNG ≈ 6.30 m en terreno (px_por_grado_lat ≈ 17628)
```

## Mediciones crudas

### bbox escala única (patrón render_panel_*, pad estilo norte ±0.020 lon / ±0.015 lat)
```
PRE-fit  3857: w=34680 h=61017  aspect=0.5684
POST-fit 3857: w=34680 h=72409  aspect=0.4789 (= MAPA_W/UNICO_H)
fit_bbox_3857 creció en ALTO (N-S). El ancho de datos se conserva.
```
Consecuencia: NO se inyecta margen E-O artificial; los márgenes provienen de la
distribución real de los puntos.

### Huella de Viña (60 pines) en px PNG
```
x: 250 .. 1473  (ancho 1223 px)     y: 5934 .. 7255  (alto 1322 px)
centro: (861, 6594)
densidad discos/huella = 0.40  (<1 → caben in situ geométricamente)
```
Viña queda al **poniente** (es la comuna costera/SO) y en el **tercio inferior** del marco.

### Huella del Norte (37 pines)
```
x: 782 .. 3638     y: 861 .. 5337
Norte NO solapa en Y con la banda de Viña (norte y≤5337 < vina y≥5934).
```

### Márgenes libres alrededor de Viña (px PNG)
```
Poniente: ancho útil = 191 px   (≈ 1 columna; es el lado OCÉANO)
Oriente : ancho útil = 2356 px  (≈ 18 columnas; lado interior, libre de pines norte)
Alto banda Viña = 1322 px ;  Alto útil marco completo = 8000 px
```

### Capacidad de discos (sep=128.2 px, radio full)
```
Poniente (banda)      :  1 col x 10 fil =   10
Oriente  (banda Viña) : 18 col x 10 fil =  180   <-- 60 caben holgados a radio full
Oriente  (marco full) : 18 col x 62 fil = 1116
```

### Reducción de radio (solo variante) — capacidad oriente(banda)/poniente(full)
```
frac=1.00 r=58.7px: 180 / 62     frac=0.75 r=44.1px: 299 / 80
frac=0.85 r=49.9px: 231 / 72     frac=0.65 r=38.2px: 405 / 182
                                  frac=0.50 r=29.4px: 627 / 230
```
**No se requiere reducir radio**: a radio full ya caben 180 en el oriente.

### GATE de dibujar_pines — VERIFICACIÓN EMPÍRICA
```
97 pines escala única: min_dist=128.2 px (req 117), fuera_marco=0, desp_max=175, desp_medio=60
 -> GATE NO se dispara.
Solo Viña (60) in situ : min_dist=128.2 px (req 117), fuera=0, desp_max=175, desp_medio=67
 -> Viña sola CABE in situ sin proxy. GATE NO se dispara.
```
**Hallazgo:** la premisa del encargo ("el GATE va a dispararse a escala única") es
**falsa** según medición. `separar_pines` resuelve el cluster con desplazamiento ≤175 px
PNG (32.7 px lienzo ≈ 23 mm en A0).

### Guard sys.nframe de 33 ante source()
```
source(33, local=TRUE)  -> flujo principal NO corre (solo define funciones)
source(33, local=FALSE) -> FLUJO PRINCIPAL CORRERÍA  (identical(environment(),globalenv())==TRUE)
```
**Hallazgo:** 33b debe usar `source(..., local = TRUE)`. Con el default `local=FALSE`
el `||` del guard dispara el flujo completo por accidente.

### Zona de descarga ORIENTE — cruces de leader line (asignación por latitud, abanico)
```
geometría            cruces  desp_medio  desp_max (px PNG)
bloque 6x10 (banda)     53      1001       1774   <-- mínimo entre bloques de descarga
4x15                   116       922       1662
3x20                   156       946       1572
2x30                   241      1192       1846
1x60 (columna)         596      2730       5535
(asignación por nombre, referencia desordenada, 6x10): 733 cruces)
```
### In situ (separar_pines) como posición de disco + leader corto al ancla real
```
desp_medio=67 px (12.5 px lienzo)  desp_max=175 px (32.7 px lienzo ≈ 23 mm A0)
cruces de leader = 3   |  pines movidos >0: 57/60  |  movidos >2r (leader visible necesario): 4/60
```
**Hallazgo:** esta variante reduce cruces 53→3 y desplazamiento medio 1001→67 px frente
al bloque de descarga, reutilizando `separar_pines` tal cual.

## Decisiones del panel adversarial (resumen; detalle en el reporte)
1. Márgenes medidos sobre el bbox proyectado real, no asumidos. ✔
2. La propuesta de bloque garantiza no-solape de discos pero NO de leader lines (53 cruces). ✔ documentado.
3. Arquitectura: `source(33, local=TRUE)` deja 33 intacto y NO ejecuta su flujo. ✔ verificado en código.
4. Todo número clave (alto panel, px/grado, capacidad, cruces, desp) calculado en código. ✔

## Cierre
- 33 intacto (byte-idéntico), working tree limpio. No se generó ningún entregable nuevo.
- Pendiente: decisión del titular sobre tratamiento de Viña y aprobación de arquitectura
  antes de Fase 1.
