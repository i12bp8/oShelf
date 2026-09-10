const samples = [
  {id:'image', type:'IMAGE', icon:'▧', title:'cover.png', detail:'Project artwork', art:true},
  {id:'folder', type:'FOLDER', icon:'▱', title:'weekend-project', detail:'Folder reference'},
  {id:'link', type:'LINK', icon:'◎', title:'omarchy.org', detail:'https://omarchy.org/'},
  {id:'text', type:'TEXT', icon:'≡', title:'git switch -c next-idea', detail:'Text snippet'},
];
const $ = id => document.getElementById(id);
let parked = [], delivered = [], timers = [], playing = false;
function stopTour() { timers.forEach(clearTimeout); timers = []; playing = false; $('tour').textContent = '▶ Watch demo'; }
function announce(text) { $('demo-status').textContent = text; }
function openShelf(open = true) { $('shelf').classList.toggle('closed', !open); $('shelf').inert = !open; $('edge-handle').setAttribute('aria-expanded', String(open)); }
function setWorkspace(next) {
  $('source-window').hidden = next !== 1; $('destination').hidden = next !== 2;
  document.querySelectorAll('[data-workspace]').forEach(b => b.setAttribute('aria-pressed', String(Number(b.dataset.workspace) === next)));
  announce(next === 2 ? parked.length ? '03 / Deliver. Drag a card to Project, or press its arrow.' : 'Your shelf is empty. Switch to Files to park an item.' : '01 / Collect. Drag a sample onto the shelf, or press +.');
}
function render() {
  $('count').textContent = String(parked.length).padStart(2,'0');
  $('empty').hidden = parked.length > 0; $('clear').disabled = parked.length === 0;
  $('shelf-cards').replaceChildren(...parked.map(id => {
    const item = samples.find(s => s.id === id), card = document.createElement('article');
    card.className = 'demo-card'; card.draggable = true; card.dataset.id = id;
    if (item.art) { const art = document.createElement('div'); art.className = 'card-art'; art.setAttribute('aria-hidden','true'); card.append(art); }
    for (const [className, text] of [['card-type',item.type],['card-title',item.title],['card-detail',item.detail]]) { const span = document.createElement('span'); span.className = className; span.textContent = text; card.append(span); }
    const button = document.createElement('button'); button.textContent = '↗'; button.setAttribute('aria-label','Pick up ' + item.title); button.addEventListener('click',() => { stopTour(); deliver(id); }); card.append(button);
    card.addEventListener('dragstart', e => { stopTour(); e.dataTransfer.setData('text/plain','shelf:' + id); e.dataTransfer.effectAllowed = 'copy'; });
    return card;
  }));
  document.querySelectorAll('[data-park]').forEach(button => { button.disabled = parked.includes(button.dataset.park); button.textContent = button.disabled ? '✓' : '+'; });
  $('delivered').replaceChildren(...delivered.map(id => { const span = document.createElement('span'); span.className = 'delivered-item'; span.textContent = '✓ ' + samples.find(s => s.id === id).title; return span; }));
}
function park(id) {
  if (!samples.some(s => s.id === id)) return;
  if (!parked.includes(id)) parked.push(id);
  openShelf(); render(); announce('02 / Switch. Select “02 Project” above. Your items stay on the shelf.');
}
function deliver(id) {
  if (!parked.includes(id)) return;
  setWorkspace(2); if (!delivered.includes(id)) delivered.push(id); render();
  announce('Delivered. The card stays on your shelf for another trip.');
}
for (const item of samples) {
  const row = document.createElement('div'); row.className = 'sample'; row.draggable = true;
  const icon = document.createElement('span'); icon.className = 'sample-icon'; icon.setAttribute('aria-hidden','true');
  const paths = {image:'M3 3h18v18H3z M3 16l5-5 5 5 4-4 4 4 M16 7h.01',folder:'M3 6h6l2 3h10v11H3z',link:'M10 13a4 4 0 0 0 6 0l4-4a4 4 0 0 0-6-6l-2 2 M14 11a4 4 0 0 0-6 0l-4 4a4 4 0 0 0 6 6l2-2',text:'M4 5h16 M4 10h12 M4 15h16 M4 20h9'};
  const svg = document.createElementNS('http://www.w3.org/2000/svg','svg'); svg.setAttribute('viewBox','0 0 24 24');
  const path = document.createElementNS('http://www.w3.org/2000/svg','path'); path.setAttribute('d',paths[item.id]); svg.append(path); icon.append(svg);
  const copy = document.createElement('div'); copy.className = 'sample-copy';
  const title = document.createElement('strong'); title.textContent = item.title;
  const detail = document.createElement('small'); detail.textContent = item.type.toLowerCase(); copy.append(title,detail);
  const button = document.createElement('button'); button.textContent = '+'; button.dataset.park = item.id; button.setAttribute('aria-label','Park ' + item.title); button.addEventListener('click', () => { stopTour(); park(item.id); });
  row.append(icon,copy,button); row.addEventListener('dragstart', e => { stopTour(); e.dataTransfer.setData('text/plain','sample:' + item.id); e.dataTransfer.effectAllowed = 'copy'; openShelf(); }); $('samples').append(row);
}
for (const element of [$('shelf'),$('destination')]) {
  element.addEventListener('dragover', e => { e.preventDefault(); e.dataTransfer.dropEffect = 'copy'; element.classList.add('dragover'); });
  element.addEventListener('dragleave', e => { if (!element.contains(e.relatedTarget)) element.classList.remove('dragover'); });
  element.addEventListener('drop', e => {
    e.preventDefault(); e.stopPropagation(); stopTour(); element.classList.remove('dragover');
    const [source,id] = e.dataTransfer.getData('text/plain').split(':');
    if (element.id === 'shelf' && source === 'sample') park(id);
    else if (element.id === 'destination' && source === 'shelf') deliver(id);
    else announce('Use the sample items to try this demo. Your own files stay on your computer.');
  });
}
$('desktop').addEventListener('dragover', e => e.preventDefault());
$('desktop').addEventListener('drop', e => e.preventDefault());
document.addEventListener('dragend',() => document.querySelectorAll('.dragover').forEach(el => el.classList.remove('dragover')));
document.querySelectorAll('button[data-edge]').forEach(button => button.addEventListener('click', () => {
  stopTour(); $('desktop').dataset.edge = button.dataset.edge;
  document.querySelectorAll('button[data-edge]').forEach(b => b.setAttribute('aria-pressed',String(b === button))); openShelf();
}));
document.querySelectorAll('[data-workspace]').forEach(button => button.addEventListener('click', () => { stopTour(); setWorkspace(Number(button.dataset.workspace)); }));
$('collapse').addEventListener('click',() => { stopTour(); openShelf(false); $('edge-handle').focus(); });
$('edge-handle').addEventListener('click',() => { stopTour(); openShelf($('shelf').classList.contains('closed')); });
$('clear').addEventListener('click',() => { stopTour(); parked = []; render(); announce('Shelf cleared. Park something new.'); });
function reset() {
  stopTour(); parked = []; delivered = [];
  $('desktop').dataset.edge = 'right';
  document.querySelectorAll('button[data-edge]').forEach(b => b.setAttribute('aria-pressed',String(b.dataset.edge === 'right')));
  document.querySelectorAll('.dragover').forEach(el => el.classList.remove('dragover'));
  setWorkspace(1); openShelf(); render();
}
$('reset').addEventListener('click',reset);
$('tour').addEventListener('click',() => {
  if (playing) { stopTour(); return; }
  reset(); playing = true; $('tour').textContent = '■ Stop demo';
  [[350,() => park('image')],[1400,() => park('link')],[2700,() => setWorkspace(2)],[3900,() => deliver('image')],[5000,() => { deliver('link'); stopTour(); }]].forEach(([delay,fn]) => timers.push(setTimeout(fn,delay)));
});
document.addEventListener('visibilitychange',() => { if (document.hidden) stopTour(); });
$('copy-install').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText($('install-code').textContent); $('copy-install').textContent = 'Copied ✓'; }
  catch { const selection = window.getSelection(), range = document.createRange(); range.selectNodeContents($('install-code')); selection.removeAllRanges(); selection.addRange(range); $('copy-install').textContent = 'Select & copy'; }
  setTimeout(() => { $('copy-install').textContent = 'Copy commands'; },2500);
});
reset();
