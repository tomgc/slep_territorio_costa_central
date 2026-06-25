# =============================================================================
# 33_generar_afiche.R
# Proposito : Generar el afiche A0 (HTML/SVG autocontenido) que reproduce el
#             handoff hi-fi e inyecta los 97 establecimientos reales. Viña del
#             Mar = pines numerados; resto = tarjeta numero + nombre + (RBD),
#             con anti-colision. Fuentes y logo embebidos en base64.
# Insumos   : 40_salidas/establecimientos_proyectados.rds
#             design_handoff_mapa_establecimientos/fonts/*.otf
#             design_handoff_mapa_establecimientos/assets/logo-color-stacked.png
# Salidas   : 40_salidas/afiche/mapa_establecimientos.html
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("dplyr", "base64enc", "glue"))

# ---- 3. Librerias ----
library(dplyr)
library(base64enc)
library(glue)

# ---- 4. Constantes de render ----
FUENTES <- list(
  gobCL_Heavy   = file.path(RUTAS$fuentes, "gobCL_Heavy.otf"),
  gobCL_Regular = file.path(RUTAS$fuentes, "gobCL_Regular.otf"),
  MuseoSans_300 = file.path(RUTAS$fuentes, "MuseoSans-300.otf"),
  MuseoSans_500 = file.path(RUTAS$fuentes, "MuseoSans_500.otf")
)
# Radio de anti-colision de tarjetas, en unidades % del viewBox.
COLISION_DY <- 3.0

# ---- 5. Funciones ----

# Embebe un archivo binario como data URI base64.
data_uri <- function(ruta, mime) {
  if (!file.exists(ruta)) stop("No existe el asset: ", ruta)
  paste0("data:", mime, ";base64,", base64enc::base64encode(ruta))
}

# Bloque @font-face con las 4 fuentes embebidas.
bloque_fontface <- function() {
  ff <- function(fam, peso, key) glue(
    "@font-face{{font-family:'{fam}';src:url({uri}) format('opentype');font-weight:{peso}}}",
    uri = data_uri(FUENTES[[key]], "font/otf")
  )
  paste(
    ff("gobCL", 900, "gobCL_Heavy"),
    ff("gobCL", 400, "gobCL_Regular"),
    ff("Museo Sans", 300, "MuseoSans_300"),
    ff("Museo Sans", 500, "MuseoSans_500"),
    sep = "\n"
  )
}

# Anti-colision vertical simple: dentro de cada comuna de tarjetas, si dos
# puntos quedan a < COLISION_DY en y, se separan. No trunca nombres (regla 1).
separar_tarjetas <- function(df) {
  df |>
    arrange(comuna, y) |>
    group_by(comuna) |>
    mutate(y = {
      yy <- y
      if (length(yy) > 1) for (i in 2:length(yy)) {
        if (yy[i] - yy[i - 1] < COLISION_DY) yy[i] <- yy[i - 1] + COLISION_DY
      }
      yy
    }) |>
    ungroup()
}

# SVG de costa estilizada (replica de Mapa.dc.html).
svg_costa <- function() {
  t <- TOKENS
  glue('<svg viewBox="0 0 100 100" preserveAspectRatio="none" style="position:absolute;inset:0;width:100%;height:100%;display:block">
<rect width="100" height="100" fill="{t$papel}"></rect>
<path d="M0,0 L24,0 C22,9 25,16 19,22 C13,28 11,36 21,44 C27,48 24,56 19,63 C15,69 20,78 13,87 C9,93 11,97 15,100 L0,100 Z" fill="{t$oceano}"></path>
<path d="M24,0 C22,9 25,16 19,22 C13,28 11,36 21,44 C27,48 24,56 19,63 C15,69 20,78 13,87 C9,93 11,97 15,100" fill="none" stroke="{t$costa}" stroke-width="0.7"></path>
<path d="M21,27 L100,27" stroke="{t$sep_comuna}" stroke-width="0.5" stroke-dasharray="2.2 2.4"></path>
<path d="M22,52 L100,52" stroke="{t$sep_comuna}" stroke-width="0.5" stroke-dasharray="2.2 2.4"></path>
<path d="M17,76 L100,76" stroke="{t$sep_comuna}" stroke-width="0.5" stroke-dasharray="2.2 2.4"></path></svg>')
}

# (Builders de leyenda, tarjetas, pines y ensamblado del afiche completo se
# implementan en la sesion de construccion; este stub deja la arquitectura,
# los tokens y la API fijados. Ver traspaso para el plan del paso 4.)
generar_afiche <- function(est) {
  stop("generar_afiche(): pendiente de implementacion en la sesion de construccion. ",
       "La arquitectura (separar_tarjetas, svg_costa, bloque_fontface, data_uri) ya esta lista.")
}

# ---- 6. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  entrada <- ruta_salidas("establecimientos_proyectados.rds")
  if (!file.exists(entrada)) stop("Falta 32. Corre run_all(to = 2) primero.")
  est <- readRDS(entrada)
  log_msg("Generando afiche (stub)...", origen = "33_afiche")
  # html <- generar_afiche(est)
  # salida <- ruta_salidas("afiche", "mapa_establecimientos.html")
  # writeLines(html, salida, useBytes = TRUE)
  log_msg("Stub de generador en su lugar. Implementacion del HTML en proxima sesion.",
          nivel = "WARN", origen = "33_afiche")
}
