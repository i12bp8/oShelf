// Explicitly opt-in: opens test windows and moves the pointer on a single-monitor desktop.
import assert from 'node:assert/strict';
import {spawn, execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {setTimeout as delay} from 'node:timers/promises';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const binaries = process.argv[2] || process.env.OSHELF_TEST_BIN;
assert.ok(binaries, 'Set OSHELF_TEST_BIN to the directory containing transfer and pointer');
const run = (cmd, args) => execFileSync(cmd, args, {encoding: 'utf8', timeout: 10000});
const monitors = JSON.parse(run('hyprctl', ['-j', 'monitors']));
assert.equal(monitors.length, 1, 'Live driver currently requires one monitor');
const monitor = monitors[0];
assert.equal(monitor.transform, 0, 'Live driver requires an unrotated monitor');
const width = Math.round(monitor.width / monitor.scale);
const height = Math.round(monitor.height / monitor.scale);
const originalWorkspace = JSON.parse(run('hyprctl', ['-j', 'activeworkspace'])).id;
const usedWorkspaces = new Set(JSON.parse(run('hyprctl', ['-j', 'workspaces'])).map(w => w.id));
let testWorkspace = 9051;
while (usedWorkspaces.has(testWorkspace)) testWorkspace++;
const originalWindow = JSON.parse(run('hyprctl', ['-j', 'activewindow']));
const originalPointer = JSON.parse(run('hyprctl', ['-j', 'cursorpos']));
const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'oshelf-live-'));
fs.symlinkSync(root, path.join(directory, 'Shelf'));
fs.symlinkSync('/usr/share/omarchy/shell/Commons', path.join(directory, 'Commons'));
fs.writeFileSync(path.join(directory, 'shell.qml'), `
import QtQuick
import Quickshell
import Quickshell.Io
import "file:${root}/components" as Shelf
ShellRoot {
    Shelf.ShelfStore { id: store }
    Shelf.ShelfWindow { id: shelf; store: store }
    function cards(item) {
        var found = [];
        if (item.objectName === "oshelf-card") {
            var point = item.mapToItem(shelf.contentItem, 0, 0);
            found.push({id: item.entry.id, x: shelf.screen.width - shelf.width + point.x, y: shelf.screen.height - shelf.height + point.y, width: item.width, height: item.height});
        }
        if (item.children) for (var child of item.children) found = found.concat(cards(child));
        return found;
    }
    IpcHandler {
        target: "test"
        function state(): string { return JSON.stringify({expanded: shelf.expanded, engaged: shelf.engaged, count: store.items.length, message: store.message,
            dragging: store.draggingId, cards: cards(shelf.contentItem), ids: store.items.map(i => i.id), kinds: store.items.map(i => i.kind), missing: store.items.some(i => i.missing)}); }
        function clear(): void { store.clear(); }
        function reveal(): void { shelf.reveal(); }
    }
}`);
const ipc = method => run('quickshell', ['ipc', '-p', directory, 'call', '--', 'test', method]);
const state = () => JSON.parse(ipc('state'));
let shell, source, shellOutput = '', sourceOutput = '';
async function until(check, message) {
    for (let i = 0; i < 60; i++) {
        try { if (check()) return; } catch {}
        await delay(100);
    }
    throw new Error(message + '\n' + sourceOutput + '\n' + shellOutput);
}
function pointer(lines) {
    const file = path.join(directory, 'pointer.txt');
    fs.writeFileSync(file, `extent ${width} ${height}\n${lines}\n`);
    run(path.join(binaries, 'pointer'), [file]);
}
async function stop(process) {
    if (!process || process.exitCode !== null) return;
    process.kill('SIGTERM');
    await Promise.race([new Promise(resolve => process.once('exit', resolve)), delay(1500)]);
    if (process.exitCode === null) process.kill('SIGKILL');
}
try {
    shell = spawn('quickshell', ['-p', directory]);
    for (const stream of [shell.stdout, shell.stderr]) stream.on('data', b => { shellOutput += b; });
    await until(() => state().count === 0, 'Shelf failed to load');
    const file = path.join(directory, 'reference $(literal) 雪.txt');
    fs.writeFileSync(file, 'Reference test');
    for (const [name, args, kind] of [
        ['text', [], 'text'], ['folder', [directory], 'folder'], ['file', [file], 'file'],
        ['bundle', [file, directory], 'file'], ['image', ['--image'], 'image'], ['bad-image', ['--bad-image'], 'image'], ['url', ['--url'], 'url']]) {
        if (process.argv[3] === '--lifecycle' && name !== 'url') continue;
        if (process.argv[3] === '--images' && !name.includes('image')) continue;
        ipc('clear');
        sourceOutput = '';
        source = spawn(path.join(binaries, 'transfer'), args);
        source.stdout.on('data', b => { sourceOutput += b; });
        source.stderr.on('data', b => { sourceOutput += b; });
        let client;
        await until(() => {
            client = JSON.parse(run('hyprctl', ['-j', 'clients'])).find(w => w.pid === source.pid);
            return client && client.at[0] >= 0;
        }, 'Test source not visible');
        await delay(500);
        client = JSON.parse(run('hyprctl', ['-j', 'clients'])).find(w => w.pid === source.pid);
        const x = Math.round(Math.min(client.at[0] + client.size[0] / 3, width - 440));
        const y = Math.round(height / 2);
        pointer(`move ${x - 60} ${y - 30}\nwait 150\nmove ${x} ${y}\nwait 200\ndown\nwait 100\nmove ${x + 24} ${y}\nwait 200\nmove ${width - 3} ${y}\nwait 500\nmove ${width - 190} ${y}\nwait 200\nup\nwait 200`);
        await until(() => state().count === 1 && state().kinds[0] === kind, `${name} capture failed at ${x},${y}: ${JSON.stringify(state())}`);
        if (name === 'text') {
            run('hyprctl', ['dispatch', `hl.dsp.focus({workspace="${testWorkspace}"})`]);
            await delay(250);
            assert.equal(state().count, 1, 'Workspace changes must preserve contents');
            run('hyprctl', ['dispatch', `hl.dsp.focus({workspace="${originalWorkspace}"})`]);
            await delay(300);
            console.log('PASS workspace switch: contents retained');
        }
        ipc('reveal');
        await delay(300);
        if (name === 'image') {
            pointer(`move ${x} ${y}\nwait 100`);
            ipc('reveal'); await delay(300);
            run('grim', ['-g', `${width - 392},${Math.round(height / 2 - 220)} 392x440`, path.join(root, 'docs', 'shelf.png')]);
        }
        pointer(`move ${width - 220} ${y}\nwait 150\ndown\nwait 100\nmove ${width - 250} ${y}\nwait 150\nmove ${width - 270} ${y}\nwait 200\nmove ${x} ${y}\nwait 300\nup\nwait 200`);
        await until(() => sourceOutput.includes('RECEIVED text=1 binary=1') && sourceOutput.includes('EXACT 1'), `${name} round trip failed`);
        assert.equal(state().count, 1, 'Pickup must retain the card');
        await until(() => state().dragging === '', 'Native drag state must finish');
        if (name === 'file') {
            fs.renameSync(file, file + '.moved'); ipc('reveal');
            await until(() => state().missing, 'Missing reference was not detected');
            fs.renameSync(file + '.moved', file);
        }
        console.log(`PASS ${name}: native round trip; original binary bytes preserved`);
        if (name === 'url') {
            // Add a second real URL offer, then reorder the two native drag sources.
            pointer(`move ${x - 60} ${y - 30}\nwait 150\nmove ${x} ${y}\nwait 150\ndown\nwait 100\nmove ${x + 24} ${y}\nwait 150\nmove ${width - 3} ${y}\nwait 400\nmove ${width - 190} ${y - 100}\nwait 150\nup\nwait 250`);
            await until(() => state().count === 2, 'Second URL failed');
            ipc('reveal'); await delay(300);
            const before = state().ids;
            const cards = state().cards.sort((a, b) => a.y - b.y);
            const from = cards[1], to = cards[0];
            const cx = Math.round(from.x + 100), cy = Math.round(from.y + from.height / 2);
            pointer(`move ${cx} ${cy}\nwait 150\ndown\nmove ${cx + 20} ${cy}\nwait 100\nmove ${cx + 40} ${cy}\nwait 150\nmove ${cx} ${Math.round(to.y + to.height / 2)}\nwait 250\nup\nwait 250`);
            await until(() => state().ids[0] === before[1] && state().dragging === '', 'Native reorder failed');
            console.log('PASS native reorder: stable card identity');
            ipc('reveal'); await delay(300);
            const card = state().cards[0];
            const dx = Math.round(card.x + 100), dy = Math.round(card.y + card.height / 2);
            const dragFile = path.join(directory, 'held-drag.txt');
            fs.writeFileSync(dragFile, `extent ${width} ${height}\nmove ${dx} ${dy}\nwait 150\ndown\nmove ${dx + 20} ${dy}\nwait 100\nmove ${dx + 40} ${dy}\nwait 1800\nup\n`);
            let held = spawn(path.join(binaries, 'pointer'), [dragFile]);
            await until(() => state().dragging !== '', 'Cancellation drag did not start');
            run('wtype', ['-k', 'Escape']);
            await new Promise(resolve => held.once('exit', resolve));
            assert.equal(state().dragging, ''); assert.equal(state().count, 2);
            console.log('PASS Escape cancellation: contents retained');
            ipc('reveal'); await delay(300);
            held = spawn(path.join(binaries, 'pointer'), [dragFile]);
            await until(() => state().dragging !== '', 'Reload drag did not start');
            fs.appendFileSync(path.join(directory, 'shell.qml'), '\n// Exercise reload while a native drag owns a card.\n');
            await new Promise(resolve => held.once('exit', resolve));
            await until(() => state().count === 0, 'Reload failed to reset the session');
            assert.ok(!/FATAL|crashed/.test(shellOutput), shellOutput);
            console.log('PASS native-drag reload: no crash');
        }
        await stop(source); source = null;
    }
    ipc('clear'); assert.equal(state().count, 0);
    assert.ok(!/OSHELF_PRIVATE_BAD_IMAGE|T1NIRUxGX1BSSVZBVEVfQkFEX0lNQUdF|TypeError|ReferenceError|Unable to assign|drag must be active/.test(shellOutput), shellOutput);
} catch (error) {
    try { console.error(state()); } catch {}
    run("grim", ["/tmp/oshelf-live-failure.png"]);
    console.error(run("hyprctl", ["-j", "activewindow"]));
    throw error;
} finally {
    await stop(source); await stop(shell);
    run('hyprctl', ['dispatch', `hl.dsp.focus({workspace="${originalWorkspace}"})`]);
    if (originalWindow.address) run('hyprctl', ['dispatch', `hl.dsp.focus({window="address:${originalWindow.address}"})`]);
    pointer(`move ${originalPointer.x} ${originalPointer.y}\nwait 100`);
    fs.rmSync(directory, {recursive: true, force: true});
}
