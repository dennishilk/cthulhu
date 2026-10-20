#!/usr/bin/env python3
"""Safely enable two cosmetic pacman settings only in [options]."""
from datetime import datetime, timezone
from pathlib import Path
import difflib
import os
import re
import shutil
import stat
import tempfile

config = Path("/etc/pacman.conf")
if config.is_symlink() or not config.is_file():
    raise SystemExit("Refusing to change a missing or symlinked pacman.conf.")

original = config.read_text(encoding="utf-8")
lines = original.splitlines(keepends=True)
sections = [
    (i, m.group(1).strip().lower())
    for i, line in enumerate(lines)
    if (m := re.match(r"^\\s*\\[([^]]+)\\]\\s*(?:#.*)?$", line))
]
options = [index for index, name in sections if name == "options"]
if len(options) != 1:
    raise SystemExit("Expected exactly one [options] in pacman.conf; refusing to edit.")
start = options[0] + 1
end = next((i for i, _ in sections if i >= start), len(lines))
section = lines[start:end]
eol = "\\r\\n" if "\\r\\n" in original else "\\n"

def ensure_flag(flag):
    active = re.compile(r"^\\s*" + re.escape(flag) + r"\\s*(?:#.*)?$")
    commented = re.compile(r"^\\s*#\\s*" + re.escape(flag) + r"\\s*(?:#.*)?$")
    if any(active.match(line.strip()) for line in section):
        return
    for i, line in enumerate(section):
        if commented.match(line.strip()):
            section[i] = flag + eol
            return
    section.append(flag + eol)

ensure_flag("Color")
ensure_flag("ILoveCandy")
updated = "".join(lines[:start] + section + lines[end:])
if updated == original:
    print("pacman.conf: Color and ILoveCandy already enabled; no change.")
    raise SystemExit(0)

print("Proposed pacman.conf changes:")
print("".join(difflib.unified_diff(original.splitlines(True), updated.splitlines(True),
                                  fromfile="pacman.conf (before)", tofile="pacman.conf (after)")))
backup = config.with_name(config.name + ".cthulhu-" +
                          datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".bak")
shutil.copy2(config, backup)
st = config.stat()
temp = None
try:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="",
                                    dir=config.parent, prefix=".pacman.conf.cthulhu.",
                                    delete=False) as f:
        temp = f.name
        os.fchmod(f.fileno(), stat.S_IMODE(st.st_mode))
        os.fchown(f.fileno(), st.st_uid, st.st_gid)
        f.write(updated)
    os.replace(temp, config)
except Exception:
    if temp and os.path.exists(temp):
        os.unlink(temp)
    raise
print(f"Updated only [options]. Backup: {backup}")
