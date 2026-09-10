import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';

// Install Playwright outside the plugin, then set OSHELF_PLAYWRIGHT to its module.
const {chromium} = await import(process.env.OSHELF_PLAYWRIGHT || 'playwright');
const root = fileURLToPath(new URL('..', import.meta.url));
const site = resolve(root, 'site');
const server = createServer(async (req,res) => {
  try {
    const path = resolve(site, '.' + new URL(req.url, 'http://localhost').pathname.replace(/\/$/, '/index.html'));
    if (!path.startsWith(site + '/')) { res.writeHead(403).end(); return; }
    const data = await readFile(path);
    res.setHeader('Content-Type', {'.html':'text/html','.css':'text/css','.js':'text/javascript','.svg':'image/svg+xml','.png':'image/png'}[extname(path)] || 'application/octet-stream');
    res.end(data);
  } catch { res.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
const base = `http://127.0.0.1:${server.address().port}`;
let browser;
try {
  browser = await chromium.launch({executablePath: process.env.CHROMIUM || '/usr/bin/chromium', headless:true});
  const page = await browser.newPage({viewport:{width:1440,height:1100},deviceScaleFactor:1});
  const errors = []; page.on('pageerror', e => errors.push(e.message));
  await page.goto(base);
  assert.equal(await page.locator('body').evaluate(el => getComputedStyle(el).backgroundColor),'rgb(0, 0, 0)');
  await page.waitForFunction(() => window.oshelfDemo && window.oshelfDemo.duration > 0);
  await page.evaluate(() => window.oshelfDemo.pause());
  await page.evaluate(() => window.oshelfDemo.seek(0));
  assert.equal(await page.locator('#shelf').evaluate(el => el.classList.contains('closed')),true,'Shelf starts closed');
  assert.equal(await page.locator('.os-card').count(),0);
  const cursorCheck = await page.evaluate(() => {
    window.oshelfDemo.seek(1.3);
    const match = document.querySelector('#cursor').style.transform.match(/translate\(([-\d.]+)px, ([-\d.]+)px\)/);
    const tile = document.querySelector('[data-park="cover"]');
    const scale = parseFloat(getComputedStyle(document.querySelector('#stage')).getPropertyValue('--stage-scale'));
    const desktop = document.querySelector('#desktop').getBoundingClientRect();
    const rect = tile.getBoundingClientRect();
    const x = (rect.left + rect.width / 2 - desktop.left) / scale, y = (rect.top + rect.height / 2 - desktop.top) / scale;
    return {near: !!match && Math.hypot(Number(match[1]) - x, Number(match[2]) - y) < 6, ghost: document.querySelector('#ghost').classList.contains('visible'), label: document.querySelector('#ghost').textContent.trim()};
  });
  assert.equal(cursorCheck.near,true,'Cursor reaches the dragged tile');
  assert.equal(cursorCheck.ghost,true,'Drag ghost is visible while dragging');
  assert.equal(cursorCheck.label,'cover.png','Ghost shows the dragged file');
  await page.evaluate(() => window.oshelfDemo.seek(5.2));
  assert.equal(await page.locator('.os-card').count(),2,'Two cards parked mid-demo');
  assert.equal(await page.locator('.delivered-item').count(),0);
  assert.equal(await page.locator('#desktop').getAttribute('data-workspace'),'1');
  assert.equal(await page.locator('#shelf').evaluate(el => el.classList.contains('closed')),false,'Shelf opens during the drag');
  await page.evaluate(() => window.oshelfDemo.seek(8));
  assert.equal(await page.locator('.delivered-item').count(),1,'First item delivered');
  assert.equal(await page.locator('#desktop').getAttribute('data-workspace'),'2','Demo switches workspace');
  await page.evaluate(() => window.oshelfDemo.seek(window.oshelfDemo.duration));
  assert.equal(await page.locator('.delivered-item').count(),2,'Both items delivered');
  assert.equal(await page.locator('.os-card').count(),2,'Cards stay on the shelf');
  await page.evaluate(() => window.oshelfDemo.replay());
  await page.waitForFunction(() => document.querySelectorAll('.delivered-item').length === 2, null, {timeout: 20000});
  await page.evaluate(() => window.oshelfDemo.replay());
  await page.waitForTimeout(1000);
  await page.evaluate(() => window.oshelfDemo.pause());
  const frozen = await page.evaluate(() => window.oshelfDemo.elapsed);
  await page.waitForTimeout(700);
  assert.equal(await page.evaluate(() => window.oshelfDemo.elapsed),frozen,'Pause stops the timeline');
  await page.evaluate(() => { const scrub = document.querySelector('#scrub'); scrub.value = '500'; scrub.dispatchEvent(new Event('input',{bubbles:true})); });
  assert.ok(Math.abs(await page.evaluate(() => window.oshelfDemo.elapsed) - 5.1) < 0.2,'Scrubber seeks the timeline');
  await page.reload();
  await page.evaluate(() => document.querySelector('#stage').scrollIntoView({block:'start', behavior:'instant'}));
  await page.waitForFunction(() => window.oshelfDemo && window.oshelfDemo.elapsed > 0.1, null, {timeout: 5000});
  for (const width of [320,390,700,768,1024,1440]) {
    await page.setViewportSize({width,height:900}); await page.reload();
    await page.waitForFunction(() => window.oshelfDemo && window.oshelfDemo.duration > 0);
    await page.evaluate(() => { window.oshelfDemo.pause(); window.oshelfDemo.seek(5.2); });
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'No horizontal page overflow at ' + width + ': ' + await page.evaluate(() => [...document.querySelectorAll('body *')].filter(el => el.getBoundingClientRect().right > innerWidth + 1).map(el => el.className).join(', ')));
    const geometry = await page.evaluate(() => {
      const outer = document.querySelector('#desktop').getBoundingClientRect(), inner = document.querySelector('#shelf').getBoundingClientRect();
      return inner.left >= outer.left - 1 && inner.right <= outer.right + 1 && inner.top >= outer.top - 1 && inner.bottom <= outer.bottom + 1;
    });
    assert.equal(geometry, true, `Shelf fits at ${width}`);
    if (width === 390 && process.env.OSHELF_SITE_CAPTURE) await page.screenshot({path:'/tmp/oshelf-site-mobile.png',fullPage:true});
  }
  await page.setViewportSize({width:1440,height:1000}); await page.reload();
  await page.waitForFunction(() => window.oshelfDemo && window.oshelfDemo.duration > 0);
  await page.evaluate(() => { window.oshelfDemo.pause(); window.oshelfDemo.seek(5.2); });
  if (process.env.OSHELF_SITE_CAPTURE) {
    await page.screenshot({path:'/tmp/oshelf-site-desktop.png',fullPage:true});
    await page.locator('#desktop').screenshot({path:join(site,'demo.png')});
    await page.setViewportSize({width:1200,height:630});
    await page.evaluate(() => { document.documentElement.style.scrollBehavior='auto'; document.querySelector('.nav').style.height='75px'; document.querySelector('.hero').style.paddingTop='35px'; document.querySelector('.hero').style.paddingBottom='35px'; window.scrollTo({top:0,behavior:'instant'}); });
    await page.screenshot({path:join(site,'social.png')});
  }
  await page.setViewportSize({width:1440,height:1000}); await page.emulateMedia({reducedMotion:'reduce'}); await page.reload();
  await page.waitForFunction(() => window.oshelfDemo && window.oshelfDemo.duration > 0);
  await page.evaluate(() => { window.oshelfDemo.pause(); window.oshelfDemo.seek(5.2); });
  assert.equal(await page.locator('.oshelf').evaluate(el => getComputedStyle(el).transitionDuration),'0s');
  assert.deepEqual(errors,[]);
  console.log('PASS website: scripted Omarchy desktop animation, timeline seek, playback controls, responsive geometry, reduced motion, no JS errors');
} finally { if (browser) await browser.close(); server.close(); }
