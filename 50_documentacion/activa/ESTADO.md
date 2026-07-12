---
slug: slep_georreferenciacion
nombre_real: SLEP Georreferenciación (Costa Central)
categoria: activo
semaforo: activo
sesion_actual: v08
ultima_actividad: 2026-07-12
maneja_sensibles: false
tipo_pendiente: bug
---
## En que vamos
Los tres productos (dos afiches A0 y el mapa interactivo regional) están completos y auditados; el pipeline no se toca hace dos sesiones. La sesión 8 cerró el borde entre lo hecho y lo publicado: los 10 commits de la sesión 7 viajaron al remoto (incluida la regla de gobernanza que sella los intermedios derivados de MRUN) y el backlog acumulativo quedó al día con la serie correlativa íntegra del 20 al 24. El proyecto no tiene, por primera vez desde la sesión 4, deuda de gobernanza ni documental pendiente de ejecución.

## Proximo paso
Incorporar el resultado del re-chequeo visual del mapa interactivo (pendiente desde v07, aún sin resultado): si arroja correcciones encabezan todo con ciclo diagnóstico→cambio→re-auditoría sobre `docs/data/`; si sale limpio, el Censo 2024 toma la sesión completa con contexto fresco.

## Bloqueantes
- Validación del director sobre los afiches 1 y 2 (externo, abierto desde v05).
- Validación con el equipo experto sobre el mapa interactivo (externo, abierto desde v06).
