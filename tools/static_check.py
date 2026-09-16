#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
warnings: list[str] = []

required = [
    "project.godot",
    "export_presets.cfg",
    "scenes/Main.tscn",
    "scripts/Main.gd",
    "scripts/GameState.gd",
    "scripts/CityView.gd",
    "scripts/WorldView.gd",
]
for rel in required:
    if not (ROOT / rel).is_file():
        errors.append(f"missing required file: {rel}")

# Validate project and scene res:// references that are expected to ship locally.
optional_prefixes = ("assets/cc0/",)
for rel in ["project.godot", "scenes/Main.tscn"]:
    path = ROOT / rel
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r'res://([^"\s]+)', text):
        target = match.group(1)
        if target.startswith(optional_prefixes):
            continue
        if not (ROOT / target).exists():
            errors.append(f"{rel}: broken res:// reference -> {target}")

# Lightweight GDScript structural sanity checks. Godot CI performs the real parse.
for path in sorted((ROOT / "scripts").glob("*.gd")):
    text = path.read_text(encoding="utf-8")
    if "\t" in text:
        warnings.append(f"{path.name}: contains tab indentation")

    funcs = re.findall(r'^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', text, flags=re.M)
    dupes = sorted({name for name in funcs if funcs.count(name) > 1})
    if dupes:
        errors.append(f"{path.name}: duplicate function names: {', '.join(dupes)}")

    # Strip quoted strings and comments before simple delimiter balance checks.
    stripped_lines = []
    for line in text.splitlines():
        # Strip quoted strings before comments so '#' inside UI color strings is not mistaken for a comment.
        line = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
        line = re.sub(r'#.*$', '', line)
        stripped_lines.append(line)
    stripped = "\n".join(stripped_lines)
    for left, right in [("(", ")"), ("[", "]"), ("{", "}")]:
        if stripped.count(left) != stripped.count(right):
            errors.append(f"{path.name}: unbalanced {left}{right} delimiters")

# Check export preset basics.
export = ROOT / "export_presets.cfg"
if export.exists():
    text = export.read_text(encoding="utf-8")
    for token in ['name="Android"', 'platform="Android"', 'architectures/arm64-v8a=true']:
        if token not in text:
            errors.append(f"export_presets.cfg: expected {token}")

# Regression guards for two expensive bugs seen in early prototype work.
city = (ROOT / "scripts/CityView.gd").read_text(encoding="utf-8") if (ROOT / "scripts/CityView.gd").exists() else ""
if "GameState.state_changed.connect(refresh_city)" in city:
    errors.append("CityView.gd: city rebuild is connected to high-frequency state_changed signal")

state = (ROOT / "scripts/GameState.gd").read_text(encoding="utf-8") if (ROOT / "scripts/GameState.gd").exists() else ""
advance_match = re.search(r'func _advance_simulation\(.*?\n(?=func )', state, flags=re.S)
if advance_match and "state_changed.emit()" in advance_match.group(0):
    errors.append("GameState.gd: _advance_simulation emits state_changed every simulation frame")

print("Empires Rise static debug check")
print(f"Root: {ROOT}")
for warning in warnings:
    print(f"WARNING: {warning}")
if errors:
    for error in errors:
        print(f"ERROR: {error}")
    print(f"FAILED: {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1)
print(f"PASS: 0 errors, {len(warnings)} warning(s)")
