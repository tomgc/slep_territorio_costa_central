---
slug: slep_georreferenciacion
nombre_real: SLEP Costa Central — georreferenciacion y territorio
categoria: activo
semaforo: activo
sesion_actual: v13
ultima_actividad: 2026-07-30
maneja_sensibles: true
tipo_pendiente: bloqueante
---
## En que vamos
La sesion 13 cerro la deuda en vuelo del hachurado y levanto el eje de educacion parvularia
de cero a capa publicada: script 39, GeoJSON de 1.329 unidades y toggle propio apagado por
defecto en el mapa regional. Se refuto el pendiente G: el backlog de disco y el del repo son
el mismo archivo byte a byte, ambos hasta la entrada 24, y la divergencia venia afirmandose
sin verificar desde la sesion 9. Quedan abiertos el orquestador y la memoria del backlog.

## Proximo paso
Resolver el pendiente D: agrupar los pasos de `run_all()` para que una maquina limpia corra
el afiche sin los parquet del Censo, y registrar ahi el script 39 de parvularia.

## Bloqueantes
- Pendiente D: `run_all()` sin argumentos corre los pasos del Censo, que dependen de 309 MB
  de parquet gitignored; en clon limpio falla aunque el afiche este perfecto. Arrastra el
  registro del script 39, hoy ausente del orquestador.
