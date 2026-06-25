# Decision: tratamiento de marcadores por densidad

**Fecha:** 2026-06-25
**Estado:** vigente
**Contexto:** El handoff de muestra trae 17 establecimientos; el maestro real
tiene 97, con 60 concentrados en Viña del Mar. El esquema original (tarjeta con
nombre completo en zonas dispersas + pines en Viña) no escala: 60 tarjetas en
Viña producen un amasijo ilegible.

## Opciones evaluadas
Se renderizaron las tres a tamano real (1240x1754) con los datos reales:

- **A — pines en todo el mapa.** Los 97 como numero; nombres en la lista lateral
  a 2 columnas. Maxima fidelidad al "racimo de numeros" del README y escala sin
  solaparse. Costo: el mapa no rotula nombres fuera de la lista.
- **B — hibrido (tarjeta si aislado, pin si en cluster).** Heuristica de
  aislamiento. Costo: tarjetas residuales se solapan con rotulos de comuna; en
  Vina casi todo cae a pin igual.
- **C — tarjetas en las 3 comunas dispersas + pines en Vina.** Reproduce el
  gesto del handoff donde es viable (37 puntos fuera de Vina) y mantiene Vina
  como racimo de pines. Costo: requiere anti-colision de tarjetas en
  Quintero/Concon.

## Decision
**Opcion C, sin inset.** Vina del Mar = pines numerados; Puchuncavi, Quintero y
Concon = tarjeta con numero + nombre completo + (RBD). Eleccion del titular del
proyecto. Es el esquema original del handoff, viable ahora porque fuera de Vina
solo hay 37 puntos.

## Implicancia tecnica
El generador (`33_generar_afiche.R`) aplica anti-colision vertical de tarjetas
por comuna (`separar_tarjetas()`, `COLISION_DY`), sin truncar nombres (regla 1
del README). Si persisten solapes en los clusters dispersos, se evalua leader
lines cortas. La lista lateral conserva los nombres completos de los 97 (incluida
Vina, que en el mapa solo lleva numero).

## Alternativas descartadas y por que
A se descarto porque el titular prefiere nombres rotulados en el mapa fuera de
Vina; B por inestabilidad de la heuristica; el inset de C por agregar un elemento
no contemplado en el README y duplicar pines.
