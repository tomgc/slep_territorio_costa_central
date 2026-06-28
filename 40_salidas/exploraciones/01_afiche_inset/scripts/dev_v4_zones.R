# Overlay de zonas de exclusion candidatas sobre el tile norte (calibracion).
suppressMessages({library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg)})
source("10_utils/10_utils.R"); source("10_utils/10_configuracion.R")
e <- new.env(); src <- readLines("30_procesamiento/33_generar_afiche.R")
fin <- grep("^# ---- 11. Flujo principal", src)
tf <- tempfile(fileext=".R"); writeLines(src[1:(fin-1)], tf); sys.source(tf, envir=e)
for(nm in ls(e)) assign(nm, get(nm, e))

b3 <- readRDS("scratchpad_afiche/b3.rds")$norte
Wpx <- MAPA_W*ESC; Hpx <- NORTE_H*ESC
Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
# px (origen top-left) -> data
px2x <- function(px) b3[1] + px/Wpx*Xr
py2y <- function(py) b3[4] - py/Hpx*Yr

# zonas candidatas en px full-res (cx, cy, half_w, half_h)
Z <- tribble(~nom,~cx,~cy,~hw,~hh,
  "Maitencillo", 700, 122, 100, 32,
  "Puchuncavi",  815, 588, 105, 34,
  "Campiche",    601, 624, 85, 32,
  "Ventanas",    441, 681, 95, 32,
  "Quintero",    233, 941, 95, 32,
  "Concon",      293,1735, 78, 32)
Z <- Z |> mutate(xmin=px2x(cx-hw), xmax=px2x(cx+hw), ymin=py2y(cy+hh), ymax=py2y(cy-hh),
                 lx=px2x(cx), ly=py2y(cy))

tl <- get_carto_3857(b3, zoom=12)
g <- ggplot() +
  annotation_raster(tl$img, tl$e[1],tl$e[2],tl$e[3],tl$e[4]) +
  geom_rect(data=Z, aes(xmin=xmin,xmax=xmax,ymin=ymin,ymax=ymax),
            fill="red", alpha=0.3, color="red", linewidth=0.4) +
  geom_text(data=Z, aes(lx, ly, label=nom), color="blue", size=2.4) +
  coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE) + theme_void()
ragg::agg_png("scratchpad_afiche/zones_norte.png", width=Wpx, height=Hpx, units="px", res=72*ESC, background="white")
print(g); dev.off()
cat("ok zones_norte\n")
