# =============================================================================
# diagnostico_migracion_github.R
# -----------------------------------------------------------------------------
# Proposito: auditoria de seguridad pre-migracion a GitHub (protocolo 4.3,
#   Fase 1) para slep_georreferenciacion. Proyecto Rama A (datos publicos del
#   directorio MINEDUC: RBD, nombre, tipo, comuna, coordenadas de
#   establecimientos educacionales). El repo SI versiona estos datos, por lo
#   que la auditoria no busca expulsar el maestro, sino confirmar que NO se
#   cuela informacion que no deba ser publica: datos personales hardcodeados
#   (RUT, correos personales), credenciales/tokens, rutas absolutas con el
#   nombre de usuario, referencias a OneDrive, nombres de archivo fuera de
#   norma, y archivos de datos derivados (.csv/.rds) cuyo contenido conviene
#   confirmar publico antes de versionar.
# Insumos: arbol del repo (raiz de codigo), corrido desde la raiz del proyecto.
# Salidas: diagnostico_migracion_github.md (hallazgo, severidad, norma,
#   recomendacion). NO modifica nada: solo reporta. Compuerta de gobernanza:
#   esperar revision del titular antes de cualquier push.
# Autor: equipo Monitoreo SLEP Costa Central
# Fecha: 2026-06-26
# =============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "fs", "stringr", "purrr", "dplyr", "tibble", "readr")
.faltan <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.faltan)) install.packages(.faltan)

# ---- Librerias ----
library(here)
library(fs)
library(stringr)
library(purrr)
library(dplyr)
library(tibble)

# ---- Rutas ----
RAIZ <- here::here()
SALIDA <- here::here("diagnostico_migracion_github.md")

# ---- Constantes y parametros ----
# Identidad del proyecto (para el encabezado del reporte).
PROYECTO   <- "slep_georreferenciacion"
REPO_REMOTO <- "slep_territorio_costa_central"

# Extensiones de texto que se escanean linea por linea por contenido sensible.
EXT_TEXTO <- c("R", "r", "qmd", "Rmd", "md", "txt", "html", "js", "css",
               "json", "yaml", "yml", "csv", "Rproj", "gitignore")

# Carpetas/archivos excluidos del escaneo (ruido, binarios, sistema).
EXCLUIR_DIR <- c(".git", ".Rproj.user", "renv", ".quarto", "_archivo",
                 "node_modules")

# Binarios y datos masivos: no se escanea su contenido (solo su nombre).
EXT_BINARIO <- c("xlsx", "xls", "parquet", "rds", "feather", "doc", "docx",
                 "pdf", "png", "jpg", "jpeg", "gif", "afpub", "otf", "ttf",
                 "shp", "shx", "dbf", "sbn", "sbx", "prj", "cpg",
                 "DS_Store", "min.js")

# Extensiones de DATOS derivados cuyo contenido conviene confirmar publico
# antes de versionar en un proyecto Rama A.
EXT_DATOS <- c("csv", "rds", "parquet", "feather", "xlsx", "xls")

# Patrones sensibles (regex). Cada uno con severidad y norma asociada.
# RUT chileno: 7-8 digitos con o sin puntos, guion, digito verificador.
RX_RUT     <- "\\b\\d{1,2}\\.?\\d{3}\\.?\\d{3}-[\\dkK]\\b"
# Correos.
RX_CORREO  <- "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
# Ruta absoluta con nombre de usuario macOS (/Users/<algo>/).
RX_USERMAC <- "/Users/[A-Za-z0-9._-]+/"
# Ruta OneDrive institucional.
RX_ONEDRIVE <- "OneDrive[A-Za-z0-9 ._-]*"
# Tokens / secretos comunes (ghp_, github_pat_, AKIA, claves genericas).
RX_TOKEN   <- "(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|secret|password|token)\\s*[:=]\\s*[\"'][^\"']{8,})"
# Nombres de archivo/carpeta con tildes, n, o espacios (norma de naming).
RX_NAMING  <- "[\u00e1\u00e9\u00ed\u00f3\u00fa\u00c1\u00c9\u00cd\u00d3\u00da\u00f1\u00d1 ]"

# ---- Funciones ----

# Clasifica una linea contra todos los patrones; devuelve filas de hallazgos.
escanear_linea <- function(ruta_rel, n_linea, texto) {
  hallazgos <- list()
  agrega <- function(tipo, severidad, norma) {
    hallazgos[[length(hallazgos) + 1]] <<- tibble(
      archivo = ruta_rel, linea = n_linea, tipo = tipo,
      severidad = severidad, norma = norma,
      extracto = str_trunc(str_trim(texto), 120)
    )
  }
  if (str_detect(texto, RX_RUT))      agrega("RUT hardcodeado", "ALTA", "Ley 19.628 / 21.719")
  if (str_detect(texto, RX_TOKEN))    agrega("Posible credencial/token", "CRITICA", "Buenas practicas seguridad")
  if (str_detect(texto, RX_USERMAC))  agrega("Ruta absoluta con usuario", "MEDIA", "C.7 portabilidad")
  if (str_detect(texto, RX_ONEDRIVE)) agrega("Referencia a OneDrive", "MEDIA", "C.7 / gobernanza datos")
  if (str_detect(texto, RX_CORREO))   agrega("Correo electronico", "BAJA", "Revisar si es institucional/publico")
  if (length(hallazgos)) bind_rows(hallazgos) else NULL
}

# ---- Flujo principal ----

message("[", format(Sys.time(), "%H:%M:%S"), "] Escaneando arbol desde: ", RAIZ)

# Inventario de todos los archivos, excluyendo carpetas de ruido.
todos <- fs::dir_info(RAIZ, recurse = TRUE, type = "file", all = TRUE) |>
  dplyr::mutate(rel = fs::path_rel(path, RAIZ)) |>
  dplyr::filter(!purrr::map_lgl(rel, function(r) {
    partes <- fs::path_split(r)[[1]]
    any(partes %in% EXCLUIR_DIR)
  }))

message("  Archivos a considerar: ", nrow(todos))

# --- 1. Hallazgos de naming (sobre TODOS los archivos, por su ruta) ---
naming <- todos |>
  dplyr::filter(str_detect(rel, RX_NAMING)) |>
  dplyr::transmute(
    archivo = rel, linea = NA_integer_,
    tipo = "Nombre con tilde/n/espacio", severidad = "MEDIA",
    norma = "Politica seccion 2 (naming)",
    extracto = rel
  )

# --- 2. Hallazgos de contenido (solo archivos de texto) ---
es_texto <- function(p) {
  ext <- fs::path_ext(p)
  nombre <- fs::path_file(p)
  if (nombre %in% c(".gitignore")) return(TRUE)
  if (str_ends(nombre, ".min.js")) return(FALSE)  # binario inlineado, no escanear
  ext %in% EXT_TEXTO && !(ext %in% EXT_BINARIO)
}

archivos_texto <- todos |> dplyr::filter(purrr::map_lgl(path, es_texto))
message("  Archivos de texto a escanear por contenido: ", nrow(archivos_texto))

contenido <- purrr::map_dfr(archivos_texto$path, function(p) {
  rel <- fs::path_rel(p, RAIZ)
  lineas <- tryCatch(readr::read_lines(p), error = function(e) character(0))
  if (!length(lineas)) return(NULL)
  purrr::imap_dfr(lineas, function(txt, i) escanear_linea(rel, i, txt))
})

# --- 3. Inventario de archivos de datos a confirmar (especifico Rama A) ---
# En un proyecto publico el riesgo no es el maestro (es publico), sino un
# .csv/.rds derivado que pudiera contener datos no publicos. Se listan para
# revision manual del titular; NO se asume que sean un problema.
datos <- todos |>
  dplyr::filter(fs::path_ext(path) %in% EXT_DATOS) |>
  dplyr::transmute(
    archivo = rel, linea = NA_integer_,
    tipo = "Archivo de datos a confirmar publico", severidad = "REVISAR",
    norma = "Politica 6.1 / Agencia de Calidad (Rama A)",
    extracto = paste0("Confirmar que el contenido es publico (directorio MINEDUC). ",
                      "Tamano: ", fs::path_file(path))
  )

# --- 4. Consolidacion ---
todos_hallazgos <- bind_rows(naming, contenido, datos)

# Orden por severidad (CRITICA -> ALTA -> MEDIA -> BAJA -> REVISAR) y archivo.
orden_sev <- c("CRITICA" = 1, "ALTA" = 2, "MEDIA" = 3, "BAJA" = 4, "REVISAR" = 5)
if (nrow(todos_hallazgos)) {
  todos_hallazgos <- todos_hallazgos |>
    dplyr::mutate(.ord = orden_sev[severidad]) |>
    dplyr::arrange(.ord, archivo, linea) |>
    dplyr::select(-.ord)
}

# ---- Reporte markdown ----
fecha <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
con <- file(SALIDA, open = "w", encoding = "UTF-8")
wl <- function(...) cat(..., "\n", sep = "", file = con)

wl("# Diagnostico de migracion a GitHub — ", PROYECTO)
wl("")
wl("- **Fecha:** ", fecha)
wl("- **Raiz auditada:** ", RAIZ)
wl("- **Repo remoto destino:** ", REPO_REMOTO, " (privado)")
wl("- **Rama:** A (datos publicos del directorio MINEDUC; se versionan).")
wl("- **Alcance:** datos personales hardcodeados, credenciales/tokens, rutas ",
   "absolutas con informacion de usuario, referencias a OneDrive, correos, ",
   "nombres de archivo fuera de norma, e inventario de archivos de datos a ",
   "confirmar publicos.")
wl("- **Naturaleza Rama A:** el maestro de establecimientos (RBD, nombre, ",
   "tipo, comuna, coordenadas) es publico (directorio MINEDUC) y se versiona; ",
   "no se reporta como hallazgo. Los .csv/.rds derivados se listan como ",
   "REVISAR para confirmacion manual, no como infraccion.")
wl("")
wl("## Resumen")
wl("")
if (!nrow(todos_hallazgos)) {
  wl("**Sin hallazgos.** El arbol esta limpio para publicacion.")
} else {
  resumen <- todos_hallazgos |>
    dplyr::count(severidad) |>
    dplyr::mutate(.ord = orden_sev[severidad]) |>
    dplyr::arrange(.ord)
  wl("| Severidad | N |")
  wl("|---|---|")
  for (i in seq_len(nrow(resumen))) {
    wl("| ", resumen$severidad[i], " | ", resumen$n[i], " |")
  }
  wl("")
  wl("**Total de hallazgos:** ", nrow(todos_hallazgos))
}
wl("")
wl("## Hallazgos detallados")
wl("")
if (!nrow(todos_hallazgos)) {
  wl("(ninguno)")
} else {
  wl("| Severidad | Tipo | Archivo | Linea | Norma | Extracto |")
  wl("|---|---|---|---|---|---|")
  for (i in seq_len(nrow(todos_hallazgos))) {
    h <- todos_hallazgos[i, ]
    ln <- if (is.na(h$linea)) "—" else as.character(h$linea)
    ex <- str_replace_all(h$extracto, "\\|", "\\\\|")
    wl("| ", h$severidad, " | ", h$tipo, " | `", h$archivo, "` | ", ln,
       " | ", h$norma, " | `", ex, "` |")
  }
}
wl("")
wl("## Interpretacion y recomendaciones")
wl("")
wl("- **CRITICA (credenciales):** detener la migracion. Rotar el secreto y ",
   "purgar del historial antes de cualquier push.")
wl("- **ALTA (RUT):** un RUT en codigo o datos es un incidente. Verificar si ",
   "el dato es realmente publico; si no, removerlo y reescribir el historial.")
wl("- **MEDIA (rutas absolutas / OneDrive / naming):** rutas con ",
   "`/Users/<nombre>/` violan portabilidad (C.7); referencias a OneDrive no ",
   "deben viajar al repo; nombres con tilde/n/espacio se renombran ",
   "(politica seccion 2).")
wl("- **BAJA (correos):** revisar caso a caso. Un correo institucional de ",
   "contacto puede ser intencional; uno personal en codigo, no.")
wl("- **REVISAR (archivos de datos):** confirmar uno por uno que el contenido ",
   "es publico (directorio MINEDUC). El maestro y sus .rds derivados de ",
   "georreferenciacion lo son; cualquier .csv/.rds inesperado con asistencia, ",
   "matricula o RUT NO debe versionarse.")
wl("")
wl("> Compuerta de gobernanza (protocolo 4.3, Fase 1): este reporte se revisa ",
   "con el titular ANTES del primer push. La auditoria no decide sola: reporta.")
close(con)

message("[", format(Sys.time(), "%H:%M:%S"), "] Reporte escrito en: ", SALIDA)
message("  Hallazgos totales: ", nrow(todos_hallazgos))
