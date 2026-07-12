# =============================================================================
# 38_construir_capa_zonal.R
# Proposito : Construir la capa de ASISTENCIA (Censo 2024) a nivel zona urbana +
#             localidad rural, para la Region de Valparaiso continental. Publica la
#             "proporcion del grupo en edad oficial que asiste al nivel" por unidad,
#             directo del geoparquet, sin join externo. Indicador definido en la
#             decision de indicador (sesion 11) SS 3.1/3.2; el termino "tasa neta"
#             esta PROHIBIDO como rotulo del producto (SS 3.2).
# Insumos   : 20_insumos/censo_2024/Cartografia_censo2024_Pais_Zonal.parquet
#             20_insumos/censo_2024/Cartografia_censo2024_Pais_Localidades.parquet
#             20_insumos/censo_2024/documentacion/P7_Educacion.xlsx (solo canario de
#             lectura; no produce ninguna columna del GeoJSON).
# Salidas   : docs/data/censo_zonal_r5.geojson (agregados territoriales sin
#             identificador individual; cumple gobernanza de docs/data/).
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-07-12
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("arrow", "sf", "dplyr", "readxl"))

# ---- 3. Librerias ----
library(arrow)
library(sf)
library(dplyr)
library(readxl)

# ---- 4. Rutas centralizadas ----
RUTA_PARQUET_ZONAL       <- ruta_insumos("censo_2024", "Cartografia_censo2024_Pais_Zonal.parquet")
RUTA_PARQUET_LOCALIDADES <- ruta_insumos("censo_2024", "Cartografia_censo2024_Pais_Localidades.parquet")
RUTA_P7_EDUCACION        <- ruta_insumos("censo_2024", "documentacion", "P7_Educacion.xlsx")
RUTA_SALIDA_GEOJSON      <- here::here("docs", "data", "censo_zonal_r5.geojson")

# ---- 5. Constantes y parametros (POLITICA 5.3.10: cero numeros magicos en flujo) ----
CRS_ORIGEN                  <- 4674    # SIRGAS 2000, GRADOS. Verificado, no asumido
CRS_METRICO                 <- 32719   # UTM 19S. Solo para operaciones metricas
CRS_WEB                     <- 4326    # Obligatorio para Leaflet
# Tolerancia medida contra 5 m: a 5 m pesa 782 KB gzip; a 20 m pesa 407 KB y NO colapsa
# ninguna unidad. Se elige 20 m por peso. Las zonas son poligonos grandes: 20 m no las daña.
TOLERANCIA_SIMPLIFICACION_M <- 20
COMUNAS_INSULARES           <- c("5104", "5201")   # Juan Fernandez, Isla de Pascua. Exclusion de ALCANCE
COMUNAS_COSTA_CENTRAL       <- c("5103", "5105", "5107", "5109")   # solo para el canario de lectura
PRECISION_COORDENADAS       <- 6       # decimales del GeoJSON (~0,1 m)
TOL_LECTURA_PARQUET         <- 0.75    # pp. Canario de lectura (SS 4.2); max medido 0,60. NO tolerancia del producto
TOL_SOLAPE_HA               <- 0.5     # ha. Sliver de sub-metro al escribir a 6 decimales dos features
                                       # vecinas (medido ~0,09 ha sobre ~9 km de borde compartido). NO es doble
                                       # conteo: los indicadores son por unidad, no por area. Un bug real de
                                       # simplificacion daria >3 ha (medido para 2 m sin recorte)

# Denominador minimo de confiabilidad de la proporcion (comun a los tres niveles).
# Medido sobre el propio artefacto (reporte_umbral_denominador_zonal.md): la desviacion
# estandar de la proporcion se ESTABILIZA en N=20 (sd sobre el umbral: basica 0,032, parv
# 0,083, media 0,052; su descenso marginal mas alla de 20 es <0,005 por cada +10). A N=20
# se captura el grueso de las celdas patologicas (proporcion exacta 0,0/1,0): parv 78/78,
# media 174/181, basica 192/227 (las patologicas con denominador >=20 son asistencia plena
# o nula reales, no ruido). Censura solo 1,0-2,7% de los ninos de cada nivel (<< 15%). Es un
# umbral de PRESENTACION (fiable_*), no de calculo: la proporcion cruda se conserva siempre.
DENOM_MINIMO        <- 20L

# Longitudes canonicas de geocodigo. Un digito perdido = union equivocada.
NCHAR_ID_ZONA       <- 9L
NCHAR_ID_LOCALIDAD  <- 8L
NCHAR_CUT           <- 4L

COLS_EDAD       <- c("n_edad_0_5", "n_edad_6_13", "n_edad_14_17")
COLS_ASISTENCIA <- c("n_asistencia_parv", "n_asistencia_basica", "n_asistencia_media")
# Nivel -> (numerador asistencia, denominador edad). El orden importa para las proporciones.
NIVELES <- list(
  parv   = c(num = "n_asistencia_parv",   den = "n_edad_0_5"),
  basica = c(num = "n_asistencia_basica", den = "n_edad_6_13"),
  media  = c(num = "n_asistencia_media",  den = "n_edad_14_17")
)

# ---- 6. Funciones ----

# Lee UNA capa del geoparquet (zonal o localidades), filtrando en Arrow ANTES de
# materializar geometria. Excluye las comunas insulares ANTES de toda operacion
# geometrica (exclusion de alcance). Castea geocodigos a character y verifica nchar.
# Unifica la llave propia (ID_ZONA / ID_LOCALIDAD) en `id_unidad` + marca `tipo_unidad`.
leer_capa <- function(ruta, llave, tipo, nchar_llave) {
  stopifnot(file.exists(ruta))
  cols <- c("CUT", "COD_REGION", llave, COLS_EDAD, COLS_ASISTENCIA, "SHAPE")
  d <- arrow::open_dataset(ruta) |>
    dplyr::filter(COD_REGION == 5) |>
    dplyr::select(dplyr::all_of(cols)) |>
    dplyr::collect()

  # Geocodigos a character INMEDIATAMENTE (sprintf para los double).
  d$CUT       <- as.character(d$CUT)
  d[[llave]]  <- sprintf("%.0f", d[[llave]])

  # Exclusion insular ANTES de toda geometria (se mide y reporta el conteo real).
  n_insular <- sum(d$CUT %in% COMUNAS_INSULARES)
  message(sprintf("Excluidas por insularidad en %s: %d (CUT %s)", tipo, n_insular,
                  paste(COMUNAS_INSULARES, collapse = ",")))
  d <- d[!d$CUT %in% COMUNAS_INSULARES, ]

  # Verificacion dura de tipado.
  nl <- unique(nchar(d[[llave]]))
  nc <- unique(nchar(d$CUT))
  if (length(nl) != 1L || nl != nchar_llave) {
    stop(sprintf("%s con nchar no constante o != %d: {%s}. Digitos perdidos, abortando.",
                 llave, nchar_llave, paste(nl, collapse = ",")))
  }
  if (length(nc) != 1L || nc != NCHAR_CUT) {
    stop(sprintf("CUT con nchar no constante o != %d: {%s}. Abortando.",
                 NCHAR_CUT, paste(nc, collapse = ",")))
  }

  geom <- sf::st_as_sfc(structure(d$SHAPE, class = "WKB"), EWKB = TRUE)
  s <- sf::st_sf(d[c("CUT", COLS_EDAD, COLS_ASISTENCIA)], geometry = geom, crs = CRS_ORIGEN)
  s$id_unidad   <- d[[llave]]
  s$tipo_unidad <- tipo
  s
}

# Simplifica en metrico (las zonas son grandes; tolerancia en metros) y revalida.
simplificar_metrico <- function(x) {
  xm <- sf::st_transform(x, CRS_METRICO)
  xs <- sf::st_simplify(xm, dTolerance = TOLERANCIA_SIMPLIFICACION_M, preserveTopology = FALSE)
  sf::st_make_valid(xs)
}

# Lleva a CRS web, alinea a la malla de precision de salida y extrae solo poligonos.
# El snapping evita el defecto de escritura de GDAL (slivers -> GeometryCollection vacia,
# diagnosticado en el Hito 2b); st_collection_extract limpia las collections que deja
# el snap o el recorte, conservando la parte poligonal (no vacia el poligono real).
a_web_limpio <- function(x) {
  xw <- sf::st_transform(x, CRS_WEB)
  xw <- sf::st_make_valid(sf::st_set_precision(xw, 10^PRECISION_COORDENADAS))
  suppressWarnings(sf::st_collection_extract(xw, "POLYGON"))
}

# Solape de area (ha) entre unidades urbanas y rurales, medido en metrico.
solape_urbano_rural_ha <- function(capa) {
  cm <- sf::st_make_valid(sf::st_transform(capa, CRS_METRICO))
  inter <- sf::st_intersection(
    sf::st_union(cm[cm$tipo_unidad == "urbano", ]),
    sf::st_union(cm[cm$tipo_unidad == "rural", ])
  )
  if (length(inter) == 0) 0 else as.numeric(sum(sf::st_area(inter))) / 1e4
}

# Extrae del xlsx del INE (hoja "8" oficial, hoja "2" no-respuesta) las filas de una
# comuna. El nombre real de la columna 14 de la hoja 2 se verifica (el archivo manda).
leer_p7_comuna <- function(h8, h2, cut) {
  fila <- function(h) { for (i in 5:nrow(h)) if (!is.na(h[[i, 5]]) && as.character(h[[i, 5]]) == cut) return(i); NA_integer_ }
  i8 <- fila(h8); i2 <- fila(h2)
  list(
    parv   = as.numeric(h8[[i8, 7]]),  # Tasa asistencia neta Parvularia (oficial)
    basica = as.numeric(h8[[i8, 8]]),  # Basica
    media  = as.numeric(h8[[i8, 9]]),  # Media
    poblacion    = as.numeric(h2[[i2, 7]]),
    no_declarado = as.numeric(h2[[i2, 14]])
  )
}

# Canario de lectura (SS 4.2): valida que LEIMOS BIEN el parquet, NO el indicador del
# producto. Agrega Costa Central, corrige por no-respuesta comunal (solo aqui), compara
# con la hoja 8 y aborta si la diferencia supera TOL_LECTURA_PARQUET. Muere en el script.
test_lectura_parquet <- function(datos_cc) {
  h8 <- readxl::read_excel(RUTA_P7_EDUCACION, sheet = "8", col_names = FALSE, .name_repair = "minimal")
  h2 <- readxl::read_excel(RUTA_P7_EDUCACION, sheet = "2", col_names = FALSE, .name_repair = "minimal")
  nombre_col14 <- as.character(h2[[4, 14]])
  if (nombre_col14 != "Nivel educativo no declarado") {
    stop(sprintf("La columna 14 de la hoja 2 es '%s', no 'Nivel educativo no declarado'. El archivo manda: abortando.",
                 nombre_col14))
  }
  agg <- datos_cc |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(c(COLS_EDAD, COLS_ASISTENCIA)), sum),
      .by = CUT
    )
  difs <- c()
  for (i in seq_len(nrow(agg))) {
    cut <- agg$CUT[i]
    of <- leer_p7_comuna(h8, h2, cut)
    r  <- of$no_declarado / of$poblacion   # factor de no-respuesta comunal
    for (niv in names(NIVELES)) {
      num <- agg[[NIVELES[[niv]]["num"]]][i]; den <- agg[[NIVELES[[niv]]["den"]]][i]
      cruda   <- 100 * num / den
      ajustada <- cruda / (1 - r)           # correccion SOLO para el canario (SS 4.2)
      difs <- c(difs, ajustada - of[[niv]])
    }
  }
  max_dif <- max(abs(difs))
  log_msg(sprintf("Canario de lectura: max|dif| = %.2f pp (TOL_LECTURA_PARQUET = %.2f)",
                  max_dif, TOL_LECTURA_PARQUET), origen = "38_zonal")
  stopifnot(max_dif <= TOL_LECTURA_PARQUET)
  invisible(max_dif)
}

# ---- 7. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {

  # -- lectura de ambas capas (insulares ya excluidas) --
  urbano <- leer_capa(RUTA_PARQUET_ZONAL,       "ID_ZONA",      "urbano", NCHAR_ID_ZONA)
  rural  <- leer_capa(RUTA_PARQUET_LOCALIDADES, "ID_LOCALIDAD", "rural",  NCHAR_ID_LOCALIDAD)
  log_msg(sprintf("Continental: %d zonas urbanas + %d localidades rurales = %d unidades",
                  nrow(urbano), nrow(rural), nrow(urbano) + nrow(rural)), origen = "38_zonal")

  # -- validacion de universo continental --
  stopifnot(nrow(urbano) == 692L, nrow(rural) == 524L)
  stopifnot(!any(urbano$CUT %in% COMUNAS_INSULARES), !any(rural$CUT %in% COMUNAS_INSULARES))

  # -- indicadores sin NA (medido: 0 NA en R5) --
  datos <- rbind(urbano, rural)
  for (col in c(COLS_EDAD, COLS_ASISTENCIA)) {
    if (anyNA(datos[[col]])) stop(sprintf("NA en %s; el parquet debia traer 0 NA en R5.", col))
  }

  # -- canario de lectura (SS 4.2): NO produce ninguna columna del GeoJSON --
  datos_cc <- sf::st_drop_geometry(datos[datos$CUT %in% COMUNAS_COSTA_CENTRAL, ])
  test_lectura_parquet(datos_cc)

  # -- proporcion CRUDA por unidad (SS 3.1); NA donde el denominador es 0 (SS denominador cero) --
  # SIN ajuste por no-respuesta (SS 3.3): la columna exportada es cruda.
  prop <- function(num, den) dplyr::if_else(den == 0L, NA_real_, round(num / den, 4L))
  # Fiabilidad: TRES estados por nivel (umbral de PRESENTACION, no de calculo).
  #   den == 0            -> fiable = NA    (no hay grupo en edad; la proporcion ya es NA)
  #   0 < den < DENOM_MIN  -> fiable = FALSE (hay grupo, pero la cifra es ruidosa)
  #   den >= DENOM_MIN     -> fiable = TRUE
  # La proporcion NO se borra cuando fiable = FALSE: se conserva (el front-end decide si la
  # colorea; los conteos absolutos siempre son verdad).
  fiable <- function(den) dplyr::if_else(den == 0L, NA, den >= DENOM_MINIMO)
  datos <- datos |>
    dplyr::mutate(
      proporcion_asistencia_parv   = prop(n_asistencia_parv,   n_edad_0_5),
      proporcion_asistencia_basica = prop(n_asistencia_basica, n_edad_6_13),
      proporcion_asistencia_media  = prop(n_asistencia_media,  n_edad_14_17),
      fiable_parv   = fiable(n_edad_0_5),
      fiable_basica = fiable(n_edad_6_13),
      fiable_media  = fiable(n_edad_14_17)
    )
  # Reporte de los tres estados por nivel (denominador 0 / ruidoso / fiable).
  for (nv in names(NIVELES)) {
    den <- datos[[NIVELES[[nv]]["den"]]]
    log_msg(sprintf("Estados %s -> den==0 (NA): %d | 0<den<%d (ruidoso, fiable=FALSE): %d | den>=%d (fiable=TRUE): %d",
                    nv, sum(den == 0L), DENOM_MINIMO, sum(den > 0L & den < DENOM_MINIMO),
                    DENOM_MINIMO, sum(den >= DENOM_MINIMO)), origen = "38_zonal")
  }

  suma_control_antes <- sum(datos$n_edad_6_13)

  # -- geometria: simplificar cada capa en metrico y recortar rural contra urbano (urbano
  #    manda en el borde). El recorte elimina el solape que la simplificacion independiente
  #    introduce, sin recalcular ningun indicador. El recorte va en METRICO y el snap a la
  #    malla de salida se aplica DESPUES (a_web_limpio sobre el combinado): asi lo que se
  #    escribe esta on-grid y GDAL no degenera slivers a GeometryCollection al redondear. --
  urb_m <- simplificar_metrico(datos[datos$tipo_unidad == "urbano", ])
  rur_m <- simplificar_metrico(datos[datos$tipo_unidad == "rural", ])
  rur_m <- suppressWarnings(
    sf::st_collection_extract(
      sf::st_make_valid(sf::st_difference(rur_m, sf::st_union(urb_m))), "POLYGON")
  )
  capa <- a_web_limpio(rbind(urb_m, rur_m))

  # -- limpieza: contar colapsadas (vacias o no poligonales) y filtrarlas --
  colapsadas <- sf::st_is_empty(capa) | !as.character(sf::st_geometry_type(capa)) %in%
    c("POLYGON", "MULTIPOLYGON")
  if (any(colapsadas)) {
    message(sprintf("Unidades colapsadas por simplificacion/recorte: %d", sum(colapsadas)))
  }
  capa <- capa[!colapsadas, ]

  # -- columnas de salida EXACTAS (SS validaciones): sin identificador individual --
  capa <- capa |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(c(COLS_EDAD, COLS_ASISTENCIA)), as.integer)
    ) |>
    dplyr::select(
      id_unidad, tipo_unidad, CUT,
      dplyr::all_of(COLS_EDAD), dplyr::all_of(COLS_ASISTENCIA),
      proporcion_asistencia_parv, proporcion_asistencia_basica, proporcion_asistencia_media,
      fiable_parv, fiable_basica, fiable_media
    )

  # -- validaciones obligatorias (abortan) --
  # Todas las unidades presentes tras el recorte (condicion del titular).
  stopifnot(
    sum(capa$tipo_unidad == "urbano") == 692L,
    sum(capa$tipo_unidad == "rural")  == 524L
  )
  # Tipado de geocodigos constante.
  stopifnot(
    all(nchar(capa$id_unidad[capa$tipo_unidad == "urbano"]) == NCHAR_ID_ZONA),
    all(nchar(capa$id_unidad[capa$tipo_unidad == "rural"])  == NCHAR_ID_LOCALIDAD),
    all(nchar(capa$CUT) == NCHAR_CUT)
  )
  # 0 NA en conteos (las proporciones SI pueden ser NA por denominador 0).
  for (col in c(COLS_EDAD, COLS_ASISTENCIA)) stopifnot(!anyNA(capa[[col]]))
  # El recorte NO movio ningun indicador: la suma de conteos es identica.
  suma_control_despues <- sum(capa$n_edad_6_13)
  if (suma_control_antes != suma_control_despues) {
    stop(sprintf("El recorte altero un indicador: sum(n_edad_6_13) %d -> %d. Abortando.",
                 suma_control_antes, suma_control_despues))
  }
  # Geometria: nada vacio, todo poligonal, todo valido.
  stopifnot(
    !any(sf::st_is_empty(capa)),
    all(as.character(sf::st_geometry_type(capa)) %in% c("POLYGON", "MULTIPOLYGON")),
    all(sf::st_is_valid(capa))
  )
  # Solape urbano ∩ rural ~ 0 tras la simplificacion (SS validaciones).
  solape_ha <- solape_urbano_rural_ha(capa)
  log_msg(sprintf("Solape urbano ∩ rural tras simplificacion+recorte: %.5f ha (umbral %.2f)",
                  solape_ha, TOL_SOLAPE_HA), origen = "38_zonal")
  if (solape_ha > TOL_SOLAPE_HA) {
    stop(sprintf("Solape %.4f ha supera el umbral %.2f ha: la union produce doble conteo geometrico. Abortando.",
                 solape_ha, TOL_SOLAPE_HA))
  }

  log_msg(sprintf("Features a escribir: %d (urbano %d, rural %d)", nrow(capa),
                  sum(capa$tipo_unidad == "urbano"), sum(capa$tipo_unidad == "rural")),
          origen = "38_zonal")

  # -- exportacion atomica (POLITICA 5.2.4): temporal + rename --
  dir.create(dirname(RUTA_SALIDA_GEOJSON), showWarnings = FALSE, recursive = TRUE)
  tmp <- file.path(dirname(RUTA_SALIDA_GEOJSON), paste0(".tmp_", basename(RUTA_SALIDA_GEOJSON)))
  if (file.exists(tmp)) file.remove(tmp)
  sf::st_write(
    capa, tmp, driver = "GeoJSON", quiet = TRUE,
    layer_options = c(sprintf("COORDINATE_PRECISION=%d", PRECISION_COORDENADAS), "RFC7946=YES")
  )
  file.rename(tmp, RUTA_SALIDA_GEOJSON)

  # -- pesos: crudo y gzip -9 MEDIDO --
  peso_crudo <- file.info(RUTA_SALIDA_GEOJSON)$size
  peso_gzip  <- as.numeric(system(
    sprintf("gzip -9 -c %s | wc -c", shQuote(RUTA_SALIDA_GEOJSON)), intern = TRUE))
  log_msg(sprintf("Escrito %s | crudo %.1f KB | gzip-9 %.1f KB",
                  RUTA_SALIDA_GEOJSON, peso_crudo / 1024, peso_gzip / 1024), origen = "38_zonal")
}
