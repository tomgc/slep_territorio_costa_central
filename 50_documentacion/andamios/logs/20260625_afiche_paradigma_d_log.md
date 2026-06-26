# Log de cierre — Afiche cartográfico paradigma D (CARTO Positron real)

> Encargo: `50_documentacion/andamios/encargo_claude_code_afiche_v1.md`
> Ejecutor: Claude Code (modo autónomo). Fecha: 2026-06-25.
> Estado: **completo, las 5 fases + panel adversarial.** Log sin commitear (para revisión previa).

---

## 1. Resumen

Se reescribió por completo `30_procesamiento/33_generar_afiche.R` para implementar el
**paradigma D** sobre un **fondo CARTO Positron real**. El afiche es un HTML autocontenido
(1240×1754) con dos planos cartográficos renderizados como PNG (maptiles + sf + ggplot2 +
ragg) e incrustados en base64:

1. **Panel norte** — Puchuncaví, Quintero y Concón. Los establecimientos *apretados*
   (vecino más cercano < 450 m, medido en UTM 19S) sacan su **nombre al mar** (columna
   única al oeste, anti-colisión 1D por latitud, leader line fina); los no-apretados
   llevan el nombre **en tierra** (ggrepel confinado al este, nunca cruza al mar).
2. **Inset de Viña del Mar** — zoom con los 60 puntos numerados (🔒-2).

El índice lateral N→S (coloreado por tipo, Viña en 2 columnas), la leyenda, el logo y la
nota de fuente componen el chrome. La numeración oficial 1..97 es única y la consumen
idénticamente mapa, inset e índice (🔒-5).

El afiche se genera de cero con `run_all(from = 1, to = 3)` en ~6 s (tras descarga de tiles).

## 2. Inventario de commits

| Hash | Tipo | Descripción |
|------|------|-------------|
| `fa4b048` | feat(insumos) | Agrega `20_insumos/comunas.geojson` (límites comunales, fcortes/Chile-GeoJSON) |
| `f8c8be0` | feat(33) | Reescribe el afiche: paradigma D sobre CARTO Positron real (Fases 1–4) + `.gitignore` |
| `421c2b9` | build(afiche) | HTML generado: mapa CARTO real, índice N→S, 26 mar / 11 tierra, inset 60 |

No commiteados (de sesiones previas, ajenos a este encargo): `estructura_actual.*`,
`traspaso_cierre_v02.md`, `afiche_boceto_final.png`, el propio encargo. Este log y el
script de auditoría (`50_documentacion/andamios/auditoria_afiche_paradigma_d.R`) quedan
sin commitear para revisión.

## 3. Cambios sustantivos y causa raíz

1. **Reescritura del 33 (osmdata/SVG → CARTO/ggplot).**
   Causa: el enfoque previo (OSM crudo, proyección lineal a SVG) producía manchas marrones
   y tarjetas encimadas. El encargo aprobó paradigma D sobre CARTO real. Se sustituyó la
   proyección lineal del 32 por reproyección sf real (3857 para render, 32719 para metros).

2. **Bug de data-masking en `seccion_indice` (índice multiplicado ×4).**
   Causa raíz: `filter(comuna_chr == comuna)` — el parámetro `comuna` quedaba ensombrecido
   por la **columna** homónima `comuna` de `est`, de modo que `comuna_chr == comuna`
   comparaba dos columnas equivalentes y daba siempre `TRUE`: cada sección devolvía las 97
   filas. En el render solo se veía la primera sección (1..97 en orden) porque
   `overflow:hidden` recortaba el resto, por eso pasó desapercibido a la vista.
   **Lo detectó el panel adversarial** (conteo 388 = 97×4 de filas en el HTML).
   Fix: renombrar el parámetro a `comuna_nom` y usar `.env$comuna_nom`.

3. **Entorno: locale C rompía el mapeo de tipos con tilde.**
   Causa: mi shell traía `LC_CTYPE=C`; los literales de `MAPEO_TIPO` con tilde no
   macheaban las cadenas UTF-8 del Excel, y `31` abortaba en `stopifnot(!any(is.na(tipo)))`.
   Es un problema **de mi entorno**, no del script (en el locale UTF-8 del titular 31/32
   funcionan). Solución de mi lado: `LANG/LC_ALL=en_US.UTF-8`. No se tocó 31 (🔒-4).

## 4. Verificación de los 6 invariantes 🔒

| Inv. | Resultado | Evidencia |
|------|-----------|-----------|
| **🔒-1** No truncar nombres | **PASA** | Audit: «los 97 nombres completos aparecen literal en el HTML (97/97)». Etiquetas al mar usan `wrap_nombre()` (envuelve a 2 líneas, no corta); índice con `white-space` normal. |
| **🔒-2** Viña en inset con zoom | **PASA** | `render_panel_vina()` genera plano aparte (zoom 13) con los 60 puntos numerados; no se dispersan en el plano principal. |
| **🔒-3** No filtrar por contención en polígono | **PASA** | Audit: «el 33 NO filtra puntos por contención (grep sin `st_within/contains/intersection/join`)». Los puntos se ubican por coordenadas. `norte=37 + viña=60 = 97`, partición exacta. |
| **🔒-4** No tocar 31/32 | **PASA** | `git diff` solo toca 33 y `.gitignore` (+ insumo geojson). El fallo de locale se resolvió en el entorno, sin editar 31/32. |
| **🔒-5** Numeración N→S consistente | **PASA** | Mapa, inset e índice consumen el mismo `est$num`. Audit: «índice HTML 1:1 con numeración independiente (97/97)»; rangos 1-20/21-30/31-37/38-97. |
| **🔒-6** Proyecto público | **PASA** | Identifica establecimientos por nombre (propósito declarado). Sin datos de personas; no aplica gobernanza NNA. |

## 5. Decisión registrada del nudo Quintero/Concón

**Camino tomado: (a) — un solo plano, mar real al oeste.** Las etiquetas de las tres
comunas chicas se apilan en **una columna oceánica única al oeste**, ordenadas por latitud
con anti-colisión 1D (separación mínima `Yr/28`). Como las comunas están separadas en
latitud (Puchuncaví ~-32.71 > Quintero ~-32.80 > Concón ~-32.93), el orden latitudinal
evita que las etiquetas converjan: Puchuncaví ocupa la franja alta, Quintero la media,
Concón la baja. Las leader lines salen en abanico desde cada clúster sin cruzar el mapa de
lado a lado.

**Refuerzo:** dispersión leve (declustering radial por comuna) para que los puntos
encimados —sobre todo Concón, 5 puntos a 59 m de mediana— sean individualmente legibles
conservando su ubicación real. Esto permitió **no** caer al camino (b) (mini-inset de
Concón): las leader lines no se cruzan y los puntos quedaron distinguibles. El gate
estratégico (mar insuficiente → cambiar paradigma) **no se alcanzó**.

## 6. Verificación visual (Fase 3) y método

Render headless del HTML con `pagedown::chrome_print` (Chrome) a 1240×1754 @2× y recortes
de alta resolución de las zonas críticas. Confirmado:
- Cero etiquetas al mar solapadas (zooms top Puchuncaví y bottom Quintero/Concón).
- Cero leader lines cruzando el mapa de lado a lado.
- Racimo de Viña legible en el inset (60 numerados).
- Ningún nombre truncado.

Salida del panel adversarial (`auditoria_afiche_paradigma_d.R`, independiente del 33):

```
[PASA] todos los tipos reconocidos (orden de tipo aplicable)
[PASA] numeracion 1..97 sin huecos ni duplicados
[PASA] rangos por comuna = 1-20 / 21-30 / 31-37 / 38-97
[PASA] dentro de cada comuna el tipo es monotono (jardin->...->adultos)
[PASA] el 33 NO filtra puntos por contencion en poligono (🔒-3)
[PASA] particion render: norte=37 + vina=60 = 97 (sin perdidas)
[PASA] los 97 nombres completos aparecen literal en el HTML (97/97)
[PASA] el indice HTML contiene 97 numeros 1..97 (encontrados=97)
[PASA] indice HTML 1:1 con numeracion independiente (97/97 coinciden)
===== PANEL ADVERSARIAL: TODO PASA (0 fallas) =====
```

## 7. Pendientes y marcas `# REVISAR`

- **Validación in situ del titular:** mi verificación fue por captura headless. Falta abrir
  `40_salidas/afiche/mapa_establecimientos.html` en un navegador y confirmar a ojo.
- **Exportación A0/PDF:** el HTML está a 1240×1754 px (proporción ~√2, tipo A4). Para un A0
  imprimible real hay que escalar el `@page`/render; `pagedown::chrome_print(html, pdf)`
  produce el PDF. Decisión del titular sobre tamaño físico final.
- **`BUFFER_VISUAL_DEG` definido pero no aplicado:** no hizo falta el buffer 🔒-3 porque la
  costa detallada de CARTO deja los 2 puntos borde (RBD 1699, 33476) sobre tierra visible.
  Constante queda como documentación de la intención; **# REVISAR**: remover o aplicar.
- **Densidad central de Viña:** algunos puntos siguen cercanos tras el declustering
  (`dmin = 0.022·Xr`); legibles pero perfectibles subiendo `dmin`.
- **Leader lines de tierra:** un par (no-apretados de Concón: 32, 34) quedan algo largas;
  no cruzan lado a lado. Se acotó el piso del repel a `0.40·Xr` para acercarlas.
- **maptiles no persiste caché entre sesiones de R** (usa `tempdir()`): cada arranque
  re-descarga tiles (~3–4 s). Si molesta, fijar `cachedir` a una ruta estable del repo.

## 8. Notas para el revisor

- **Locale UTF-8 obligatorio** para correr el pipeline (`LANG/LC_ALL=en_US.UTF-8`), por el
  mapeo de tipos con tilde en 31. Esto es del entorno, no del código.
- **Red en la primera corrida** (descarga de tiles CARTO).
- El panel adversarial es **re-ejecutable** y vive en
  `50_documentacion/andamios/auditoria_afiche_paradigma_d.R` (no se hizo source del 33: lo
  re-deriva desde el maestro crudo). Está fuera de `scratchpad_afiche/` (que es gitignored)
  para que no se pierda; decidir si se versiona o se mueve a `30_procesamiento/`.
- Honestidad sobre lo que costó: lo más caro fue (1) el bug de data-masking del índice, que
  se veía bien a la vista y solo el conteo del panel adversarial delató; y (2) calibrar el
  bbox/aspect y la columna oceánica para que las 26 etiquetas cupieran sin solape — varias
  iteraciones de render-y-mirar.
