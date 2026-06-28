# =============================================================================
# auditoria_v2.R — PANEL ADVERSARIAL del afiche simplificado (encargo v2).
# Independiente del 33: re-deriva desde el maestro crudo y contrasta con el HTML
# y el codigo. NO hace source() del 33.
# =============================================================================
suppressMessages({library(readxl); library(janitor); library(dplyr)})

MAESTRO <- "20_insumos/maestro_establecimientos.xlsx"
HTML    <- "40_salidas/afiche/mapa_establecimientos.html"
SCRIPT  <- "30_procesamiento/33_generar_afiche.R"
falla <- 0L
ok <- function(cond, msg){ cat(sprintf("[%s] %s\n", ifelse(cond,"PASA","FALLA"), msg)); if(!cond) falla<<-falla+1L }
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }

m <- read_excel(MAESTRO) |> clean_names() |>
  mutate(nombre = nombre_del_establecimiento, rbd = as.character(rbd))
cat(sprintf("Maestro: %d filas\n", nrow(m)))

# ---- numeracion independiente (comuna por lat media -> tipo -> nombre) ----
tipo_ord <- c("Jardín infantil","Escuela básica","Liceo","Escuela especial",
              "Centro de educación para jóvenes y adultos")
com_ord <- m |> summarise(la=mean(latitud), .by=comuna) |> arrange(desc(la)) |> pull(comuna)
aud <- m |>
  mutate(comuna_f=factor(comuna, levels=com_ord),
         tipo_f  =factor(tipo_establecimiento, levels=tipo_ord)) |>
  arrange(comuna_f, tipo_f, nombre) |>
  mutate(num=row_number())

# ===== CHECK (a): numeracion 1..97 sin huecos + rangos por comuna =====
ok(identical(sort(aud$num),1:97), "numeracion 1..97 sin huecos ni duplicados")
rng <- aud |> summarise(lo=min(num), hi=max(num), .by=comuna) |> arrange(lo) |> as.data.frame()
print(rng)
esp <- data.frame(comuna=com_ord, lo=c(1,21,31,38), hi=c(20,30,37,97))
ok(isTRUE(all.equal(rng$lo,esp$lo)) && isTRUE(all.equal(rng$hi,esp$hi)),
   "rangos por comuna = 1-20 / 21-30 / 31-37 / 38-97")

# ===== CHECK (b): 97 puntos 1:1, sin filtro de poligono (🔒-3) =====
src <- paste(readLines(SCRIPT, warn=FALSE), collapse="\n")
ok(!grepl("st_within|st_contains|st_intersection|st_filter|st_join", src),
   "el 33 NO filtra puntos por contencion en poligono (🔒-3)")
n_chicas <- sum(m$comuna %in% c("Puchuncaví","Quintero","Concón"))
n_vina   <- sum(m$comuna == "Viña del Mar")
ok(n_chicas+n_vina==97 && n_chicas==37 && n_vina==60,
   sprintf("particion render: norte=%d + vina=%d = 97 (sin perdidas)", n_chicas, n_vina))

# ===== CHECK (c): indice con numero + nombre + RBD para los 97 =====
html <- paste(readLines(HTML, warn=FALSE, encoding="UTF-8"), collapse="\n")
# grep de cada RBD y cada nombre
rbd_pres <- vapply(m$rbd, function(r) grepl(paste0("(RBD ", r, ")"), html, fixed=TRUE), logical(1))
ok(all(rbd_pres), sprintf("los 97 RBD aparecen en el HTML (%d/97)", sum(rbd_pres)))
nom_pres <- vapply(esc(m$nombre), function(s) grepl(s, html, fixed=TRUE), logical(1))
ok(all(nom_pres), sprintf("los 97 nombres completos aparecen en el HTML (%d/97)", sum(nom_pres)))
# parse de filas (num, nombre, rbd) y cruce 1:1 con la numeracion independiente
pat <- 'text-align:right">([0-9]+)</span>\\s*<span[^>]*line-height:1.2[^>]*>(.*?) <span[^>]*>\\(RBD ([0-9]+)\\)</span></span>'
mm <- regmatches(html, gregexpr(pat, html, perl=TRUE))[[1]]
num_h <- as.integer(sub(paste0(".*?",pat,".*"),"\\1", mm, perl=TRUE))
nom_h <- sub(paste0(".*?",pat,".*"),"\\2", mm, perl=TRUE)
rbd_h <- sub(paste0(".*?",pat,".*"),"\\3", mm, perl=TRUE)
ok(length(num_h)==97 && identical(sort(num_h),1:97),
   sprintf("el indice tiene 97 filas num+nombre+RBD (encontradas=%d)", length(num_h)))
idx <- data.frame(num=num_h, nombre=nom_h, rbd=rbd_h, stringsAsFactors=FALSE) |> arrange(num)
ref <- aud |> transmute(num, nombre=esc(nombre), rbd) |> arrange(num)
cmp <- merge(idx, ref, by="num", suffixes=c("_html","_aud"))
ok(all(cmp$nombre_html==cmp$nombre_aud) && all(cmp$rbd_html==cmp$rbd_aud),
   sprintf("indice 1:1 num->(nombre,RBD) vs maestro independiente (%d/97)",
           sum(cmp$nombre_html==cmp$nombre_aud & cmp$rbd_html==cmp$rbd_aud)))

# ===== CHECK (d): poda efectiva — sin etiquetas/leader lines en el mapa =====
# El render del mapa es PNG; se verifica en el codigo del 33 que no quedan
# constructos de etiqueta/linea. El unico texto admitido es el numero del pin.
norte_fn <- sub(".*render_panel_norte <- function.*?\\n(.*?)\\n\\}.*", "\\1",
                src, perl=TRUE)  # cuerpo aproximado
# constructos de codigo (no palabras de comentario): geoms de etiqueta/linea +
# logica de anti-colision/etiqueta al mar. Si alguno persiste, la poda no fue total.
prohibidos <- c("geom_label", "geom_text_repel", "geom_label_repel",
                "geom_segment", "x_sea", "apretado", "UMBRAL_APRETADO",
                "y_et", "geom_label(", "geom_richtext")
hay <- prohibidos[vapply(prohibidos, function(p) grepl(p, src, fixed=TRUE), logical(1))]
ok(length(hay)==0,
   sprintf("poda efectiva: sin constructos de etiqueta/linea en el 33 (%s)",
           if(length(hay)) paste("quedan:", paste(hay, collapse=",")) else "ninguno"))

cat(sprintf("\n===== PANEL ADVERSARIAL v2: %s (%d fallas) =====\n",
            ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status = if(falla==0) 0 else 1)
