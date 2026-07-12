/* =============================================================================
   mapa.js — Mapa interactivo de establecimientos, Región de Valparaíso.
   Hito 2b: paleta azul de rango amplio (marino→celeste), frontera del SLEP
   Costa Central, encuadre protagónico, pins sobre rótulos, hover orgánico,
   tarjeta rediseñada. Estado 100% en memoria (sin browser storage).
   ============================================================================= */
'use strict';

/* ---- Paleta 2b (contrastes WCAG y DeltaE2000 verificados; ver reporte) ---- */
const PAL_SLEP = {
  'Costa Central': '#0D2E52',   // azul marino profundo: protagonista, radio +1
  'Valparaíso':    '#155B8F',   // azul
  'Aconcagua':     '#0E7CB0',   // azul claro
  'Los Andes':     '#0995B5',   // cian
  'Marga Marga':   '#1A9384',   // turquesa
  'Petorca':       '#1F8FD0'    // celeste
};
const PAL_DEP = {
  'Municipal':                        '#496524',
  'Particular Subvencionado':         '#A6741C',
  'Particular Pagado':                '#7A4A8A',
  'Corp. de Administración Delegada': '#B08122'  // ocre similar al subvencionado, a propósito
};
// etiquetas de despliegue (sin abreviaturas; la clave de arriba es el valor del dato)
const ETIQUETA_DEP = {
  'Corp. de Administración Delegada': 'Corporación de Administración Delegada'
};
const COLOR_ATENUADO = '#c9c4bb';
const COLOR_CIRUELA  = '#4A2746';
const HOVER_EXTRA = 4.5;          // crecimiento del pin al hover (mas notorio)
const HOVER_MS    = 180;          // duracion del tween (suave, no salto)
const TOLERANCIA_HOVER = 8;       // px extra de area sensible ("close-enough")
// Radio por zoom (densidad evaluada empiricamente). Costa Central +1 (doble codificacion).
function radioBase(z) { return z <= 9 ? 3.5 : z <= 11 ? 4.5 : 5.5; }
const ETIQUETA_SLEP = 'Servicio Local de Educación';

/* ---- Estado en memoria ---- */
const S = { ee: [], sinGeo: [], meta: null, capa: null, marcadores: new Map(),
            total: 0, zoomActual: 9 };

/* ---- Utilidades ---- */
const esNum = v => typeof v === 'number';
function colorDe(p) { return p.slep ? PAL_SLEP[p.slep] : PAL_DEP[p.dep] || '#888'; }
function radioDe(p) { return radioBase(S.zoomActual) + (p.slep === 'Costa Central' ? 1 : 0); }
function fmt(n) { return esNum(n) ? n.toLocaleString('es-CL') : n; }
function depTexto(p) {
  return p.slep ? `${ETIQUETA_SLEP} ${p.slep}` : (ETIQUETA_DEP[p.dep] || p.dep);
}
// Sentence/nombre propio: los nombres vienen EN MAYUSCULAS del dato; allcaps prohibido.
const MINUSCULAS = new Set(['de', 'del', 'la', 'las', 'los', 'el', 'y', 'e', 'o', 'u', 'a']);
const SIGLAS = new Set(['slep', 'rbd', 'ceia', 'j.', 'ii', 'iii', 'iv']);
function titulo(s) {
  if (!s) return s;
  return s.toLowerCase().split(/\s+/).map((w, i) => {
    if (SIGLAS.has(w)) return w.toUpperCase();
    if (i > 0 && MINUSCULAS.has(w)) return w;
    return w.charAt(0).toUpperCase() + w.slice(1);
  }).join(' ');
}
/* ---- Sintesis de ensenanza (tooltip y tarjeta) ----
   Comprime niveles numericos consecutivos en rangos ("de 1° a 8°"); con saltos
   los lista sin inventar rangos ("1°, 2° y 5°"). Niveles no numericos
   (parvularia, especial, adultos) van con nombre completo en la tarjeta; en el
   tooltip solo el macrogrupo (el detalle vive en el click). Umbral del tooltip:
   2 modalidades (un tooltip es identificacion al vuelo; con 3+ se vuelve parrafo
   y el detalle completo esta a un clic). */
const UMBRAL_MODALIDADES_TOOLTIP = 2;
function unirY(xs) {
  if (xs.length <= 1) return xs.join('');
  return xs.slice(0, -1).join(', ') + ' y ' + xs[xs.length - 1];
}
function nivelesNumericos(niv) {
  const m = niv.map(v => v.match(/^(\d+)° (básico|medio)$/));
  if (!m.every(Boolean)) return null;
  const nums = [...new Set(m.map(x => +x[1]))].sort((a, b) => a - b);
  const rangos = []; let ini = nums[0], fin = nums[0];
  for (let i = 1; i < nums.length; i++) {
    if (nums[i] === fin + 1) fin = nums[i];
    else { rangos.push([ini, fin]); ini = fin = nums[i]; }
  }
  rangos.push([ini, fin]);
  if (rangos.length === 1 && rangos[0][0] !== rangos[0][1])
    return `de ${rangos[0][0]}° a ${rangos[0][1]}°`;
  return unirY(rangos.map(([a, b]) => a === b ? `${a}°` : `${a}° a ${b}°`));
}
function fraseModalidad(e, completa) {
  const rango = nivelesNumericos(e.niv);
  if (rango) return `${e.m} ${rango}`;
  return completa ? `${e.m}: ${unirY(e.niv)}` : e.m;
}
// Texto para EE sin ningun registro (60 casos): figura funcionando en el
// directorio pero sin matricula ni tipos de ensenanza en ninguna fuente oficial.
const TEXTO_SIN_OFERTA_CORTO = 'Sin registros de matrícula ni enseñanza (2016–2025)';
const TEXTO_SIN_OFERTA_LARGO = 'Figura como funcionando en el directorio oficial, pero sin matrícula ni tipos de enseñanza registrados en 2016–2025.';
function anioActual() { return S.meta.ventana_anios[S.meta.ventana_anios.length - 1]; }
function esOfertaHistorica(p) { return p.ens.length > 0 && esNum(p.ensa) && p.ensa < anioActual(); }

function resumenEnsTooltip(p) {
  if (!p.ens.length) return TEXTO_SIN_OFERTA_CORTO;
  const frases = p.ens.slice(0, UMBRAL_MODALIDADES_TOOLTIP).map(e => fraseModalidad(e, false));
  const resto = p.ens.length - UMBRAL_MODALIDADES_TOOLTIP;
  if (resto > 0) frases.push(`${resto} ${resto === 1 ? 'modalidad más' : 'modalidades más'}`);
  const base = unirY(frases);
  return esOfertaHistorica(p) ? `Impartía hasta ${p.ensa}: ${base}` : base;
}
function detalleEnsPopup(p) {
  if (!p.ens.length)
    return `<div class="pp-ens"><div class="pp-ens-item pp-ens-ausencia">${TEXTO_SIN_OFERTA_LARGO}</div></div>`;
  const encabezado = esOfertaHistorica(p) ?
    `<div class="pp-ens-hist">Impartía hasta ${p.ensa}:</div>` : '';
  return `<div class="pp-ens">${encabezado}${p.ens.map(e =>
    `<div class="pp-ens-item">${fraseModalidad(e, true)}</div>`).join('')}</div>`;
}

function ultimoAnioConDato(s, anios) {
  for (let i = s.length - 1; i >= 0; i--) if (esNum(s[i])) return anios[i];
  return null;
}
function anioDe(s, anios, valor) {           // primer anio en que la serie toca el valor
  for (let i = 0; i < s.length; i++) if (s[i] === valor) return anios[i];
  return null;
}

/* ---- Tween de radio (canvas no tiene transiciones CSS; animacion propia) ---- */
function animarRadio(m, hasta) {
  if (m._tween) clearInterval(m._tween);
  const desde = m._radius, t0 = performance.now();
  m._tween = setInterval(() => {
    const t = Math.min(1, (performance.now() - t0) / HOVER_MS);
    const k = 1 - Math.pow(1 - t, 3);                     // ease-out
    m.setRadius(desde + (hasta - desde) * k);
    if (t >= 1) { clearInterval(m._tween); m._tween = null; }
  }, 16);
}

/* ---- Sparkline SVG: huecos = linea interrumpida (nunca cero); valor de
   matricula etiquetado sobre CADA punto (alturas alternadas para no chocar);
   maximo y minimo destacados con punto mayor y etiqueta en negrita ---- */
function sparkline(serie, anios) {
  const W = 520, H = 116, PAD = 18, PB = 20, PT = 18;
  const vals = serie.filter(esNum);
  if (!vals.length) return '';
  // eje Y desde 0: la matricula es magnitud absoluta; partir del minimo exagera caidas
  const maxV = Math.max(...vals), minV = Math.min(...vals);
  const x = i => PAD + i * (W - 2 * PAD) / (serie.length - 1);
  const y = v => (H - PB) - (v / maxV) * (H - PB - PT);
  const seg = []; let cur = [];
  serie.forEach((v, i) => {
    if (!esNum(v)) { if (cur.length) seg.push(cur); cur = []; }
    else cur.push([x(i), y(v)]);
  });
  if (cur.length) seg.push(cur);
  let g = '';
  for (const sg of seg) {
    if (sg.length > 1) {
      const pts = sg.map(p => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(' ');
      g += `<polyline points="${pts}" fill="none" stroke="${COLOR_CIRUELA}" stroke-width="1.8"/>`;
    }
  }
  // puntos + valor etiquetado en cada uno (alternando arriba/abajo); max y min destacados
  let alterna = 0, maxMarcado = false, minMarcado = false;
  serie.forEach((v, i) => {
    if (!esNum(v)) {
      g += `<line x1="${x(i).toFixed(1)}" y1="${H - PB + 2}" x2="${x(i).toFixed(1)}" y2="${H - PB + 7}" stroke="${COLOR_ATENUADO}" stroke-width="1.6"/>`;
      return;
    }
    const esMax = v === maxV && !maxMarcado, esMin = v === minV && !minMarcado && maxV !== minV;
    if (esMax) maxMarcado = true;
    if (esMin) minMarcado = true;
    const px = x(i), py = y(v);
    g += `<circle cx="${px.toFixed(1)}" cy="${py.toFixed(1)}" r="${(esMax || esMin) ? 3.1 : 2.1}" fill="${COLOR_CIRUELA}"/>`;
    const arriba = alterna % 2 === 0; alterna++;
    const ty = arriba ? py - 7 : py + 14;
    const peso = (esMax || esMin) ? ' font-weight="bold"' : '';
    g += `<text x="${px.toFixed(1)}" y="${Math.max(8, Math.min(H - PB - 2, ty)).toFixed(1)}" font-size="10.2"${peso} fill="${(esMax || esMin) ? COLOR_CIRUELA : '#6b655c'}" text-anchor="middle">${fmt(v)}</text>`;
  });
  // eje X: TODOS los anios etiquetados
  anios.forEach((a, i) => {
    g += `<text x="${x(i).toFixed(1)}" y="${H - 4}" font-size="9.2" fill="#8a857b" text-anchor="middle">${a}</text>`;
  });
  return `<svg class="pp-spark-svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="Serie de matrícula">${g}</svg>`;
}

/* ---- Tarjeta de detalle (click) ---- */
function htmlPopup(p) {
  const anios = S.meta.ventana_anios;
  const sinSerie = !esNum(p.mx);
  const enCierre = !esNum(p.ma) && esNum(p.mx);
  let estado = '';
  if (enCierre) {
    const ult = ultimoAnioConDato(p.s, anios);
    estado = `<div class="pp-estado cierre"><strong>${p.ma}</strong> Registró matrícula hasta ${ult}: los indicadores de la ventana son reales.</div>`;
  } else if (sinSerie) {
    estado = `<div class="pp-estado sindato"><strong>${p.ma}</strong> Sin registros de matrícula en la ventana 2016–2025.</div>`;
  }
  const anioMax = esNum(p.mx) ? anioDe(p.s, anios, p.mx) : null;
  const anioMin = esNum(p.mn) ? anioDe(p.s, anios, p.mn) : null;
  const ind = (etq, v, anio) => `<div class="pp-ind"><div class="pp-ind-etq">${etq}</div>
    <div class="pp-ind-val${esNum(v) ? '' : ' sin-dato'}">${fmt(v)}${anio ? ` <span class="pp-ind-anio">(${anio})</span>` : ''}</div></div>`;
  // orden: actual, promedio, maximo (anio), minimo (anio)
  const indicadores = `<div class="pp-indicadores">
    ${ind('Matrícula actual (2025)', p.ma, null)}
    ${ind('Promedio últimos 10 años', p.pr, null)}
    ${ind('Máximo últimos 10 años', p.mx, anioMax)}
    ${ind('Mínimo últimos 10 años', p.mn, anioMin)}</div>`;
  const nDatos = p.s.filter(esNum).length;
  const tituloSpark = esNum(p.mx) ?
    `Serie ${anios[0]}–${anios[anios.length - 1]} · Máximo ${fmt(p.mx)} (${anioMax}) · Mínimo ${fmt(p.mn)} (${anioMin})` :
    `Serie ${anios[0]}–${anios[anios.length - 1]}`;
  const spark = sinSerie ? '' :
    `<div class="pp-spark"><div class="pp-spark-titulo">${tituloSpark}</div>${sparkline(p.s, anios)}</div>`;
  const notaProm = (esNum(p.pr) && nDatos < anios.length) ?
    `<div class="pp-nota">El promedio, el máximo y el mínimo se calculan sobre los ${nDatos} años con dato de la serie; los años sin registro no se computan.</div>` :
    (esNum(p.pr) ? `<div class="pp-nota">Promedio calculado sobre los ${nDatos} años con dato de la serie.</div>` : '');
  const notaCorta = nDatos === 1 ?
    `<div class="pp-nota">${S.meta.criterios_calculo.nota_serie_corta}</div>` : '';
  return `<div class="pp">
    <div class="pp-nombre">${titulo(p.n)} <span class="pp-rbd">(RBD ${p.rbd})</span></div>
    <div class="pp-sub">${titulo(p.com)} · ${depTexto(p)}</div>
    ${detalleEnsPopup(p)}${estado}${indicadores}${spark}${notaProm}${notaCorta}</div>`;
}

/* ---- Leyenda ---- */
function construirLeyenda() {
  const el = document.getElementById('leyenda');
  const item = (color, etq) =>
    `<div class="leyenda-item"><span class="leyenda-punto" style="background:${color}"></span>${etq}</div>`;
  let h = '<div class="leyenda-grupo">Servicios Locales de Educación</div>';
  for (const [n, c] of Object.entries(PAL_SLEP)) h += item(c, `SLEP ${n}`);
  h += '<div class="leyenda-grupo">Otras dependencias</div>';
  for (const [n, c] of Object.entries(PAL_DEP)) h += item(c, ETIQUETA_DEP[n] || n);
  el.innerHTML = h;
  const pend = (S.meta.filtro_slep || []).filter(s => s.estado === 'pendiente');
  if (pend.length)
    document.getElementById('nota-slep-pendientes').textContent =
      'SLEP con traspaso pendiente: ' +
      pend.map(s => `${s.slep} (${s.anio_traspaso})`).join(' · ') + '.';
}

/* ---- Pins ---- */
function crearCapa(mapa, renderer) {
  const grupo = L.featureGroup();
  for (const f of S.ee) {
    const p = f.properties;
    const m = L.circleMarker([f.geometry.coordinates[1], f.geometry.coordinates[0]], {
      renderer, radius: radioDe(p), color: '#ffffff', weight: 1.5,
      fillColor: colorDe(p), fillOpacity: 0.92
    });
    const ensTt = resumenEnsTooltip(p);
    m.bindTooltip(
      `<div class="tt-nombre">${titulo(p.n)} (RBD ${p.rbd})</div>
       <div class="tt-sub">${titulo(p.com)} · ${depTexto(p)}</div>` +
      (ensTt ? `<div class="tt-ens">${ensTt}</div>` : ''),
      { className: 'tt-ee', direction: 'top', offset: [0, -8], sticky: true });
    m.on('mouseover', () => { m.setStyle({ weight: 2 }); animarRadio(m, radioDe(p) + HOVER_EXTRA); });
    m.on('mouseout',  () => { m.setStyle({ weight: 1.5 }); animarRadio(m, radioDe(p)); });
    m.bindPopup(() => htmlPopup(p), { maxWidth: 580, autoPanPadding: [34, 34] });
    m._props = p;
    S.marcadores.set(p.rbd, m);
    grupo.addLayer(m);
  }
  grupo.addTo(mapa);
  S.capa = grupo;
  return grupo;
}

/* =============================================================================
   FILTROS (hito 3) — 7 filtros acumulativos con opciones dependientes.
   - Estado 100% en memoria (F). match(p) = AND de los filtros activos.
   - Opciones estilo FACETA: las de cada filtro se calculan sobre el subconjunto
     que cumple TODOS LOS DEMAS filtros (permite cambiar la seleccion propia sin
     quedar atrapado). Opciones sin EE disponibles quedan deshabilitadas.
   - Tipo de ensenanza filtra por p.ens (pares observados), NO por p.mg:
     asi los 25 con oferta HISTORICA aparecen al filtrar su macrogrupo (quien
     filtra "Educacion Parvularia" debe saber que ahi HUBO un jardin que cerro;
     el tooltip/tarjeta ya los marca "Impartia hasta 20XX"), y los 60 sin
     registro no aparecen en ningun filtro de ensenanza (no hay dato).
   - Nivel: solo visible con Tipo elegido; cambiar el Tipo lo RESETEA (sin
     filtros huerfanos). Orden de aplicacion indiferente: match es funcion pura
     del estado.
   ============================================================================= */
const ORDEN_TIPOS = ['Educación Parvularia', 'Enseñanza Básica', 'Enseñanza Media HC',
                     'Enseñanza Media TP', 'Educación de Adultos', 'Educación Especial'];
const F = { prov: null, com: null, dep: null, slep: null, rbd: null, tipo: null, nivel: null };

const PRED = {
  prov:  (p, v) => p.prov === v,
  com:   (p, v) => p.com === v,
  dep:   (p, v) => p.dep === v,
  slep:  (p, v) => p.slep === v,
  rbd:   (p, v) => p.rbd === v,
  tipo:  (p, v) => p.ens.some(e => e.m === v),
  nivel: (p, v) => F.tipo !== null && p.ens.some(e => e.m === F.tipo && e.niv.includes(v))
};
function cumple(p, excepto) {
  for (const k of Object.keys(PRED)) {
    if (k === excepto || F[k] === null) continue;
    if (!PRED[k](p, F[k])) return false;
  }
  return true;
}
function hayFiltrosActivos() { return Object.values(F).some(v => v !== null); }

/* -- reconstruccion de opciones dependientes -- */
function opcionesSelect(sel, valores, etiquetaDe, todasTxt, disponibles) {
  const actual = F[sel.dataset.clave];
  sel.innerHTML = '';
  const op0 = document.createElement('option');
  op0.value = ''; op0.textContent = todasTxt; sel.appendChild(op0);
  for (const v of valores) {
    const op = document.createElement('option');
    op.value = v; op.textContent = etiquetaDe(v);
    op.disabled = !disponibles.has(v) && v !== actual;
    if (v === actual) op.selected = true;
    sel.appendChild(op);
  }
}
function reconstruirOpciones() {
  const g = id => document.getElementById(id);
  const dispo = clave => {
    const s = new Set();
    for (const f of S.ee) { const p = f.properties; if (cumple(p, clave)) {
      if (clave === 'tipo') p.ens.forEach(e => s.add(e.m));
      else if (clave === 'nivel') p.ens.forEach(e => { if (e.m === F.tipo) e.niv.forEach(n => s.add(n)); });
      else { const v = p[clave === 'com' ? 'com' : clave]; if (v != null) s.add(v); }
    } }
    return s;
  };
  const provs = [...new Set(S.ee.map(f => f.properties.prov))].sort((a, b) => a.localeCompare(b, 'es'));
  opcionesSelect(g('f-prov'), provs, v => v, 'Todas', dispo('prov'));
  const coms = [...new Set(S.ee.map(f => f.properties.com))].sort((a, b) => a.localeCompare(b, 'es'));
  opcionesSelect(g('f-com'), coms, v => titulo(v), 'Todas', dispo('com'));
  const deps = ['Servicio Local de Educación', 'Municipal', 'Particular Subvencionado',
                'Particular Pagado', 'Corp. de Administración Delegada'];
  opcionesSelect(g('f-dep'), deps, v => ETIQUETA_DEP[v] || v, 'Todas', dispo('dep'));
  const sleps = (S.meta.filtro_slep || []).filter(x => x.estado === 'vigente').map(x => x.slep);
  opcionesSelect(g('f-slep'), sleps, v => v, 'Todos', dispo('slep'));
  opcionesSelect(g('f-tipo'), ORDEN_TIPOS, v => v, 'Todos', dispo('tipo'));
  // Nivel: solo con Tipo elegido
  const wrap = g('f-nivel-wrap');
  wrap.hidden = F.tipo === null;
  if (F.tipo !== null) {
    const nivs = [...dispoNivelesDelTipo()].sort((a, b) => a.localeCompare(b, 'es', { numeric: true }));
    opcionesSelect(g('f-nivel'), nivs, v => v, 'Todos', dispo('nivel'));
  }
}
function dispoNivelesDelTipo() {
  // universo de niveles del tipo elegido (sobre el subconjunto que cumple lo demas)
  const s = new Set();
  for (const f of S.ee) { const p = f.properties;
    if (cumple(p, 'nivel')) p.ens.forEach(e => { if (e.m === F.tipo) e.niv.forEach(n => s.add(n)); });
  }
  return s;
}

/* -- combobox de establecimiento -- */
function iniciarCombobox() {
  const inp = document.getElementById('f-ee');
  const lista = document.getElementById('f-ee-lista');
  const selBox = document.getElementById('f-ee-sel');
  const MAX_VISIBLES = 30;
  const candidatos = q => {
    q = q.trim().toLowerCase();
    if (!q) return [];
    const out = [];
    for (const f of S.ee) { const p = f.properties;
      if (!cumple(p, 'rbd')) continue;                       // respeta los demas filtros
      if (p.n.toLowerCase().includes(q) || p.rbd.startsWith(q)) out.push(p);
    }
    return out;
  };
  const render = () => {
    const c = candidatos(inp.value);
    if (!inp.value.trim()) { lista.hidden = true; return; }
    lista.hidden = false;
    if (!c.length) { lista.innerHTML = '<div class="combobox-vacio">Sin coincidencias con los filtros vigentes.</div>'; return; }
    lista.innerHTML = c.slice(0, MAX_VISIBLES).map(p =>
      `<div class="combobox-item" data-rbd="${p.rbd}">${titulo(p.n)} <span class="cb-rbd">RBD ${p.rbd} · ${titulo(p.com)}</span></div>`).join('') +
      (c.length > MAX_VISIBLES ? `<div class="combobox-mas">${c.length - MAX_VISIBLES} coincidencias más: sigue escribiendo para acotar.</div>` : '');
  };
  inp.addEventListener('input', render);
  inp.addEventListener('focus', render);
  document.addEventListener('click', ev => { if (!ev.target.closest('.combobox')) lista.hidden = true; });
  lista.addEventListener('click', ev => {
    const item = ev.target.closest('.combobox-item');
    if (!item) return;
    F.rbd = item.dataset.rbd;
    const p = S.marcadores.get(F.rbd)._props;
    selBox.hidden = false;
    selBox.innerHTML = `<span>${titulo(p.n)} (RBD ${p.rbd})</span><button type="button" aria-label="Quitar establecimiento">×</button>`;
    selBox.querySelector('button').addEventListener('click', () => {
      F.rbd = null; selBox.hidden = true; inp.value = ''; aplicarFiltros();
    });
    inp.value = ''; lista.hidden = true;
    aplicarFiltros();
  });
}

/* -- aplicacion: estilos, contador, cero-resultados, opciones -- */
function aplicarFiltros() {
  const activos = hayFiltrosActivos();
  let n = 0;
  const coincidentes = [];
  S.marcadores.forEach(m => {
    const p = m._props;
    const ok = !activos || cumple(p, null);
    if (ok) { n++; coincidentes.push(m); }
    m.setStyle(ok ?
      { fillColor: colorDe(p), fillOpacity: 0.92, color: '#ffffff', weight: 1.5 } :
      { fillColor: COLOR_ATENUADO, fillOpacity: 0.5, color: '#ffffff', weight: 1 });
  });
  coincidentes.forEach(m => m.bringToFront());   // coincidentes plenos ENCIMA
  document.getElementById('contador').textContent =
    `${n.toLocaleString('es-CL')} de ${S.total.toLocaleString('es-CL')}`;
  // cero resultados: mensaje explicito + deshacer (nunca mapa vacio y mudo)
  let cero = document.getElementById('cero-resultados');
  if (activos && n === 0) {
    if (!cero) {
      cero = document.createElement('div');
      cero.id = 'cero-resultados'; cero.className = 'cero-resultados';
      cero.innerHTML = '<p>Ningún establecimiento cumple esta combinación de filtros.</p>' +
        '<button type="button" class="boton-limpiar">Limpiar filtros</button>';
      cero.querySelector('button').addEventListener('click', limpiarFiltros);
      document.getElementById('mapa').appendChild(cero);
    }
  } else if (cero) cero.remove();
  reconstruirOpciones();
}
function limpiarFiltros() {
  for (const k of Object.keys(F)) F[k] = null;
  const selBox = document.getElementById('f-ee-sel');
  selBox.hidden = true; selBox.innerHTML = '';
  document.getElementById('f-ee').value = '';
  document.getElementById('f-nivel-wrap').hidden = true;
  aplicarFiltros();
}
function iniciarFiltros() {
  const enlazar = (id, clave) => {
    const sel = document.getElementById(id);
    sel.dataset.clave = clave;
    sel.addEventListener('change', () => {
      F[clave] = sel.value === '' ? null : sel.value;
      if (clave === 'tipo') F.nivel = null;      // cambiar Tipo RESETEA Nivel (sin huerfanos)
      aplicarFiltros();
    });
  };
  enlazar('f-prov', 'prov'); enlazar('f-com', 'com'); enlazar('f-dep', 'dep');
  enlazar('f-slep', 'slep'); enlazar('f-tipo', 'tipo'); enlazar('f-nivel', 'nivel');
  document.getElementById('f-limpiar').addEventListener('click', limpiarFiltros);
  iniciarCombobox();
  reconstruirOpciones();
}

/* ---- Arranque ---- */
async function iniciar() {
  const [geo, meta, frontera, fronteraRegion, rotulosComuna] = await Promise.all([
    fetch('data/establecimientos.geojson').then(r => r.json()),
    fetch('data/metadatos.json').then(r => r.json()),
    fetch('data/frontera_costa_central.geojson').then(r => r.json()),
    fetch('data/frontera_region.geojson').then(r => r.json()),
    fetch('data/comunas_rotulos.json').then(r => r.json())
  ]);
  // Normalizacion defensiva de la frontera R->JS: jsonlite (auto_unbox) convierte
  // arrays de UN elemento en escalares (niv: "1° básico" en vez de ["1° básico"];
  // idem ens y mg). El JS trabaja siempre con arrays. (Hallazgo hermano del bug
  // de huecos {}: auditar desde el consumidor.)
  const comoArray = v => v == null ? [] : (Array.isArray(v) ? v : [v]);
  const normalizar = p => {
    p.mg = comoArray(p.mg);
    p.ens = comoArray(p.ens);
    p.ens.forEach(e => { e.niv = comoArray(e.niv); });
  };
  geo.features.forEach(f => normalizar(f.properties));
  fetch('data/sin_geo.json').then(r => r.json()).then(sg => {
    sg.forEach(normalizar); S.sinGeo = sg;
  });
  S.ee = geo.features; S.meta = meta; S.total = geo.features.length;

  const montar = () => {
    try {
    const cont = document.getElementById('mapa');
    if (cont.clientWidth === 0 || cont.clientHeight === 0) { setTimeout(montar, 120); return; }
    const mapa = L.map('mapa', { preferCanvas: true, zoomControl: true });
    // pane de rotulos BAJO los pins (overlayPane=400): los pins nunca quedan tapados
    mapa.createPane('rotulos');
    mapa.getPane('rotulos').style.zIndex = 340;
    // frontera bajo los pins, sobre los rotulos
    mapa.createPane('frontera');
    mapa.getPane('frontera').style.zIndex = 370;
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · © <a href="https://carto.com/">CARTO</a>',
      subdomains: 'abcd', maxZoom: 19
    }).addTo(mapa);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd', maxZoom: 19, pane: 'rotulos', opacity: 0.9
    }).addTo(mapa);

    // frontera regional (contexto): solo linea, apenas insinuada, bajo la de CC
    L.geoJSON(fronteraRegion, {
      pane: 'frontera',
      style: { color: '#9aa4ad', weight: 1, opacity: 0.5, fill: false },
      interactive: false
    }).addTo(mapa);
    // frontera del territorio SLEP Costa Central (union sin divisorias internas)
    const capaFrontera = L.geoJSON(frontera, {
      pane: 'frontera',
      style: { color: PAL_SLEP['Costa Central'], weight: 1.6, opacity: 0.7,
               fillColor: PAL_SLEP['Costa Central'], fillOpacity: 0.02 },
      interactive: false
    }).addTo(mapa);

    const renderer = L.canvas({ tolerance: TOLERANCIA_HOVER });  // area sensible ampliada
    S.zoomActual = 10;
    crearCapa(mapa, renderer);
    // encuadre: Costa Central protagonista con contexto regional inmediato
    mapa.fitBounds(capaFrontera.getBounds().pad(0.15));

    // Rotulos de COMUNA propios (los del basemap quedaron bajo los pins; estos
    // son ~36 y van ARRIBA de los pins con halo blanco: el texto se lee y deja
    // ver lo de abajo). Tamano adaptativo por zoom; bajo z9 se ocultan (36
    // etiquetas apretadas a escala regional completa son ruido). OJO: los
    // L.marker (icono DOM) deben agregarse DESPUES de que el mapa tenga vista.
    mapa.createPane('rotulosComuna');
    mapa.getPane('rotulosComuna').style.zIndex = 420;
    mapa.getPane('rotulosComuna').style.pointerEvents = 'none';
    for (const rc of rotulosComuna) {
      L.marker([rc.lat, rc.lon], {
        pane: 'rotulosComuna', interactive: false, keyboard: false,
        icon: L.divIcon({ className: 'rotulo-comuna', html: `<span>${rc.n}</span>`,
                          iconSize: null })
      }).addTo(mapa);
    }
    const ajustarRotulos = () => {
      const z = mapa.getZoom();
      const pane = mapa.getPane('rotulosComuna');
      pane.style.display = z < 9 ? 'none' : '';
      pane.style.fontSize = z >= 12 ? '13px' : z >= 10 ? '11.5px' : '10px';
    };
    mapa.on('zoomend', ajustarRotulos);
    const aplicarRadios = () => {
      S.zoomActual = mapa.getZoom();
      S.marcadores.forEach(m => { if (!m._tween) m.setStyle({ radius: radioDe(m._props) }); });
    };
    mapa.on('zoomend', aplicarRadios);
    aplicarRadios();
    ajustarRotulos();
    new ResizeObserver(() => mapa.invalidateSize()).observe(cont);
    iniciarFiltros();           // requiere marcadores ya creados
    window.__M = { mapa, S, F, aplicarFiltros, limpiarFiltros };   // handle de inspeccion (sin estado persistente)
    } catch (e) { window.__errMontar = e.message + ' @ ' + (e.stack || '').split('\n')[1]; throw e; }
  };
  montar();

  document.getElementById('contador').textContent =
    `${S.total.toLocaleString('es-CL')} de ${S.total.toLocaleString('es-CL')}`;
  construirLeyenda();
}

iniciar().catch(err => {
  document.getElementById('mapa').innerHTML =
    `<p style="padding:20px;font-size:14px">Error cargando los datos del mapa: ${err.message}</p>`;
});
