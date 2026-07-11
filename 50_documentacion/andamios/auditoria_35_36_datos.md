# Auditoría de datos — Scripts 35 y 36 del mapa interactivo

> **Fecha:** 2026-07-10 · **Encargo:** `encargo_claude_code_35_36_v1.md` §4
> **Método:** verificación independiente contra el crudo (recuento con código propio,
> `length(unique(MRUN))` releyendo los CSV originales), NO contra los logs de 35/36.
> Comparación contra los artefactos publicados (`establecimientos.geojson`, `sin_geo.json`).
> Scripts de auditoría en scratchpad (no versionados): `aud_1_muestra.R`,
> `aud_2_recuento.R`, `aud_3_universo_tot.R` + bloque de gobernanza/idempotencia.
> **Subagentes usados: 0 de 2.**

## 1. Recuento independiente — muestra adversarial de 11 RBD · TOLERANCIA 0

Muestra construida por criterios (no cómoda): el más grande (1757, actual 2.339), el más
chico (14250, actual 1), 2 en cierre progresivo (14371, 14439), 1 sin dato con geo (11188),
1 sin dato sin geo (41707), 1 con serie de 1 año (11221), 1 con hueco EN MEDIO de la serie
(14256), 1 SLEP (12146), 1 municipal (1122, La Ligua), 1 part. subvencionado (11201, San
Antonio). Comunas: Quilpué, Viña, Valparaíso, La Ligua, San Antonio. Dependencias: las 4
presentes + SLEP.

**Resultado: 44/44 comparaciones (11 RBD × 4 indicadores) idénticas — tolerancia 0 cumplida.**

| RBD | actual (pub/rec) | max_10 | prom_10 | min_10 | OK |
|---|---|---|---|---|---|
| 1122 | 306 / 306 | 339 / 339 | 318 / 318 | 301 / 301 | ✓ |
| 1757 | 2339 / 2339 | 2488 / 2488 | 2352 / 2352 | 1997 / 1997 | ✓ |
| 11188 | "Sin matrícula en 2025." / — | "sin dato" / — | "sin dato" / — | "sin dato" / — | ✓ |
| 11201 | 163 / 163 | 196 / 196 | 141 / 141 | 83 / 83 | ✓ |
| 11221 | 13 / 13 | 13 / 13 | 13 / 13 | 13 / 13 | ✓ |
| 12146 | 279 / 279 | 792 / 792 | 449 / 449 | 225 / 225 | ✓ |
| 14250 | 1 / 1 | 32 / 32 | 9 / 9 | 1 / 1 | ✓ |
| 14256 | "Sin matrícula en 2025." / — | 59 / 59 | 41 / 41 | 18 / 18 | ✓ |
| 14371 | "Sin matrícula en 2025." / — | 89 / 89 | 50 / 50 | 23 / 23 | ✓ |
| 14439 | "Sin matrícula en 2025." / — | 109 / 109 | 74 / 74 | 34 / 34 | ✓ |
| 41707 | "Sin matrícula en 2025." / — | "sin dato" / — | "sin dato" / — | "sin dato" / — | ✓ |

("—" = el recálculo independiente no encuentra ningún año en el crudo, consistente con el texto literal.)

## 2. Regla min>0 — exhibida

- **Nota estructural verificada:** en la fuente no existen filas con matrícula 0 (imposible
  por construcción: si el RBD-año tiene fila, hay ≥1 estudiante). La regla min>0 opera
  sobre **huecos** (años ausentes de la serie), que es la forma real del "0".
- **RBD 14256** (Esc. de Párvulos Caracolito): serie cruda `2016=54 2017=59 2018=56 2019=34
  · · · 2023=18 2024=26 ·` (huecos 2020–2022 y 2025). Publicado: serie con `null` en los
  huecos, **min_10 = 18** (mínimo de los años observados; los huecos NO cuentan como 0) ✓.
- **RBD 11188 y 41707** (sin ningún año en la ventana): los cuatro indicadores = `"sin
  dato"`, **nunca 0** ✓.
- Bonus serie corta: **RBD 11221** (único año 2025=13): actual=max=prom=min=13, esperado
  por construcción y documentado en `metadatos.json` (`nota_serie_corta`) ✓.

## 3. matricula_actual = año 2025 — verificada contra el CSV 2025
En los 6 RBD de la muestra con dato 2025 (1122, 1757, 11201, 11221, 12146, 14250), el valor
publicado coincide con el conteo directo del CSV 2025 ✓. Los 5 sin fila 2025 llevan el
literal exacto `"Sin matrícula en 2025."` ✓.

## 4. Universo y geo
| Check | Resultado |
|---|---|
| Features (pins) en el GeoJSON | **1.251** ✓ |
| Bloque `sin_geo.json` | **17** ✓ |
| Insulares (2101, 14675, 14860, 14881, 42235, 2009) en cualquier JSON | **0** ✓ |
| Provincias | **7 continentales** (Los Andes, Marga Marga, Petorca, Quillota, San Antonio, San Felipe de Aconcagua, Valparaíso) ✓ |
| RBD duplicados en JSON | 0 ✓ |

## 5. Gobernanza (crítica)
- `git ls-files` grep `historico_matricula|mrun|auxiliares csv/pdf|simce` → **vacío** ✓.
- Grep de `mrun` en los artefactos publicables → **1 hit en `metadatos.json`**: es la
  **descripción metodológica** ("número de estudiantes distintos (MRUN unicos)… el
  identificador se descarta tras agregar"), exigida por el encargo §3.4. NO es un dato:
  hallazgo revisado y aceptado. `establecimientos.geojson` y `sin_geo.json`: 0 hits ✓.
- Columnas de los `.rds` intermedios: `indicadores{rbd,matricula_actual,max_10,prom_10,
  min_10,n_anios_con_dato}`, `serie{rbd,anio,matricula}`, `directorio{...atributos EE...}`
  → **ningún identificador individual** ✓.
- `.rds` intermedios trackeados: **0** ✓ (quedan en disco). Los JSON agregados aún NO
  commiteados (pendiente de aprobación del titular, según flujo del encargo).

## 6. Idempotencia 35→36 (corrida completa ×2)
`establecimientos.geojson`: hash **`035513e1…`** idéntico en dos corridas completas de
35→36 ✓ (además `sin_geo.json` `cbd8894a…` y `metadatos.json` `5ebac55a…` estables; sin
timestamps de ejecución en las salidas — `fecha_corte` es constante).

## 7. Coherencia de totales (2025)
- Suma de `matricula_actual` numérica en el JSON (pins + sin_geo): **355.355**.
- Suma independiente del crudo 2025 filtrado al universo (distinct MRUN por RBD, camino
  propio): **355.355**. **Coinciden** ✓ (y cuadran con el total regional del log de 35).

## Hallazgos y resolución
1. "mrun" en `metadatos.json` = texto metodológico exigido; sin dato individual. **OK.**
2. No existen matrículas 0 explícitas en la fuente; la regla min>0 se ejerce sobre huecos.
   Documentado aquí y consistente con el diseño de 35 (años ausentes ≠ 0). **OK.**
3. Sin diferencias en ningún recuento (tolerancia 0). **Sin correcciones necesarias.**

**Veredicto: AUDITORÍA APROBADA sin hallazgos pendientes.** Los artefactos de datos están
listos para commit tras revisión del titular (36 + JSONs + esta auditoría).

---

## ADDENDUM (2026-07-11) — Hallazgo post-auditoría: huecos de serie como `{}` en vez de `null`

**Qué pasó.** El campo `s` (serie anual) publicaba los años sin registro como `{}` (objeto
vacío) y no como `null`, violando el propio glosario de metadatos ("null = sin registro").
Causa: en `presentar()` de 36 los huecos se construían como `NULL` de R, y `jsonlite`
serializa `NULL` dentro de una lista como `{}` (el `na = "null"` solo aplica a `NA`).
Detectado en el hito 2 del mapa web: el popup de RBD 14439 decía "operó hasta 2025" cuando
su serie termina en 2022 (en JS `{} !== null`, el hueco pasaba por dato).

**Por qué esta auditoría no lo vio.** El recuento independiente se hizo en R: `read_json`
convierte `{}` en lista vacía y el código de comparación trataba lista-vacía y null como
equivalentes ("sin dato"), así que los VALORES cuadraban a tolerancia 0 mientras el
ENCODING estaba mal. El consumidor real (JavaScript) distingue lo que R normaliza.

**Corrección (autorizada por el titular, alcance estricto).** Huecos como `NA_integer_` en
`presentar()` → `null` literal. Verificado tras regenerar: indicadores/dep/slep campo a
campo vs el GeoJSON commiteado = 0 diferencias; valores de serie idénticos; `{}` en campo
`s` = 0; huecos totales 741 (geojson) + 170 (sin_geo) = **911** = 1268×10 − 11.769 filas de
serie del RDS de 35 (fuente de verdad) ✓; idempotente (hash `f7998edc…` ×2). JS del mapa
además endurecido: hueco = todo valor no numérico (`esNum`), no solo `null`.

**Regla aprendida.** Los artefactos que cruzan la frontera R→JS deben auditarse DESDE EL
CONSUMIDOR (parsear con el mismo runtime que los consumirá, o al menos con grep sobre el
texto crudo), no solo desde el productor: el parser del productor puede normalizar
silenciosamente exactamente el defecto que el consumidor va a sufrir.
