# Auditoría exhaustiva de asignación SLEP — mapa web (§6.A, bloqueante de publicación)

- **Fecha:** 2026-07-12
- **Auditor:** Claude Code (sesión mapa web, hito auditorías)
- **Objeto auditado:** `docs/data/establecimientos.geojson` (1.251 pins) + `docs/data/sin_geo.json`
  (17 EE) + artefacto vivo (`docs/index.html` servido) + XLSX exportado por el propio mapa.
- **Fuente de verdad del cruce:** `20_insumos/auxiliares/listado_slep_2026.xlsx`, hoja
  `Listado SLEP`, filtrada a `num_region == 5`.
- **Método:** verificación **exhaustiva RBD por RBD** (anti-joins sobre los 1.268 EE), **no
  muestral**, en R (`jsonlite` + `readxl`; script reproducible en el Apéndice). El chequeo 7
  se hizo contra el artefacto real en navegador (tooltips renderizados de los 1.251 pins +
  popups abiertos de 6 EE), no contra el código.
- **Contexto del riesgo:** este patrón de bug ya ocurrió una vez en el pipeline
  (`slep_nombre` asignado a EE particulares de comunas traspasadas; lo atrapó el gate
  compuesto de 35/36). Patrón demostrado, no hipotético.

## Veredicto

**VERDE — 0 discrepancias en los 1.268 EE auditados (1.251 pins + 17 sin geo).**
La publicación queda desbloqueada por esta auditoría.

## Cruce comuna → SLEP según el listado oficial (región 5)

| SLEP | Traspaso | Comunas |
|---|---|---|
| Valparaíso | 2021 | Valparaíso, Juan Fernández* |
| Costa Central | 2025 | Concón, Puchuncaví, Quintero, Viña del Mar |
| Aconcagua | 2026 | Catemu, Llaillay, Panquehue, Putaendo, San Felipe, Santa María |
| Los Andes | 2026 | Calle Larga, Los Andes, Rinconada, San Esteban |
| Marga Marga | 2026 | Limache, Olmué, Quilpué, Villa Alemana |
| Petorca | 2026 | Cabildo, La Ligua, Papudo, Petorca — **Zapallar postergada (2027)** |
| del Litoral | 2027 (pend.) | San Antonio, Algarrobo, Cartagena, El Quisco, El Tabo, Casablanca — **Santo Domingo (2028)** |
| Quillota | 2029 (pend.) | Quillota, Calera, Hijuelas, La Cruz, Nogales |

\* Juan Fernández pertenece al SLEP Valparaíso en el listado, pero el territorio insular está
excluido del universo v1 (decisión de alcance documentada en `metadatos.json`), por lo que no
aporta EE al mapa. Hanga Roa (Isla de Pascua, 2027) queda fuera por la misma razón.

## Resultados por chequeo

| # | Chequeo | Resultado |
|---|---|---|
| 0 | Universo: 1.251 pins + 17 sin geo = 1.268; RBD únicos | **OK** |
| 1 | Todo EE con `slep` no vacío tiene `dependencia` = "Servicio Local de Educación" | **OK — 0 excepciones** |
| 2 | Todo EE con dependencia SLEP tiene `slep` válido (uno de los 6 vigentes) | **OK — 0 excepciones** |
| 3 | Particulares (pagado/subvencionado), corp. delegada y municipales con `slep`: recuento | **0** (y universo de dependencias cerrado en 5 valores) |
| 4 | Los 343 con SLEP: `slep` == SLEP oficial de su comuna, RBD por RBD (anti-join) | **OK — 0 excepciones**; ninguno en comuna postergada ni con traspaso > 2026 |
| 5 | Desagregado: Costa Central 73 · Valparaíso 54 · Aconcagua 67 · Marga Marga 58 · Petorca 55 · Los Andes 36 = 343 | **OK — coincidencia exacta en los 6 + suma** |
| 6 | Zapallar (4), Santo Domingo (6), del Litoral sin Sto. Domingo (48), Quillota (47): todos municipales, ninguno con `slep` ni con dependencia SLEP | **OK en los 4 grupos** |
| 7 | Hover/popup del mapa vivo vs GeoJSON crudo | **OK** (detalle abajo) |
| 8 | XLSX exportado por el mapa (1.268 filas): columna SLEP y Dependencia vs JSON, RBD por RBD | **OK — 0 discrepancias** |

### Nota de conteo (chequeo 6)

El encargo cuenta **Santo Domingo (6)** aparte de **del Litoral (48)**, pero el listado
oficial incluye Santo Domingo entre las comunas del SLEP del Litoral (con traspaso propio
2028). Auditadas por separado: del Litoral sin Santo Domingo = 48 exactos; Santo Domingo = 6
exactos; la unión (54) también es 100 % municipal y sin `slep`. No es discrepancia de datos.

### Detalle del chequeo 7 (artefacto real, no el código)

- **Tooltips (hover), exhaustivo:** para cada uno de los **1.251** marcadores se comparó el
  HTML ya renderizado del tooltip contra la dependencia derivada de un **fetch fresco del
  GeoJSON crudo** (no del estado en memoria): `dep == "Servicio Local de Educación"` ⇒ texto
  "Servicio Local de Educación {slep}"; corporación ⇒ etiqueta larga; resto ⇒ literal.
  **0 discrepancias**; además `_props` de cada marcador es idéntico al crudo en
  `dep/slep/com/n` (el JS no reescribe la dependencia).
- **Popups (click), 1 EE por SLEP,** abiertos de verdad en el DOM:

| SLEP | RBD | Línea de dependencia mostrada | Comuna |
|---|---|---|---|
| Costa Central | 12171 | Servicio Local de Educación Costa Central | Viña del Mar ✔ |
| Valparaíso | 12146 | Servicio Local de Educación Valparaíso | Valparaíso ✔ |
| Aconcagua | 11191 | Servicio Local de Educación Aconcagua | San Felipe ✔ |
| Los Andes | 1194 | Servicio Local de Educación Los Andes | Los Andes ✔ |
| Marga Marga | 11231 | Servicio Local de Educación Marga Marga | Limache ✔ |
| Petorca | 11196 | Servicio Local de Educación Petorca | Cabildo ✔ |

Las 6 comunas corresponden al SLEP correcto según el listado oficial.

### Detalle del chequeo 8

`establecimientos_rv_2026-07-11.xlsx` (exportación real del mapa, universo completo):
1.268 filas; todo RBD del XLSX existe en los JSON publicados; columna **SLEP** idéntica al
`slep` del JSON RBD por RBD (vacía cuando `null`); columna **Dependencia** idéntica al `dep`
del JSON (módulo etiqueta larga documentada de la corporación); SLEP no vacío ⇒ Dependencia
SLEP. **0 discrepancias.**

## Apéndice — script reproducible (R)

Ejecutar desde la raíz del proyecto con locale UTF-8:

```r
suppressMessages({ library(jsonlite); library(readxl); library(janitor); library(dplyr) })
DEP_SLEP <- "Servicio Local de Educación"
SLEP_VALIDOS <- c("Valparaíso","Costa Central","Aconcagua","Los Andes","Marga Marga","Petorca")
POSTERGADAS <- c("ZAPALLAR","SANTO DOMINGO")

geo <- fromJSON("docs/data/establecimientos.geojson", simplifyDataFrame = TRUE)
pins <- geo$features$properties |> transmute(rbd, n, com, prov, dep, slep)
singeo <- fromJSON("docs/data/sin_geo.json") |> transmute(rbd, n, com, prov, dep, slep)
ee <- bind_rows(pins, singeo)
stopifnot(nrow(pins) == 1251, nrow(singeo) == 17, !any(duplicated(ee$rbd)))

lst <- read_excel("20_insumos/auxiliares/listado_slep_2026.xlsx", sheet = "Listado SLEP") |>
  clean_names() |> filter(num_region == 5)
mapa_slep <- lst |> distinct(comuna = toupper(nom_comuna_rbd),
                             slep_oficial = nombre_slep_formato, anio = agno_traspaso_educ)
stopifnot(!any(duplicated(mapa_slep$comuna)))

# 1-3
stopifnot(nrow(filter(ee, !is.na(slep), dep != DEP_SLEP)) == 0)
stopifnot(nrow(filter(ee, dep == DEP_SLEP, is.na(slep) | !slep %in% SLEP_VALIDOS)) == 0)
stopifnot(nrow(filter(ee, dep %in% c("Particular Pagado","Particular Subvencionado",
  "Corp. de Administración Delegada","Municipal"), !is.na(slep))) == 0)
# 4
con_slep <- ee |> filter(!is.na(slep)) |> left_join(mapa_slep, by = c("com" = "comuna"))
stopifnot(nrow(con_slep) == 343, !any(is.na(con_slep$slep_oficial)),
          all(con_slep$slep == con_slep$slep_oficial),
          all(con_slep$anio <= 2026), !any(con_slep$com %in% POSTERGADAS))
# 5
esperado <- c("Costa Central"=73,"Valparaíso"=54,"Aconcagua"=67,
              "Marga Marga"=58,"Petorca"=55,"Los Andes"=36)
stopifnot(all(table(con_slep$slep)[names(esperado)] == esperado))
# 6
litoral <- setdiff(toupper(unique(lst$nom_comuna_rbd[lst$nombre_slep_formato == "del Litoral"])),
                   "SANTO DOMINGO")
quillota <- toupper(unique(lst$nom_comuna_rbd[lst$nombre_slep_formato == "Quillota"]))
grupo <- function(coms, n_esp) {
  stopifnot(nrow(filter(ee, com %in% coms, dep == "Municipal")) == n_esp,
            nrow(filter(ee, com %in% coms, !is.na(slep))) == 0,
            nrow(filter(ee, com %in% coms, dep == DEP_SLEP)) == 0) }
grupo("ZAPALLAR", 4); grupo("SANTO DOMINGO", 6); grupo(litoral, 48); grupo(quillota, 47)
cat("6.A VERDE: 0 discrepancias\n")
```

El chequeo 7 se ejecuta en el navegador (consola del mapa servido): comparar
`__M.S.marcadores.get(rbd)._props` y `getTooltip().getContent()` de cada pin contra un
`fetch('data/establecimientos.geojson')` fresco, y abrir los 6 popups listados arriba.
