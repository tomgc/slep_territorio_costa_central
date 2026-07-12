---
slug: slep_georreferenciacion
nombre_real: SLEP Georreferenciacion - Territorio Costa Central
categoria: activo
semaforo: activo
sesion_actual: v10
ultima_actividad: 2026-07-12
maneja_sensibles: true
tipo_pendiente: nuevo
---
## En que vamos
El mapa interactivo (variante 3) esta publicado y sin pendientes ejecutables; los afiches A0 (variantes 1 y 2) siguen esperando validacion del director. La sesion 10 diagnostico a fondo el Censo 2024 y cerro la decision de alcance de la capa censal: dos capas, dos indicadores, dos escalas (densidad de poblacion en edad escolar a nivel manzana en Costa Central; tasa de asistencia a nivel zona/localidad en la region continental). No se escribio codigo de producto: la sesion produjo dos reportes de medicion y un archivo de decision formal.

## Proximo paso
Etapa 2: construir la capa censal segun la decision de alcance, empezando por la prueba de humo de render en Leaflet (~6.000 poligonos, transferencia medida pero FPS no verificado).

## Bloqueantes
- El titular debe copiar cuatro insumos del Censo (tres parquet de cartografia + P7_Educacion.xlsx) desde la raiz de datos de `slep_estudio_oferta_demanda` a la de este proyecto. Sin eso la Etapa 2 no arranca. No es bloqueante del proyecto completo (hay trabajo ejecutable: commit del cierre acumulado v09+v10).
- Validacion del director sobre los afiches A0: bloqueante externo de esas dos variantes desde v05, no del proyecto.
