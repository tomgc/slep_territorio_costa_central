# Procedencia de esta variante

Este repositorio no se creó desde cero ni se clonó: se **copió** desde el árbol
de trabajo de un proyecto interno y se inicializó como repositorio nuevo, con un
commit único.

## De qué corte proviene

- **Fecha del corte:** 27 de agosto de 2026.
- **Qué se copió:** del árbol de trabajo de ese día, lo que sirve al sitio:
  `docs/` completo, el `.gitignore` y el `README.md`, con las capas del Censo
  2024 podadas del front-end. Todo lo demás quedó fuera; lo más relevante se
  lista más abajo, con sus motivos.
- **Sin hash de origen.** El historial del proyecto interno **no viaja** a esta
  variante, de modo que no existe aquí ningún commit al que ese hash pudiera
  referirse. Citarlo daría la impresión de una trazabilidad que este repositorio
  no tiene: su primer commit es la génesis, no un descendiente de nada.

Ese es también el motivo por el que existe este archivo. Sin historial
compartido, la única forma de saber de dónde salió cada cosa y qué se le hizo
después es escribirlo.

## Qué se excluyó deliberadamente, y por qué

| Excluido | Por qué |
|---|---|
| Historial de git del proyecto interno | Contiene la gestión interna de un trabajo de varios meses, que no es material publicable. Además, borrar un archivo del árbol no lo borra del historial: seguiría siendo servible desde cualquier commit anterior |
| Capas del Censo 2024 (código y datos) | Decisión de alcance: esta variante es de matrícula. Se retiró el bloque completo del front-end junto con los artefactos de datos que lo alimentaban, en vez de ocultar la capa con una condición en tiempo de ejecución |
| Documentación interna del proyecto | Traspasos, encargos, actas de decisión, auditorías y registros de sesión del área que sostiene el proyecto. No es material público |
| Insumos crudos | Los datos de origen de los que se derivan los agregados, voluminosos y reconstruibles desde sus fuentes oficiales. El sitio no los necesita: consume lo que hay en `docs/data/` |
| Salidas del pipeline | Productos intermedios y afiches generados, reproducibles desde el código del proyecto interno |
| **Código de procesamiento** | El pipeline en R que produce los artefactos de `docs/data/`, y su configuración de entorno. Dos razones, y la primera basta: **no es ejecutable aquí**, porque depende de insumos y de una raíz de datos que no viajan, de modo que nadie podría reproducir nada con él. La segunda es que su código nombra infraestructura interna del servicio (proyectos de despliegue, rutas de control de acceso, códigos de decisión del área) que no tiene por qué ser pública. La transparencia metodológica que justificaba publicarlo la sirven este documento y el `README.md` |
| Cachés y configuración local | Caché de la cuenta del servicio de despliegue de la variante interna, biblioteca de paquetes de `renv` y configuración de herramientas de trabajo. Nada de eso describe al proyecto: describe a la máquina que lo corrió |
| Material de archivo | Versiones antiguas y exploraciones, conservadas en el proyecto interno |
| Material de handoff de diseño | Prototipos y tipografías de trabajo con que se definió el aspecto del producto. Es material de taller: su función se cumplió cuando el diseño quedó definido, y el sitio publicado no lo usa. Las tipografías que el sitio sí necesita viven en `docs/assets/fonts/` |

## Qué se conserva del proyecto interno

La fuente completa del sitio (`docs/`), su `.gitignore` y el `README.md`. A eso
se suma un único archivo que no proviene del proyecto interno: la licencia
(`LICENSE`), agregada aquí. Nada más: el índice de este repositorio se define
por **inclusión**, no por una lista de exclusiones.

La diferencia no es de estilo. Una lista de exclusiones sólo protege de lo que
alguien encontró y recordó anotar; una lista de inclusiones protege también de lo
que nadie buscó. El criterio aquí es "¿sirve para servir el sitio?", y lo que no
lo cumple no entra, se haya revisado o no.

Puedes comprobar el resultado en un clon:

```sh
git ls-files | cut -d/ -f1 | sort -u
```

## Dónde vive la documentación completa

En el repositorio interno del proyecto, versionada bajo `50_documentacion/`:
decisiones de arquitectura y de alcance, registro de sesiones, auditorías y
mediciones. **No se replica aquí ni en ningún otro sitio.** Una copia fuera de
git deja de estar versionada en el destino y se desactualiza sola; un
repositorio de documentación aparte obliga a sincronizar dos remotos en cada
cierre.

El acceso se solicita al equipo responsable del proyecto interno, como lectura
de ese repositorio.

## La deriva

Las dos variantes siguen **caminos separados** desde el corte. No hay fuente
común ni motor de compilación que genere ambas: una corrección hecha en el
proyecto interno **no llega aquí** salvo que alguien la porte a mano. Eso no es
un defecto de la implementación, es la decisión que se tomó, con su costo
conocido.

La tabla siguiente es el registro de esa deriva. Todo cambio portado desde el
proyecto interno la actualiza. Si deja de llenarse, la deriva se vuelve
invisible, que es exactamente el modo en que un fork deja de ser explicable.

### Cambios portados desde el proyecto interno

| Fecha | Qué | Quién |
|---|---|---|
| 2026-08-29 | **Inyección de `slep_sostenedor` y `slep_procedencia`** en `docs/data/parvularia_r5.geojson` (1.329 features, exactamente dos claves nuevas por feature; el resto del archivo quedó byte-idéntico, verificado por reversión). Fuente: el artefacto vigente del proyecto interno, huella `fa1ebd687340d69f21f583ceae99c48717f9ef56c81e1bdc9ea9bfd9e78137d4`; inyector versionado en el proyecto interno (`50_documentacion/andamios/inyectar_atribucion_fork.R`). **Porte del consumidor** (`docs/assets/mapa.js`): la atribución de Servicio Local de un VTF se lee del dato en vez de derivarse de la comuna (se eliminó `slepDeComuna`), la tarjeta y la exportación declaran la procedencia (frase en la tarjeta, columna `Procedencia` y hoja `Notas` del XLSX) y la leyenda, la nota y la etiqueta del tipo 6 dejaron de decir «administrador» y «comuna sin traspaso». `README.md` actualizado en su fila de la capa. Encargo S34-E4 de la sesión 34 del proyecto interno, con verificación completa transcrita en su log | Área de Monitoreo |
