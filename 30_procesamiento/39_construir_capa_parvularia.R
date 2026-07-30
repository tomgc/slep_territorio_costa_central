# =============================================================================
# 39_construir_capa_parvularia.R
# Proposito : Construir la capa de EDUCACION PARVULARIA de la Region de
#             Valparaiso (continental) para el mapa web: una feature por unidad
#             educativa con coordenada valida, con matricula 2025 total y
#             desglosada por nivel. Cubre los tres origenes del dato: MINEDUC
#             (reconocidos), JUNJI (incluido VTF) e INTEGRA.
#             Pendiente N, fase 1, decision "opcion 2": capa adicional del mapa
#             regional vigente, NO producto propio.
# Insumos   : 20_insumos/historico_matricula/Matricula-Ed.-Parvularia-2025/
#               *.csv  (UTF-8, separador ';', 49 columnas, NIVEL PERSONA)
#             docs/data/frontera_region.geojson (solo para el bounding box)
# Salidas   : docs/data/parvularia_r5.geojson (agregado por unidad; SIN ninguna
#             fila de persona y SIN el identificador individual MRUN)
# Gobernanza: el insumo es microdato de personas. Este script agrega en memoria
#             y NUNCA persiste una fila por persona ni la columna MRUN, que no
#             llega siquiera a leerse (no esta en COLS_FUENTE).
# Deuda     : NO esta registrado en 00_run_all.R. El registro pertenece a la
#             decision del pendiente D (grupos de pasos), que sigue abierta.
#             Mientras tanto se corre a mano:
#               Rscript 30_procesamiento/39_construir_capa_parvularia.R
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-07-30
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("data.table", "sf", "dplyr", "jsonlite"))

# ---- 3. Librerias ----
library(data.table)
library(sf)
library(dplyr)

# ---- 4. Rutas centralizadas ----
DIR_PARVULARIA      <- ruta_insumos("historico_matricula", "Matricula-Ed.-Parvularia-2025")
RUTA_FRONTERA       <- here::here("docs", "data", "frontera_region.geojson")
RUTA_SALIDA_GEOJSON <- here::here("docs", "data", "parvularia_r5.geojson")

# ---- 5. Constantes y parametros (POLITICA 5.3.10: cero numeros magicos) ----
CRS_WEB               <- 4326      # obligatorio para Leaflet
COD_REGION_VALPARAISO <- 5L
PRECISION_COORDENADAS <- 6L        # decimales del GeoJSON (~0,1 m)
NCHAR_COD_COMUNA      <- 4L

# Insulares fuera de la capa, como en todas las capas publicadas del proyecto.
COMUNAS_INSULARES <- c("5104", "5201")   # Juan Fernandez, Isla de Pascua

# Area de monitoreo = Costa Central. Codigos VERIFICADOS contra el propio dato
# (`distinct(COD_COM_ESTAB, NOM_COM_ESTAB)` en el andamio de la fase 0), no
# asumidos: 5103 Concon, 5105 Puchuncavi, 5107 Quintero, 5109 Viña del Mar.
# Coinciden con COMUNAS_COSTA_CENTRAL del script 37.
COMUNAS_AREA_MONITOREO <- c("5103", "5105", "5107", "5109")

# Glosa de TIPO_ESTAB tomada del ER oficial que acompaña al CSV 2025
# (ER_Educacion_parvularia_Oficial_WEB.pdf, pag. 3). No es memoria: se leyo.
GLOSA_TIPO_ESTAB <- c(
  "1" = "Escuela Municipal",
  "2" = "Escuela Particular Subvencionado",
  "3" = "Escuela Particular Pagado",
  "4" = "Escuela Servicio Local de Educacion",
  "5" = "JUNJI Administracion Directa",
  "6" = "JUNJI VTF",
  "7" = "INTEGRA Administracion Directa",
  "8" = "INTEGRA CAD")

# Nivel: NIVEL2 es la clasificacion ARMONIZADA en 3 niveles que MINEDUC publica
# para los tres origenes (ER pag. 3: 1 Sala Cuna, 2 Medio, 3 Transicion). Medido:
# 0 NA en los tres origenes. Las columnas por-origen (COD_ENSE2_M, COD_PROG_J,
# COD_MODAL_I) son de programa/modalidad y solo existen en su propio origen: NO
# sirven para el desglose transversal.
NIVEL2_SALA_CUNA  <- 1L
NIVEL2_MEDIO      <- 2L
NIVEL2_TRANSICION <- 3L

# Las 8 unidades continentales sin coordenada usable, medidas en la fase 0
# (7 INTEGRA Administracion Directa + 1 JUNJI Administracion Directa; 177 niños).
# Se declaran UNA A UNA a proposito: la guardia de la seccion 6 aborta si aparece
# cualquier otra, para que una perdida nueva nunca pase en silencio.
UNIDADES_SIN_GEO_CONOCIDAS <- c(
  "40801",    # coordenada fuera de la region (cae en Rio Hurtado, Coquimbo)
  "40802",    # coordenada fuera de la region (cae en Rio Hurtado, Coquimbo)
  "52320",    # coordenada ausente
  "52321",    # coordenada ausente
  "53303",    # coordenada ausente
  "53402",    # coordenada ausente
  "53701",    # coordenada fuera de la region (cae en Isla de Pascua)
  "5701014")  # coordenada fuera de la region (cae en San Clemente, Maule)

# Columnas minimas de la fuente. MRUN NO se pide: el identificador individual no
# entra a memoria en ningun momento.
COLS_FUENTE <- c("COD_REG_ESTAB", "COD_COM_ESTAB", "NOM_COM_ESTAB", "ID_ESTAB",
                 "NOM_ESTAB", "ORIGEN", "TIPO_ESTAB", "NIVEL2",
                 "LATITUD", "LONGITUD")
# Llaves y codigos SIEMPRE character (POLITICA 7: RBD/RUT/codigos nunca numeric).
COLS_CHARACTER <- c("ID_ESTAB", "COD_COM_ESTAB", "LATITUD", "LONGITUD")

# ---- 6. Funciones ----

# Normalizador UNICO de coordenada. La matricula usa PUNTO decimal y el
# directorio oficial usa COMA: forzar un `dec=` en fread devuelve la otra fuente
# como character sin avisar y toda comparacion numerica da falso en silencio
# (medido en la fase 0). Por eso la coordenada se lee como texto y se normaliza
# aqui, en un solo lugar.
num_coord <- function(x) {
  if (is.numeric(x)) return(x)
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", ".", x, fixed = TRUE)))
}

# Lee el CSV de matricula parvularia restringido a la region pedida.
leer_matricula_region <- function(dir_fuente, cod_region) {
  f <- list.files(dir_fuente, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  if (length(f) != 1L) {
    stop(sprintf("Se esperaba exactamente 1 CSV en %s y hay %d. No se puede elegir por ti.",
                 dir_fuente, length(f)))
  }
  d <- data.table::fread(
    f, sep = ";", encoding = "UTF-8", select = COLS_FUENTE,
    colClasses = list(character = COLS_CHARACTER), showProgress = FALSE)
  data.table::setnames(d, toupper(names(d)))
  tibble::as_tibble(d) |>
    filter(COD_REG_ESTAB == cod_region) |>
    mutate(LATITUD  = num_coord(LATITUD),
           LONGITUD = num_coord(LONGITUD),
           COD_COM_ESTAB = formatC(COD_COM_ESTAB, width = NCHAR_COD_COMUNA,
                                   flag = "0", format = "d"))
}

# Bounding box continental de la region, del artefacto que ya publica el mapa.
bbox_continental <- function(ruta) {
  bb <- sf::st_bbox(sf::st_read(ruta, quiet = TRUE))
  function(lat, lon) {
    !is.na(lat) & !is.na(lon) &
      lon >= bb[["xmin"]] & lon <= bb[["xmax"]] &
      lat >= bb[["ymin"]] & lat <= bb[["ymax"]]
  }
}

# ---- 7. Flujo ----

log_msg("Leyendo matricula parvularia 2025 (nivel persona, solo en memoria)",
        origen = "39_parvularia")
matricula <- leer_matricula_region(DIR_PARVULARIA, COD_REGION_VALPARAISO)
n_filas_r5 <- nrow(matricula)

# -- insulares fuera, como en todas las capas publicadas --
continental <- matricula |> filter(!COD_COM_ESTAB %in% COMUNAS_INSULARES)
n_filas_continental <- nrow(continental)
log_msg(sprintf("Filas R5: %d | continentales: %d | insulares descartadas: %d",
                n_filas_r5, n_filas_continental, n_filas_r5 - n_filas_continental),
        origen = "39_parvularia")

# -- el nombre y los atributos deben ser constantes dentro de una llave --
inconsistentes <- continental |>
  summarise(n_nombres = n_distinct(NOM_ESTAB), n_tipos = n_distinct(TIPO_ESTAB),
            .by = ID_ESTAB) |>
  filter(n_nombres > 1 | n_tipos > 1)
if (nrow(inconsistentes) > 0) {
  stop(sprintf(paste0(
    "%d unidades tienen NOM_ESTAB o TIPO_ESTAB no constante dentro de la misma\n",
    "  ID_ESTAB. Tomar first() elegiria un valor arbitrario y la capa mentiria.\n",
    "  accion: revisar esas llaves antes de agregar. NO se escribe la salida."),
    nrow(inconsistentes)))
}

# -- agregacion por unidad: AQUI MUERE EL NIVEL PERSONA --
unidades <- continental |>
  summarise(
    nombre           = first(NOM_ESTAB),
    cod_comuna       = first(COD_COM_ESTAB),
    comuna           = first(NOM_COM_ESTAB),
    origen           = first(ORIGEN),
    tipo_estab       = first(TIPO_ESTAB),
    matricula_total  = n(),
    mat_sala_cuna    = sum(NIVEL2 == NIVEL2_SALA_CUNA,  na.rm = TRUE),
    mat_medio        = sum(NIVEL2 == NIVEL2_MEDIO,      na.rm = TRUE),
    mat_transicion   = sum(NIVEL2 == NIVEL2_TRANSICION, na.rm = TRUE),
    lat              = first(LATITUD),
    lon              = first(LONGITUD),
    .by = ID_ESTAB) |>
  rename(id_estab = ID_ESTAB) |>
  mutate(
    tipo_glosa         = unname(GLOSA_TIPO_ESTAB[as.character(tipo_estab)]),
    en_area_monitoreo  = cod_comuna %in% COMUNAS_AREA_MONITOREO,
    origen             = as.integer(origen),
    tipo_estab         = as.integer(tipo_estab),
    matricula_total    = as.integer(matricula_total),
    mat_sala_cuna      = as.integer(mat_sala_cuna),
    mat_medio          = as.integer(mat_medio),
    mat_transicion     = as.integer(mat_transicion))

# El desglose por nivel debe reconstituir el total, o el desglose miente.
desglose_descuadrado <- with(unidades,
  sum(mat_sala_cuna + mat_medio + mat_transicion != matricula_total))
if (desglose_descuadrado > 0) {
  stop(sprintf(paste0(
    "El desglose por nivel no suma el total en %d unidades. Hay valores de NIVEL2\n",
    "  fuera de {1,2,3} o NA que se estan perdiendo. accion: revisar la tabla cruda de\n",
    "  NIVEL2 por origen antes de agregar. NO se escribe la salida."), desglose_descuadrado))
}
if (anyNA(unidades$tipo_glosa)) {
  stop(sprintf(paste0(
    "Hay %d unidades con TIPO_ESTAB fuera de la glosa oficial {1..8}: la glosa del ER\n",
    "  quedo desactualizada respecto del dato. accion: releer el ER y actualizar\n",
    "  GLOSA_TIPO_ESTAB. NO se escribe la salida."), sum(is.na(unidades$tipo_glosa))))
}

# -- particion por georreferencia --
es_valida <- bbox_continental(RUTA_FRONTERA)
unidades <- unidades |> mutate(geo_ok = es_valida(lat, lon))
sin_geo  <- unidades |> filter(!geo_ok)

# -- GUARDIA: ninguna unidad con matricula puede perderse en silencio --
# La fase 0 midio 8 unidades continentales sin coordenada usable (177 niños), y
# estan declaradas una a una en UNIDADES_SIN_GEO_CONOCIDAS. Esta guardia existe
# para el dia que llegue un dato nuevo: si aparece CUALQUIER otra unidad sin
# coordenada y con matricula, el script aborta en vez de publicar una capa con
# niños desaparecidos. El umbral es matricula > 0, no una tolerancia.
inesperadas <- sin_geo |>
  filter(!id_estab %in% UNIDADES_SIN_GEO_CONOCIDAS, matricula_total > 0L)
if (nrow(inesperadas) > 0) {
  stop(sprintf(paste0(
    "Hay %d unidades SIN coordenada usable que no estan en la lista de exclusion\n",
    "  declarada, y suman %d niños que quedarian fuera del mapa sin dejar rastro.\n",
    "  id_estab afectados: %s\n",
    "  causa probable: dato nuevo de MINEDUC, o coordenada que dejo de ser plausible.\n",
    "  accion: verificar cada una y, si corresponde, agregarla a\n",
    "  UNIDADES_SIN_GEO_CONOCIDAS con el motivo al lado. NO se escribe la salida."),
    nrow(inesperadas), sum(inesperadas$matricula_total),
    paste(sort(inesperadas$id_estab), collapse = ", ")))
}
log_msg(sprintf("Excluidas por falta de coordenada usable: %d unidades, %d niños (todas declaradas)",
                nrow(sin_geo), sum(sin_geo$matricula_total)), origen = "39_parvularia")

capa <- unidades |> filter(geo_ok)

# -- cuadratura: la capa debe empatar con el conteo DIRECTO de filas --
# Se cuenta sobre `continental` sin pasar por la agregacion: si la agregacion
# perdiera o duplicara filas, esta comparacion lo delata.
ninos_directo <- continental |>
  filter(!ID_ESTAB %in% sin_geo$id_estab) |>
  nrow()
diferencia <- sum(capa$matricula_total) - ninos_directo
log_msg(sprintf("Cuadratura: suma de matricula_total = %d | conteo directo de filas = %d | diferencia = %d",
                sum(capa$matricula_total), ninos_directo, diferencia), origen = "39_parvularia")
if (diferencia != 0L) {
  stop(sprintf(paste0(
    "La suma de matricula_total (%d) no empata con el conteo directo de filas\n",
    "  continentales con coordenada valida (%d): diferencia %d.\n",
    "  accion: la agregacion por ID_ESTAB esta perdiendo o duplicando filas.\n",
    "  NO se escribe la salida."), sum(capa$matricula_total), ninos_directo, diferencia))
}

# -- validaciones de tipado antes de escribir --
stopifnot(
  is.character(capa$id_estab),
  is.character(capa$cod_comuna),
  all(nchar(capa$cod_comuna) == NCHAR_COD_COMUNA),
  !anyNA(capa$lat), !anyNA(capa$lon),
  all(capa$origen %in% 1:3),
  all(capa$tipo_estab %in% 1:8)
)

# -- a sf y a disco, escritura atomica (POLITICA 5.2.4) --
capa_sf <- capa |>
  select(id_estab, nombre, cod_comuna, comuna, origen, tipo_estab, tipo_glosa,
         matricula_total, mat_sala_cuna, mat_medio, mat_transicion,
         en_area_monitoreo, lat, lon) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = CRS_WEB)

stopifnot(
  !any(sf::st_is_empty(capa_sf)),
  all(as.character(sf::st_geometry_type(capa_sf)) == "POINT")
)

log_msg(sprintf("Features a escribir: %d | matricula total: %d | en area de monitoreo: %d",
                nrow(capa_sf), sum(capa_sf$matricula_total),
                sum(capa_sf$en_area_monitoreo)), origen = "39_parvularia")

dir.create(dirname(RUTA_SALIDA_GEOJSON), showWarnings = FALSE, recursive = TRUE)
tmp <- file.path(dirname(RUTA_SALIDA_GEOJSON),
                 paste0(".tmp_", basename(RUTA_SALIDA_GEOJSON)))
if (file.exists(tmp)) file.remove(tmp)
sf::st_write(capa_sf, tmp, driver = "GeoJSON", quiet = TRUE,
             layer_options = c(sprintf("COORDINATE_PRECISION=%d", PRECISION_COORDENADAS),
                               "RFC7946=YES"))
invisible(file.rename(tmp, RUTA_SALIDA_GEOJSON))
log_msg(sprintf("Escrito: %s", RUTA_SALIDA_GEOJSON), origen = "39_parvularia")

# ---- 8. Auditoria DESDE EL CONSUMIDOR ----
# El proyecto ya se quemo dos veces con jsonlite: NULL serializado como {} y
# arreglos de un elemento desempaquetados a escalar. Por eso la verificacion no
# mira el objeto en memoria: relee el archivo escrito y lo audita como lo vera el
# JS, con jsonlite y no con sf.
crudo <- jsonlite::fromJSON(RUTA_SALIDA_GEOJSON, simplifyVector = FALSE)
props <- lapply(crudo$features, function(f) f$properties)
coords <- lapply(crudo$features, function(f) f$geometry$coordinates)

n_features   <- length(crudo$features)
campos       <- sort(unique(unlist(lapply(props, names))))
tipo_id      <- unique(vapply(props, function(p) class(p$id_estab)[1], character(1)))
tipo_comuna  <- unique(vapply(props, function(p) class(p$cod_comuna)[1], character(1)))
tipo_mat     <- unique(vapply(props, function(p) class(p$matricula_total)[1], character(1)))
suma_mat     <- sum(vapply(props, function(p) as.integer(p$matricula_total), integer(1)))
coords_vacias <- sum(vapply(coords, function(c) length(c) != 2L || anyNA(unlist(c)), logical(1)))
campos_por_feature <- unique(lengths(props))

cat("\n=== AUDITORIA DEL ARTEFACTO (releido desde disco con jsonlite) ===\n")
cat("features            : ", n_features, "\n", sep = "")
cat("campos por feature  : ", paste(campos_por_feature, collapse = ", "), "\n", sep = "")
cat("campos              : ", paste(campos, collapse = ", "), "\n", sep = "")
cat("clase de id_estab   : ", paste(tipo_id, collapse = ", "), "\n", sep = "")
cat("clase de cod_comuna : ", paste(tipo_comuna, collapse = ", "), "\n", sep = "")
cat("clase de matricula  : ", paste(tipo_mat, collapse = ", "), "\n", sep = "")
cat("suma matricula_total: ", suma_mat, "\n", sep = "")
cat("coordenadas vacias  : ", coords_vacias, "\n", sep = "")

# El JS trata id_estab y cod_comuna como llaves: si jsonlite las escribio como
# numero, un cod_comuna "0510" pierde el cero y el join se rompe rio abajo.
stopifnot(
  n_features == nrow(capa_sf),
  suma_mat == sum(capa_sf$matricula_total),
  coords_vacias == 0L,
  identical(tipo_id, "character"),
  identical(tipo_comuna, "character"),
  length(campos_por_feature) == 1L      # ninguna feature con campos faltantes
)
cat("AUDITORIA: OK — el artefacto en disco cuadra con lo agregado.\n")
