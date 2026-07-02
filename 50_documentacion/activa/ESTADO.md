---
slug: slep_georreferenciacion
nombre_real: Georreferenciación de establecimientos del territorio — afiche cartográfico A0 (SLEP Costa Central)
categoria: activo
semaforo: cerrado
sesion_actual: v05
ultima_actividad: 2026-06-28
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos
Se construyó, auditó y commiteó la variante de escala única continua del afiche A0 (97 establecimientos), corrigiendo la regresión donde la etiqueta de una comuna tapaba un pin mediante un offset calibrado por código y el switch REUSAR_PNG. El titular reposicionó a mano las 4 etiquetas de comuna al océano en Affinity y exportó el PDF plotter-ready (300 DPI, fuentes incrustadas); el producto original con inset permanece byte-idéntico. Ambas variantes quedan listas para la validación con el director.

## Proximo paso
Cerrar deudas técnicas menores ejecutables ahora: re-correr el escáner (desactualizado, no incluye el script nuevo ni el log del fix), verificar la constante posiblemente muerta y documentar en README el locale UTF-8 y el origen re-descargable de las comunas.

## Bloqueantes
ninguno
