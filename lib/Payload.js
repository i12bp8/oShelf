var maxItemBytes = 16 * 1024 * 1024;
var maxShelfBytes = 64 * 1024 * 1024;
var maxItems = 48;

function portable(format) {
    return typeof format === "string" && format.length <= 200
        && /^[a-zA-Z0-9!#$&^_.+-]+\/[a-zA-Z0-9!#$&^_.+;-]+(?:[ =a-zA-Z0-9"-]*)$/.test(format)
        && !/x-qt|x-kde-cutselection|x-special|filetransfer|portal|x-moz-file|x-moz-url|x-moz-nativeimage/i.test(format);
}

function localPath(uri) {
    var match = /^file:\/\/(?:localhost)?(\/[^?#]*)$/.exec(uri);
    if (!match) return "";
    try {
        var path = decodeURIComponent(match[1]);
        return path.indexOf("\0") < 0 ? path : "";
    } catch (_) { return ""; }
}

function webDomain(value) {
    var match = /^https?:\/\/([^\s/@]+)(?:[/?#]|$)/i.exec(value);
    return match ? match[1].replace(/^www\./i, "") : "";
}

function base64(buffer) {
    var bytes = new Uint8Array(buffer), out = "";
    var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    for (var i = 0; i < bytes.length; i += 3) {
        var n = (bytes[i] << 16) | ((bytes[i + 1] || 0) << 8) | (bytes[i + 2] || 0);
        out += alphabet[(n >>> 18) & 63] + alphabet[(n >>> 12) & 63]
            + (i + 1 < bytes.length ? alphabet[(n >>> 6) & 63] : "=")
            + (i + 2 < bytes.length ? alphabet[n & 63] : "=");
    }
    return out;
}

function capture(drop, remaining) {
    var formats = Array.prototype.slice.call(drop.formats);
    if (formats.length > 48) throw new Error("This drag offers too many formats.");
    var mime = {}, bytes = 0;
    formats.filter(portable).forEach(function(format) {
        var buffer = drop.getDataAsArrayBuffer(format);
        if (!(buffer instanceof ArrayBuffer)) throw new Error("This format cannot be carried.");
        bytes += buffer.byteLength;
        if (bytes > maxItemBytes || bytes > remaining)
            throw new Error("This payload is too large. Carry the original file instead.");
        if (buffer.byteLength) mime[format] = buffer;
    });
    if (!Object.keys(mime).length) throw new Error("This drag has no portable data.");
    var urls = drop.hasUrls ? Array.prototype.map.call(drop.urls, String) : [];
    if (urls.length > 256) throw new Error("Carry at most 256 files in one card.");
    // Never replay a foreign file host or a process-local transfer token as a file.
    if (urls.some(function(url) { return /^file:/i.test(url) && !localPath(url); }))
        throw new Error("Only local file references can be carried.");
    var text = drop.hasText ? String(drop.text).slice(0, 4096) : "";
    var paths = urls.map(localPath).filter(Boolean);
    var kind = "data", title = "Transfer", detail = Object.keys(mime).join(" · "), thumbnail = "";
    if (paths.length) {
        kind = "file";
        title = paths.length > 1 ? paths.length + " files" : paths[0].split("/").pop() || "/";
        detail = paths.length > 1 ? paths.slice(0, 3).map(function(p) { return p.split("/").pop(); }).join(" · ") : "File reference";
    } else if (webDomain(urls[0] || text.trim())) {
        kind = "url"; title = webDomain(urls[0] || text.trim()); detail = urls[0] || text.trim();
    } else if (text) {
        kind = "text"; title = text; detail = "Text snippet";
    }
    var imageFormat = ["image/png", "image/jpeg", "image/webp"].filter(function(f) { return !!mime[f]; })[0];
    if (!paths.length && imageFormat) {
        kind = "image"; title = "Image"; detail = "Image · " + Math.ceil(mime[imageFormat].byteLength / 1024) + " KB";
        // Bound preview encoding separately; the original bytes remain available to targets.
        if (mime[imageFormat].byteLength <= 2 * 1024 * 1024)
            thumbnail = "data:" + imageFormat + ";base64," + base64(mime[imageFormat]);
    }
    return {mime: mime, bytes: bytes, paths: paths, kind: kind, title: title,
        detail: detail, thumbnail: thumbnail, missing: false};
}

if (typeof module !== "undefined") module.exports = {capture: capture, portable: portable,
    localPath: localPath, webDomain: webDomain, base64: base64, maxItemBytes: maxItemBytes};
