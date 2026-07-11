/* =============================================================================
   mapa.js — Mapa interactivo de establecimientos, Región de Valparaíso.
   Hito 2: mapa base + pins por SLEP/dependencia + hover + click con 4
   indicadores (3 estados) + sparkline. Estado 100% en memoria (sin browser
   storage). Datos congelados: data/*.json (esquema en metadatos.json).
   ============================================================================= */
'use strict';

/* ---- Paleta (contrastes WCAG verificados; ver auditoría) ---- */
const PAL_SLEP = {
  'Costa Central': '#0F3B66',   // protagonista: el más oscuro, radio +1
  'Valparaíso':    '#1E5D90',   // gradación por antigüedad de traspaso
  'Aconcagua':     '#28709F',
  'Los Andes':     '#2F7FA8',
  'Marga Marga':   '#3789AE',
  'Petorca':       '#3E92B4'
};
const PAL_DEP = {
  'Municipal':                        '#496524',
  'Particular Subvencionado':         '#A6741C',
  'Particular Pagado':                '#7A4A8A',
  'Corp. de Administración Delegada': '#4D5D6B'
};
const COLOR_ATENUADO = '#c9c4bb';
const RADIO_HOVER = 3;
// Radio por zoom (evaluacion empirica de densidad: a zoom regional el Gran
// Valparaiso satura con radio fijo; pins mas chicos en vista amplia, plenos al
// acercarse). Costa Central lleva +1 px (doble codificacion, ademas del color).
function radioBase(z) { return z <= 9 ? 3.5 : z <= 11 ? 4.5 : 5.5; }
const ETIQUETA_SLEP = 'Servicio Local de Educación';

/* ---- Estado en memoria ---- */
const S = { ee: [], sinGeo: [], meta: null, capa: null, marcadores: new Map(), total: 0 };

/* ---- Utilidades ---- */
const esNum = v => typeof v === 'number';
function colorDe(p) { return p.slep ? PAL_SLEP[p.slep] : PAL_DEP[p.dep] || '#888'; }
function radioDe(p) {
  const z = S.zoomActual || 9;
  return radioBase(z) + (p.slep === 'Costa Central' ? 1 : 0);
}
function fmt(n) { return esNum(n) ? n.toLocaleString('es-CL') : n; }
function depTexto(p) { return p.slep ? `${ETIQUETA_SLEP} ${p.slep}` : p.dep; }
function ultimoAnioConDato(s, anios) {
  for (let i = s.length - 1; i >= 0; i--) if (esNum(s[i])) return anios[i];
  return null;
}

/* ---- Sparkline SVG: huecos = línea interrumpida (null NO es cero) ---- */
function sparkline(serie, anios) {
  const W = 240, H = 64, PAD = 6, PB = 14;
  const vals = serie.filter(esNum);
  if (!vals.length) return '';
  // eje Y desde 0: la matrícula es magnitud absoluta; partir del mínimo exagera caídas
  const maxV = Math.max(...vals);
  const x = i => PAD + i * (W - 2 * PAD) / (serie.length - 1);
  const y = v => (H - PB) - (v / maxV) * (H - PB - PAD);
  // segmentos contiguos (se cortan en los huecos)
  const seg = []; let cur = [];
  serie.forEach((v, i) => {
    if (!esNum(v)) { if (cur.length) seg.push(cur); cur = []; }
    else cur.push([x(i), y(v), v, anios[i]]);
  });
  if (cur.length) seg.push(cur);
  let g = '';
  for (const sg of seg) {
    if (sg.length === 1) {                     // año aislado -> punto
      g += `<circle cx="${sg[0][0].toFixed(1)}" cy="${sg[0][1].toFixed(1)}" r="2.6" fill="#4A2746"/>`;
    } else {
      const pts = sg.map(p => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(' ');
      g += `<polyline points="${pts}" fill="none" stroke="#4A2746" stroke-width="1.8"/>`;
      g += sg.map(p => `<circle cx="${p[0].toFixed(1)}" cy="${p[1].toFixed(1)}" r="1.7" fill="#4A2746"/>`).join('');
    }
  }
  // marcas de hueco (tic gris en la base, para que el vacío se lea como "sin dato")
  serie.forEach((v, i) => {
    if (!esNum(v)) g += `<line x1="${x(i).toFixed(1)}" y1="${H - PB + 2}" x2="${x(i).toFixed(1)}" y2="${H - PB + 6}" stroke="#c9c4bb" stroke-width="1.5"/>`;
  });
  const a0 = anios[0], a1 = anios[anios.length - 1];
  g += `<text x="${PAD}" y="${H - 2}" font-size="8.5" fill="#9a9488">${a0}</text>`;
  g += `<text x="${W - PAD}" y="${H - 2}" font-size="8.5" fill="#9a9488" text-anchor="end">${a1}</text>`;
  g += `<text x="${W - PAD}" y="${PAD + 4}" font-size="8.5" fill="#9a9488" text-anchor="end">máx ${fmt(maxV)}</text>`;
  return `<svg class="pp-spark-svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="Serie de matrícula">${g}</svg>`;
}

/* ---- Contenido del popup: 4 indicadores en 3 estados + sparkline ---- */
function htmlPopup(p) {
  const anios = S.meta.ventana_anios;
  const sinSerie = !esNum(p.mx);                       // estado 3
  const enCierre = !esNum(p.ma) && esNum(p.mx);        // estado 2
  let estado = '';
  if (enCierre) {
    const ult = ultimoAnioConDato(p.s, anios);
    estado = `<div class="pp-estado cierre"><strong>${p.ma}</strong> Registró matrícula hasta ${ult}: los indicadores de la ventana son reales.</div>`;
  } else if (sinSerie) {
    estado = `<div class="pp-estado sindato"><strong>${p.ma}</strong> Sin registros de matrícula en la ventana 2016–2025.</div>`;
  }
  const ind = (etq, v) => `<div class="pp-ind"><div class="pp-ind-etq">${etq}</div>
    <div class="pp-ind-val${esNum(v) ? '' : ' sin-dato'}">${fmt(v)}</div></div>`;
  const indicadores = `<div class="pp-indicadores">
    ${ind('Matrícula actual (2025)', p.ma)}
    ${ind('Máximo últimos 10 años', p.mx)}
    ${ind('Promedio últimos 10 años', p.pr)}
    ${ind('Mínimo últimos 10 años', p.mn)}</div>`;
  const nDatos = p.s.filter(esNum).length;
  const spark = sinSerie ? '' :
    `<div class="pp-spark"><div class="pp-spark-titulo">Serie ${anios[0]}–${anios[anios.length - 1]}</div>${sparkline(p.s, anios)}</div>`;
  const nota = nDatos === 1 ?
    `<div class="pp-nota">${S.meta.criterios_calculo.nota_serie_corta}</div>` : '';
  return `<div class="pp">
    <div class="pp-nombre">${p.n} (RBD ${p.rbd})</div>
    <div class="pp-sub">${p.com} · ${depTexto(p)}</div>
    ${estado}${indicadores}${spark}${nota}</div>`;
}

/* ---- Leyenda ---- */
function construirLeyenda() {
  const el = document.getElementById('leyenda');
  const item = (color, etq) =>
    `<div class="leyenda-item"><span class="leyenda-punto" style="background:${color}"></span>${etq}</div>`;
  let h = '<div class="leyenda-grupo">Servicios Locales de Educación</div>';
  for (const [n, c] of Object.entries(PAL_SLEP)) h += item(c, `SLEP ${n}`);
  h += '<div class="leyenda-grupo">Otras dependencias</div>';
  for (const [n, c] of Object.entries(PAL_DEP)) h += item(c, n);
  el.innerHTML = h;
  // nota de SLEP pendientes, desde metadatos (decisión del titular)
  const pend = (S.meta.filtro_slep || []).filter(s => s.estado === 'pendiente');
  if (pend.length)
    document.getElementById('nota-slep-pendientes').textContent =
      'SLEP con traspaso pendiente (sus EE siguen municipales): ' +
      pend.map(s => `${s.slep} (${s.anio_traspaso})`).join(' · ') + '.';
}

/* ---- Pins ---- */
function crearCapa(mapa) {
  const grupo = L.featureGroup();
  for (const f of S.ee) {
    const p = f.properties;
    const m = L.circleMarker([f.geometry.coordinates[1], f.geometry.coordinates[0]], {
      radius: radioDe(p), color: '#ffffff', weight: 1.5,
      fillColor: colorDe(p), fillOpacity: 0.92
    });
    m.bindTooltip(
      `<div class="tt-nombre">${p.n} (RBD ${p.rbd})</div>
       <div class="tt-sub">${p.com} · ${depTexto(p)}</div>`,
      { className: 'tt-ee', direction: 'top', offset: [0, -6], sticky: true });
    m.on('mouseover', () => m.setStyle({ radius: radioDe(p) + RADIO_HOVER, weight: 2 }));
    m.on('mouseout',  () => m.setStyle({ radius: radioDe(p), weight: 1.5 }));
    m.bindPopup(() => htmlPopup(p), { maxWidth: 300, autoPanPadding: [30, 30] });
    m._props = p;
    S.marcadores.set(p.rbd, m);
    grupo.addLayer(m);
  }
  grupo.addTo(mapa);
  S.capa = grupo;
  return grupo;
}

/* ---- Arranque ---- */
async function iniciar() {
  const [geo, meta] = await Promise.all([
    fetch('data/establecimientos.geojson').then(r => r.json()),
    fetch('data/metadatos.json').then(r => r.json())
  ]);
  fetch('data/sin_geo.json').then(r => r.json()).then(sg => { S.sinGeo = sg; });
  S.ee = geo.features; S.meta = meta; S.total = geo.features.length;

  // El mapa se crea SOLO cuando el contenedor ya tiene tamano: si Leaflet nace
  // con un contenedor 0x0 (p. ej. prerender con la pestana oculta), cachea el
  // tamano 0 y fitBounds/invalidateSize quedan inutilizables (invalidateSize es
  // no-op sin vista inicial). setTimeout y no rAF: rAF no corre en pestanas ocultas.
  const montar = () => {
    const cont = document.getElementById('mapa');
    if (cont.clientWidth === 0 || cont.clientHeight === 0) { setTimeout(montar, 120); return; }
    const mapa = L.map('mapa', { preferCanvas: true, zoomControl: true });
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · © <a href="https://carto.com/">CARTO</a>',
      subdomains: 'abcd', maxZoom: 19
    }).addTo(mapa);
    // rotulos de referencia encima (Positron labels aparte, no compiten con pins)
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd', maxZoom: 19, pane: 'shadowPane', opacity: 0.9
    }).addTo(mapa);
    S.zoomActual = 9;
    const capa = crearCapa(mapa);
    mapa.fitBounds(capa.getBounds().pad(0.04));
    // radio por zoom: se reaplica a todos los marcadores al cambiar el nivel
    const aplicarRadios = () => {
      S.zoomActual = mapa.getZoom();
      S.marcadores.forEach(m => m.setStyle({ radius: radioDe(m._props) }));
    };
    mapa.on('zoomend', aplicarRadios);
    aplicarRadios();
    new ResizeObserver(() => mapa.invalidateSize()).observe(cont);
    window.__M = { mapa, S };   // handle de inspeccion (sin estado persistente)
  };
  montar();

  document.getElementById('contador').textContent =
    `${S.total.toLocaleString('es-CL')} de ${S.total.toLocaleString('es-CL')}`;
  construirLeyenda();
}

iniciar().catch(err => {
  document.getElementById('mapa').innerHTML =
    `<p style="padding:20px;font-size:13px">Error cargando los datos del mapa: ${err.message}</p>`;
});
