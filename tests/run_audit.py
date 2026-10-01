"""Regression audit using LuaJIT and a strict CSP API simulator (no game required).

Run: python tests/run_audit.py
Requires lupa with luajit21. Does not start AC or change settings/files.
"""
from pathlib import Path
import re
from lupa.luajit21 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SDK = ROOT.parents[2] / 'extension/internal/lua-sdk/ac_apps/lib.lua'


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    sdk = SDK.read_text(encoding='utf-8')
    # A nonexistent FFI field must FAIL rather than silently returning nil.
    car_section = sdk.split('---@class ac.StateCar : ClassBase', 1)[1].split('---@class ac.StateCarPhysics', 1)[0]
    fields = re.findall(r'---@field (\w+) ([^\s]+)', car_section)
    defaults = {name: (False if kind == 'boolean' else 0) for name, kind in fields}
    lua.globals().carDefaults = lua.table_from(defaults)
    lua.globals().root = ROOT.as_posix()
    lua.globals().assetExists = lambda filename: Path(filename).is_file()
    windows = re.split(r'\[WINDOW_\.\.\.\]', (ROOT / 'manifest.ini').read_text(encoding='utf-8'))[1:]
    callbacks = []
    for section in windows:
        props = dict(re.findall(r'^(\w+)\s*=\s*(.+)$', section, re.M))
        width, height = map(float, props['SIZE'].split(','))
        callbacks.append({'title': props['NAME'], 'main': props['FUNCTION_MAIN'],
                          'id': props.get('ID', ''),
                          'show': props.get('FUNCTION_ON_SHOW', ''), 'hide': props.get('FUNCTION_ON_HIDE', ''),
                          'width': width, 'height': height})
    lua.globals().windowDefinitions = lua.table_from([lua.table_from(row) for row in callbacks])
    assert len(callbacks) == 19, f'Expected 19 app windows, found {len(callbacks)}'
    manifest = (ROOT / 'manifest.ini').read_text(encoding='utf-8')
    assert '[UI_CALLBACKS]' not in manifest, 'Per-window HUD must not use a fullscreen overlay callback'
    for asset in [*ROOT.glob('fonts/*.ttf'), ROOT / 'icon.png',
                  ROOT / 'assets/fastest.wav', ROOT / 'assets/pb.wav', ROOT / 'assets/green.wav']:
        assert asset.is_file() and asset.stat().st_size > 0, f'Missing asset: {asset}'
    for path in ROOT.glob('**/*.lua'):
        if 'tests' not in path.parts:
            lua.compile(path.read_text(encoding='utf-8'), name=str(path.relative_to(ROOT)))
    lua.execute((ROOT / 'tests/csp_mock.lua').read_text(encoding='utf-8'))
    lua.execute((ROOT / 'Streamer Hud.lua').read_text(encoding='utf-8'))
    for row in callbacks:
        for key in ('main', 'show', 'hide'):
            callback = row[key]
            if callback:
                assert lua.eval('type')(lua.globals().script[callback]) == 'function', (
                    f'Manifest callback missing in script: script.{callback}')
                assert lua.eval('type')(lua.globals()[callback]) == 'function', (
                    f'Manifest callback missing as global: {callback}')
    lua.execute((ROOT / 'tests/regression.lua').read_text(encoding='utf-8'))
    print(f'PASS: {len(callbacks)} app windows, dual callback registration and feature regressions')


if __name__ == '__main__':
    main()
