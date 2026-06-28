# =============================================================================
# auditoria_v6.R — PANEL ADVERSARIAL: numeracion N->S estricta + nota + indice.
# Independiente del 33.
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor)})
falla <- 0L
ok <- function(c,m){ cat(sprintf("[%s] %s\n", ifelse(c,"PASA","FALLA"), m)); if(!c) falla<<-falla+1L }
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }

PIN_RADIO_PX<-22; PIN_GAP_PX<-4; ESC<-2L; MAPA_W<-728; NORTE_H<-944; VINA_H<-560
zona<-function(nom,cx,cy,hw,hh)data.frame(nom,xmin=cx-hw,xmax=cx+hw,ymin=cy-hh,ymax=cy+hh)
ZN<-rbind(zona("Mai",700,122,100,32),zona("Puc",815,588,105,34),zona("Cam",601,624,85,32),
  zona("Ven",441,681,95,32),zona("Qui",233,941,95,32),zona("Con",293,1735,78,32))
ZV<-zona("VdM",492,618,182,78); b3<-readRDS("scratchpad_afiche/b3.rds")
separar<-function(px,py,r,gap,Z,Wpx,Hpx,iters=1200){n<-length(px);sep<-2*r+gap
  for(it in 1:iters){mv<-FALSE
    for(a in 1:(n-1))for(b in (a+1):n){dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
      if(d<sep){if(d<1e-6){an<-2*pi*a/n;dx<-cos(an);dy<-sin(an);d<-1};ph<-(sep-d)/2;ux<-dx/d;uy<-dy/d
        px[a]<-px[a]+ux*ph;py[a]<-py[a]+uy*ph;px[b]<-px[b]-ux*ph;py[b]<-py[b]-uy*ph;mv<-TRUE}}
    for(z in 1:nrow(Z)){ins<-which(px>Z$xmin[z]-r&px<Z$xmax[z]+r&py>Z$ymin[z]-r&py<Z$ymax[z]+r)
      for(i in ins){dl<-px[i]-(Z$xmin[z]-r);dr<-(Z$xmax[z]+r)-px[i];db<-py[i]-(Z$ymin[z]-r);dt<-(Z$ymax[z]+r)-py[i];m<-min(dl,dr,db,dt)
        if(m==dl)px[i]<-Z$xmin[z]-r else if(m==dr)px[i]<-Z$xmax[z]+r else if(m==db)py[i]<-Z$ymin[z]-r else py[i]<-Z$ymax[z]+r;mv<-TRUE}}
    px<-pmin(pmax(px,r),Wpx-r);py<-pmin(pmax(py,r),Hpx-r);if(!mv)break};list(px=px,py=py)}
mindist<-function(px,py){n<-length(px);m<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<m)m<-d};m}

m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))
html <- paste(readLines("40_salidas/afiche/mapa_establecimientos.html", warn=FALSE, encoding="UTF-8"), collapse="\n")

# ===== (a) numeracion N->S ESTRICTA por latitud =====
aud <- m |> arrange(desc(latitud), desc(longitud), nombre) |> mutate(num=row_number())
ok(all(diff(aud$latitud) <= 0), "numeracion estricta: lat[i] >= lat[i+1] para todo i")
ok(identical(sort(aud$num),1:97), "1..97 sin huecos ni duplicados")
rng <- aud |> summarise(lo=min(num),hi=max(num),.by=comuna) |> arrange(lo)
ok(all(rng$lo==c(1,21,31,38)) && all(rng$hi==c(20,30,37,97)),
   "rangos por comuna 1-20/21-30/31-37/38-97 (se mantienen)")
ref <- c("Escuela Básica La Laguna","Jardín Infantil Mi Mundo Feliz","Colegio Maitencillo",
  "Escuela Básica La Quebrada","Escuela Básica El Rungue","Jardín Infantil Los Conejitos",
  "Escuela Horcón","Jardín Infantil Sirenita","Escuela Básica El Rincón",
  "Jardín Infantil Semillita de Puchuncaví","Colegio General José Velásquez Bórquez",
  "Escuela La Chocota","Escuela Multidéficit Amanecer","Jardín Infantil Renacer",
  "Escuela Campiche","Colegio La Greda","Complejo Educacional Sargento Aldea",
  "Jardín Infantil Caballito de Mar","Escuela Pucalán","Escuela Los Maquis")
ok(identical(aud$nombre[aud$comuna=="Puchuncaví"], ref), "Puchuncaví 1-20 = referencia del encargo")

# ===== (b) numero del indice = numeracion geografica, 1:1 =====
pat <- 'text-align:right">([0-9]+)</span>\\s*<span[^>]*line-height:1.2[^>]*>(.*?) <span[^>]*>\\(RBD ([0-9]+)\\)</span></span>'
mm <- regmatches(html, gregexpr(pat, html, perl=TRUE))[[1]]
nh <- as.integer(sub(paste0(".*?",pat,".*"),"\\1",mm,perl=TRUE))
noh<- sub(paste0(".*?",pat,".*"),"\\2",mm,perl=TRUE)
ok(length(nh)==97 && identical(sort(nh),1:97), sprintf("indice: 97 filas num+nombre+RBD (%d)", length(nh)))
idx <- data.frame(num=nh, nombre=noh) |> arrange(num)
refidx <- aud |> transmute(num, nombre=esc(nombre)) |> arrange(num)
ok(all(idx$nombre==refidx$nombre), sprintf("indice num->nombre 1:1 con numeracion geografica (%d/97)", sum(idx$nombre==refidx$nombre)))

# ===== (c) nota de fuente: texto nuevo presente, viejo ausente =====
nuevo <- "Desarrollado por el Área de Monitoreo a partir de datos de OpenStreetMap, CARTO (Positron), los límites comunales publicados por la Biblioteca del Congreso Nacional de Chile (BCN) y el maestro de establecimientos del SLEP Costa Central, de elaboración propia."
viejo <- "Fondo cartográfico © OpenStreetMap · © CARTO (Positron)."
ok(grepl(nuevo, html, fixed=TRUE), "nota: texto NUEVO presente literal")
ok(!grepl(viejo, html, fixed=TRUE), "nota: texto VIEJO ausente")

# ===== (d) afiche intacto: anti-colision, RBD/nombres, limites BCN =====
verif <- function(cmask, bb, H, Z, etq){ sub<-m[cmask,]; pc<-st_as_sf(sub,coords=c("longitud","latitud"),crs=4326)
  xy<-st_coordinates(st_transform(pc,3857)); Wpx<-MAPA_W*ESC;Hpx<-H*ESC;Xr<-bb[2]-bb[1];Yr<-bb[4]-bb[3]
  px<-(xy[,1]-bb[1])/Xr*Wpx;py<-(bb[4]-xy[,2])/Yr*Hpx; s<-separar(px,py,PIN_RADIO_PX,PIN_GAP_PX,Z,Wpx,Hpx)
  ok(mindist(s$px,s$py) >= 2*PIN_RADIO_PX-0.5, sprintf("%s: anti-colision min_dist=%.1f px >= %d", etq, mindist(s$px,s$py), 2*PIN_RADIO_PX)) }
verif(m$comuna %in% c("Puchuncaví","Quintero","Concón"), b3$norte, NORTE_H, ZN, "norte")
verif(m$comuna=="Viña del Mar", b3$vina, VINA_H, ZV, "vina")
ok(all(vapply(m$rbd,function(r)grepl(paste0("(RBD ",r,")"),html,fixed=TRUE),logical(1))) &&
   all(vapply(esc(m$nombre),function(s)grepl(s,html,fixed=TRUE),logical(1))), "indice: 97 RBD y 97 nombres completos (sin truncar)")
g <- st_read("20_insumos/comunas.geojson", quiet=TRUE)
ok(nrow(g)==4, "limites BCN: 4 comunas en el geojson")
src <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")
ok(!any(vapply(c("geom_label","geom_text_repel","geom_segment"),function(p)grepl(p,src,fixed=TRUE),logical(1))),
   "afiche: sin etiquetas de establecimiento ni leader lines")

cat(sprintf("\n===== PANEL ADVERSARIAL v6: %s (%d fallas) =====\n", ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status=if(falla==0)0 else 1)
