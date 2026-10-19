#!/usr/bin/env python3
"""Expand the shared file inventory into both complete installation documents."""
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[1]
files = json.loads((root / 'docs/files.json').read_text())
base = 'https://github.com/dennishilk/cthulhu/blob/main/WM/xmonad/nixos-kanagawa-dragon/'
raw = 'https://raw.githubusercontent.com/dennishilk/cthulhu/main/WM/xmonad/nixos-kanagawa-dragon/'

def language(path):
    return ('nix' if path.endswith('.nix') else 'haskell' if path.endswith('.hs') or path.endswith('.xmobarrc')
            else 'bash' if path.endswith('.sh') or path.endswith('cthulhu-audio')
            else 'json' if path.endswith(('.json', '.jsonc')) else 'ini')

library = '\n\n'.join('### '+path+'\n\n[GitHub]('+base+path+') · [Raw]('+raw+path+')\n\n```'+language(path)+'\n'
                       +(root/path).read_text().rstrip()+'\n```' for path in files)
for lang in ['en', 'de']:
    content = (root / f'docs/guide.{lang}.md').read_text().replace('<!-- FILE_LIBRARY -->', library)
    target = root / f'INSTALL.{lang}.md'
    if '--check' in sys.argv:
        if not target.exists() or target.read_text() != content:
            raise SystemExit('Outdated '+str(target))
        print('Documentation matches sources:', lang)
    else:
        target.write_text(content)
