# =============================================================================
# 00_escanear_proyecto.R
# Proposito : Escanear la raiz de codigo y emitir snapshots de estructura.
#             Retencion estricta = 2 timestamps sellados. Jamas escanea datos
#             externos (Rama A: no aplica, pero la regla se conserva).
# Insumos   : el arbol del proyecto.
# Salidas   : 50_documentacion/estructura/{YYYYMMDD_HHMMSS_estructura.{txt,md},
#             estructura_actual.{txt,md}}
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
# =============================================================================

if (!requireNamespace("here", quietly = TRUE)) utils::install.packages("here")
if (!requireNamespace("fs", quietly = TRUE)) utils::install.packages("fs")
library(fs)

INCLUIR_ARCHIVO <- FALSE  # _archivo/ fuera del escaneo por defecto.
EXCLUIR <- c(".git", ".Rproj.user", "renv", ".quarto")
if (!INCLUIR_ARCHIVO) EXCLUIR <- c(EXCLUIR, "_archivo")

raiz <- here::here()
dir_out <- here::here("50_documentacion", "estructura")
fs::dir_create(dir_out)

archivos <- fs::dir_info(raiz, recurse = TRUE, all = FALSE)
archivos <- archivos[!grepl(paste0("(^|/)(", paste(EXCLUIR, collapse = "|"), ")(/|$)"),
                            fs::path_rel(archivos$path, raiz)), ]

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
rel <- fs::path_rel(archivos$path, raiz)
orden <- order(rel)
lineas <- sprintf("%s%s  (%s)",
                  ifelse(archivos$type[orden] == "directory", "[D] ", "    "),
                  rel[orden],
                  ifelse(archivos$type[orden] == "directory", "-",
                         format(fs::as_fs_bytes(archivos$size[orden]))))
ext <- tools::file_ext(rel[archivos$type != "directory"])
tab_ext <- sort(table(ext[ext != ""]), decreasing = TRUE)

header <- c(
  sprintf("# Estructura del proyecto: %s", basename(raiz)),
  sprintf("Fecha: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("Total entradas: %d (%d carpetas, %d archivos)",
          nrow(archivos), sum(archivos$type == "directory"),
          sum(archivos$type != "directory")),
  "", "## Arbol", ""
)
cuerpo_ext <- c("", "## Conteo por extension", "",
                sprintf("- .%s: %d", names(tab_ext), as.integer(tab_ext)))

contenido_md  <- c(header, "```", lineas, "```", cuerpo_ext)
contenido_txt <- c(header, lineas, cuerpo_ext)

# 1. Escribir snapshot nuevo
f_txt <- file.path(dir_out, sprintf("%s_estructura.txt", ts))
f_md  <- file.path(dir_out, sprintf("%s_estructura.md",  ts))
writeLines(contenido_txt, f_txt, useBytes = TRUE)
writeLines(contenido_md,  f_md,  useBytes = TRUE)

# 2. Actualizar aliases
writeLines(contenido_txt, file.path(dir_out, "estructura_actual.txt"), useBytes = TRUE)
writeLines(contenido_md,  file.path(dir_out, "estructura_actual.md"),  useBytes = TRUE)

# 3. Poda atomica (retencion 2), solo si 1 y 2 terminaron ok
sellados <- list.files(dir_out, pattern = "^\\d{8}_\\d{6}_estructura\\.(txt|md)$")
if (length(sellados) > 0) {
  ts_unicos <- sort(unique(substr(sellados, 1, 15)), decreasing = TRUE)
  conservar <- head(ts_unicos, 2)
  borrar <- sellados[!substr(sellados, 1, 15) %in% conservar]
  if (length(borrar) > 0) file.remove(file.path(dir_out, borrar))
}
cat(sprintf("Escaneo listo: %s\n", basename(f_md)))
