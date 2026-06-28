# Prototipo v4: pines grandes + anti-colision 2D + zonas de exclusion. Reporta gate.
suppressMessages({library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg)})
source("10_utils/10_utils.R"); source("10_utils/10_configuracion.R")
e <- new.env(); src <- readLines("30_procesamiento/33_generar_afiche.R")
fin <- grep("^# ---- 11. Flujo principal", src); tf<-tempfile(fileext=".R"); writeLines(src[1:(fin-1)],tf); sys.source(tf,envir=e)
for(nm in ls(e)) assign(nm, get(nm, e)); registrar_fuentes()

PIN_RADIO_PX <- 22; PIN_GAP_PX <- 4; PIN_FONT <- 4.3

zonas_px <- function(tb){ tb |> mutate(xmin=cx-hw, xmax=cx+hw, ymin=cy-hh, ymax=cy+hh) }
ZN <- zonas_px(tribble(~nom,~cx,~cy,~hw,~hh,
  "Maitencillo",700,122,100,32, "Puchuncavi",815,588,105,34, "Campiche",601,624,85,32,
  "Ventanas",441,681,95,32, "Quintero",233,941,95,32, "Concon",293,1735,78,32))
ZV <- zonas_px(tribble(~nom,~cx,~cy,~hw,~hh, "Vina del Mar",492,618,182,78))

separar_pines <- function(px, py, r, gap, Z, Wpx, Hpx, iters=800){
  n<-length(px); sep<-2*r+gap; ox<-px; oy<-py
  for(it in 1:iters){ moved<-FALSE
    for(a in 1:(n-1)) for(b in (a+1):n){
      dx<-px[a]-px[b]; dy<-py[a]-py[b]; d<-sqrt(dx*dx+dy*dy)
      if(d<sep){ if(d<1e-6){ang<-2*pi*a/n; dx<-cos(ang); dy<-sin(ang); d<-1}
        ph<-(sep-d)/2; ux<-dx/d; uy<-dy/d
        px[a]<-px[a]+ux*ph; py[a]<-py[a]+uy*ph; px[b]<-px[b]-ux*ph; py[b]<-py[b]-uy*ph; moved<-TRUE } }
    if(nrow(Z)) for(z in seq_len(nrow(Z))){
      ins<-which(px>Z$xmin[z]-r & px<Z$xmax[z]+r & py>Z$ymin[z]-r & py<Z$ymax[z]+r)
      for(i in ins){ dl<-px[i]-(Z$xmin[z]-r); dr<-(Z$xmax[z]+r)-px[i]
        db<-py[i]-(Z$ymin[z]-r); dt<-(Z$ymax[z]+r)-py[i]; m<-min(dl,dr,db,dt)
        if(m==dl) px[i]<-Z$xmin[z]-r else if(m==dr) px[i]<-Z$xmax[z]+r else
        if(m==db) py[i]<-Z$ymin[z]-r else py[i]<-Z$ymax[z]+r; moved<-TRUE } }
    px<-pmin(pmax(px,r),Wpx-r); py<-pmin(pmax(py,r),Hpx-r)
    if(!moved) break }
  list(px=px, py=py, iters=it, desp=sqrt((px-ox)^2+(py-oy)^2))
}
mindist <- function(px,py){ n<-length(px); m<-Inf
  for(a in 1:(n-1)) for(b in (a+1):n){ d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2); if(d<m) m<-d }; m }
circulos <- function(cx,cy,r,fill,id,nseg=44){ ang<-seq(0,2*pi,length.out=nseg+1)[-1]
  do.call(rbind, lapply(seq_along(cx), function(i)
    data.frame(X=cx[i]+r*cos(ang), Y=cy[i]+r*sin(ang), grp=id[i], fill=fill[i]))) }

est <- numerar(readRDS("40_salidas/establecimientos_validados.rds")); com_sf <- cargar_comunas()
b3all <- readRDS("scratchpad_afiche/b3.rds")

render <- function(comunas, H, zoom, b3, Z, out, inset=FALSE){
  Wpx<-MAPA_W*ESC; Hpx<-H*ESC; Xr<-b3[2]-b3[1]; Yr<-b3[4]-b3[3]
  sub <- est |> filter(if(inset) comuna_chr==comunas else comuna_chr %in% comunas)
  pc <- st_as_sf(sub, coords=c("longitud","latitud"), crs=4326)
  xy <- st_coordinates(st_transform(pc,3857)); sub$X<-xy[,1]; sub$Y<-xy[,2]
  # data -> px (origen top-left)
  px <- (sub$X-b3[1])/Xr*Wpx; py <- (b3[4]-sub$Y)/Yr*Hpx
  d0 <- mindist(px,py)
  s <- separar_pines(px,py,PIN_RADIO_PX,PIN_GAP_PX,Z,Wpx,Hpx)
  d1 <- mindist(s$px,s$py)
  fuera <- sum(s$px< PIN_RADIO_PX | s$px>Wpx-PIN_RADIO_PX | s$py<PIN_RADIO_PX | s$py>Hpx-PIN_RADIO_PX)
  inzone <- 0; if(nrow(Z)) for(z in seq_len(nrow(Z))) inzone<-inzone+sum(s$px>Z$xmin[z]&s$px<Z$xmax[z]&s$py>Z$ymin[z]&s$py<Z$ymax[z])
  cat(sprintf("[%s] n=%d  min_dist antes=%.1f despues=%.1f px (req>=%d)  desp med=%.0f max=%.0f px  fuera_marco=%d  en_zona=%d  iters=%d\n",
      out, nrow(sub), d0, d1, 2*PIN_RADIO_PX, mean(s$desp), max(s$desp), fuera, inzone, s$iters))
  # px -> data
  cxd <- b3[1]+s$px/Wpx*Xr; cyd <- b3[4]-s$py/Hpx*Yr
  rdat <- PIN_RADIO_PX*Xr/Wpx
  poly <- circulos(cxd, cyd, rdat, sub$color, sub$num)
  bord <- comuna_paths(com_sf, comunas)
  tl <- get_carto_3857(b3, zoom=zoom)
  g <- ggplot() + annotation_raster(tl$img, tl$e[1],tl$e[2],tl$e[3],tl$e[4]) +
    geom_path(data=bord, aes(X,Y,group=grp), color=COL_BORDE_COMUNA, linewidth=0.5, alpha=0.85) +
    geom_polygon(data=poly, aes(X,Y,group=grp,fill=fill), color="white", linewidth=0.5) +
    scale_fill_identity() +
    geom_text(data=data.frame(X=cxd,Y=cyd,num=sub$num), aes(X,Y,label=num),
              color="white", family="gobCL", fontface="bold", size=PIN_FONT) +
    coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE) + theme_void()
  ragg::agg_png(out, width=Wpx, height=Hpx, units="px", res=72*ESC, background="white")
  print(g); dev.off()
}
render(COMUNAS_CHICAS, NORTE_H, 12, b3all$norte, ZN, "scratchpad_afiche/v4_norte.png", inset=FALSE)
render(COMUNA_INSET,   VINA_H,  13, b3all$vina,  ZV, "scratchpad_afiche/v4_vina.png",  inset=TRUE)
cat("listo\n")
