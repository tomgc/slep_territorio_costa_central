# =============================================================================
# 10_configuracion.R
# Proposito : Rutas centralizadas, constantes del proyecto y tokens de diseno.
#             Rama A (proyecto publico, raiz unificada): todas las rutas via
#             here::here(); sin variable de entorno ni data root externo.
# Insumos   : 10_utils/10_utils.R (debe cargarse antes).
# Salidas   : objetos de configuracion en el entorno (RUTAS, TIPOS, TOKENS,
#             LIENZO, PROYECTO_ID).
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

PROYECTO_ID <- "slep_georreferenciacion"

# ---- Rutas (Rama A: todo dentro del repo) ----
RUTAS <- list(
  insumos        = here::here("20_insumos"),
  salidas        = here::here("40_salidas"),
  salidas_afiche = here::here("40_salidas", "afiche"),
  handoff        = here::here("design_handoff_mapa_establecimientos"),
  fuentes        = here::here("design_handoff_mapa_establecimientos", "fonts"),
  logo           = here::here(
    "design_handoff_mapa_establecimientos", "assets", "logo-color-stacked.png"
  ),
  maestro        = here::here("20_insumos", "maestro_establecimientos.xlsx")
)

# Helpers de acceso (espejo simple de la API ruta_*() del modelo de dos raices,
# aqui resueltos contra el repo porque el proyecto es publico).
ruta_insumos <- function(...) here::here("20_insumos", ...)
ruta_salidas <- function(...) here::here("40_salidas", ...)

# ---- Mapeo Tipo establecimiento (Excel) -> clave de tipo (README) ----
# El tipo es unico por establecimiento; "Nivel de ensenanza" NO altera el tipo.
MAPEO_TIPO <- c(
  "Jardín infantil"                                = "jardin",
  "Escuela básica"                                 = "basica",
  "Liceo"                                          = "liceo",
  "Escuela especial"                               = "especial",
  "Centro de educación para jóvenes y adultos"     = "adultos"
)

# ---- Tabla de tipos (orden de leyenda: menor a mayor edad) ----
TIPOS <- data.frame(
  key   = c("jardin", "basica", "liceo", "especial", "adultos"),
  label = c("Jardines infantiles", "Escuelas básicas", "Liceos",
            "Educación especial", "Educación de adultos (CEIA)"),
  sub   = c("Educación parvularia", "Enseñanza básica", "Enseñanza media",
            "Escuelas especiales", "CEIA"),
  color = c("#75924E", "#0062A0", "#E88663", "#A6741C", "#4A2746"),
  stringsAsFactors = FALSE
)

# ---- Comunas (orden norte -> sur, segun README) ----
COMUNAS_ORDEN <- c("Puchuncaví", "Quintero", "Concón", "Viña del Mar")

# ---- Lienzo y tokens de diseno (hi-fi del README; NO modificar sin handoff) ----
LIENZO <- list(
  ancho      = 1240L,
  alto       = 1754L,
  header_h   = 190L,
  footer_h   = 72L,
  lista_w    = 468L,
  # margen interior de proyeccion de puntos al marco del mapa, en % del viewBox
  margen_pct = list(x_min = 6, x_max = 94, y_min = 5, y_max = 95)
)

TOKENS <- list(
  pagina      = "#EAE6DC",
  papel       = "#FFFFFF",
  ciruela     = "#4A2746",
  tinta_fuerte= "#1C1212",
  tinta_media1= "#2E2230",
  tinta_media2= "#2E2A28",
  bajada      = "#5d5650",
  muted       = "#9a9488",
  marengo     = "#3A3A3A",
  linea1      = "#E7DFC9",
  linea2      = "#E2D9C4",
  linea3      = "#ECE2C6",
  oceano      = "#EAF3F8",
  costa       = "#C7DCEA",
  sep_comuna  = "#EDE7DA",
  rotulo_com  = "#B6A294",
  rotulo_oce  = "#AECBDB",
  sep_footer  = "#C9A7BC"
)
