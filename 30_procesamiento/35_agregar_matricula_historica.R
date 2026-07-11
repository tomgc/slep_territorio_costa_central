# =============================================================================
# 35_agregar_matricula_historica.R
# Proposito : Etapa 2.2 del mapa interactivo. Para cada RBD del universo
#             continental (salida de 34), calcula la serie anual de matricula
#             2016-2025 y los 4 indicadores de la ventana movil, leyendo el
#             historico por estudiante. GOBERNANZA: el MRUN se usa SOLO en
#             memoria para contar estudiantes distintos y se DESCARTA; ninguna
#             salida contiene identificadores individuales (POLITICA §6).
# Reglas    : matricula RBD-anio = uniqueN(MRUN) (regla robusta aunque el
#             archivo "Matricula unica" traiga una fila por estudiante).
#             RBD-anios SIN registro quedan AUSENTES de la serie (no 0): la
#             distincion es critica para min_10 (solo anios con matricula > 0).
#             matricula_actual/min_10 quedan NA numerico cuando no hay dato;
#             los textos literales (TEXTO_SIN_MATRICULA / ETIQUETA_SIN_DATO)
#             los aplica 36 al exportar (aqui se definen como constantes).
# Insumos   : 40_salidas/mapa_interactivo/directorio_region5.rds (de 34)
#             20_insumos/historico_matricula/Matricula-por-estudiante-YYYY/*.csv
#             (UTF-8 con BOM, sep ;, headers en case variable)
# Salidas   : 40_salidas/mapa_interactivo/matricula_historica_r5.rds
#             (intermedio agregado, sin dato individual, NO trackeado)
# Autor     : equipo SLEP Costa Central — Fecha: 2026-07-10
# =============================================================================

# ---- 1. Bootstrapping ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("data.table"))

# ---- 3. Librerias ----
suppressMessages(library(data.table))

# ---- 4. Rutas centralizadas ----
RUTA_UNIVERSO   <- ruta_salidas("mapa_interactivo", "directorio_region5.rds")
DIR_HISTORICO   <- ruta_insumos("historico_matricula")
RUTA_SALIDA     <- ruta_salidas("mapa_interactivo", "matricula_historica_r5.rds")

# ---- 5. Constantes nombradas ----
N_ANIOS  <- 10L
ANIO_MIN <- 2016L
ANIO_MAX <- 2025L
ANIOS_VENTANA <- seq.int(ANIO_MIN, ANIO_MAX)
stopifnot(length(ANIOS_VENTANA) == N_ANIOS)

# Textos literales que 36 aplica al exportar (definidos aqui por contrato):
TEXTO_SIN_MATRICULA <- "Sin matrícula en 2025."   # EE sin fila 2025 en el historico
ETIQUETA_SIN_DATO   <- "sin dato"                  # min_10 sin ningun anio > 0

# Validacion de totales regionales: un salto interanual mayor a este umbral
# es anomalo para matricula regional (diagnostico: variaciones reales ~1-3%).
UMBRAL_SALTO_ANUAL_PCT <- 8

# ---- 6. Funciones ----

# Resuelve el CSV unico de la carpeta del anio (los nombres varian por anio).
csv_del_anio <- function(anio) {
  d <- file.path(DIR_HISTORICO, sprintf("Matricula-por-estudiante-%d", anio))
  f <- list.files(d, pattern = "(?i)\\.csv$", full.names = TRUE)
  if (length(f) != 1)
    stop("Carpeta ", d, ": se esperaba 1 CSV, hay ", length(f), ".")
  f
}

# Matricula por RBD de un anio: lee SOLO (RBD, MRUN), normaliza case de headers,
# llaves character, filtra al universo y cuenta MRUN distintos. El objeto crudo
# con MRUN vive solo dentro de esta funcion (se libera al salir).
matricula_anio <- function(anio, rbd_universo) {
  f <- csv_del_anio(anio)
  hdr <- names(fread(f, sep = ";", nrows = 0))
  cols <- hdr[match(c("RBD", "MRUN"), toupper(hdr))]
  if (anyNA(cols)) stop("Anio ", anio, ": faltan columnas RBD/MRUN en ", basename(f))
  dt <- fread(f, sep = ";", select = cols, colClasses = "character",
              encoding = "UTF-8", showProgress = FALSE)
  setnames(dt, toupper(names(dt)))
  dt <- dt[RBD %chin% rbd_universo & !is.na(MRUN) & MRUN != ""]
  res <- dt[, .(matricula = uniqueN(MRUN)), by = .(rbd = RBD)]
  res[, anio := anio]
  rm(dt); invisible(gc(FALSE))
  res
}

# ---- 7. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  t0 <- Sys.time()
  if (!file.exists(RUTA_UNIVERSO)) stop("Falta 34. Corre 34_preparar_directorio_region.R.")
  universo <- readRDS(RUTA_UNIVERSO)
  stopifnot(is.character(universo$rbd), !anyDuplicated(universo$rbd))
  rbd_universo <- universo$rbd
  n_flag <- sum(universo$matricula_flag == "1")
  log_msg(sprintf("Universo continental: %d RBD (flag MATRICULA=1 en directorio: %d).",
                  length(rbd_universo), n_flag), origen = "35_matricula")

  # los 10 archivos deben existir antes de leer ninguno
  invisible(vapply(ANIOS_VENTANA, csv_del_anio, character(1)))

  # serie larga RBD x anio (anios sin registro AUSENTES, no 0)
  serie <- rbindlist(lapply(ANIOS_VENTANA, matricula_anio, rbd_universo = rbd_universo))
  stopifnot(!anyDuplicated(serie[, .(rbd, anio)]),
            all(serie$matricula >= 1),             # uniqueN>=1 por construccion
            all(serie$anio %in% ANIOS_VENTANA))

  # totales regionales por anio + validacion de saltos interanuales
  tot <- serie[, .(total = sum(matricula)), by = anio][order(anio)]
  log_msg(paste("Totales regionales:", paste(sprintf("%d=%d", tot$anio, tot$total),
                collapse = " ")), origen = "35_matricula")
  salto_pct <- abs(diff(tot$total)) / head(tot$total, -1) * 100
  if (any(salto_pct > UMBRAL_SALTO_ANUAL_PCT))
    stop("Salto interanual anomalo (> ", UMBRAL_SALTO_ANUAL_PCT, "%): ",
         paste(sprintf("%d->%d: %.1f%%", head(tot$anio, -1)[salto_pct > UMBRAL_SALTO_ANUAL_PCT],
                       tot$anio[-1][salto_pct > UMBRAL_SALTO_ANUAL_PCT],
                       salto_pct[salto_pct > UMBRAL_SALTO_ANUAL_PCT]), collapse = "; "))

  # 4 indicadores por RBD (sobre la serie observada; NA numerico donde no hay dato)
  indicadores <- serie[, .(
    matricula_actual = { m <- matricula[anio == ANIO_MAX]
                         if (length(m) == 1) m else NA_integer_ },
    max_10  = max(matricula),
    prom_10 = mean(matricula),                       # sin redondear (regla: solo en 36)
    min_10  = { v <- matricula[matricula > 0]        # min SOLO sobre anios > 0
                if (length(v) > 0) min(v) else NA_integer_ },
    n_anios_con_dato = .N), by = rbd]

  # todos los RBD del universo presentes (left join; sin serie => todo NA)
  out_ind <- merge(data.table(rbd = rbd_universo), indicadores, by = "rbd", all.x = TRUE)
  out <- list(indicadores = out_ind, serie = serie[order(rbd, anio)],
              anios = ANIOS_VENTANA,
              texto_sin_matricula = TEXTO_SIN_MATRICULA,
              etiqueta_sin_dato   = ETIQUETA_SIN_DATO)

  # ---- Validaciones C.8 ----
  stopifnot(!anyDuplicated(out_ind$rbd),
            nrow(out_ind) == length(rbd_universo))
  con_2025 <- sum(!is.na(out_ind$matricula_actual))
  sin_2025 <- sum(is.na(out_ind$matricula_actual))
  if (con_2025 != n_flag)
    stop("Incoherencia: RBD con matricula 2025 en historico (", con_2025,
         ") != flag MATRICULA=1 del directorio (", n_flag, ").")
  sin_serie <- out_ind[is.na(max_10), rbd]           # sin NINGUN anio en la ventana
  log_msg(sprintf("Con matricula 2025: %d | sin matricula 2025: %d (esperados %d) | sin NINGUN anio en ventana ('%s'): %d RBD: %s",
                  con_2025, sin_2025, length(rbd_universo) - n_flag, ETIQUETA_SIN_DATO,
                  length(sin_serie), paste(sin_serie, collapse = " ")),
          origen = "35_matricula")
  # ningun MRUN sobrevive: la salida solo tiene estas columnas
  stopifnot(identical(sort(names(out_ind)),
                      sort(c("rbd", "matricula_actual", "max_10", "prom_10",
                             "min_10", "n_anios_con_dato"))),
            identical(sort(names(serie)), sort(c("rbd", "anio", "matricula"))))

  # distribucion de los 4 indicadores (solo RBD con serie)
  d <- out_ind[!is.na(max_10)]
  resumen <- function(x) sprintf("min=%.0f mediana=%.0f max=%.0f",
                                 min(x, na.rm = TRUE), median(x, na.rm = TRUE),
                                 max(x, na.rm = TRUE))
  log_msg(sprintf("Indicadores (n=%d con serie): actual[%s] max10[%s] prom10[%s] min10[%s]",
                  nrow(d), resumen(d$matricula_actual), resumen(d$max_10),
                  resumen(d$prom_10), resumen(d$min_10)), origen = "35_matricula")

  # ---- salida atomica ----
  tmp <- paste0(RUTA_SALIDA, ".tmp")
  saveRDS(out, tmp); file.rename(tmp, RUTA_SALIDA)
  log_msg(sprintf("Serie e indicadores escritos en %s (%d RBD, %d filas de serie). Corrida: %.1f s.",
                  RUTA_SALIDA, nrow(out_ind), nrow(serie),
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))),
          origen = "35_matricula")
}
