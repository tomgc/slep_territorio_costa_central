# =============================================================================
# 31_leer_validar.R
# Proposito : Leer el maestro de establecimientos, limpiar, validar integridad,
#             mapear tipos y asignar numeracion de referencia norte -> sur.
# Insumos   : 20_insumos/maestro_establecimientos.xlsx
# Salidas   : 40_salidas/establecimientos_validados.rds (data.frame ordenado)
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("readxl", "janitor", "dplyr"))

# ---- 3. Librerias ----
library(readxl)
library(janitor)
library(dplyr)

# ---- 4. Constantes ----
COLS_CLAVE <- c("rbd", "comuna", "latitud", "longitud", "tipo_establecimiento")
# Bounding box plausible de las 4 comunas (Region de Valparaiso). Fuera de esto
# se considera coordenada sospechosa y se alerta (no se descarta en silencio).
LAT_RANGO <- c(-33.20, -32.55)
LON_RANGO <- c(-71.70, -71.25)

# ---- 5. Funciones ----

# Lee y normaliza nombres de columnas. RBD SIEMPRE character (es llave).
leer_maestro <- function(ruta = RUTAS$maestro) {
  if (!file.exists(ruta)) {
    stop("No se encuentra el maestro en: ", ruta,
         "\nColoca maestro_establecimientos.xlsx en 20_insumos/.")
  }
  readxl::read_excel(ruta) |>
    janitor::clean_names() |>
    mutate(rbd = as.character(rbd))
}

# Valida integridad: NAs en columnas clave, tipos no mapeados, coordenadas
# fuera de rango, RBD duplicados. Alerta con warning(); no falla en silencio.
validar_maestro <- function(df) {
  for (col in COLS_CLAVE) {
    n_na <- sum(is.na(df[[col]]))
    if (n_na > 0) {
      warning(sprintf("Columna '%s': %d valores NA.", col, n_na), call. = FALSE)
    }
  }
  tipos_no_mapeados <- setdiff(unique(df$tipo_establecimiento), names(MAPEO_TIPO))
  if (length(tipos_no_mapeados) > 0) {
    warning("Tipos no mapeados (revisar MAPEO_TIPO): ",
            paste(tipos_no_mapeados, collapse = " | "), call. = FALSE)
  }
  fuera_lat <- df$latitud  < LAT_RANGO[1] | df$latitud  > LAT_RANGO[2]
  fuera_lon <- df$longitud < LON_RANGO[1] | df$longitud > LON_RANGO[2]
  if (any(fuera_lat | fuera_lon, na.rm = TRUE)) {
    warning(sprintf("%d establecimiento(s) con coordenadas fuera del bounding box esperado.",
                    sum(fuera_lat | fuera_lon, na.rm = TRUE)), call. = FALSE)
  }
  dup <- df$rbd[duplicated(df$rbd)]
  if (length(dup) > 0) {
    warning("RBD duplicados: ", paste(unique(dup), collapse = ", "), call. = FALSE)
  }
  invisible(df)
}

# Mapea tipo, ordena norte->sur (latitud descendente) y asigna n correlativo.
preparar_establecimientos <- function(df) {
  df |>
    mutate(
      tipo   = unname(MAPEO_TIPO[tipo_establecimiento]),
      comuna = factor(comuna, levels = COMUNAS_ORDEN)
    ) |>
    arrange(desc(latitud)) |>
    mutate(n = row_number()) |>
    select(n, rbd, nombre = nombre_del_establecimiento,
           rbd_visualizacion, comuna, tipo, latitud, longitud,
           nivel_de_ensenanza = nivel_de_ensenanza)
}

# ---- 6. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  log_msg("Leyendo maestro de establecimientos...", origen = "31_leer")
  maestro <- leer_maestro()
  log_msg(sprintf("Leidos %d registros.", nrow(maestro)), origen = "31_leer")

  validar_maestro(maestro)
  est <- preparar_establecimientos(maestro)

  # Validacion post: todos con tipo asignado y coordenadas presentes.
  stopifnot(!any(is.na(est$tipo)), !any(is.na(est$latitud)), !any(is.na(est$longitud)))

  salida <- ruta_salidas("establecimientos_validados.rds")
  # Escritura atomica: write -> rename.
  tmp <- paste0(salida, ".tmp")
  saveRDS(est, tmp)
  file.rename(tmp, salida)
  log_msg(sprintf("Guardados %d establecimientos validados en %s",
                  nrow(est), salida), origen = "31_leer")
}
