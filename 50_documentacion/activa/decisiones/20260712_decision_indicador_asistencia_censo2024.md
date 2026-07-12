# Decisión — Indicador de asistencia de la capa zonal (Censo 2024)

**Fecha:** 2026-07-12 · **Sesión:** 11 · **Proyecto:** `slep_georreferenciacion`
**Estado:** Adoptada
**Supersede:** `20260712_decision_alcance_censo2024.md` en §3 (indicador de la capa de
asistencia), §6 (validación obligatoria) y §10 (criterio de éxito, puntos 1 y 3). El
resto de aquel documento (dos capas, dos escalas; la manzana acotada a Costa Central;
el tratamiento del cero; la gobernanza del microdato) **sigue plenamente vigente**.

**Insumo que la funda:**
`50_documentacion/andamios/reporte_diagnostico_zonal_censo2024.md` (Etapa 2, Hito 2a).
Todas las cifras de este documento salen de esa medición, hecha sobre el artefacto real.

---

## 1. Qué cambia y por qué

El contrato de alcance (§3) especificó la capa zonal como **"tasa de asistencia neta por
nivel"**, y su criterio de éxito #1 (§10) exigió que esa tasa, agregada por comuna,
**convergiera a la cifra publicada por el INE** en `P7_Educacion.xlsx` hoja 8.

La medición del Hito 2a demuestra que **eso no es posible**, y que insistir en ello
produciría un indicador falso.

**El hallazgo, medido:** la proporción calculada directamente desde las columnas del
parquet subestima la tasa neta oficial del INE de forma **sistemática**: las **12 celdas**
(4 comunas × 3 niveles) caen del mismo lado, entre **0,53 y 1,35 puntos porcentuales**
por debajo, con una media de **0,89 pp**.

| Comuna | Nivel | Proporción (parquet) | Tasa neta INE | Diferencia (pp) |
|---|---|---:|---:|---:|
| Concón | Parvularia | 54,47 | 55,40 | −0,93 |
| Concón | Básica | 94,99 | 96,10 | −1,11 |
| Concón | Media | 87,29 | 88,50 | −1,21 |
| Puchuncaví | Parvularia | 52,12 | 52,70 | −0,58 |
| Puchuncaví | Básica | 91,67 | 92,70 | −1,03 |
| Puchuncaví | Media | 82,75 | 84,10 | **−1,35** |
| Quintero | Parvularia | 48,97 | 49,80 | −0,83 |
| Quintero | Básica | 94,14 | 95,10 | −0,96 |
| Quintero | Media | 84,20 | 85,10 | −0,90 |
| Viña del Mar | Parvularia | 51,47 | 52,00 | −0,53 |
| Viña del Mar | Básica | 94,94 | 95,60 | −0,66 |
| Viña del Mar | Media | 86,12 | 86,70 | −0,58 |

**La causa está identificada y cuantificada.** El INE **excluye del denominador** a
quienes no declararon (preguntas 33 y 34 del cuestionario). Nuestra fórmula divide por la
población en edad oficial **completa**, que los incluye. De ahí que subestime siempre, y
siempre en la magnitud de la no-respuesta.

La prueba de que esa es la causa, y no otra: la no-respuesta *implícita* (`1 − calculada /
oficial`) reproduce casi exactamente la columna **"Nivel educativo no declarado"** de la
hoja 2 del propio archivo del INE.

| Comuna | No-respuesta implícita (básica) | "Nivel educativo no declarado" (hoja 2) |
|---|---:|---:|
| Concón | 1,16 % | 1,01 % |
| Puchuncaví | 1,11 % | 0,90 % |
| Quintero | 1,01 % | 0,94 % |
| Viña del Mar | 0,69 % | 0,74 % |

Al corregir por ese factor, la diferencia máxima cae de **1,35 pp a 0,60 pp**, y los
residuos se centran (signos mixtos, sin sesgo).

**Consecuencia semántica, y es la buena noticia:** las columnas del parquet **miden lo que
creíamos**. `n_asistencia_basica` cuenta asistencia actual a educación básica de la
población en edad oficial 6–13. El universo y los tramos etarios son correctos. El único
delta es el tratamiento del denominador. Esto **verifica empíricamente** la semántica que
el reporte de viabilidad (§8.3) había dejado explícitamente sin verificar.

---

## 2. La restricción dura: la corrección no es aplicable donde el mapa la necesita

La columna de no-respuesta **existe solo a nivel comuna** (hoja 2 del tabulado del INE).
El parquet **no la trae** a escala de zona ni de localidad.

Por lo tanto: **la tasa neta del INE no es reconstruible a escala sub-comunal.** Es
reconstruible únicamente a nivel comuna, cruzando con un archivo externo.

Esto no es una limitación del pipeline: es una limitación del dato publicado.

---

## 3. Decisión

### 3.1 El indicador que se publica

```
proporcion_asistencia_basica = n_asistencia_basica / n_edad_6_13
proporcion_asistencia_parv   = n_asistencia_parv   / n_edad_0_5
proporcion_asistencia_media  = n_asistencia_media  / n_edad_14_17
```

Calculado **por unidad territorial** (zona urbana o localidad rural), directamente desde
las columnas incrustadas del parquet, sin join externo.

### 3.2 Cómo se rotula, en todo el producto

**"Proporción del grupo en edad oficial que asiste al nivel."**

**Nunca "tasa de asistencia neta".** Ese término está tomado: designa un indicador
específico del INE, con una definición de denominador que este producto no puede
reproducir. Usarlo sería afirmar una equivalencia que la medición desmiente.

La regla aplica a la leyenda del mapa, a los popups, a los nombres de columna de cualquier
exportación (XLSX, CSV), y a la prosa técnica y de comunidad por igual.

### 3.3 No se ajusta por no-respuesta

Se evaluó corregir cada unidad por el factor de no-respuesta de su comuna, lo que haría
converger la cifra con el INE (≤ 0,60 pp).

**Se descarta.** Ese ajuste **inventa precisión que el dato no tiene**: asume que la
no-respuesta se distribuye uniformemente dentro de la comuna, y no existe evidencia de
eso. Sería maquillar el número para que calce con una cifra oficial, a costa de afirmar
sobre cada zona algo que no se midió. El producto prefiere una cifra honesta que discrepa
a una cifra conveniente que no se puede defender.

**Regla general derivada (aplicable a toda la cartera):** *una corrección que hace calzar
un indicador con una cifra oficial no es, por eso, una corrección correcta. Si la
corrección se apoya en un supuesto de homogeneidad que no se midió, introduce precisión
falsa donde antes había un sesgo declarado. Un sesgo conocido y declarado es preferible a
una precisión inventada.*

### 3.4 La discrepancia con el INE se declara, no se esconde

El mapa mostrará cifras que **no calzan** con las que el INE publica para las mismas
comunas: ~1 pp por debajo, siempre en la misma dirección. Alguien lo va a notar. Debe
encontrarlo explicado, no descubrirlo como un error.

Va en la **nota metodológica del producto**, con la magnitud medida (0,53–1,35 pp, media
0,89 pp, siempre a la baja) y su causa (el INE excluye la no-respuesta del denominador;
este producto no puede hacerlo a escala sub-comunal porque el dato no existe a esa
escala).

### 3.5 El popup no yuxtapone la cifra del INE

El popup de una zona o localidad muestra **solo su propia proporción**.

**No** muestra junto a ella la tasa oficial de su comuna. La cifra del INE es **comunal**;
la del mapa es **zonal**. Ponerlas lado a lado invita a una comparación que no es válida:
una zona con 88 % no está "por debajo" del 95,6 % de su comuna en ningún sentido
interpretable, porque el 95,6 % **contiene** a esa zona y la promedia con las demás. El
etiquetado correcto no neutraliza la yuxtaposición: dos números juntos comunican
comparación aunque el texto diga otra cosa.

El contraste con la cifra oficial vive donde **sí** es legítimo (mismo territorio, misma
unidad geográfica): la nota metodológica y, si el producto llega a tener una vista
comunal, ese panel.

---

## 4. Validación: qué se valida, y qué ya no

### 4.1 Se elimina `TOL_VALIDACION_TASA`

El contrato de alcance (§10, criterio de éxito #1) exigía que la tasa agregada convergiera
a la cifra oficial, con una tolerancia por definir.

**Ese criterio se elimina.** El indicador publicado **no es** el del INE, y por lo tanto
**no tiene por qué converger con él**. Mantener el criterio obligaría a fijar una
tolerancia de al menos 1,5 pp para envolver el sesgo sistemático de 1,35 pp ya medido, y
un test calibrado para tolerar el error que ya conocemos **no valida nada**: certifica que
el error cabe. Un test diseñado para pasar no es un test.

### 4.2 Se crea `TOL_LECTURA_PARQUET = 0,75 pp`

En su lugar, un test genuino, que valida algo distinto: **que leímos bien el parquet.**

```r
# Test de integridad de lectura (NO valida el indicador publicado: valida el pipeline).
# Procedimiento:
#   1. Agregar zonas + localidades por comuna.
#   2. Calcular la proporción cruda por comuna.
#   3. Corregir por la no-respuesta comunal de P7_Educacion.xlsx hoja 2.
#   4. Comparar contra la tasa neta oficial de la hoja 8.
# La diferencia máxima medida en el Hito 2a fue 0,60 pp.
TOL_LECTURA_PARQUET <- 0.75   # puntos porcentuales
```

Si esa diferencia supera 0,75 pp, **algo se leyó mal**: un filtro de comuna equivocado, un
geocódigo casteado con pérdida, una unidad territorial perdida en la unión. Es un canario,
no una tolerancia del producto.

El valor **se deriva de la medición** (0,60 pp máximo observado, más un margen mínimo para
el redondeo del INE a un decimal), no se elige a priori.

**Distinción que no debe perderse:** este test compara una cifra **corregida** (que el
producto no publica) contra la oficial. La corrección se usa **solo** aquí, como
instrumento de diagnóstico. **No entra al producto** (§3.3).

---

## 5. Criterio de éxito de la capa zonal (reemplaza al del contrato)

La capa está terminada cuando:

1. `TOL_LECTURA_PARQUET` pasa: la proporción comunal corregida por no-respuesta converge a
   la hoja 8 dentro de 0,75 pp, en las 12 celdas (4 comunas × 3 niveles).
2. El indicador está rotulado como **"proporción del grupo en edad oficial que asiste al
   nivel"** en leyenda, popups y exportaciones. La expresión "tasa neta" no aparece en
   ningún texto visible referida a la cifra del mapa.
3. La nota metodológica declara la discrepancia con el INE, su magnitud medida y su causa.
4. El popup de una unidad no muestra la cifra comunal del INE junto a la de la unidad.
5. La unión Zonal ∪ Localidades no produce doble conteo (medido en el Hito 2a: solape de
   área = 0,0 ha; verificar que se conserve tras la simplificación).
6. Ningún identificador individual entra a `docs/data/`.

---

## 6. Hechos verificados que el script de producción debe respetar

Todos medidos en el Hito 2a. Ninguno asumido.

| Hecho | Valor medido | Implicancia |
|---|---|---|
| Tipo de geometría de Localidades | **MULTIPOLYGON** | No es puntual: la tasa se puede colorear como en la capa urbana. El rediseño que este riesgo habría forzado **no** es necesario |
| Llave de Localidades | **`ID_LOCALIDAD`** (8 dígitos) | **No** es `ID_ZONA`, que en las localidades rurales viene vacío. La unión urbano+rural se hace por llaves distintas, no por una común |
| Llave de Zonal | `ID_ZONA` (9 dígitos) | — |
| Localidades en R5 / Costa Central | 532 / **37** | Concón 2, Puchuncaví 16, Quintero 16, Viña del Mar 3 |
| Zonas en R5 / Costa Central | 694 / **159** | Concón 15, Puchuncaví 16, Quintero 13, Viña del Mar 115 |
| Indicadores incrustados en ambas capas | **Sí**, con **0 NA** en R5 y en Costa Central | El join con el CSV agregado **no es necesario** en ninguna de las dos |
| Solape espacial urbano ∩ rural | **0,0 ha** | Sin doble conteo. Los 58 pares que `st_intersects` detecta comparten solo borde |
| Cobertura de área comunal por la unión | Concón 95,3 %; Viña 98,8 %; Quintero 99,8 %; Puchuncaví 99,8 % | El 0,2–4,7 % restante es rural disperso, fuera de toda zona o localidad nombrada. **Se declara en la nota metodológica** |
| CRS de ambas capas | EPSG:4674 (SIRGAS 2000, grados) | Proyectar a 32719 antes de toda operación métrica |
| Nombre real de la columna de no-respuesta | **"Nivel educativo no declarado"** (hoja 2) | El encargo la nombró mal. El archivo manda |

---

## 7. Lo que sigue sin determinarse

1. **La no-respuesta a escala sub-comunal.** No existe en el dato publicado. Es la razón
   de toda esta decisión, y no es resoluble sin que el INE publique esa desagregación.
2. **La hoja 2 mide no-respuesta de *nivel educativo alcanzado*, no de *asistencia*.** Son
   preguntas distintas del cuestionario. La coincidencia con la no-respuesta implícita es
   fuerte (§1), pero **no es una identidad**. El ajuste del test de lectura (§4.2) es una
   aproximación validada empíricamente, no una equivalencia demostrada. **Esto es una razón
   adicional para no llevar ese ajuste al producto.**
3. **Cobertura poblacional de la unión.** Se midió cobertura de **área** (95–99,8 %), no de
   población. La convergencia limpia del test sugiere cobertura poblacional alta, pero no
   se contó persona por persona.
4. **Educación superior.** No se validó (el tramo etario 18–24 no calza con un nivel
   escolar simple). Fuera del alcance de v1: el producto cubre parvularia, básica y media.
