suppressMessages({library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg)})
source("10_utils/10_configuracion.R")
ff <- here::here("design_handoff_mapa_establecimientos","fonts")
try(systemfonts::register_font("gobCL", plain=file.path(ff,"gobCL_Regular.otf"), bold=file.path(ff,"gobCL_Heavy.otf")), silent=TRUE)

TIPO_ORDEN <- c("jardin","basica","liceo","especial","adultos")
est <- readRDS("40_salidas/establecimientos_validados.rds") |>
  mutate(comuna_chr=as.character(comuna),
         comuna_f=factor(comuna_chr, levels=COMUNAS_ORDEN),
         tipo_f=factor(tipo, levels=TIPO_ORDEN)) |>
  arrange(comuna_f, tipo_f, nombre) |>
  mutate(num=row_number(), color=TIPOS$color[match(tipo, TIPOS$key)])

vina <- est |> filter(comuna_chr=="Viña del Mar")
pc <- st_as_sf(vina, coords=c("longitud","latitud"), crs=4326)
bb <- as.numeric(st_bbox(pc))   # xmin ymin xmax ymax
mx <- 0.012
poly <- st_as_sfc(st_bbox(c(xmin=bb[1]-mx,ymin=bb[2]-mx,xmax=bb[3]+mx,ymax=bb[4]+mx), crs=4326))
poly <- st_transform(poly, 3857)
tiles <- get_tiles(poly, provider="CartoDB.Positron", zoom=13, crop=TRUE, cachedir=tempdir())
arr <- as.array(tiles)
img <- matrix(grDevices::rgb(arr[,,1],arr[,,2],arr[,,3],maxColorValue=255), nrow=dim(arr)[1])
e <- as.vector(ext(tiles))

p3857 <- st_transform(pc, 3857); xy <- st_coordinates(p3857)
vina$X <- xy[,1]; vina$Y <- xy[,2]
Xr <- e[2]-e[1]
# decluster
decluster <- function(df, dmin, iters=150){ X<-df$X; Y<-df$Y; k<-nrow(df)
  for(it in 1:iters){ moved<-FALSE
    for(a in 1:(k-1)) for(b in (a+1):k){
      dx<-X[a]-X[b]; dy<-Y[a]-Y[b]; d<-sqrt(dx*dx+dy*dy)
      if(d<dmin && d>1e-9){ push<-(dmin-d)/2; X[a]<-X[a]+dx/d*push; Y[a]<-Y[a]+dy/d*push
        X[b]<-X[b]-dx/d*push; Y[b]<-Y[b]-dy/d*push; moved<-TRUE } }
    if(!moved) break }
  df$X<-X; df$Y<-Y; df }
vina <- decluster(vina, dmin=0.026*Xr)

g <- ggplot() +
  annotation_raster(img, e[1],e[2],e[3],e[4]) +
  geom_point(data=vina, aes(X,Y), shape=21, fill=vina$color, color="white", size=5.4, stroke=1.1) +
  geom_text(data=vina, aes(X,Y,label=num), color="white", family="gobCL", fontface="bold", size=2.7) +
  coord_equal(xlim=c(e[1],e[2]), ylim=c(e[3],e[4]), expand=FALSE) + theme_void()
agg_png("scratchpad_afiche/panel_vina.png", width=900, height=820, units="px", res=140, background="white")
print(g); dev.off()
cat("OK panel_vina.png  n=", nrow(vina), "\n")
