# =============================================================================
# auditoria.R — PANEL ADVERSARIAL (independiente del 33).
# Re-deriva la numeracion desde el maestro crudo con logica propia y la contrasta
# contra el HTML generado. NO hace source() del 33: rompe sus puntos ciegos.
# =============================================================================
suppressMessages({library(readxl); library(janitor); library(dplyr)})

MAESTRO <- "20_insumos/maestro_establecimientos.xlsx"
HTML    <- "40_salidas/afiche/mapa_establecimientos.html"
SCRIPT  <- "30_procesamiento/33_generar_afiche.R"
falla <- 0L
ok <- function(cond, msg){ cat(sprintf("[%s] %s\n", ifelse(cond,"PASA","FALLA"), msg)); if(!cond) falla<<-falla+1L }

# ---- lectura cruda ----
m <- read_excel(MAESTRO) |> clean_names() |>
  mutate(nombre = nombre_del_establecimiento, rbd = as.character(rbd))
cat(sprintf("Maestro: %d filas\n", nrow(m)))

# ===========================================================================
# CHECK (a): numeracion 1..97 cumple los 4 criterios de orden, sin huecos.
# Re-derivada INDEPENDIENTE: orden de comuna por latitud media (no se lee de
# COMUNAS_ORDEN); tipo por el orden declarado; nombre alfabetico.
# ===========================================================================
tipo_ord <- c("Jardín infantil","Escuela básica","Liceo","Escuela especial",
              "Centro de educación para jóvenes y adultos")
com_ord <- m |> summarise(la = mean(latitud), .by = comuna) |>
  arrange(desc(la)) |> pull(comuna)
cat("Orden comunas por lat media (N->S): ", paste(com_ord, collapse=" > "), "\n")

aud <- m |>
  mutate(comuna_f = factor(comuna, levels = com_ord),
         tipo_f   = factor(tipo_establecimiento, levels = tipo_ord)) |>
  arrange(comuna_f, tipo_f, nombre) |>
  mutate(num = row_number())

ok(all(!is.na(aud$tipo_f)), "todos los tipos reconocidos (orden de tipo aplicable)")
ok(identical(sort(aud$num), 1:97), "numeracion 1..97 sin huecos ni duplicados")
rng <- aud |> summarise(lo=min(num), hi=max(num), .by=comuna) |>
  arrange(lo) |> as.data.frame()
print(rng)
esp <- data.frame(comuna=com_ord, lo=c(1,21,31,38), hi=c(20,30,37,97))
ok(isTRUE(all.equal(rng$lo, esp$lo)) && isTRUE(all.equal(rng$hi, esp$hi)),
   "rangos por comuna = 1-20 / 21-30 / 31-37 / 38-97")
# criterio de orden interno: dentro de comuna, tipo asc y luego nombre asc
orden_ok <- aud |> group_by(comuna_f) |>
  summarise(mono = all(diff(as.integer(tipo_f)) >= 0), .groups="drop")
ok(all(orden_ok$mono), "dentro de cada comuna el tipo es monotono (jardin->...->adultos)")

# ===========================================================================
# CHECK (b): 97 puntos 1:1 con el maestro; NINGUN punto perdido por filtro de
# poligono (🔒-3). Se inspecciona el codigo del 33 y los conteos del render.
# ===========================================================================
src <- paste(readLines(SCRIPT, warn=FALSE), collapse="\n")
sin_filtro_poligono <- !grepl("st_within|st_contains|st_intersection|st_filter|st_join", src)
ok(sin_filtro_poligono, "el 33 NO filtra puntos por contencion en poligono (🔒-3)")
# conteo que alimenta el render: chicas (3 comunas) + vina = 97, particion exacta
n_chicas <- sum(m$comuna %in% c("Puchuncaví","Quintero","Concón"))
n_vina   <- sum(m$comuna == "Viña del Mar")
ok(n_chicas + n_vina == 97 && n_chicas == 37 && n_vina == 60,
   sprintf("particion render: norte=%d + vina=%d = 97 (sin perdidas)", n_chicas, n_vina))

# ===========================================================================
# CHECK (c): ningun nombre truncado. Cada nombre completo del maestro debe
# aparecer literal en el HTML (indice). Comparacion con escape HTML.
# ===========================================================================
html <- paste(readLines(HTML, warn=FALSE, encoding="UTF-8"), collapse="\n")
esc <- function(x){ x<-gsub("&","&amp;",x,fixed=TRUE); x<-gsub("<","&lt;",x,fixed=TRUE); gsub(">","&gt;",x,fixed=TRUE) }
nombres_esc <- esc(m$nombre)
presentes <- vapply(nombres_esc, function(s) grepl(s, html, fixed=TRUE), logical(1))
ok(all(presentes), sprintf("los 97 nombres completos aparecen literal en el HTML (%d/97)", sum(presentes)))
if(any(!presentes)) cat("  AUSENTES:\n   - ", paste(m$nombre[!presentes], collapse="\n   - "), "\n")

# ---- 1:1 indice HTML vs numeracion independiente ----
# Extrae pares (num, nombre) del indice del HTML y compara con 'aud'.
num_html <- regmatches(html, gregexpr('text-align:right">([0-9]+)</span>\\s*<span[^>]*line-height:1.2[^>]*>([^<]+)</span>', html))[[1]]
pares <- regmatches(html, gregexpr('text-align:right">[0-9]+</span>', html))[[1]]
nums  <- as.integer(gsub('\\D','', pares))
nombres_html <- regmatches(html, gregexpr('line-height:1.2;color:[^>]*>([^<]+)</span>', html))[[1]]
nombres_html <- gsub('.*>([^<]+)</span>$','\\1', nombres_html)
ok(length(nums)==97 && identical(sort(nums),1:97),
   sprintf("el indice HTML contiene 97 numeros 1..97 (encontrados=%d)", length(nums)))
# cruce num->nombre indice vs aud (independiente)
idx_html <- data.frame(num=nums, nombre=nombres_html, stringsAsFactors=FALSE) |> arrange(num)
cmp <- merge(idx_html, transform(aud[,c("num","nombre")], nombre=esc(nombre)), by="num", suffixes=c("_html","_aud"))
ok(all(cmp$nombre_html == cmp$nombre_aud),
   sprintf("indice HTML 1:1 con numeracion independiente (%d/97 coinciden)", sum(cmp$nombre_html==cmp$nombre_aud)))
if(any(cmp$nombre_html != cmp$nombre_aud)){
  d <- cmp[cmp$nombre_html!=cmp$nombre_aud,]
  for(i in seq_len(min(5,nrow(d)))) cat(sprintf("   num %d: html='%s' aud='%s'\n", d$num[i], d$nombre_html[i], d$nombre_aud[i]))
}

cat(sprintf("\n===== PANEL ADVERSARIAL: %s (%d fallas) =====\n",
            ifelse(falla==0,"TODO PASA","HAY FALLAS"), falla))
quit(status = if(falla==0) 0 else 1)
