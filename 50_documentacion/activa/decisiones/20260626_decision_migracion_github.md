# Diagnostico de migracion a GitHub — slep_georreferenciacion

- **Fecha:** 2026-06-26 16:31:42
- **Raiz auditada:** /Users/tomgc/Projects/slep_georreferenciacion
- **Repo remoto destino:** slep_territorio_costa_central (privado)
- **Rama:** A (datos publicos del directorio MINEDUC; se versionan).
- **Alcance:** datos personales hardcodeados, credenciales/tokens, rutas absolutas con informacion de usuario, referencias a OneDrive, correos, nombres de archivo fuera de norma, e inventario de archivos de datos a confirmar publicos.
- **Naturaleza Rama A:** el maestro de establecimientos (RBD, nombre, tipo, comuna, coordenadas) es publico (directorio MINEDUC) y se versiona; no se reporta como hallazgo. Los .csv/.rds derivados se listan como REVISAR para confirmacion manual, no como infraccion.

## Resumen

| Severidad | N |
|---|---|
| MEDIA | 8 |
| REVISAR | 4 |

**Total de hallazgos:** 12

## Hallazgos detallados

| Severidad | Tipo | Archivo | Linea | Norma | Extracto |
|---|---|---|---|---|---|
| MEDIA | Nombre con tilde/n/espacio | `design_handoff_mapa_establecimientos/Prototipo Mapa Establecimientos.dc.html` | — | Politica seccion 2 (naming) | `design_handoff_mapa_establecimientos/Prototipo Mapa Establecimientos.dc.html` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 11 | C.7 / gobernanza datos | `#   nombre de usuario, referencias a OneDrive, nombres de archivo fuera de` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 69 | C.7 / gobernanza datos | `# Ruta OneDrive institucional.` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 70 | C.7 / gobernanza datos | `RX_ONEDRIVE <- "OneDrive[A-Za-z0-9 ._-]*"` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 91 | C.7 / gobernanza datos | `if (str_detect(texto, RX_ONEDRIVE)) agrega("Referencia a OneDrive", "MEDIA", "C.7 / gobernanza datos")` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 177 | C.7 / gobernanza datos | `"absolutas con informacion de usuario, referencias a OneDrive, correos, ",` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 225 | C.7 / gobernanza datos | `wl("- **MEDIA (rutas absolutas / OneDrive / naming):** rutas con ",` |
| MEDIA | Referencia a OneDrive | `diagnostico_migracion_github.R` | 226 | C.7 / gobernanza datos | `"`/Users/<nombre>/` violan portabilidad (C.7); referencias a OneDrive no ",` |
| REVISAR | Archivo de datos a confirmar publico | `20_insumos/maestro_establecimientos.xlsx` | — | Politica 6.1 / Agencia de Calidad (Rama A) | `Confirmar que el contenido es publico (directorio MINEDUC). Tamano: maestro_establecimientos.xlsx` |
| REVISAR | Archivo de datos a confirmar publico | `40_salidas/establecimientos_proyectados.rds` | — | Politica 6.1 / Agencia de Calidad (Rama A) | `Confirmar que el contenido es publico (directorio MINEDUC). Tamano: establecimientos_proyectados.rds` |
| REVISAR | Archivo de datos a confirmar publico | `40_salidas/establecimientos_validados.rds` | — | Politica 6.1 / Agencia de Calidad (Rama A) | `Confirmar que el contenido es publico (directorio MINEDUC). Tamano: establecimientos_validados.rds` |
| REVISAR | Archivo de datos a confirmar publico | `scratchpad_afiche/b3.rds` | — | Politica 6.1 / Agencia de Calidad (Rama A) | `Confirmar que el contenido es publico (directorio MINEDUC). Tamano: b3.rds` |

## Interpretacion y recomendaciones

- **CRITICA (credenciales):** detener la migracion. Rotar el secreto y purgar del historial antes de cualquier push.
- **ALTA (RUT):** un RUT en codigo o datos es un incidente. Verificar si el dato es realmente publico; si no, removerlo y reescribir el historial.
- **MEDIA (rutas absolutas / OneDrive / naming):** rutas con `/Users/<nombre>/` violan portabilidad (C.7); referencias a OneDrive no deben viajar al repo; nombres con tilde/n/espacio se renombran (politica seccion 2).
- **BAJA (correos):** revisar caso a caso. Un correo institucional de contacto puede ser intencional; uno personal en codigo, no.
- **REVISAR (archivos de datos):** confirmar uno por uno que el contenido es publico (directorio MINEDUC). El maestro y sus .rds derivados de georreferenciacion lo son; cualquier .csv/.rds inesperado con asistencia, matricula o RUT NO debe versionarse.

> Compuerta de gobernanza (protocolo 4.3, Fase 1): este reporte se revisa con el titular ANTES del primer push. La auditoria no decide sola: reporta.
