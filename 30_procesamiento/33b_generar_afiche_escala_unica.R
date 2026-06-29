# =============================================================================
# 33b_generar_afiche_escala_unica.R
# Proposito : SEGUNDA version del afiche (variante "escala unica"). Las 4 comunas en
#             UN solo panel a escala unica continua, Viña IN SITU PURO (separar_pines,
#             sin leaders ni punto-ancla), pin GLOBAL a radio 60% del de produccion,
#             fuente del numero al maximo que cabe (ratio glifo/diametro ~0.72).
#             Producto ADICIONAL: el afiche original con inset (33) se conserva
#             byte-identico y sus salidas no se sobrescriben.
# Arquitectura: source(33, local=TRUE) en un new.env() para REUTILIZAR sus funciones y
#             constantes SIN editar 33 y SIN disparar su flujo principal (verificado:
#             el guard de 33 usa identical(environment(),globalenv()); con local=TRUE
#             ese identical es FALSO y sys.nframe()>0, asi que NO corre).
# Insumos   : 40_salidas/establecimientos_proyectados.rds (de 32). comunas.geojson.
#             Tiles CARTO PositronNoLabels. fuentes/*.otf, logo.
# Salidas   : 40_salidas/afiche/mapa_establecimientos_escala_unica.html
#             40_salidas/afiche/mapa_establecimientos_escala_unica.pdf (A0)
#             40_salidas/afiche/panel_escala_unica.png (intermedio; gitignored)
# NO cableado a 00_run_all (orquestador intocado): script ejecutable independiente.
# Autor     : equipo SLEP Costa Central — Fecha: 2026-06-28
# =============================================================================

# ---- 1. Reuso de 33 sin ejecutar su flujo ni editarlo ----
e <- new.env()
source(here::here("30_procesamiento", "33_generar_afiche.R"), local = e)
stopifnot(is.function(e$separar_pines), is.function(e$circulos),
          is.function(e$comuna_paths), is.function(e$get_carto_3857),
          is.function(e$fit_bbox_3857), is.function(e$bbox_a_3857),
          is.function(e$numerar), is.function(e$cargar_comunas),
          is.function(e$etiquetas_pct), is.function(e$etiquetas_html),
          is.function(e$construir_indice), is.function(e$construir_leyenda),
          is.function(e$bloque_fontface), is.function(e$data_uri),
          is.function(e$mindist))

# ---- 2. Overrides de la variante (lo unico propio; el resto se reutiliza) ----
FRAC_RADIO  <- 0.60                       # pin GLOBAL a 60% del PIN_RADIO_PX de 33
RATIO_GLIFO <- 0.72                       # "97" ~72% del diametro (max legible)
UNICO_H     <- e$ALTO_BODY                # panel unico ocupa todo el body (= NORTE+GAP+VINA)
ZOOM_TILE   <- 12L                        # zoom de tiles para el panel unico
# REUSAR_PNG=TRUE (via env) reutiliza panel_escala_unica.png existente y NO lo regenera:
# recalcula solo la geometria (b3 para las etiquetas) y reescribe HTML+PDF. Util cuando
# cambian las etiquetas/chrome pero los pines no se mueven. Default FALSE (render completo).
REUSAR_PNG  <- isTRUE(as.logical(Sys.getenv("REUSAR_PNG", "FALSE")))

# Offset por comuna (en puntos porcentuales) sobre la posicion que devuelve
# e$etiquetas_pct (ancla = centroide geografico). Capa ADITIVA propia de 33b: NO toca
# e$etiquetas_pct ni 33. Solo mueve la tarjeta HTML; el PNG de pines no cambia.
# Calibrado contra el render real (cajas de texto vs los 97 circulos de pin):
#  - Viña: su centroide cae sobre el cluster denso (tapaba el pin 56); se baja bajo el
#    cluster, lo mas al SW que permite el ancho del rotulo (clearance +18.6 px al pin 96).
#  - Puchuncaví/Quintero/Concón: ya despejadas (cl 26/58/13 px). NO se mueven: el
#    desplazamiento NW de Puchuncaví hacia la costa choca con sus propios pines (pin 7).
OFFSET_ETIQUETAS_PCT <- list(
  "Puchuncaví"   = c(dx =  0.0, dy =  0.0),
  "Quintero"     = c(dx =  0.0, dy =  0.0),
  "Concón"       = c(dx =  0.0, dy =  0.0),
  "Viña del Mar" = c(dx = -1.5, dy =  9.0)
)

# Tamaño de fuente del numero al MAXIMO que cabe (misma metrica de glifo que el sondeo
# 03_escala_unica_tamano_pin/scripts/preview_tamano_pin.R): mide el ancho real de "97"
# en gobCL Heavy y resuelve el 'size' de geom_text para llenar RATIO_GLIFO del diametro.
fit_font_size <- function(ratio, diam_px, ESC) {
  ragg::agg_capture(width = 4, height = 4, units = "in", res = 72 * ESC)
  w_ref_in <- grid::convertWidth(grid::grobWidth(grid::textGrob(
    "97", gp = grid::gpar(fontfamily = "gobCL", fontface = "bold", fontsize = 100))),
    "inches", valueOnly = TRUE)
  invisible(grDevices::dev.off())
  target_w_in <- (ratio * diam_px) / (72 * ESC)
  FS <- 100 * target_w_in / w_ref_in        # fontsize grid (pt)
  FS / (72.27 / 25.4)                        # -> 'size' de geom_text
}

# ---- 3. Render del panel unico (Viña in situ; sin gate de aborto: a 60% no se dispara) ----
render_panel_unico <- function(est, com_sf, out) {
  RADIO <- FRAC_RADIO * e$PIN_RADIO_PX
  GAP   <- e$PIN_GAP_PX                     # gap fijo (igual que el sondeo aprobado)
  Wpx <- e$MAPA_W * e$ESC; Hpx <- UNICO_H * e$ESC
  pc <- sf::st_as_sf(est, coords = c("longitud", "latitud"), crs = 4326)
  bb <- as.numeric(sf::st_bbox(pc))                              # xmin ymin xmax ymax
  b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)    # mismo pad que render_panel_*
  b3 <- e$bbox_a_3857(c(b4[1], b4[3], b4[2], b4[4]))
  b3 <- e$fit_bbox_3857(b3, e$MAPA_W / UNICO_H, grow_west = FALSE)
  Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
  xy <- sf::st_coordinates(sf::st_transform(pc, 3857)); est$X <- xy[,1]; est$Y <- xy[,2]
  px <- (est$X - b3[1])/Xr*Wpx; py <- (b3[4] - est$Y)/Yr*Hpx
  s <- e$separar_pines(px, py, RADIO, GAP, Wpx, Hpx)             # anti-colision 2D sobre los 97
  dmin  <- e$mindist(s$px, s$py)
  fuera <- sum(s$px < RADIO | s$px > Wpx-RADIO | s$py < RADIO | s$py > Hpx-RADIO)
  font_size <- fit_font_size(RATIO_GLIFO, 2*RADIO, e$ESC)
  if (REUSAR_PNG && file.exists(out)) {
    log_msg(sprintf("[escala unica] REUSAR_PNG: se reutiliza %s (no se regenera el mapa).", out),
            origen = "33b_escala_unica")
  } else {
    tl <- e$get_carto_3857(b3, zoom = ZOOM_TILE)
    cxd <- b3[1] + s$px/Wpx*Xr; cyd <- b3[4] - s$py/Hpx*Yr
    rdat <- RADIO * Xr/Wpx
    poly <- e$circulos(cxd, cyd, rdat, est$color, est$num)
    bord <- e$comuna_paths(com_sf, COMUNAS_ORDEN)
    g <- ggplot() +
      annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]) +
      geom_path(data = bord, aes(X, Y, group = grp),
                color = e$COL_BORDE_COMUNA, linewidth = 0.5, alpha = 0.85) +
      geom_polygon(data = poly, aes(X, Y, group = grp, fill = fill),
                   color = "white", linewidth = 0.5) +
      scale_fill_identity() +
      geom_text(data = data.frame(X = cxd, Y = cyd, num = est$num),
                aes(X, Y, label = num), color = "white", family = "gobCL",
                fontface = "bold", size = font_size) +
      coord_equal(xlim = c(b3[1], b3[2]), ylim = c(b3[3], b3[4]), expand = FALSE) +
      theme_void()
    ragg::agg_png(out, width = Wpx, height = Hpx, units = "px", res = 72*e$ESC, background = "white")
    print(g); grDevices::dev.off()
  }
  list(n = nrow(est), dmin = dmin, fuera = fuera, desp_max = max(s$desp),
       b3 = b3, font_size = font_size, radio = RADIO, Wpx = Wpx, Hpx = Hpx)
}

# ---- 4. HTML de panel unico (reutiliza TODO el chrome de 33; solo cambia el layout) ----
generar_html_unico <- function(est, etq, png_unico) {
  t <- TOKENS
  logo_uri <- e$data_uri(RUTAS$logo, "image/png")
  logo_tag <- if (identical(logo_uri, ""))
    glue('<div style="height:120px;width:190px;display:flex;align-items:center;justify-content:center;border:1px dashed {t$linea2};color:{t$muted};font-size:12px">[logo SLEP]</div>')
  else glue('<img src="{logo_uri}" style="height:120px;width:auto;display:block"/>')
  mapa_uri <- e$data_uri(png_unico, "image/png")

  glue('<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><style>
{e$bloque_fontface()}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{margin:0;background:{t$pagina}}}
@page{{size:{e$A0_W_MM}mm {e$A0_H_MM}mm;margin:0}}
</style></head><body>
<div style="zoom:{e$ZOOM};width:{LIENZO$ancho}px;height:{LIENZO$alto}px;background:{t$papel};margin:0 auto;display:flex;flex-direction:column;font-family:\'Museo Sans\',sans-serif">

<div style="height:{LIENZO$header_h}px;flex:none;display:flex;align-items:center;gap:30px;padding:0 48px;border-bottom:2px solid {t$ciruela}">
{logo_tag}
<div style="width:1px;height:96px;background:{t$linea2}"></div>
<div>
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:34px;letter-spacing:-.01em;color:{t$ciruela};line-height:1.04">Mapa de establecimientos educacionales</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:15px;color:{t$bajada};margin-top:5px">SLEP Costa Central · Puchuncaví · Quintero · Concón · Viña del Mar · 97 establecimientos · escala única</div>
</div>
</div>

<div style="flex:1;display:flex;min-height:0">
<aside style="width:{LIENZO$lista_w}px;flex:none;border-right:1px solid {t$linea1};padding:14px 22px;display:flex;flex-direction:column;overflow:hidden">
<div style="font-family:\'gobCL\',sans-serif;font-weight:900;font-size:16px;color:{t$tinta_fuerte};margin-bottom:2px">Índice de establecimientos</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:10.5px;line-height:1.35;color:{t$bajada};margin-bottom:7px">Numeración geográfica norte→sur; el número del mapa es el del índice.</div>
<div style="margin-bottom:9px;padding-bottom:9px;border-bottom:1px solid {t$linea2}">{e$construir_leyenda(est)}</div>
<div style="flex:1;display:flex;flex-direction:column;justify-content:space-between;overflow:hidden">{e$construir_indice(est)}</div>
<div style="font-family:\'Museo Sans\',sans-serif;font-weight:300;font-size:9px;line-height:1.4;color:{t$muted};margin-top:10px;padding-top:7px;border-top:1px solid {t$linea3}">Desarrollado por el Área de Monitoreo a partir de datos de OpenStreetMap, CARTO (Positron), los límites comunales publicados por la Biblioteca del Congreso Nacional de Chile (BCN) y el maestro de establecimientos del SLEP Costa Central, de elaboración propia.</div>
</aside>

<div style="flex:1;min-width:0;padding:{e$PAD_MAPA}px;display:flex;flex-direction:column">
<div style="position:relative;width:100%;height:{UNICO_H}px;border:1px solid {t$linea2};border-radius:8px;overflow:hidden">
<div style="position:absolute;top:8px;left:10px;z-index:2;font-family:\'gobCL\',sans-serif;font-weight:900;font-size:13px;color:{t$ciruela};background:rgba(255,255,255,.82);padding:2px 8px;border-radius:5px">Puchuncaví · Quintero · Concón · Viña del Mar · escala única</div>
<img src="{mapa_uri}" style="display:block;width:100%;height:100%;object-fit:cover"/>
{e$etiquetas_html(etq)}
</div>
</div>
</div>
</div>
</body></html>')
}

# ---- 5. Flujo principal ----
if (sys.nframe() == 0 || identical(environment(), globalenv())) {
  entrada <- ruta_salidas("establecimientos_proyectados.rds")
  if (!file.exists(entrada)) stop("Falta 32. Corre run_all(to = 2) primero.")
  est <- readRDS(entrada)
  log_msg(sprintf("[escala unica] Generando variante con %d establecimientos...", nrow(est)),
          origen = "33b_escala_unica")

  e$registrar_fuentes()
  est <- e$numerar(est)                       # numeracion N->S 1..97 oficial (sin cambios)
  log_msg("[escala unica] Numeracion N->S 1..97 verificada (numerar de 33).",
          origen = "33b_escala_unica")

  dir.create(RUTAS$salidas_afiche, showWarnings = FALSE, recursive = TRUE)
  com_sf <- e$cargar_comunas()
  png_unico <- ruta_salidas("afiche", "panel_escala_unica.png")
  ru <- render_panel_unico(est, com_sf, png_unico)
  # Verificacion: no-solape garantizado y nada fuera del marco (a 60% no dispara gate).
  stopifnot(ru$fuera == 0, ru$dmin >= 2*ru$radio - 0.5)
  log_msg(sprintf("[escala unica] Panel unico: %d pines, radio=%.1fpx, min_dist=%.1f >= %.0f, fuera=%d, desp_max=%.0f, size_font=%.2f",
                  ru$n, ru$radio, ru$dmin, 2*ru$radio, ru$fuera, ru$desp_max, ru$font_size),
          origen = "33b_escala_unica")

  # Las 4 etiquetas de comuna recalculadas para el bbox del panel unico (no copiadas),
  # mas el offset aditivo calibrado para sacarlas de encima de los pines.
  etq <- e$etiquetas_pct(e$ETIQUETAS_COMUNA, ru$b3)
  for (k in seq_len(nrow(etq))) {
    of <- OFFSET_ETIQUETAS_PCT[[etq$nom[k]]]
    if (!is.null(of)) {
      etq$left[k] <- etq$left[k] + unname(of["dx"])
      etq$top[k]  <- etq$top[k]  + unname(of["dy"])
    }
  }
  etq$left <- pmin(pmax(etq$left, 2), 95)        # clamp al marco
  etq$top  <- pmin(pmax(etq$top,  2), 95)
  log_msg(sprintf("[escala unica] Etiquetas comuna (%%, con offset): %s",
                  paste(sprintf("%s(%.1f,%.1f)", etq$nom, etq$left, etq$top), collapse=" ")),
          origen = "33b_escala_unica")

  html <- generar_html_unico(est, etq, png_unico)
  salida <- ruta_salidas("afiche", "mapa_establecimientos_escala_unica.html")
  tmp <- paste0(salida, ".tmp"); writeLines(html, tmp, useBytes = TRUE); file.rename(tmp, salida)
  log_msg(sprintf("[escala unica] HTML A0 generado en %s", salida), origen = "33b_escala_unica")

  # ---- Export PDF A0 vertical, fuentes incrustadas (mismo metodo que v8 de 33) ----
  pdf_out <- ruta_salidas("afiche", "mapa_establecimientos_escala_unica.pdf")
  in_pulg <- function(mm) mm / 25.4
  ok <- tryCatch({
    pagedown::chrome_print(
      input = salida, output = pdf_out, verbose = 0,
      options = list(
        paperWidth = in_pulg(e$A0_W_MM), paperHeight = in_pulg(e$A0_H_MM),
        marginTop = 0, marginBottom = 0, marginLeft = 0, marginRight = 0,
        printBackground = TRUE, preferCSSPageSize = TRUE))
    TRUE
  }, error = function(err) { log_msg(paste("[escala unica] chrome_print fallo:", conditionMessage(err)),
                                     nivel = "ERROR", origen = "33b_escala_unica"); FALSE })
  if (ok) {
    mb <- round(file.info(pdf_out)$size / 1e6, 1)
    log_msg(sprintf("[escala unica] PDF A0 generado en %s (%.1f MB)", pdf_out, mb), origen = "33b_escala_unica")
    if (requireNamespace("pdftools", quietly = TRUE)) {
      ps <- pdftools::pdf_pagesize(pdf_out)
      log_msg(sprintf("[escala unica] PDF pagesize: %.0f x %.0f pt (A0 = 2384 x 3370 pt)",
                      ps$width[1], ps$height[1]), origen = "33b_escala_unica")
      fn <- pdftools::pdf_fonts(pdf_out)
      log_msg(sprintf("[escala unica] Fuentes incrustadas: %d/%d. Familias: %s",
                      sum(fn$embedded), nrow(fn), paste(unique(fn$name), collapse = ", ")),
              origen = "33b_escala_unica")
    }
  }
}
