# Auditoría de la recodificación SLEP vigente 2026 (34→35→36)

> **Fecha:** 2026-07-11 · **Regla auditada:** dependencia mostrada = situación institucional
> vigente a 2026 (comunas con AGNO_TRASPASO_EDUC ≤ 2026 → "Servicio Local de Educación" +
> `slep_nombre`), implementada en 34 con gate COMPUESTO; cascada 35→36 regenerada.
> **Corrección previa aceptada por el titular:** total esperado **343**, no 344 (el 344
> arrastraba a RBD 2009 — Robinson Crusoe, SLEP Valparaíso — excluido por insular v1).
> **Método:** caminos independientes del pipeline (crudo + listado releídos con código
> propio) contra los artefactos publicados. **Subagentes: 0 de 2.**

## 1. Los 343 por dos caminos independientes
| Camino | Resultado |
|---|---|
| A: conteo en `establecimientos.geojson` publicado (`dep == "Servicio Local de Educación"`) | **343** |
| B: directorio CRUDO + listado SLEP releídos sin pasar por 34 (`COD_DEPE2==5` ∪ (`traspaso≤2026` ∧ `COD_DEPE2==1`)) | **343** |

Desagregado por SLEP en el JSON (`slep_nombre`): Costa Central 73 · Aconcagua 67 ·
Marga Marga 58 · Petorca 55 · Valparaíso 54 · Los Andes 36. Suma = 343 ✓.
Gate compuesto de 34 (`stopifnot` por partes): dep5 previos 127 (54+49+14+6+4 por comuna),
recodificados 216 (67+58+55+36 por SLEP), total 343, sin doble conteo (`recod ∧ dep5_pre = 0`),
municipales no traspasados (4/6/48/47). Todos activos en cada corrida.

## 2. EE que cambiaron municipal→SLEP (uno por SLEP 2026; verificado contra el crudo)
| SLEP | RBD | Comuna | Crudo (COD_DEPE2) | Traspaso listado | Publicado |
|---|---|---|---|---|---|
| Aconcagua | 11191 | San Felipe | 1 (municipal) | 2026 ≤ 2026 ✓ | SLEP · "Aconcagua" |
| Los Andes | 1194 | Los Andes | 1 | 2026 ✓ | SLEP · "Los Andes" |
| Marga Marga | 11231 | Limache | 1 | 2026 ✓ | SLEP · "Marga Marga" |
| Petorca | 11196 | Cabildo | 1 | 2026 ✓ | SLEP · "Petorca" |

Total recodificados detectados vía crudo: **216** (esperado 216) ✓.

## 3. Excepciones respetadas (siguen municipales)
- **Zapallar**: 4 Municipal + 1 Part. Subv.; **0 SLEP** ✓ (postergada, 2027).
- **Santo Domingo**: 6 Municipal + 2 P. Pagado + 2 P. Subv.; **0 SLEP** ✓ (postergada, 2028).
- del Litoral 48 y Quillota 47 municipales intactos (gate de 34) ✓.

## 4. Costa Central y Valparaíso intactos
`slep_nombre`: Costa Central **73** (Concón, Puchuncaví, Quintero, Viña del Mar) y
Valparaíso **54** — ni duplicados ni movidos; 0 RBD duplicados en el JSON ✓.

## 5. La matrícula NO se contaminó
- **Hash de `matricula_historica_r5.rds` IDÉNTICO** al de la corrida pre-recodificación
  (`f32ddf3f10…`) tras regenerar 35 ✓ (la salida de 35 no contiene dependencia).
- Comparación campo a campo del GeoJSON **viejo commiteado** (`git show 5256389:…`) vs
  nuevo: 1.251 features en ambos; **0 diferencias** en `ma/mx/pr/mn` y en la serie `s` ✓.
  Solo cambian `dep` (216 EE) y la clave nueva `slep`.

## 6. Metadatos y filtro SLEP
- `criterios_calculo$dependencia` declara la regla con el texto fijado por el titular
  (vigencia 2026, corte 30-abr-2025, postergadas Zapallar/Santo Domingo, recodificación
  deliberada y documentada) ✓.
- `filtro_slep`: los **8 SLEP continentales** con año y estado — Valparaíso 2021 vigente,
  Costa Central 2025 vigente, Aconcagua/Los Andes/Marga Marga/Petorca 2026 vigentes,
  del Litoral 2027 pendiente, Quillota 2029 pendiente ✓ (Hanga Roa insular, fuera de v1).
- Glosario: clave `slep` documentada; `dep` remite a la regla ✓.

## 7. Idempotencia y gobernanza
- Cadena completa 34→35→36 corrida **dos veces**: hashes idénticos de los 3 JSON
  (`establecimientos.geojson` = `ca29f2b7…`) ✓. Serie estable entre corridas ✓.
- `git ls-files` limpio de crudos/MRUN ✓. `mrun` en geojson/sin_geo: 0 ✓ (en metadatos
  solo la mención metodológica ya auditada). `00_run_all` y 33 intactos ✓.
- Peso: `establecimientos.geojson` 0,708 MB (< 1 MB) ✓.

## Hallazgos y resolución
1. **Gate compuesto atrapó un defecto real en la primera corrida:** `slep_nombre` quedaba
   asignado también a EE particulares de comunas traspasadas (el gate
   `sum(!is.na(slep_nombre))==343` falló). Corregido: el nombre del SLEP marca SOLO a los
   EE administrados por el SLEP (`COD_DEPE2==5` tras la regla). Ejemplo de por qué el
   total único no bastaba y el compuesto sí.
2. Sin otros hallazgos. **AUDITORÍA APROBADA.**

## Estado
34 y 36 modificados + 3 JSON regenerados: **sin commitear**, a la espera de revisión del
titular. 35 sin cambios de código (su salida es bit-idéntica).
