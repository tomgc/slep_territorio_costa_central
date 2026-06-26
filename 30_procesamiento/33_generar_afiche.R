# =============================================================================
# 33_generar_afiche.R
# Proposito : Generar el afiche cartografico simplificado (encargo v2) sobre fondo
#             CARTO Positron REAL. Dos planos con SOLO pines numerados (sin
#             etiquetas de texto ni leader lines en el mapa): (1) panel norte con
#             Puchuncavi, Quintero y Concon; (2) inset de Vina del Mar con zoom y
#             60 pines (decision 🔒-4). En ambos se dibujan los limites comunales
#             sobre el CARTO. Numeracion oficial N->S 1..97 compartida por mapa,
#             inset e indice; el indice (izquierda) lleva numero + nombre + RBD.
# Insumos   : 40_salidas/establecimientos_proyectados.rds (de 32; se reusan
#               lat/lon, nombre, tipo, comuna, rbd; la numeracion se recalcula).
#             20_insumos/comunas.geojson (limites, campo "Comuna").
#             Tiles CARTO Positron via maptiles (descarga en linea, cacheada).
#             fonts/*.otf ; assets/logo-color-stacked.png
# Salidas   : 40_salidas/afiche/mapa_establecimientos.html (autocontenido)
#             40_salidas/afiche/panel_norte.png, panel_vina.png (incrustados)
# Autor     : equipo SLEP Costa Central
# Fecha     : 2026-06-25
#
# NOTA DE ENTORNO: la primera corrida descarga tiles CARTO (red). maptiles cachea
# en tempdir(). Requiere locale UTF-8 para mapear tipos con tilde (ver MAPEO_TIPO).
# =============================================================================

# ---- 1. Bootstrapping y configuracion ----
source(here::here("10_utils", "10_utils.R"))
source(here::here("10_utils", "10_configuracion.R"))

# ---- 2. Auto-instalacion ----
instalar_si_falta(c("dplyr", "sf", "maptiles", "terra", "ggplot2", "ragg",
                    "systemfonts", "base64enc", "glue", "pagedown", "pdftools"))

# ---- 3. Librerias ----
suppressMessages({
  library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg); library(glue)
})

# ---- 4. Constantes ----
TIPO_ORDEN  <- c("jardin", "basica", "liceo", "especial", "adultos")  # 🔒-5 Fase 1
COMUNAS_CHICAS <- c("Puchuncaví", "Quintero", "Concón")
COMUNA_INSET   <- "Viña del Mar"

# Lienzo del afiche (1240x1754). Area de mapa = derecha de la lista, sin footer.
PAD_MAPA   <- 22
GAP_PANEL  <- 16
MAPA_W     <- LIENZO$ancho - LIENZO$lista_w - 2 * PAD_MAPA            # 728
ALTO_BODY  <- LIENZO$alto - LIENZO$header_h - 2 * PAD_MAPA           # 1520
NORTE_H    <- 944
VINA_H     <- ALTO_BODY - NORTE_H - GAP_PANEL                        # 560

# ---- Salida fisica A0 vertical (encargo v8) ----
# El lienzo px (1240x1754, proporcion ~A4/raiz2) se imprime a tamaño A0 vertical.
A0_W_MM <- 841; A0_H_MM <- 1189; PX_POR_PULG_CSS <- 96
DPI_A0  <- 200L  # densidad objetivo de los PNG de mapa sobre A0 (>=150 minimo)
# ESC = factor de render de los PNG para que su ancho en px de la densidad pedida
# sobre el ancho fisico que el panel ocupa en A0. A 200 dpi da ~5.34.
ESC <- DPI_A0 * A0_W_MM / (25.4 * LIENZO$ancho)
# ZOOM lleva el contenedor px a tamaño A0 (ajusta por alto, deja ~1mm de holgura
# para no forzar una 2a pagina). El texto sigue siendo vectorial bajo zoom.
ZOOM <- 0.999 * (A0_H_MM / 25.4 * PX_POR_PULG_CSS) / LIENZO$alto

# Colores de pin por tipo (encargo v2). El indice y la leyenda usan los mismos.
COLOR_TIPO <- c(jardin = "#6a8a3a", basica = "#2d5f8a", liceo = "#c8732e",
                especial = "#7a4a8a", adultos = "#555555")
# Borde comunal sutil pero visible sobre CARTO Positron.
COL_BORDE_COMUNA <- "#7a7a7a"

# Pin unico grande (encargo v4). Radio/separacion en px del PNG; ESCALAN con ESC
# para conservar la proporcion del pin respecto al panel a cualquier densidad
# (22 px / 4 px cuando ESC=2; v8 sube ESC para A0 sin cambiar la proporcion).
# La anti-colision GARANTIZA centros a >= 2*PIN_RADIO_PX (verificado numericamente).
PIN_RADIO_PX <- 11 * ESC   # radio del pin en px del PNG (22 px-equivalentes a ESC=2)
PIN_GAP_PX   <- 2 * ESC    # separacion minima visible entre bordes de pines
PIN_FONT     <- 4.3        # tamaño unico del numero (geom_text, mm; proporcion constante)

# Indice (v6): fuente ligeramente mayor (antes 10/12.5 px) para llenar el alto.
# Tope por no-overflow: los 97 (Viña en 2 col) deben caber; space-between reparte slack.
INDICE_FONT     <- 10.3  # px: numero, nombre y RBD del indice (max sin overflow)
INDICE_FONT_HDR <- 13    # px: encabezado de comuna

# Etiquetas de comuna PROPIAS (v7): el tile ya no trae rotulos (PositronNoLabels),
# asi que el afiche dibuja sus propias etiquetas de comuna. Azul institucional gobCL,
# tamaño unico grande, en zonas despejadas. Posiciones (lon/lat) afinadas sobre el
# render para caer en el vacio sin pines.
COLOR_COMUNA      <- "#0F69B4"   # azul institucional gobCL
LABEL_COMUNA_FONT <- 6.2         # tamaño unico (geom_text, mm); > numero de pin
ETIQUETAS_COMUNA <- data.frame(
  nom    = c("Puchuncaví", "Quintero", "Concón", "Viña del Mar"),
  panel  = c("norte", "norte", "norte", "vina"),
  # afinadas sobre el render hacia el vacio sin pines, dentro del marco:
  lon    = c(-71.425, -71.520, -71.515, -71.573),
  lat    = c(-32.752, -32.860, -32.945, -33.010),
  stringsAsFactors = FALSE)

# Rutas de PNG de paneles.
PNG_NORTE <- ruta_salidas("afiche", "panel_norte.png")
PNG_VINA  <- ruta_salidas("afiche", "panel_vina.png")

# ---- 5. Fuentes para ragg (gobCL ya esta en system_fonts; Museo Sans no) ----
registrar_fuentes <- function() {
  ff <- RUTAS$fuentes
  try(systemfonts::register_font("Museo Sans",
        plain = file.path(ff, "MuseoSans-300.otf"),
        bold  = file.path(ff, "MuseoSans_500.otf")), silent = TRUE)
  try(systemfonts::register_font("gobCL",
        plain = file.path(ff, "gobCL_Regular.otf"),
        bold  = file.path(ff, "gobCL_Heavy.otf")), silent = TRUE)
}

# ---- 6. Utilidades de datos ----

# Referencia (encargo v6): Puchuncaví 1-20 por latitud N->S estricta. Verifica el
# criterio de orden contra el dato real.
PUCHUNCAVI_REF <- c(
  "Escuela Básica La Laguna", "Jardín Infantil Mi Mundo Feliz", "Colegio Maitencillo",
  "Escuela Básica La Quebrada", "Escuela Básica El Rungue", "Jardín Infantil Los Conejitos",
  "Escuela Horcón", "Jardín Infantil Sirenita", "Escuela Básica El Rincón",
  "Jardín Infantil Semillita de Puchuncaví", "Colegio General José Velásquez Bórquez",
  "Escuela La Chocota", "Escuela Multidéficit Amanecer", "Jardín Infantil Renacer",
  "Escuela Campiche", "Colegio La Greda", "Complejo Educacional Sargento Aldea",
  "Jardín Infantil Caballito de Mar", "Escuela Pucalán", "Escuela Los Maquis")

# Numeracion N->S ESTRICTA por latitud (Fase 1 v6): mas al norte = 1, mas al sur =
# 97. El tipo NO influye en el orden (solo en el color). Empates de latitud
# (improbables) se desempatan por longitud y luego nombre. Verificable.
numerar <- function(est) {
  est <- est |>
    mutate(comuna_chr = as.character(comuna)) |>
    arrange(desc(latitud), desc(longitud), nombre) |>
    mutate(num = row_number(),
           color = unname(COLOR_TIPO[tipo]))
  # numeracion sin huecos/duplicados y estrictamente decreciente en latitud.
  stopifnot(identical(sort(est$num), seq_len(nrow(est))))
  stopifnot(all(diff(est$latitud) <= 0))
  # rangos por comuna se mantienen (las comunas no se solapan en latitud).
  rng <- est |> summarise(lo = min(num), hi = max(num), .by = comuna_chr)
  esperado <- data.frame(
    comuna_chr = COMUNAS_ORDEN,
    lo = c(1, 21, 31, 38), hi = c(20, 30, 37, 97))
  chk <- merge(rng, esperado, by = "comuna_chr", suffixes = c("", "_e"))
  stopifnot(all(chk$lo == chk$lo_e), all(chk$hi == chk$hi_e))
  # el orden N->S reproduce la referencia de Puchuncaví del encargo.
  stopifnot(identical(est$nombre[est$comuna_chr == "Puchuncaví"], PUCHUNCAVI_REF))
  est
}

escapar_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;",  x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# ---- 7. Capa geo: tiles CARTO y ajuste de bbox ----

# Ajusta un bbox 3857 (xmin,xmax,ymin,ymax) al aspect del slot (w/h). Si necesita
# ancho, crece al oeste (mar, para las etiquetas); si alto, crece simetrico.
fit_bbox_3857 <- function(b, aspect, grow_west = TRUE) {
  w <- b[2] - b[1]; h <- b[4] - b[3]; cur <- w / h
  if (cur < aspect) {
    d <- aspect * h - w
    if (grow_west) b[1] <- b[1] - d else { b[1] <- b[1] - d/2; b[2] <- b[2] + d/2 }
  } else {
    d <- w / aspect - h; b[3] <- b[3] - d/2; b[4] <- b[4] + d/2
  }
  b
}

# bbox 4326 (xmin,xmax,ymin,ymax) -> bbox 3857 (xmin,xmax,ymin,ymax).
bbox_a_3857 <- function(b4) {
  poly <- st_as_sfc(st_bbox(c(xmin=b4[1], ymin=b4[3], xmax=b4[2], ymax=b4[4]), crs = 4326))
  as.numeric(st_bbox(st_transform(poly, 3857)))[c(1, 3, 2, 4)]
}

# Carga los limites de las 4 comunas desde el geojson generalizado, con etiqueta
# canonica por match normalizado (sin tildes). Devuelve sf en 4326.
cargar_comunas <- function() {
  todo <- sf::st_read(ruta_insumos("comunas.geojson"), quiet = TRUE)
  col  <- intersect(c("Comuna","comuna","NOM_COMUNA","nombre"), names(todo))[1]
  norm <- function(x) { x <- tolower(trimws(as.character(x)))
    x <- iconv(x, to = "ASCII//TRANSLIT"); gsub("[^a-z ]", "", x) }
  idx <- match(norm(todo[[col]]), norm(COMUNAS_ORDEN))
  sub <- todo[!is.na(idx), ]
  sub$comuna <- COMUNAS_ORDEN[idx[!is.na(idx)]]
  if (is.na(sf::st_crs(sub))) sf::st_crs(sub) <- 4326
  sf::st_transform(sub, 4326)
}

# Contornos comunales como paths en 3857 (geom_path bajo coord_equal). Agrupa por
# anillo (columnas L* de st_coordinates) para no unir poligonos distintos.
comuna_paths <- function(com_sf, comunas) {
  s  <- sf::st_transform(com_sf[com_sf$comuna %in% comunas, ], 3857)
  cc <- sf::st_coordinates(s)
  Ls <- grep("^L", colnames(cc), value = TRUE)
  data.frame(X = cc[, "X"], Y = cc[, "Y"],
             grp = apply(cc[, Ls, drop = FALSE], 1, paste, collapse = "-"))
}

# Descarga tiles CARTO Positron que cubren un bbox 3857; devuelve imagen + extent.
get_carto_3857 <- function(b, zoom) {
  poly <- st_as_sfc(st_bbox(c(xmin = b[1], ymin = b[3], xmax = b[2], ymax = b[4]),
                            crs = 3857))
  tiles <- maptiles::get_tiles(poly, provider = "CartoDB.PositronNoLabels",
                               zoom = zoom, crop = TRUE, cachedir = tempdir())
  arr <- terra::as.array(tiles)
  img <- matrix(grDevices::rgb(arr[, , 1], arr[, , 2], arr[, , 3], maxColorValue = 255),
                nrow = dim(arr)[1])
  list(img = img, e = as.vector(terra::ext(tiles)))
}

# Anti-colision 2D real (encargo v4), en px del PNG. Repulsion de discos
# (radio r, separacion minima 2r+gap) + clamp al marco. Parte de la posicion real y
# desplaza lo minimo. (v7: las zonas de exclusion se eliminaron junto al tile con
# rotulos; la repulsion entre pines se mantiene intacta.)
separar_pines <- function(px, py, r, gap, Wpx, Hpx, iters = 1200) {
  n <- length(px); sep <- 2*r + gap; ox <- px; oy <- py
  for (it in seq_len(iters)) {
    moved <- FALSE
    for (a in 1:(n-1)) for (b in (a+1):n) {
      dx <- px[a]-px[b]; dy <- py[a]-py[b]; d <- sqrt(dx*dx + dy*dy)
      if (d < sep) {
        if (d < 1e-6) { ang <- 2*pi*a/n; dx <- cos(ang); dy <- sin(ang); d <- 1 }
        ph <- (sep-d)/2; ux <- dx/d; uy <- dy/d
        px[a] <- px[a]+ux*ph; py[a] <- py[a]+uy*ph
        px[b] <- px[b]-ux*ph; py[b] <- py[b]-uy*ph; moved <- TRUE
      }
    }
    px <- pmin(pmax(px, r), Wpx-r); py <- pmin(pmax(py, r), Hpx-r)
    if (!moved) break
  }
  list(px = px, py = py, iters = it, desp = sqrt((px-ox)^2 + (py-oy)^2))
}

# Distancia minima entre todos los pares de centros (verificacion de no-solape).
mindist <- function(px, py) {
  n <- length(px); m <- Inf
  for (a in 1:(n-1)) for (b in (a+1):n) {
    d <- sqrt((px[a]-px[b])^2 + (py[a]-py[b])^2); if (d < m) m <- d
  }
  m
}

# Poligonos circulares (radio r en datos) para dibujar pines de tamaño exacto.
circulos <- function(cx, cy, r, fill, id, nseg = 44) {
  ang <- seq(0, 2*pi, length.out = nseg + 1)[-1]
  do.call(rbind, lapply(seq_along(cx), function(i)
    data.frame(X = cx[i] + r*cos(ang), Y = cy[i] + r*sin(ang),
               grp = id[i], fill = fill[i])))
}

# Proyecta etiquetas de comuna (lon/lat) a coordenadas 3857 para geom_text.
etiquetas_xy <- function(et) {
  if (nrow(et) == 0) return(et)
  p <- st_coordinates(st_transform(
    st_as_sf(et, coords = c("lon", "lat"), crs = 4326), 3857))
  et$X <- p[,1]; et$Y <- p[,2]; et
}

# Dibuja un plano: proyecta -> px -> separa (anti-colision 2D) -> datos -> circulos
# + numeros sobre tiles + limites + etiquetas de comuna propias. GATE: si no logra
# no-solape o empuja pines fuera del marco, PARA con numeros (no fuerza).
dibujar_pines <- function(sub, b3, H, tl, com_sf, comunas, etiquetas, out) {
  Wpx <- MAPA_W*ESC; Hpx <- H*ESC; Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
  pc <- st_as_sf(sub, coords = c("longitud", "latitud"), crs = 4326)
  xy <- st_coordinates(st_transform(pc, 3857)); sub$X <- xy[,1]; sub$Y <- xy[,2]
  px <- (sub$X - b3[1])/Xr*Wpx; py <- (b3[4] - sub$Y)/Yr*Hpx
  s  <- separar_pines(px, py, PIN_RADIO_PX, PIN_GAP_PX, Wpx, Hpx)
  dmin  <- mindist(s$px, s$py)
  fuera <- sum(s$px < PIN_RADIO_PX | s$px > Wpx-PIN_RADIO_PX |
               s$py < PIN_RADIO_PX | s$py > Hpx-PIN_RADIO_PX)
  if (dmin < 2*PIN_RADIO_PX - 0.5 || fuera > 0)
    stop(sprintf(paste0("GATE [%s]: min_dist=%.1f px (requerido %.0f) o pines fuera ",
      "de marco=%d. La anti-colision con PIN_RADIO_PX=%.1f no cabe; bajar el radio ",
      "o usar mini-inset para el cluster denso (decision del usuario)."),
      out, dmin, 2*PIN_RADIO_PX, fuera, PIN_RADIO_PX))
  cxd <- b3[1] + s$px/Wpx*Xr; cyd <- b3[4] - s$py/Hpx*Yr
  rdat <- PIN_RADIO_PX * Xr/Wpx
  poly <- circulos(cxd, cyd, rdat, sub$color, sub$num)
  bord <- comuna_paths(com_sf, comunas)
  et   <- etiquetas_xy(etiquetas)
  g <- ggplot() +
    annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]) +
    geom_path(data = bord, aes(X, Y, group = grp),
              color = COL_BORDE_COMUNA, linewidth = 0.5, alpha = 0.85) +
    geom_polygon(data = poly, aes(X, Y, group = grp, fill = fill),
                 color = "white", linewidth = 0.5) +
    scale_fill_identity() +
    geom_text(data = data.frame(X = cxd, Y = cyd, num = sub$num),
              aes(X, Y, label = num), color = "white", family = "gobCL",
              fontface = "bold", size = PIN_FONT) +
    geom_text(data = et, aes(X, Y, label = nom), color = COLOR_COMUNA,
              family = "gobCL", fontface = "bold", size = LABEL_COMUNA_FONT) +
    coord_equal(xlim = c(b3[1], b3[2]), ylim = c(b3[3], b3[4]), expand = FALSE) +
    theme_void()
  ragg::agg_png(out, width = Wpx, height = Hpx, units = "px", res = 72*ESC, background = "white")
  print(g); grDevices::dev.off()
  list(n = nrow(sub), dmin = dmin, desp_max = max(s$desp))
}

# ---- 8. Render del panel norte (pines grandes, anti-colision 2D, sin solape) ----
render_panel_norte <- function(est, com_sf) {
  chicas <- est |> filter(comuna_chr %in% COMUNAS_CHICAS)
  pc <- st_as_sf(chicas, coords = c("longitud", "latitud"), crs = 4326)
  bb <- as.numeric(st_bbox(pc))                                  # xmin ymin xmax ymax
  b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)
  b3 <- bbox_a_3857(c(b4[1], b4[3], b4[2], b4[4]))               # -> xmin xmax ymin ymax
  b3 <- fit_bbox_3857(b3, MAPA_W / NORTE_H, grow_west = FALSE)
  tl <- get_carto_3857(b3, zoom = 12)
  et <- ETIQUETAS_COMUNA[ETIQUETAS_COMUNA$panel == "norte", ]
  dibujar_pines(chicas, b3, NORTE_H, tl, com_sf, COMUNAS_CHICAS, et, PNG_NORTE)
}

# ---- 9. Render del inset Vina (🔒-2) ----
render_panel_vina <- function(est, com_sf) {
  vina <- est |> filter(comuna_chr == COMUNA_INSET)
  pc <- st_as_sf(vina, coords = c("longitud", "latitud"), crs = 4326)
  bb <- as.numeric(st_bbox(pc))
  b4 <- c(bb[1]-0.012, bb[2]-0.010, bb[3]+0.012, bb[4]+0.010)
  b3 <- bbox_a_3857(c(b4[1], b4[3], b4[2], b4[4]))
  b3 <- fit_bbox_3857(b3, MAPA_W / VINA_H, grow_west = FALSE)
  tl <- get_carto_3857(b3, zoom = 13)
  et <- ETIQUETAS_COMUNA[ETIQUETAS_COMUNA$panel == "vina", ]
  dibujar_pines(vina, b3, VINA_H, tl, com_sf, COMUNA_INSET, et, PNG_VINA)
}

# ---- 10. Chrome HTML (header, indice N->S, leyenda, logo) ----
data_uri <- function(ruta, mime) {
  if (!file.exists(ruta)) { warning("No existe asset: ", ruta, call. = FALSE); return("") }
  paste0("data:", mime, ";base64,", base64enc::base64encode(ruta))
}
bloque_fontface <- function() {
  ff <- function(fam, peso, archivo) {
    uri <- data_uri(file.path(RUTAS$fuentes, archivo), "font/otf")
    if (identical(uri, "")) return("")
    glue("@font-face{{font-family:'{fam}';src:url({uri}) format('opentype');font-weight:{peso};font-display:swap}}")
  }
  piezas <- c(ff("gobCL", 900, "gobCL_Heavy.otf"), ff("gobCL", 400, "gobCL_Regular.otf"),
              ff("Museo Sans", 300, "MuseoSans-300.otf"), ff("Museo Sans", 500, "MuseoSans_500.otf"))
  paste(piezas[piezas != ""], collapse = "\n")
}

# Una fila del indice: dot de color por tipo + numero + nombre + RBD (sin truncar).
fila_indice <- function(num, nombre, rbd, color) {
  glue('<div style="display:flex;align-items:baseline;gap:6px;padding:1px 0;break-inside:avoid">
<span style="width:8px;height:8px;border-radius:50%;background:{color};flex:none;transform:translateY(1px)"></span>
<span style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:{INDICE_FONT}px;color:{TOKENS$tinta_fuerte};min-width:17px;text-align:right">{num}</span>
<span style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:{INDICE_FONT}px;line-height:1.2;color:{TOKENS$tinta_media1}">{escapar_html(nombre)} <span style="color:{TOKENS$muted}">(RBD {rbd})</span></span>
</div>')
}
seccion_indice <- function(est, comuna_nom, columnas = 1) {
  # filtra por el nombre de comuna; .env evita el data-masking con la columna 'comuna'.
  sub <- est |> filter(comuna_chr == .env$comuna_nom) |> arrange(num)
  filas <- vapply(seq_len(nrow(sub)), function(i)
    fila_indice(sub$num[i], sub$nombre[i], sub$rbd[i], sub$color[i]), character(1))
  cols_css <- if (columnas > 1)
    glue("column-count:{columnas};column-gap:14px;") else ""
  glue('<div>
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:{INDICE_FONT_HDR}px;color:{TOKENS$ciruela};border-bottom:1px solid {TOKENS$linea2};padding-bottom:3px;margin-bottom:5px">{comuna_nom} <span style="color:{TOKENS$muted};font-weight:400">({nrow(sub)})</span></div>
<div style="{cols_css}">{paste(filas, collapse="")}</div>
</div>')
}
construir_indice <- function(est) {
  paste(
    seccion_indice(est, "Puchuncaví",   1),
    seccion_indice(est, "Quintero",     1),
    seccion_indice(est, "Concón",       1),
    seccion_indice(est, "Viña del Mar", 2),
    collapse = "\n")
}
construir_leyenda <- function(est) {
  items <- vapply(seq_len(nrow(TIPOS)), function(i) {
    t <- TIPOS[i, ]; n <- sum(est$tipo == t$key); col <- COLOR_TIPO[[t$key]]
    glue('<div style="display:flex;align-items:center;gap:7px">
<span style="width:11px;height:11px;border-radius:50%;background:{col};flex:none"></span>
<span style="font-family:\'Museo Sans\',sans-serif;font-weight:500;font-size:10.5px;color:{TOKENS$tinta_media1}">{t$label} <span style="color:{TOKENS$muted};font-weight:300">({n})</span></span>
</div>')
  }, character(1))
  glue('<div style="display:flex;flex-wrap:wrap;gap:6px 16px">{paste(items, collapse="")}</div>')
}

generar_html <- function(est) {
  logo_uri <- data_uri(RUTAS$logo, "image/png")
  logo_tag <- if (identical(logo_uri, ""))
    glue('<div style="height:120px;width:190px;display:flex;align-items:center;justify-content:center;border:1px dashed {TOKENS$linea2};color:{TOKENS$muted};font-size:12px">[logo SLEP]</div>')
  else glue('<img src="{logo_uri}" style="height:120px;width:auto;display:block"/>')
  norte_uri <- data_uri(PNG_NORTE, "image/png")
  vina_uri  <- data_uri(PNG_VINA,  "image/png")
  t <- TOKENS

  glue('<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><style>
{bloque_fontface()}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{margin:0;background:{t$pagina}}}
@page{{size:{A0_W_MM}mm {A0_H_MM}mm;margin:0}}
</style></head><body>
<div style="zoom:{ZOOM};width:{LIENZO$ancho}px;height:{LIENZO$alto}px;background:{t$papel};margin:0 auto;display:flex;flex-direction:column;font-family:\'Museo Sans\',sans-serif">

<div style="height:{LIENZO$header_h}px;flex:none;display:flex;align-items:center;gap:30px;padding:0 48px;border-bottom:2px solid {t$ciruela}">
{logo_tag}
<div style="width:1px;height:96px;background:{t$linea2}"></div>
<div>
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:34px;letter-spacing:-.01em;color:{t$ciruela};line-height:1.04">Mapa de establecimientos educacionales</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:15px;color:{t$bajada};margin-top:5px">SLEP Costa Central · Puchuncaví · Quintero · Concón · Viña del Mar · 97 establecimientos</div>
</div>
</div>

<div style="flex:1;display:flex;min-height:0">
<aside style="width:{LIENZO$lista_w}px;flex:none;border-right:1px solid {t$linea1};padding:14px 22px;display:flex;flex-direction:column;overflow:hidden">
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:16px;color:{t$tinta_fuerte};margin-bottom:2px">Índice de establecimientos</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:10.5px;line-height:1.35;color:{t$bajada};margin-bottom:7px">Numeración geográfica norte→sur; el número del mapa es el del índice.</div>
<div style="margin-bottom:9px;padding-bottom:9px;border-bottom:1px solid {t$linea2}">{construir_leyenda(est)}</div>
<div style="flex:1;display:flex;flex-direction:column;justify-content:space-between;overflow:hidden">{construir_indice(est)}</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:9px;line-height:1.4;color:{t$muted};margin-top:10px;padding-top:7px;border-top:1px solid {t$linea3}">Desarrollado por el Área de Monitoreo a partir de datos de OpenStreetMap, CARTO (Positron), los límites comunales publicados por la Biblioteca del Congreso Nacional de Chile (BCN) y el maestro de establecimientos del SLEP Costa Central, de elaboración propia.</div>
</aside>

<div style="flex:1;min-width:0;padding:{PAD_MAPA}px;display:flex;flex-direction:column;gap:{GAP_PANEL}px">
<div style="position:relative;width:100%;height:{NORTE_H}px;border:1px solid {t$linea2};border-radius:8px;overflow:hidden">
<div style="position:absolute;top:8px;left:10px;z-index:2;font-family:\'gobCL\',sans-serif;font-weight:900;font-size:13px;color:{t$ciruela};background:rgba(255,255,255,.82);padding:2px 8px;border-radius:5px">Puchuncaví · Quintero · Concón</div>
<img src="{norte_uri}" style="display:block;width:100%;height:100%;object-fit:cover"/>
</div>
<div style="position:relative;width:100%;height:{VINA_H}px;border:1px solid {t$linea2};border-radius:8px;overflow:hidden">
<div style="position:absolute;top:8px;left:10px;z-index:2;font-family:\'gobCL\',sans-serif;font-weight:900;font-size:13px;color:{t$ciruela};background:rgba(255,255,255,.82);padding:2px 8px;border-radius:5px">Viña del Mar · ampliación (60)</div>
<img src="{vina_uri}" style="display:block;width:100%;height:100%;object-fit:cover"/>
</div>
</div>
</div>
</div>
</body></html>')
}

# ---- 11. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  entrada <- ruta_salidas("establecimientos_proyectados.rds")
  if (!file.exists(entrada)) stop("Falta 32. Corre run_all(to = 2) primero.")
  est <- readRDS(entrada)
  log_msg(sprintf("Generando afiche con %d establecimientos...", nrow(est)),
          origen = "33_afiche")

  registrar_fuentes()
  est <- numerar(est)
  log_msg("Numeracion N->S 1..97 verificada (rangos por comuna).", origen = "33_afiche")

  dir.create(RUTAS$salidas_afiche, showWarnings = FALSE, recursive = TRUE)
  com_sf <- cargar_comunas()
  log_msg(sprintf("Limites comunales cargados: %d comunas.", nrow(com_sf)),
          origen = "33_afiche")
  rn <- render_panel_norte(est, com_sf)
  log_msg(sprintf("Panel norte: %d pines (min_dist=%.1f px >= %.0f; desp max=%.0f px).",
                  rn$n, rn$dmin, 2*PIN_RADIO_PX, rn$desp_max), origen = "33_afiche")
  rv <- render_panel_vina(est, com_sf)
  log_msg(sprintf("Inset Vina: %d pines (min_dist=%.1f px >= %.0f; desp max=%.0f px).",
                  rv$n, rv$dmin, 2*PIN_RADIO_PX, rv$desp_max), origen = "33_afiche")

  html <- generar_html(est)
  salida <- ruta_salidas("afiche", "mapa_establecimientos.html")
  tmp <- paste0(salida, ".tmp")
  writeLines(html, tmp, useBytes = TRUE)
  file.rename(tmp, salida)
  log_msg(sprintf("Afiche A0 generado en %s (ESC=%.2f, DPI_A0=%d, ZOOM=%.3f)",
                  salida, ESC, DPI_A0, ZOOM), origen = "33_afiche")

  # ---- Exportar a PDF A0 vertical con fuentes incrustadas (texto editable) ----
  pdf_out <- ruta_salidas("afiche", "mapa_establecimientos.pdf")
  in_pulg <- function(mm) mm / 25.4
  ok <- tryCatch({
    pagedown::chrome_print(
      input = salida, output = pdf_out, verbose = 0,
      options = list(
        paperWidth = in_pulg(A0_W_MM), paperHeight = in_pulg(A0_H_MM),
        marginTop = 0, marginBottom = 0, marginLeft = 0, marginRight = 0,
        printBackground = TRUE, preferCSSPageSize = TRUE))
    TRUE
  }, error = function(e) { log_msg(paste("chrome_print fallo:", conditionMessage(e)),
                                   nivel = "ERROR", origen = "33_afiche"); FALSE })
  if (ok) {
    mb <- round(file.info(pdf_out)$size / 1e6, 1)
    log_msg(sprintf("PDF A0 generado en %s (%.1f MB)", pdf_out, mb), origen = "33_afiche")
    # Verificacion de editabilidad: texto seleccionable + fuentes incrustadas.
    if (requireNamespace("pdftools", quietly = TRUE)) {
      ps <- pdftools::pdf_pagesize(pdf_out)
      log_msg(sprintf("PDF pagesize: %.0f x %.0f pt (A0 = 2384 x 3370 pt)",
                      ps$width[1], ps$height[1]), origen = "33_afiche")
      fn <- pdftools::pdf_fonts(pdf_out)
      log_msg(sprintf("Fuentes incrustadas: %d/%d (embedded). Familias: %s",
                      sum(fn$embedded), nrow(fn),
                      paste(unique(fn$name), collapse = ", ")), origen = "33_afiche")
    } else {
      log_msg("Instala 'pdftools' para verificar texto/fuentes del PDF.",
              nivel = "WARN", origen = "33_afiche")
    }
  }
}
