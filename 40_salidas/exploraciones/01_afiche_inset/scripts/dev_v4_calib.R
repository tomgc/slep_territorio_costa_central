# Calibracion v4: renderiza paneles SIN pines para ubicar rotulos de ciudad.
suppressMessages({library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg)})
source("10_utils/10_utils.R"); source("10_utils/10_configuracion.R")
# carga funciones del 33 (hasta antes del flujo principal)
e <- new.env(); src <- readLines("30_procesamiento/33_generar_afiche.R")
fin <- grep("^# ---- 11. Flujo principal", src)
tf <- tempfile(fileext=".R"); writeLines(src[1:(fin-1)], tf); sys.source(tf, envir=e)
for(nm in ls(e)) assign(nm, get(nm, e))
registrar_fuentes()

est <- numerar(readRDS("40_salidas/establecimientos_validados.rds"))
com_sf <- cargar_comunas()

# --- replica bbox del panel norte ---
calib <- function(comunas, H, zoom, b4mar, out){
  sub <- est |> filter(comuna_chr %in% comunas)
  pc <- st_as_sf(sub, coords=c("longitud","latitud"), crs=4326)
  bb <- as.numeric(st_bbox(pc))
  b4 <- c(bb[1]-b4mar[1], bb[2]-b4mar[2], bb[3]+b4mar[3], bb[4]+b4mar[4])
  b3 <- bbox_a_3857(c(b4[1],b4[3],b4[2],b4[4]))
  b3 <- fit_bbox_3857(b3, MAPA_W/H, grow_west=FALSE)
  tl <- get_carto_3857(b3, zoom=zoom)
  bord <- comuna_paths(com_sf, comunas)
  g <- ggplot() +
    annotation_raster(tl$img, tl$e[1],tl$e[2],tl$e[3],tl$e[4]) +
    geom_path(data=bord, aes(X,Y,group=grp), color=COL_BORDE_COMUNA, linewidth=0.5, alpha=0.85) +
    coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE) + theme_void()
  ragg::agg_png(out, width=MAPA_W*ESC, height=H*ESC, units="px", res=72*ESC, background="white")
  print(g); dev.off()
  cat(out, "b3=", paste(round(b3), collapse=","), "\n")
  b3
}
b3n <- calib(COMUNAS_CHICAS, NORTE_H, 12, c(0.020,0.015,0.020,0.015), "scratchpad_afiche/calib_norte.png")
b3v <- calib(COMUNA_INSET,   VINA_H,  13, c(0.012,0.010,0.012,0.010), "scratchpad_afiche/calib_vina.png")
saveRDS(list(norte=b3n, vina=b3v), "scratchpad_afiche/b3.rds")
cat("listo\n")
