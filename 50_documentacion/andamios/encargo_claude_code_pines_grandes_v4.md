# Encargo autónomo — Pines grandes, sin solape, sin tapar nombres de comuna

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 3, v4).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** en el afiche simplificado actual (pines
> numerados sobre CARTO + límites BCN), hacer que los pines sean (1) más grandes,
> tamaño único, con número de fuente única grande; (2) que **nunca se
> superpongan**; (3) que **nunca tapen el nombre de la comuna/ciudad** que rotula
> el tile CARTO. Decisión del usuario: priorizar no-solape (el pin es marcador
> aproximado; el dato exacto vive en el índice).

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.

**Regla de detención (PARA solo si):**
1. Un invariante 🔒 se vería comprometido.
2. La separación necesaria para no-solape empuja tantos pines fuera del marco que
   el mapa pierde sentido (reporta antes de forzar; ver gate al final).

**Reglas heredadas:** R-only, `|>`, `dplyr >= 1.1` con `.by=`, `here::here()`, sin
rutas absolutas, locale UTF-8, commits atómicos en español.

---

## 2.2 Contexto

**Estado actual:** el `33_generar_afiche.R` genera dos planos PNG (panel norte con
las 3 comunas chicas + inset Viña) sobre CARTO Positron con límites BCN, pines
numerados coloreados por tipo, e índice lateral con número+nombre+RBD. Hoy los
pines son pequeños y usan un "declustering radial leve" que NO garantiza
no-solape.

**Rutas:** `30_procesamiento/33_generar_afiche.R`; salida
`40_salidas/afiche/mapa_establecimientos.html`; orquestador `00_run_all.R`
(`run_all(from=1,to=3)`).

**Densidad real (calculada por el redactor; informa el dimensionamiento):**
distancia mínima entre pines por comuna: Viña 5 m, Quintero 17 m, Puchuncaví
26 m, Concón 53 m. Con pines grandes, la separación es obligatoria en los
clústeres (Viña-centro, Quintero, Concón, Ventanas).

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Se conserva todo lo demás del afiche: límites BCN, numeración N→S
  (1-20/21-30/31-37/38-97), inset de Viña, índice a la izquierda con
  número+nombre+RBD, sin etiquetas de texto ni leader lines en el mapa,
  autocontención, atribución BCN.
- **🔒-3.** Los puntos NO se filtran por contención en polígono.
- **🔒-4.** Numeración N→S consistente entre mapa, inset e índice (un pin movido
  por anti-colisión conserva su número).

---

## 2.4 Fases

### Fase 0 — Lectura del estado real
- Lee `33_generar_afiche.R`. Localiza: dónde se fija el tamaño del pin y la fuente
  del número; dónde está el "declustering radial leve" actual; cómo se renderizan
  panel norte e inset Viña.

### Fase 1 — Pines más grandes, tamaño y fuente únicos
- Define constantes nombradas: `PIN_RADIO` (tamaño único de pin, claramente mayor
  que el actual) y `PIN_FONT` (tamaño único del número, dimensionado para llenar
  el pin grande y quedar legible). Aplícalas a TODOS los pines de ambos planos
  (panel norte e inset Viña) por igual.
- El número debe quedar centrado y legible dentro del pin grande. Pin circular
  relleno por color de tipo, número en blanco, borde blanco fino para separar del
  fondo.

### Fase 2 — Anti-colisión 2D real (nunca solapar)
Reemplaza el "declustering radial leve" por una separación que **garantice**
no-solape dado `PIN_RADIO`:
- Algoritmo iterativo de separación (force-directed / repulsión de discos, o
  `ggrepel`/`packcircles` aplicado a los CENTROS de los pines, no a etiquetas):
  partiendo de la posición real proyectada, desplaza los pines lo mínimo hasta que
  la distancia entre cualquier par de centros sea ≥ `2·PIN_RADIO + PIN_GAP`
  (separación mínima visible). `PIN_GAP` como constante nombrada.
- Conserva el número de cada pin (🔒-4) y minimiza el desplazamiento (un pin se
  mueve solo lo necesario). Decisión del usuario: priorizar no-solape sobre
  posición exacta; el pin es marcador aproximado, el dato exacto está en el índice.
- Aplica a ambos planos: panel norte (37 pines, clústeres de Ventanas/Quintero/
  Concón) e inset Viña (60 pines, varios a 5 m).
- **Criterio de éxito verificable:** tras la separación, computa la distancia
  mínima entre todos los pares de centros y confirma que es ≥ `2·PIN_RADIO`
  (en coordenadas de render). Repórtalo como número, no como impresión visual.

### Fase 3 — Zonas de exclusión de las etiquetas de comuna/ciudad
El nombre de cada ciudad (Quintero, Concón, Maitencillo, Puchuncaví, Ventanas,
Viña del Mar) lo dibuja el **tile CARTO** (está horneado en el raster, no se puede
mover desde el código). Para que ningún pin lo tape:
- Define una **zona de exclusión rectangular** alrededor de la posición donde el
  tile rotula cada ciudad. Las coordenadas de esos rótulos son estables para un
  zoom/bbox dado; determínalas inspeccionando el render (captura el panel sin
  pines, ubica los textos de ciudad, define los rectángulos en coordenadas del
  mapa). Decláralas como una tabla de constantes (`ZONAS_EXCLUSION`).
- El algoritmo de anti-colisión (Fase 2) trata esas zonas como **obstáculos
  fijos**: ningún pin puede quedar dentro de una zona de exclusión; si su posición
  real cae ahí, se desplaza al borde más cercano fuera de la zona.
- **Criterio de éxito:** en el render final, los textos de ciudad del tile
  (especialmente "Quintero", el caso que el usuario reportó) quedan legibles, sin
  pin encima. Verifícalo a ojo en el zoom de cada ciudad rotulada.

### Fase 4 — Regenerar y verificar
- `run_all(from=1,to=3)`. Render headless + zooms de los clústeres (Ventanas,
  Quintero, Concón, Viña-centro) y de las etiquetas de ciudad.
- Verifica: (a) ningún par de pines se toca; (b) "Quintero" y demás nombres de
  ciudad legibles sin pin encima; (c) pines y números claramente más grandes que
  antes; (d) numeración consistente. Commits atómicos.

## 2.5 Criterios de éxito
1. Pines tamaño único grande, número de fuente única grande y legible.
2. Distancia mínima entre centros de pines ≥ 2·PIN_RADIO (sin solape), verificado
   numéricamente en ambos planos.
3. Ningún nombre de ciudad del tile tapado por un pin (zonas de exclusión).
4. Todo lo demás del afiche intacto (🔒-2).

## 2.6 Auto-auditoría (panel adversarial)
(a) Distancia mínima entre todos los pares de pines en cada plano ≥ 2·PIN_RADIO
    (reporta el mínimo real en px/unidades de render).
(b) Ningún centro de pin dentro de una zona de exclusión.
(c) Afiche intacto: 97 pines, numeración N→S, índice 97 RBD+nombres, límites BCN,
    sin etiquetas/leader lines, atribución BCN.
(d) Numeración consistente mapa/inset/índice tras el reposicionamiento.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_pines_grandes_log.md`: constantes usadas
(PIN_RADIO, PIN_FONT, PIN_GAP), algoritmo de separación elegido y por qué,
coordenadas de las zonas de exclusión, distancia mínima resultante (antes/después),
cuánto se desplazaron los pines en promedio/máximo, verificación de 🔒, pendientes,
notas para el revisor. Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial (distancia mínima real por plano, check de zonas de
exclusión), confirmación visual (pines grandes, sin solape, "Quintero" legible),
ruta del log.

---

**Gate estratégico (decisión del usuario, marca y reporta si lo alcanzas):** si
con `PIN_RADIO` grande la anti-colisión empuja pines tan lejos que se salen del
marco del panel o el mapa pierde correspondencia con la geografía (p. ej. el
clúster de Viña-centro se expande sobre media ciudad), PARA: las alternativas
serían bajar `PIN_RADIO`, o un mini-inset para el clúster más denso, y eso lo
decide el usuario. Reporta con números (cuántos pines se salen, cuánto se
desplazó el peor caso) en vez de forzar un resultado feo.
