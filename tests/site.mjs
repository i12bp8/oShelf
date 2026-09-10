import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve, extname, join} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
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
  await page.locator('[data-park="image"]').click();
  assert.equal(await page.locator('.demo-card').count(),1);
  await page.locator('[data-workspace="2"]').click();
  await page.locator('.demo-card button').click();
  assert.equal(await page.locator('.delivered-item').count(),1);
  assert.equal(await page.locator('.demo-card').count(),1,'Pickup must retain the card');
  await page.locator('#collapse').click();
  assert.equal(await page.locator('#shelf').evaluate(el => el.inert),true);
  await page.locator('#edge-handle').click();
  for (const edge of ['left','bottom','right']) {
    await page.locator(`button[data-edge="${edge}"]`).click();
    await page.waitForTimeout(350);
    const fits = await page.evaluate(() => {
      const outer = document.querySelector('#desktop').getBoundingClientRect(), inner = document.querySelector('#shelf').getBoundingClientRect();
      return inner.left >= outer.left && inner.right <= outer.right && inner.top >= outer.top && inner.bottom <= outer.bottom;
    });
    assert.ok(fits, edge + ' shelf fits desktop');
  }
  await page.locator('#reset').click();
  await page.locator('.sample').first().dragTo(page.locator('#shelf'));
  assert.equal(await page.locator('.demo-card').count(),1,'Drag into shelf');
  await page.locator('[data-workspace="2"]').click();
  await page.locator('.demo-card').dragTo(page.locator('#destination'));
  assert.equal(await page.locator('.delivered-item').count(),1,'Drag out of shelf');
  await page.locator('#reset').click();
  await page.locator('#tour').click();
  await page.waitForFunction(() => document.querySelectorAll('.delivered-item').length === 2);
  await page.locator('#reset').click();
  for (const id of ['image','folder','link']) await page.locator(`[data-park="${id}"]`).click();
  if (process.env.OSHELF_SITE_CAPTURE) {
    await page.screenshot({path:'/tmp/oshelf-site-desktop.png',fullPage:true});
    await page.locator('#desktop').screenshot({path:join(site,'demo.png')});
    await page.setViewportSize({width:1200,height:630});
    await page.evaluate(() => { document.documentElement.style.scrollBehavior='auto'; document.querySelector('.nav').style.height='75px'; document.querySelector('.hero').style.paddingTop='35px'; document.querySelector('.hero').style.paddingBottom='35px'; window.scrollTo({top:0,behavior:'instant'}); });
    await page.screenshot({path:join(site,'social.png')});
  }
  for (const width of [390,768]) {
    await page.setViewportSize({width,height:900}); await page.reload();
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'No horizontal page overflow at ' + width + ': ' + await page.evaluate(() => [...document.querySelectorAll('body *')].filter(el => el.getBoundingClientRect().right > innerWidth + 1).map(el => el.className).join(', ')));
    for (const edge of ['left','bottom','right']) {
      await page.locator(`button[data-edge="${edge}"]`).click();
      await page.locator('[data-park="link"]').click();
      await page.locator('.demo-card button').click();
      assert.equal(await page.locator('.delivered-item').count(),1);
      await page.locator('#reset').click();
    }
    if (width === 390 && process.env.OSHELF_SITE_CAPTURE) await page.screenshot({path:'/tmp/oshelf-site-mobile.png',fullPage:true});
  }
  await page.emulateMedia({reducedMotion:'reduce'});
  assert.equal(await page.locator('.shelf').evaluate(el => getComputedStyle(el).transitionDuration),'0s');
  assert.deepEqual(errors,[]);
  console.log('PASS website: native browser DnD, click flow, all placements, tour, mobile/tablet, reduced motion, no JS errors');
} finally { if (browser) await browser.close(); server.close(); }
