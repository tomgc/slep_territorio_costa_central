# =============================================================================
# 10_utils.R
# Proposito : Bootstrapping del proyecto. Funciones base sin dependencias de
#             paquetes cargados (se llaman con paquete::funcion()). Se cargan
#             ANTES de cualquier library().
# Insumos   : ninguno.
# Salidas   : funciones en el entorno global (instalar_si_falta, log_msg).
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

# ---- instalar_si_falta ----
# Instala los paquetes ausentes y no carga nada (eso lo hace cada script con
# library()). Cero dependencias externas.
instalar_si_falta <- function(paquetes) {
  faltantes <- paquetes[!vapply(
    paquetes,
    function(p) requireNamespace(p, quietly = TRUE),
    logical(1)
  )]
  if (length(faltantes) > 0) {
    message("Instalando paquetes faltantes: ", paste(faltantes, collapse = ", "))
    utils::install.packages(faltantes)
  }
  invisible(TRUE)
}

# ---- log_msg ----
# Logging sin paquetes externos. Formato:
# [YYYY-MM-DD HH:MM:SS] [origen] [NIVEL] mensaje
log_msg <- function(mensaje, nivel = c("INFO", "WARN", "ERROR"), origen = "general") {
  nivel <- match.arg(nivel)
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] [%s] [%s] %s\n", ts, origen, nivel, mensaje))
  invisible(NULL)
}
