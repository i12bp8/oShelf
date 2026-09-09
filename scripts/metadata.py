#!/usr/bin/env python3
"""Read local reference metadata; never open payloads or follow remote URLs."""
import json
import os
import stat
import sys


def inspect(paths):
    if not isinstance(paths, list) or len(paths) > 256:
        raise ValueError("invalid reference list")
    result = []
    for path in paths:
        if not isinstance(path, str) or not path.startswith("/") or "\0" in path:
            raise ValueError("invalid path")
        try:
            info = os.stat(path)
            kind = "folder" if stat.S_ISDIR(info.st_mode) else "file"
            regular = stat.S_ISREG(info.st_mode)
            result.append({"exists": True, "kind": kind, "image": regular and
                           os.path.splitext(path)[1].lower() in {".png", ".jpg", ".jpeg", ".webp"}})
        except OSError:
            result.append({"exists": False, "kind": "file", "image": False})
    return result


if __name__ == "__main__":
    try:
        raw = sys.stdin.buffer.readline(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024:
            raise ValueError("too large")
        print(json.dumps(inspect(json.loads(raw))))
    except (ValueError, TypeError, UnicodeError):
        sys.exit(1)
