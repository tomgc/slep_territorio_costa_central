# Desarrollo iterativo del render cartografico (scratch). No es entregable.
suppressMessages({
  library(dplyr); library(sf); library(maptiles); library(terra)
  library(ggplot2); library(ragg); library(ggrepel)
})
source("10_utils/10_configuracion.R")

# ---- fuentes ----
ff <- here::here("design_handoff_mapa_establecimientos","fonts")
try(systemfonts::register_font(name="Museo Sans",
    plain=file.path(ff,"MuseoSans-300.otf"), bold=file.path(ff,"MuseoSans_500.otf")), silent=TRUE)
try(systemfonts::register_font(name="gobCL",
    plain=file.path(ff,"gobCL_Regular.otf"), bold=file.path(ff,"gobCL_Heavy.otf")), silent=TRUE)

# ---- numeracion N->S ----
TIPO_ORDEN <- c("jardin","basica","liceo","especial","adultos")
est <- readRDS("40_salidas/establecimientos_validados.rds") |>
  mutate(comuna_chr=as.character(comuna),
         comuna_f=factor(comuna_chr, levels=COMUNAS_ORDEN),
         tipo_f=factor(tipo, levels=TIPO_ORDEN)) |>
  arrange(comuna_f, tipo_f, nombre) |>
  mutate(num=row_number(),
         color=TIPOS$color[match(tipo, TIPOS$key)])

# ---- tiles helper: SpatRaster CARTO -> annotation_raster args ----
get_carto <- function(bb4326, zoom){
  bb4326 <- as.numeric(bb4326)
  poly <- st_as_sfc(st_bbox(c(xmin=bb4326[1],ymin=bb4326[2],xmax=bb4326[3],ymax=bb4326[4]), crs=4326))
  poly <- st_transform(poly, 3857)   # tiles vuelven en 3857 (metros planos)
  tiles <- get_tiles(poly, provider="CartoDB.Positron", zoom=zoom, crop=TRUE, cachedir=tempdir())
  arr <- terra::as.array(tiles)
  img <- matrix(grDevices::rgb(arr[,,1],arr[,,2],arr[,,3], maxColorValue=255), nrow=dim(arr)[1])
  e <- as.vector(terra::ext(tiles))  # xmin xmax ymin ymax (3857)
  list(img=img, xmin=e[1], xmax=e[2], ymin=e[3], ymax=e[4])
}

# ---- panel norte: bbox de las 3 comunas chicas, extendido al oeste ----
chicas <- est |> filter(comuna_chr %in% c("Puchuncaví","Quintero","Concón"))
pc <- st_as_sf(chicas, coords=c("longitud","latitud"), crs=4326)
bb <- st_bbox(pc)
# margenes: oeste amplio (oceano para etiquetas), resto moderado
xmin <- bb["xmin"] - 0.075; xmax <- bb["xmax"] + 0.020
ymin <- bb["ymin"] - 0.020; ymax <- bb["ymax"] + 0.015
cat(sprintf("bbox panel norte: lon[%.3f,%.3f] lat[%.3f,%.3f]\n", xmin,xmax,ymin,ymax))

tl <- get_carto(c(xmin,ymin,xmax,ymax), zoom=12)

# puntos a 3857
p3857 <- st_transform(pc, 3857)
xy <- st_coordinates(p3857)
chicas$X <- xy[,1]; chicas$Y <- xy[,2]

# dispersion leve (declustering radial) por comuna: separa puntos encimados a una
# distancia visual minima, conservando la ubicacion real lo mas posible.
decluster <- function(df, dmin, iters=120){
  X <- df$X; Y <- df$Y
  for(cc in unique(df$comuna_chr)){
    idx <- which(df$comuna_chr==cc); k <- length(idx)
    if(k<2) next
    ord <- order(df$num[idx])           # angulo determinista para coincidentes
    for(t in seq_along(idx)){ i<-idx[ord[t]]
      X[i]<-X[i]+cos(2*pi*t/k)*dmin*0.01; Y[i]<-Y[i]+sin(2*pi*t/k)*dmin*0.01 }
    for(it in 1:iters){ moved<-FALSE
      for(a in 1:(k-1)) for(b in (a+1):k){ i<-idx[a]; j<-idx[b]
        dx<-X[i]-X[j]; dy<-Y[i]-Y[j]; d<-sqrt(dx*dx+dy*dy)
        if(d<dmin){ push<-(dmin-d)/2; ux<-dx/d; uy<-dy/d
          X[i]<-X[i]+ux*push; Y[i]<-Y[i]+uy*push
          X[j]<-X[j]-ux*push; Y[j]<-Y[j]-uy*push; moved<-TRUE } }
      if(!moved) break }
  }
  df$X<-X; df$Y<-Y; df
}
chicas <- decluster(chicas, dmin=0.013*(tl$xmax - tl$xmin))

# ---- apretado: NN<450m en UTM 19S, por comuna ----
pm <- st_transform(pc, 32719); cm <- st_coordinates(pm)
chicas$mx <- cm[,1]; chicas$my <- cm[,2]
chicas$nn <- NA_real_
for(cc in unique(chicas$comuna_chr)){
  idx <- which(chicas$comuna_chr==cc)
  if(length(idx)>1){
    D <- as.matrix(dist(cbind(chicas$mx[idx], chicas$my[idx]))); diag(D) <- Inf
    chicas$nn[idx] <- apply(D, 1, min)
  } else chicas$nn[idx] <- Inf
}
chicas$apretado <- chicas$nn < 450

# ---- envoltura de nombres (no truncar: se ajusta a 2 lineas) ----
wrap_nombre <- function(x, w=26) vapply(x, function(s) paste(strwrap(s, width=w), collapse="\n"), character(1))

# ---- layout etiquetas al mar: columna unica oeste, anti-colision 1D ----
Xr <- tl$xmax - tl$xmin; Yr <- tl$ymax - tl$ymin
x_sea <- tl$xmin + 0.34*Xr                 # ancla de la columna oceanica
gap   <- Yr/28                              # alto minimo entre cajas
mar <- chicas |> filter(apretado) |> arrange(Y)   # sur->norte (Y asc)
yv <- mar$Y
for(i in 2:length(yv)) if(yv[i]-yv[i-1] < gap) yv[i] <- yv[i-1]+gap
# si rebasa el tope, desplaza todo abajo
over <- max(yv) - (tl$ymax - 0.02*Yr); if(over>0) yv <- yv - over
under <- (tl$ymin + 0.02*Yr) - min(yv); if(under>0) yv <- yv + under
mar$y_et <- yv
mar$etiqueta <- paste0(mar$num, "  ", wrap_nombre(mar$nombre))

# tierra: no apretados, etiqueta junto al punto (repel hacia el este)
tierra <- chicas |> filter(!apretado)
tierra$etiqueta <- paste0(tierra$num, "  ", tierra$nombre)

# ---- render ----
g <- ggplot() +
  annotation_raster(tl$img, tl$xmin, tl$xmax, tl$ymin, tl$ymax) +
  # leader lines al mar
  geom_segment(data=mar, aes(x=X, y=Y, xend=x_sea, yend=y_et),
               color="#5b6670", linewidth=0.3) +
  # etiquetas al mar (caja, ancladas a la derecha en x_sea)
  geom_label(data=mar, aes(x=x_sea, y=y_et, label=etiqueta),
             hjust=1, vjust=0.5, size=2.4, family="Museo Sans", lineheight=0.9,
             label.size=0.15, label.padding=unit(1.3,"pt"), label.r=unit(2,"pt"),
             fill="white", color="#2E2230") +
  # etiquetas en tierra (confinadas al este: nunca cruzan al mar)
  ggrepel::geom_label_repel(data=tierra, aes(X,Y,label=etiqueta),
             size=2.4, family="Museo Sans", color="#2E2230",
             xlim=c(tl$xmin+0.46*Xr, tl$xmax), ylim=c(tl$ymin, tl$ymax),
             box.padding=0.35, point.padding=0.25, label.size=0.15,
             label.padding=unit(1.3,"pt"), label.r=unit(2,"pt"), fill="white",
             segment.size=0.25, segment.color="#5b6670", min.segment.length=0,
             seed=42, max.overlaps=Inf, max.time=1, max.iter=20000) +
  # puntos + numero
  geom_point(data=chicas, aes(X,Y), shape=21, fill=chicas$color, color="white",
             size=4.4, stroke=1) +
  geom_text(data=chicas, aes(X,Y,label=num), color="white",
            family="gobCL", fontface="bold", size=2.5) +
  coord_equal(xlim=c(tl$xmin,tl$xmax), ylim=c(tl$ymin,tl$ymax), expand=FALSE) +
  theme_void()

agg_png("scratchpad_afiche/panel_norte.png", width=820, height=1240, units="px", res=130, background="white")
print(g)
dev.off()

# zoom arriba (Puchuncaví) y abajo (nudo Quintero+Concón)
zoom <- function(file, ylo, yhi){
  agg_png(file, width=900, height=760, units="px", res=150, background="white")
  print(g + coord_equal(xlim=c(tl$xmin, tl$xmin+0.62*Xr),
                        ylim=c(tl$ymin+ylo*Yr, tl$ymin+yhi*Yr), expand=FALSE))
  dev.off()
}
zoom("scratchpad_afiche/zoom_top.png",   0.52, 1.0)
zoom("scratchpad_afiche/zoom_bottom.png", 0.0, 0.50)
cat(sprintf("OK panel_norte.png + zooms | mar=%d tierra=%d\n", nrow(mar), nrow(tierra)))
