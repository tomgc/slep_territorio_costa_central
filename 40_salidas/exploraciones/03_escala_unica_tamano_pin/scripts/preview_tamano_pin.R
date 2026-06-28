# =============================================================================
# preview_tamano_pin.R — Sondeo VISUAL (no Fase 1). Panel unico escala unica, Viña
# IN SITU PURO (base A), variando SOLO el radio del pin (T1 75%, T2 60%, T3 45% del
# PIN_RADIO de produccion). La FUENTE del numero se ajusta al MAXIMO que cabe en cada
# disco (el "97" ocupa ~target del diametro), NO se escala proporcional al radio.
# El pin es global: norte y Viña al MISMO radio en cada variante.
# Reusa 33 via source(local=TRUE). 33 NO se edita. Salidas en scratchpad_afiche/.
# =============================================================================
suppressWarnings(suppressMessages({ library(dplyr); library(sf); library(maptiles)
  library(terra); library(ggplot2); library(ragg); library(grid) }))
setwd("/Users/tomgc/Projects/slep_georreferenciacion")

e <- new.env(); source(here::here("30_procesamiento","33_generar_afiche.R"), local = e)
e$registrar_fuentes()

ESC_PREVIEW <- 1.40; ESC_PROD <- e$ESC                # 5.34 produccion
MAPA_W <- e$MAPA_W; UNICO_H <- e$ALTO_BODY
Wpx <- MAPA_W*ESC_PREVIEW; Hpx <- UNICO_H*ESC_PREVIEW
PIN_GAP <- 2*ESC_PREVIEW
MM_POR_PXLIENZO <- 841/1240                           # 0.678 mm/px lienzo en A0
PT_POR_MM <- 72.27/25.4                               # .pt de ggplot
TARGET_GLIFO <- 0.72                                  # "97" ~72% del diametro del disco

est <- readRDS(ruta_salidas("establecimientos_proyectados.rds")); est <- e$numerar(est)
norm <- function(s){s<-tolower(iconv(as.character(s),to="ASCII//TRANSLIT")); gsub("[^a-z ]","",s)}
es_vina <- norm(est$comuna)=="vina del mar"; stopifnot(sum(es_vina)==60, sum(!es_vina)==37)

pc <- st_as_sf(est, coords=c("longitud","latitud"), crs=4326)
bb <- as.numeric(st_bbox(pc)); b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)
b3 <- e$bbox_a_3857(c(b4[1],b4[3],b4[2],b4[4])); b3 <- e$fit_bbox_3857(b3, MAPA_W/UNICO_H, grow_west=FALSE)
Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
xy <- st_coordinates(st_transform(pc,3857)); est$X<-xy[,1]; est$Y<-xy[,2]
est$px <- (est$X-b3[1])/Xr*Wpx; est$py <- (b3[4]-est$Y)/Yr*Hpx
tl <- e$get_carto_3857(b3, zoom=12); bord <- e$comuna_paths(e$cargar_comunas(), COMUNAS_ORDEN)
px2dx <- function(px) b3[1]+px/Wpx*Xr; py2dy <- function(py) b3[4]-py/Hpx*Yr
mindist <- function(px,py){n<-length(px);m<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<m)m<-d};m}

# --- medidor de ancho de "97" en pulgadas para un fontsize grid dado (linear) ---
ragg::agg_capture(width=4, height=4, units="in", res=72*ESC_PREVIEW)
FS_REF <- 100
w97_in_ref <- grid::convertWidth(grid::grobWidth(grid::textGrob(
  "97", gp=grid::gpar(fontfamily="gobCL", fontface="bold", fontsize=FS_REF))), "inches", valueOnly=TRUE)
invisible(grDevices::dev.off())

render <- function(g,out){ragg::agg_png(out,width=Wpx,height=Hpx,units="px",res=72*ESC_PREVIEW,background="white");print(g);grDevices::dev.off()}

variantes <- list(
  list(id="T1", frac=0.75, rot="T1 — radio 75%", out="scratchpad_afiche/preview_T1_r75.png"),
  list(id="T2", frac=0.60, rot="T2 — radio 60%", out="scratchpad_afiche/preview_T2_r60.png"),
  list(id="T3", frac=0.45, rot="T3 — radio 45%", out="scratchpad_afiche/preview_T3_r45.png"))

cat(sprintf("ESC_PREVIEW=%.2f  dims=%.0f x %.0f px  (PIN_RADIO prod=11 px lienzo)\n", ESC_PREVIEW, Wpx, Hpx))
for(V in variantes){
  radio_lienzo <- 11*V$frac
  PIN_R <- radio_lienzo*ESC_PREVIEW                       # px preview
  diam_px <- 2*PIN_R; sepd <- 2*PIN_R + PIN_GAP
  # fuente al maximo: ancho("97") = TARGET_GLIFO*diametro
  target_w_in <- (TARGET_GLIFO*diam_px)/(72*ESC_PREVIEW)  # px -> pulgadas del device
  FS <- FS_REF * target_w_in / w97_in_ref                 # grid fontsize (pt)
  size_geom <- FS / PT_POR_MM                             # 'size' de geom_text
  # ratio glifo/diametro alcanzado (verificacion)
  w_ach_in <- w97_in_ref * FS/FS_REF
  ratio_ach <- (w_ach_in*72*ESC_PREVIEW)/diam_px
  # separar 97 a este radio
  s <- e$separar_pines(est$px, est$py, PIN_R, PIN_GAP, Wpx, Hpx)
  dmin <- mindist(s$px, s$py)
  fuera <- sum(s$px<PIN_R|s$px>Wpx-PIN_R|s$py<PIN_R|s$py>Hpx-PIN_R)
  disp_lz <- s$desp/ESC_PREVIEW                           # px lienzo
  # % Viña a <1 radio de su real
  pct_vina_1r <- 100*mean(s$desp[es_vina] < PIN_R)
  cx <- px2dx(s$px); cy <- py2dy(s$py); rdat <- PIN_R*Xr/Wpx
  poly <- e$circulos(cx, cy, rdat, est$color, est$num)
  g <- ggplot() +
    annotation_raster(tl$img, tl$e[1],tl$e[2],tl$e[3],tl$e[4]) +
    geom_path(data=bord, aes(X,Y,group=grp), color=e$COL_BORDE_COMUNA, linewidth=0.4, alpha=0.85) +
    geom_polygon(data=poly, aes(X,Y,group=grp,fill=fill), color="white", linewidth=0.3) +
    scale_fill_identity() +
    geom_text(data=data.frame(X=cx,Y=cy,num=est$num), aes(X,Y,label=num),
              color="white", family="gobCL", fontface="bold", size=size_geom) +
    coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE) + theme_void() +
    annotate("label", x=b3[1]+0.02*Xr, y=b3[4]-0.015*Yr, label=V$rot, hjust=0, vjust=1,
             size=5.2, family="gobCL", fontface="bold", color="#4A2746", fill="white", label.size=0.3)
  render(g, V$out)
  # metricas en A0 real
  radio_mm   <- radio_lienzo*MM_POR_PXLIENZO
  glifo_mm   <- TARGET_GLIFO*2*radio_mm
  cat(sprintf("\n%s radio=%.2f px lienzo (%.2f mm A0) | fuente '97' ancho=%.2f mm A0, ratio glifo/diam=%.2f\n",
              V$id, radio_lienzo, radio_mm, glifo_mm, ratio_ach))
  cat(sprintf("   separar(97): min_dist=%.1f px (req %.0f) fuera=%d | desp medio=%.1f px lienzo (%.1f mm) max=%.1f px (%.1f mm)\n",
              dmin, 2*PIN_R, fuera, mean(disp_lz), mean(disp_lz)*MM_POR_PXLIENZO, max(disp_lz), max(disp_lz)*MM_POR_PXLIENZO))
  cat(sprintf("   %% Viña a <1 radio de su real = %.0f%%  | salida %s\n", pct_vina_1r, V$out))
}
