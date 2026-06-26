# =============================================================================
# auditoria_v3.R — PANEL ADVERSARIAL del reemplazo de limites comunales (BCN).
# Independiente del 33. Compara fcortes (HEAD de git) vs BCN (geojson actual).
# =============================================================================
suppressMessages({library(sf); library(dplyr); library(readxl); library(janitor)})

falla <- 0L
ok <- function(cond, msg){ cat(sprintf("[%s] %s\n", ifelse(cond,"PASA","FALLA"), msg)); if(!cond) falla<<-falla+1L }
norm <- function(x){ x<-tolower(trimws(as.character(x))); x<-iconv(x,to="ASCII//TRANSLIT"); gsub("[^a-z ]","",x) }
esc  <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }
obj  <- c("puchuncavi","quintero","concon","vina del mar")
pares<- list(c("puchuncavi","quintero"),c("quintero","concon"),c("concon","vina del mar"))
vtx  <- function(g) sum(vapply(st_geometry(g), function(x) nrow(st_coordinates(x)), integer(1)))
solape <- function(s){ cn<-norm(s$Comuna)
  vapply(pares, function(p){ a<-s[cn==p[1],]; b<-s[cn==p[2],]
    ar<-tryCatch(as.numeric(st_area(st_intersection(st_union(a),st_union(b)))),error=function(e)NA)
    if(length(ar)==0) 0 else ar }, numeric(1)) }
prep <- function(g){ if(is.na(st_crs(g))) st_crs(g)<-4326
  g<-st_make_valid(g[norm(g$Comuna) %in% obj, ]); st_transform(g, 3857) }

NUEVO <- "20_insumos/comunas.geojson"
HTML  <- "40_salidas/afiche/mapa_establecimientos.html"

# ---- leer BCN (actual) y fcortes (HEAD de git) ----
bcn <- prep(st_read(NUEVO, quiet=TRUE))
ftmp <- tempfile(fileext=".geojson")
system2("git", c("show", "HEAD:20_insumos/comunas.geojson"), stdout=ftmp)
fco <- prep(st_read(ftmp, quiet=TRUE))

# ===== (a) las 4 comunas presentes con nombre correcto =====
ok(setequal(norm(bcn$Comuna), obj) && nrow(bcn)==4,
   sprintf("las 4 comunas presentes en el nuevo geojson (%d): %s",
           nrow(bcn), paste(bcn$Comuna, collapse=" | ")))

# ===== (b) interseccion de areas adyacentes ~ 0, antes vs despues =====
sa <- solape(bcn); sf <- solape(fco)
cat("=== solape (m2) por par adyacente ===\n")
for(i in seq_along(pares))
  cat(sprintf("  %-12s∩%-12s  fcortes=%12.1f   BCN=%8.2f\n",
              pares[[i]][1], pares[[i]][2], sf[i], sa[i]))
ok(all(sa < 100), sprintf("BCN: solapes ~0 (max %.2f m2 < 100)", max(sa)))
ok(all(sf > 1e5), sprintf("fcortes (antes) SI solapaba (min %.0f m2)", min(sf)))

# ===== (c) vertices BCN >> fcortes =====
cat("=== vertices por comuna ===\n")
vb <- vf <- setNames(integer(4), obj)
for(o in obj){ vb[o]<-vtx(bcn[norm(bcn$Comuna)==o,]); vf[o]<-vtx(fco[norm(fco$Comuna)==o,])
  cat(sprintf("  %-14s fcortes=%4d   BCN=%5d\n", o, vf[o], vb[o])) }
ok(all(vb > vf*5), "BCN: vertices >> fcortes (alta resolucion) en las 4 comunas")

# ===== (d) afiche intacto =====
m <- read_excel("20_insumos/maestro_establecimientos.xlsx") |> clean_names() |>
  mutate(nombre=nombre_del_establecimiento, rbd=as.character(rbd))
html <- paste(readLines(HTML, warn=FALSE, encoding="UTF-8"), collapse="\n")
tipo_ord <- c("Jardín infantil","Escuela básica","Liceo","Escuela especial","Centro de educación para jóvenes y adultos")
com_ord  <- m |> summarise(la=mean(latitud), .by=comuna) |> arrange(desc(la)) |> pull(comuna)
aud <- m |> mutate(comuna_f=factor(comuna, levels=com_ord), tipo_f=factor(tipo_establecimiento, levels=tipo_ord)) |>
  arrange(comuna_f, tipo_f, nombre) |> mutate(num=row_number())
rng <- aud |> summarise(lo=min(num), hi=max(num), .by=comuna) |> arrange(lo)
esp <- data.frame(lo=c(1,21,31,38), hi=c(20,30,37,97))
ok(identical(sort(aud$num),1:97) && isTRUE(all.equal(rng$lo,esp$lo)) && isTRUE(all.equal(rng$hi,esp$hi)),
   "afiche: numeracion N->S 1..97, rangos 1-20/21-30/31-37/38-97")
rbd_ok <- all(vapply(m$rbd, function(r) grepl(paste0("(RBD ",r,")"),html,fixed=TRUE), logical(1)))
nom_ok <- all(vapply(esc(m$nombre), function(s) grepl(s,html,fixed=TRUE), logical(1)))
ok(rbd_ok && nom_ok, "afiche: indice con 97 RBD y 97 nombres completos")
src <- paste(readLines("30_procesamiento/33_generar_afiche.R", warn=FALSE), collapse="\n")
poda <- !any(vapply(c("geom_label","geom_text_repel","geom_label_repel","geom_segment","x_sea","apretado","y_et"),
                    function(p) grepl(p,src,fixed=TRUE), logical(1)))
ok(poda, "afiche: sin etiquetas ni leader lines en el mapa (poda v2 intacta)")
ok(!grepl("st_within|st_contains|st_intersection\\(.*est|st_filter|st_join", src) ||
   !grepl("filter.*st_", src),
   "afiche: los puntos no se filtran por contencion en poligono (🔒-3)")

# ===== (e) atribucion BCN + .shp no versionado =====
ok(grepl("Biblioteca del Congreso Nacional", html, fixed=TRUE), "atribucion BCN presente en el HTML")
tracked <- system2("git", c("ls-files", "20_insumos/comunas_bcn/"), stdout=TRUE)
ok(length(tracked)==0, sprintf("comunas_bcn/ NO trackeado en git (%d archivos)", length(tracked)))

cat(sprintf("\n===== PANEL ADVERSARIAL v3: %s (%d fallas) =====\n",
            ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status = if(falla==0) 0 else 1)
