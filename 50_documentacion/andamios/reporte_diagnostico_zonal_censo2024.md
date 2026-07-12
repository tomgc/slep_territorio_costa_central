# Reporte — diagnóstico de la capa zonal (Censo 2024)

**Fecha:** 2026-07-12 · **Etapa 2, Hito 2a** · Naturaleza: solo medición. No construye la
capa, no escribe script de producción, no toca `docs/` ni `30_procesamiento/`. Andamiaje
en `/tmp/censo_zonal/` (muere ahí). Único archivo al repo: este reporte.

**Pregunta decisiva:** ¿la tasa de asistencia calculada desde las columnas del parquet
ES la misma tasa neta que publica el INE en `P7_Educacion.xlsx`? — respondida con cifra.

---

## 1. Método

- Parquets leídos con `arrow` (GDAL no tiene driver Parquet); geometría reconstruida
  desde la columna WKB `SHAPE` con `st_as_sfc(..., EWKB=TRUE)`. Filtrado por
  `COD_REGION==5` **en Arrow** antes de materializar geometría.
- Schema autoritativo vía `ParquetFileReader$GetSchema()`.
- Todo geocódigo casteado a **character** de inmediato (`sprintf("%.0f")` para los
  `double`), con `nchar()` verificado constante.
- `P7_Educacion.xlsx` leído con `readxl`. Hoja 8 = tasas oficiales; hoja 2 = población
  por nivel alcanzado y no-respuesta.
- Áreas y solapamientos en **EPSG:32719** (métrico), con `st_make_valid` y `s2` apagado.

---

## 2. Anatomía de Localidades (el parquet que nadie había abierto)

| Propiedad | Valor (medido) |
|---|---|
| Features total | 9 736 |
| Features Región 5 | **532** |
| Columnas | 204 |
| **Tipo de geometría** (`st_geometry_type`) | **MULTIPOLYGON** ✅ (no puntos) |
| CRS (`geo` metadata) | EPSG:**4674** — SIRGAS 2000 |
| Indicadores incrustados | **Sí**: `n_asistencia_{parv,basica,media,superior}`, `n_edad_{0_5,6_13,14_17,…}` |
| NA en indicadores (R5) | **0** en todos |
| NA en indicadores (Costa Central) | **0** en todos |
| **Llave real** | **`ID_LOCALIDAD`** (double → character, **8 dígitos**, única: 532/532) |

`COD_LOCALIDAD` es solo un índice local (1–3 dígitos, no único). **No** existe columna
`ID_ZONA` en Localidades: la llave es `ID_LOCALIDAD`. Costa Central: **37 localidades**
(Concón 2, Puchuncaví 16, Quintero 16, Viña del Mar 3).

> La **geometría es poligonal**: la condición de parada de la Fase 1 (si fueran puntos,
> redíseño) **no** se disparó. La capa rural se puede colorear por tasa como la urbana.

---

## 3. Anatomía de Zonal (verificación)

| Propiedad | Valor (medido) |
|---|---|
| Features Región 5 | **694** (coincide con lo esperado) |
| `AREA_C` | **URBANO** (todas) |
| Tipo de geometría | **MULTIPOLYGON** |
| CRS | EPSG:**4674** |
| Indicadores incrustados | **Sí** (mismos nombres que Localidades y Manzanas) |
| NA en indicadores (R5 y Costa Central) | **0** |
| Llave | `ID_ZONA` (double → character, **9 dígitos**) |

Costa Central: **159 zonas** (Concón 15, Puchuncaví 16, Quintero 13, Viña del Mar 115).

---

## 4. Viabilidad de la unión urbano + rural

| Criterio | Resultado |
|---|---|
| ¿Mismo esquema de indicadores? | **Sí** — nombres idénticos de `n_asistencia_*` / `n_edad_*` |
| ¿Mismo CRS? | **Sí** — ambos EPSG:4674 |
| ¿Mismo tipo de geometría? | **Sí** — MULTIPOLYGON ambos |
| ¿Se solapan espacialmente? | **NO** — área de solape = **0,0 ha** (0,000 %). Los 58 pares que `st_intersects` reporta solo comparten borde; sin solape de área → **sin doble conteo** |
| Cobertura territorial de Costa Central por (Zonal ∪ Localidades) | Viña del Mar **98,8 %**, Concón **95,3 %**, Quintero **99,8 %**, Puchuncaví **99,8 %** |

La unión es **materialmente posible** por la llave respectiva (`ID_ZONA` urbano /
`ID_LOCALIDAD` rural), sin solape ni doble conteo, cubriendo 95–99,8 % del área comunal.
El 0,2–4,7 % no cubierto es rural disperso fuera de toda localidad o zona nombrada.

---

## 5. LA TABLA DE CONVERGENCIA (la prueba decisiva)

Tasas **oficiales leídas de la hoja 8** de `P7_Educacion.xlsx` (no del contrato §6):

| CUT | Comuna | Parvularia | Básica | Media | Superior |
|---|---|---:|---:|---:|---:|
| 5103 | Concón | 55,4 | 96,1 | 88,5 | 57,1 |
| 5105 | Puchuncaví | 52,7 | 92,7 | 84,1 | 37,9 |
| 5107 | Quintero | 49,8 | 95,1 | 85,1 | 42,2 |
| 5109 | Viña del Mar | 52,0 | 95,6 | 86,7 | 59,5 |

Tasa **calculada del parquet** (agregando las 196 zonas+localidades de Costa Central):
`tasa = 100 · Σ n_asistencia_nivel / Σ n_edad_bracket`.

| Comuna | Nivel | Calculada | Oficial | Dif (pp) |
|---|---|---:|---:|---:|
| Concón | parv | 54,47 | 55,40 | **−0,93** |
| Concón | básica | 94,99 | 96,10 | **−1,11** |
| Concón | media | 87,29 | 88,50 | **−1,21** |
| Puchuncaví | parv | 52,12 | 52,70 | **−0,58** |
| Puchuncaví | básica | 91,67 | 92,70 | **−1,03** |
| Puchuncaví | media | 82,75 | 84,10 | **−1,35** |
| Quintero | parv | 48,97 | 49,80 | **−0,83** |
| Quintero | básica | 94,14 | 95,10 | **−0,96** |
| Quintero | media | 84,20 | 85,10 | **−0,90** |
| Viña del Mar | parv | 51,47 | 52,00 | **−0,53** |
| Viña del Mar | básica | 94,94 | 95,60 | **−0,66** |
| Viña del Mar | media | 86,12 | 86,70 | **−0,58** |

**Diferencia máxima sin ajuste: 1,35 pp. Media: −0,89 pp. Las 12 celdas negativas.**

### La diferencia es SISTEMÁTICA, no ruido → hipótesis de no-respuesta

Todas las celdas subestiman en la misma dirección y magnitud parecida: es una diferencia
**metodológica**. La tasa neta del INE **excluye del denominador a quienes no declararon**;
mi fórmula divide por la población etaria completa (que los incluye). Contraste: la
no-respuesta *implícita* (1 − calc/oficial) contra la columna **"Nivel educativo no
declarado"** de la hoja 2:

| Comuna | No-respuesta implícita (básica) | "No declarado" hoja 2 |
|---|---:|---:|
| Concón | 1,16 % | **1,01 %** |
| Puchuncaví | 1,11 % | **0,90 %** |
| Quintero | 1,01 % | **0,94 %** |
| Viña del Mar | 0,69 % | **0,74 %** |

Casi calcan. Recalculando `tasa_ajustada = calculada / (1 − r)`, con `r` = no-respuesta
comunal de la hoja 2:

| Comuna | Nivel | Calc. cruda | Calc. ajustada | Oficial | Dif (pp) |
|---|---|---:|---:|---:|---:|
| Concón | básica | 94,99 | 95,96 | 96,10 | −0,14 |
| Puchuncaví | básica | 91,67 | 92,50 | 92,70 | −0,20 |
| Quintero | básica | 94,14 | 95,03 | 95,10 | −0,07 |
| Viña del Mar | básica | 94,94 | 95,65 | 95,60 | +0,05 |
| Puchuncaví | media | 82,75 | 83,50 | 84,10 | **−0,60** |
| Viña del Mar | media | 86,12 | 86,76 | 86,70 | +0,06 |

**Con el ajuste por no-respuesta la diferencia máxima cae de 1,35 pp a 0,60 pp**, y los
residuos se centran (signos mixtos). Residuo restante = usar la no-respuesta comunal
como proxy uniforme por tramo etario + cobertura 95–99,8 % + redondeo oficial a 1 decimal.

---

## 6. Veredicto sobre la semántica del indicador

**La tasa directa del parquet NO es idéntica a la tasa neta del INE: la subestima
sistemáticamente 0,5–1,35 pp** (media 0,89 pp) porque el INE excluye la no-respuesta del
denominador y la fórmula directa no. **PERO la semántica de las columnas `n_asistencia_*`
y `n_edad_*` ES la correcta** (mismo universo, mismos tramos etarios): al ajustar por
no-respuesta, converge a ≤ 0,60 pp. Es decir: las columnas miden lo que creíamos
(asistencia al nivel por tramo etario oficial), y el único delta es el tratamiento del
denominador.

Respuesta a la pregunta decisiva: **NO exactamente** — pero por una razón identificada,
cuantificada y corregible, no por un desajuste de universo. La capa zonal **se puede
construir**, con una condición de etiquetado (ver §9).

Esto además **verifica empíricamente** la semántica que el reporte de viabilidad §8.3
dejó sin verificar: la convergencia (tras ajuste) prueba que `n_asistencia_basica` cuenta
asistencia **actual** a básica de la población en **edad oficial 6–13**, no otra cosa.

---

## 7. Fórmula correcta del indicador (para el script de producción)

Por unidad territorial (zona urbana o localidad rural), agregando y **sin** poder
descontar la no-respuesta a nivel sub-comunal (el parquet no trae columna de
no-respuesta por tramo etario):

```
# Indicador reproducible desde el parquet, por unidad:
proporcion_asistencia_basica = n_asistencia_basica / n_edad_6_13      # análogo parv (0_5) y media (14_17)
# Interpretación honesta: "proporción del grupo en edad oficial que asiste al nivel".
# NO es la "tasa neta INE": la subestima ~0,5–1,35 pp por incluir la no-respuesta en el denominador.
```

La tasa **neta INE exacta** NO es reconstruible a escala zona/localidad desde estos
parquets: requeriría la no-respuesta por tramo etario, columna ausente. Solo es
reconstruible a nivel **comuna** (cruzando con la hoja 2), no a nivel sub-comunal.

---

## 8. TOL_VALIDACION_TASA (derivada de la medición, no elegida a priori)

- Si el pipeline valida la **tasa cruda** sub-comunal agregada a comuna contra la oficial
  de la hoja 8: la diferencia máxima medida es **1,35 pp** → `TOL_VALIDACION_TASA = 1,5 pp`
  (1,35 medido + margen para redondeo).
- Si el pipeline aplica el **ajuste por no-respuesta** comunal antes de validar: la
  diferencia máxima cae a **0,60 pp** → `TOL_VALIDACION_TASA = 0,75 pp`.

Ambos valores salen de la cifra medida, no de una elección previa. Recomendado el primero
(1,5 pp) si se publica la proporción cruda; el segundo (0,75 pp) solo si el pipeline
incorpora la corrección comunal.

---

## 9. Recomendación

**Recomendación:** construir la capa zonal (Zonal ∪ Localidades, unión viable y sin doble
conteo) publicando el indicador como **"proporción del grupo en edad oficial que asiste
al nivel"** — no rotularlo "tasa neta INE", porque la subestima sistemáticamente ~0,9 pp,
y esa diferencia (no-respuesta) no es corregible a escala sub-comunal desde estos
parquets.

---

## 10. Lo que NO se pudo determinar y por qué

1. **La no-respuesta por tramo etario y por unidad sub-comunal:** el parquet no la trae;
   solo hay no-respuesta comunal (hoja 2), usada como proxy uniforme. Por eso la tasa
   neta INE exacta no es reproducible a nivel zona/localidad.
2. **La hoja 2 mide no-respuesta de "nivel educativo alcanzado", no de "asistencia":** son
   preguntas distintas del cuestionario. La coincidencia con la no-respuesta implícita es
   fuerte pero no garantiza que sean el mismo universo de no-declarantes; el ajuste es una
   aproximación validada empíricamente, no una identidad.
3. **Cobertura poblacional exacta de la unión:** se midió cobertura de **área** (95–99,8 %),
   no de población; se infiere alta cobertura poblacional por la convergencia limpia, pero
   no se contó persona por persona.
4. **Superior:** no se validó la tasa de educación superior (edad 18–24 no acotada a un
   tramo escolar simple); el foco fueron parvularia/básica/media.

---

## Panel adversarial

1. **¿Tipo de geometría de Localidades medido con `st_geometry_type()`?** Sí:
   `MULTIPOLYGON` (único valor). No es puntual.
2. **¿Cifras de la hoja 8 leídas del xlsx o copiadas del contrato?** Leídas del xlsx
   (`readxl`, hoja "8", fila 4 encabezados, filas por CUT). No se compararon contra §6 del
   contrato; el archivo mandó. El encabezado real de la no-respuesta es **"Nivel educativo
   no declarado"** (no "Asistencia o nivel educativo no declarado" como decía el encargo):
   **el archivo manda, se señala aquí en negrita.**
3. **¿Tabla de convergencia con datos reales del parquet, celda por celda?** Sí: 196
   unidades (159 zonas + 37 localidades) agregadas por CUT, 12 celdas comuna×nivel.
4. **¿La tasa converge? ¿Se declaró sin atenuar?** La tasa cruda **NO** converge (gap
   sistemático 0,5–1,35 pp); se declara sin maquillar. Converge **solo tras ajustar por
   no-respuesta** (≤0,60 pp), y esa condición queda escrita como parte del veredicto, no
   como excusa.
5. **¿La tolerancia se deriva de la diferencia máxima medida?** Sí: 1,35 pp (cruda) y
   0,60 pp (ajustada) son medidas; las TOL propuestas (1,5 / 0,75) las envuelven con
   margen mínimo. No se eligió primero.
6. **¿Geocódigos a character antes de todo join?** Sí. `nchar` constantes:
   `ID_LOCALIDAD`=8, `ID_ZONA`=9, `CUT`=4.
7. **¿Se escribió algo fuera de `/tmp/censo_zonal/` y del reporte?** Ver `git status` en
   la entrega. `docs/` intacto.
8. **¿Alguna afirmación sin comando que la respalde?** No: anatomías, geometría, unión,
   convergencia y ajuste salen de scripts ejecutados esta sesión.
