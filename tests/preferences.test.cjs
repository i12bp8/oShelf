const {test} = require('node:test');
const assert = require('node:assert/strict');
const {normalize, defaults, ranges} = require('../lib/Preferences.js');

test('malformed preferences fall back to safe defaults', () => {
    for (const input of [null, [], 'left', 12, {placement: 'top', openDelay: '0', steadyHover: 0, reducedMotion: 'true'}])
        assert.deepEqual(normalize(input), defaults);
});
test('every numeric preference is bounded, finite, and integral', () => {
    for (const [key, [min, max]] of Object.entries(ranges)) {
        assert.equal(normalize({[key]: -10000})[key], min);
        assert.equal(normalize({[key]: 100000})[key], max);
        for (const invalid of [NaN, Infinity, -Infinity, null, '400'])
            assert.equal(normalize({[key]: invalid})[key], defaults[key]);
        assert.equal(normalize({[key]: min + 0.6})[key], min + 1);
    }
});
test('only recognized options are retained and normalizing is idempotent', () => {
    for (const placement of ['left', 'right', 'bottom']) {
        const value = normalize({placement, steadyHover: false, reducedMotion: true, unknown: 'ignored'});
        assert.equal(value.placement, placement);
        assert.equal(value.steadyHover, false);
        assert.equal(value.reducedMotion, true);
        assert.equal('unknown' in value, false);
        assert.deepEqual(normalize(value), value);
    }
});
