import {mkdtempSync, readFileSync, symlinkSync, writeFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';

const root = fileURLToPath(new URL('..', import.meta.url));
const directory = mkdtempSync(join(tmpdir(), 'oshelf-workflow-'));
try {
    symlinkSync('/usr/share/omarchy/shell/Commons', join(directory, 'Commons'));
    const configPath = join(directory, 'preferences.json');
    writeFileSync(configPath, JSON.stringify({placement: 'left', sideWidth: 520, closeDelay: 1}));
    const source = readFileSync(new URL('workflow.qml', import.meta.url), 'utf8');
    writeFileSync(join(directory, 'shell.qml'), source.replace('"../components"', JSON.stringify('file:' + resolve(root, 'components'))));
    const result = spawnSync('quickshell', ['-p', directory], {
        env: {...process.env, QT_QPA_PLATFORM: 'wayland', OSHELF_CAPTURE: process.argv[2] || '', OSHELF_VIEW: process.argv[3] || 'right', OSHELF_TEST_CONFIG: configPath},
        encoding: 'utf8', timeout: 15000,
    });
    const output = result.stdout + result.stderr;
    assert.equal(result.status, 0, output);
    assert.match(output, /PASS shelf workflow/, output);
    assert.doesNotMatch(output, /FAIL|ReferenceError|TypeError|is not a type|Cannot assign|Binding loop/, output);
    const saved = JSON.parse(readFileSync(configPath, 'utf8'));
    assert.equal(saved.placement, 'bottom');
    assert.equal(saved.bottomWidth, 1100);
    console.log('PASS shelf workflow and QML load');
} finally {
    rmSync(directory, {recursive: true, force: true});
}
