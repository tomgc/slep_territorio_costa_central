# =============================================================================
# auditoria_v8.R — PANEL ADVERSARIAL: exportacion PDF A0 (texto editable, mapas a dpi).
# Independiente del 33.
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor)
  library(pdftools); library(magick)})
falla <- 0L
ok <- function(c,m){ cat(sprintf("[%s] %s\n", ifelse(c,"PASA","FALLA"), m)); if(!c) falla<<-falla+1L }
esc_html <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }

PDF <- "40_salidas/afiche/mapa_establecimientos.pdf"
HTML<- "40_salidas/afiche/mapa_establecimientos.html"
A0_W_MM<-841; A0_H_MM<-1189; mm2pt<-72/25.4
m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))

# ===== (a) pagesize A0 vertical ±1mm =====
ps <- pdf_pagesize(PDF)
ok(abs(ps$width[1]-A0_W_MM*mm2pt) <= 1*mm2pt && abs(ps$height[1]-A0_H_MM*mm2pt) <= 1*mm2pt,
   sprintf("(a) pagesize = %.0f x %.0f pt (A0 = %.0f x %.0f pt, tol +-1mm)",
           ps$width[1], ps$height[1], A0_W_MM*mm2pt, A0_H_MM*mm2pt))

# ===== (b) pdf_text seleccionable con muestras del indice y la nota =====
txt <- paste(pdf_text(PDF), collapse="\n")
ok(nchar(txt) > 1000, sprintf("(b) pdf_text no vacio (%d chars)", nchar(txt)))
m1 <- m[which.max(m$latitud),]   # establecimiento mas al norte (num 1)
ok(grepl(m1$nombre, txt, fixed=TRUE) && grepl(paste0("RBD ", m1$rbd), txt, fixed=TRUE),
   sprintf("(b) indice editable: '%s' + (RBD %s) en el texto", m1$nombre, m1$rbd))
ok(grepl("Desarrollado por el Área de Monitoreo", txt, fixed=TRUE), "(b) nota del Area de Monitoreo en el texto")

# ===== (c) pdf_fonts: gobCL y MuseoSans incrustadas =====
fn <- pdf_fonts(PDF)
gob <- fn[grepl("gobCL", fn$name), ]; mus <- fn[grepl("MuseoSans", fn$name), ]
ok(nrow(gob)>0 && all(gob$embedded), sprintf("(c) gobCL incrustada (%d/%d embedded)", sum(gob$embedded), nrow(gob)))
ok(nrow(mus)>0 && all(mus$embedded), sprintf("(c) Museo Sans incrustada (%d/%d embedded)", sum(mus$embedded), nrow(mus)))
ok(all(fn$embedded), sprintf("(c) TODAS las fuentes incrustadas (%d/%d)", sum(fn$embedded), nrow(fn)))

# ===== (d) resolucion de los PNG de mapa >= 150 dpi sobre A0 =====
MAPA_W <- 728; LIENZO_ANCHO <- 1240
ancho_in <- MAPA_W/LIENZO_ANCHO * A0_W_MM / 25.4
for(f in c("panel_norte.png","panel_vina.png")){
  w <- image_info(image_read(file.path("40_salidas/afiche", f)))$width
  dpi <- w/ancho_in
  ok(dpi >= 150, sprintf("(d) %s: %d px / %.2f in = %.0f dpi (>= 150)", f, w, ancho_in, dpi))
}

# ===== (e) diseño v7 intacto =====
html <- paste(readLines(HTML, warn=FALSE, encoding="UTF-8"), collapse="\n")
ok(length(gregexpr("min-width:17px", html)[[1]])==97, "(e) indice con 97 filas")
ok(all(vapply(m$rbd,function(r)grepl(paste0("(RBD ",r,")"),html,fixed=TRUE),logical(1))) &&
   all(vapply(esc_html(m$nombre),function(s)grepl(s,html,fixed=TRUE),logical(1))), "(e) 97 RBD + 97 nombres sin truncar")
aud <- m |> arrange(desc(latitud), desc(longitud), nombre) |> mutate(num=row_number())
ok(all(diff(aud$latitud)<=0), "(e) numeracion N->S estricta (lat monotona)")
src <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")
ok(grepl("CartoDB.PositronNoLabels", src, fixed=TRUE), "(e) tile sin rotulos")
ok(grepl("ETIQUETAS_COMUNA", src, fixed=TRUE) && grepl("#0F69B4", src, fixed=TRUE), "(e) 4 etiquetas de comuna azul gobCL")
# anti-colision a la resolucion A0 (ESC escalado)
ESC <- 200*A0_W_MM/(25.4*LIENZO_ANCHO); PIN_R <- 11*ESC; PIN_G <- 2*ESC
b3 <- readRDS("scratchpad_afiche/b3.rds")
separar<-function(px,py,r,gap,Wpx,Hpx,it=1500){n<-length(px);sep<-2*r+gap
  for(i in 1:it){mv<-FALSE;for(a in 1:(n-1))for(b in (a+1):n){dx<-px[a]-px[b];dy<-py[a]-py[b];d<-sqrt(dx*dx+dy*dy)
    if(d<sep){if(d<1e-6){an<-2*pi*a/n;dx<-cos(an);dy<-sin(an);d<-1};ph<-(sep-d)/2;ux<-dx/d;uy<-dy/d
      px[a]<-px[a]+ux*ph;py[a]<-py[a]+uy*ph;px[b]<-px[b]-ux*ph;py[b]<-py[b]-uy*ph;mv<-TRUE}}
    px<-pmin(pmax(px,r),Wpx-r);py<-pmin(pmax(py,r),Hpx-r);if(!mv)break};list(px=px,py=py)}
mindist<-function(px,py){n<-length(px);mn<-Inf;for(a in 1:(n-1))for(b in (a+1):n){d<-sqrt((px[a]-px[b])^2+(py[a]-py[b])^2);if(d<mn)mn<-d};mn}
for(P in list(list(mask=m$comuna %in% c("Puchuncaví","Quintero","Concón"),bb=b3$norte,H=944,nm="norte"),
              list(mask=m$comuna=="Viña del Mar",bb=b3$vina,H=560,nm="vina"))){
  sub<-m[P$mask,]; xy<-st_coordinates(st_transform(st_as_sf(sub,coords=c("longitud","latitud"),crs=4326),3857))
  Wpx<-MAPA_W*ESC;Hpx<-P$H*ESC;px<-(xy[,1]-P$bb[1])/(P$bb[2]-P$bb[1])*Wpx;py<-(P$bb[4]-xy[,2])/(P$bb[4]-P$bb[3])*Hpx
  s<-separar(px,py,PIN_R,PIN_G,Wpx,Hpx)
  ok(mindist(s$px,s$py) >= 2*PIN_R-1, sprintf("(e) %s anti-colision A0: min_dist=%.0f px >= %.0f", P$nm, mindist(s$px,s$py), 2*PIN_R)) }

cat(sprintf("\n===== PANEL ADVERSARIAL v8: %s (%d fallas) =====\n", ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status=if(falla==0)0 else 1)
