# =============================================================================
# 37_construir_capa_manzana.R
# Proposito : Construir la capa de DENSIDAD (Censo 2024) a nivel manzana, acotada
#             a Costa Central: conteos de poblacion en edad escolar por manzana,
#             simplificados y reproyectados para Leaflet. Primer codigo de
#             produccion del Censo (contrato de alcance sesion 10, seccion 3/3.1/
#             3.2/3.4/9; capa de manzana NO supersedida).
# Insumos   : 20_insumos/censo_2024/Cartografia_censo2024_Pais_Manzanas.parquet
#             (geoparquet INE, geometria WKB en columna SHAPE, indicadores
#             agregados incrustados; el join con el CSV NO es necesario).
# Salidas   : docs/data/censo_manzanas_cc.geojson (agregados territoriales sin
#             identificador individual; cumple gobernanza de docs/data/).
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-07-12
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("arrow", "sf", "dplyr"))

# ---- 3. Librerias ----
library(arrow)
library(sf)
library(dplyr)

# ---- 4. Rutas centralizadas ----
RUTA_PARQUET_MANZANAS <- ruta_insumos("censo_2024",
                                      "Cartografia_censo2024_Pais_Manzanas.parquet")
RUTA_SALIDA_GEOJSON   <- here::here("docs", "data", "censo_manzanas_cc.geojson")

# ---- 5. Constantes y parametros (POLITICA 5.3.10: cero numeros magicos en flujo) ----
CRS_ORIGEN                  <- 4674    # SIRGAS 2000, GRADOS. Verificado (contrato section 9), no asumido
CRS_METRICO                 <- 32719   # UTM 19S. Solo para operaciones metricas
CRS_WEB                     <- 4326    # Obligatorio para Leaflet
TOLERANCIA_SIMPLIFICACION_M <- 5       # metros. A 20 m colapsan 14%; a 5 m, 3,8%
COMUNAS_COSTA_CENTRAL       <- c("5103", "5105", "5107", "5109")   # character
PRECISION_COORDENADAS       <- 6       # decimales del GeoJSON (~0,1 m)

# Longitudes canonicas de geocodigo (contrato section 9). Un digito perdido = join equivocado.
NCHAR_MANZENT <- 13L
NCHAR_CUT     <- 4L

# Columnas minimas de indicador (el peso importa: no arrastrar las 218 del parquet).
COLS_EDAD <- c("n_edad_0_5", "n_edad_6_13", "n_edad_14_17")

# ---- 6. Funciones ----

# Lee del geoparquet SOLO las manzanas de las comunas pedidas, filtrando en Arrow
# ANTES de materializar geometria (nunca cargar las 216.341 del pais). Reconstruye
# la geometria desde la columna WKB `SHAPE` porque GDAL no tiene driver Parquet.
leer_manzanas_costa_central <- function(ruta, comunas) {
  stopifnot(file.exists(ruta))
  cc_int <- as.integer(comunas)   # CUT es int32 en el parquet; se filtra por el entero
  cols <- c("CUT", "COD_REGION", "MANZENT", COLS_EDAD, "SHAPE")

  d <- arrow::open_dataset(ruta) |>
    dplyr::filter(CUT %in% cc_int) |>
    dplyr::select(dplyr::all_of(cols)) |>
    dplyr::collect()

  # Geocodigos a character INMEDIATAMENTE (sprintf para los double: sin cientifica).
  d$MANZENT <- sprintf("%.0f", d$MANZENT)
  d$CUT     <- as.character(d$CUT)

  # Verificacion dura de tipado: un geocodigo con nchar inconstante = digitos perdidos.
  nm <- unique(nchar(d$MANZENT))
  nc <- unique(nchar(d$CUT))
  if (length(nm) != 1L || nm != NCHAR_MANZENT) {
    stop(sprintf("MANZENT con nchar no constante o != %d: {%s}. Digitos perdidos, abortando.",
                 NCHAR_MANZENT, paste(nm, collapse = ",")))
  }
  if (length(nc) != 1L || nc != NCHAR_CUT) {
    stop(sprintf("CUT con nchar no constante o != %d: {%s}. Digitos perdidos, abortando.",
                 NCHAR_CUT, paste(nc, collapse = ",")))
  }

  # Reconstruir geometria WKB y armar sf en el CRS de origen (grados).
  geom <- sf::st_as_sfc(structure(d$SHAPE, class = "WKB"), EWKB = TRUE)
  sf::st_sf(d[setdiff(names(d), "SHAPE")], geometry = geom, crs = CRS_ORIGEN)
}

# Simplifica en metrico y vuelve a grados. Orden obligatorio (section 9): simplificar en
# grados con tolerancia en metros colapsaria la region a un punto.
simplificar_para_web <- function(x, tolerancia_m) {
  x_metrico <- sf::st_transform(x, CRS_METRICO)
  x_simple  <- sf::st_simplify(x_metrico, dTolerance = tolerancia_m)
  sf::st_transform(x_simple, CRS_WEB)
}

# ---- 7. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {

  # -- lectura --
  log_msg(sprintf("Leyendo manzanas de Costa Central desde %s", RUTA_PARQUET_MANZANAS),
          origen = "37_manzana")
  manzanas <- leer_manzanas_costa_central(RUTA_PARQUET_MANZANAS, COMUNAS_COSTA_CENTRAL)
  n_leidas <- nrow(manzanas)
  log_msg(sprintf("Manzanas leidas tras filtro Costa Central: %d", n_leidas),
          origen = "37_manzana")

  # -- transformacion: simplificar en metrico y volver a grados --
  manzanas_web <- simplificar_para_web(manzanas, TOLERANCIA_SIMPLIFICACION_M)

  # Alinear la geometria a la malla de precision de salida ANTES de escribir. GDAL, al
  # redondear a PRECISION_COORDENADAS decimales en la escritura, degenera algunos slivers
  # a GeometryCollection vacia (defecto de la escritura, no de la geometria en memoria:
  # st_is_empty los da FALSE). El snapping explicito + revalidacion evita esa
  # degeneracion silenciosa: lo que se valida aqui es exactamente lo que se escribe.
  manzanas_web <- sf::st_set_precision(manzanas_web, 10^PRECISION_COORDENADAS)
  manzanas_web <- sf::st_make_valid(manzanas_web)

  # -- limpieza: contar y filtrar las colapsadas (no se ocultan) --
  # Colapsada = vacia o no poligonal tras simplificar+alinear. Se cuenta y se reporta.
  es_poligono <- as.character(sf::st_geometry_type(manzanas_web)) %in%
    c("POLYGON", "MULTIPOLYGON")
  colapsadas <- sf::st_is_empty(manzanas_web) | !es_poligono
  n_colapsadas <- sum(colapsadas)
  message(sprintf("Geometrias colapsadas por simplificacion (%d m): %d de %d (%.2f%%)",
                  TOLERANCIA_SIMPLIFICACION_M, n_colapsadas, n_leidas,
                  100 * n_colapsadas / n_leidas))

  # -- GUARDIA: las colapsadas deben estar VACIAS de poblacion en edad escolar --
  # La auditoria de la sesion 12 midio que las 230 colapsadas a 5 m tienen 0 ninos en los
  # tres tramos, y por eso el descarte no censura poblacion. Pero eso depende de la
  # tolerancia y de la version del dato: el dia que alguien suba TOLERANCIA_SIMPLIFICACION_M
  # (como YA se hizo en la capa zonal, de 5 a 20 m) o llegue un dato nuevo del INE, el
  # descarte podria empezar a borrar manzanas con ninos y hoy nadie se enteraria. Esta
  # guardia convierte ese hallazgo en control permanente. El umbral es CERO, no una
  # tolerancia: un solo nino perdido en silencio es exactamente el defecto que atrapa.
  ninos_colapsados <- vapply(COLS_EDAD,
    function(col) sum(manzanas_web[[col]][colapsadas]), numeric(1))
  if (any(ninos_colapsados > 0)) {
    con_ninos <- colapsadas & (manzanas_web$n_edad_0_5 > 0 |
                               manzanas_web$n_edad_6_13 > 0 |
                               manzanas_web$n_edad_14_17 > 0)
    stop(sprintf(paste0(
      "El descarte de manzanas colapsadas perderia poblacion en edad escolar.\n",
      "  ninos por tramo en las colapsadas: n_edad_0_5=%d, n_edad_6_13=%d, n_edad_14_17=%d\n",
      "  manzanas colapsadas con al menos un nino: %d de %d colapsadas\n",
      "  causa probable: TOLERANCIA_SIMPLIFICACION_M=%d demasiado alta, o dato nuevo del INE.\n",
      "  accion: bajar la tolerancia hasta que las colapsadas vuelvan a tener 0 ninos, o\n",
      "  redisenar el descarte para conservar las manzanas pobladas. NO se escribe la salida."),
      ninos_colapsados["n_edad_0_5"], ninos_colapsados["n_edad_6_13"],
      ninos_colapsados["n_edad_14_17"], sum(con_ninos), n_colapsadas,
      TOLERANCIA_SIMPLIFICACION_M))
  }
  message(sprintf("Las %d colapsadas no contienen poblacion en edad escolar: 0 ninos en los tres tramos.",
                  n_colapsadas))

  manzanas_web <- manzanas_web[!colapsadas, ]

  # -- columnas de salida minimas; conteos a INTEGER (no double) --
  manzanas_web <- manzanas_web |>
    dplyr::mutate(
      n_edad_0_5   = as.integer(n_edad_0_5),
      n_edad_6_13  = as.integer(n_edad_6_13),
      n_edad_14_17 = as.integer(n_edad_14_17)
    ) |>
    dplyr::select(MANZENT, CUT, dplyr::all_of(COLS_EDAD))

  # -- validaciones obligatorias (POLITICA 5.3.8) --
  # Tipado constante tras todo el pipeline.
  stopifnot(
    all(nchar(manzanas_web$MANZENT) == NCHAR_MANZENT),
    all(nchar(manzanas_web$CUT) == NCHAR_CUT)
  )
  # Todas las comunas del resultado pertenecen a Costa Central.
  stopifnot(all(manzanas_web$CUT %in% COMUNAS_COSTA_CENTRAL))
  # Cero NA en los tres conteos (medido: 0 NA en Costa Central).
  stopifnot(
    !anyNA(manzanas_web$n_edad_0_5),
    !anyNA(manzanas_web$n_edad_6_13),
    !anyNA(manzanas_web$n_edad_14_17)
  )
  # El cero es dato real (contrato 3.4): NO se filtra. Se reporta cuantas hay.
  n_cero_basica <- sum(manzanas_web$n_edad_6_13 == 0L)
  # Ninguna geometria vacia y todas poligonales en lo que se escribe.
  stopifnot(
    !any(sf::st_is_empty(manzanas_web)),
    all(as.character(sf::st_geometry_type(manzanas_web)) %in% c("POLYGON", "MULTIPOLYGON"))
  )
  # Todas las geometrias escritas deben ser validas.
  if (!all(sf::st_is_valid(manzanas_web))) {
    stop("Hay geometrias invalidas tras la simplificacion; no se escribe la salida.")
  }

  n_final <- nrow(manzanas_web)
  log_msg(sprintf("Features validos a escribir: %d | con n_edad_6_13==0 (cero real): %d",
                  n_final, n_cero_basica), origen = "37_manzana")

  # -- exportacion atomica (POLITICA 5.2.4): temporal + rename --
  dir.create(dirname(RUTA_SALIDA_GEOJSON), showWarnings = FALSE, recursive = TRUE)
  tmp <- file.path(dirname(RUTA_SALIDA_GEOJSON),
                   paste0(".tmp_", basename(RUTA_SALIDA_GEOJSON)))
  if (file.exists(tmp)) file.remove(tmp)
  sf::st_write(
    manzanas_web, tmp, driver = "GeoJSON", quiet = TRUE,
    layer_options = c(sprintf("COORDINATE_PRECISION=%d", PRECISION_COORDENADAS),
                      "RFC7946=YES")
  )
  file.rename(tmp, RUTA_SALIDA_GEOJSON)

  # -- pesos: crudo y gzip -9 MEDIDO (no estimado) --
  peso_crudo <- file.info(RUTA_SALIDA_GEOJSON)$size
  peso_gzip  <- as.numeric(system(
    sprintf("gzip -9 -c %s | wc -c", shQuote(RUTA_SALIDA_GEOJSON)), intern = TRUE))
  log_msg(sprintf("Escrito %s | crudo %.1f KB | gzip-9 %.1f KB",
                  RUTA_SALIDA_GEOJSON, peso_crudo / 1024, peso_gzip / 1024),
          origen = "37_manzana")
}
