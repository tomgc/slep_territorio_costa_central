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
const COLOR_INSTITUCIONAL = '#0D2E52';  // azul SLEP CC: unico color principal (sesion 9)
/* ---- Mascara invertida (sesion 12) ----
   Todo lo que NO es Region de Valparaiso se vela: no es foco de analisis, y
   dejarlo a plena saturacion competia visualmente con el territorio del estudio.
   La tecnica es UN polígono: anillo exterior = mundo entero, anillos interiores =
   los del contorno regional. La regla par-impar del GeoJSON convierte esos
   anillos interiores en agujeros, y el relleno solo pinta el exterior.
   Es un solo feature, no un recorte de tiles: costo de render despreciable. */
const COLOR_MASCARA   = '#EAE6DC';   // color pagina: vela sin ensuciar
const OPACIDAD_MASCARA = 0.72;       // el fondo de fuera se insinua, no desaparece
const MUNDO = [[-180, -85], [180, -85], [180, 85], [-180, 85], [-180, -85]];
const HOVER_EXTRA = 4.5;          // crecimiento del pin al hover (mas notorio)
const HOVER_MS    = 180;          // duracion del tween (suave, no salto)
const TOLERANCIA_HOVER = 8;       // px extra de area sensible ("close-enough")
const ZOOM_MAX_ENCUADRE = 14;     // tope al encuadrar filtrados (un pin unico no salta a z19)
const PAD_ENCUADRE_FILTRO = 0.12; // aire alrededor del encuadre de los coincidentes
// Radio por zoom (densidad evaluada empiricamente). Costa Central +1 (doble codificacion).
function radioBase(z) { return z <= 9 ? 3.5 : z <= 11 ? 4.5 : 5.5; }
const ETIQUETA_SLEP = 'Servicio Local de Educación';

/* ---- Estado en memoria ---- */
const S = { ee: [], sinGeo: [], meta: null, capa: null, marcadores: new Map(),
            tipoEE: '', renderer: null,
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
      g += `<polyline points="${pts}" fill="none" stroke="${COLOR_INSTITUCIONAL}" stroke-width="1.8"/>`;
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
    g += `<circle cx="${px.toFixed(1)}" cy="${py.toFixed(1)}" r="${(esMax || esMin) ? 3.1 : 2.1}" fill="${COLOR_INSTITUCIONAL}"/>`;
    const arriba = alterna % 2 === 0; alterna++;
    const ty = arriba ? py - 7 : py + 14;
    const peso = (esMax || esMin) ? ' font-weight="bold"' : '';
    g += `<text x="${px.toFixed(1)}" y="${Math.max(8, Math.min(H - PB - 2, ty)).toFixed(1)}" font-size="10.2"${peso} fill="${(esMax || esMin) ? COLOR_INSTITUCIONAL : '#6b655c'}" text-anchor="middle">${fmt(v)}</text>`;
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

/* ---- Leyenda (UNICA) ----
   Sesion 21: la capa parvularia no construye leyenda propia.
   Sesion 22: la leyenda es una lista de SOSTENEDORES y nada mas. Ya no hay
   grupo de simbolos ni fila de anillo, porque la marca dejo de codificar el
   nivel: todo lo de un mismo sostenedor se ve igual, imparta parvulos, basica o
   media. JUNJI e INTEGRA entran como sostenedores propios; los VTF de las
   comunas confirmadas se leen en la fila de su SLEP y no tienen fila aparte. */
function construirLeyenda() {
  const el = document.getElementById('leyenda');
  const item = (color, etq) =>
    `<div class="leyenda-item"><span class="leyenda-punto" style="background:${color}"></span>${etq}</div>`;
  let h = '<div class="leyenda-grupo">Servicios Locales de Educación</div>';
  for (const [n, c] of Object.entries(PAL_SLEP)) h += item(c, `SLEP ${n}`);
  h += '<div class="leyenda-grupo">Otras dependencias</div>';
  for (const [n, c] of Object.entries(PAL_DEP)) h += item(c, ETIQUETA_DEP[n] || n);
  // JUNJI e INTEGRA no son dependencias del directorio escolar: no existen en
  // PAL_DEP y por eso entran como grupo propio, no como cuarta fila de arriba.
  h += '<div class="leyenda-grupo">Sostenedores de educación parvularia</div>';
  h += item(COLOR_JUNJI, 'JUNJI');
  h += item(COLOR_INTEGRA, 'INTEGRA');
  // Los VTF cuyo sostenedor es un Servicio Local ya aparecen arriba, en la
  // fila de ese SLEP. Esta fila es para los demas: sostenedor distinto de un
  // Servicio Local, o sin dato en la fuente.
  h += item(COLOR_SIN_ADMIN, 'JUNJI VTF con sostenedor distinto de un Servicio Local');
  el.innerHTML = h;
  const pend = (S.meta.filtro_slep || []).filter(s => s.estado === 'pendiente');
  if (pend.length)
    document.getElementById('nota-slep-pendientes').textContent =
      'SLEP con traspaso pendiente: ' +
      pend.map(s => `${s.slep} (${s.anio_traspaso})`).join(' · ') + '.';
  // Traspaso parcial: el SLEP ya tiene EE en el mapa (por eso su estado es
  // vigente y aparece en el desplegable), pero alguna de sus comunas se
  // incorpora en un anio posterior al de vigencia. Sin este segmento la nota
  // anunciaba un traspaso completo que los propios pines contradicen.
  const parc = (S.meta.filtro_slep || []).filter(s => s.traspaso_parcial === true);
  if (parc.length) {
    const nota = document.getElementById('nota-slep-pendientes');
    nota.textContent += (nota.textContent ? ' ' : '') +
      'SLEP con traspaso parcial: ' +
      parc.map(s => `${s.slep} (completa en ${s.anio_traspaso_max})`).join(' · ') + '.';
  }
}

/* ---- Mascara invertida: el mundo menos la Region de Valparaiso ----
   Recolecta TODOS los anillos exteriores del contorno regional (el primer anillo
   de cada Polygon; los siguientes son huecos del propio poligono y no se tocan)
   y los cuelga como anillos interiores de un unico poligono cuyo exterior es el
   mundo. No modifica S.fronteraRegion. */
function anillosExterioresDe(gj) {
  const geoms = (gj.features ? gj.features.map(f => f.geometry) : [gj.geometry || gj]);
  const anillos = [];
  for (const g of geoms) {
    if (!g) continue;
    if (g.type === 'Polygon') anillos.push(g.coordinates[0]);
    else if (g.type === 'MultiPolygon') g.coordinates.forEach(pg => anillos.push(pg[0]));
  }
  return anillos;
}
function geojsonMascara(fronteraRegion) {
  return {
    type: 'Feature', properties: {},
    geometry: { type: 'Polygon', coordinates: [MUNDO, ...anillosExterioresDe(fronteraRegion)] }
  };
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

/* -- Tipo de EE (sesion 22): que universo se ve -------------------------------
   Reemplaza al toggle de la capa parvularia. NO entra en F ni en PRED, y es
   deliberado: F filtra establecimientos del directorio uno a uno, esto decide
   que CAPA se dibuja. Los demas filtros siguen gobernando SOLO los pines, porque
   una unidad de parvulos no tiene RBD, dependencia ni tipo de ensenanza en el
   sentido del directorio. Vive en S, no en F, para que hayFiltrosActivos() no
   lo cuente y no dispare el encuadre ni el cartel de cero resultados.          */
const TIPO_EE = { TODOS: '', JARDINES: 'jardines', ESCUELAS: 'escuelas' };
// Etiquetas de despliegue del filtro. Existen porque la exportacion tiene que
// DECLARAR que universo se llevo el archivo: un SVG con 395 discos y sin la
// frase "Tipo de EE: Jardines infantiles" en el pie es indistinguible de un
// mapa incompleto. TODOS no lleva etiqueta: "sin filtro" ya es el defecto.
const ETIQUETA_TIPO_EE = {
  [TIPO_EE.JARDINES]: 'Jardines infantiles',
  [TIPO_EE.ESCUELAS]: 'Escuelas y liceos'
};

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

/* Los jardines son establecimientos educacionales y cuentan en el mismo universo
   (sesion 22), asi que los filtros tienen que gobernarlos tambien. Tres reglas
   que el dato no resuelve solo y que quedan declaradas aqui:
   - Dependencia y SLEP se resuelven por el Servicio Local de la comuna, que es
     el mismo criterio con que se pintan. JUNJI e INTEGRA no son dependencias del
     directorio, asi que nunca pasan un filtro de dependencia.
   - Tipo de ensenanza: una unidad de parvulos solo imparte parvularia.
   - Nivel y Nombre del establecimiento los EXCLUYEN: los niveles del dato
     parvulario (sala cuna, medio, transicion) no son los del directorio (NT1,
     NT2, 1 a 8), y estas unidades no tienen RBD que buscar.                    */
function cumpleParv(pr) {
  if (F.rbd !== null || F.nivel !== null) return false;
  if (F.tipo !== null && F.tipo !== 'Educación Parvularia') return false;
  if (F.com !== null && pr.comuna !== F.com) return false;
  if (F.prov !== null && provDeComuna(pr.comuna) !== F.prov) return false;
  const s = slepDelVtf(pr);
  if (F.dep !== null && !(s && F.dep === 'Servicio Local de Educación')) return false;
  if (F.slep !== null && s !== F.slep) return false;
  return true;
}
function verPines()      { return S.tipoEE !== TIPO_EE.JARDINES; }
function verParvularia() { return S.tipoEE !== TIPO_EE.ESCUELAS; }

async function aplicarTipoEE(valor) {
  S.tipoEE = valor;
  if (S.capa) {
    const puesta = S.mapa.hasLayer(S.capa);
    if (verPines() && !puesta) S.capa.addTo(S.mapa);
    else if (!verPines() && puesta) S.mapa.removeLayer(S.capa);
  }
  await activarParvularia(verParvularia());
  aplicarFiltros();
}

// Un solo universo: los jardines son establecimientos educacionales y entran en
// el total. S.parvularia.total se fija al cargar el geojson y NO depende de que
// la capa este montada, para que el denominador no cambie al filtrar.
function totalUniverso() {
  return S.total + ((S.parvularia && S.parvularia.total) || 0);
}
function textoContador(n) {
  return `${n.toLocaleString('es-CL')} de ${totalUniverso().toLocaleString('es-CL')} establecimientos`;
}

/* Unidades de parvulos que la exportacion considera: las MISMAS que la capa
   monta (tipo_estab >= 5, el mismo predicado del `filter` del L.geoJSON), leidas
   del cache y no de la capa. Del cache y no de la capa porque exportar no puede
   depender de que el usuario haya tenido la capa encendida en ese instante: con
   "Escuelas y liceos" la capa esta desmontada y el cache sigue en memoria.
   Devuelve vacio si el geojson nunca llego a cargarse, y quien la llama declara
   ese vacio en la hoja de notas en vez de callarlo. */
function featuresParvularia() {
  const d = S.parvularia && S.parvularia.cache;
  return d ? d.features.filter(f => f.properties.tipo_estab >= 5) : [];
}

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
    if (ok && verPines()) { n++; coincidentes.push(m); }
    m.setStyle(ok ?
      { fillColor: colorDe(p), fillOpacity: 0.92, color: '#ffffff', weight: 1.5 } :
      { fillColor: COLOR_ATENUADO, fillOpacity: 0.5, color: '#ffffff', weight: 1 });
  });
  // Los jardines cuentan y se atenuan con el mismo criterio que los pines.
  if (S.parvularia && S.parvularia.capa) {
    S.parvularia.capa.eachLayer(m => {
      const pr = m.feature.properties;
      const ok = !activos || cumpleParv(pr);
      if (ok) { n++; coincidentes.push(m); }
      m.setStyle(ok ?
        { fillColor: colorParvularia(pr), fillOpacity: 0.92, color: '#ffffff', weight: 1.5 } :
        { fillColor: COLOR_ATENUADO, fillOpacity: 0.5, color: '#ffffff', weight: 1 });
    });
  }
  coincidentes.forEach(m => m.bringToFront());   // coincidentes plenos ENCIMA
  document.getElementById('contador').textContent = textoContador(n);
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
  // zoom-to-fit: con filtros activos y resultados, encuadra los coincidentes.
  // Con n === 0 la vista NO se mueve (el mensaje de cero ya informa).
  if (activos && coincidentes.length) {
    S.mapa.fitBounds(L.featureGroup(coincidentes).getBounds().pad(PAD_ENCUADRE_FILTRO),
                     { maxZoom: ZOOM_MAX_ENCUADRE, animate: true });
  }
  reconstruirOpciones();
}
function limpiarFiltros() {
  for (const k of Object.keys(F)) F[k] = null;
  const selBox = document.getElementById('f-ee-sel');
  selBox.hidden = true; selBox.innerHTML = '';
  document.getElementById('f-ee').value = '';
  document.getElementById('f-nivel-wrap').hidden = true;
  // "Tipo de EE" tambien se limpia: es un filtro de la barra, no una preferencia
  // persistente. aplicarTipoEE termina llamando a aplicarFiltros.
  document.getElementById('f-tipoee').value = TIPO_EE.TODOS;
  aplicarTipoEE(TIPO_EE.TODOS);
  // limpiar es un gesto distinto de filtrar: vuelve al encuadre por defecto
  S.mapa.fitBounds(S.boundsDefecto, { animate: true });
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

/* =============================================================================
   EXPORTACIÓN (hito 4) — SVG de la vista actual + XLSX de los datos filtrados.
   - SVG: vectores puros (pins, frontera regional, frontera Costa Central,
     rótulos de comuna, leyenda, título y atribución) proyectados con el zoom y
     encuadre VIGENTES. El fondo cartográfico (tiles CARTO) es imagen raster y
     NO se incrusta: se declara en la nota del pie del propio SVG. Con filtro
     activo, los no coincidentes van ATENUADOS (misma lectura que la pantalla:
     sin basemap, son la única referencia geográfica del territorio).
   - XLSX: SheetJS LOCAL (assets/vendor, sin CDN) con carga diferida (~930 KB:
     no penaliza la carga inicial). Filas = universo completo o filtrado según
     F, INCLUYENDO los EE sin coordenadas que el filtro alcance ("existen aunque
     no se pinchen"). Números como celdas numéricas nativas: Excel/Numbers en
     locale español los muestra con punto de miles y coma decimal sin
     conversión alguna. Literales tal cual el JSON ("Sin matrícula en 2025.",
     "sin dato"); año sin registro = celda vacía (nunca 0).
   ============================================================================= */
function escXML(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function slugArchivo(s) {
  return String(s).normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}
function fechaLocalISO() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
function partesFiltro() {
  const partes = [];
  // Primero porque decide el UNIVERSO, no una condicion dentro de el. Vive en S
  // y no en F (ver el bloque de TIPO_EE), asi que hay que traerlo a mano: es
  // exactamente el olvido que dejo la exportacion ciega al filtro en la s22.
  if (S.tipoEE) partes.push(['Tipo de EE', ETIQUETA_TIPO_EE[S.tipoEE] || S.tipoEE]);
  if (F.prov)  partes.push(['Provincia', F.prov]);
  if (F.com)   partes.push(['Comuna', titulo(F.com)]);
  if (F.dep)   partes.push(['Dependencia', ETIQUETA_DEP[F.dep] || F.dep]);
  if (F.slep)  partes.push(['SLEP', F.slep]);
  if (F.rbd) {
    const m = S.marcadores.get(F.rbd);
    partes.push(['Establecimiento', m ? `${titulo(m._props.n)} (RBD ${F.rbd})` : `RBD ${F.rbd}`]);
  }
  if (F.tipo)  partes.push(['Tipo de enseñanza', F.tipo]);
  if (F.nivel) partes.push(['Nivel', F.nivel]);
  return partes;
}
function descripcionFiltro() {
  const p = partesFiltro();
  return p.length ? p.map(([k, v]) => `${k}: ${v}`).join(' · ') : null;
}
// nombre con sentido: el filtro aplicado si lo hay; la fecha si no
function nombreArchivo(base, ext) {
  const p = partesFiltro();
  const sufijo = p.length ? p.map(([, v]) => slugArchivo(v)).join('_').slice(0, 90)
                          : fechaLocalISO();
  return `${base}_${sufijo}.${ext}`;
}
function descargarBlob(blob, nombre) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = nombre;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
}

/* ---- SVG ---- */
const SVG_CAB = 96, SVG_PIE = 60;          // bandas de título y atribución
const FUENTE_TITULO = 'gobCL, Helvetica, Arial, sans-serif';
const FUENTE_TEXTO  = 'gobCL, Helvetica, Arial, sans-serif';
// anillos de un (Multi)Polygon GeoJSON como path SVG (proyección pt: [lon,lat]→{x,y})
function pathDeGeojson(gj, pt) {
  const geoms = (gj.features ? gj.features.map(f => f.geometry) : [gj.geometry || gj]);
  const anillo = cs => 'M' + cs.map(c => { const q = pt(c); return `${q.x.toFixed(1)} ${q.y.toFixed(1)}`; }).join('L') + 'Z';
  let d = '';
  for (const g of geoms) {
    if (!g) continue;
    if (g.type === 'Polygon')      g.coordinates.forEach(r => { d += anillo(r); });
    else if (g.type === 'MultiPolygon') g.coordinates.forEach(pg => pg.forEach(r => { d += anillo(r); }));
  }
  return d;
}
function construirSVG() {
  const mapa = S.mapa;
  const tam = mapa.getSize();
  const W = Math.round(tam.x), HM = Math.round(tam.y), H = SVG_CAB + HM + SVG_PIE;
  const activos = hayFiltrosActivos();
  // "Tipo de EE" no vive en F, asi que hayFiltrosActivos() no lo ve: hay que
  // preguntarlo aparte. Sin esto, con "Jardines infantiles" el SVG salia con los
  // 1.251 pines plenos que la pantalla oculta (defecto de la sesion 22).
  const verP = verPines(), verV = verParvularia();
  const pt = c => { const q = mapa.latLngToContainerPoint([c[1], c[0]]); return { x: q.x, y: q.y + SVG_CAB }; };

  // pins: atenuados primero, coincidentes ENCIMA (mismo orden que la pantalla)
  let aten = '', plenos = '', n = 0;
  const slepsVista = new Set(), depsVista = new Set(), parvVista = new Set();
  let hayAtenEnVista = false;
  if (verP) for (const f of S.ee) {
    const p = f.properties;
    const q = pt(f.geometry.coordinates);
    const ok = !activos || cumple(p, null);
    if (ok) n++;
    if (q.x < -20 || q.x > W + 20 || q.y < SVG_CAB - 20 || q.y > SVG_CAB + HM + 20) continue;
    const r = radioDe(p);
    if (ok) {
      plenos += `<circle cx="${q.x.toFixed(1)}" cy="${q.y.toFixed(1)}" r="${r}" fill="${colorDe(p)}" fill-opacity="0.92" stroke="#ffffff" stroke-width="1.5"/>`;
      if (p.slep) slepsVista.add(p.slep); else depsVista.add(p.dep);
    } else {
      aten += `<circle cx="${q.x.toFixed(1)}" cy="${q.y.toFixed(1)}" r="${Math.max(2.5, r - 1)}" fill="${COLOR_ATENUADO}" fill-opacity="0.5" stroke="#ffffff" stroke-width="1"/>`;
      hayAtenEnVista = true;
    }
  }

  // Unidades de parvulos: mismo simbolo, mismo criterio de atenuacion y mismo
  // contador que los pines. Antes no se dibujaban en ningun estado del filtro,
  // de modo que el SVG nunca dijo lo mismo que la pantalla desde la sesion 21.
  // Un VTF con SLEP conocido entra a la leyenda por la fila de su SLEP, igual
  // que en construirLeyenda(); los demas por su categoria parvularia.
  if (verV) for (const f of featuresParvularia()) {
    const pr = f.properties;
    const q = pt(f.geometry.coordinates);
    const ok = !activos || cumpleParv(pr);
    if (ok) n++;
    if (q.x < -20 || q.x > W + 20 || q.y < SVG_CAB - 20 || q.y > SVG_CAB + HM + 20) continue;
    const r = radioParvularia(pr);
    if (ok) {
      plenos += `<circle cx="${q.x.toFixed(1)}" cy="${q.y.toFixed(1)}" r="${r}" fill="${colorParvularia(pr)}" fill-opacity="0.92" stroke="#ffffff" stroke-width="1.5"/>`;
      const s = slepDelVtf(pr);
      if (s) slepsVista.add(s); else parvVista.add(pr.tipo_estab);
    } else {
      aten += `<circle cx="${q.x.toFixed(1)}" cy="${q.y.toFixed(1)}" r="${Math.max(2.5, r - 1)}" fill="${COLOR_ATENUADO}" fill-opacity="0.5" stroke="#ffffff" stroke-width="1"/>`;
      hayAtenEnVista = true;
    }
  }

  // fronteras (región: contexto tenue; Costa Central: protagonista)
  const dRegion = pathDeGeojson(S.fronteraRegion, pt);
  const dCC = pathDeGeojson(S.frontera, pt);
  // mascara invertida: el SVG debe decir lo MISMO que la pantalla. Un solo path
  // (mundo + anillos regionales como huecos) con fill-rule evenodd.
  const dMascara = pathDeGeojson(geojsonMascara(S.fronteraRegion), pt);

  // rótulos de comuna: misma regla de visibilidad que la pantalla (z>=9)
  let rotulos = '';
  if (S.zoomActual >= 9 && S.rotulos) {
    const fs = S.zoomActual >= 12 ? 13 : S.zoomActual >= 10 ? 11.5 : 10;
    for (const rc of S.rotulos) {
      const q = pt([rc.lon, rc.lat]);
      if (q.x < 0 || q.x > W || q.y < SVG_CAB || q.y > SVG_CAB + HM) continue;
      rotulos += `<text x="${q.x.toFixed(1)}" y="${q.y.toFixed(1)}" font-family="${FUENTE_TEXTO}" font-size="${fs}" fill="#3A3A3A" text-anchor="middle" stroke="#ffffff" stroke-width="3" paint-order="stroke" letter-spacing=".02em">${escXML(rc.n)}</text>`;
    }
  }

  // leyenda: SOLO categorías presentes entre los coincidentes de la vista
  const items = [];
  for (const [nom, col] of Object.entries(PAL_SLEP)) if (slepsVista.has(nom)) items.push([col, `SLEP ${nom}`]);
  for (const [nom, col] of Object.entries(PAL_DEP)) if (depsVista.has(nom)) items.push([col, ETIQUETA_DEP[nom] || nom]);
  // Categorias parvularias presentes. Se deduplica por ETIQUETA porque los tipos
  // 7 y 8 comparten la de INTEGRA (fusion deliberada de la sesion 22) y dos
  // filas identicas en la leyenda serian un defecto visible.
  const etqParv = new Set();
  for (const t of parvVista) {
    const etq = ETIQUETA_PARVULARIA[t];
    if (!etq || etqParv.has(etq)) continue;
    etqParv.add(etq);
    items.push([COLOR_PARVULARIA[t] || '#888', etq]);
  }
  if (activos && hayAtenEnVista) items.push([COLOR_ATENUADO, 'No cumple el filtro aplicado']);
  const LW = 268, LIH = 19, LPAD = 12;
  const LH = LPAD * 2 + 16 + items.length * LIH;
  const lx = W - LW - 14, ly = SVG_CAB + 14;
  let leyenda = `<g><rect x="${lx}" y="${ly}" width="${LW}" height="${LH}" rx="9" fill="#ffffff" fill-opacity="0.94" stroke="#E2D9C4"/>`;
  leyenda += `<text x="${lx + LPAD}" y="${ly + LPAD + 10}" font-family="${FUENTE_TITULO}" font-size="12" font-weight="bold" fill="#1C1212">Leyenda</text>`;
  items.forEach(([col, etq], i) => {
    const yy = ly + LPAD + 16 + i * LIH + 9;
    leyenda += `<circle cx="${lx + LPAD + 7}" cy="${yy - 4}" r="6" fill="${col}" stroke="#ffffff" stroke-width="1.5"/>`;
    leyenda += `<text x="${lx + LPAD + 20}" y="${yy}" font-family="${FUENTE_TEXTO}" font-size="11.5" fill="#2E2230">${escXML(etq)}</text>`;
  });
  leyenda += '</g>';

  // cabecera y pie
  const desc = descripcionFiltro();
  // Universo unico (1.646): el mismo denominador del contador de pantalla. Con
  // S.total (1.251) el SVG contradecia al mapa del que salio.
  const linea2 = `${fmt(n)} de ${fmt(totalUniverso())} establecimientos georreferenciados` +
    (desc ? ` · Filtro — ${desc}` : ' · Sin filtros: universo completo') +
    ' · Dependencia vigente 2026';
  // Los sin-coordenadas son del directorio: con los pines fuera de vista no hay
  // ninguno que declarar, y contarlos igual seria hablar de un universo ausente.
  const nSinAlc = verP ? S.sinGeo.filter(p => !activos || cumple(p, null)).length : 0;
  const pie1 = 'Elaborado por el Área de Monitoreo a partir de datos del Centro de Estudios MINEDUC (Directorio Oficial y Matrícula por estudiante 2016–2025) y listado oficial de SLEP 2026.';
  const pie2 = `Exportado el ${fechaLocalISO()} desde el mapa interactivo · El fondo cartográfico (tiles raster de CARTO) no se incluye: este SVG contiene pins, fronteras, rótulos y leyenda vectoriales.`;
  const pl = nSinAlc === 1 ? '' : 'n';
  const pie3 = (activos ? 'Los pins atenuados no cumplen el filtro aplicado. ' : '') +
    (nSinAlc ? `${nSinAlc} establecimiento${nSinAlc === 1 ? '' : 's'} sin coordenadas ` +
      (activos ? `cumple${pl} el filtro y ` : '') + `no figura${pl} en el mapa (sí en la descarga XLSX).` : '');

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="Mapa de establecimientos educacionales, Región de Valparaíso">
<rect width="${W}" height="${H}" fill="#ffffff"/>
<rect x="0" y="${SVG_CAB}" width="${W}" height="${HM}" fill="#F2F1EC"/>
<clipPath id="clipmapa"><rect x="0" y="${SVG_CAB}" width="${W}" height="${HM}"/></clipPath>
<g clip-path="url(#clipmapa)">
<path d="${dMascara}" fill-rule="evenodd" fill="${COLOR_MASCARA}" fill-opacity="${OPACIDAD_MASCARA}" stroke="none"/>
<path d="${dRegion}" fill="none" stroke="#9aa4ad" stroke-width="1" stroke-opacity="0.6"/>
<path d="${dCC}" fill="${PAL_SLEP['Costa Central']}" fill-opacity="0.03" stroke="${PAL_SLEP['Costa Central']}" stroke-width="1.8" stroke-opacity="0.8"/>
${aten}${plenos}${rotulos}
</g>
${leyenda}
<text x="20" y="38" font-family="${FUENTE_TITULO}" font-size="21" font-weight="bold" fill="${COLOR_INSTITUCIONAL}">Mapa de establecimientos educacionales · Región de Valparaíso</text>
<text x="20" y="64" font-family="${FUENTE_TEXTO}" font-size="12.5" fill="#5d5650">${escXML(linea2)}</text>
<line x1="0" y1="${SVG_CAB - 2}" x2="${W}" y2="${SVG_CAB - 2}" stroke="${COLOR_INSTITUCIONAL}" stroke-width="2"/>
<text x="20" y="${SVG_CAB + HM + 18}" font-family="${FUENTE_TEXTO}" font-size="9.5" fill="#9a9488">${escXML(pie1)}</text>
<text x="20" y="${SVG_CAB + HM + 32}" font-family="${FUENTE_TEXTO}" font-size="9.5" fill="#9a9488">${escXML(pie2)}</text>
<text x="20" y="${SVG_CAB + HM + 46}" font-family="${FUENTE_TEXTO}" font-size="9.5" fill="#9a9488">${escXML(pie3)}</text>
</svg>`;
}
function exportarSVG() {
  descargarBlob(new Blob([construirSVG()], { type: 'image/svg+xml;charset=utf-8' }),
                nombreArchivo('mapa_establecimientos_rv', 'svg'));
}

/* ---- XLSX ---- */
let promSheetJS = null;
function cargarSheetJS() {
  if (window.XLSX) return Promise.resolve();
  if (!promSheetJS) promSheetJS = new Promise((res, rej) => {
    const sc = document.createElement('script');
    sc.src = 'assets/vendor/xlsx.full.min.js';
    sc.onload = res;
    sc.onerror = () => { promSheetJS = null; rej(new Error('no se pudo cargar SheetJS local')); };
    document.head.appendChild(sc);
  });
  return promSheetJS;
}
// universo exportable: pins + sin-geo, filtrados con los MISMOS predicados del mapa
function filasExportables() {
  if (!verPines()) return [];   // "Jardines infantiles": el directorio no viaja
  const activos = hayFiltrosActivos();
  const todos = S.ee.map(f => f.properties).concat(S.sinGeo);
  const sel = todos.filter(p => !activos || cumple(p, null));
  sel.sort((a, b) => a.com.localeCompare(b.com, 'es') || a.n.localeCompare(b.n, 'es'));
  return sel;
}
/* Unidades de parvulos exportables, con los MISMOS predicados de la pantalla.
   Van a una hoja aparte y no a la de establecimientos: no tienen RBD, ni niveles
   del directorio, ni serie 2016-2025, de modo que mezclarlas dejaria 395 filas
   con la mayor parte de las columnas del directorio vacias. Dos hojas dicen la
   verdad; una hoja con huecos
   parece un dato faltante. */
function filasParvularia() {
  if (!verParvularia()) return [];
  const activos = hayFiltrosActivos();
  const sel = featuresParvularia()
    .map(f => f.properties)
    .filter(pr => !activos || cumpleParv(pr));
  sel.sort((a, b) => a.comuna.localeCompare(b.comuna, 'es') ||
                     a.nombre.localeCompare(b.nombre, 'es'));
  return sel;
}
function textoEnsExport(p) {
  if (!p.ens.length) return TEXTO_SIN_OFERTA_CORTO;
  const base = p.ens.map(e => fraseModalidad(e, true)).join(' · ');
  return esOfertaHistorica(p) ? `Impartía hasta ${p.ensa}: ${base}` : base;
}
function construirLibro() {
  const anios = S.meta.ventana_anios;
  const filas = filasExportables();
  const cab = ['RBD', 'Nombre', 'Comuna', 'Provincia', 'Dependencia', 'SLEP',
               'Macrogrupos', 'Tipos de enseñanza y niveles', 'Coordenadas',
               'Matrícula actual (2025)', 'Promedio últimos 10 años',
               'Máximo últimos 10 años', 'Mínimo últimos 10 años', ...anios];
  const aoa = [cab];
  for (const p of filas) {
    aoa.push([+p.rbd, titulo(p.n), titulo(p.com), p.prov,
      ETIQUETA_DEP[p.dep] || p.dep, p.slep || null,
      p.mg.length ? p.mg.join(' · ') : null, textoEnsExport(p), p.geo || null,
      p.ma, p.pr, p.mx, p.mn,
      ...p.s.map(v => esNum(v) ? v : null)]);
  }
  const ws = XLSX.utils.aoa_to_sheet(aoa);
  ws['!cols'] = [{ wch: 7 }, { wch: 44 }, { wch: 16 }, { wch: 22 }, { wch: 30 }, { wch: 14 },
                 { wch: 40 }, { wch: 70 }, { wch: 15 }, { wch: 20 }, { wch: 20 }, { wch: 20 },
                 { wch: 20 }, ...anios.map(() => ({ wch: 8 }))];
  const wb = XLSX.utils.book_new();
  if (filas.length) XLSX.utils.book_append_sheet(wb, ws, 'Establecimientos');

  // Hoja de jardines: columnas propias, porque el dato parvulario no tiene RBD
  // ni la serie del directorio. El desglose por nivel se escribe tal cual viene
  // (null = el origen no lo trae), sin convertir ausencia en cero.
  const parv = filasParvularia();
  if (parv.length) {
    // La Procedencia viaja junto al Sostenedor (porte S34-E4): el archivo se
    // lee sin el mapa delante y la atribucion no puede quedar sobreentendida.
    const cabP = ['Nombre', 'Comuna', 'Provincia', 'Sostenedor', 'Procedencia',
                  'Matrícula total (2025)', 'Sala cuna', 'Medio', 'Transición'];
    const aoaP = [cabP];
    for (const pr of parv) {
      aoaP.push([titulo(pr.nombre), titulo(pr.comuna), provDeComuna(pr.comuna) || null,
        etiquetaParvularia(pr), pr.slep_procedencia || null,
        esNum(pr.matricula_total) ? pr.matricula_total : null,
        esNum(pr.mat_sala_cuna) ? pr.mat_sala_cuna : null,
        esNum(pr.mat_medio) ? pr.mat_medio : null,
        esNum(pr.mat_transicion) ? pr.mat_transicion : null]);
    }
    const wsP = XLSX.utils.aoa_to_sheet(aoaP);
    wsP['!cols'] = [{ wch: 44 }, { wch: 16 }, { wch: 22 }, { wch: 40 }, { wch: 18 },
                    { wch: 20 }, { wch: 12 }, { wch: 12 }, { wch: 12 }];
    XLSX.utils.book_append_sheet(wb, wsP, 'Jardines infantiles');
  }
  // Un libro sin ninguna hoja de datos no es un archivo valido: si el filtro
  // dejo fuera a los dos universos, viaja la cabecera del directorio vacia y la
  // hoja de notas explica por que.
  if (!wb.SheetNames.length) XLSX.utils.book_append_sheet(wb, ws, 'Establecimientos');

  // hoja de notas: el archivo debe poder leerse SOLO (sin el mapa al lado)
  const nGeo = filas.filter(p => !p.geo).length;
  const notas = [
    ['Producto', S.meta.producto],
    ['Exportado', fechaLocalISO()],
    ['Filtro aplicado', descripcionFiltro() || 'Sin filtro: universo completo'],
    ['Establecimientos incluidos', filas.length + parv.length],
    ['— del directorio (hoja Establecimientos)', filas.length],
    ['    · con coordenadas (pins del mapa)', nGeo],
    ['    · sin coordenadas', filas.length - nGeo],
    ['— unidades de párvulos (hoja Jardines infantiles)', parv.length],
    ['Dos hojas', 'Las unidades de párvulos de JUNJI e INTEGRA no tienen RBD, niveles del directorio ni serie anual, así que van en su propia hoja con sus propias columnas.'],
    ['Universo parvulario', 'Solo unidades cuyo sostenedor no está en el directorio: los jardines de un establecimiento con RBD ya están en la fila de ese establecimiento.'],
    // Los tres valores de Procedencia y el anio del insumo, declarados donde el
    // archivo se lee solo (porte S34-E4). El anio sale del dato, no se escribe
    // a mano; solo se emite si la hoja de jardines viajo en este libro.
    ...(parv.length ? (() => {
      const a = anioInsumoParvularia();
      const anioTxt = a ? String(a) : 'no derivable del dato';
      return [['Procedencia (jardines)',
        `Los tres valores de la columna Procedencia: declarada_${a || '<año>'} = la fuente del insumo declara al Servicio Local como sostenedor; derivada_comuna = sostenedor municipal al que se le atribuye el Servicio Local que opera en su comuna, cuya entrada en operación es posterior al corte del insumo; sin_dato = sin Servicio Local atribuido (figura la glosa de su tipo). Año del insumo: ${anioTxt}.`]];
    })() : []),
    ['Serie anual', 'Celda vacía = año sin registro de matrícula en la fuente (nunca 0).'],
    ['Dependencia', S.meta.criterios_calculo.dependencia],
    ['Matrícula', S.meta.criterios_calculo.matricula],
    ['Mínimo', S.meta.criterios_calculo.min_10],
    ['Oferta educativa', S.meta.criterios_calculo.niveles],
    ['Fuentes', `${S.meta.fuentes.directorio} ${S.meta.fuentes.matricula}`]
  ];
  const wsN = XLSX.utils.aoa_to_sheet(notas);
  wsN['!cols'] = [{ wch: 34 }, { wch: 120 }];
  XLSX.utils.book_append_sheet(wb, wsN, 'Notas');
  return wb;
}
async function exportarXLSX() {
  await cargarSheetJS();
  const out = XLSX.write(construirLibro(), { bookType: 'xlsx', type: 'array' });
  descargarBlob(new Blob([out], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }),
                nombreArchivo('establecimientos_rv', 'xlsx'));
}
function iniciarExportacion() {
  const bSvg = document.getElementById('btn-svg');
  const bXlsx = document.getElementById('btn-xlsx');
  bSvg.addEventListener('click', () => {
    try { exportarSVG(); }
    catch (e) { alert(`No se pudo generar el SVG: ${e.message}`); }
  });
  bXlsx.addEventListener('click', async () => {
    bXlsx.disabled = true;
    try { await exportarXLSX(); }
    catch (e) { alert(`No se pudo generar el XLSX: ${e.message}`); }
    finally { bXlsx.disabled = false; }
  });
}

/* ---- Arranque ---- */

/* ---- Indicador de carga de capa diferida ---------------------------------
   Lo usa la capa de parvularia mientras su fetch esta en vuelo. Vive aqui, y no
   dentro de la capa que lo usa, porque el bloque que lo alojaba no viaja a esta
   variante del sitio. Movido, no reescrito. */
function indicadorCargaCapa(mostrar) {
  let el = document.getElementById('capa-cargando');
  if (mostrar) {
    if (!el) {
      el = document.createElement('div');
      el.id = 'capa-cargando'; el.className = 'capa-cargando';
      el.textContent = 'Cargando capa…';
      document.getElementById('mapa').appendChild(el);
    }
  } else if (el) el.remove();
}

/* =============================================================================
   CAPA DE EDUCACION PARVULARIA (pendiente N, fase 1) — jardines y salas cuna.
   - Sin toggle propio (sesion 22): la enciende y apaga el filtro "Tipo de EE"
     de la barra superior. Carga diferida y cacheada: con "Todos" por defecto,
     se descarga al montar.
   - SIN pane propio y con el MISMO renderer Canvas que los pines (sesion 22).
     Medido en la Duda 17: dos canvas superpuestos no se reparten el puntero, el
     de arriba captura el mousemove en toda su superficie haya o no figura
     debajo, y el de abajo pierde el hover entero. Un pane propio ordenaba el z
     al precio de dejar sin hover a una de las dos capas. Con renderer unico el
     orden lo da el orden de dibujo y la prueba de impacto es una sola.
   - UNIVERSO RECORTADO (sesion 22): la capa publica solo los tipos 5 a 8, que
     son sostenedores ausentes del directorio (JUNJI, JUNJI VTF, INTEGRA). Los
     tipos 1 a 4 se excluyen porque son las unidades de parvulos de EE que YA
     tienen pin: medido, los 934 caen a menos de 25 m de un pin del directorio y
     coinciden en nombre. Dibujarlos era el mismo establecimiento dos veces, con
     dos simbolos, y era exactamente lo que rompia la regla del titular.
   - MISMO SIMBOLO que los pines (sesion 22). El simbolo codifica SOSTENEDOR y
     nada mas: un EE del SLEP Costa Central se ve igual sea jardin, escuela o
     liceo. El nivel que imparte vive en el filtro y en la tarjeta, no en la
     marca. Por eso desaparecen el anillo hueco, el radio menor y el punteado
     de VTF que la sesion 21 habia introducido.
   - Fuente: docs/data/parvularia_r5.geojson, agregado por unidad a partir de
     los catastros oficiales de educacion parvularia; sin ninguna fila de persona.
   ============================================================================= */
const PARVULARIA_URL = 'data/parvularia_r5.geojson';
/* ---- COLOR E IDENTIDAD (sesion 21) -----------------------------------------
   Todo lo de abajo esta apoyado en dos mediciones sobre los datos publicados,
   no en supuestos:
   (a) `origen` particiona la capa sin celdas mixtas: origen 1 = tipos 1 a 4
       (registro MINEDUC), origen 2 = tipos 5 y 6 (JUNJI), origen 3 = tipos 7 y
       8 (INTEGRA). Por eso la leyenda puede agrupar por origen sin inventar
       una categoria que el dato no tenga.
   (b) comuna -> SLEP es funcion en establecimientos.geojson: de 36 comunas,
       23 tienen exactamente un SLEP y NINGUNA tiene dos. Las 103 unidades de
       tipo 4 resuelven su SLEP por comuna al 100%.
   Consecuencia (b): el tipo 4 deja de pintarse con el azul de Costa Central en
   toda la region. Cada unidad recibe el color del SLEP que la administra, que
   es el mismo criterio que ya usan los pines del directorio (colorDe).
   Para los tipos 1 a 3 se REUSAN las constantes de PAL_DEP: una unidad
   parvularia municipal y una escuela municipal comparten color, que es lo que
   hace legible la capa junto a los pines. */
const COLOR_JUNJI   = '#9E3F1E';   // terracota; sin cambio
// Sesion 22: el vino oscuro #5E1A33 separaba bien de JUNJI pero quedaba a 2,8 de
// L* del azul marino de Costa Central, y a tamano de pin la luminancia es lo que
// discrimina: se leian como el mismo color. El magenta separa 24,0 de L* contra
// Costa Central, mantiene 20,9 de distancia minima contra toda la paleta (el mas
// cercano es el violeta de particular pagado) y conserva 4,71 de contraste
// contra el fondo de pagina. Medido, no elegido de vista.
const COLOR_INTEGRA = '#C2185B';
// Gris de ADMINISTRADOR NO IDENTIFICADO. Distinto del atenuado de los filtros
// (#c9c4bb): aquel dice "no cumple el filtro", este dice "no sabemos de quien
// es". Solo lo usan los VTF fuera de las cuatro comunas del Area de Monitoreo.
const COLOR_SIN_ADMIN = '#7d7a74';
/* "JUNJI VTF" nombra la VIA DE FINANCIAMIENTO (transferencia de fondos), no al
   sostenedor: quien lo tiene a su cargo es un tercero. Desde el porte S34-E4 el
   dato trae a ese tercero en el campo slep_sostenedor, y slep_procedencia
   declara de donde sale cada atribucion. El VTF cuyo sostenedor es un Servicio
   Local toma el color de ese Servicio; queda en gris el de sostenedor distinto
   de un Servicio Local o sin dato en la fuente. Nada se deriva de la comuna. */
const COLOR_PARVULARIA = {
  // Los tipos 1 a 4 NO entran: son unidades de EE que ya tienen pin propio.
  5: COLOR_JUNJI,                             // JUNJI Administracion Directa
  6: COLOR_SIN_ADMIN,                         // JUNJI VTF sin SLEP sostenedor en la fuente
  7: COLOR_INTEGRA,                           // INTEGRA Administracion Directa
  8: COLOR_INTEGRA                            // INTEGRA CAD
};
/* Etiquetas de despliegue. La capa NO son escuelas: son unidades educativas de
   parvulos, y llamarlas "Escuela municipal" era aplicarles la taxonomia del
   directorio escolar. La glosa cruda (`tipo_glosa`) se conserva en el dato y no
   se toca; lo que cambia es como se la nombra en pantalla.
   INTEGRA CAD (3 casos) se fusiona con INTEGRA: la distincion no sostiene una
   categoria propia. JUNJI VTF (174 casos) SI la sostiene, porque la administra
   un tercero con fondos JUNJI y es la figura que se traspasa a los SLEP. */
const ETIQUETA_PARVULARIA = {
  5: 'JUNJI',
  6: 'JUNJI VTF',
  7: 'INTEGRA',
  8: 'INTEGRA'
};
/* Tabla comuna -> SLEP derivada de los pines ya cargados (S.ee). Se construye
   una sola vez, la primera vez que se necesita: la capa parvularia carga
   diferida y S.ee siempre esta poblado antes de que se pueda encender. */
function provDeComuna(com) {
  if (!S.provPorComuna) {
    S.provPorComuna = new Map();
    for (const f of S.ee) {
      const p = f.properties;
      if (p.prov && !S.provPorComuna.has(p.com)) S.provPorComuna.set(p.com, p.prov);
    }
  }
  return S.provPorComuna.get(com) || null;
}
/* SLEP SOSTENEDOR de un VTF, LEIDO DEL DATO (porte S34-E4 desde el proyecto
   interno). Antes esta funcion derivaba el SLEP de la comuna con una tabla
   comuna -> SLEP construida desde los pines (slepDeComuna, eliminada junto con
   su tabla: este era su unico llamador, medido antes de borrarla). Esa
   derivacion convertia un atributo geografico en uno administrativo y atribuia
   un Servicio Local a VTF de sostenedor privado. Ahora el valor viene del campo
   slep_sostenedor del geojson; sin dato, null. */
function slepDelVtf(p) {
  return p.tipo_estab === 6 ? (p.slep_sostenedor || null) : null;
}
/* Anio del corte del insumo parvulario, LEIDO DEL DATO: el sufijo de
   `declarada_<anio>` que trae slep_procedencia. Fuente unica del anio para la
   frase de procedencia de la tarjeta y la hoja Notas; no se escribe a mano. */
function anioInsumoParvularia() {
  if (S.parvularia.anioInsumo !== undefined) return S.parvularia.anioInsumo;
  let anio = null;
  const feats = (S.parvularia.cache && S.parvularia.cache.features) || [];
  for (const f of feats) {
    const m = /^declarada_(\d{4})$/.exec(f.properties.slep_procedencia || '');
    if (m) { anio = +m[1]; break; }
  }
  S.parvularia.anioInsumo = anio;
  return anio;
}
function colorParvularia(p) {
  const s = slepDelVtf(p);
  if (s) return PAL_SLEP[s] || COLOR_SIN_ADMIN;
  return COLOR_PARVULARIA[p.tipo_estab] || '#888';
}
function etiquetaParvularia(p) {
  const s = slepDelVtf(p);
  if (s) return `${ETIQUETA_SLEP} ${s}`;
  return ETIQUETA_PARVULARIA[p.tipo_estab] || p.tipo_glosa;
}
// Mismo radio que un pin, con el mismo bono de tamano para el SLEP protagonista
// que aplica radioDe: la marca no distingue jardin de escuela.
function radioParvularia(p) {
  return radioBase(S.zoomActual) + (p && slepDelVtf(p) === 'Costa Central' ? 1 : 0);
}

// IDENTICO al estilo de crearCapa: disco pleno con aro blanco. Cualquier
// divergencia aqui reintroduce la diferencia de simbolo que la sesion 22
// elimino.
function estiloParvularia(f) {
  const p = f.properties;
  return { radius: radioParvularia(p), color: '#ffffff', weight: 1.5,
           fillColor: colorParvularia(p), fillOpacity: 0.92 };
}

function popupParvularia(p) {
  // El desglose por nivel se OMITE linea a linea: cuando el dato no existe (null:
  // un origen que no lo trae) y tambien cuando es cero (la unidad no imparte ese
  // nivel). Nunca se muestra "NA" ni un cero. No se oculta nada al hacerlo: la
  // cifra de arriba es el total, y la guardia del script 39 garantiza que los tres
  // niveles suman ese total, asi que con total > 0 siempre queda al menos una linea.
  // Hoy los tres origenes traen el desglose (NIVEL2, 0 NA medido), pero la omision
  // no es rama muerta: el dia que un origen deje de traerlo, el popup calla.
  const nivel = (et, v) => (v == null || v === 0 ? '' :
    `<div>${et}</div><div class="val">${fmt(v)}</div>`);
  const filas = nivel('Sala cuna', p.mat_sala_cuna) +
                nivel('Medio', p.mat_medio) +
                nivel('Transición', p.mat_transicion);
  // Procedencia derivada: la atribucion del Servicio Local no viene de la
  // fuente sino de la comuna, y la tarjeta lo declara (porte S34-E4). El anio
  // sale del dato (anioInsumoParvularia), nunca escrito a mano; si no fuera
  // derivable, la frase omite el parentesis en vez de inventarlo.
  let procedencia = '';
  if (p.slep_procedencia === 'derivada_comuna') {
    const a = anioInsumoParvularia();
    procedencia = `<div class="pp-nota">Se le atribuye el Servicio Local que ` +
      `opera en su comuna. El último dato de sostenedor disponible` +
      `${a ? ` (${a})` : ''} es anterior al inicio de funciones de ese Servicio.</div>`;
  }
  return `<div class="pp pp-parv">
    <div class="pp-nombre">${titulo(p.nombre)}</div>
    <div class="pp-sub">${etiquetaParvularia(p)} · ${titulo(p.comuna)}</div>
    <div class="pp-parv-total">
      <span class="pp-parv-cifra">${fmt(p.matricula_total)}</span>
      <span class="pp-parv-etq">niños matriculados (2025)</span>
    </div>
    ${filas ? `<div class="pp-tabla-cifras">${filas}</div>` : ''}
    ${procedencia}
  </div>`;
}

// La capa no construye leyenda (invariante de la sesion 21: la leyenda es unica
// y vive en construirLeyenda). Lo unico que aporta al panel es la procedencia
// del dato, que no es leyenda, y va bajo la leyenda unica.
function notaParvularia(visible) {
  const nota = document.getElementById('parvularia-nota');
  if (!nota) return;
  nota.textContent = !visible ? '' :
    'Educación parvularia 2025 (JUNJI e INTEGRA), región continental. Solo ' +
    'unidades cuyo sostenedor no está en el directorio de establecimientos: los ' +
    'jardines de un EE con RBD ya se muestran en el pin de ese establecimiento. ' +
    'Los VTF llevan el color del Servicio Local que la fuente declara como su ' +
    'sostenedor (matrícula parvularia 2025); los de sostenedor municipal cuya ' +
    'comuna ya cuenta con un Servicio Local en operación llevan el de ese ' +
    'Servicio, con la procedencia declarada en la tarjeta y en la exportación. ' +
    'Los demás van en gris.';
}

async function activarParvularia(encender) {
  S.parvularia.activa = encender;
  notaParvularia(encender);

  if (!encender) {
    if (S.parvularia.capa) { S.mapa.removeLayer(S.parvularia.capa); S.parvularia.capa = null; }
    return;
  }
  let data = S.parvularia.cache;
  if (!data) {
    indicadorCargaCapa(true);
    try {
      data = await fetch(PARVULARIA_URL).then(r => r.json());
      S.parvularia.cache = data;
    }
    catch (e) {
      indicadorCargaCapa(false);
      const nota = document.getElementById('parvularia-nota');
      if (nota) nota.textContent = 'No se pudo cargar la capa de educación parvularia.';
      S.parvularia.activa = false;
      return;
    }
    indicadorCargaCapa(false);
  }
  // El total del universo parvulario se fija una vez y sobrevive a que la capa
  // se apague: es denominador, no cuenta de lo visible.
  if (S.parvularia.total == null) {
    S.parvularia.total = data.features.filter(f => f.properties.tipo_estab >= 5).length;
  }
  // si el usuario apago mientras cargaba, no montar
  if (!S.parvularia.activa) return;
  S.parvularia.capa = L.geoJSON(data, {
    renderer: S.renderer,
    // Fuera los tipos 1 a 4: son unidades de parvulos de EE que ya tienen pin.
    filter: f => f.properties.tipo_estab >= 5,
    // OJO: las capas que devuelve pointToLayer NO heredan `renderer` del
    // L.geoJSON: hay que pasarlo en las opciones del propio circleMarker o el
    // marcador se dibuja en un canvas nuevo, que es exactamente la situacion
    // que la Duda 17 midio como causa de la perdida del hover.
    pointToLayer: (f, latlng) => L.circleMarker(latlng, Object.assign(
      { renderer: S.renderer }, estiloParvularia(f))),
    // Hover con el MISMO contrato que los pines del directorio (crearCapa):
    // tooltip pegajoso arriba, engrosado del trazo y tween de radio. El
    // renderer ya se creo con TOLERANCIA_HOVER, asi que el area sensible
    // existia; lo que faltaba era enlazarla.
    onEachFeature: (f, capa) => {
      const p = f.properties;
      capa.bindTooltip(
        `<div class="tt-nombre">${titulo(p.nombre)}</div>
         <div class="tt-sub">${titulo(p.comuna)} · ${etiquetaParvularia(p)}</div>
         <div class="tt-ens">${fmt(p.matricula_total)} niños matriculados (2025)</div>`,
        { className: 'tt-ee', direction: 'top', offset: [0, -8], sticky: true });
      capa.on('mouseover', () => {
        capa.setStyle({ weight: 2 });
        animarRadio(capa, radioParvularia(p) + HOVER_EXTRA);
      });
      capa.on('mouseout', () => {
        capa.setStyle({ weight: 1.5 });
        animarRadio(capa, radioParvularia(p));
      });
      capa.bindPopup(() => popupParvularia(p), { maxWidth: 320, autoPanPadding: [30, 30] });
    }
  }).addTo(S.mapa);
  aplicarFiltros();
}

function iniciarParvularia() {
  // renderer: el MISMO de los pines (S.renderer), no uno propio. Ver la Duda 17
  // en la cabecera de este bloque.
  S.parvularia = { activa: false, cache: null, capa: null, total: null };
  const sel = document.getElementById('f-tipoee');
  if (sel) sel.addEventListener('change', () => aplicarTipoEE(sel.value));
  notaParvularia(false);
  aplicarTipoEE(S.tipoEE);
}

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
  S.frontera = frontera; S.fronteraRegion = fronteraRegion; S.rotulos = rotulosComuna;

  const montar = () => {
    try {
    const cont = document.getElementById('mapa');
    if (cont.clientWidth === 0 || cont.clientHeight === 0) { setTimeout(montar, 120); return; }
    const mapa = L.map('mapa', { preferCanvas: true, zoomControl: true });
    S.mapa = mapa;                           // referencia para la exportacion SVG
    // pane de rotulos BAJO los pins (overlayPane=400): los pins nunca quedan tapados
    mapa.createPane('rotulos');
    mapa.getPane('rotulos').style.zIndex = 340;
    // mascara SOBRE el tile y sus rotulos (340), BAJO la frontera (370) y los
    // pins (400): vela el fuera de region sin velar lo que dibujamos nosotros.
    mapa.createPane('mascara');
    mapa.getPane('mascara').style.zIndex = 350;
    mapa.getPane('mascara').style.pointerEvents = 'none';
    // frontera bajo los pins, sobre los rotulos
    mapa.createPane('frontera');
    mapa.getPane('frontera').style.zIndex = 370;
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png?key=cb1_2esd_1_4e3da3997ce4873fcc7b2ded', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · © <a href="https://carto.com/">CARTO</a>',
      subdomains: 'abcd', maxZoom: 19
    }).addTo(mapa);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png?key=cb1_2esd_1_4e3da3997ce4873fcc7b2ded', {
      subdomains: 'abcd', maxZoom: 19, pane: 'rotulos', opacity: 0.9
    }).addTo(mapa);

    // Mascara invertida: vela todo lo que NO es Region de Valparaiso. Va ANTES
    // de las fronteras (mismo orden que el zIndex de los panes). Renderer SVG
    // explicito: el mapa corre en preferCanvas, y la regla de anillos-como-huecos
    // es nativa en SVG (fill-rule) sin depender del path de Canvas.
    L.geoJSON(geojsonMascara(fronteraRegion), {
      pane: 'mascara', renderer: L.svg(),
      style: { stroke: false, fillColor: COLOR_MASCARA, fillOpacity: OPACIDAD_MASCARA },
      interactive: false
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

    // UNICO renderer Canvas del mapa de puntos: lo comparten los pines del
    // directorio y la capa parvularia (Duda 17). No crear otro.
    const renderer = L.canvas({ tolerance: TOLERANCIA_HOVER });  // area sensible ampliada
    S.renderer = renderer;
    S.zoomActual = 10;
    crearCapa(mapa, renderer);
    // encuadre por defecto: Costa Central protagonista con contexto regional
    // inmediato. Guardado en S como UNICA fuente de verdad (limpiarFiltros vuelve aqui).
    S.boundsDefecto = capaFrontera.getBounds().pad(0.15);
    mapa.fitBounds(S.boundsDefecto);

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
      // La capa de parvularia sigue el mismo escalado por zoom que los pines,
      // porque comparte su simbolo (ver estiloParvularia): si no lo siguiera,
      // el mismo disco quedaria de dos portes distintos a cada cambio de zoom.
      if (S.parvularia && S.parvularia.capa) {
        S.parvularia.capa.eachLayer(m =>
          m.setStyle({ radius: radioParvularia(m.feature && m.feature.properties) }));
      }
    };
    mapa.on('zoomend', aplicarRadios);
    aplicarRadios();
    ajustarRotulos();
    new ResizeObserver(() => mapa.invalidateSize()).observe(cont);
    iniciarFiltros();           // requiere marcadores ya creados
    iniciarParvularia();        // capa de parvularia (carga diferida, independiente)
    iniciarExportacion();
    window.__M = { mapa, S, F, aplicarFiltros, limpiarFiltros,
                   construirSVG, construirLibro, filasExportables,
                   cargarSheetJS, descripcionFiltro, nombreArchivo,
                   aplicarTipoEE, filasParvularia, featuresParvularia,
                   totalUniverso };   // handle de inspeccion (sin estado persistente)
    } catch (e) { window.__errMontar = e.message + ' @ ' + (e.stack || '').split('\n')[1]; throw e; }
  };
  montar();

  document.getElementById('contador').textContent = textoContador(S.total);
  construirLeyenda();
}

iniciar().catch(err => {
  document.getElementById('mapa').innerHTML =
    `<p style="padding:20px;font-size:14px">Error cargando los datos del mapa: ${err.message}</p>`;
});
