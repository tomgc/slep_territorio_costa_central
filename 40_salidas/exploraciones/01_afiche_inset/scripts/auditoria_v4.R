# =============================================================================
# auditoria_v4.R — PANEL ADVERSARIAL (pines grandes, no-solape, zonas).
# Independiente del 33: re-implementa la proyeccion y la separacion 2D, y verifica
# la propiedad de no-solape sobre las posiciones re-derivadas. NO hace source(33).
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor)})
falla <- 0L
ok <- function(c,m){ cat(sprintf("[%s] %s\n", ifelse(c,"PASA","FALLA"), m)); if(!c) falla<<-falla+1L }
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }
norm <- function(x){ x<-tolower(trimws(as.character(x))); x<-iconv(x,to="ASCII//TRANSLIT"); gsub("[^a-z ]","",x) }

# ---- constantes (copia independiente de las del 33) ----
PIN_RADIO_PX <- 22; PIN_GAP_PX <- 4; ESC <- 2L; MAPA_W <- 728; NORTE_H <- 944; VINA_H <- 560
zona <- function(nom,cx,cy,hw,hh) data.frame(nom,xmin=cx-hw,xmax=cx+hw,ymin=cy-hh,ymax=cy+hh)
ZN <- rbind(zona("Maitencillo",700,122,100,32),zona("Puchuncavi",815,588,105,34),
  zona("Campiche",601,624,85,32),zona("Ventanas",441,681,95,32),
  zona("Quintero",233,941,95,32),zona("Concon",293,1735,78,32))
ZV <- zona("Vina del Mar",492,618,182,78)
b3 <- readRDS("scratchpad_afiche/b3.rds")

separar <- function(px,py,r,gap,Z,Wpx,Hpx,iters=1200){ n<-length(px); sep<-2*r+gap
  for(it in 1:iters){ moved<-FALSE
    for(a in 1:(n-1)) for(b in (a+1):n){ dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
      if(d<sep){ if(d<1e-6){ang<-2*pi*a/n;dx<-cos(ang);dy<-sin(ang);d<-1}
        ph<-(sep-d)/2;ux<-dx/d;uy<-dy/d; px[a]<-px[a]+ux*ph;py[a]<-py[a]+uy*ph;px[b]<-px[b]-ux*ph;py[b]<-py[b]-uy*ph;moved<-TRUE}}
    for(z in 1:nrow(Z)){ ins<-which(px>Z$xmin[z]-r&px<Z$xmax[z]+r&py>Z$ymin[z]-r&py<Z$ymax[z]+r)
      for(i in ins){ dl<-px[i]-(Z$xmin[z]-r);dr<-(Z$xmax[z]+r)-px[i];db<-py[i]-(Z$ymin[z]-r);dt<-(Z$ymax[z]+r)-py[i];m<-min(dl,dr,db,dt)
        if(m==dl)px[i]<-Z$xmin[z]-r else if(m==dr)px[i]<-Z$xmax[z]+r else if(m==db)py[i]<-Z$ymin[z]-r else py[i]<-Z$ymax[z]+r; moved<-TRUE}}
    px<-pmin(pmax(px,r),Wpx-r);py<-pmin(pmax(py,r),Hpx-r); if(!moved)break }
  list(px=px,py=py) }
mindist <- function(px,py){ n<-length(px);m<-Inf; for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<m)m<-d};m }

m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))

verif_plano <- function(cmask, bb, H, Z, etq){
  sub <- m[cmask,]; pc <- st_as_sf(sub, coords=c("longitud","latitud"), crs=4326)
  xy <- st_coordinates(st_transform(pc,3857)); Wpx<-MAPA_W*ESC; Hpx<-H*ESC; Xr<-bb[2]-bb[1]; Yr<-bb[4]-bb[3]
  px<-(xy[,1]-bb[1])/Xr*Wpx; py<-(bb[4]-xy[,2])/Yr*Hpx
  s<-separar(px,py,PIN_RADIO_PX,PIN_GAP_PX,Z,Wpx,Hpx); d<-mindist(s$px,s$py)
  inz<-0; for(z in 1:nrow(Z)) inz<-inz+sum(s$px>Z$xmin[z]&s$px<Z$xmax[z]&s$py>Z$ymin[z]&s$py<Z$ymax[z])
  ok(d >= 2*PIN_RADIO_PX-0.5, sprintf("%s: min_dist=%.1f px >= %d (2*PIN_RADIO)", etq, d, 2*PIN_RADIO_PX))
  ok(inz==0, sprintf("%s: 0 centros dentro de zonas de exclusion (%d)", etq, inz))
}
verif_plano(m$comuna %in% c("Puchuncaví","Quintero","Concón"), b3$norte, NORTE_H, ZN, "norte (37)")
verif_plano(m$comuna == "Viña del Mar", b3$vina, VINA_H, ZV, "vina (60)")

# ---- (c)/(d) afiche intacto ----
html <- paste(readLines("40_salidas/afiche/mapa_establecimientos.html", warn=FALSE, encoding="UTF-8"), collapse="\n")
tipo_ord <- c("Jardín infantil","Escuela básica","Liceo","Escuela especial","Centro de educación para jóvenes y adultos")
com_ord <- m |> summarise(la=mean(latitud), .by=comuna) |> arrange(desc(la)) |> pull(comuna)
aud <- m |> mutate(cf=factor(comuna,levels=com_ord), tf=factor(tipo_establecimiento,levels=tipo_ord)) |>
  arrange(cf,tf,nombre) |> mutate(num=row_number())
rng <- aud |> summarise(lo=min(num),hi=max(num),.by=comuna) |> arrange(lo)
ok(identical(sort(aud$num),1:97) && all(rng$lo==c(1,21,31,38)) && all(rng$hi==c(20,30,37,97)),
   "afiche: numeracion N->S 1..97 (rangos 1-20/21-30/31-37/38-97)")
ok(all(vapply(m$rbd,function(r)grepl(paste0("(RBD ",r,")"),html,fixed=TRUE),logical(1))) &&
   all(vapply(esc(m$nombre),function(s)grepl(s,html,fixed=TRUE),logical(1))),
   "afiche: indice con 97 RBD y 97 nombres completos")
src <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")
ok(!any(vapply(c("geom_label","geom_text_repel","geom_segment","x_sea","apretado"),
        function(p)grepl(p,src,fixed=TRUE),logical(1))), "afiche: sin etiquetas/leader lines en el mapa")
ok(grepl("Biblioteca del Congreso Nacional",html,fixed=TRUE), "afiche: atribucion BCN presente")
# limites BCN alta resolucion presentes (geojson actual)
g <- st_read("20_insumos/comunas.geojson", quiet=TRUE)
vtot <- sum(vapply(st_geometry(g[norm(g$Comuna)%in%c("puchuncavi","quintero","concon","vina del mar"),]),
                   function(x)nrow(st_coordinates(x)),integer(1)))
ok(nrow(g)==4 && vtot>10000, sprintf("afiche: limites BCN alta resolucion (4 comunas, %d vertices)", vtot))

cat(sprintf("\n===== PANEL ADVERSARIAL v4: %s (%d fallas) =====\n", ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status=if(falla==0)0 else 1)
