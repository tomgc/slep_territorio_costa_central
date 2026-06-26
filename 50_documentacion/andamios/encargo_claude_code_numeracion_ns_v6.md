# Encargo autónomo — Numeración N→S estricta + nota de fuente + índice ajustado

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste 5, v6).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario, 3 cambios:**
> 1. Renumerar 1-97 **estrictamente por latitud (N→S)**, sin agrupar por tipo
>    dentro de cada comuna.
> 2. Reemplazar el texto de la nota de fuente por el redactado del usuario.
> 3. En el índice: aprovechar el espacio vertical completo (de arriba a abajo,
>    sin hueco antes de la firma) y aumentar ligeramente la fuente.

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.
**Regla de detención:** un invariante 🔒 se vería comprometido.
**Reglas heredadas:** R-only, `|>`, `.by=`, `here::here()`, sin rutas absolutas,
locale UTF-8, commits atómicos en español.

---

## 2.2 Contexto

**Estado actual (v5):** `33_generar_afiche.R` genera el afiche con tile sin
rótulos, etiquetas de comuna propias, límites BCN, pines grandes con anti-colisión
2D, índice a la izquierda con número+nombre+RBD agrupado por comuna.

**Numeración actual:** comuna N→S, y DENTRO de cada comuna por tipo (jardín→
básica→liceo→especial→adultos)→nombre. **Esto cambia (Fase 1).**

**Rutas:** `30_procesamiento/33_generar_afiche.R`; `run_all(from=1,to=3)`.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Se conserva: tile sin rótulos, etiquetas de comuna propias, límites
  BCN, inset de Viña, índice con número+nombre+RBD, pines grandes con anti-colisión
  garantizada (min_dist ≥ 44 px), sin etiquetas de establecimiento ni leader lines,
  autocontención, color por tipo en pines y leyenda.
- **🔒-3.** Los puntos no se filtran por contención en polígono.
- **🔒-4.** La nueva numeración es consistente entre mapa, inset e índice: el
  número del pin en el mapa = el número en el índice, para los 97.

---

## 2.4 Fases

### Fase 1 — Numeración N→S estricta (por latitud)
- Cambia el criterio de `numerar()`: ordena los 97 establecimientos
  **estrictamente por latitud descendente** (más al norte = 1, más al sur = 97).
  Para empates exactos de latitud (improbable), desempata por longitud y luego
  nombre, de forma determinista.
- **NO agrupar por tipo.** El tipo deja de influir en el orden numérico (el color
  del pin y la leyenda siguen marcando el tipo; solo el número es geográfico).
- **Verificación esperada (ya calculada por el redactor):** como las comunas no se
  solapan en latitud, los rangos por comuna se MANTIENEN: Puchuncaví 1-20,
  Quintero 21-30, Concón 31-37, Viña 38-97. Confírmalo con `stopifnot`. Si por
  alguna razón un rango se cruzara, PARA y reporta (sería señal de un dato
  inesperado).
- Referencia (Puchuncaví debe quedar exactamente así, por latitud):
  1 Escuela Básica La Laguna · 2 Jardín Infantil Mi Mundo Feliz · 3 Colegio
  Maitencillo · 4 Escuela Básica La Quebrada · 5 Escuela Básica El Rungue · 6
  Jardín Infantil Los Conejitos · 7 Escuela Horcón · 8 Jardín Infantil Sirenita ·
  9 Escuela Básica El Rincón · 10 Jardín Infantil Semillita de Puchuncaví · 11
  Colegio General José Velásquez Bórquez · 12 Escuela La Chocota · 13 Escuela
  Multidéficit Amanecer · 14 Jardín Infantil Renacer · 15 Escuela Campiche · 16
  Colegio La Greda · 17 Complejo Educacional Sargento Aldea · 18 Jardín Infantil
  Caballito de Mar · 19 Escuela Pucalán · 20 Escuela Los Maquis.
- El índice se ordena por este `num` (puede seguir agrupado por comuna como
  encabezado, pero la secuencia numérica dentro de cada comuna es la N→S estricta).

### Fase 2 — Nota de fuente (texto exacto)
- Reemplaza el texto actual de la nota de fuente por **este, literal**:

  > Desarrollado por el Área de Monitoreo a partir de datos de OpenStreetMap,
  > CARTO (Positron), los límites comunales publicados por la Biblioteca del
  > Congreso Nacional de Chile (BCN) y el maestro de establecimientos del SLEP
  > Costa Central, de elaboración propia.

- Una sola nota, en el pie. Mantén su estilo tipográfico (tamaño pequeño, color
  tenue) pero con el texto nuevo completo.

### Fase 3 — Índice: aprovechar el alto completo + fuente ligeramente mayor
- El índice de la izquierda hoy deja **espacio vacío abajo, antes de la firma/
  nota**. Redistribuye para que el contenido del índice ocupe el alto disponible
  **de arriba a abajo**, sin ese hueco.
- **Aumenta ligeramente la fuente** del índice (números, nombres y RBD) para mejor
  legibilidad, aprovechando el espacio que se libera al distribuir mejor. Hazlo
  con criterio: que llene el alto sin desbordar ni chocar con la firma. Declara el
  nuevo tamaño como constante.
- Mantén: agrupación por comuna con su encabezado, color por tipo, las 2 columnas
  de Viña, número+nombre+RBD sin truncar.
- **Criterio de éxito:** el índice llena el alto disponible (sin hueco grande
  abajo), la fuente es algo mayor y más legible, nada se trunca ni desborda, la
  firma/nota de fuente queda debajo en su lugar.

### Fase 4 — Regenerar y verificar
- `run_all(from=1,to=3)`. Render headless + zoom al índice y al pie.
- Verifica: (a) numeración N→S estricta (Puchuncaví como la referencia de Fase 1);
  (b) nota de fuente con el texto nuevo exacto; (c) índice sin hueco inferior,
  fuente mayor, sin truncar; (d) mapa/inset usan la nueva numeración, pines sin
  solape intactos. Commits atómicos.

## 2.5 Criterios de éxito
1. Numeración 1-97 estrictamente por latitud N→S, rangos por comuna 1-20/21-30/
   31-37/38-97 (mantienen), consistente mapa/inset/índice.
2. Nota de fuente con el texto exacto del usuario.
3. Índice llena el alto disponible, fuente ligeramente mayor, sin truncar.
4. Resto del afiche intacto (🔒-2): pines grandes sin solape, etiquetas de comuna,
   tile sin rótulos, límites BCN.

## 2.6 Auto-auditoría (panel adversarial)
(a) Numeración: ordenada estrictamente por latitud descendente (verifica que
    `lat[i] >= lat[i+1]` para todo i); rangos por comuna correctos; 1-97 sin
    huecos ni duplicados.
(b) El número del índice = número del pin en el mapa, 1:1 para los 97.
(c) Nota de fuente: el texto nuevo aparece literal en el HTML; el texto viejo NO.
(d) Afiche intacto: 97 pines, anti-colisión min_dist ≥ 44 px, índice 97 RBD+
    nombres sin truncar, etiquetas de comuna presentes, tile sin rótulos.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_numeracion_ns_indice_log.md`: criterio de
orden nuevo, confirmación de rangos por comuna mantenidos, tamaño de fuente del
índice antes/después, verificación del texto de la nota, verificación de 🔒,
pendientes, notas. Honesto. Sin commitear.

## 2.8 Reporte final
Hashes, panel adversarial (numeración N→S estricta verificada, rangos, nota nueva
presente / vieja ausente, anti-colisión intacta), confirmación visual (índice lleno
sin hueco, fuente mayor, numeración geográfica), ruta del log.
