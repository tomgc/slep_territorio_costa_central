# Decisión: exclusión del territorio insular del universo del mapa interactivo

**Fecha:** 2026-07-12 (decisión tomada en la sesión 6; archivo formalizado en la sesión 7)
**Ámbito:** variante 3 (mapa interactivo regional), versión 1
**Estado:** vigente
**Traspaso de origen:** `traspaso_cierre_v06.md` §3.3

---

## Contexto

El mapa interactivo cubre la Región de Valparaíso completa. La región incluye dos
territorios insulares oceánicos: **Rapa Nui / Isla de Pascua** (comuna
`COD_COM_RBD` 5201) y **Juan Fernández** (comuna 5104). Ambos tienen
establecimientos educacionales activos con coordenadas válidas en el directorio
oficial, y ambos están a miles de kilómetros del continente.

La pregunta era si el universo del mapa debía ser "la Región de Valparaíso según
la división político-administrativa" o "el entorno territorial del SLEP Costa
Central".

## Decisión

**Los dos territorios insulares quedan excluidos del producto completo en su
versión 1**: no aparecen en el mapa, ni en las tablas, ni en la exportación a
XLSX. El universo resultante es de **1.268 establecimientos educacionales**
continentales (partiendo de 1.274 tras filtrar `ESTADO_ESTAB = 1`).

La exclusión se implementa **por comuna insular**, no por provincia:

```r
COMUNAS_INSULARES_EXCLUIDAS_V1 <- c("5201", "5104")  # Isla de Pascua, Juan Fernández
```

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Incluirlos con el encuadre del mapa ajustado | El encuadre tendría que abarcar 3.500 km de océano. El mapa continental quedaría comprimido a una fracción del viewport, ilegible. |
| Incluirlos sin ajustar el encuadre | Los pines quedarían fuera del área visible por defecto: presentes en los datos pero invisibles en la práctica, que es la peor de las combinaciones (el usuario no los ve, pero los conteos los incluyen). |
| Excluirlos **por provincia** (52 Isla de Pascua, 51 Valparaíso) | Error. La provincia de Valparaíso (51) es mayoritariamente continental: excluirla completa habría eliminado también los establecimientos de Valparaíso, Viña del Mar y Concón. Solo la **comuna** 5104 (Juan Fernández) es insular dentro de esa provincia. |

## Justificación

Hay dos argumentos, y el orden importa:

1. **Argumento cartográfico (el primero en aparecer, el más débil):** la distancia
   distorsiona el encuadre. Es cierto, pero es un argumento sobre la
   implementación, no sobre el alcance: alguien podría responder "pues haz un
   inset" y el argumento se cae.

2. **Argumento de propósito (el decisivo, aportado por el titular):** el mapa
   existe para entender el SLEP Costa Central **y su entorno territorial
   inmediato**. Rapa Nui y Juan Fernández no son "entorno" del SLEP Costa Central
   en ningún sentido operativo: son territorios oceánicos separados, con un
   sistema educativo de características propias y una población muy particular,
   que no dialoga con la pregunta que el mapa responde. Su inclusión no aportaría
   información: agregaría ruido con apariencia de completitud.

El segundo argumento es el que sostiene la decisión. El primero solo la hace
además conveniente.

## Naturaleza de la exclusión

**Es una exclusión de ALCANCE, no de calidad del dato.** Los establecimientos
insulares tienen datos válidos, coordenadas correctas y matrícula real. No se
excluyen porque estén mal: se excluyen porque no pertenecen a la pregunta.

Consecuencia operativa (invariante 🔒): **nadie debe "arreglar" el mapa
reincluyéndolos** al detectar que faltan. Su ausencia es intencional y está
declarada. Reincorporarlos exige un encargo explícito de versión 2, no un bugfix.

## Implicancias

- La cifra de 1.268 establecimientos es el universo canónico del producto. Todo
  gate de validación del pipeline se calibra contra ella.
- **Pendiente de versión 2:** ambos territorios son candidatos a una capa o inset
  separado. Los datos ya están disponibles; solo se filtran. La reincorporación
  es barata si se decide.
- Precedente relacionado: en las variantes 1 y 2 (los afiches), un establecimiento
  de Juan Fernández (RBD 2009) apareció mal clasificado en el universo del SLEP.
  El episodio dejó la lección de validar los datos geográficos contra la geografía
  conocida, y es el antecedente directo de que la insularidad se trate aquí como
  criterio estructural y no como caso puntual.
