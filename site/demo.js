const $ = id => document.getElementById(id);
const desktop = $('desktop'), stage = $('stage'), shelf = $('shelf'), edge = $('edge-handle'), cursorEl = $('cursor'), ghostEl = $('ghost');

const artwork = {
  cover: '<svg viewBox="0 0 320 220" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="220" fill="#161616"/><circle cx="236" cy="58" r="24" fill="#333"/><path d="M0 152 72 92l46 40 54-62 74 82 74-42v110H0z" fill="#242424"/><path d="M0 184 84 132l58 42 62-52 116 70v28H0z" fill="#0e0e0e"/></svg>',
  sunset: '<svg viewBox="0 0 320 220" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="220" fill="#0b0b0b"/><circle cx="160" cy="98" r="52" fill="#202020"/><circle cx="160" cy="98" r="34" fill="#3d3d3d"/><path d="M0 128h320M0 146h320M0 164h320M0 182h320" stroke="#1d1d1d" stroke-width="6"/></svg>'
};
const samples = [
  {id: 'cover', kind: 'image', title: 'cover.png', detail: 'Image · 84 KB', file: 'cover.png', art: 'cover'},
  {id: 'sunset', kind: 'image', title: 'sunset.png', detail: 'Image · 128 KB', file: 'sunset.png', art: 'sunset'},
  {id: 'project', kind: 'folder', title: 'weekend-project', detail: 'Folder reference', file: 'weekend-project'},
  {id: 'link', kind: 'url', title: 'omarchy.org', detail: 'https://omarchy.org/', file: 'omarchy.org'},
  {id: 'notes', kind: 'text', title: 'git switch -c next-idea', detail: 'Text snippet', file: 'next-idea.txt'},
  {id: 'plan', kind: 'file', title: 'launch-plan.md', detail: 'File reference', file: 'launch-plan.md'}
];
const byId = id => samples.find(s => s.id === id);
const tileIcon = kind => kind === 'url' ? 'i-link' : kind === 'image' ? 'i-pictures' : kind === 'folder' ? 'i-folder' : kind === 'text' ? 'i-text' : 'i-file';
const cardIcon = kind => kind === 'url' ? 'i-url' : kind === 'image' ? 'i-image' : kind === 'folder' ? 'i-folder' : kind === 'text' ? 'i-text' : 'i-file';

function media(kind, art) {
  const wrap = document.createElement('span');
  if (art) { wrap.className = 'thumb'; wrap.innerHTML = artwork[art]; }
  else { wrap.className = 'ficon'; wrap.innerHTML = `<svg class="icon"><use href="#${tileIcon(kind)}"/></svg>`; }
  return wrap;
}
function renderSamples() {
  $('samples').replaceChildren(...samples.map(sample => {
    const tile = document.createElement('div');
    tile.className = 'nw-tile'; tile.dataset.park = sample.id;
    tile.append(media(sample.kind, sample.art));
    const name = document.createElement('strong'); name.textContent = sample.file; tile.append(name);
    return tile;
  }));
}
function renderCards(parked) {
  $('shelf-cards').replaceChildren(...parked.map(id => {
    const sample = byId(id);
    const card = document.createElement('article');
    card.className = 'os-card'; card.dataset.id = id; card.dataset.kind = sample.kind;
    if (sample.art) { const thumb = document.createElement('span'); thumb.className = 'os-card-thumb'; thumb.innerHTML = artwork[sample.art]; card.append(thumb); }
    const icon = document.createElement('span'); icon.className = 'os-card-icon'; icon.innerHTML = `<svg class="icon"><use href="#${cardIcon(sample.kind)}"/></svg>`; card.append(icon);
    const kind = document.createElement('span'); kind.className = 'os-card-kind'; kind.textContent = sample.kind === 'url' ? 'LINK' : sample.kind.toUpperCase(); card.append(kind);
    const title = document.createElement('strong'); title.className = 'os-card-title'; title.textContent = sample.title; card.append(title);
    const detail = document.createElement('span'); detail.className = 'os-card-detail'; detail.textContent = sample.detail; card.append(detail);
    return card;
  }));
  $('os-meta').textContent = parked.length ? `ON YOUR SHELF  ·  ${parked.length}` : 'READY WHEN YOU ARE';
  $('empty').hidden = parked.length > 0;
  edge.classList.toggle('has-items', parked.length > 0);
}
function renderDelivered(delivered) {
  const grid = $('delivered');
  grid.querySelectorAll('.nw-tile').forEach(el => el.remove());
  for (const id of delivered) {
    const sample = byId(id);
    const tile = document.createElement('div'); tile.className = 'nw-tile delivered-item'; tile.dataset.id = id;
    tile.append(media(sample.kind, sample.art));
    const name = document.createElement('strong'); name.textContent = sample.file; tile.append(name);
    grid.append(tile);
  }
  grid.classList.toggle('empty', delivered.length === 0);
}
function openShelf(open) {
  shelf.classList.toggle('closed', !open);
  edge.classList.toggle('hidden', open);
}
function setWorkspace(next) {
  desktop.dataset.workspace = String(next);
  document.querySelectorAll('.ws').forEach(el => { el.hidden = Number(el.dataset.ws) !== next; });
  document.querySelectorAll('.obar-workspaces [data-workspace]').forEach(el => { if (el.dataset.workspace === '1' || el.dataset.workspace === '2') el.setAttribute('aria-pressed', String(Number(el.dataset.workspace) === next)); });
}

/* Timeline */
const T = {pickCover: 1.0, openShelf: 1.9, parkCover: 2.6, pickLink: 3.3, parkLink: 4.8, switchWs: 5.6, pickCard1: 6.3, deliverCover: 7.5, pickCard2: 8.1, deliverLink: 9.2, end: 10.2};
const DURATION = T.end;
const K = {};
function designPoint(el, clampEl) {
  const scale = parseFloat(getComputedStyle(stage).getPropertyValue('--stage-scale')) || 1;
  const base = desktop.getBoundingClientRect();
  let rect = el.getBoundingClientRect();
  if (clampEl) {
    const bounds = clampEl.getBoundingClientRect();
    const left = Math.max(rect.left, bounds.left), right = Math.min(rect.right, bounds.right);
    const top = Math.max(rect.top, bounds.top), bottom = Math.min(rect.bottom, bounds.bottom);
    if (right > left && bottom > top) rect = {left, right, top, bottom};
  }
  return {x: (rect.left + rect.right) / 2 / scale - base.left / scale, y: (rect.top + rect.bottom) / 2 / scale - base.top / scale};
}
function buildTimeline() {
  renderCards(['cover', 'link']);
  const list = $('shelf-cards');
  K.cover = designPoint(document.querySelector('[data-park="cover"]'));
  K.link = designPoint(document.querySelector('[data-park="link"]'));
  K.ws2 = designPoint(document.querySelector('.obar-workspaces [data-workspace="2"]'));
  K.shelf = designPoint(shelf);
  K.shelfDrop = {x: K.shelf.x, y: K.shelf.y - 30};
  K.card1 = designPoint(document.querySelector('.os-card[data-id="cover"]'), list);
  K.card2 = designPoint(document.querySelector('.os-card[data-id="link"]'), list);
  const workspace2 = document.querySelector('.ws[data-ws="2"]');
  workspace2.hidden = false;
  K.dest = designPoint($('delivered'));
  workspace2.hidden = true;
  KEYS = KEY_DEFS.map(key => key.ref ? {t: key.t, ...K[key.ref]} : key);
  renderCards([]);
}
let KEYS = [];
const KEY_DEFS = [
  {t: 0, x: 860, y: 500},
  {t: T.pickCover, x: 0, y: 0, ref: 'cover'},
  {t: T.pickCover + 0.35, x: 0, y: 0, ref: 'cover'},
  {t: T.parkCover, x: 0, y: 0, ref: 'shelfDrop'},
  {t: T.pickLink, x: 0, y: 0, ref: 'link'},
  {t: T.pickLink + 0.35, x: 0, y: 0, ref: 'link'},
  {t: T.parkLink, x: 0, y: 0, ref: 'shelfDrop'},
  {t: T.switchWs, x: 0, y: 0, ref: 'ws2'},
  {t: T.switchWs + 0.3, x: 0, y: 0, ref: 'ws2'},
  {t: T.pickCard1, x: 0, y: 0, ref: 'card1'},
  {t: T.pickCard1 + 0.35, x: 0, y: 0, ref: 'card1'},
  {t: T.deliverCover, x: 0, y: 0, ref: 'dest'},
  {t: T.pickCard2, x: 0, y: 0, ref: 'card2'},
  {t: T.pickCard2 + 0.35, x: 0, y: 0, ref: 'card2'},
  {t: T.deliverLink, x: 0, y: 0, ref: 'dest'},
  {t: T.end, x: 1420, y: 840}
];
const easeInOut = p => p < .5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;
function cursorAt(t) {
  if (t <= KEYS[0].t) return KEYS[0];
  for (let i = 0; i < KEYS.length - 1; i++) {
    const a = KEYS[i], b = KEYS[i + 1];
    if (t <= b.t) { const e = easeInOut((t - a.t) / Math.max(.0001, b.t - a.t)); return {x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e}; }
  }
  return KEYS[KEYS.length - 1];
}
function dragAt(t) {
  if (t >= T.pickCover && t < T.parkCover) return {id: 'cover', from: 'tile'};
  if (t >= T.pickLink && t < T.parkLink) return {id: 'link', from: 'tile'};
  if (t >= T.pickCard1 && t < T.deliverCover) return {id: 'cover', from: 'card'};
  if (t >= T.pickCard2 && t < T.deliverLink) return {id: 'link', from: 'card'};
  return null;
}
function statusAt(t) {
  if (t < T.pickCover) return '01 / Collect. Drag a file toward the edge.';
  if (t < T.parkCover) return 'Dragging cover.png to the shelf…';
  if (t < T.pickLink) return 'Parked. The card waits until you pick it up.';
  if (t < T.parkLink) return 'Parking the link…';
  if (t < T.switchWs) return '02 / Switch. Two items parked, one workspace away.';
  if (t < T.pickCard1) return 'The shelf follows you across workspaces.';
  if (t < T.deliverCover) return '03 / Pick up. Delivering the image…';
  if (t < T.pickCard2) return 'Delivered. The card stays for another trip.';
  if (t < T.deliverLink) return 'Delivering the link…';
  return 'Park. Switch. Pick up. That is the whole loop.';
}
const state = {parked: [], delivered: [], ws: 1, open: true, dragKey: ''};
function renderDrag(drag) {
  const key = drag ? drag.id + ':' + drag.from : '';
  if (key !== state.dragKey) {
    state.dragKey = key;
    document.querySelectorAll('.dragging').forEach(el => el.classList.remove('dragging'));
    if (drag) {
      const sample = byId(drag.id);
      ghostEl.replaceChildren(media(sample.kind, sample.art));
      const name = document.createElement('strong'); name.textContent = sample.file; ghostEl.append(name);
      const source = drag.from === 'tile' ? document.querySelector(`[data-park="${drag.id}"]`) : document.querySelector(`.os-card[data-id="${drag.id}"]`);
      if (source) source.classList.add('dragging');
    }
  }
  ghostEl.classList.toggle('visible', !!drag);
}
function renderAt(t) {
  const parked = [];
  if (t >= T.parkCover) parked.push('cover');
  if (t >= T.parkLink) parked.push('link');
  const delivered = [];
  if (t >= T.deliverCover) delivered.push('cover');
  if (t >= T.deliverLink) delivered.push('link');
  if (parked.join() !== state.parked.join()) { state.parked = parked; renderCards(parked); }
  if (delivered.join() !== state.delivered.join()) { state.delivered = delivered; renderDelivered(delivered); }
  const ws = t >= T.switchWs ? 2 : 1;
  if (ws !== state.ws) { state.ws = ws; setWorkspace(ws); }
  const open = t >= T.openShelf;
  if (open !== state.open) { state.open = open; openShelf(open); }
  desktop.style.setProperty('--dwell', !open && t >= T.openShelf - 0.4 ? Math.min(1, (t - (T.openShelf - 0.4)) / 0.4) : 0);
  const drag = dragAt(t);
  renderDrag(drag);
  const point = cursorAt(t);
  cursorEl.style.transform = `translate(${point.x}px, ${point.y}px)`;
  ghostEl.style.transform = `translate(${point.x + 16}px, ${point.y + 12}px)`;
  document.querySelector('.obar-workspaces [data-workspace="2"]').classList.toggle('pressed', Math.abs(t - T.switchWs) < 0.14);
  $('os-message').textContent = drag ? 'Release to park' : 'Temporary by design';
  $('demo-status').textContent = statusAt(t);
  const pct = Math.round(t / DURATION * 1000);
  $('scrub').value = String(pct);
  $('scrub').style.setProperty('--progress', String(pct / 10));
  $('time').textContent = formatTime(t) + ' / ' + formatTime(DURATION);
}
const formatTime = seconds => Math.floor(seconds / 60) + ':' + String(Math.floor(seconds % 60)).padStart(2, '0');

/* Playback */
let elapsed = 0, playing = false, raf = 0, lastTs = 0, started = false;
function updatePlay() { $('play').textContent = playing ? '❚❚' : '▶'; $('play').setAttribute('aria-label', playing ? 'Pause demo' : 'Play demo'); }
function play() {
  if (playing) return;
  if (elapsed >= DURATION - 0.001) elapsed = 0;
  playing = true; lastTs = performance.now(); updatePlay();
  raf = requestAnimationFrame(loop);
}
function pause() { playing = false; cancelAnimationFrame(raf); updatePlay(); }
function loop(now) {
  elapsed = Math.min(DURATION, elapsed + Math.min(0.1, (now - lastTs) / 1000));
  lastTs = now;
  renderAt(elapsed);
  if (elapsed >= DURATION) { playing = false; updatePlay(); return; }
  raf = requestAnimationFrame(loop);
}
function seek(t) { elapsed = Math.max(0, Math.min(DURATION, t)); renderAt(elapsed); }
function replay() { pause(); seek(0); play(); }
$('play').addEventListener('click', () => playing ? pause() : play());
$('replay').addEventListener('click', replay);
$('scrub').addEventListener('input', e => { pause(); seek(Number(e.target.value) / 1000 * DURATION); });
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
new IntersectionObserver((entries, observer) => {
  if (started || reducedMotion.matches) return;
  if (entries.some(entry => entry.isIntersecting && entry.intersectionRatio >= 0.3)) { started = true; observer.disconnect(); play(); }
}, {threshold: [0.3]}).observe(stage);

/* Clock, stage fit, install copy */
function tick() {
  const now = new Date();
  $('obar-clock').textContent = now.toLocaleDateString('en-US', {weekday: 'long'}) + ' ' + String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
}
function fit() { stage.style.setProperty('--stage-scale', String(stage.clientWidth / 1920)); }
window.addEventListener('resize', fit);
$('copy-install').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText($('install-code').textContent); $('copy-install').textContent = 'Copied ✓'; }
  catch { const selection = window.getSelection(), range = document.createRange(); range.selectNodeContents($('install-code')); selection.removeAllRanges(); selection.addRange(range); $('copy-install').textContent = 'Select & copy'; }
  setTimeout(() => { $('copy-install').textContent = 'Copy commands'; }, 2500);
});

window.oshelfDemo = {play, pause, replay, seek, duration: DURATION, get elapsed() { return elapsed; }, get playing() { return playing; }};
renderSamples();
fit();
buildTimeline();
tick(); setInterval(tick, 30000);
renderAt(0);
updatePlay();
if (reducedMotion.matches) seek(DURATION);
