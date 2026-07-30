# =============================================================================
# Andamio de diagnostico — universo de educacion parvularia, Region de Valparaiso
# Pendiente N (fase 0). SOLO MIDE. No es parte del pipeline, no escribe insumos,
# no persiste ninguna fila de nivel persona.
# Encargo: 50_documentacion/andamios/encargo_claude_code_parvularia_diagnostico_v1.md
# =============================================================================
for (p in c("readr", "dplyr", "here", "data.table")) {
  if (!requireNamespace(p, quietly = TRUE)) stop("falta el paquete: ", p)
}
library(dplyr)

# Interruptor de secciones: el PASO 1 no se re-corre en cada iteracion.
CORRER <- Sys.getenv("DIAG_PASO", "1")

RUTA_PARV <- function(anio) {
  d <- here::here("20_insumos", "historico_matricula",
                  paste0("Matricula-Ed.-Parvularia-", anio))
  f <- list.files(d, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  stopifnot(length(f) == 1L)
  f
}
RUTA_DIRECTORIO <- here::here("20_insumos", "auxiliares",
                              "directorio_oficial_ee_publico.csv")

# ---- PASO 1.2/1.3 — separador, encoding y esquema (solo 200 filas) ----------
# Se leen 200 filas por año: basta para el esquema y evita cargar 150 MB.
sondear <- function(anio) {
  f <- RUTA_PARV(anio)
  l1 <- readLines(f, n = 1L, warn = FALSE)
  sep <- c(";" = lengths(regmatches(l1, gregexpr(";", l1))),
           "," = lengths(regmatches(l1, gregexpr(",", l1))),
           "|" = lengths(regmatches(l1, gregexpr("\\|", l1))))
  sep_real <- names(sep)[which.max(sep)]
  leer <- function(enc) suppressWarnings(readr::read_delim(
    f, delim = sep_real, n_max = 200L, progress = FALSE,
    locale = readr::locale(encoding = enc, decimal_mark = ","),
    show_col_types = FALSE, name_repair = "minimal"))
  d_lat <- try(leer("latin1"), silent = TRUE)
  d_utf <- try(leer("UTF-8"),  silent = TRUE)
  # Criterio de encoding: cuantas celdas de texto traen el caracter de reemplazo
  # U+FFFD o secuencias mojibake tipicas. Menos rotura = encoding correcto.
  rotura <- function(d) {
    if (inherits(d, "try-error")) return(NA_integer_)
    txt <- d |> select(where(is.character)) |> unlist(use.names = FALSE)
    sum(grepl("�|Ã|Â|�", txt), na.rm = TRUE)
  }
  d <- if (!inherits(d_lat, "try-error")) d_lat else d_utf
  list(anio = anio, archivo = basename(f), sep = sep_real,
       sep_conteo = sep, n_col = ncol(d),
       rotura_latin1 = rotura(d_lat), rotura_utf8 = rotura(d_utf),
       columnas = names(d),
       tipos = vapply(d, function(x) class(x)[1], character(1)))
}

if (CORRER == "1") {
cat("=== PASO 1 — esquema por año (200 filas) ===\n")
sondeos <- lapply(c(2011, 2018, 2025), sondear)
names(sondeos) <- c("2011", "2018", "2025")

for (s in sondeos) {
  cat("\n--- ", s$anio, " · ", s$archivo, "\n", sep = "")
  cat("separador: '", s$sep, "'  (conteo en la cabecera: ",
      paste(names(s$sep_conteo), s$sep_conteo, sep = "=", collapse = " "), ")\n", sep = "")
  cat("columnas: ", s$n_col, "\n", sep = "")
  cat("celdas de texto rotas — latin1: ", s$rotura_latin1,
      " | UTF-8: ", s$rotura_utf8, "\n", sep = "")
}

cat("\n=== Esquema 2025 (nombre : tipo) ===\n")
print(data.frame(columna = sondeos[["2025"]]$columnas,
                 tipo = unname(sondeos[["2025"]]$tipos)), right = FALSE)

# ---- Encoding a nivel de BYTES (definitivo, no heuristico) ------------------
# El sondeo por "celdas rotas" no decide cuando el tramo leido no trae tildes.
# Esto mira los bytes: si hay bytes altos (>=0x80) y la secuencia es UTF-8
# valida, el archivo es UTF-8; si hay bytes altos y NO es UTF-8 valido, es
# latin1. Sin bytes altos, el tramo es ASCII puro y ambos encodings coinciden.
sondear_bytes <- function(anio, n_bytes = 20e6) {
  f <- RUTA_PARV(anio)
  crudo <- readBin(f, "raw", n = n_bytes)
  altos <- sum(crudo >= as.raw(128))
  txt <- rawToChar(crudo)
  Encoding(txt) <- "UTF-8"
  list(anio = anio, bytes_leidos = length(crudo), bytes_altos = altos,
       utf8_valido = !is.na(validUTF8(txt)) && validUTF8(txt))
}
cat("\n=== Encoding por bytes (primeros 20 MB de cada archivo) ===\n")
for (a in c(2011, 2018, 2025)) {
  b <- sondear_bytes(a)
  cat(b$anio, ": bytes >=0x80: ", b$bytes_altos,
      " | secuencia UTF-8 valida: ", b$utf8_valido,
      " => ", if (b$bytes_altos == 0) "ASCII puro (indistinguible)"
              else if (b$utf8_valido) "UTF-8" else "latin1", "\n", sep = "")
}

# ---- Delta de esquema, normalizando MAYUSCULAS ------------------------------
# 2011 trae los nombres en minuscula y 2018/2025 en mayuscula. Comparar sin
# normalizar reporta "49 columnas nuevas" que es un artefacto de la caja, no un
# cambio de esquema. Se compara en mayuscula y se declara el cambio de caja.
cat("\n=== Delta de esquema (nombres normalizados a MAYUSCULA) ===\n")
c11 <- toupper(sondeos[["2011"]]$columnas)
c18 <- toupper(sondeos[["2018"]]$columnas)
c25 <- toupper(sondeos[["2025"]]$columnas)
cat("caja original — 2011: ", sondeos[["2011"]]$columnas[1], " | 2018: ",
    sondeos[["2018"]]$columnas[1], " | 2025: ", sondeos[["2025"]]$columnas[1], "\n", sep = "")
cat("en 2025 y NO en 2011 (", length(setdiff(c25, c11)), "): ",
    paste(setdiff(c25, c11), collapse = ", "), "\n", sep = "")
cat("en 2011 y NO en 2025 (", length(setdiff(c11, c25)), "): ",
    paste(setdiff(c11, c25), collapse = ", "), "\n", sep = "")
cat("en 2025 y NO en 2018 (", length(setdiff(c25, c18)), "): ",
    paste(setdiff(c25, c18), collapse = ", "), "\n", sep = "")
cat("en 2018 y NO en 2025 (", length(setdiff(c18, c25)), "): ",
    paste(setdiff(c18, c25), collapse = ", "), "\n", sep = "")

# ---- GATE del PASO 1 --------------------------------------------------------
cat("\n=== GATE PASO 1 — familias de columnas exigidas en 2025 ===\n")
fam <- list(
  `id de establecimiento` = grep("^(ID_ESTAB|RBD)", c25, value = TRUE),
  `nombre de establecimiento` = grep("NOM_ESTAB", c25, value = TRUE),
  `codigo de comuna` = grep("COD_COM", c25, value = TRUE),
  `dependencia/administrador` = grep("DEPEND|DEPE1|SOSTENEDOR|ORIGEN", c25, value = TRUE))
for (n in names(fam)) cat(n, ": ", if (length(fam[[n]])) paste(fam[[n]], collapse = ", ")
                          else "AUSENTE", "\n", sep = "")
cat("GATE: ", if (all(lengths(fam) > 0)) "PASA" else "FALLA", "\n", sep = "")

# ---- Corte temporal declarado del archivo 2025 ------------------------------
cat("\n=== Corte del archivo 2025 (AGNO/MES sobre 200 filas) ===\n")
d25 <- suppressWarnings(readr::read_delim(
  RUTA_PARV(2025), delim = ";", n_max = 200L, progress = FALSE,
  locale = readr::locale(encoding = "UTF-8", decimal_mark = ","),
  show_col_types = FALSE, name_repair = "minimal"))
print(d25 |> count(AGNO, MES))
}

# =============================================================================
# COMPUERTA DE GOBERNANZA + PASO 2 — universo regional 2025   (DIAG_PASO=2)
# El archivo es de nivel PERSONA. Antes de usar LATITUD/LONGITUD hay que
# demostrar que son del ESTABLECIMIENTO y no del domicilio del niño.
# =============================================================================
COLS_R5 <- c("COD_REG_ESTAB", "COD_COM_ESTAB", "NOM_COM_ESTAB", "ID_ESTAB", "RBD",
             "ID_ESTAB_J", "ID_ESTAB_I", "LATITUD", "LONGITUD", "ORIGEN",
             "DEPENDENCIA", "COD_DEPE1_M", "TIPO_SOSTENEDOR", "TIPO_ESTAB", "FORMAL")
# Llaves SIEMPRE character (convencion del proyecto: RBD/RUT/codigos nunca numeric).
CLASES <- list(character = c("ID_ESTAB", "RBD", "ID_ESTAB_J", "ID_ESTAB_I",
                             "COD_DEPE1_M", "TIPO_SOSTENEDOR"))

leer_r5 <- function(anio, cols = COLS_R5) {
  f <- RUTA_PARV(anio)
  disponibles <- names(data.table::fread(f, sep = ";", nrows = 0L, encoding = "UTF-8"))
  # 2011/2018 traen otra caja y otro juego de columnas: se pide la interseccion.
  mapa <- setNames(disponibles, toupper(disponibles))
  pedir <- unname(mapa[intersect(toupper(cols), names(mapa))])
  cl <- lapply(CLASES, function(v) unname(mapa[intersect(toupper(v), names(mapa))]))
  # LATITUD/LONGITUD se leen SIEMPRE como texto y se normalizan aparte: las dos
  # fuentes del proyecto usan separador decimal distinto (matricula punto,
  # directorio coma) y forzar `dec=` en fread rompe una de las dos en silencio,
  # devolviendola como character sin avisar.
  cl$character <- unique(c(cl$character, intersect(c("LATITUD", "LONGITUD"), pedir)))
  d <- data.table::fread(f, sep = ";", encoding = "UTF-8",
                         select = pedir, colClasses = cl, showProgress = FALSE)
  data.table::setnames(d, toupper(names(d)))
  d <- tibble::as_tibble(d) |> filter(COD_REG_ESTAB == 5)
  d
}

if (CORRER == "2") {
r5 <- leer_r5(2025)
cat("=== Filas de R5 en 2025 (nivel persona, solo en memoria) ===\n")
cat("filas: ", nrow(r5), "\n", sep = "")

# ---- COMPUERTA: pares (LAT,LON) distintos por llave -------------------------
cat("\n=== COMPUERTA — pares (LATITUD,LONGITUD) distintos por ID_ESTAB ===\n")
nulas <- r5 |> filter(is.na(LATITUD) | is.na(LONGITUD))
cat("filas con coordenada nula: ", nrow(nulas),
    " (", sprintf("%.2f%%", 100 * nrow(nulas) / nrow(r5)), " de las filas de R5)\n", sep = "")

pares <- r5 |>
  filter(!is.na(LATITUD), !is.na(LONGITUD)) |>
  distinct(ID_ESTAB, LATITUD, LONGITUD) |>
  count(ID_ESTAB, name = "n_pares")

cat("llaves ID_ESTAB con al menos un par no nulo: ", nrow(pares), "\n", sep = "")
cat("\ndistribucion de pares distintos por llave:\n")
print(pares |> count(n_pares, name = "n_llaves") |> arrange(n_pares), n = 30)
cat("\nmaximo de pares distintos en una sola llave: ", max(pares$n_pares), "\n", sep = "")
cat("llaves con exactamente 1 par: ", sum(pares$n_pares == 1),
    " (", sprintf("%.2f%%", 100 * mean(pares$n_pares == 1)), ")\n", sep = "")
cat("llaves con 2 o mas pares:    ", sum(pares$n_pares >= 2),
    " (", sprintf("%.2f%%", 100 * mean(pares$n_pares >= 2)), ")\n", sep = "")
cat("\nVEREDICTO COMPUERTA: ",
    if (mean(pares$n_pares == 1) >= 0.95) "coordenada de ESTABLECIMIENTO — se puede seguir"
    else "REVISAR — fraccion no trivial con varios pares por llave", "\n", sep = "")

# ---- PASO 2.1/2.2 — unidades y niños ---------------------------------------
cat("\n=== PASO 2 — universo regional 2025 ===\n")
insulares <- c(5104, 5201)   # Juan Fernandez, Isla de Pascua
cat("filas (niños) en R5: ", nrow(r5), "\n", sep = "")
cat("  de ellas insulares (5104, 5201): ", sum(r5$COD_COM_ESTAB %in% insulares), "\n", sep = "")
cat("unidades distintas por ID_ESTAB: ", n_distinct(r5$ID_ESTAB), "\n", sep = "")
cat("  continentales: ", n_distinct(r5$ID_ESTAB[!r5$COD_COM_ESTAB %in% insulares]),
    " | insulares: ", n_distinct(r5$ID_ESTAB[r5$COD_COM_ESTAB %in% insulares]), "\n", sep = "")

# ---- PASO 2 (precision del titular): cobertura de cada llave x ORIGEN -------
vacia <- function(x) is.na(x) | trimws(x) == "" | x %in% c("0", "NA")
cat("\n=== Cobertura de cada llave candidata, cruzada con ORIGEN ===\n")
cat("(filas de R5; 'poblada' = no nula, no vacia, distinta de '0')\n\n")
for (k in c("ID_ESTAB", "RBD", "ID_ESTAB_J", "ID_ESTAB_I")) {
  cat("--- ", k, "\n", sep = "")
  print(r5 |>
    mutate(poblada = !vacia(.data[[k]])) |>
    count(ORIGEN, poblada) |>
    tidyr::pivot_wider(names_from = poblada, values_from = n, values_fill = 0,
                       names_prefix = "poblada_"))
  cat("\n")
}

cat("=== Tabla cruda de ORIGEN (unidades y niños) ===\n")
print(r5 |> summarise(ninos = n(), unidades = n_distinct(ID_ESTAB), .by = ORIGEN) |>
        arrange(desc(ninos)))
}


# Normalizador unico de coordenada: acepta coma o punto decimal y devuelve
# numeric. Es la respuesta al hallazgo de que las dos fuentes difieren.
num_coord <- function(x) {
  if (is.numeric(x)) return(x)
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", ".", x, fixed = TRUE)))
}

# =============================================================================
# PASO 2 (resto) + PASO 3 — georreferenciacion, dos fuentes   (DIAG_PASO=3)
# =============================================================================
if (CORRER == "3") {
r5 <- leer_r5(2025) |> mutate(LATITUD = num_coord(LATITUD), LONGITUD = num_coord(LONGITUD))
insulares <- c(5104, 5201)

# ---- PASO 2.3 — categorias CRUDAS de cada campo de administrador -----------
cat("=== PASO 2.3 — campos candidatos a administrador, valores crudos ===\n")
for (k in c("ORIGEN", "DEPENDENCIA", "COD_DEPE1_M", "TIPO_ESTAB", "TIPO_SOSTENEDOR", "FORMAL")) {
  cat("\n--- ", k, " (niños y unidades)\n", sep = "")
  print(r5 |> summarise(ninos = n(), unidades = n_distinct(ID_ESTAB), .by = all_of(k)) |>
          arrange(desc(ninos)), n = 30)
}
cat("\n--- ORIGEN x DEPENDENCIA (unidades) — donde deberia aparecer VTF\n")
print(r5 |> summarise(unidades = n_distinct(ID_ESTAB), ninos = n(),
                      .by = c(ORIGEN, DEPENDENCIA)) |> arrange(ORIGEN, DEPENDENCIA), n = 40)

# ---- PASO 2.5 — unidades por comuna ----------------------------------------
cat("\n=== PASO 2.5 — unidades y niños por comuna ===\n")
AREA_MONITOREO <- c(5105, 5107, 5103, 5109)
print(r5 |>
  summarise(unidades = n_distinct(ID_ESTAB), ninos = n(), .by = c(COD_COM_ESTAB, NOM_COM_ESTAB)) |>
  mutate(marca = case_when(COD_COM_ESTAB %in% AREA_MONITOREO ~ "<< area de monitoreo",
                           COD_COM_ESTAB %in% insulares ~ "<< insular", TRUE ~ "")) |>
  arrange(desc(unidades)), n = 40)

# ---- Tabla por unidad: aqui muere el nivel persona --------------------------
uni <- r5 |>
  summarise(ninos = n(), RBD = first(RBD), ORIGEN = first(ORIGEN),
            COD_COM_ESTAB = first(COD_COM_ESTAB),
            LATITUD = first(LATITUD), LONGITUD = first(LONGITUD), .by = ID_ESTAB) |>
  mutate(insular = COD_COM_ESTAB %in% insulares)
cat("\nunidades agregadas: ", nrow(uni), " | niños: ", sum(uni$ninos),
    " | insulares: ", sum(uni$insular), "\n", sep = "")

# ---- PASO 3a — coordenadas del propio archivo de matricula -----------------
if (!requireNamespace("sf", quietly = TRUE)) stop("falta sf")
bb <- sf::st_bbox(sf::st_read(here::here("docs", "data", "frontera_region.geojson"), quiet = TRUE))
cat("\n=== PASO 3a — bbox continental de R5 (docs/data/frontera_region.geojson) ===\n"); print(bb)
dentro_bb <- function(lat, lon) !is.na(lat) & !is.na(lon) &
  lon >= bb[["xmin"]] & lon <= bb[["xmax"]] & lat >= bb[["ymin"]] & lat <= bb[["ymax"]]

uni <- uni |> mutate(coord_presente = !is.na(LATITUD) & !is.na(LONGITUD),
                     coord_mat_ok = dentro_bb(LATITUD, LONGITUD))
cat("\ncoordenada presente en matricula: ", sum(uni$coord_presente), "/", nrow(uni), "\n", sep = "")
cat("presente pero FUERA del bbox continental: ", sum(uni$coord_presente & !uni$coord_mat_ok),
    " (de ellas insulares: ", sum(uni$coord_presente & !uni$coord_mat_ok & uni$insular),
    " | continentales fuera de rango: ",
    sum(uni$coord_presente & !uni$coord_mat_ok & !uni$insular), ")\n", sep = "")
cat("\ncobertura de coordenada valida por ORIGEN (unidades continentales):\n")
print(uni |> filter(!insular) |>
  summarise(unidades = n(), con_coord = sum(coord_mat_ok),
            pct_unidades = round(100 * mean(coord_mat_ok), 2),
            ninos_con_coord = sum(ninos[coord_mat_ok]), ninos = sum(ninos),
            pct_ninos = round(100 * ninos_con_coord / ninos, 2),
            .by = ORIGEN) |> arrange(ORIGEN))

# ---- PASO 3b — cruce contra el directorio oficial, por RBD (character) -----
dir <- data.table::fread(RUTA_DIRECTORIO, sep = ";", encoding = "UTF-8",
                         select = c("RBD", "COD_REG_RBD", "LATITUD", "LONGITUD"),
                         colClasses = "character", showProgress = FALSE) |>
  tibble::as_tibble() |>
  mutate(LAT_DIR = num_coord(LATITUD), LON_DIR = num_coord(LONGITUD)) |>
  select(RBD, LAT_DIR, LON_DIR) |>
  distinct(RBD, .keep_all = TRUE)
cat("\n=== PASO 3b — cruce contra el directorio por RBD ===\n")
cat("RBD unicos en el directorio: ", nrow(dir), " | clase RBD: ",
    class(uni$RBD), " (matricula) / ", class(dir$RBD), " (directorio)\n", sep = "")
vacia <- function(x) is.na(x) | trimws(x) == "" | x %in% c("0", "NA")
uni <- uni |>
  mutate(tiene_rbd = !vacia(RBD)) |>
  left_join(dir, by = "RBD") |>
  mutate(match_dir = tiene_rbd & !is.na(LAT_DIR),
         coord_dir_ok = dentro_bb(LAT_DIR, LON_DIR))
print(uni |> summarise(unidades = n(), con_rbd = sum(tiene_rbd), matchean = sum(match_dir),
                       con_coord_dir_valida = sum(coord_dir_ok), ninos = sum(ninos),
                       .by = ORIGEN) |> arrange(ORIGEN))

# ---- PASO 3c — distancia entre las dos fuentes -----------------------------
ambas <- uni |> filter(coord_mat_ok, coord_dir_ok)
cat("\n=== PASO 3c — distancia entre las dos fuentes ===\n")
cat("unidades con coordenada valida en AMBAS: ", nrow(ambas), "\n", sep = "")
if (nrow(ambas) > 0) {
  d_m <- as.numeric(sf::st_distance(
    sf::st_as_sf(ambas, coords = c("LONGITUD", "LATITUD"), crs = 4326),
    sf::st_as_sf(ambas, coords = c("LON_DIR", "LAT_DIR"), crs = 4326), by_element = TRUE))
  cat("metros — mediana: ", round(median(d_m), 1), " | p95: ", round(quantile(d_m, .95), 1),
      " | maximo: ", round(max(d_m), 1), "\n", sep = "")
  cat("identicas (<1 m): ", sum(d_m < 1), " (", sprintf("%.1f%%", 100 * mean(d_m < 1)),
      ") | >100 m: ", sum(d_m > 100), " | >1 km: ", sum(d_m > 1000), "\n", sep = "")
}

# ---- PASO 3d — conclusion ---------------------------------------------------
uni <- uni |> mutate(geo_ok = coord_mat_ok | coord_dir_ok)
cont <- uni |> filter(!insular)
cat("\n=== PASO 3d — georreferenciable HOY, sin fuentes nuevas (continental) ===\n")
cat("unidades: ", sum(cont$geo_ok), "/", nrow(cont), " (",
    sprintf("%.2f%%", 100 * mean(cont$geo_ok)), ") | niños: ",
    sum(cont$ninos[cont$geo_ok]), "/", sum(cont$ninos), " (",
    sprintf("%.2f%%", 100 * sum(cont$ninos[cont$geo_ok]) / sum(cont$ninos)), ")\n", sep = "")
print(cont |> summarise(unidades = n(), geo = sum(geo_ok), pct_uni = round(100 * mean(geo_ok), 2),
                        ninos_geo = sum(ninos[geo_ok]), ninos = sum(ninos),
                        pct_ninos = round(100 * ninos_geo / ninos, 2),
                        .by = ORIGEN) |> arrange(ORIGEN))
cat("\nsin georreferencia por ninguna via (continental): ", sum(!cont$geo_ok),
    " unidades | ", sum(cont$ninos[!cont$geo_ok]), " niños\n", sep = "")
cat("aporte EXCLUSIVO del directorio (sin coord en matricula, si en directorio): ",
    sum(!cont$coord_mat_ok & cont$coord_dir_ok), " unidades\n", sep = "")
}

# =============================================================================
# PASO 2.4 (VTF) + PASO 4 — serie historica                   (DIAG_PASO=4)
# Glosa de TIPO_ESTAB tomada del ER oficial que acompaña al archivo 2025
# (20_insumos/.../ER_Educacion_parvularia_Oficial_WEB.pdf, pag. 3):
#   1 Escuela Municipal · 2 Part. Subvencionado · 3 Part. Pagado ·
#   4 Escuela SLEP · 5 JUNJI Adm. Directa · 6 JUNJI VTF ·
#   7 INTEGRA Adm. Directa · 8 INTEGRA CAD
# =============================================================================
ETIQ_TIPO_ESTAB <- c("1" = "Escuela Municipal", "2" = "Escuela Part. Subvencionado",
                     "3" = "Escuela Part. Pagado", "4" = "Escuela SLEP",
                     "5" = "JUNJI Administracion Directa", "6" = "JUNJI VTF",
                     "7" = "INTEGRA Administracion Directa", "8" = "INTEGRA CAD")

if (CORRER == "4") {
r5 <- leer_r5(2025) |> mutate(LATITUD = num_coord(LATITUD), LONGITUD = num_coord(LONGITUD))
insulares <- c(5104, 5201)
bb <- sf::st_bbox(sf::st_read(here::here("docs", "data", "frontera_region.geojson"), quiet = TRUE))
dentro_bb <- function(lat, lon) !is.na(lat) & !is.na(lon) &
  lon >= bb[["xmin"]] & lon <= bb[["xmax"]] & lat >= bb[["ymin"]] & lat <= bb[["ymax"]]

cat("=== PASO 2.4 — ORIGEN x TIPO_ESTAB: donde vive VTF ===\n")
print(r5 |>
  summarise(unidades = n_distinct(ID_ESTAB), ninos = n(), .by = c(ORIGEN, TIPO_ESTAB)) |>
  mutate(glosa = ETIQ_TIPO_ESTAB[as.character(TIPO_ESTAB)]) |>
  arrange(ORIGEN, TIPO_ESTAB), n = 20)

uni <- r5 |>
  summarise(ninos = n(), ORIGEN = first(ORIGEN), TIPO_ESTAB = first(TIPO_ESTAB),
            COD_COM_ESTAB = first(COD_COM_ESTAB), LATITUD = first(LATITUD),
            LONGITUD = first(LONGITUD), .by = ID_ESTAB) |>
  mutate(insular = COD_COM_ESTAB %in% insulares, geo_ok = dentro_bb(LATITUD, LONGITUD))
cat("\n=== Georreferenciacion por TIPO_ESTAB (continental) ===\n")
print(uni |> filter(!insular) |>
  summarise(unidades = n(), geo = sum(geo_ok), pct_uni = round(100 * mean(geo_ok), 2),
            ninos_geo = sum(ninos[geo_ok]), ninos = sum(ninos),
            pct_ninos = round(100 * ninos_geo / ninos, 2), .by = TIPO_ESTAB) |>
  mutate(glosa = ETIQ_TIPO_ESTAB[as.character(TIPO_ESTAB)]) |> arrange(TIPO_ESTAB), n = 20)

# ---- PASO 4 — serie historica: 2011, 2018, 2025 -----------------------------
cat("\n=== PASO 4 — unidades y niños de R5 en tres cortes ===\n")
llaves <- list()
for (a in c(2011, 2018, 2025)) {
  d <- leer_r5(a, cols = c("COD_REG_ESTAB", "COD_COM_ESTAB", "ID_ESTAB", "ORIGEN"))
  llaves[[as.character(a)]] <- unique(d$ID_ESTAB)
  cat(a, ": filas(niños) ", nrow(d), " | unidades ", n_distinct(d$ID_ESTAB),
      " | ID_ESTAB nchar ", paste(range(nchar(d$ID_ESTAB)), collapse = "-"),
      " | clase ", class(d$ID_ESTAB), "\n", sep = "")
  cat("   ORIGEN presentes: ", paste(sort(unique(d$ORIGEN)), collapse = ", "), "\n", sep = "")
  rm(d); gc(verbose = FALSE)
}
k11 <- llaves[["2011"]]; k18 <- llaves[["2018"]]; k25 <- llaves[["2025"]]
cat("\n--- estabilidad de la llave ID_ESTAB\n")
cat("llaves 2011 presentes en 2025: ", length(intersect(k11, k25)), "/", length(k11),
    " (", sprintf("%.1f%%", 100 * length(intersect(k11, k25)) / length(k11)), ")\n", sep = "")
cat("llaves 2018 presentes en 2025: ", length(intersect(k18, k25)), "/", length(k18),
    " (", sprintf("%.1f%%", 100 * length(intersect(k18, k25)) / length(k18)), ")\n", sep = "")
cat("llaves 2025 presentes en 2011: ", length(intersect(k25, k11)), "/", length(k25),
    " (", sprintf("%.1f%%", 100 * length(intersect(k25, k11)) / length(k25)), ")\n", sep = "")
}

# =============================================================================
# PASO 0 de la fase 1 — mediciones previas a la capa          (DIAG_PASO=5)
# =============================================================================
if (CORRER == "5") {
r5 <- leer_r5(2025, cols = c("COD_REG_ESTAB", "COD_COM_ESTAB", "NOM_COM_ESTAB",
                             "ID_ESTAB", "RBD", "ORIGEN", "TIPO_ESTAB",
                             "LATITUD", "LONGITUD", "NIVEL1", "NIVEL2",
                             "COD_ENSE2_M", "COD_PROG_J", "COD_MODAL_I")) |>
  mutate(LATITUD = num_coord(LATITUD), LONGITUD = num_coord(LONGITUD))
insulares <- c(5104, 5201)

# ---- PASO 0.1 — ¿ID_ESTAB == RBD en ORIGEN 1? ------------------------------
cat("=== PASO 0.1 — ID_ESTAB vs RBD en ORIGEN 1 (comparacion de VALORES) ===\n")
o1 <- r5 |> filter(ORIGEN == 1) |> distinct(ID_ESTAB, RBD)
cat("unidades ORIGEN 1: ", nrow(o1), "\n", sep = "")
cat("con ID_ESTAB == RBD (character, exacto): ", sum(o1$ID_ESTAB == o1$RBD), "\n", sep = "")
cat("que difieren: ", sum(o1$ID_ESTAB != o1$RBD), "\n", sep = "")
dif <- o1 |> filter(ID_ESTAB != RBD)
if (nrow(dif) > 0) {
  cat("\npatron de los discrepantes (largo y prefijo, SIN reproducir el valor):\n")
  print(dif |> mutate(nchar_id = nchar(ID_ESTAB), nchar_rbd = nchar(RBD),
                      pref_id = substr(ID_ESTAB, 1, 1), pref_rbd = substr(RBD, 1, 1)) |>
          count(nchar_id, nchar_rbd, pref_id, pref_rbd, name = "n_unidades"), n = 20)
}

# ---- PASO 0.2 — las 4 unidades continentales fuera del bbox ----------------
bb <- sf::st_bbox(sf::st_read(here::here("docs", "data", "frontera_region.geojson"), quiet = TRUE))
dentro_bb <- function(lat, lon) !is.na(lat) & !is.na(lon) &
  lon >= bb[["xmin"]] & lon <= bb[["xmax"]] & lat >= bb[["ymin"]] & lat <= bb[["ymax"]]
uni <- r5 |>
  summarise(ninos = n(), ORIGEN = first(ORIGEN), TIPO_ESTAB = first(TIPO_ESTAB),
            COD_COM_ESTAB = first(COD_COM_ESTAB), NOM_COM_ESTAB = first(NOM_COM_ESTAB),
            LATITUD = first(LATITUD), LONGITUD = first(LONGITUD), .by = ID_ESTAB) |>
  mutate(insular = COD_COM_ESTAB %in% insulares)
fuera <- uni |> filter(!insular, !is.na(LATITUD), !dentro_bb(LATITUD, LONGITUD))
cat("\n=== PASO 0.2 — unidades continentales con coordenada fuera del bbox ===\n")
cat("cantidad: ", nrow(fuera), "\n", sep = "")
print(fuera |> select(COD_COM_ESTAB, NOM_COM_ESTAB, ORIGEN, TIPO_ESTAB,
                      LATITUD, LONGITUD, ninos))
cat("\ncoordenadas repetidas entre ellas (centinela?): ",
    nrow(fuera) - n_distinct(paste(fuera$LATITUD, fuera$LONGITUD)), " duplicados\n", sep = "")
cat("ceros exactos: ", sum(fuera$LATITUD == 0 | fuera$LONGITUD == 0), "\n", sep = "")
cat("sin coordenada del todo (NA): ", sum(is.na(uni$LATITUD) & !uni$insular), "\n", sep = "")

# ---- Verificacion de los codigos del area de monitoreo ---------------------
cat("\n=== Codigos de comuna del area de monitoreo, CONTRA EL DATO ===\n")
cat("(el encargo §4.1 propone 5101, 5107, 5109, 5801 y pide verificarlos)\n")
print(r5 |> distinct(COD_COM_ESTAB, NOM_COM_ESTAB) |>
        filter(COD_COM_ESTAB %in% c(5101, 5103, 5105, 5107, 5109, 5801)) |>
        arrange(COD_COM_ESTAB))

# ---- Columna que codifica el NIVEL, por origen -----------------------------
cat("\n=== Columna de nivel: valores crudos por ORIGEN ===\n")
for (k in c("NIVEL1", "NIVEL2", "COD_ENSE2_M", "COD_PROG_J", "COD_MODAL_I")) {
  if (!k %in% names(r5)) { cat("\n--- ", k, ": AUSENTE del archivo 2025\n", sep = ""); next }
  cat("\n--- ", k, " x ORIGEN (filas)\n", sep = "")
  print(r5 |> count(ORIGEN, .data[[k]]) |>
          tidyr::pivot_wider(names_from = ORIGEN, values_from = n,
                             values_fill = 0, names_prefix = "origen_") |>
          arrange(.data[[k]]), n = 25)
}
cat("\nNA en NIVEL2 por origen:\n")
print(r5 |> summarise(filas = n(), na_nivel2 = sum(is.na(NIVEL2)),
                      pct_na = round(100 * mean(is.na(NIVEL2)), 3), .by = ORIGEN) |> arrange(ORIGEN))
}

# =============================================================================
# PASO 0.2 (cierre) — donde caen realmente las 4 fuera del bbox  (DIAG_PASO=6)
# Point-in-polygon contra la cobertura comunal NACIONAL de BCN (346 comunas):
# distingue "otra region de Chile" de "en el mar" sin suponer nada.
# =============================================================================
if (CORRER == "6") {
r5 <- leer_r5(2025, cols = c("COD_REG_ESTAB", "COD_COM_ESTAB", "NOM_COM_ESTAB",
                             "ID_ESTAB", "ORIGEN", "TIPO_ESTAB", "LATITUD", "LONGITUD")) |>
  mutate(LATITUD = num_coord(LATITUD), LONGITUD = num_coord(LONGITUD))
insulares <- c(5104, 5201)
bb <- sf::st_bbox(sf::st_read(here::here("docs", "data", "frontera_region.geojson"), quiet = TRUE))
dentro_bb <- function(lat, lon) !is.na(lat) & !is.na(lon) &
  lon >= bb[["xmin"]] & lon <= bb[["xmax"]] & lat >= bb[["ymin"]] & lat <= bb[["ymax"]]

fuera <- r5 |>
  summarise(ninos = n(), ORIGEN = first(ORIGEN), TIPO_ESTAB = first(TIPO_ESTAB),
            COD_COM_ESTAB = first(COD_COM_ESTAB), NOM_COM_ESTAB = first(NOM_COM_ESTAB),
            LATITUD = first(LATITUD), LONGITUD = first(LONGITUD), .by = ID_ESTAB) |>
  filter(!COD_COM_ESTAB %in% insulares, !is.na(LATITUD), !dentro_bb(LATITUD, LONGITUD))

# El shapefile de BCN tiene anillos con vertices duplicados que s2 rechaza; para un
# point-in-polygon esto se resuelve en el plano, sin alterar el insumo en disco.
sf::sf_use_s2(FALSE)
nac <- sf::st_read(here::here("20_insumos", "comunas_bcn", "comunas.shp"), quiet = TRUE) |>
  sf::st_transform(4326) |>
  sf::st_make_valid()
pts <- sf::st_as_sf(fuera, coords = c("LONGITUD", "LATITUD"), crs = 4326)
idx <- sf::st_within(pts, nac) |> as.list() |> vapply(function(i) if (length(i)) i[1] else NA_integer_, 1L)

cat("=== PASO 0.2 — las ", nrow(fuera), " unidades continentales fuera del bbox ===\n", sep = "")
res <- fuera |>
  mutate(lat = round(LATITUD, 5), lon = round(LONGITUD, 5),
         cae_en_comuna = ifelse(is.na(idx), "(ninguna: MAR o fuera de Chile)", nac$Comuna[idx]),
         cae_en_region = ifelse(is.na(idx), "-", nac$Region[idx])) |>
  select(comuna_declarada = NOM_COM_ESTAB, cod_declarado = COD_COM_ESTAB,
         ORIGEN, TIPO_ESTAB, ninos, lat, lon, cae_en_comuna, cae_en_region)
print(as.data.frame(res), right = FALSE)
cat("\ncentinelas: ceros exactos ", sum(fuera$LATITUD == 0 | fuera$LONGITUD == 0),
    " | coordenadas repetidas entre ellas ",
    nrow(fuera) - n_distinct(paste(fuera$LATITUD, fuera$LONGITUD)),
    " | en el mar (sin comuna) ", sum(is.na(idx)), "\n", sep = "")
}

# ---- IDs de las unidades continentales sin coordenada valida (DIAG_PASO=7) --
if (CORRER == "7") {
r5 <- leer_r5(2025, cols = c("COD_REG_ESTAB", "COD_COM_ESTAB", "ID_ESTAB",
                             "ORIGEN", "TIPO_ESTAB", "LATITUD", "LONGITUD")) |>
  mutate(LATITUD = num_coord(LATITUD), LONGITUD = num_coord(LONGITUD))
bb <- sf::st_bbox(sf::st_read(here::here("docs", "data", "frontera_region.geojson"), quiet = TRUE))
dentro <- function(lat, lon) !is.na(lat) & !is.na(lon) &
  lon >= bb[["xmin"]] & lon <= bb[["xmax"]] & lat >= bb[["ymin"]] & lat <= bb[["ymax"]]
sin_geo <- r5 |>
  summarise(ninos = n(), ORIGEN = first(ORIGEN), TIPO_ESTAB = first(TIPO_ESTAB),
            LATITUD = first(LATITUD), LONGITUD = first(LONGITUD),
            COD_COM_ESTAB = first(COD_COM_ESTAB), .by = ID_ESTAB) |>
  filter(!COD_COM_ESTAB %in% c(5104, 5201), !dentro(LATITUD, LONGITUD)) |>
  mutate(causa = ifelse(is.na(LATITUD), "coordenada ausente", "coordenada fuera de la region"))
cat("unidades continentales sin coordenada valida: ", nrow(sin_geo),
    " | niños: ", sum(sin_geo$ninos), "\n", sep = "")
print(sin_geo |> select(ID_ESTAB, ORIGEN, TIPO_ESTAB, ninos, causa) |> arrange(ID_ESTAB))
cat("\nvector para el script 39:\n")
cat('c("', paste(sort(sin_geo$ID_ESTAB), collapse = '", "'), '")\n', sep = "")
}
