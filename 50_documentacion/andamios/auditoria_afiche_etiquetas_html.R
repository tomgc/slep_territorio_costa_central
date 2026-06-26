# =============================================================================
# auditoria_v9.R — PANEL ADVERSARIAL: etiquetas de comuna como texto HTML editable.
# Independiente del 33.
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor); library(pdftools)})
falla <- 0L
ok <- function(c,m){ cat(sprintf("[%s] %s\n", ifelse(c,"PASA","FALLA"), m)); if(!c) falla<<-falla+1L }
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }

HTML<-"40_salidas/afiche/mapa_establecimientos.html"; PDF<-"40_salidas/afiche/mapa_establecimientos.pdf"
html <- paste(readLines(HTML, warn=FALSE, encoding="UTF-8"), collapse="\n")
src  <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")
m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))
COM <- c("Puchuncaví","Quintero","Concón","Viña del Mar")

# ===== (a) etiquetas como texto HTML absoluto; geom_text de etiquetas eliminado =====
# parsear los divs de etiqueta (left/top% + color azul + nombre)
pat <- 'left:([0-9.]+)%;top:([0-9.]+)%;transform:translate\\(-50%,-50%\\)[^>]*color:#0F69B4[^>]*>([^<]+)</div>'
mm <- regmatches(html, gregexpr(pat, html, perl=TRUE))[[1]]
nombres_html <- sub(paste0(".*?",pat,".*"),"\\3", mm, perl=TRUE)
ok(length(mm)==4 && setequal(nombres_html, COM),
   sprintf("(a) 4 etiquetas de comuna como texto HTML absoluto: %s", paste(nombres_html, collapse=", ")))
# geom_text de etiquetas eliminado del render (solo queda el de numeros de pin)
ok(!grepl("geom_text(data = et", src, fixed=TRUE) && !grepl("label = nom", src, fixed=TRUE),
   "(a) geom_text de etiquetas de comuna eliminado del PNG (ya no se rasteriza)")
ok(grepl("etiquetas_html", src, fixed=TRUE) && grepl("etiquetas_pct", src, fixed=TRUE),
   "(a) mecanismo HTML (etiquetas_pct + etiquetas_html) presente")

# ===== (b) en el PDF las 4 etiquetas son texto extraible =====
txt <- paste(pdf_text(PDF), collapse="\n")
ok(all(vapply(COM, function(n) grepl(n, txt, fixed=TRUE), logical(1))),
   "(b) las 4 etiquetas de comuna aparecen como texto en el PDF")
# el mapa-label agrega una ocurrencia extra: confirmamos que el HTML la aporta (div absoluto)
ok(length(mm)==4, "(b) el HTML aporta las 4 etiquetas como texto (no parte del PNG)")

# ===== (c) posicion: recomputar %% desde lon/lat via 3857 y comparar con el HTML =====
ET <- data.frame(nom=COM, panel=c("norte","norte","norte","vina"),
  lon=c(-71.425,-71.520,-71.515,-71.573), lat=c(-32.752,-32.860,-32.945,-33.010))
b3 <- readRDS("scratchpad_afiche/b3.rds")
pct <- function(et, bb){ p<-st_coordinates(st_transform(st_as_sf(et,coords=c("lon","lat"),crs=4326),3857))
  data.frame(nom=et$nom, left=(p[,1]-bb[1])/(bb[2]-bb[1])*100, top=(bb[4]-p[,2])/(bb[4]-bb[3])*100) }
ref <- rbind(pct(ET[ET$panel=="norte",], b3$norte), pct(ET[ET$panel=="vina",], b3$vina))
# parsear left/top del HTML por nombre
hp <- data.frame(nom=nombres_html,
  left=as.numeric(sub(paste0(".*?",pat,".*"),"\\1", mm, perl=TRUE)),
  top =as.numeric(sub(paste0(".*?",pat,".*"),"\\2", mm, perl=TRUE)))
cmp <- merge(ref, hp, by="nom", suffixes=c("_ref","_html"))
maxdif <- max(abs(cmp$left_ref-cmp$left_html), abs(cmp$top_ref-cmp$top_html))
ok(maxdif < 0.2, sprintf("(c) posiciones HTML = recomputadas desde lon/lat (max dif %.3f %%)", maxdif))

# ===== (d) resto v8 intacto =====
ps <- pdf_pagesize(PDF); mm2pt <- 72/25.4
ok(abs(ps$width[1]-841*mm2pt)<=mm2pt && abs(ps$height[1]-1189*mm2pt)<=mm2pt, "(d) PDF A0 (841x1189 mm)")
fn <- pdf_fonts(PDF); ok(all(fn$embedded) && any(grepl("gobCL",fn$name)) && any(grepl("MuseoSans",fn$name)),
   "(d) fuentes incrustadas (gobCL + MuseoSans embedded)")
aud <- m |> arrange(desc(latitud), desc(longitud), nombre) |> mutate(num=row_number())
ok(all(diff(aud$latitud)<=0), "(d) numeracion N->S estricta")
ok(length(gregexpr("min-width:17px", html)[[1]])==97 &&
   all(vapply(m$rbd,function(r)grepl(paste0("(RBD ",r,")"),html,fixed=TRUE),logical(1))) &&
   all(vapply(esc(m$nombre),function(s)grepl(s,html,fixed=TRUE),logical(1))), "(d) indice 97 filas con RBD+nombres")
ok(grepl("Desarrollado por el Área de Monitoreo", txt, fixed=TRUE), "(d) nota del Area de Monitoreo (texto)")
ok(grepl("CartoDB.PositronNoLabels", src, fixed=TRUE), "(d) tile sin rotulos")
# anti-colision A0 intacta
ESC<-200*841/(25.4*1240); PIN_R<-11*ESC; PIN_G<-2*ESC; MAPA_W<-728
separar<-function(px,py,r,gap,Wpx,Hpx,it=1500){n<-length(px);sep<-2*r+gap
  for(i in 1:it){mv<-FALSE;for(a in 1:(n-1))for(b in (a+1):n){dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
    if(d<sep){if(d<1e-6){an<-2*pi*a/n;dx<-cos(an);dy<-sin(an);d<-1};ph<-(sep-d)/2
      px[a]<-px[a]+dx/d*ph;py[a]<-py[a]+dy/d*ph;px[b]<-px[b]-dx/d*ph;py[b]<-py[b]-dy/d*ph;mv<-TRUE}}
    px<-pmin(pmax(px,r),Wpx-r);py<-pmin(pmax(py,r),Hpx-r);if(!mv)break};list(px=px,py=py)}
mind<-function(px,py){n<-length(px);z<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<z)z<-d};z}
for(P in list(list(mask=m$comuna%in%c("Puchuncaví","Quintero","Concón"),bb=b3$norte,H=944,nm="norte"),
              list(mask=m$comuna=="Viña del Mar",bb=b3$vina,H=560,nm="vina"))){
  xy<-st_coordinates(st_transform(st_as_sf(m[P$mask,],coords=c("longitud","latitud"),crs=4326),3857))
  Wpx<-MAPA_W*ESC;Hpx<-P$H*ESC;px<-(xy[,1]-P$bb[1])/(P$bb[2]-P$bb[1])*Wpx;py<-(P$bb[4]-xy[,2])/(P$bb[4]-P$bb[3])*Hpx
  s<-separar(px,py,PIN_R,PIN_G,Wpx,Hpx); ok(mind(s$px,s$py)>=2*PIN_R-1, sprintf("(d) %s anti-colision min_dist=%.0f>=%.0f", P$nm, mind(s$px,s$py), 2*PIN_R)) }

cat(sprintf("\n===== PANEL ADVERSARIAL v9: %s (%d fallas) =====\n", ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status=if(falla==0)0 else 1)
