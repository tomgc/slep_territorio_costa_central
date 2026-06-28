suppressMessages({library(dplyr); library(glue)})
source("10_utils/10_utils.R"); source("10_utils/10_configuracion.R")
# carga las funciones reales del 33 sin ejecutar el flujo principal
e <- new.env()
src <- readLines("30_procesamiento/33_generar_afiche.R")
# corta antes del flujo principal
fin <- grep("^# ---- 11. Flujo principal", src)
writeLines(src[1:(fin-1)], tf <- tempfile(fileext=".R"))
sys.source(tf, envir=e)
est <- readRDS("40_salidas/establecimientos_validados.rds")
est <- e$numerar(est)
cat("nrow est:", nrow(est), "\n")
idx <- e$construir_indice(est)
cat("class idx:", class(idx), " length:", length(idx), "\n")
cnt <- function(s, p) sum(lengths(regmatches(s, gregexpr(p, s, fixed=TRUE))))
cat("min-width:15px en idx:", cnt(idx, "min-width:15px"), "\n")
cat("Caballito en idx:", cnt(idx, "Caballito"), "\n")
# probar cada seccion
for(cc in c("Puchuncaví","Quintero","Concón","Viña del Mar")){
  s <- e$seccion_indice(est, cc, 1)
  cat(sprintf("seccion %-13s length=%d  filas(min-width)=%d\n", cc, length(s), cnt(s,"min-width:15px")))
}
