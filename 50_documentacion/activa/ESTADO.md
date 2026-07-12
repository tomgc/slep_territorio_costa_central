---
slug: slep_georreferenciacion
nombre_real: SLEP Georreferenciacion Costa Central
categoria: activo
semaforo: activo
sesion_actual: v11
ultima_actividad: 2026-07-12
maneja_sensibles: true
tipo_pendiente: bug
---
## En que vamos
La Etapa 2 del Censo 2024 avanzo en medicion y decision, sin codigo de producto verificado. Se cerro el riesgo de render (la capa de manzana es viable en Leaflet con renderer Canvas, medido en navegador real) y se descubrio que la proporcion de asistencia calculada desde el geoparquet NO es la tasa neta del INE: la subestima entre 0,53 y 1,35 puntos porcentuales de forma sistematica, porque el INE excluye la no-respuesta del denominador y ese dato no existe a escala sub-comunal. Se decidio publicar la proporcion cruda con rotulado honesto y declarar la discrepancia, en vez de corregirla (seria inventar precision). El encargo del primer script de produccion quedo corriendo al cierre.

## Proximo paso
Verificar contra el artefacto si `30_procesamiento/37_construir_capa_manzana.R` y `docs/data/censo_manzanas_cc.geojson` existen y son correctos: el traspaso v11 NO afirma su estado, lo declara desconocido.

## Bloqueantes
- Validacion del director de los afiches estaticos (abierto desde v05, externo).
- Validacion del mapa interactivo con el equipo experto (abierto desde v06, externo).
- Ninguno bloquea el trabajo ejecutable: los hitos 3 (capa zonal) y 4 (front-end) pueden avanzar.
