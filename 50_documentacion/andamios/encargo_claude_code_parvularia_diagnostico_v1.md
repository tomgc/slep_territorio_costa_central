# Encargo Claude Code — diagnóstico del universo de educación parvularia (R5)

**Pendiente:** N (fase 0) · **Tipo:** diagnóstico, solo medición · **Versión:** v1
**Proyecto:** `slep_georreferenciacion` · **Rama:** `main`

---

## 0. Qué es este encargo y qué NO es

Este encargo **mide**. No construye una capa, no agrega un script numerado al pipeline,
no toca `docs/`, no commitea y no decide el alcance del producto. Su único entregable es
un log con cifras verificadas que permita decidir, en el turno siguiente, tres cosas que
hoy no se pueden decidir sin datos:

1. si el universo parvulario de la Región de Valparaíso es georreferenciable con lo que
   ya hay en el repositorio, o exige una fuente de coordenadas externa;
2. si JUNJI, Fundación Integra y VTF son distinguibles con los campos de la fuente, o
   requieren un directorio aparte;
3. si el producto es una capa más del mapa regional existente o un producto propio.

**Regla de oro de este encargo:** toda cifra que reportes debe venir de un conteo
programático ejecutado por ti en esta corrida. Ninguna cifra puede venir de la
documentación del proyecto, de un traspaso, de la glosa de MINEDUC ni de tu memoria. Si
no la contaste, no la reportas: reportas que no la mediste.

---

## 1. Estado real declarado (verifícalo antes de usarlo)

Estos son los supuestos con los que se escribió el encargo. **Ninguno está verificado
contra el disco.** El PASO 1 los verifica; si alguno resulta falso, detente y repórtalo
antes de seguir.

- La matrícula de educación parvularia 2011–2025 ya está en el repositorio, bajo
  `20_insumos/historico_matricula/Matricula-Ed.-Parvularia-<AÑO>/`, un CSV por año.
  (hipotesis, verificar con: `ls -1 20_insumos/historico_matricula/ | grep -i parvularia`)
- El año más reciente en disco es 2025, con corte al 31-08-2025.
  (hipotesis, verificar con: `ls -1 20_insumos/historico_matricula/Matricula-Ed.-Parvularia-2025/`)
- El directorio con coordenadas de los establecimientos vive en
  `20_insumos/auxiliares/directorio_oficial_ee_publico.csv`.
  (hipotesis, verificar con: `ls -l 20_insumos/auxiliares/directorio_oficial_ee_publico.csv`)
- Los CSV de MINEDUC vienen en `latin1` con separador `;`. Es el patrón histórico del
  proveedor, no un hecho verificado para estos archivos concretos.
- La fuente (`https://datosabiertos.mineduc.cl/matricula-educacion-parvularia/`) declara
  cubrir JUNJI, Fundación Integra y los establecimientos reconocidos oficialmente por el
  Estado. Esa es una afirmación del proveedor: el encargo existe para comprobar si los
  campos del archivo permiten efectivamente separarlos.

**No descargues nada de internet.** Todo el trabajo es sobre archivos ya en disco. Si un
archivo que el encargo asume no existe, detente y repórtalo; no busques un sustituto.

---

## 2. Restricciones no negociables

- **Solo lectura sobre los insumos.** No muevas, renombres, conviertas ni borres nada
  bajo `20_insumos/`.
- **Scripts bloqueados:** `00_run_all.R`, `30_procesamiento/31_*` a `36_*`, `10_utils/*`.
  No los toques ni los leas para modificarlos.
- **No agregues un script numerado al pipeline.** Si necesitas código para medir, va en
  `50_documentacion/andamios/diagnostico_parvularia_r5.R` (andamio, no pipeline).
- **Microdato de personas: prohibido persistir.** Estos archivos son de nivel persona.
  Puedes leerlos en memoria para agregar, pero **ningún artefacto que escribas puede
  contener una fila por persona ni identificador individual** (MRUN, RUT, nombre). Si
  encuentras un identificador individual, decláralo en el log por nombre de columna y no
  lo reproduzcas en ningún ejemplo.
- **Ningún ejemplo de fila cruda en el log.** Cuando necesites ilustrar, muestra nombres
  de columnas y tipos, nunca contenido de una fila de persona.
- **Sin commits, sin push, sin stage.** Al terminar, el working tree queda sucio a
  propósito y yo decido qué entra.
- **R exclusivamente.** Pipe nativo `|>`, `dplyr >= 1.1` con `.by=`, `here::here()` para
  todas las rutas. Nada de Python.
- **Memoria:** los CSV pesan del orden de 150 MB. Lee con selección de columnas y filtra
  la región lo antes posible; no cargues el archivo entero si puedes evitarlo. Si
  necesitas leerlo entero, hazlo un año a la vez y libera con `rm()` + `gc()`.

---

## 3. Pasos

### PASO 1 — Verificación de supuestos y esquema

Antes de contar nada, establece la forma real de los datos.

1. Lista los directorios de parvularia en disco y el CSV de cada uno, con tamaño.
2. Del archivo de 2025, lee **solo las primeras 200 filas** y reporta: separador real,
   encoding real (prueba `latin1` y `UTF-8`; declara cuál produce tildes correctas),
   número de columnas y `names()` completo con el tipo inferido de cada una.
3. Repite el paso 2 para 2011 y para 2018. El objetivo es detectar si el esquema cambió
   a lo largo de la serie: reporta las columnas presentes en 2025 y ausentes en 2011, y
   viceversa.

**GATE:** si las columnas de 2025 no incluyen ninguna de las siguientes familias, detente
y repórtalo antes de seguir: un identificador de establecimiento, un nombre de
establecimiento, un código de comuna, y algún campo de dependencia o administrador.

### PASO 2 — El universo regional, año 2025

Todo lo que sigue se restringe a la Región de Valparaíso (código 5), **incluyendo** las
comunas insulares en el conteo pero marcándolas aparte: la exclusión de 5104 y 5201 es
una regla de las capas publicadas, y en un diagnóstico interesa saber cuánto se pierde.

1. Número de **unidades educativas distintas** en R5, contadas sobre el identificador que
   el PASO 1 haya encontrado. Declara explícitamente cuál columna usaste como llave y
   trátala como `character` siempre.
2. Número de **niños matriculados** en R5.
3. Desglose de unidades y de matrícula por cada campo candidato a "administrador" o
   "dependencia" que exista en el archivo. Reporta la tabla completa de valores
   distintos con su frecuencia, sin agrupar por tu cuenta: quiero ver las categorías
   crudas tal como vienen.
4. Sobre esa tabla, responde con evidencia: **¿se pueden separar JUNJI, Fundación Integra
   y VTF?** Si sí, di con qué columna y qué valores. Si no, di qué falta.
5. Desglose de unidades por comuna, con las cuatro comunas del área de monitoreo
   (Puchuncaví, Quintero, Concón, Viña del Mar) identificadas en la tabla.

### PASO 3 — Georreferenciación: la pregunta que decide todo

1. Cruza las unidades de R5 del PASO 2 contra
   `20_insumos/auxiliares/directorio_oficial_ee_publico.csv` por la llave del PASO 2
   (ambas como `character`, sin coerción numérica en ningún punto del cruce).
2. Reporta: cuántas unidades **matchean**, cuántas no, y de las que matchean, cuántas
   traen coordenadas no nulas y plausibles (dentro del bounding box continental de la
   región).
3. **Desglosa el match por administrador.** Esta es la cifra central del encargo: la
   hipótesis que hay que refutar o confirmar es que las unidades reconocidas oficialmente
   (con RBD) matchean y las de JUNJI/Integra no, porque no tienen RBD. Si es así, dilo con
   los números; si no es así, dilo también.
4. Si hay unidades sin coordenadas, reporta cuántos niños representan. Una unidad sin
   georreferenciar no pesa lo mismo si atiende a 12 niños que si atiende a 300.

### PASO 4 — Viabilidad de la serie histórica

1. Para 2011, 2018 y 2025, cuenta unidades y matrícula de R5 (mismo procedimiento del
   PASO 2). Tres años bastan para el diagnóstico; no proceses los quince.
2. Reporta si la llave de establecimiento es estable entre esos tres cortes: cuántas
   llaves de 2011 siguen presentes en 2025, y si el formato de la llave cambió.
3. Declara si una serie por unidad es viable, es dudosa o es inviable, con la cifra que
   sostiene el juicio.

### PASO 5 — Log

Escribe `50_documentacion/andamios/log_diagnostico_parvularia_r5.md` con, en este orden:

1. Los supuestos del §1 y el resultado de verificar cada uno (verdadero / falso / con qué
   comando).
2. Esquema real: columnas de 2025, y el delta contra 2011 y 2018.
3. Las tablas de los PASOS 2, 3 y 4, con la cifra y el comando o la línea de código que
   la produjo al lado.
4. **Sección "Lo que no medí":** todo lo que el encargo pedía y no pudiste medir, con la
   razón. Esta sección no puede quedar vacía por conveniencia; si de verdad mediste todo,
   escribe "nada" y eso queda como afirmación tuya, verificable.
5. **Sección "Lo que el dato permite y lo que no":** tres párrafos cortos, uno por cada
   una de las tres preguntas del §0, respondidos con las cifras de arriba y no con
   opinión. Si una pregunta quedó sin respuesta, dilo.

---

## 4. Panel adversarial (obligatorio antes de responder)

Responde estos siete puntos en el chat, además del log. Si alguno no lo puedes responder,
el encargo no está terminado.

1. ¿Qué columna usaste como llave de establecimiento, y por qué esa y no otra? ¿La
   trataste como `character` en todos los cruces?
2. ¿Cuántas unidades de R5 hay en 2025 y cuántos niños? ¿Las insulares están dentro o
   fuera de esa cifra?
3. ¿JUNJI, Integra y VTF son separables? Con qué columna y qué valores exactos.
4. ¿Qué porcentaje del universo parvulario regional queda georreferenciable hoy, sin
   fuentes nuevas? ¿Y qué porcentaje de los niños?
5. ¿El déficit de coordenadas se concentra en un administrador, o está repartido?
6. ¿Persististe alguna fila de nivel persona, en cualquier archivo, aunque fuera temporal?
   Si escribiste temporales, ¿los borraste? Nómbralos.
7. ¿Qué archivos tocaste? Da la salida cruda de `git status --short`.

**Gate final:** reporta lo que efectivamente hay y detente en cualquier cosa que este
encargo no explique. Si encuentras algo que contradice el §1, la contradicción es el
hallazgo más importante del turno y va primero en tu respuesta, no al final.
