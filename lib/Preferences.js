var defaults = {placement: "right", openDelay: 350, closeDelay: 700,
    activationLength: 200, activationDepth: 8, activationPosition: 50,
    steadyHover: true, motionDuration: 260, reducedMotion: false,
    sideWidth: 360, sideHeight: 520, bottomWidth: 680, bottomHeight: 400};
var ranges = {openDelay: [150, 1500], closeDelay: [250, 2500],
    activationLength: [80, 600], activationDepth: [4, 24],
    activationPosition: [10, 90], motionDuration: [120, 420],
    sideWidth: [360, 640], sideHeight: [460, 1000], bottomWidth: [560, 1400], bottomHeight: [400, 800]};
function normalize(input) {
    input = input && typeof input === "object" && !Array.isArray(input) ? input : {};
    var out = Object.assign({}, defaults);
    Object.keys(ranges).forEach(function(key) {
        var value = input[key];
        if (typeof value === "number" && isFinite(value))
            out[key] = Math.round(Math.max(ranges[key][0], Math.min(ranges[key][1], value)));
    });
    if (["left", "right", "bottom"].indexOf(input.placement) >= 0) out.placement = input.placement;
    ["steadyHover", "reducedMotion"].forEach(function(key) {
        if (typeof input[key] === "boolean") out[key] = input[key];
    });
    return out;
}
if (typeof module !== "undefined") module.exports = {normalize: normalize, defaults: defaults, ranges: ranges};
