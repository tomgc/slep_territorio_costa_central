# =============================================================================
# 36_construir_geojson_web.R
# Proposito : Etapa 2.3 del mapa interactivo. Une universo (34) + serie e
#             indicadores (35) y construye los artefactos web AGREGADOS:
#             - establecimientos.geojson : FeatureCollection con los 1.251 pins
#               (decision: GeoJSON y no JSON plano, por integracion directa con
#               Leaflet (L.geoJSON); el peso medido queda < 1 MB, ver log).
#             - sin_geo.json : bloque separado con los EE sin coordenadas (para
#               el XLSX; NO van al mapa, no se inventan coordenadas).
#             - metadatos.json : ventana, criterios, universo, glosas y claves.
#             Reglas de presentacion aplicadas AQUI (contrato con 35):
#             - matricula_actual ausente -> TEXTO_SIN_MATRICULA (literal).
#             - min_10 sin anios > 0    -> ETIQUETA_SIN_DATO (nunca 0).
#             - prom_10 se redondea a entero SOLO aqui.
#             Filtro Nivel dependiente: pares (COD_ENSE, COD_GRADO) OBSERVADOS
#             en el crudo 2025 (sin MRUN), decodificados con el Anexo V (a
#             partir de 2019) del esquema oficial; macrogrupo via planilla
#             canonica. Par observado sin glosa => DETIENE (no se inventa).
# Insumos   : 40_salidas/mapa_interactivo/directorio_region5.rds (34)
#             40_salidas/mapa_interactivo/matricula_historica_r5.rds (35)
#             20_insumos/auxiliares/codigo_tipo_y_macrogrupo.xlsx (canonica)
#             20_insumos/historico_matricula/Matricula-por-estudiante-2025/*.csv
#             (solo columnas RBD/COD_ENSE/COD_GRADO; el MRUN no se lee)
# Salidas   : 40_salidas/mapa_interactivo/web/data/{establecimientos.geojson,
#             sin_geo.json, metadatos.json} (agregados, SIN dato individual;
#             estos SI se versionan)
# Autor     : equipo SLEP Costa Central — Fecha: 2026-07-10
# =============================================================================

# ---- 1. Bootstrapping ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("data.table", "jsonlite", "readxl"))

# ---- 3. Librerias ----
suppressMessages({ library(data.table); library(jsonlite) })

# ---- 4. Rutas centralizadas ----
RUTA_UNIVERSO    <- ruta_salidas("mapa_interactivo", "directorio_region5.rds")
RUTA_MATRICULA   <- ruta_salidas("mapa_interactivo", "matricula_historica_r5.rds")
RUTA_MACROGRUPOS <- ruta_insumos("auxiliares", "codigo_tipo_y_macrogrupo.xlsx")
RUTA_LISTADO_SLEP <- ruta_insumos("auxiliares", "listado_slep_2026.xlsx")
DIR_CSV_2025     <- ruta_insumos("historico_matricula", "Matricula-por-estudiante-2025")
DIR_WEB_DATA     <- ruta_salidas("mapa_interactivo", "web", "data")
RUTA_GEOJSON     <- file.path(DIR_WEB_DATA, "establecimientos.geojson")
RUTA_SIN_GEO     <- file.path(DIR_WEB_DATA, "sin_geo.json")
RUTA_METADATOS   <- file.path(DIR_WEB_DATA, "metadatos.json")

# ---- 5. Constantes nombradas ----
ANIO_ACTUAL     <- 2025L
FECHA_CORTE     <- "2025-04-30"     # corte oficial del directorio y matricula (fija: idempotencia)
ANIO_VIGENCIA_SLEP <- 2026L         # regla de dependencia vigente (ver 34 y metadatos)
DIGITOS_COORD   <- 5L               # ~1 m de precision; reduce peso del geojson
PESO_MAX_MB     <- 1                # gate de peso para Pages

# Diccionario de niveles: Anexo V (a partir de 2019) del esquema oficial de
# Matricula por estudiante (ER_Matricula_por_alumno_PUBL_WEB.pdf, pp. 18-23),
# restringido a los 23 COD_ENSE presentes en region 5 (planilla canonica).
NIVELES_ANEXO_V <- local({
  filas <- list(
    # ENSE 10 — parvularia
    c("10","1","Sala Cuna Mayor"), c("10","2","Nivel Medio Menor"),
    c("10","3","Nivel Medio Mayor"), c("10","4","Prekínder (NT1)"),
    c("10","5","Kínder (NT2)"), c("10","6","Sala Cuna Menor"),
    c("10","7","Sala Cuna Heterogéneo"), c("10","8","Nivel Medio Heterogéneo"),
    c("10","9","Nivel Transición Heterogéneo"), c("10","10","Heterogéneo"),
    # ENSE 110 — basica 1..8
    lapply(1:8, function(g) c("110", as.character(g), sprintf("%d° básico", g))),
    # basica adultos
    c("165","1","Nivel Básico 1 (1° a 4° básico)"),
    c("165","2","Nivel Básico 2 (5° y 6° básico)"),
    c("165","3","Nivel Básico 3 (7° y 8° básico)"),
    c("167","2","Nivel Básico 2 (5° y 6° básico)"),
    c("167","3","Nivel Básico 3 (7° y 8° básico)"),
    # especial: basico 1..8 + parvulario 21..25 + laboral 31..34 segun codigo
    lapply(c("211","212","213","215","216","217"), function(ce) c(
      lapply(1:8, function(g) c(ce, as.character(g), sprintf("%d° básico", g))),
      list(c(ce,"21","Atención Temprana"), c(ce,"22","Nivel Medio Menor"),
           c(ce,"23","Nivel Medio Mayor"), c(ce,"24","Nivel de Transición 1"),
           c(ce,"25","Nivel de Transición 2"), c(ce,"31","Laboral 1"),
           c(ce,"32","Laboral 2"), c(ce,"33","Laboral 3")),
      if (ce %in% c("213","215")) list(c(ce,"34","Laboral 4")) else list())),
    c("214","23","Nivel Medio Mayor"), c("214","24","Nivel de Transición 1"),
    c("214","25","Nivel de Transición 2"),
    lapply(1:8, function(g) c("299", as.character(g), sprintf("%d° básico", g))),
    c("299","24","Nivel de Transición 1"), c("299","25","Nivel de Transición 2"),
    c("299","31","Laboral 1"), c("299","32","Laboral 2"), c("299","33","Laboral 3"),
    # medias jovenes 1..4
    lapply(c("310","410","510","610","710","810"), function(ce)
      lapply(1:4, function(g) c(ce, as.character(g), sprintf("%d° medio", g)))),
    # medias adultos
    c("363","1","1er nivel (1° y 2° medio)"), c("363","3","2do nivel (3° y 4° medio)"),
    lapply(c("463","563","663","763"), function(ce) list(
      c(ce,"1","1er nivel (1° y 2° medio)"), c(ce,"3","2do nivel (3° medio)"),
      c(ce,"4","3er nivel (4° medio)"))))
  aplanar <- function(x) if (is.character(x)) list(x) else do.call(c, lapply(x, aplanar))
  dt <- rbindlist(lapply(aplanar(filas), function(v)
    data.table(cod_ense = v[1], cod_grado = v[2], nivel = v[3])))
  stopifnot(!anyDuplicated(dt[, .(cod_ense, cod_grado)]))
  dt
})

# ---- 6. Funciones ----

# Pares (RBD, COD_ENSE, COD_GRADO) observados en el ULTIMO ANIO CON MATRICULA de
# cada RBD (decision del titular 2026-07-11): para los 1.183 con matricula 2025
# es el crudo 2025 (identico a antes); para los EE en cierre progresivo, su
# ultimo anio observado en la serie (oferta HISTORICA, marcada con ens_anio).
# Los EE sin ningun anio quedan sin pares (no hay fuente: el ENS_* del
# directorio es matricula-dependiente por definicion de su glosa, nota 5).
# El MRUN NO se lee (select explicito de 3 columnas).
pares_ultimo_anio <- function(serie) {
  ultimo <- serie[, .(anio_oferta = max(anio)), by = rbd]
  res <- vector("list", 0L)
  for (a in sort(unique(ultimo$anio_oferta), decreasing = TRUE)) {
    rbds_a <- ultimo[anio_oferta == a, rbd]
    d <- ruta_insumos("historico_matricula", sprintf("Matricula-por-estudiante-%d", a))
    f <- list.files(d, pattern = "(?i)\\.csv$", full.names = TRUE)
    stopifnot(length(f) == 1)
    hdr <- names(fread(f, sep = ";", nrows = 0))
    cols <- hdr[match(c("RBD", "COD_ENSE", "COD_GRADO"), toupper(hdr))]
    stopifnot(!anyNA(cols))
    dt <- fread(f, sep = ";", select = cols, colClasses = "character",
                encoding = "UTF-8", showProgress = FALSE)
    setnames(dt, toupper(names(dt)))
    p <- unique(dt[RBD %chin% rbds_a & COD_ENSE != "" & COD_GRADO != "",
                   .(rbd = RBD, cod_ense = COD_ENSE, cod_grado = COD_GRADO)])
    p[, anio_oferta := a]
    res[[length(res) + 1L]] <- p
    rm(dt); invisible(gc(FALSE))
  }
  rbindlist(res)
}

# Serializa un data.table/list a JSON con escritura atomica.
escribir_json_atomico <- function(x, ruta, ...) {
  tmp <- paste0(ruta, ".tmp")
  jsonlite::write_json(x, tmp, auto_unbox = TRUE, na = "null", digits = NA, ...)
  file.rename(tmp, ruta)
  round(file.info(ruta)$size / 1e6, 3)
}

# ---- 7. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  for (f in c(RUTA_UNIVERSO, RUTA_MATRICULA))
    if (!file.exists(f)) stop("Falta insumo: ", f, ". Corre 34 y 35 primero.")
  universo <- as.data.table(readRDS(RUTA_UNIVERSO))
  mat      <- readRDS(RUTA_MATRICULA)
  ind      <- mat$indicadores
  serie    <- mat$serie
  ANIOS    <- mat$anios
  TEXTO_SIN_MATRICULA <- mat$texto_sin_matricula
  ETIQUETA_SIN_DATO   <- mat$etiqueta_sin_dato
  stopifnot(is.character(universo$rbd), is.character(ind$rbd),
            nrow(universo) == nrow(ind))

  # planilla canonica: cod_ense -> macrogrupo
  planilla <- as.data.table(readxl::read_excel(RUTA_MACROGRUPOS, sheet = 1))
  setnames(planilla, c("cod_ense", "desc_ense", "macrogrupo"))
  planilla[, cod_ense := as.character(as.integer(cod_ense))]

  # pares (tipo, nivel) del ultimo anio con matricula por RBD; gate si falta glosa
  pares <- pares_ultimo_anio(serie)
  sin_macro <- setdiff(unique(pares$cod_ense), planilla$cod_ense)
  if (length(sin_macro) > 0)
    stop("COD_ENSE observados sin macrogrupo en planilla: ",
         paste(sin_macro, collapse = ","), ". Pedir asignacion al titular.")
  pares <- merge(pares, planilla[, .(cod_ense, macrogrupo)], by = "cod_ense")
  sin_glosa <- unique(pares[!NIVELES_ANEXO_V, on = c("cod_ense", "cod_grado")][
                      , .(cod_ense, cod_grado)])
  if (nrow(sin_glosa) > 0)
    stop("Pares (COD_ENSE,COD_GRADO) observados sin glosa Anexo V: ",
         paste(sprintf("%s/%s", sin_glosa$cod_ense, sin_glosa$cod_grado), collapse = " "),
         ". Completar diccionario (no inventar).")
  pares <- merge(pares, NIVELES_ANEXO_V, by = c("cod_ense", "cod_grado"))
  # por EE: lista macrogrupo -> niveles (para el filtro dependiente) + anio de la oferta
  ens_por_ee <- pares[, .(niv = list(sort(unique(nivel)))), by = .(rbd, macrogrupo)]
  ens_lista <- ens_por_ee[, .(ens = list(unname(mapply(function(m, n) list(m = m, niv = n),
                                                       macrogrupo, niv, SIMPLIFY = FALSE)))),
                          by = rbd]
  ens_lista <- merge(ens_lista, unique(pares[, .(rbd, ens_anio = anio_oferta)]), by = "rbd")
  n_hist <- ens_lista[ens_anio < ANIO_ACTUAL, .N]
  log_msg(sprintf("Pares tipo-nivel: %d pares distintos en %d EE (todos con glosa); %d EE con oferta HISTORICA (ultimo anio < %d).",
                  nrow(unique(pares[, .(cod_ense, cod_grado)])), uniqueN(pares$rbd),
                  n_hist, ANIO_ACTUAL), origen = "36_geojson")

  # ---- ensamble por EE ----
  d <- merge(universo, ind, by = "rbd", all.x = TRUE)
  d <- merge(d, ens_lista, by = "rbd", all.x = TRUE)
  # serie como array de 10 (null donde no hay registro)
  serie_w <- dcast(serie, rbd ~ anio, value.var = "matricula")
  cols_anio <- as.character(ANIOS)
  faltan <- setdiff(cols_anio, names(serie_w))
  if (length(faltan) > 0) serie_w[, (faltan) := NA_integer_]
  d <- merge(d, serie_w, by = "rbd", all.x = TRUE)

  presentar <- function(fila) {
    list(
      rbd  = fila$rbd,
      n    = fila$nombre,
      com  = fila$comuna,
      prov = fila$provincia,
      dep  = fila$dependencia,
      slep = fila$slep_nombre,              # NA -> null (solo EE administrados por SLEP)
      mg   = if (is.null(fila$macrogrupos[[1]])) list() else as.list(fila$macrogrupos[[1]]),
      ens  = if (is.null(fila$ens[[1]])) list() else fila$ens[[1]],
      ensa = if (is.null(fila$ens[[1]])) NA_integer_ else fila$ens_anio,  # anio de la oferta (< 2025 = historica)
      ma   = if (is.na(fila$matricula_actual)) TEXTO_SIN_MATRICULA else fila$matricula_actual,
      mx   = if (is.na(fila$max_10))  ETIQUETA_SIN_DATO else fila$max_10,
      pr   = if (is.na(fila$prom_10)) ETIQUETA_SIN_DATO else round(fila$prom_10),  # redondeo SOLO aqui
      mn   = if (is.na(fila$min_10))  ETIQUETA_SIN_DATO else fila$min_10,
      # huecos como NA (na="null" los escribe como null LITERAL en el JSON).
      # NUNCA como NULL de R: jsonlite serializa NULL dentro de lista como {} y
      # el consumidor JS trataria el hueco como dato (bug corregido 2026-07-11).
      s    = lapply(cols_anio, function(a) { v <- fila[[a]]; if (is.na(v)) NA_integer_ else v })
    )
  }

  con_geo <- d[geo_valida == TRUE]
  sin_geo <- d[geo_valida == FALSE]
  log_msg(sprintf("Ensamble: %d EE (%d pins, %d sin geo).",
                  nrow(d), nrow(con_geo), nrow(sin_geo)), origen = "36_geojson")

  features <- lapply(seq_len(nrow(con_geo)), function(i) {
    fila <- con_geo[i]
    list(type = "Feature",
         geometry = list(type = "Point",
                         coordinates = c(round(fila$lon, DIGITOS_COORD),
                                         round(fila$lat, DIGITOS_COORD))),
         properties = presentar(fila))
  })
  geojson <- list(type = "FeatureCollection", features = features)

  sin_geo_lista <- lapply(seq_len(nrow(sin_geo)), function(i) {
    x <- presentar(sin_geo[i]); x$geo <- "sin coordenadas"; x
  })

  metadatos <- list(
    producto = "Mapa interactivo de establecimientos educacionales, Region de Valparaiso",
    fecha_corte = FECHA_CORTE,
    ventana_anios = ANIOS,
    universo = list(
      criterio = "Directorio oficial 2025, region 5, ESTADO_ESTAB=1 (funcionando)",
      n_establecimientos = nrow(d), n_pins = nrow(con_geo), n_sin_geo = nrow(sin_geo),
      exclusion_insular = paste("Territorio insular oceanico excluido del alcance v1",
        "(comunas 5201 Isla de Pascua y 5104 Juan Fernandez, 6 EE; sistema educativo",
        "insular propio y distorsion del encuadre continental). Decision de alcance,",
        "no descarte definitivo: candidato a capa/inset en v2.")),
    criterios_calculo = list(
      dependencia = "La dependencia refleja la situación institucional vigente a 2026, incluyendo traspasos a Servicios Locales de Educación posteriores al corte del directorio (30-abr-2025). Comunas con traspaso postergado (Zapallar, Santo Domingo) se mantienen municipales. Fuente: listado oficial de SLEP 2026; recodificación deliberada y documentada respecto del dato literal del directorio.",
      matricula = "Matricula anual por RBD = numero de estudiantes distintos (MRUN unicos) en la base oficial 'Matricula por estudiante'; el identificador se descarta tras agregar y no se publica.",
      matricula_actual = sprintf("Matricula del anio mas reciente disponible (%d). Sin registro ese anio: '%s'", ANIO_ACTUAL, TEXTO_SIN_MATRICULA),
      max_10 = "Mayor matricula anual en la ventana.",
      prom_10 = "Promedio de la matricula anual observada en la ventana (redondeado a entero en la publicacion).",
      min_10 = sprintf("Menor matricula anual entre los anios CON REGISTRO en la ventana. Los anios sin registro (huecos de la serie) no se computan como 0 ni arrastran el minimo (la fuente no contiene matriculas 0 explicitas: un RBD-anio sin estudiantes simplemente no tiene fila). Sin ningun anio con registro: '%s' (nunca 0).", ETIQUETA_SIN_DATO),
      nota_serie_corta = "En EE con un solo anio de dato en la ventana, los cuatro indicadores coinciden por construccion.",
      parvularia = "Los parvulos de escuelas con RBD estan incluidos via la base oficial; los jardines JUNJI/Integra sin RBD no forman parte del universo (fuente separada, corte distinto).",
      niveles = "Pares (tipo de ensenanza, nivel) observados en la matricula del ULTIMO anio con registro de cada RBD, decodificados con el Anexo V (a partir de 2019) del esquema oficial; tipo agrupado segun planilla canonica de macrogrupos. Si el ultimo anio es anterior a 2025 (EE en cierre progresivo), la oferta es HISTORICA y el campo ensa lo indica. Los EE sin ningun anio de matricula no tienen oferta derivable: el ENS_* del directorio es matricula-dependiente por definicion de su glosa (nota 5), no un registro de autorizacion administrativa."),
    glosario_claves = list(
      rbd = "Rol Base de Datos", n = "nombre", com = "comuna", prov = "provincia",
      dep = "dependencia (vigente 2026; ver criterios_calculo$dependencia)",
      slep = "nombre del SLEP que administra el EE (null si no es SLEP)",
      mg = "macrogrupos de ensenanza",
      ens = "lista {m: macrogrupo, niv: niveles observados}",
      ensa = "anio del que proviene la oferta (2025 = vigente; anterior = historica, EE en cierre; null = sin oferta derivable)",
      ma = "matricula actual (2025)", mx = "maximo 10 anios",
      pr = "promedio 10 anios", mn = "minimo 10 anios (>0)",
      s  = sprintf("serie anual %d-%d (null = sin registro)", min(ANIOS), max(ANIOS))),
    filtro_slep = local({
      # los 8 SLEP continentales de la region (Hanga Roa insular queda fuera de v1),
      # con estado segun la regla de vigencia: los "pendiente" no tienen EE en el
      # mapa (el filtro puede mostrarlos deshabilitados).
      sl <- as.data.table(readxl::read_excel(RUTA_LISTADO_SLEP, sheet = "Listado SLEP"))
      sl <- sl[NUM_REGION == 5 & NOMBRE_SLEP_FORMATO != "Hanga Roa",
               .(slep = NOMBRE_SLEP_FORMATO,
                 anio_traspaso = as.integer(AGNO_TRASPASO_EDUC))]
      sl <- sl[, .(anio_traspaso = min(anio_traspaso)), by = slep][order(anio_traspaso, slep)]
      stopifnot(nrow(sl) == 8L)   # los 8 SLEP continentales
      sl[, estado := fifelse(anio_traspaso <= ANIO_VIGENCIA_SLEP,
                             "vigente", "pendiente")]
      lapply(seq_len(nrow(sl)), function(i) as.list(sl[i]))
    }),
    fuentes = list(
      directorio = "Directorio Oficial de Establecimientos, Centro de Estudios MINEDUC (corte 30-abr).",
      matricula = "Matricula por estudiante 2016-2025, Centro de Estudios MINEDUC.",
      slep = "Listado oficial de SLEP 2026 (listado_slep_2026.xlsx), incl. hoja de consideraciones especificas.",
      macrogrupos = "Planilla canonica codigo_tipo_y_macrogrupo.xlsx (titular del proyecto)."))

  dir.create(DIR_WEB_DATA, showWarnings = FALSE, recursive = TRUE)
  mb_geo  <- escribir_json_atomico(geojson,      RUTA_GEOJSON)
  mb_sg   <- escribir_json_atomico(sin_geo_lista, RUTA_SIN_GEO)
  mb_meta <- escribir_json_atomico(metadatos,    RUTA_METADATOS)
  log_msg(sprintf("Escritos: establecimientos.geojson %.3f MB | sin_geo.json %.3f MB | metadatos.json %.3f MB.",
                  mb_geo, mb_sg, mb_meta), origen = "36_geojson")
  if (mb_geo > PESO_MAX_MB)
    stop("establecimientos.geojson pesa ", mb_geo, " MB (> ", PESO_MAX_MB, " MB).")

  # ---- validaciones de salida ----
  chk <- jsonlite::read_json(RUTA_GEOJSON)
  stopifnot(length(chk$features) == nrow(con_geo))
  txt <- paste(readLines(RUTA_GEOJSON, warn = FALSE), collapse = "")
  stopifnot(!grepl("MRUN|mrun", txt))
  log_msg(sprintf("Validado: %d features; sin rastro de identificadores individuales.",
                  length(chk$features)), origen = "36_geojson")
}
