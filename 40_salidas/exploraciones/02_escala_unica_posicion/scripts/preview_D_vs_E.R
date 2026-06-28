# =============================================================================
# preview_D_vs_E.R — Sondeo VISUAL (no Fase 1). Dos variantes circulares de Vina,
# comparables lado a lado con preview_A_in_situ.png (mismo bbox/tile/norte/ESC).
#   D: arco de descarga (60 discos en arco que envuelve el cluster) + leader radial.
#   E: silueta circular COMPACTA sobre el centroide real (separar_pines con frontera
#      circular), sin leaders salvo umbral.
# Reusa 33 via source(local=TRUE). 33 NO se edita. Salidas en scratchpad_afiche/.
# =============================================================================
suppressWarnings(suppressMessages({ library(dplyr); library(sf); library(maptiles)
  library(terra); library(ggplot2); library(ragg) }))
setwd("/Users/tomgc/Projects/slep_georreferenciacion")

e <- new.env()
source(here::here("30_procesamiento","33_generar_afiche.R"), local = e)
e$registrar_fuentes()

# ---- mismos parametros que el sondeo A/C ----
ESC_PREVIEW <- 1.40
MAPA_W <- e$MAPA_W; UNICO_H <- e$ALTO_BODY
Wpx <- MAPA_W*ESC_PREVIEW; Hpx <- UNICO_H*ESC_PREVIEW
PIN_R <- 11*ESC_PREVIEW; PIN_GAP <- 2*ESC_PREVIEW; PIN_FONT <- 4.3
sepd <- 2*PIN_R + PIN_GAP
MM_POR_PXLIENZO <- 841/1240               # A0 ancho / lienzo ancho

est <- readRDS(ruta_salidas("establecimientos_proyectados.rds")); est <- e$numerar(est)
norm <- function(s){s<-tolower(iconv(as.character(s),to="ASCII//TRANSLIT")); gsub("[^a-z ]","",s)}
es_vina <- norm(est$comuna)=="vina del mar"
stopifnot(sum(es_vina)==60, sum(!es_vina)==37)

# ---- bbox escala unica (identico a A/C) ----
pc <- st_as_sf(est, coords=c("longitud","latitud"), crs=4326)
bb <- as.numeric(st_bbox(pc)); b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)
b3 <- e$bbox_a_3857(c(b4[1],b4[3],b4[2],b4[4])); b3 <- e$fit_bbox_3857(b3, MAPA_W/UNICO_H, grow_west=FALSE)
Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
xy <- st_coordinates(st_transform(pc,3857)); est$X<-xy[,1]; est$Y<-xy[,2]
est$px <- (est$X-b3[1])/Xr*Wpx; est$py <- (b3[4]-est$Y)/Yr*Hpx

tl  <- e$get_carto_3857(b3, zoom=12)
bord <- e$comuna_paths(e$cargar_comunas(), COMUNAS_ORDEN)
px2dx <- function(px) b3[1]+px/Wpx*Xr; py2dy <- function(py) b3[4]-py/Hpx*Yr
rdat <- PIN_R*Xr/Wpx

# ---- helpers identicos a A/C ----
separar <- e$separar_pines
mindist <- function(px,py){n<-length(px);m<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<m)m<-d};m}
seg_cross<-function(p1,p2,p3,p4){d<-function(a,b,c)(c[1]-a[1])*(b[2]-a[2])-(c[2]-a[2])*(b[1]-a[1])
  d1<-d(p3,p4,p1);d2<-d(p3,p4,p2);d3<-d(p1,p2,p3);d4<-d(p1,p2,p4)
  (d1>0&&d2<0||d1<0&&d2>0)&&(d3>0&&d4<0||d3<0&&d4>0)}
cuenta_cruces<-function(ax,ay,bx,by){n<-length(ax);k<-0
  for(i in 1:(n-1))for(j in (i+1):n)if(seg_cross(c(ax[i],ay[i]),c(bx[i],by[i]),c(ax[j],ay[j]),c(bx[j],by[j])))k<-k+1;k}

# norte separado (identico en todas)
nrt <- est[!es_vina,]
sn <- separar(nrt$px, nrt$py, PIN_R, PIN_GAP, Wpx, Hpx)
nrt$cx <- px2dx(sn$px); nrt$cy <- py2dy(sn$py)

base_layers <- function(rotulo) list(
  annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]),
  geom_path(data=bord, aes(X,Y,group=grp), color=e$COL_BORDE_COMUNA, linewidth=0.4, alpha=0.85),
  coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE), theme_void(),
  annotate("label", x=b3[1]+0.02*Xr, y=b3[4]-0.015*Yr, label=rotulo, hjust=0, vjust=1,
           size=5.2, family="gobCL", fontface="bold", color="#4A2746", fill="white", label.size=0.3))
discos <- function(cx,cy,fill,num) list(
  geom_polygon(data=e$circulos(cx,cy,rdat,fill,seq_along(cx)), aes(X,Y,group=grp,fill=fill), color="white", linewidth=0.4),
  geom_text(data=data.frame(X=cx,Y=cy,num=num), aes(X,Y,label=num), color="white", family="gobCL", fontface="bold", size=PIN_FONT))
render <- function(g,out){ragg::agg_png(out,width=Wpx,height=Hpx,units="px",res=72*ESC_PREVIEW,background="white");print(g);grDevices::dev.off()}

v <- est[es_vina,]
Cx <- mean(v$px); Cy <- mean(v$py)                 # centroide cluster (px, py-abajo)

# =================== PNG-D : arco de descarga + leader radial ===================
# angulo de cada ancla respecto al centroide (coords math: y arriba)
ang <- atan2(-(v$py-Cy), (v$px-Cx))                # [-pi,pi]
rmax <- max(sqrt((v$px-Cx)^2+(v$py-Cy)^2))
# arco: anillo radio R que envuelve el cluster, abierto hacia el PONIENTE (oceano).
# discos uniformes en un span centrado al ORIENTE (0 rad), ordenados por angulo de ancla.
span <- 280*pi/180                                 # deja ~80 deg de hueco al poniente
R <- max(rmax + sepd*1.6, 60*sepd/span)            # radio que da arco-largo suficiente
ord <- order(ang)                                  # asignacion por angulo (monotona)
vD <- v[ord,]
# posiciones angulares uniformes en el span (centrado en 0 = oriente)
theta <- seq(-span/2, span/2, length.out=nrow(vD))
vD$dpx <- Cx + R*cos(theta)
vD$dpy <- Cy - R*sin(theta)
# clamp dentro del marco; si algun disco se sale, encoge R (iterativo simple)
for(it in 1:40){ fuera <- any(vD$dpx<PIN_R|vD$dpx>Wpx-PIN_R|vD$dpy<PIN_R|vD$dpy>Hpx-PIN_R)
  if(!fuera) break; R <- R*0.97; vD$dpx <- Cx+R*cos(theta); vD$dpy <- Cy-R*sin(theta) }
vD$ax<-px2dx(vD$px); vD$ay<-py2dy(vD$py); vD$dx<-px2dx(vD$dpx); vD$dy<-py2dy(vD$dpy)
crucesD <- cuenta_cruces(vD$px,vD$py,vD$dpx,vD$dpy)
dispD <- sqrt((vD$dpx-vD$px)^2+(vD$dpy-vD$py)^2)/ESC_PREVIEW   # px lienzo
gD <- ggplot() + base_layers("D — arco descarga") +
  geom_segment(data=vD, aes(ax,ay,xend=dx,yend=dy), color="#9a8aa0", linewidth=0.25) +
  geom_point(data=vD, aes(ax,ay), color="#444444", size=0.7) +
  discos(nrt$cx,nrt$cy,nrt$color,nrt$num) + discos(vD$dx,vD$dy,vD$color,vD$num) +
  scale_fill_identity()
render(gD, "scratchpad_afiche/preview_D_arco_descarga.png")

# =================== PNG-E : silueta circular compacta (separar con frontera circular) ===================
# separar_pines con clamp CIRCULAR al radio rho (en vez del marco). rho minimo que
# logra min_dist>=sepd; se incrementa si no cabe. Semilla = posiciones reales.
sep_circular <- function(px,py,r,gap,cx,cy,rho,iters=2000){
  n<-length(px); sep<-2*r+gap
  for(it in seq_len(iters)){ moved<-FALSE
    for(a in 1:(n-1))for(b in (a+1):n){ dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
      if(d<sep){ if(d<1e-6){an<-2*pi*a/n;dx<-cos(an);dy<-sin(an);d<-1}
        ph<-(sep-d)/2;ux<-dx/d;uy<-dy/d; px[a]<-px[a]+ux*ph;py[a]<-py[a]+uy*ph
        px[b]<-px[b]-ux*ph;py[b]<-py[b]-uy*ph;moved<-TRUE}}
    # clamp circular
    dd<-sqrt((px-cx)^2+(py-cy)^2); out<-dd>(rho-r)
    if(any(out)){ k<-(rho-r)/dd[out]; px[out]<-cx+(px[out]-cx)*k; py[out]<-cy+(py[out]-cy)*k }
    if(!moved && !any(out)) break }
  list(px=px,py=py) }
rho <- PIN_R*8.6
for(try in 1:30){ sE <- sep_circular(v$px,v$py,PIN_R,PIN_GAP,Cx,Cy,rho)
  if(mindist(sE$px,sE$py) >= 2*PIN_R-0.5) break; rho <- rho*1.05 }
vE <- v; vE$ex<-sE$px; vE$ey<-sE$py; vE$cx<-px2dx(sE$px); vE$cy<-py2dy(sE$py)
dminE <- mindist(sE$px,sE$py)
fueraE <- sum(sE$px<PIN_R|sE$px>Wpx-PIN_R|sE$py<PIN_R|sE$py>Hpx-PIN_R)
dispE <- sqrt((sE$px-v$px)^2+(sE$py-v$py)^2)/ESC_PREVIEW       # px lienzo
umbralE <- sum(sqrt((sE$px-v$px)^2+(sE$py-v$py)^2) > 2*PIN_R)  # discos que pediria leader
# solape con norte: min dist entre cualquier disco E y cualquier disco norte separado
solap_norte <- { m<-Inf; for(i in seq_len(nrow(vE)))for(j in seq_len(nrow(nrt))){
  d<-sqrt((vE$ex[i]-sn$px[j])^2+(vE$ey[i]-sn$py[j])^2); if(d<m)m<-d }; m }
# leaders solo para discos sobre umbral (criterio opcion B)
thr <- 2*PIN_R; idxL <- which(sqrt((sE$px-v$px)^2+(sE$py-v$py)^2) > thr)
gE <- ggplot() + base_layers("E — circulo compacto")
if(length(idxL)>0){ lE <- data.frame(ax=px2dx(v$px[idxL]),ay=py2dy(v$py[idxL]),dx=vE$cx[idxL],dy=vE$cy[idxL])
  gE <- gE + geom_segment(data=lE,aes(ax,ay,xend=dx,yend=dy),color="#9a8aa0",linewidth=0.25) +
    geom_point(data=lE,aes(ax,ay),color="#444444",size=0.7) }
gE <- gE + discos(nrt$cx,nrt$cy,nrt$color,nrt$num) + discos(vE$cx,vE$cy,vE$color,vE$num) + scale_fill_identity()
render(gE, "scratchpad_afiche/preview_E_circulo_compacto.png")

# ---- Reporte de metricas ----
cat(sprintf("\nESC_PREVIEW=%.2f  dims D y E = %.0f x %.0f px (radio=%.1f sep=%.1f)\n",
            ESC_PREVIEW, Wpx, Hpx, PIN_R, sepd))
cat(sprintf("D (arco): cruces leader=%d (grilla C=53)  desp medio=%.0f px lienzo  max=%.0f px lienzo  (R=%.0f px prev)\n",
            crucesD, mean(dispD), max(dispD), R))
cat(sprintf("E (circulo): desp medio=%.0f px lienzo (%.1f mm A0)  max=%.0f px lienzo (%.1f mm A0)\n",
            mean(dispE), mean(dispE)*MM_POR_PXLIENZO, max(dispE), max(dispE)*MM_POR_PXLIENZO))
cat(sprintf("E: min_dist=%.1f px (req %.0f)  fuera_marco=%d  discos>umbral_leader=%d  min_dist_a_norte=%.0f px (sep=%.0f -> %s)\n",
            dminE, 2*PIN_R, fueraE, umbralE, solap_norte, sepd, ifelse(solap_norte>=sepd,"SIN solape","SOLAPA")))
cat("Salidas: scratchpad_afiche/preview_D_arco_descarga.png , preview_E_circulo_compacto.png\n")
