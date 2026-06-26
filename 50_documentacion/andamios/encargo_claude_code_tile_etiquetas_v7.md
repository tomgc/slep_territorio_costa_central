# Encargo autónomo — Tile sin rótulos + etiquetas de comuna propias (reanclado sobre v6)

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 6, v7).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** lo que pedía el encargo v5 (que no se ejecutó):
> (1) tile CARTO Positron SIN rótulos de texto; (2) eliminar las zonas de
> exclusión; (3) dibujar etiquetas de comuna PROPIAS, grandes, tamaño único, color
> azul institucional gobCL, en las posiciones que el usuario marcó con flechas.

---

## Contexto del reanclaje (importante)

El encargo v5 se redactó pero **no se ejecutó**: el usuario se lo saltó. Luego se
ejecutó el v6 (numeración N→S estricta + nota de fuente nueva + índice a alto
completo) sobre el estado v4. **Por lo tanto el estado actual es v6**, NO el "v5"
que el v6 asumía. Este encargo (v7) reancla el contenido del v5 sobre el v6 real.

**Estado actual REAL (v6), confirmado por el redactor sobre el HTML:**
- Tile `CartoDB.Positron` **CON rótulos** de ciudad horneados.
- **7 zonas de exclusión** (`ZONAS_*`) que evitan que los pines tapen esos rótulos.
- **Bordes** comunales dibujados (`geom_path`), NO etiquetas de comuna propias.
- Numeración **N→S estricta por latitud** (1=más norte … 97=más sur), rangos
  1-20/21-30/31-37/38-97. **No tocar esta numeración.**
- Nota de fuente nueva (Área de Monitoreo). **No tocar.**
- Índice a alto completo, fuente 10,3 px, número+nombre+RBD. **No tocar.**
- Pines grandes (PIN_RADIO_PX=22) con anti-colisión 2D garantizada (min_dist
  ≥ 44 px). **Conservar.**

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.
**Regla de detención:** un 🔒 se vería comprometido, o el tile sin rótulos no está
disponible en el provider (Fase 1).
**Reglas heredadas:** R-only, `here::here()`, sin rutas absolutas, locale UTF-8,
commits atómicos en español.

---

## 2.2 Contexto de rutas
`30_procesamiento/33_generar_afiche.R`; salida
`40_salidas/afiche/mapa_establecimientos.html`; `run_all(from=1,to=3)`.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Se conserva TODO lo del v6: numeración N→S estricta (1-20/21-30/31-37/
  38-97, por latitud), nota de fuente del Área de Monitoreo, índice a alto completo
  con número+nombre+RBD a 10,3 px, límites BCN, pines grandes con anti-colisión
  garantizada, inset de Viña, autocontención, color por tipo en pines y leyenda.
  **Este encargo SOLO cambia: el tile (a sin rótulos), las zonas de exclusión (se
  eliminan) y agrega etiquetas de comuna propias.**
- **🔒-3.** Los puntos no se filtran por contención en polígono.
- **🔒-4.** La anti-colisión 2D entre pines se mantiene (min_dist ≥ 2·PIN_RADIO_PX).

---

## 2.4 Fases

### Fase 0 — Lectura del estado real
- Lee `33_generar_afiche.R`. Localiza: el provider del tile (`get_tiles(...,
  provider=)`), las `ZONAS_*` y su uso como obstáculos en la anti-colisión, la
  función de render de cada panel, y dónde se dibujan los bordes comunales.

### Fase 1 — Tile sin rótulos
- Cambia el provider a la variante SIN etiquetas: en `maptiles` es
  **`"CartoDB.PositronNoLabels"`** (confírmalo con `get_tiles`; si ese string no
  resuelve, prueba la variante nolabels según la versión instalada). Si ninguna
  variante sin rótulos resuelve, PARA y reporta (no inventes otro basemap).
- **Criterio:** el tile de fondo renderiza sin ningún texto horneado (solo
  geografía: costa, manzanas, vías en gris claro). Los bordes comunales BCN
  (`geom_path`) SE MANTIENEN: son el límite dibujado por código, no del tile.

### Fase 2 — Eliminar zonas de exclusión
- Como el tile ya no tiene rótulos, elimina las `ZONAS_*` y la rama de la
  anti-colisión que las trata como obstáculos. **La repulsión entre pines SE
  MANTIENE intacta (🔒-4)**: solo se quita el tratamiento de obstáculos-zona.
- Poda limpia: elimina constantes/imports que queden huérfanos.

### Fase 3 — Etiquetas de comuna propias
- Dibuja una etiqueta de texto por comuna (`geom_text`/`geom_label`) en el plano
  que corresponda: Puchuncaví/Quintero/Concón en el panel norte; Viña del Mar en
  el inset.
- **Tamaño:** único para las 4 (constante `LABEL_COMUNA_FONT`), claramente grande
  (es el rótulo jerárquico del mapa, mayor que los números de pin).
- **Color:** azul institucional gobCL único para las 4. Usa el azul gobCL
  (~`#0F69B4`; si el proyecto ya define un azul institucional en
  `10_configuracion.R` o en el `.dc.html` del design handoff, usa ESE). Constante
  `COLOR_COMUNA`.
- **Tipografía:** gobCL si está registrada (las .otf gobCL están embebidas); si no,
  la familia del resto del afiche.
- **Posiciones (marcadas por el usuario con flechas; punto de partida, AFÍNALAS
  sobre el render buscando el vacío sin pines):**
  - Panel norte:
    - Puchuncaví: ~ lon −71.522, lat −32.747 (centro-norte, zona despejada).
    - Quintero: ~ lon −71.575, lat −32.911 (centro, este del pueblo, vacío grande).
    - Concón: ~ lon −71.553, lat −33.057 (abajo, zona despejada).
  - Inset Viña:
    - Viña del Mar: ~ lon −71.547, lat −33.025 (franja centro-izquierda despejada).
- **Anti-colisión con pines:** la etiqueta de comuna NO debe quedar sobre un pin.
  Si la posición sugerida cae cerca de uno, desplázala al vacío más próximo.
  Verifícalo en el render.
- **Criterio:** las 4 etiquetas se leen grandes, azules, en zonas despejadas, sin
  pin ni borde encima, una por comuna.

### Fase 4 — Regenerar y verificar
- `run_all(from=1,to=3)`. Render headless + zooms.
- Verifica: (a) tile sin rótulos horneados; (b) 4 etiquetas de comuna grandes,
  azules, bien ubicadas, sin solape con pines; (c) anti-colisión de pines intacta
  (min_dist ≥ 44 px); (d) numeración N→S, nota, índice del v6 intactos. Commits.

## 2.5 Criterios de éxito
1. Tile Positron sin rótulos de texto.
2. Zonas de exclusión eliminadas.
3. 4 etiquetas de comuna propias, tamaño único grande, azul institucional, en las
   posiciones marcadas, sin solapar pines.
4. Anti-colisión de pines intacta. Todo el v6 intacto (🔒-2).

## 2.6 Auto-auditoría (panel adversarial)
(a) Tile sin texto horneado (raster; verifica visualmente y declara).
(b) 4 etiquetas de comuna presentes con COLOR_COMUNA y LABEL_COMUNA_FONT; ninguna
    superpuesta a un pin.
(c) Anti-colisión pines: min_dist ≥ 44 px en ambos planos.
(d) v6 intacto: numeración N→S estricta (lat monótona), nota del Área de Monitoreo,
    índice 97 RBD+nombres sin truncar, límites BCN, 97 pines.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_tile_etiquetas_comuna_log.md`: provider de
tile, constantes (COLOR_COMUNA, LABEL_COMUNA_FONT), posiciones finales de las 4
etiquetas (y cuánto se afinaron), confirmación de que zonas de exclusión se
eliminaron sin romper anti-colisión, verificación de 🔒 (incluido que el v6 quedó
intacto), pendientes, notas. Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial, confirmación visual (tile limpio, 4 etiquetas azules
grandes bien ubicadas, numeración N→S intacta), ruta del log.
