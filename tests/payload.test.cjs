const test = require('node:test');
const assert = require('node:assert/strict');
const P = require('../lib/Payload.js');
function drop(data, text = '', urls = []) {
    return {formats: Object.keys(data), hasText: !!text, text, hasUrls: !!urls.length, urls,
        getDataAsArrayBuffer: f => Uint8Array.from(data[f]).buffer};
}
const bytes = s => [...Buffer.from(s)];
test('preserves bytes including NUL and non-UTF8 in custom MIME', () => {
    const p = P.capture(drop({'application/x-example': [0, 255, 128, 10]}), 1024);
    assert.deepEqual([...new Uint8Array(p.mime['application/x-example'])], [0, 255, 128, 10]);
});
test('keeps file references encoded and titles plain', () => {
    const url = 'file:///tmp/%24%28touch%20oops%29%0A%3Cb%3E.png';
    const p = P.capture(drop({'text/uri-list': bytes(url)}, '', [url]), 1024);
    assert.equal(p.paths[0], '/tmp/$(touch oops)\n<b>.png');
    assert.equal(p.title, '$(touch oops)\n<b>.png');
    assert.equal(p.kind, 'file');
});
test('rejects remote file hosts and malformed URI encodings', () => {
    for (const url of ['file://server/a', 'file:///tmp/%XX', 'file:///tmp/%00']) {
        assert.throws(() => P.capture(drop({'text/uri-list': bytes(url)}, '', [url]), 1024));
    }
});
test('excludes cut flags and process-local transfer formats', () => {
    for (const f of ['application/x-kde-cutselection', 'application/vnd.portal.filetransfer',
        'application/x-qt-image', 'application/x-moz-file', '__proto__']) assert.equal(P.portable(f), false);
});
test('enforces per-item and remaining-session budgets atomically', () => {
    assert.throws(() => P.capture(drop({'text/plain': bytes('hello')}), 4), /too large/);
    assert.throws(() => P.capture(drop({'application/octet-stream': new Uint8Array(P.maxItemBytes + 1)}), Infinity), /too large/);
    assert.throws(() => P.capture(drop({}), 1024), /no portable/);
});
test('image preview encoding round trips bytes', () => {
    for (let n = 0; n < 100; n++) {
        const b = Uint8Array.from({length: n}, (_, i) => (i * 37) % 256);
        assert.equal(P.base64(b.buffer), Buffer.from(b).toString('base64'));
    }
});
test('URL previews do not treat credentials or script schemes as domains', () => {
    assert.equal(P.webDomain('https://www.example.org/a'), 'example.org');
    assert.equal(P.webDomain('https://user:secret@example.org'), '');
    assert.equal(P.webDomain('javascript:alert(1)'), '');
});
