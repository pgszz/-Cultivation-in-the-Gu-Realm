"""Exercise the Windows launcher with real Godot and disposable projects."""
from __future__ import annotations

import argparse
import datetime
import json
import os
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', type=Path, required=True)
    args = parser.parse_args()
    if os.name != 'nt':
        parser.error('The launcher requires Windows.')
    engine = args.godot.resolve()
    run = ROOT / '.test-runs' / ('startup-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:6])
    # Spaces, Unicode and shell metacharacters must remain literal path text.
    project = run / 'project with spaces & 山路'
    project.mkdir(parents=True)
    (project / 'project.godot').write_text(
        'config_version=5\n[application]\n'
        f'config/name="Gudao-QA-{run.name}"\n'
        'config/use_custom_user_dir=false\nrun/main_scene="res://main.tscn"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    (project / 'main.tscn').write_text(
        '[gd_scene load_steps=2 format=3]\n'
        '[ext_resource type="Script" path="res://main.gd" id="1"]\n'
        '[node name="Main" type="Node"]\nscript = ExtResource("1")\n', encoding='utf-8')
    script = project / 'main.gd'
    report = []

    def launch(label: str, source: str, success: bool, prepare: bool = False, error: str = '') -> str:
        script.write_text(source, encoding='utf-8')
        command = ['powershell.exe', '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                   '-File', str(ROOT / 'tools/start_game.ps1'), '-GodotPath', str(engine),
                   '-ProjectPath', str(project)]
        if prepare:
            command.append('-PrepareOnly')
        result = subprocess.run(command, capture_output=True, timeout=220)
        output = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        (run / f'{label}.log').write_text(output, encoding='utf-8')
        passed = (result.returncode == 0) == success
        if success:
            passed = passed and ('Import passed.' if prepare else 'Character selection ready.') in output
        else:
            passed = passed and error in output and 'Character selection ready.' not in output
        report.append({'case': label, 'passed': passed, 'exit_code': result.returncode, 'command': command})
        print(('PASS ' if passed else 'FAIL ') + label, flush=True)
        if not passed:
            print(output, flush=True)
        return output

    launch('clean_import', 'extends Node\n', True, prepare=True)
    (project / 'late.gd').write_text('class_name LateLaunchDependency\nextends RefCounted\n', encoding='utf-8')
    good_source = ('extends Node\nvar dependency := LateLaunchDependency.new()\n'
                   'func _ready() -> void:\n'
                   '\tawait RenderingServer.frame_post_draw\n'
                   '\tprint("GUDAO_STARTUP_READY")\n'
                   '\tawait get_tree().create_timer(2.0).timeout\n'
                   '\tget_tree().quit()\n')
    launch('new_class_after_cached_import', good_source, True)
    launch('parse_error_blocks_launch', 'extends Node\nvar invalid :=\n', False, error='import failed.')
    launch('runtime_error_blocks_success', 'extends Node\nfunc _ready() -> void:\n\tpush_error("Intentional startup failure")\n\tawait get_tree().create_timer(2.0).timeout\n\tget_tree().quit()\n', False, error='Game startup failed.')
    launch('early_exit_blocks_success', 'extends Node\nfunc _ready() -> void:\n\tget_tree().quit()\n', False, error='The game closed during startup.')
    # No .godot directory is edited by the test; both cached and fresh indexes
    # above are written only by the engine's import command.
    (run / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print('REPORT ' + str(run / 'report.json'), flush=True)
    return 0 if all(item['passed'] for item in report) else 1


if __name__ == '__main__':
    raise SystemExit(main())
