# Empires Rise v0.4 Debug Report

## Checks run before packaging

- `python3 tools/static_check.py`
  - required project files
  - local `res://` references
  - duplicate GDScript function names
  - delimiter balance after safe string/comment stripping
  - Android export preset basics
- `bash -n` on every shell script
- Python bytecode compilation for `tools/static_check.py`
- YAML parse of both GitHub Actions workflows
- grep review for Variant-inference `:=` declarations in GDScript
- ZIP integrity test after packaging

## CI checks included

The project ships with two GitHub workflows:

1. **Godot Smoke Test**
   - installs Godot 4.7.2
   - imports the project headlessly
   - runs the main scene briefly
   - treats printed GDScript parse/compiler errors as failures

2. **Android Debug APK**
   - configures Java 17 and Android SDK
   - creates a debug keystore
   - exports with Godot 4.7.2
   - uploads the resulting APK artifact

## Android-specific fixes included

- `rendering/textures/vram_compression/import_etc2_astc=true`
- explicit `sdkmanager` discovery on GitHub runners
- no dependency on optional downloaded art for the prototype
- typed local GDScript variables used throughout the visual/UI pass to avoid the Variant-inference warnings that broke the earlier Android export

## Local limitation

This packaging environment does not contain a Godot executable, so the engine-level smoke test is included for Codespaces/GitHub Actions rather than claimed as locally executed. The static, shell, YAML, and archive checks were executed before packaging.
