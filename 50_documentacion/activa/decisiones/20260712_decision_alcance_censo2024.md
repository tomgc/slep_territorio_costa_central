# Decisión de alcance — Capa Censo 2024 en el mapa interactivo

**Fecha:** 2026-07-12 · **Sesión:** 10 · **Proyecto:** `slep_georreferenciacion`
**Estado:** Adoptada
**Insumos que la fundan:**
`50_documentacion/andamios/reporte_diagnostico_censo2024.md` (Etapa 1),
`50_documentacion/andamios/reporte_viabilidad_manzana_censo2024.md` (Etapa 1b).
Todas las cifras de este documento salen de esos dos reportes, medidos sobre el
artefacto real, no de la documentación del INE.

---

> ## ⚠️ SUPERSEDIDA PARCIALMENTE — leer antes de usar este documento
>
> **Sesión 11 (2026-07-12).** La medición del Hito 2a
> (`50_documentacion/andamios/reporte_diagnostico_zonal_censo2024.md`) desmintió el
> indicador especificado aquí para la capa de asistencia.
>
> **Quedan SUPERSEDIDOS por
> `20260712_decision_indicador_asistencia_censo2024.md`:**
>
> - **§3** (el indicador de la capa de asistencia): **no** es la "tasa de asistencia
>   neta" del INE. Ese indicador **no es reconstruible** a escala sub-comunal desde
>   estos datos. Lo que se publica es la **proporción del grupo en edad oficial que
>   asiste al nivel**, que subestima la tasa neta del INE entre 0,53 y 1,35 pp
>   (medido, las 12 celdas del mismo lado).
> - **§6** (validación obligatoria): la convergencia con la hoja 8 **ya no es criterio
>   de éxito del producto**. Se conserva únicamente como **test de integridad de
>   lectura del parquet** (`TOL_LECTURA_PARQUET = 0,75 pp`).
> - **§10** (criterio de éxito), puntos **1** y **3**: reemplazados.
>
> **SIGUE PLENAMENTE VIGENTE** todo el resto: dos capas / dos indicadores / dos
> escalas; la densidad a nivel manzana acotada a Costa Central; el tratamiento del
> cero como dato real; la gobernanza del microdato; las restricciones técnicas de §9.
>
> Este documento **no se edita**: se conserva como registro de lo que se sabía en la
> Etapa 1b. El cambio de diseño lo produjo una medición, y esa trazabilidad es el
> aprendizaje.

---

## 1. Qué se decide

Incorporar el Censo de Población y Vivienda 2024 (INE) al mapa interactivo
(variante 3) como **capa de información territorial**, no como producto separado.

La decisión responde tres preguntas: **qué indicador**, **a qué escala geográfica**,
y **con qué gobernanza**.

---

## 2. Contexto: qué preguntan los datos del Censo que los del SLEP no pueden responder

El SLEP conoce al estudiante **matriculado** (registro `MRUN`, serie 2016–2025). No
conoce al que no lo está, ni sabe dónde vive respecto de dónde hay oferta. El Censo
2024 responde exactamente eso: dónde vive la población en edad escolar, y qué
proporción de ella asiste a educación formal.

Esa asimetría es la justificación completa de la capa. Sin ella, el Censo sería
decoración.

---

## 3. Decisión: dos capas, dos indicadores, dos escalas

| Capa | Unidad geográfica | Indicador | Universo |
|---|---|---|---|
| **Densidad** | **Manzana** | `n_edad_0_5`, `n_edad_6_13`, `n_edad_14_17` (conteos absolutos) | Costa Central (4 comunas) |
| **Asistencia** | **Zona urbana + localidad rural** | Tasa de asistencia neta por nivel (parvularia, básica, media) | Región de Valparaíso continental |

### 3.1 Por qué la densidad va a nivel manzana y la tasa no

**Este es el núcleo de la decisión y la razón de que las capas estén separadas.**

Medido sobre el dato real de Costa Central (Etapa 1b, Fase 5):

- Mediana de `n_edad_6_13` por manzana: **3 niños**.
- Manzanas con cero niños en edad básica: **28,5 %**.

Un **conteo** es robusto ante un `n` pequeño: 3 niños son 3 niños, y el mapa dice la
verdad. Un **cociente** no lo es: una tasa de asistencia calculada sobre un
denominador de 3 salta de 67 % a 100 % por **un solo niño**. Colorear eso no muestra
desescolarización: muestra ruido con apariencia de precisión, e invita a leer un
patrón que no existe. Es peor que no tener el mapa.

A nivel zona/localidad el indicador de tasa es calculable en el **99,4 %** de las
unidades, con denominadores que hacen que la cifra signifique algo.

**Regla general derivada (aplicable a toda la cartera):** *un conteo tolera la
desagregación fina; un cociente no. Antes de mapear una tasa, mirar la distribución
de su denominador, no solo la disponibilidad del numerador.*

### 3.2 Por qué la manzana se acota a Costa Central

No por peso (medido: la región continental completa a nivel manzana son **1,6 MB
gzip**, perfectamente manejable), sino por **pertinencia y render**:

- El detalle de manzana es una herramienta de gestión sobre el territorio propio del
  SLEP. Fuera de él es contexto, y el contexto se lee mejor a escala de zona.
- La prueba de humo de render (FPS de pintado) **no se ha ejecutado**. La Etapa 1b
  midió transferencia (KB), no rendimiento. 5.983 polígonos (Costa Central) es un
  riesgo acotado; 26.662 (región completa) no lo es. Ver §7.

### 3.3 Zona urbana + localidad rural: una sola capa, no dos

La capa zonal del INE (`Zonal_CPV24`) **solo cubre área urbana**: 694 polígonos en la
Región de Valparaíso. El área rural no tiene zona censal; tiene **localidad**
(`Localidades_CPV24`) y entidad.

En el dato agregado, ambas conviven en un mismo archivo:
`Base_zona_localidad_CPV24.csv` (1.263 filas en R5 = 694 zonas urbanas + 536
localidades rurales + resto). El INE las trata como **la misma unidad de análisis**.

**Decisión:** la capa de asistencia se construye uniendo `Zonal_CPV24` (urbano) y
`Localidades_CPV24` (rural). Separarlas contradiría a la fuente y dejaría el
territorio rural de Puchuncaví y Quintero en blanco.

### 3.4 Tratamiento del cero en la capa de densidad

Una manzana con `n_edad_6_13 = 0` **no es un dato faltante**: es un dato real (un
sector industrial, un paño de oficinas, un barrio sin residentes jóvenes).

**Decisión:** se dibuja en **gris neutro, fuera de la escala cromática**, con entrada
propia en la leyenda ("sin población en edad básica"). No se le asigna el color más
claro de la escala (lo disfrazaría de "poco") ni se omite del mapa (borraría el
28,5 % del territorio).

---

## 4. Alternativas consideradas y descartadas

| Alternativa | Por qué se descartó |
|---|---|
| **Todo a nivel comuna** (usando `P7_Educacion.xlsx`, tabulado oficial del INE ya calculado) | Construible en un día, pero el grano es demasiado grueso: una comuna como Viña del Mar promedia realidades opuestas. Se **conserva** como fuente de validación externa (ver §6) |
| **Tasa de asistencia a nivel manzana** | Denominador mediano de 3. La tasa sería ruido. Ver §3.1 |
| **Todo a nivel manzana, región completa** | Peso viable (1,6 MB gzip), pero render no verificado y pertinencia baja fuera del territorio propio |
| **Flujos origen-destino** (`p44_lug_trab`, `p24_lug_resid5`) | El Censo **no pregunta dónde estudia el NNA**, solo si asiste. `p44_lug_trab` es del adulto trabajador. La analogía "commuting escolar" no se sostiene con estas variables. Descartado de v1 |
| **Escolaridad del jefe de hogar como capa** (`escolaridad`, `cine11`) | Viable técnicamente, pero es contexto socioeconómico con alto riesgo de estigmatizar territorios en un producto público. Requiere decisión editorial propia. Diferido a v2 |
| **Leer el microdato de personas** (18,5 M registros) | **Innecesario.** La cartografía geoparquet ya trae los indicadores agregados incrustados (`n_asistencia_*`, `n_edad_*`), con 0 NA en Costa Central. El microdato solo haría falta para cruces que el INE no publicó |

---

## 5. Gobernanza de datos

- **El microdato de personas NO entra al proyecto.** No se usa (ver §4) y, de usarse,
  contiene datos personales sensibles de NNA (`edad`, `sexo`, `div_genero`,
  `p28_autoid_pueblo`, `p29_afrodescendencia`, `p31_religion`, `p27_nacionalidad`,
  `discapacidad`, seis variables `p32*_dificultad_*`), categoría protegida bajo la
  **Ley 21.719** (vigente desde diciembre de 2026, dentro de la vida útil de este
  producto).
- **Lo que se publica son agregados territoriales**, ya sometidos por el INE a control
  de divulgación estadística (regla de frecuencia mínima: celdas con menos de 4 casos
  se suprimen, marcador `*`; regla de concentración; indeterminación geográfica).
- Los insumos del Censo viven en la **raíz de datos del proyecto padre**
  (`slep_estudio_oferta_demanda`), no en este repo. Ver §8.
- `docs/data/` sigue recibiendo **solo agregados sin identificador individual**, como
  hasta ahora. La regla no cambia.

---

## 6. Validación obligatoria antes de publicar

`P7_Educacion.xlsx` (cuarta publicación de resultados del INE, 30 de junio de 2025,
hoja 8) contiene la **tasa de asistencia neta oficial por comuna**. Es el contraste
independiente contra el cual validar la capa de zona: al agregar las zonas de una
comuna, la tasa debe converger a la cifra publicada.

Referencia para las cuatro comunas de Costa Central (hoja 8, tasa neta, %):

| Comuna | Parvularia | Básica | Media | Superior |
|---|---|---|---|---|
| Concón | 55,4 | 96,1 | 88,5 | 57,1 |
| Viña del Mar | 52,0 | 95,6 | 86,7 | 59,5 |
| Puchuncaví | 52,7 | **92,7** | **84,1** | 37,9 |
| Quintero | 49,8 | 95,1 | 85,1 | 42,2 |
| *País* | *52,3* | *95,4* | *87,4* | *46,6* |

**Hallazgo sustantivo, no metodológico:** Puchuncaví tiene la tasa de asistencia
básica más baja de Costa Central (92,7 % contra 95,4 % nacional) y la de media más
baja (84,1 % contra 87,4 %). En un rango regional que va de 90,4 a 97,7, eso la ubica
en el cuartil inferior. **Es exactamente el tipo de hallazgo que la matrícula del SLEP
no puede producir**, y justifica la capa por sí solo.

**Advertencia metodológica sobre la tasa neta:** el INE excluye del denominador a
quienes no respondieron las preguntas 33 y 34. Una comuna con alta no-respuesta puede
mostrar una tasa artificialmente estable. La hoja 2 de `P7_Educacion.xlsx` trae la
columna "Asistencia o nivel educativo no declarado", que permite cuantificar esa
no-respuesta. **Es un check obligatorio antes de publicar cualquier cifra.**

---

## 7. Riesgos abiertos y no resueltos

| # | Riesgo | Estado |
|---|---|---|
| 1 | **Render de ~6.000 polígonos en Leaflet.** La Etapa 1b midió transferencia (KB), no FPS de pintado | **No verificado.** Prueba de humo obligatoria en la Etapa 2, antes de comprometer la capa de manzana |
| 2 | **Simplificación destruye manzanas chicas.** A 20 m colapsan 835 de 5.983 (14 %); a 5 m colapsan 230 (3,8 %) | Mitigado: **tolerancia fijada en 5 m**. El 3,8 % residual debe reportarse, no ocultarse |
| 3 | **Indeterminación geográfica.** La Nota Técnica n°5 declara 13,1 % de manzanas urbanas indeterminadas en Valparaíso (máximo nacional) | **Bajo en Costa Central:** 0,79 % en el dato (39 manzanas), 0 % dibujadas. El 13,1 % es regional, no de nuestras comunas. No distorsiona el mapa, pero se declara en la nota metodológica |
| 4 | **Joins no 1:1.** Manzana: 21.876 con match, 4.786 polígonos sin dato CSV, 1.866 datos sin geometría (códigos `...999999`, indeterminados) | **Falso problema:** la cartografía geoparquet ya trae los indicadores incrustados. El join con el CSV **no es necesario** |

---

## 8. Arquitectura: de dónde se leen los datos

Los insumos del Censo viven en la raíz de datos de **otro proyecto**:
`slep_estudio_oferta_demanda/20_insumos/censo_2024/`.

Tres opciones evaluadas:

- **(A)** Leer directamente de la raíz de datos del proyecto padre, vía una segunda
  variable de entorno.
- **(B)** Copiar a la raíz de datos de este proyecto solo los insumos necesarios.
- **(C)** Construir el producto en el proyecto padre y consumir aquí solo el agregado
  final.

**Decisión: (B).** (A) crea un acoplamiento entre raíces de datos que POLITICA §6.2 no
contempla y que rompe la reproducibilidad en máquina nueva (el proyecto dejaría de
correr si el padre no está sincronizado); (C) parte en dos un producto que es una sola
capa del mapa.

**Insumos a copiar** (tarea manual del titular, no del asistente):
`cartografia/Cartografia_censo2024_Pais_Zonal.parquet`,
`cartografia/Cartografia_censo2024_Pais_Manzanas.parquet`,
`cartografia/Cartografia_censo2024_Pais_Localidades.parquet`,
`documentacion/P7_Educacion.xlsx`.
Destino: `<DATA_ROOT>/20_insumos/censo_2024/`.

---

## 9. Restricciones técnicas verificadas (no asumidas)

| Hecho | Valor medido | Implicancia |
|---|---|---|
| CRS de origen | **EPSG:4674 (SIRGAS 2000)**, en grados | **No es UTM.** Para simplificar en metros hay que proyectar a EPSG:32719 primero, simplificar, y volver a EPSG:4326 para Leaflet |
| Driver Parquet en GDAL | **Ausente** | La lectura va por `arrow` + reconstrucción de geometría desde WKB (columna `SHAPE`), no por `sf::st_read()` directo |
| Tipo de `MANZENT` | `double`, **13 dígitos** | **Se castea a `character` inmediatamente después de leer.** Un `double` de 13 dígitos está en zona de riesgo de pérdida de precisión (POLITICA 5.3.6) |
| Tipo de `ID_ZONA` | `double` | Idem: a `character` |
| Tipo de `CUT` | `int32` | Idem: a `character` (pierde ceros a la izquierda en otras regiones) |
| Manzanas en el país | **216.341** | La presentación del INE dice 168.295. **El dato manda sobre el folleto** |
| Encoding de los CSV | UTF-8 **con BOM**, separador `;` | No Latin-1 |
| Marcador de supresión del INE | `*` | Confirmado: 8.702 celdas en `n_pueblos_orig` de la R5 |
| Supresión en variables escolares (R5) | **0 %** (1 sola celda en `n_asistencia_superior`) | La regla de frecuencia mínima **no muerde** las variables que nos importan |

---

## 10. Criterio de éxito

La capa está terminada cuando:

1. La tasa de asistencia agregada por comuna, calculada desde las zonas, **converge a
   la cifra publicada en `P7_Educacion.xlsx` hoja 8** (tolerancia a definir como
   constante nombrada).
2. El mapa renderiza las dos capas sin degradación perceptible de interacción
   (verificado en navegador, no calculado).
3. El 3,8 % de manzanas colapsadas por simplificación y el 0,79 % de indeterminadas
   están **declarados en la nota metodológica**, no ocultos.
4. Las manzanas con cero niños se distinguen visualmente de las sin dato.
5. Ningún identificador individual entra a `docs/data/`.
