# =============================================================================
# 00_run_all.R
# Proposito : Orquestador unico del pipeline. Solo orquesta: cero logica de
#             negocio, no modifica scripts de estacion, sin cache por timestamp.
# Insumos   : scripts de 30_procesamiento/.
# Salidas   : artefactos en 40_salidas/.
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

# ---- Anclaje de raiz ----
if (!requireNamespace("rprojroot", quietly = TRUE)) utils::install.packages("rprojroot")
RAIZ <- rprojroot::find_root(rprojroot::has_file(".here") |
                             rprojroot::is_rstudio_project |
                             rprojroot::is_git_root)
if (!requireNamespace("here", quietly = TRUE)) utils::install.packages("here")

# ---- Carga base: utils (bootstrapping) y luego configuracion ----
source(file.path(RAIZ, "10_utils", "10_utils.R"))
source(file.path(RAIZ, "10_utils", "10_configuracion.R"))

# ---- Definicion de pasos (orden de ejecucion) ----
PASOS <- list(
  list(id = 1L, etiqueta = "Leer y validar maestro",      ruta = file.path("30_procesamiento", "31_leer_validar.R")),
  list(id = 2L, etiqueta = "Proyectar al lienzo",         ruta = file.path("30_procesamiento", "32_proyectar_lienzo.R")),
  list(id = 3L, etiqueta = "Generar afiche HTML/SVG",     ruta = file.path("30_procesamiento", "33_generar_afiche.R"))
)

# Verificar al inicio que todas las rutas existan.
for (p in PASOS) {
  if (!file.exists(file.path(RAIZ, p$ruta))) {
    stop(sprintf("Paso %d: no existe la ruta %s", p$id, p$ruta))
  }
}

# ---- run_all ----
run_all <- function(from = NULL, to = NULL, only = NULL, skip = NULL) {
  ids <- vapply(PASOS, function(p) p$id, integer(1))
  sel <- ids
  if (!is.null(from)) sel <- sel[sel >= from]
  if (!is.null(to))   sel <- sel[sel <= to]
  if (!is.null(only)) sel <- intersect(sel, only)
  if (!is.null(skip)) sel <- setdiff(sel, skip)

  t0_total <- Sys.time()
  ejecutados <- integer(0); saltados <- setdiff(ids, sel)

  for (p in PASOS) {
    if (!(p$id %in% sel)) next
    cat(sprintf("\n========== [%d] %s (%s) ==========\n", p$id, p$etiqueta, p$ruta))
    t0 <- Sys.time()
    tryCatch(
      source(file.path(RAIZ, p$ruta), echo = FALSE, chdir = TRUE),
      error = function(e) stop(sprintf("Paso %d fallo: %s", p$id, conditionMessage(e)))
    )
    dur <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
    cat(sprintf("---------- [%d] OK en %s s ----------\n", p$id, dur))
    ejecutados <- c(ejecutados, p$id)
  }

  dur_total <- round(as.numeric(difftime(Sys.time(), t0_total, units = "secs")), 1)
  cat(sprintf("\n===== Resumen: ejecutados {%s} · saltados {%s} · %s s total =====\n",
              paste(ejecutados, collapse = ","),
              paste(saltados, collapse = ","), dur_total))
  invisible(ejecutados)
}

# ---- Ejemplos de uso ----
# run_all()                 # pipeline completo
# run_all(skip = c(1, 2))   # solo generar afiche (usa rds existentes)
# run_all(from = 2)         # desde proyeccion
# run_all(only = 1)         # solo leer y validar
