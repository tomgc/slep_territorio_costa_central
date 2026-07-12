# Reporte — auditoría de las manzanas colapsadas (Hito 2b)

**Fecha:** 2026-07-12 · **Etapa 2, auditoría del Hito 2b** · Solo medición (Fase 1).
**Pregunta:** las 230 manzanas que el script 37 descarta por colapso geométrico (3,84 %),
¿tenían niños dentro? El conteo geométrico nunca miró su contenido.

**Método:** se reprodujo el pipeline de lectura del script 37 **idéntico** (mismo parquet,
filtro Costa Central `CUT ∈ {5103,5105,5107,5109}`, cast de `MANZENT`, CRS 4674 → 32719,
`st_simplify(dTolerance = 5)`, `st_set_precision(10^6)` + `st_make_valid`, colapso =
`st_is_empty | !poligonal`), pero **sin descartar** las colapsadas: se identificaron y se
midió su contenido. Área en métrico (EPSG:32719), calculada sobre la geometría **original**
(pre-simplificación). Todo en `/tmp/censo_audit/`; nada al repo salvo este reporte.

---

## Veredicto

**Las 230 manzanas colapsadas contienen CERO niños en los tres tramos etarios.** No se está
borrando población del mapa: el "3,84 % de geometrías colapsadas" es, en efecto, una cifra
geométricamente neutra en términos de población. La afirmación queda **medida, no asumida**.

**La Fase 2 no se justifica.** No hay nada que arreglar en el script 37.

---

## Resultados

### (a) Reproducción determinista
Colapsadas: **230** (esperado 230). El pipeline se reprodujo exactamente → es determinista.

### (b) Manzanas colapsadas con conteo > 0, por tramo
| Tramo | Colapsadas con >0 | de 230 |
|---|---:|---:|
| `n_edad_0_5` | **0** | 230 |
| `n_edad_6_13` | **0** | 230 |
| `n_edad_14_17` | **0** | 230 |

Ninguna de las 230 tiene un solo niño en ningún tramo.

### (c)/(d) Niños en las colapsadas — LA CIFRA QUE IMPORTA
| Tramo | Σ en colapsadas | Total Costa Central | % perdido |
|---|---:|---:|---:|
| `n_edad_0_5` | 0 | 21 175 | **0,000 %** |
| `n_edad_6_13` | 0 | 38 301 | **0,000 %** |
| `n_edad_14_17` | 0 | 19 875 | **0,000 %** |

Cero población infantil perdida, en los tres tramos.

### (e) Área de las colapsadas: ¿slivers o manzanas reales?
| min | p25 | mediana | p75 | max |
|---:|---:|---:|---:|---:|
| 8,8 m² | 84,9 m² | **178,6 m²** | 328,9 m² | 2 453,6 m² |

Referencia: mediana de las NO colapsadas = **5 495,7 m²**. Las colapsadas son manzanas
**pequeñas** (mediana ~179 m², ~31× más chicas que la mediana), no todas micro-slivers (el
máximo es 2 454 m²). Pero — el punto decisivo — **todas, cualquiera sea su tamaño, tienen 0
niños**: son paños no residenciales (industriales, comerciales, equipamiento) que la
simplificación a 5 m degenera.

### (f) Las 10 "peores" por `n_edad_6_13`
Las 10 manzanas colapsadas con más niños en edad básica… tienen **todas 0**:

| MANZENT | CUT | área m² | 0_5 | 6_13 | 14_17 |
|---|---|---:|---:|---:|---:|
| 5103023020019 | 5103 | 279,5 | 0 | 0 | 0 |
| 5107033070010 | 5107 | 279,0 | 0 | 0 | 0 |
| 5109021001003 | 5109 | 87,0 | 0 | 0 | 0 |
| 5109021002019 | 5109 | 225,0 | 0 | 0 | 0 |
| 5109021004017 | 5109 | 594,4 | 0 | 0 | 0 |
| 5109021004019 | 5109 | 296,2 | 0 | 0 | 0 |
| 5109031001007 | 5109 | 315,4 | 0 | 0 | 0 |
| 5109031001013 | 5109 | 347,3 | 0 | 0 | 0 |
| 5109031001016 | 5109 | 181,1 | 0 | 0 | 0 |
| 5109031001022 | 5109 | 127,4 | 0 | 0 | 0 |

### (g) Colapsadas por comuna
| CUT | Comuna | Colapsadas | Total manzanas CC | % de la comuna |
|---|---|---:|---:|---:|
| 5103 | Concón | 72 | 738 | **9,76 %** |
| 5105 | Puchuncaví | 25 | 556 | 4,50 % |
| 5107 | Quintero | 6 | 634 | 0,95 % |
| 5109 | Viña del Mar | 127 | 4 055 | 3,13 % |

Concón concentra proporcionalmente la pérdida geométrica (9,76 % de sus manzanas colapsan),
pero como todas son manzanas vacías de niños, esa concentración **no** censura población en
Concón. Es una característica del amanzanamiento de Concón (más manzanas chicas no
residenciales), no un sesgo del indicador.

---

## Panel adversarial

1. **¿Las 230 se reprodujeron con el mismo pipeline?** Sí: **230** exacto, con las mismas
   constantes y el mismo orden de operaciones del script 37. El pipeline es determinista (un
   número distinto habría sido el hallazgo; no lo fue).
2. **¿La cifra (d) —% de NIÑOS— para los tres tramos?** Sí: **0,000 %** en `n_edad_0_5`,
   `n_edad_6_13` y `n_edad_14_17`.
3. **¿Slivers o manzanas reales?** Cifra de área: mediana 178,6 m² (min 8,8; max 2 453,6),
   contra 5 495,7 m² de las no colapsadas. Pequeñas, algunas no micro; **todas con 0 niños**.
4. **¿Alguna colapsada con ≥ 10 niños en básica?** **Ninguna** (0). Ni siquiera 1: las 230
   tienen `n_edad_6_13 = 0`.
5. **¿Se escribió algo fuera de `/tmp/` y del reporte?** No (ver `git status` en la entrega).
6. **¿Afirmación sin respaldo?** No: cada cifra sale del script de medición en
   `/tmp/censo_audit/medicion.R`, ejecutado esta sesión.

---

## Recomendación

**No ejecutar la Fase 2.** El descarte de las 230 manzanas colapsadas no pierde ningún niño;
el mapa de densidad no censura población. Lo único que valdría la pena, si se quiere blindar
el pipeline a futuro, es convertir esta medición en una **validación permanente** en el
script 37 (un `stopifnot` de que la suma de `n_edad_*` en las colapsadas sea 0, que abortaría
si una versión futura del dato o de la tolerancia empezara a colapsar manzanas con niños).
Esa es una decisión tuya; este encargo no la ejecuta.

---

## Fase 2 — ejecutada (autorizada, misma sesión)

Se instaló la validación permanente en `30_procesamiento/37_construir_capa_manzana.R`, en el
bloque de limpieza, **antes** del descarte de las colapsadas:

- Suma `n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17` sobre el subconjunto colapsado.
- Si **cualquiera** es > 0 → `stop()` con un mensaje accionable que reporta cuántos niños por
  tramo se perderían, cuántas manzanas los contienen, la causa probable (tolerancia demasiado
  alta o dato nuevo del INE) y la acción a tomar. **No se escribe la salida.**
- Si las tres son 0 → `message()` explícito en el log de cada corrida: *"Las 230 colapsadas
  no contienen poblacion en edad escolar: 0 ninos en los tres tramos."*
- **Umbral = CERO**, sin margen: un solo niño perdido en silencio es el defecto que atrapa.

**Verificaciones:**
- Corrida de producción (tolerancia 5 m): la validación **pasa** con su `message()`; el
  artefacto es idéntico en cifras y byte a byte determinista (5.753 features, 1.474 ceros,
  crudo 2.911.694 B, `md5 0a2cc82afb8c2149807ceab88b148cdc`, estable entre corridas).
- Prueba de disparo (en `/tmp`, tolerancia forzada a 300 m, sin tocar el script de
  producción): la misma guardia **aborta** correctamente — 5.868 colapsan, 33.901 niños de
  básica en 4.427 manzanas, con el mensaje accionable completo. Una validación que nunca se
  vio fallar no está verificada; esta sí.
