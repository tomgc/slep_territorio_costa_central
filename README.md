# slep_territorio_costa_central

Mapa web de los establecimientos educacionales de la **Región de Valparaíso**,
con matrícula actual e histórica. Es un sitio estático: HTML, CSS y JavaScript
servidos desde `docs/`, sin servidor de aplicación ni base de datos.

Esta es la **variante pública** del proyecto. Existe una variante interna, de la
que ésta se derivó por copia, que incluye capas adicionales y documentación de
gestión que no se publican. La procedencia exacta de este corte, y qué quedó
fuera, están en [`docs/PROCEDENCIA.md`](docs/PROCEDENCIA.md).

---

## Alcance territorial

**Región de Valparaíso completa**, territorio continental. No se recorta a
ninguna comuna ni a ningún servicio local en particular.

Queda fuera el territorio insular oceánico (Rapa Nui e Isla Juan Fernández):
tienen sistema educativo propio y su inclusión distorsiona el encuadre del mapa
continental. Es una decisión de alcance declarada, no un descarte del dato.

---

## Qué capas incluye

Todas las cifras de esta tabla son **unidades que el mapa dibuja**, no totales de
los archivos. La distinción importa: un archivo de datos puede traer más
registros de los que su capa monta, y la columna dice cuáles se ven.

| Capa | Qué muestra | Unidades que el mapa dibuja | Comprobación |
|---|---|---|---|
| **Establecimientos** | Un pin por establecimiento en funcionamiento, con matrícula actual (2025) e histórica (2016-2025), dependencia y oferta por nivel | 1.251 | `jq '.features\|length' docs/data/establecimientos.geojson` |
| **Educación parvularia** | Jardines infantiles y salas cuna **sin RBD** (JUNJI, JUNJI VTF, INTEGRA), con el mismo símbolo que los pines; el color de relleno codifica al sostenedor o administrador: JUNJI e INTEGRA llevan colores propios de la capa, los VTF de comunas con SLEP llevan el color de ese SLEP (el mismo que sus pines) y los VTF de comunas sin traspaso un gris de administrador no identificado | 395 | `jq '[.features[]\|select(.properties.tipo_estab >= 5)]\|length' docs/data/parvularia_r5.geojson` |
| **Frontera regional** | Límite de la Región de Valparaíso y máscara del exterior | 1 | `jq '.features\|length' docs/data/frontera_region.geojson` |
| **Frontera Costa Central** | Límite de las cuatro comunas del servicio local Costa Central | 1 | `jq '.features\|length' docs/data/frontera_costa_central.geojson` |
| **Rótulos comunales** | Nombre de cada comuna sobre el mapa | 36 | `jq 'length' docs/data/comunas_rotulos.json` |

**Por qué la capa parvularia dibuja menos de lo que trae su archivo.**
`docs/data/parvularia_r5.geojson` contiene 1.329 registros, y el mapa monta 395.
La diferencia no es un descarte por calidad del dato: el archivo trae también las
unidades de párvulos de establecimientos **que sí tienen RBD**, y ésas ya
aparecen como pin en la capa de establecimientos. Dibujarlas otra vez las
contaría dos veces. El predicado que separa unas de otras está en
`docs/assets/mapa.js` (`filter: f => f.properties.tipo_estab >= 5`), de modo que
la cifra es verificable sin tomarle la palabra a este documento.

El universo de establecimientos en funcionamiento es de 1.268
(`jq '.universo.n_establecimientos' docs/data/metadatos.json`). Los 17 que no
tienen coordenada válida (`jq 'length' docs/data/sin_geo.json`) no se dibujan,
pero **sí entran en la exportación a XLSX**, en la misma hoja que los demás y
sujetos a los mismos filtros. En esa hoja la columna «Coordenadas» no trae
coordenadas: en los 17 lleva el texto «sin coordenadas», que es el valor del
campo `geo` de sus registros en `docs/data/sin_geo.json`, y en los
georreferenciados queda vacía. Así ningún filtro los pierde por no ser
dibujables.

Sobre el mapa hay **filtros acumulativos** y un selector de **Tipo de EE** que
decide qué capa se dibuja. No toda combinación habilitada devuelve resultados:
cuando una queda en cero, el mapa lo dice con un aviso explícito y un botón para
limpiar los filtros, en vez de quedar vacío.

Dos exportaciones: **SVG** de la vista vigente y **XLSX** de las filas
filtradas.

El fondo cartográfico es CARTO Positron, que se descarga del servicio externo de
CARTO al abrir el mapa. Es la única dependencia de red del sitio: el resto
(Leaflet, SheetJS, tipografías, datos) viaja en este repositorio.

Las teselas se piden con una **clave pública de basemaps que está a la vista en
`docs/assets/mapa.js` por diseño**, no por descuido: es la única forma de usar
el servicio desde un sitio estático sin servidor propio. La clave solo da
acceso al basemap (sin datos), es revocable, y su tier gratuito está limitado a
5.000.000 de teselas por mes calendario. Quien reutilice este sitio debería
obtener su propia clave en CARTO en vez de heredar esta.

## Qué capas NO incluye

Las **capas del Censo 2024** (densidad de población en edad escolar por manzana,
y proporción de asistencia por zona) existen en la variante interna y **no
forman parte de ésta**. Ni el código que las montaba ni sus artefactos de datos
están en este repositorio: se retiraron del árbol, no se ocultaron con una
condición en tiempo de ejecución.

---

## Cómo se levanta el sitio

El sitio vive completo en `docs/`. No hay paso de compilación: lo que está en el
repositorio es exactamente lo que se sirve.

**En línea.** GitHub Pages publica `docs/` de la rama `main`. No hay que
configurar nada más.

**En local.** El mapa carga sus datos con `fetch()`, y eso no funciona abriendo
`docs/index.html` con doble clic: bajo el esquema `file://` el navegador bloquea
esas peticiones. Hace falta un servidor estático cuya raíz sea `docs/`.

Cualquiera sirve, y el repositorio no impone ninguno: no trae dependencias ni
manifiesto de paquetes. Lo único que importa es que la raíz servida sea `docs/`,
para que las rutas relativas del sitio (`data/…`, `assets/…`) resuelvan.

---

## ⚠️ El push es la publicación

**No hay compuerta intermedia entre este repositorio y el sitio público.** Cada
push a `main` reconstruye y republica GitHub Pages con lo que haya en `docs/`,
incluida `docs/data/`.

En esta variante `docs/data/` **sí está versionada**; en la variante interna no
lo está, porque allí los datos se publican por otra vía. Esa diferencia es la
razón por la que este sitio funciona servido desde GitHub Pages sin más
configuración, y también la razón por la que **cualquier archivo que se agregue
a `docs/data/` queda público en el siguiente push**.

Antes de publicar, verificar qué contiene:

```sh
git ls-files docs/data
```

Deben ser exactamente los siete artefactos que el mapa consume. Ninguno más.

---

## El código que genera los datos no está aquí

Este repositorio es **el sitio**, no el proceso que lo alimenta. El pipeline en R
que produce los artefactos de `docs/data/` vive en el proyecto interno y no viaja
a esta variante. La razón y el alcance exacto de esa exclusión están en
[`docs/PROCEDENCIA.md`](docs/PROCEDENCIA.md).

Lo que sí conviene saber de él para leer los datos: el histórico de matrícula del
que salen las cifras contiene identificadores individuales de estudiantes. El
pipeline los usa sólo en memoria para contar estudiantes distintos por
establecimiento y año, y los descarta antes de escribir nada. **Ningún artefacto
publicado en `docs/data/` contiene un dato individual:** todos son conteos
agregados por establecimiento.

---

## Cómo leer las cifras

Las reglas de cálculo están declaradas, en detalle y junto al propio dato, en
`docs/data/metadatos.json`. Tres que conviene conocer antes de interpretar el
mapa:

- **La dependencia no es literal del directorio.** El directorio oficial tiene
  corte al 30 de abril de 2025 y antecede a varios traspasos a Servicios Locales
  de Educación Pública que ya ocurrieron. Los datos publican la dependencia ya
  recodificada a la situación vigente en 2026 (criterio declarado en
  `docs/data/metadatos.json`), manteniendo como municipales las comunas cuyo
  traspaso todavía no ocurre; el mapa la rotula tal cual viene, sin
  recodificarla.
- **Los años sin matrícula no se cuentan como cero.** La fuente no contiene
  matrículas cero explícitas: un establecimiento sin estudiantes en un año
  simplemente no tiene fila. Contar esos huecos como cero hundiría los promedios
  y los mínimos de establecimientos con historia escasa pero real.
- **Sin matrícula no siempre significa cerrado.** Un establecimiento puede
  aparecer sin registro por estar en cierre progresivo o por no haber tenido
  nunca un estudiante matriculado en la ventana observada. Ambas situaciones se
  distinguen en el dato: el primero conserva su serie histórica y una oferta con
  año (`ensa`) anterior a 2025; el segundo lleva la serie anual completa sin
  registro.

---

## Origen de los datos

Datos públicos del Centro de Estudios del Ministerio de Educación (directorio
oficial de establecimientos e histórico de matrícula) y de los catastros de
educación parvularia. Este repositorio no agrega ni redistribuye dato personal
alguno.

---

## Licencia

El contenido de este repositorio puede reutilizarse bajo la licencia
[Creative Commons Atribución 4.0 Internacional](LICENSE) (CC BY 4.0), con
atribución según la fórmula que ya usa el pie del propio sitio: «Elaborado por
el Área de Monitoreo a partir de datos del Centro de Estudios MINEDUC
(Directorio Oficial y Matrícula por estudiante 2016–2025), listado oficial de
SLEP 2026 y tiles CARTO Positron».
