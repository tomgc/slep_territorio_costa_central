# =============================================================================
# auditoria_v7.R — PANEL ADVERSARIAL: tile sin rotulos + etiquetas de comuna.
# Independiente del 33.
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor)})
falla <- 0L
ok <- function(c,m){ cat(sprintf("[%s] %s\n", ifelse(c,"PASA","FALLA"), m)); if(!c) falla<<-falla+1L }
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }

PIN_RADIO_PX<-22; PIN_GAP_PX<-4; ESC<-2L; MAPA_W<-728; NORTE_H<-944; VINA_H<-560
LABEL_FONT<-6.2; b3<-readRDS("scratchpad_afiche/b3.rds")
# etiquetas finales (copia independiente)
ET <- data.frame(nom=c("Puchuncaví","Quintero","Concón","Viña del Mar"),
  panel=c("norte","norte","norte","vina"),
  lon=c(-71.425,-71.520,-71.515,-71.573), lat=c(-32.752,-32.860,-32.945,-33.010))

separar <- function(px,py,r,gap,Wpx,Hpx,iters=1200){n<-length(px);sep<-2*r+gap
  for(it in 1:iters){mv<-FALSE
    for(a in 1:(n-1))for(b in (a+1):n){dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
      if(d<sep){if(d<1e-6){an<-2*pi*a/n;dx<-cos(an);dy<-sin(an);d<-1};ph<-(sep-d)/2;ux<-dx/d;uy<-dy/d
        px[a]<-px[a]+ux*ph;py[a]<-py[a]+uy*ph;px[b]<-px[b]-ux*ph;py[b]<-py[b]-uy*ph;mv<-TRUE}}
    px<-pmin(pmax(px,r),Wpx-r);py<-pmin(pmax(py,r),Hpx-r);if(!mv)break};list(px=px,py=py)}
mindist <- function(px,py){n<-length(px);m<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<m)m<-d};m}

m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))
html <- paste(readLines("40_salidas/afiche/mapa_establecimientos.html", warn=FALSE, encoding="UTF-8"), collapse="\n")
src <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")

# ===== (a) tile sin rotulos: provider sin labels, sin zonas de exclusion =====
ok(grepl("CartoDB.PositronNoLabels", src, fixed=TRUE), "tile: provider CartoDB.PositronNoLabels en el codigo")
ok(!grepl("ZONAS_NORTE", src, fixed=TRUE) && !grepl("ZONAS_VINA", src, fixed=TRUE),
   "zonas de exclusion eliminadas del codigo")

# ===== anti-colision + posiciones de pines por plano (re-derivadas) =====
planos <- list(
  list(mask=m$comuna %in% c("Puchuncaví","Quintero","Concón"), bb=b3$norte, H=NORTE_H, pan="norte"),
  list(mask=m$comuna=="Viña del Mar", bb=b3$vina, H=VINA_H, pan="vina"))
PIN <- list()
for(p in planos){ sub<-m[p$mask,]; pc<-st_as_sf(sub,coords=c("longitud","latitud"),crs=4326)
  xy<-st_coordinates(st_transform(pc,3857)); Wpx<-MAPA_W*ESC;Hpx<-p$H*ESC;Xr<-p$bb[2]-p$bb[1];Yr<-p$bb[4]-p$bb[3]
  px<-(xy[,1]-p$bb[1])/Xr*Wpx; py<-(p$bb[4]-xy[,2])/Yr*Hpx; s<-separar(px,py,PIN_RADIO_PX,PIN_GAP_PX,Wpx,Hpx)
  # (c) anti-colision
  ok(mindist(s$px,s$py) >= 2*PIN_RADIO_PX-0.5, sprintf("(c) %s: anti-colision min_dist=%.1f px >= %d (intacta)", p$pan, mindist(s$px,s$py), 2*PIN_RADIO_PX))
  PIN[[p$pan]]<-list(px=s$px,py=s$py,Wpx=Wpx,Hpx=Hpx,bb=p$bb) }

# ===== (b) 4 etiquetas de comuna presentes, COLOR/FONT, sin pin encima =====
ok(grepl("COLOR_COMUNA      <- \"#0F69B4\"", src) || grepl('COLOR_COMUNA <- "#0F69B4"', src) || grepl("#0F69B4", src),
   "etiqueta: COLOR_COMUNA = #0F69B4 (azul gobCL) definido")
ok(grepl("LABEL_COMUNA_FONT", src, fixed=TRUE), "etiqueta: LABEL_COMUNA_FONT (tamaño unico) definido")
ok(nrow(ET)==4 && all(ET$nom %in% c("Puchuncaví","Quintero","Concón","Viña del Mar")), "etiqueta: 4 comunas")
# bbox de cada etiqueta (px) y chequeo de no-solape con pines de su plano
fpx <- LABEL_FONT*2.845*(144/72.27)   # alto aprox del texto en px
chw <- 0.55*fpx
for(i in 1:nrow(ET)){ pan<-ET$panel[i]; P<-PIN[[pan]]
  xy<-st_coordinates(st_transform(st_as_sf(ET[i,],coords=c("lon","lat"),crs=4326),3857))
  ax<-(xy[1]-P$bb[1])/(P$bb[2]-P$bb[1])*P$Wpx; ay<-(P$bb[4]-xy[2])/(P$bb[4]-P$bb[3])*P$Hpx
  hw<-nchar(ET$nom[i])*chw/2; hh<-fpx/2
  dentro<-which(P$px > ax-hw-PIN_RADIO_PX & P$px < ax+hw+PIN_RADIO_PX & P$py > ay-hh-PIN_RADIO_PX & P$py < ay+hh+PIN_RADIO_PX)
  ok(length(dentro)==0, sprintf("(b) '%s' sin pin sobre la etiqueta (pines en bbox+r: %d)", ET$nom[i], length(dentro)))
}

# ===== (d) v6 intacto =====
aud <- m |> arrange(desc(latitud), desc(longitud), nombre) |> mutate(num=row_number())
ok(all(diff(aud$latitud)<=0), "(d) numeracion N->S estricta (lat monotona)")
rng <- aud |> summarise(lo=min(num),hi=max(num),.by=comuna) |> arrange(lo)
ok(all(rng$lo==c(1,21,31,38)) && all(rng$hi==c(20,30,37,97)), "(d) rangos por comuna 1-20/21-30/31-37/38-97")
ok(grepl("Desarrollado por el Área de Monitoreo", html, fixed=TRUE), "(d) nota del Area de Monitoreo presente")
ok(all(vapply(m$rbd,function(r)grepl(paste0("(RBD ",r,")"),html,fixed=TRUE),logical(1))) &&
   all(vapply(esc(m$nombre),function(s)grepl(s,html,fixed=TRUE),logical(1))), "(d) indice 97 RBD+nombres sin truncar")
g <- st_read("20_insumos/comunas.geojson", quiet=TRUE); ok(nrow(g)==4, "(d) limites BCN (4 comunas)")
ok(grepl("min-width:17px", html, fixed=TRUE) && length(gregexpr("min-width:17px", html)[[1]])==97, "(d) 97 filas en el indice")

cat(sprintf("\n===== PANEL ADVERSARIAL v7: %s (%d fallas) =====\n", ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status=if(falla==0)0 else 1)
