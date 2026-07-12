# Decisión: recodificación de la dependencia SLEP vigente a 2026

**Fecha:** 2026-07-12 (decisión tomada en la sesión 6; archivo formalizado en la sesión 7)
**Ámbito:** variante 3 (mapa interactivo regional)
**Estado:** vigente
**Traspaso de origen:** `traspaso_cierre_v06.md` §3.5
**Implementación:** `30_procesamiento/34_preparar_directorio_region.R`

---

## Contexto

El directorio oficial de establecimientos educacionales de MINEDUC tiene **corte
al 30 de abril de 2025**. Entre esa fecha y la publicación del mapa (julio de
2026) ocurrieron varios traspasos de establecimientos desde la administración
municipal a los Servicios Locales de Educación Pública, la mayoría con fecha
efectiva del 1 de enero de 2026.

Esto genera una discrepancia: el mapa, si mostrara la dependencia **literal del
directorio**, presentaría como "municipales" a cientos de establecimientos que a
la fecha de publicación ya son SLEP. El usuario del mapa vería un territorio
administrativo que ya no existe.

## Decisión

**El mapa muestra la dependencia vigente a 2026, no la literal del directorio
2025.** Las comunas cuyo año de traspaso (`AGNO_TRASPASO_EDUC`, según
`listado_slep_2026.xlsx`) sea **menor o igual a 2026** se muestran bajo su SLEP
correspondiente, aunque el directorio las registre como municipales.

La regla se activa mediante una constante nombrada explícita:

```r
TRASPASO_SLEP_VIGENTE_2026 <- TRUE
```

### Excepciones respetadas (siguen municipales)

Comunas cuyo traspaso está postergado más allá de 2026:

| Comuna / SLEP | Año de traspaso |
|---|---|
| Zapallar (SLEP Petorca) | 2027 |
| SLEP del Litoral (completo) | 2027 |
| Santo Domingo (SLEP del Litoral) | 2028 |
| Quillota | 2029 |

### Universo resultante (gate compuesto)

```r
N_SLEP_DEP5_DIRECTORIO <- 127L   # ya SLEP en el dato: Valparaíso 54 + Costa Central 73
N_SLEP_RECODIFICADOS   <- 216L   # Aconcagua 67, Marga Marga 58, Petorca-sin-Zapallar 55, Los Andes 36
N_SLEP_TOTAL_ESPERADO  <- 343L   # 127 + 216
```

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Mostrar solo la dependencia literal del directorio 2025 | Fidelidad a la fuente, pero infidelidad a la realidad. El mapa se publica en 2026 y su usuario es institucional: mostrarle un mapa administrativo obsoleto de su propio sector es peor que introducir una recodificación declarada. |
| Recodificar en silencio, sin declararlo | Descartado por transparencia. Si el usuario cruza el mapa contra el directorio oficial y encuentra discrepancias, debe poder entender por qué. |

## Justificación y declaración de transparencia

La recodificación es una **intervención sobre el dato de la fuente**, y por lo
tanto se declara explícitamente en `docs/data/metadatos.json`, de modo que
cualquier usuario del mapa sepa que la dependencia mostrada **no es literal del
directorio 2025** y conozca la regla exacta que se aplicó.

El principio operante: es legítimo corregir un dato desactualizado cuando se
conoce la actualización con certeza; no es legítimo hacerlo sin decirlo.

## Regla técnica aprendida: gate compuesto, no total único

Este es el aporte metodológico duradero de la decisión, y la razón por la que
merece archivo propio.

La validación **no** se hizo contra un total único (`sum(dependencia == "SLEP") == 343`).
Se hizo contra un **gate compuesto** que verifica cada componente por separado:

```r
stopifnot(
  sum(universo$dependencia_original == "SLEP") == N_SLEP_DEP5_DIRECTORIO,
  sum(universo$recodificado) == N_SLEP_RECODIFICADOS,
  sum(universo$dependencia == "Servicio Local de Educación") == N_SLEP_TOTAL_ESPERADO
)
```

**Por qué importa:** en la primera corrida, el gate compuesto atrapó un defecto
real. El campo `slep_nombre` se estaba asignando también a establecimientos
**particulares** de las comunas traspasadas (que no cambian de dependencia: un
colegio particular subvencionado en una comuna traspasada sigue siendo
particular). Un gate de total único **habría pasado igual**, porque el conteo
agregado de establecimientos con dependencia SLEP seguía siendo correcto: el error
estaba en la asignación del nombre del SLEP, no en el conteo de la dependencia.

**Regla general, aplicable más allá de este proyecto:** cuando la corrección de la
*asignación* importa tanto como la corrección del *conteo*, verificar por partes.
Un total agregado correcto puede esconder una asignación incorrecta en sus
componentes.

## Implicancias

- La dependencia mostrada en el mapa es un **dato derivado**, no un dato de la
  fuente. Cualquier análisis que use el mapa como insumo debe saberlo.
- La regla es **temporal por naturaleza**: cuando MINEDUC publique un directorio
  con corte posterior a los traspasos de 2026, la recodificación dejará de ser
  necesaria para esas comunas. La constante `TRASPASO_SLEP_VIGENTE_2026` está
  nombrada precisamente para que su obsolescencia sea visible y no quede como
  lógica enterrada.
- Las excepciones (Zapallar, del Litoral, Santo Domingo, Quillota) deberán
  revisarse conforme se acerquen sus años de traspaso.
