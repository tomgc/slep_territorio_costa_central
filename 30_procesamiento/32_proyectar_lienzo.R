# =============================================================================
# 32_proyectar_lienzo.R
# Proposito : Transformar lat/long a coordenadas x/y (% del viewBox 0..100) del
#             lienzo del afiche mediante transformacion lineal con bounding box
#             fijo. Preserva posiciones relativas; sin basemap real (README).
# Insumos   : 40_salidas/establecimientos_validados.rds
# Salidas   : 40_salidas/establecimientos_proyectados.rds
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("dplyr"))

# ---- 3. Librerias ----
library(dplyr)

# ---- 4. Constantes ----
# Tratamiento de marcador por densidad: Viña del Mar = pin; resto = tarjeta.
COMUNA_PIN <- "Viña del Mar"

# ---- 5. Funciones ----

# Transformacion lineal de (lon, lat) al rango [x_min,x_max] x [y_min,y_max]%.
# Oeste (lon menor) -> izquierda; Norte (lat mayor) -> arriba.
proyectar <- function(df, margen = LIENZO$margen_pct) {
  lo0 <- min(df$longitud); lo1 <- max(df$longitud)
  la0 <- min(df$latitud);  la1 <- max(df$latitud)
  df |>
    mutate(
      x = margen$x_min + (longitud - lo0) / (lo1 - lo0) * (margen$x_max - margen$x_min),
      y = margen$y_min + (latitud  - la1) / (la0 - la1) * (margen$y_max - margen$y_min),
      x = round(x, 2),
      y = round(y, 2),
      marcador = if_else(as.character(comuna) == COMUNA_PIN, "pin", "tarjeta")
    )
}

# ---- 6. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  entrada <- ruta_salidas("establecimientos_validados.rds")
  if (!file.exists(entrada)) stop("Falta 31. Corre run_all(only = 1) primero.")

  est <- readRDS(entrada)
  log_msg(sprintf("Proyectando %d puntos al lienzo...", nrow(est)), origen = "32_proy")
  est <- proyectar(est)

  stopifnot(all(est$x >= 0 & est$x <= 100), all(est$y >= 0 & est$y <= 100))

  salida <- ruta_salidas("establecimientos_proyectados.rds")
  tmp <- paste0(salida, ".tmp"); saveRDS(est, tmp); file.rename(tmp, salida)
  log_msg(sprintf("Proyeccion lista (%d pines, %d tarjetas) en %s",
                  sum(est$marcador == "pin"), sum(est$marcador == "tarjeta"),
                  salida), origen = "32_proy")
}
