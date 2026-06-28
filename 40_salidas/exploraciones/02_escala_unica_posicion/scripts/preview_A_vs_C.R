# =============================================================================
# preview_A_vs_C.R — Sondeo VISUAL (no Fase 1). Renderiza 2 PNG baja-res del panel
# unico a escala unica que difieren SOLO en el tratamiento de Vina:
#   A: in situ puro (separar_pines, sin leaders ni ancla)
#   C: proxy a bloque oriente 6x10 + leader line a ancla real (abanico por latitud)
# Reusa funciones de 33 via source(local=TRUE) en un new.env (NO dispara su flujo).
# 33 NO se edita. Salidas en scratchpad_afiche/ (gitignored).
# =============================================================================
suppressWarnings(suppressMessages({ library(dplyr); library(sf); library(maptiles)
  library(terra); library(ggplot2); library(ragg) }))
setwd("/Users/tomgc/Projects/slep_georreferenciacion")

# ---- Reuso de 33 SIN ejecutar su flujo (verificado en Fase 0: local=TRUE no corre) ----
e <- new.env()
source(here::here("30_procesamiento","33_generar_afiche.R"), local = e)
stopifnot(is.function(e$separar_pines), is.function(e$circulos),
          is.function(e$comuna_paths), is.function(e$get_carto_3857),
          is.function(e$fit_bbox_3857), is.function(e$bbox_a_3857),
          is.function(e$numerar), is.function(e$cargar_comunas))
e$registrar_fuentes()                       # gobCL para los numeros

# ---- ESC reducido para preview (mantiene proporcion radio/panel de 33) ----
ESC_PREVIEW  <- 1.4
MAPA_W  <- e$MAPA_W                          # 728
UNICO_H <- e$ALTO_BODY                       # 1520 (panel unico ocupa todo el body)
Wpx <- MAPA_W*ESC_PREVIEW; Hpx <- UNICO_H*ESC_PREVIEW
PIN_R   <- 11*ESC_PREVIEW                    # misma proporcion 11/1520 que 33
PIN_GAP <- 2*ESC_PREVIEW
PIN_FONT <- 4.3                              # mm, constante (igual que 33)
sepd <- 2*PIN_R + PIN_GAP

# ---- Datos + numeracion oficial (reusa numerar) ----
est <- readRDS(ruta_salidas("establecimientos_proyectados.rds"))
est <- e$numerar(est)                        # agrega num (N->S) y color por tipo
norm <- function(s){s<-tolower(iconv(as.character(s),to="ASCII//TRANSLIT")); gsub("[^a-z ]","",s)}
es_vina  <- norm(est$comuna)=="vina del mar"
stopifnot(sum(es_vina)==60, sum(!es_vina)==37)   # guard: clasificacion correcta

# ---- bbox escala unica (identico a Fase 0) ----
pc <- st_as_sf(est, coords=c("longitud","latitud"), crs=4326)
bb <- as.numeric(st_bbox(pc))
b4 <- c(bb[1]-0.020, bb[2]-0.015, bb[3]+0.020, bb[4]+0.015)
b3 <- e$bbox_a_3857(c(b4[1],b4[3],b4[2],b4[4]))
b3 <- e$fit_bbox_3857(b3, MAPA_W/UNICO_H, grow_west=FALSE)
Xr <- b3[2]-b3[1]; Yr <- b3[4]-b3[3]
xy <- st_coordinates(st_transform(pc,3857))
est$X<-xy[,1]; est$Y<-xy[,2]
est$px <- (est$X-b3[1])/Xr*Wpx; est$py <- (b3[4]-est$Y)/Yr*Hpx

# ---- Tile + limites (IDENTICOS en A y C) ----
tl  <- e$get_carto_3857(b3, zoom=12)
bord <- e$comuna_paths(e$cargar_comunas(), COMUNAS_ORDEN)

px2dx <- function(px) b3[1] + px/Wpx*Xr
py2dy <- function(py) b3[4] - py/Hpx*Yr
rdat  <- PIN_R*Xr/Wpx

# ---- Norte: separar 37 SOLOS (identico en A y C) ----
nrt <- est[!es_vina,]
sn <- e$separar_pines(nrt$px, nrt$py, PIN_R, PIN_GAP, Wpx, Hpx)
nrt$cx <- px2dx(sn$px); nrt$cy <- py2dy(sn$py)

# ---- Base del plot (tile + limites + norte): comun a A y C ----
base_layers <- function(rotulo){
  list(
    annotation_raster(tl$img, tl$e[1], tl$e[2], tl$e[3], tl$e[4]),
    geom_path(data=bord, aes(X,Y,group=grp), color=e$COL_BORDE_COMUNA,
              linewidth=0.4, alpha=0.85),
    coord_equal(xlim=c(b3[1],b3[2]), ylim=c(b3[3],b3[4]), expand=FALSE),
    theme_void(),
    annotate("label", x=b3[1]+0.02*Xr, y=b3[4]-0.015*Yr, label=rotulo,
             hjust=0, vjust=1, size=5.2, family="gobCL", fontface="bold",
             color="#4A2746", fill="white", label.size=0.3)
  )
}
# dibuja un set de discos numerados (centros en data coords)
discos <- function(cx,cy,fill,num){
  poly <- e$circulos(cx,cy,rdat,fill, seq_along(cx))
  list(
    geom_polygon(data=poly, aes(X,Y,group=grp,fill=fill), color="white", linewidth=0.4),
    geom_text(data=data.frame(X=cx,Y=cy,num=num), aes(X,Y,label=num),
              color="white", family="gobCL", fontface="bold", size=PIN_FONT)
  )
}
render <- function(g, out){
  ragg::agg_png(out, width=Wpx, height=Hpx, units="px", res=72*ESC_PREVIEW, background="white")
  print(g); grDevices::dev.off()
}

# =================== PNG-A : Vina in situ puro ===================
v <- est[es_vina,]
sv <- e$separar_pines(v$px, v$py, PIN_R, PIN_GAP, Wpx, Hpx)
v$cx <- px2dx(sv$px); v$cy <- py2dy(sv$py)
gA <- ggplot() + base_layers("A — in situ") +
  discos(c(nrt$cx,v$cx), c(nrt$cy,v$cy),
         c(nrt$color,v$color), c(nrt$num,v$num)) +
  scale_fill_identity()
outA <- "scratchpad_afiche/preview_A_in_situ.png"
render(gA, outA)

# =================== PNG-C : proxy a bloque oriente 6x10 + leaders ===================
vc <- est[es_vina,]
hv_xmax <- max(vc$px); hv_y0 <- min(vc$py); hv_y1 <- max(vc$py)
ncol<-6; nrw<-10
x_start <- hv_xmax + sepd*0.7
band_h  <- (nrw-1)*sepd
gy0 <- mean(c(hv_y0,hv_y1)) - band_h/2
gy0 <- max(PIN_R, min(gy0, Hpx-PIN_R-band_h))
sl <- expand.grid(r=0:(nrw-1), c=0:(ncol-1)); sl <- sl[order(sl$r, sl$c),]
ord <- order(vc$py)                                  # N->S = py asc (abanico latitud)
vc <- vc[ord,]
vc$dpx <- x_start + sl$c[seq_len(nrow(vc))]*sepd
vc$dpy <- gy0     + sl$r[seq_len(nrow(vc))]*sepd
# data coords
vc$ax <- px2dx(vc$px);  vc$ay <- py2dy(vc$py)         # ancla real
vc$dx <- px2dx(vc$dpx); vc$dy <- py2dy(vc$dpy)        # disco desplazado
leaders <- data.frame(x=vc$ax, y=vc$ay, xend=vc$dx, yend=vc$dy)
gC <- ggplot() + base_layers("C — proxy+leader") +
  geom_segment(data=leaders, aes(x=x,y=y,xend=xend,yend=yend),
               color="#9a8aa0", linewidth=0.25) +
  geom_point(data=vc, aes(ax,ay), color="#444444", size=0.7) +
  discos(nrt$cx, nrt$cy, nrt$color, nrt$num) +
  discos(vc$dx, vc$dy, vc$color, vc$num) +
  scale_fill_identity()
outC <- "scratchpad_afiche/preview_C_proxy_leader.png"
render(gC, outC)

# ---- Verificacion: cruces visibles de leader en C (debe ~53) ----
seg_cross<-function(p1,p2,p3,p4){d<-function(a,b,c)(c[1]-a[1])*(b[2]-a[2])-(c[2]-a[2])*(b[1]-a[1])
  d1<-d(p3,p4,p1);d2<-d(p3,p4,p2);d3<-d(p1,p2,p3);d4<-d(p1,p2,p4)
  (d1>0&&d2<0||d1<0&&d2>0)&&(d3>0&&d4<0||d3<0&&d4>0)}
A<-cbind(vc$px,vc$py); B<-cbind(vc$dpx,vc$dpy); ncr<-0
for(i in 1:(nrow(vc)-1))for(j in (i+1):nrow(vc))if(seg_cross(A[i,],B[i,],A[j,],B[j,]))ncr<-ncr+1

cat(sprintf("\nESC_PREVIEW=%.2f  dims A y C = %.0f x %.0f px  (radio pin=%.1f px, sep=%.1f px)\n",
            ESC_PREVIEW, Wpx, Hpx, PIN_R, sepd))
cat(sprintf("Cruces de leader en C (medidos en este render): %d (Fase 0 reporto 53)\n", ncr))
cat(sprintf("Salidas:\n  %s\n  %s\n", outA, outC))
