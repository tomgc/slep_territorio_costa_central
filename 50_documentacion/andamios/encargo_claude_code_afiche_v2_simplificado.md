# Encargo autónomo — Afiche simplificado (pines numerados, sin etiquetas ni líneas)

> Proyecto: `slep_georreferenciacion`. Sesión 3 (ajuste).
> Redactor: Claude conversacional. Ejecutor: Claude Code (modo autónomo).
> **Meta aprobada por el usuario:** generar un afiche con mapa de calles
> (CARTO Positron real) + límites comunales + pines numerados 1-97 (SIN
> etiquetas de texto, SIN leader lines) + índice a la izquierda con número,
> nombre y RBD. El usuario colocará los nombres en el mapa manualmente.

---

## Cambio respecto al encargo v1

Esta es una **simplificación deliberada** del afiche anterior. Se ELIMINA toda
la colocación automática de etiquetas y leader lines (etiquetas al mar,
etiquetas en tierra, ggrepel, anti-colisión). El mapa principal queda con
**solo pines numerados**. El resto de la infraestructura del v1 (CARTO real,
numeración N→S, inset de Viña, índice) se conserva.

**Punto de partida:** el `33_generar_afiche.R` actual ya genera CARTO real +
numeración N→S + inset de Viña + índice. Tu trabajo es **quitar** las capas de
etiquetas/líneas del mapa principal y **agregar** el RBD al índice. NO es una
reescritura desde cero: es una poda + un ajuste.

---

## 2.1 Encabezado de contrato

**Modo:** autónomo, secuencial, todas las fases en este turno.

**Regla de detención (PARA solo si):**
1. Un invariante 🔒 te obligaría a violarlo.
2. Un dato real contradice un supuesto (conteo ≠ 97, columna ausente).
3. El `33` actual no tiene la estructura que este encargo asume (en ese caso
   reporta qué encontraste, no improvises una reescritura completa).

**Reglas canónicas heredadas:** R-only, `|>`, `dplyr >= 1.1` con `.by=`,
`here::here()`, sin rutas absolutas en código, snake_case sin tildes en nombres
de archivo, commits atómicos en español, locale UTF-8 obligatorio para correr el
pipeline (ya documentado en el log previo).

---

## 2.2 Contexto

**Rutas (raíz `slep_georreferenciacion`):**
- Insumos: `20_insumos/maestro_establecimientos.xlsx` (hoja "maestro transporte";
  columna **RBD** disponible, úsala para el índice), `20_insumos/comunas.geojson`.
- Script a editar: `30_procesamiento/33_generar_afiche.R`.
- Salida: `40_salidas/afiche/mapa_establecimientos.html`.
- Orquestador: `00_run_all.R` (correr `run_all(from=1, to=3)` regenera todo).

**Estado actual del 33 (de la sesión previa):** genera dos planos PNG (panel
norte con CARTO real + inset Viña) embebidos en base64, más un índice lateral.
La numeración N→S oficial (Puchuncaví 1-20, Quintero 21-30, Concón 31-37, Viña
38-97) ya existe y está verificada. NO la rehagas.

---

## 2.3 Invariantes (🔒)

- **🔒-1.** No tocar `31_leer_validar.R` ni `32_proyectar_lienzo.R`.
- **🔒-2.** Numeración N→S oficial intacta: Puchuncaví 1-20, Quintero 21-30,
  Concón 31-37, Viña 38-97 (comuna N→S, dentro por tipo
  jardín→básica→liceo→especial→adultos, dentro por nombre). Mapa, inset e índice
  comparten el MISMO número.
- **🔒-3.** Los 97 puntos se ubican por coordenadas; nunca se filtran por
  contención en el polígono comunal (el GeoJSON está generalizado; perderías
  RBD 1699 y 33476).
- **🔒-4.** Viña del Mar en inset con zoom (los 60 numerados ahí, no dispersos
  en el plano principal). Decisión del usuario.
- **🔒-5.** El índice incluye, por establecimiento: **número + nombre completo +
  RBD**. Ningún nombre truncado.
- **🔒-6.** El HTML es autocontenido (CSS/fuentes/imágenes embebidas, 0
  referencias de red), como el actual.

---

## 2.4 Fases

### Fase 0 — Lectura del estado real
- Lee `33_generar_afiche.R` completo. Identifica: dónde se dibujan los pines,
  dónde se dibujan las etiquetas al mar / en tierra / leader lines, y dónde se
  construye el índice.
- Confirma que el maestro tiene columna RBD y conteo 97. Si no, PARA.

### Fase 1 — PODA: quitar etiquetas y líneas del mapa principal
- Elimina del render del panel norte TODO lo que sea: etiquetas de texto al mar,
  etiquetas de texto en tierra, leader lines, ggrepel, lógica de anti-colisión,
  cálculo de "apretado"/NN<450m, columna oceánica de etiquetas. **Todo eso se va.**
- Lo que QUEDA en el mapa principal: tiles CARTO Positron, límites comunales
  dibujados (ver Fase 2), y los pines numerados coloreados por tipo.
- Si al quitar las etiquetas el bbox/aspect del panel quedaba dimensionado para
  dejar espacio oceánico a las etiquetas, **reajusta el bbox** para que el mapa
  llene el espacio sin océano vacío desperdiciado (ahora no hay etiquetas que
  poner ahí). Centra en las 4 comunas con margen razonable.

### Fase 2 — Límites comunales visibles (verificar explícitamente)
- Dibuja el contorno de las 4 comunas (Puchuncaví, Quintero, Concón, Viña) sobre
  el CARTO, con línea sutil pero visible (p. ej. gris medio, lw ~0.8, sin
  relleno o relleno muy tenue para no tapar las calles).
- **Criterio de éxito verificable:** en el render final se distinguen los 4
  contornos comunales. Confírmalo mirando el PNG, no por supuesto.

### Fase 3 — Pines numerados legibles
- Cada establecimiento: pin circular coloreado por tipo (jardín verde #6a8a3a,
  escuela azul #2d5f8a, liceo naranja #c8732e, especial morado #7a4a8a, adultos
  gris #555) con su número en blanco, centrado, legible.
- En el panel norte (37 pines de las 3 comunas chicas): donde dos pines queden
  literalmente encimados, aplica dispersión leve (declustering radial mínimo)
  conservando la posición real lo más posible. SIN líneas que conecten nada.
- En el inset de Viña (60 pines): igual, números legibles, declustering leve solo
  si se enciman.

### Fase 4 — Índice lateral izquierdo con RBD
- Índice a la IZQUIERDA del afiche (el usuario lo pidió a la izquierda).
- Por comuna en orden N→S, cada entrada: **`<número>  <nombre completo>  (RBD <rbd>)`**,
  coloreada por tipo. Viña (38-97) en 2 columnas para que quepa.
- Leyenda de colores por tipo. Sin truncar nombres (🔒-5).

### Fase 5 — Regenerar y verificar
- `run_all(from=1, to=3)`. Render headless del HTML a PNG.
- Verifica visualmente: calles CARTO presentes, 4 límites comunales visibles,
  pines numerados legibles, índice a la izquierda con número+nombre+RBD, Viña en
  inset. Commits atómicos.

---

## 2.5 Criterios de éxito globales
1. Se genera de cero con el orquestador.
2. Mapa con calles CARTO Positron (no placeholder, no OSM crudo).
3. Los 4 límites comunales se distinguen en el render.
4. 97 pines numerados, sin etiquetas de texto ni líneas en el mapa.
5. Índice a la izquierda con número + nombre + RBD, sin truncar.
6. Viña en inset. Numeración N→S consistente entre mapa, inset e índice.

## 2.6 Auto-auditoría antes de reportar
Panel adversarial independiente (re-derivado desde el maestro crudo, sin reusar
funciones del 33) que verifique: (a) numeración 1-97 sin huecos, rangos por
comuna correctos; (b) los 97 puntos presentes 1:1 (sin pérdida por filtro de
polígono); (c) el índice del HTML contiene número + nombre + RBD para los 97
(grep de cada RBD y cada nombre); (d) que NO queden etiquetas de texto ni
elementos de leader line en el SVG/PNG del mapa principal (confirmar que la poda
fue efectiva). Reporta el conteo de cada check.

## 2.7 Log de cierre
`50_documentacion/andamios/logs/YYYYMMDD_afiche_simplificado_log.md` según
plantilla fija: resumen, commits, qué se podó (con causa), verificación de los 6
🔒 con PASA/FALLA y evidencia, confirmación de que los límites comunales se ven,
pendientes, notas para el revisor. Honesto. Sin commitear (revisión previa).

## 2.8 Reporte final
Hashes de commits, resultado del panel adversarial (4 checks con evidencia),
confirmación visual de los 6 criterios, ruta del log.
