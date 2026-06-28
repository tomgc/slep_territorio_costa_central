# Fase 2: recorta BCN a las 4 comunas, reproyecta a 4326, guarda liviano.
suppressMessages({library(sf); library(dplyr)})
norm <- function(x){ x<-tolower(trimws(as.character(x))); x<-iconv(x,to="ASCII//TRANSLIT"); gsub("[^a-z ]","",x) }
obj <- c("puchuncavi","quintero","concon","vina del mar")

TOL_SIMPLIFY_M <- 20   # tolerancia de simplificacion (m, en 3857) si el geojson pesa demasiado
TOPE_MB        <- 3.5  # umbral de peso para decidir simplificar

bcn <- st_read("20_insumos/comunas_bcn/comunas.shp", quiet=TRUE)
sel <- bcn[norm(bcn$Comuna) %in% obj, c("Comuna","cod_comuna","Provincia","Region")]
sel <- st_make_valid(sel)

solape <- function(s){ # s en metrico
  pares <- list(c("puchuncavi","quintero"),c("quintero","concon"),c("concon","vina del mar"))
  cn <- norm(s$Comuna)
  vapply(pares, function(p){ a<-s[cn==p[1],]; b<-s[cn==p[2],]
    ar<-tryCatch(as.numeric(st_area(st_intersection(st_union(a),st_union(b)))),error=function(e)NA)
    if(length(ar)==0) 0 else ar }, numeric(1))
}
cat("solape full-res (m2):", paste(round(solape(sel),2), collapse=", "), "\n")

escribir <- function(g, ruta){
  g <- st_transform(g, 4326)
  if(file.exists(ruta)) file.remove(ruta)
  st_write(g, ruta, quiet=TRUE, layer_options="COORDINATE_PRECISION=6")
  file.info(ruta)$size/1e6
}

dest <- "20_insumos/comunas.geojson"
mb <- escribir(sel, dest)
cat(sprintf("geojson full-res: %.2f MB\n", mb))

if(mb > TOPE_MB){
  cat(sprintf("Supera %.1f MB: simplifico con dTolerance=%dm y reverifico solape...\n", TOPE_MB, TOL_SIMPLIFY_M))
  sels <- st_simplify(sel, dTolerance=TOL_SIMPLIFY_M, preserveTopology=TRUE)
  sels <- st_make_valid(sels)
  cat("solape simplificado (m2):", paste(round(solape(sels),2), collapse=", "), "\n")
  mb <- escribir(sels, dest)
  cat(sprintf("geojson simplificado: %.2f MB\n", mb))
  g_final <- sels
} else {
  cat("Peso aceptable: sin simplificar.\n")
  g_final <- sel
}

# verificacion final post-escritura: releer y contar vertices
chk <- st_read(dest, quiet=TRUE)
vtx <- function(g) sum(vapply(st_geometry(g), function(x) nrow(st_coordinates(x)), integer(1)))
cat("=== geojson final ===\n")
cat("campo:", paste(names(chk), collapse=", "), "\n")
for(o in obj){ s<-chk[norm(chk$Comuna)==o,]; cat(sprintf("  %-14s vtx=%5d\n", o, vtx(s))) }
