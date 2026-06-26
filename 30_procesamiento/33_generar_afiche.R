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
                    "systemfonts", "base64enc", "glue"))

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
ESC        <- 2L              # factor de render (retina)

# Colores de pin por tipo (encargo v2). El indice y la leyenda usan los mismos.
COLOR_TIPO <- c(jardin = "#6a8a3a", basica = "#2d5f8a", liceo = "#c8732e",
                especial = "#7a4a8a", adultos = "#555555")
# Borde comunal sutil pero visible sobre CARTO Positron.
COL_BORDE_COMUNA <- "#7a7a7a"

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

# Numeracion oficial N->S (Fase 1): comuna (N->S) -> tipo -> nombre. Verificable.
numerar <- function(est) {
  est <- est |>
    mutate(
      comuna_chr = as.character(comuna),
      comuna_f   = factor(comuna_chr, levels = COMUNAS_ORDEN),
      tipo_f     = factor(tipo, levels = TIPO_ORDEN)
    ) |>
    arrange(comuna_f, tipo_f, nombre) |>
    mutate(num = row_number(),
           color = unname(COLOR_TIPO[tipo]))
  # 🔒-5: rangos por comuna exactos y sin huecos/duplicados.
  stopifnot(identical(sort(est$num), seq_len(nrow(est))))
  rng <- est |> summarise(lo = min(num), hi = max(num), .by = comuna_chr)
  esperado <- data.frame(
    comuna_chr = COMUNAS_ORDEN,
    lo = c(1, 21, 31, 38), hi = c(20, 30, 37, 97))
  chk <- merge(rng, esperado, by = "comuna_chr", suffixes = c("", "_e"))
  stopifnot(all(chk$lo == chk$lo_e), all(chk$hi == chk$hi_e))
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
  tiles <- maptiles::get_tiles(poly, provider = "CartoDB.Positron",
                               zoom = zoom, crop = TRUE, cachedir = tempdir())
  arr <- terra::as.array(tiles)
  img <- matrix(grDevices::rgb(arr[, , 1], arr[, , 2], arr[, , 3], maxColorValue = 255),
                nrow = dim(arr)[1])
  list(img = img, e = as.vector(terra::ext(tiles)))
}

# Dispersion leve (declustering radial) por grupo: separa puntos encimados a una
# distancia visual minima conservando la ubicacion real lo mas posible.
decluster <- function(df, dmin, por_comuna = TRUE, iters = 140) {
  X <- df$X; Y <- df$Y
  grupos <- if (por_comuna) split(seq_len(nrow(df)), df$comuna_chr)
            else list(seq_len(nrow(df)))
  for (idx in grupos) {
    k <- length(idx); if (k < 2) next
    for (t in seq_len(k)) {                    # semilla determinista coincidentes
      i <- idx[order(df$num[idx])[t]]
      X[i] <- X[i] + cos(2*pi*t/k) * dmin * 0.01
      Y[i] <- Y[i] + sin(2*pi*t/k) * dmin * 0.01
    }
    for (it in seq_len(iters)) {
      moved <- FALSE
      for (a in 1:(k-1)) for (b in (a+1):k) {
        i <- idx[a]; j <- idx[b]
        dx <- X[i]-X[j]; dy <- Y[i]-Y[j]; d <- sqrt(dx*dx + dy*dy)
        if (d < dmin && d > 1e-9) {
          push <- (dmin - d)/2
          X[i] <- X[i]+dx/d*push; Y[i] <- Y[i]+dy/d*push
          X[j] <- X[j]-dx/d*push; Y[j] <- Y[j]-dy/d*push; moved <- TRUE
        }
      }
      if (!moved) break
    }
  }
  df$X <- X; df$Y <- Y; df
}

# ---- 8. Render del panel norte (pines numerados sobre CARTO + limites) ----
# Encargo v2: SIN etiquetas de texto ni leader lines. Solo tiles, contornos
# comunales y pines numerados coloreados por tipo (con dispersion leve).
render_panel_norte <- function(est, com_sf) {
  chicas <- est |> filter(comuna_chr %in% COMUNAS_CHICAS)
  pc <- st_as_sf(chicas, coords = c("longitud", "latitud"), crs = 4326)

  # bbox centrado en las 3 comunas chicas con margen razonable (ya no se reserva
  # franja oceanica para etiquetas: el mapa llena el slot).
  bb <- as.numeric(st_bbox(pc))                                  # xmin ymin xmax ymax
  b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)
  b3 <- bbox_a_3857(c(b4[1], b4[3], b4[2], b4[4]))               # -> xmin xmax ymin ymax
  b3 <- fit_bbox_3857(b3, MAPA_W / NORTE_H, grow_west = FALSE)
  tl <- get_carto_3857(b3, zoom = 12)
  Xr <- b3[2]-b3[1]

  # puntos a 3857 + dispersion leve (sin lineas que conecten nada).
  xy <- st_coordinates(st_transform(pc, 3857))
  chicas$X <- xy[,1]; chicas$Y <- xy[,2]
  chicas <- decluster(chicas, dmin = 0.013 * Xr)

  bordes <- comuna_paths(com_sf, COMUNAS_CHICAS)

  g <- ggplot() +
    annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]) +
    geom_path(data = bordes, aes(X, Y, group = grp),
              color = COL_BORDE_COMUNA, linewidth = 0.5, alpha = 0.85) +
    geom_point(data = chicas, aes(X, Y), shape = 21, fill = chicas$color,
               color = "white", size = 4.6, stroke = 1) +
    geom_text(data = chicas, aes(X, Y, label = num), color = "white",
              family = "gobCL", fontface = "bold", size = 2.5) +
    coord_equal(xlim = c(b3[1], b3[2]), ylim = c(b3[3], b3[4]), expand = FALSE) +
    theme_void()

  ragg::agg_png(PNG_NORTE, width = MAPA_W*ESC, height = NORTE_H*ESC,
                units = "px", res = 72*ESC, background = "white")
  print(g); grDevices::dev.off()
  list(pines = nrow(chicas))
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
  Xr <- b3[2]-b3[1]

  xy <- st_coordinates(st_transform(pc, 3857))
  vina$X <- xy[,1]; vina$Y <- xy[,2]
  vina$comuna_chr <- "v"
  vina <- decluster(vina, dmin = 0.022 * Xr, por_comuna = FALSE)

  bordes <- comuna_paths(com_sf, COMUNA_INSET)

  g <- ggplot() +
    annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]) +
    geom_path(data = bordes, aes(X, Y, group = grp),
              color = COL_BORDE_COMUNA, linewidth = 0.5, alpha = 0.85) +
    geom_point(data = vina, aes(X, Y), shape = 21, fill = vina$color,
               color = "white", size = 5.2, stroke = 1.1) +
    geom_text(data = vina, aes(X, Y, label = num), color = "white",
              family = "gobCL", fontface = "bold", size = 2.7) +
    coord_equal(xlim = c(b3[1], b3[2]), ylim = c(b3[3], b3[4]), expand = FALSE) +
    theme_void()

  ragg::agg_png(PNG_VINA, width = MAPA_W*ESC, height = VINA_H*ESC,
                units = "px", res = 72*ESC, background = "white")
  print(g); grDevices::dev.off()
  invisible(NULL)
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
<span style="width:7px;height:7px;border-radius:50%;background:{color};flex:none;transform:translateY(1px)"></span>
<span style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:10px;color:{TOKENS$tinta_fuerte};min-width:15px;text-align:right">{num}</span>
<span style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:10px;line-height:1.2;color:{TOKENS$tinta_media1}">{escapar_html(nombre)} <span style="color:{TOKENS$muted}">(RBD {rbd})</span></span>
</div>')
}
seccion_indice <- function(est, comuna_nom, columnas = 1) {
  # filtra por el nombre de comuna; .env evita el data-masking con la columna 'comuna'.
  sub <- est |> filter(comuna_chr == .env$comuna_nom) |> arrange(num)
  filas <- vapply(seq_len(nrow(sub)), function(i)
    fila_indice(sub$num[i], sub$nombre[i], sub$rbd[i], sub$color[i]), character(1))
  cols_css <- if (columnas > 1)
    glue("column-count:{columnas};column-gap:14px;") else ""
  glue('<div style="margin-bottom:9px">
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:12.5px;color:{TOKENS$ciruela};border-bottom:1px solid {TOKENS$linea2};padding-bottom:2px;margin-bottom:4px">{comuna_nom} <span style="color:{TOKENS$muted};font-weight:400">({nrow(sub)})</span></div>
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
@page{{size:{LIENZO$ancho}px {LIENZO$alto}px;margin:0}}
</style></head><body>
<div style="width:{LIENZO$ancho}px;height:{LIENZO$alto}px;background:{t$papel};margin:0 auto;display:flex;flex-direction:column;font-family:\'Museo Sans\',sans-serif">

<div style="height:{LIENZO$header_h}px;flex:none;display:flex;align-items:center;gap:30px;padding:0 48px;border-bottom:2px solid {t$ciruela}">
{logo_tag}
<div style="width:1px;height:96px;background:{t$linea2}"></div>
<div>
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:34px;letter-spacing:-.01em;color:{t$ciruela};line-height:1.04">Mapa de establecimientos educacionales</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:15px;color:{t$bajada};margin-top:5px">SLEP Costa Central · Puchuncaví · Quintero · Concón · Viña del Mar · 97 establecimientos</div>
</div>
</div>

<div style="flex:1;display:flex;min-height:0">
<aside style="width:{LIENZO$lista_w}px;flex:none;border-right:1px solid {t$linea1};padding:18px 22px;display:flex;flex-direction:column;overflow:hidden">
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:16px;color:{t$tinta_fuerte};margin-bottom:3px">Índice de establecimientos</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:10.5px;line-height:1.4;color:{t$bajada};margin-bottom:9px">Numeración norte→sur. Cada número del mapa corresponde a un establecimiento; el índice es de respaldo.</div>
<div style="margin-bottom:9px;padding-bottom:9px;border-bottom:1px solid {t$linea2}">{construir_leyenda(est)}</div>
<div style="flex:1;overflow:hidden">{construir_indice(est)}</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:8.5px;color:{t$muted};margin-top:8px;padding-top:6px;border-top:1px solid {t$linea3}">Fondo cartográfico © OpenStreetMap · © CARTO (Positron). Establecimientos: maestro SLEP Costa Central.</div>
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
  res <- render_panel_norte(est, com_sf)
  log_msg(sprintf("Panel norte: %d pines numerados (sin etiquetas ni lineas).",
                  res$pines), origen = "33_afiche")
  render_panel_vina(est, com_sf)
  log_msg("Inset Vina (60 pines) renderizado.", origen = "33_afiche")

  html <- generar_html(est)
  salida <- ruta_salidas("afiche", "mapa_establecimientos.html")
  tmp <- paste0(salida, ".tmp")
  writeLines(html, tmp, useBytes = TRUE)
  file.rename(tmp, salida)
  log_msg(sprintf("Afiche generado en %s", salida), origen = "33_afiche")
  log_msg("Para exportar a PDF: pagedown::chrome_print(<html>, <pdf>).",
          origen = "33_afiche")
}
