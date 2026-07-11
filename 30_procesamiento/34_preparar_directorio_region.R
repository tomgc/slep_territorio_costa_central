# =============================================================================
# 34_preparar_directorio_region.R
# Proposito : Etapa 2.1 del mapa interactivo regional. Prepara el universo de
#             establecimientos de la Region de Valparaiso desde el directorio
#             oficial: filtra region 5 + funcionando, EXCLUYE el territorio
#             insular oceanico (comunas 5201 Isla de Pascua y 5104 Juan
#             Fernandez; alcance v1), decodifica (provincia, dependencia,
#             macrogrupos segun planilla canonica), RECODIFICA la dependencia a
#             la situacion SLEP vigente 2026 (ver bloque de constantes), valida
#             geo continental y reporta los sin geo (se excluyen del mapa, NO
#             se inventan).
#             Los NIVELES por EE no salen de aqui: se derivan en 35 de los pares
#             (COD_ENSE, COD_GRADO) observados en el historico (diagnostico §7.6).
# Insumos   : 20_insumos/auxiliares/directorio_oficial_ee_publico.csv (UTF-8, ;)
#             20_insumos/auxiliares/codigo_tipo_y_macrogrupo.xlsx (fuente UNICA
#               de macrogrupos; 23 codigos -> 6 macrogrupos)
# Salidas   : 40_salidas/mapa_interactivo/directorio_region5.rds
# Reglas    : llaves character; sin filtrar por contencion; escritura atomica;
#             idempotente. Pipeline SEPARADO de 00_run_all (🔒).
# Autor     : equipo SLEP Costa Central — Fecha: 2026-07-10
# =============================================================================

# ---- 1. Bootstrapping ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("data.table", "dplyr", "readxl"))

# ---- 3. Librerias ----
suppressMessages({ library(data.table); library(dplyr) })

# ---- 4. Rutas centralizadas ----
RUTA_DIRECTORIO  <- ruta_insumos("auxiliares", "directorio_oficial_ee_publico.csv")
RUTA_MACROGRUPOS <- ruta_insumos("auxiliares", "codigo_tipo_y_macrogrupo.xlsx")
RUTA_LISTADO_SLEP <- ruta_insumos("auxiliares", "listado_slep_2026.xlsx")
DIR_SALIDA_MAPA  <- ruta_salidas("mapa_interactivo")
RUTA_SALIDA      <- file.path(DIR_SALIDA_MAPA, "directorio_region5.rds")

# ---- 5. Constantes nombradas ----
COD_REGION_VALPARAISO <- "5"
ESTADO_FUNCIONANDO    <- "1"     # glosa ESTADO_ESTAB: 1 Funcionando
N_MACROGRUPOS_ESPERADOS <- 6L
N_CODIGOS_PLANILLA      <- 23L

# Exclusion de alcance v1 (decision del titular, 2026-07-10): territorio insular
# oceanico FUERA del alcance continental v1 (sistema educativo insular propio;
# los pins a cientos/miles de km distorsionan el encuadre regional). Es decision
# de alcance, NO descarte definitivo: candidato a capa/inset en v2. Criterio POR
# COMUNA (COD_COM_RBD, character), verificado contra el directorio:
#   5201 = Isla de Pascua (prov 52; 5 EE funcionando)
#   5104 = Juan Fernandez (prov 51; 1 EE funcionando: RBD 2009)
COMUNAS_INSULARES_EXCLUIDAS_V1 <- c("5201", "5104")
N_EE_INSULARES_ESPERADOS <- 6L    # 5 Rapa Nui + 1 Juan Fernandez (check)

# Anexo I glosas oficiales: provincias de la region 5 (COD_PRO_RBD -> nombre).
PROVINCIAS_R5 <- c(
  "51" = "Valparaíso", "52" = "Isla de Pascua", "53" = "Los Andes",
  "54" = "Petorca",    "55" = "Quillota",       "56" = "San Antonio",
  "57" = "San Felipe de Aconcagua", "58" = "Marga Marga")

# Glosas COD_DEPE2 (dependencia agrupada, 5 valores; la que usa el filtro).
DEPENDENCIAS <- c(
  "1" = "Municipal", "2" = "Particular Subvencionado", "3" = "Particular Pagado",
  "4" = "Corp. de Administración Delegada", "5" = "Servicio Local de Educación")

# =============================================================================
# RECODIFICACION SLEP VIGENTE 2026 (decision del titular, 2026-07-11).
# QUE HACE: la dependencia mostrada refleja la situacion institucional VIGENTE
# a 2026, no el corte del directorio (30-abr-2025). Las comunas con
# AGNO_TRASPASO_EDUC <= 2026 en listado_slep_2026.xlsx (region 5) se muestran
# como "Servicio Local de Educacion" con el nombre del SLEP
# (NOMBRE_SLEP_FORMATO), aunque el directorio las traiga como municipales.
# POR QUE: el directorio 2025 antecede a los traspasos del 1-ene-2026
# (Aconcagua, Los Andes, Marga Marga, Petorca); mostrar el dato literal
# pintaria como municipales 216 EE que hoy administran los SLEP. Esta es una
# RECODIFICACION DELIBERADA que se aparta del dato oficial, declarada en
# metadatos.json; no un parche silencioso.
# EXCEPCIONES (hoja "Consideraciones" del listado): Zapallar (Petorca, 2027) y
# Santo Domingo (del Litoral, 2028) postergadas; del Litoral (2027) y Quillota
# (2029) aun no traspasan -> todos siguen municipales.
# Costa Central (73) y Valparaiso (54) ya vienen como COD_DEPE2=5 del
# directorio: la regla no los altera, solo les asigna el nombre del SLEP.
# =============================================================================
TRASPASO_SLEP_VIGENTE_2026 <- TRUE
ANIO_VIGENCIA_TRASPASO     <- 2026L
# Gate COMPUESTO (no un total unico: un agregado puede pasar con componentes
# malos que se compensan). Desagregados verificados con stopifnot en el flujo.
# NOTA: el 55.o EE de SLEP Valparaiso es RBD 2009 (Colegio Insular Robinson
# Crusoe, Juan Fernandez, traspasado 2021): queda FUERA por la exclusion de
# territorio insular v1 (decision de sesion; ver COMUNAS_INSULARES_EXCLUIDAS_V1).
N_SLEP_DEP5_DIRECTORIO <- 127L   # ya SLEP en el dato: Valparaiso 54 + Costa Central 73
N_SLEP_RECODIFICADOS   <- 216L   # municipales que pasan a SLEP por traspaso <= 2026
N_SLEP_TOTAL_ESPERADO  <- 343L   # 127 + 216
# Desagregados esperados (verificados por partes):
SLEP_DEP5_POR_COMUNA <- c("5101" = 54L,                      # Valparaiso
                          "5109" = 49L, "5105" = 14L,        # Costa Central:
                          "5107" =  6L, "5103" =  4L)        #  Vina/Puch/Quint/Concon
SLEP_RECOD_POR_SLEP  <- c("Aconcagua" = 67L, "Marga Marga" = 58L,
                          "Petorca" = 55L, "Los Andes" = 36L)
MUNICIPALES_NO_TRASPASADOS <- c(zapallar = 4L, santo_domingo = 6L,
                                del_litoral = 48L, quillota = 47L)
COMUNA_ZAPALLAR      <- "5405"
COMUNA_SANTO_DOMINGO <- "5606"
COMUNAS_DEL_LITORAL  <- c("5601", "5602", "5603", "5102", "5604", "5605")  # sin Sto Domingo
COMUNAS_QUILLOTA     <- c("5501", "5502", "5503", "5504", "5506")

# Caja de validacion geografica continental (unica vigente para geo_valida).
# El territorio insular ya salio del universo por COMUNA (criterio de arriba);
# si un EE del universo trae coords fuera de esta caja pero no vacias, el flujo
# lo DETIENE como inconsistencia (coords reales fuera del continente => o es
# insular mal codificado en comuna, o es un error de captura que hay que mirar).
BBOX_CONTINENTE <- list(lat = c(-34.5, -31.5), lon = c(-72.5, -70.0))

# ---- 6. Funciones ----

# Lee la planilla canonica de macrogrupos (fuente UNICA del filtro Tipo de
# ensenanza). Verifica 23 codigos -> 6 macrogrupos, sin duplicados.
leer_macrogrupos <- function() {
  pl <- readxl::read_excel(RUTA_MACROGRUPOS, sheet = 1) |> as.data.table()
  setnames(pl, c("cod_ense", "desc_ense", "macrogrupo"))
  pl[, cod_ense := as.character(as.integer(cod_ense))]
  stopifnot(nrow(pl) == N_CODIGOS_PLANILLA,
            uniqueN(pl$macrogrupo) == N_MACROGRUPOS_ESPERADOS,
            !anyDuplicated(pl$cod_ense))
  pl
}

# Lee el directorio oficial (UTF-8, sep ;) con TODAS las columnas como character
# (llaves character; los numeros se convierten solo donde se usan).
leer_directorio <- function() {
  fread(RUTA_DIRECTORIO, sep = ";", encoding = "UTF-8",
        colClasses = "character", showProgress = FALSE)
}

# Coordenada valida si es parseable y cae en el continente region 5 o en Rapa Nui.
en_caja <- function(lat, lon, caja) {
  !is.na(lat) & !is.na(lon) &
    lat >= caja$lat[1] & lat <= caja$lat[2] &
    lon >= caja$lon[1] & lon <= caja$lon[2]
}

# Lee el listado oficial de SLEP (region 5): comuna -> SLEP y anio de traspaso.
# Llaves character. NOMBRE_SLEP_FORMATO es el nombre a mostrar (decision titular).
leer_listado_slep <- function() {
  sl <- readxl::read_excel(RUTA_LISTADO_SLEP, sheet = "Listado SLEP") |> as.data.table()
  sl <- sl[NUM_REGION == 5, .(cod_comuna = as.character(COD_COM_RBD),
                              slep_nombre = NOMBRE_SLEP_FORMATO,
                              anio_traspaso = as.integer(AGNO_TRASPASO_EDUC))]
  stopifnot(!anyDuplicated(sl$cod_comuna), !any(is.na(sl$anio_traspaso)))
  sl
}

# Macrogrupos por RBD desde ENS_01..ENS_11 cruzados con la planilla canonica.
# Devuelve tabla RBD -> lista de codigos y de macrogrupos (unicos, orden planilla).
derivar_tipos <- function(dt, planilla) {
  ens_cols <- grep("^ENS_", names(dt), value = TRUE)
  largo <- melt(dt[, c("RBD", ens_cols), with = FALSE], id.vars = "RBD",
                value.name = "cod_ense", variable.name = "slot")
  largo <- largo[!is.na(cod_ense) & !cod_ense %chin% c("", "0")]
  largo <- unique(largo[, .(RBD, cod_ense)])
  sin_clasificar <- setdiff(unique(largo$cod_ense), planilla$cod_ense)
  if (length(sin_clasificar) > 0)
    stop("Codigos COD_ENSE sin macrogrupo en la planilla canonica: ",
         paste(sin_clasificar, collapse = ", "),
         ". Detener y pedir asignacion al titular (no inventar).")
  largo <- merge(largo, planilla[, .(cod_ense, macrogrupo)], by = "cod_ense")
  largo[, .(codigos_ense = list(sort(unique(cod_ense))),
            macrogrupos  = list(unique(macrogrupo))), by = RBD]
}

# ---- 7. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  planilla <- leer_macrogrupos()
  log_msg(sprintf("Planilla canonica: %d codigos -> %d macrogrupos.",
                  nrow(planilla), uniqueN(planilla$macrogrupo)), origen = "34_directorio")

  dir_nac <- leer_directorio()
  log_msg(sprintf("Directorio nacional: %d filas (AGNO %s).",
                  nrow(dir_nac), paste(unique(dir_nac$AGNO), collapse = ",")),
          origen = "34_directorio")

  r5 <- dir_nac[COD_REG_RBD == COD_REGION_VALPARAISO &
                ESTADO_ESTAB == ESTADO_FUNCIONANDO]
  insulares <- r5[COD_COM_RBD %chin% COMUNAS_INSULARES_EXCLUIDAS_V1]
  stopifnot(nrow(insulares) == N_EE_INSULARES_ESPERADOS)   # 5 Rapa Nui + 1 J.Fernandez
  r5 <- r5[!COD_COM_RBD %chin% COMUNAS_INSULARES_EXCLUIDAS_V1]  # exclusion alcance v1
  log_msg(sprintf("Exclusion insular v1 (comunas %s): %d EE fuera del producto (RBD: %s).",
                  paste(COMUNAS_INSULARES_EXCLUIDAS_V1, collapse = ","),
                  nrow(insulares), paste(sort(insulares$RBD), collapse = " ")),
          origen = "34_directorio")
  stopifnot(!anyDuplicated(r5$RBD),                  # RBD unicos
            !any(is.na(r5$RBD) | r5$RBD == ""),      # llaves completas
            !any(is.na(r5$COD_COM_RBD) | r5$COD_COM_RBD == ""),
            all(r5$COD_PRO_RBD %chin% names(PROVINCIAS_R5)),
            !any(r5$COD_COM_RBD %chin% COMUNAS_INSULARES_EXCLUIDAS_V1),
            all(r5$COD_DEPE2 %chin% names(DEPENDENCIAS)))
  log_msg(sprintf("Universo region 5 funcionando (sin comunas insulares): %d EE (flag MATRICULA=1: %d; provincias: %d).",
                  nrow(r5), sum(r5$MATRICULA == "1"), uniqueN(r5$COD_PRO_RBD)),
          origen = "34_directorio")

  # decodificaciones (character -> glosa; nunca se publican los codigos crudos solos)
  r5[, `:=`(provincia   = unname(PROVINCIAS_R5[COD_PRO_RBD]),
            dependencia = unname(DEPENDENCIAS[COD_DEPE2]),
            rural       = fifelse(RURAL_RBD == "1", "Rural", "Urbano"))]

  # ---- Recodificacion SLEP vigente 2026 (ver bloque de constantes) ----
  if (TRASPASO_SLEP_VIGENTE_2026) {
    listado <- leer_listado_slep()
    # gate: NINGUNA comuna del universo puede faltar en el listado (no se asume
    # municipal por omision)
    faltantes <- setdiff(unique(r5$COD_COM_RBD), listado$cod_comuna)
    if (length(faltantes) > 0)
      stop("Comunas del universo ausentes del listado SLEP: ",
           paste(faltantes, collapse = ","), ". No se asume nada: revisar listado.")
    r5 <- merge(r5, listado, by.x = "COD_COM_RBD", by.y = "cod_comuna",
                all.x = TRUE, sort = FALSE)
    vigente <- r5$anio_traspaso <= ANIO_VIGENCIA_TRASPASO
    dep5_pre <- r5$COD_DEPE2 == "5"
    # gates de estado PREVIO (desagregado por comuna; sin doble conteo)
    stopifnot(sum(dep5_pre) == N_SLEP_DEP5_DIRECTORIO)
    for (cc in names(SLEP_DEP5_POR_COMUNA))
      stopifnot(sum(dep5_pre & r5$COD_COM_RBD == cc) == SLEP_DEP5_POR_COMUNA[[cc]])
    stopifnot(all(vigente[dep5_pre]))          # todo dep5 previo esta en comuna vigente
    recod <- vigente & !dep5_pre & r5$COD_DEPE2 == "1"   # SOLO municipales cambian
    stopifnot(sum(recod) == N_SLEP_RECODIFICADOS,
              sum(recod & dep5_pre) == 0)      # sin doble conteo (por construccion)
    for (sn in names(SLEP_RECOD_POR_SLEP))
      stopifnot(sum(recod & r5$slep_nombre == sn) == SLEP_RECOD_POR_SLEP[[sn]])
    # aplicar: dependencia mostrada = SLEP + nombre. El nombre del SLEP marca
    # SOLO a los EE administrados por el SLEP (dep5 tras la regla): un particular
    # de una comuna traspasada NO es del SLEP.
    r5[recod, `:=`(COD_DEPE2 = "5", dependencia = DEPENDENCIAS[["5"]])]
    r5[COD_DEPE2 != "5", slep_nombre := NA_character_]
    # gates de estado POSTERIOR
    stopifnot(sum(r5$COD_DEPE2 == "5") == N_SLEP_TOTAL_ESPERADO,
              sum(!is.na(r5$slep_nombre)) == N_SLEP_TOTAL_ESPERADO,
              sum(r5$COD_COM_RBD == COMUNA_ZAPALLAR & r5$COD_DEPE2 == "1") ==
                MUNICIPALES_NO_TRASPASADOS[["zapallar"]],
              sum(r5$COD_COM_RBD == COMUNA_SANTO_DOMINGO & r5$COD_DEPE2 == "1") ==
                MUNICIPALES_NO_TRASPASADOS[["santo_domingo"]],
              sum(r5$COD_COM_RBD %chin% COMUNAS_DEL_LITORAL & r5$COD_DEPE2 == "1") ==
                MUNICIPALES_NO_TRASPASADOS[["del_litoral"]],
              sum(r5$COD_COM_RBD %chin% COMUNAS_QUILLOTA & r5$COD_DEPE2 == "1") ==
                MUNICIPALES_NO_TRASPASADOS[["quillota"]])
    log_msg(sprintf(paste0("Recodificacion SLEP vigente 2026: %d dep5 del directorio + ",
                    "%d recodificados = %d EE SLEP (%s). Municipales no traspasados ",
                    "intactos: Zapallar %d, Sto Domingo %d, del Litoral %d, Quillota %d."),
                    N_SLEP_DEP5_DIRECTORIO, sum(recod), sum(r5$COD_DEPE2 == "5"),
                    paste(sprintf("%s=%d", names(SLEP_RECOD_POR_SLEP), SLEP_RECOD_POR_SLEP),
                          collapse = " "),
                    MUNICIPALES_NO_TRASPASADOS[["zapallar"]],
                    MUNICIPALES_NO_TRASPASADOS[["santo_domingo"]],
                    MUNICIPALES_NO_TRASPASADOS[["del_litoral"]],
                    MUNICIPALES_NO_TRASPASADOS[["quillota"]]),
            origen = "34_directorio")
  } else {
    r5[, slep_nombre := NA_character_]
  }

  # geo: decimal con coma en el directorio 2025
  r5[, `:=`(lat = suppressWarnings(as.numeric(gsub(",", ".", LATITUD))),
            lon = suppressWarnings(as.numeric(gsub(",", ".", LONGITUD))))]
  # check de coherencia: en el universo continental, coords PARSEABLES fuera de la
  # caja continental son inconsistencia (insular mal codificado en comuna o error
  # de captura) => DETIENE. Los sin-geo legitimos son solo coords vacias/no parseables.
  parseable <- !is.na(r5$lat) & !is.na(r5$lon)
  fuera_caja <- parseable & !en_caja(r5$lat, r5$lon, BBOX_CONTINENTE)
  if (any(fuera_caja))
    stop("Inconsistencia: ", sum(fuera_caja), " EE con coordenadas parseables FUERA ",
         "de la caja continental en el universo post-exclusion insular (RBD: ",
         paste(r5$RBD[fuera_caja], collapse = ","), "). Revisar comuna vs geo.")
  r5[, geo_valida := en_caja(lat, lon, BBOX_CONTINENTE)]
  sin_geo <- r5[geo_valida == FALSE, RBD]
  log_msg(sprintf("Geo valida (continental): %d de %d. SIN GEO (excluidos del mapa, no se inventa): %d RBD: %s",
                  sum(r5$geo_valida), nrow(r5), length(sin_geo),
                  paste(sin_geo, collapse = " ")), origen = "34_directorio")

  # tipos de ensenanza por EE (macrogrupos, fuente unica planilla)
  tipos <- derivar_tipos(r5, planilla)
  r5 <- merge(r5, tipos, by = "RBD", all.x = TRUE)
  log_msg(sprintf("EE con >=1 codigo de ensenanza: %d de %d.",
                  sum(!vapply(r5$macrogrupos, is.null, TRUE)), nrow(r5)),
          origen = "34_directorio")

  # seleccion final (solo lo que el pipeline usa; sin MRUN de sostenedor ni pagos)
  out <- r5[, .(rbd = RBD, dgv = DGV_RBD, nombre = NOM_RBD,
                cod_comuna = COD_COM_RBD, comuna = NOM_COM_RBD,
                cod_provincia = COD_PRO_RBD, provincia,
                cod_dependencia = COD_DEPE2, dependencia, slep_nombre, rural,
                lat, lon, geo_valida,
                matricula_flag = MATRICULA, mat_total = MAT_TOTAL,
                codigos_ense, macrogrupos)]
  setorder(out, rbd)

  # escritura atomica e idempotente
  dir.create(DIR_SALIDA_MAPA, showWarnings = FALSE, recursive = TRUE)
  tmp <- paste0(RUTA_SALIDA, ".tmp")
  saveRDS(out, tmp); file.rename(tmp, RUTA_SALIDA)
  log_msg(sprintf("Universo escrito en %s (%d EE, %d con geo).",
                  RUTA_SALIDA, nrow(out), sum(out$geo_valida)), origen = "34_directorio")
}
