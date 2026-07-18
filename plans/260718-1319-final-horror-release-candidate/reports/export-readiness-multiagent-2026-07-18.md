# Windows x86_64 export readiness (honest smoke-test gate)

> **Historical preflight — superseded.** This records the state before the
> templates, tracked preset, and verifier existed. Current result:
> `windows-export-verified-2026-07-18.md` and `final-automated-audit-2026-07-18.md`.

**Date:** 2026-07-18  
**Assessor:** export-readiness multiagent (Phase 6 preflight only)  
**Repo:** `D:\Horror_Game`  
**Plan phase:** [phase-06-windows-export-docs-and-completion-audit.md](../phase-06-windows-export-docs-and-completion-audit.md)  
**Verdict:** **Export cannot run now** — stop at install + preset prep; no `.exe` was produced or launched.

---

## Executive answer

| Question | Result |
|---|---|
| Can a Windows x86_64 export smoke run **right now**? | **No** |
| Was an `.exe` built or menu-launched? | **No** (not attempted; blockers present) |
| Primary blockers | (1) export templates **archive present but not installed**; (2) **`export_presets.cfg` missing**; (3) Phase 6 also wants ignore-rule flip so a credential-free preset can be tracked |

No fabricated export success. No binaries committed. No destructive ops performed.

---

## 1. `export_presets.cfg` and ignore rules

| Item | Status | Detail |
|---|---|---|
| `export_presets.cfg` at repo root | **Absent** | `Test-Path D:\Horror_Game\export_presets.cfg` → `False` |
| `export.cfg` | **Absent** (expected local) | Also gitignored |
| README / docs claim | Matches disk | Source-only; no committed preset, executable, or bundled Godot binary |

### `.gitignore` (current)

Relevant lines from `D:\Horror_Game\.gitignore`:

```text
.artifacts/
.tmp/
exports/
builds/
*.tmp
*.log

# Local export configuration (not required to run the source project)
export.cfg
export_presets.cfg
```

Implications:

- Build outputs under `.artifacts/`, `exports/`, and `builds/` stay ignored (good).
- **`export_presets.cfg` is ignored today**, so even a hand-authored credential-free preset would not be committed until Phase 6 step 2 changes ignore rules.
- Phase 6 owned-files intent: track a **credential-free** `export_presets.cfg`; keep templates, keystores, and build binaries ignored.

**Do not invent a preset file content as “success.”** A working Windows Desktop preset must be created in Godot **Project → Export** (or carefully authored and then verified by a real export).

---

## 2. Godot 4.7.1 host binary

| Path | Present | Notes |
|---|---|---|
| `D:\Tools\Godot-4.7.1\` | **Yes** | Portable layout (`_sc_` present, length 1) |
| `Godot_v4.7.1-stable_win64.exe` | **Yes** | ~179 MB editor GUI |
| `Godot_v4.7.1-stable_win64_console.exe` | **Yes** | Console binary used by host suite |
| Console `--version` | **Yes** | `4.7.1.stable.official.a13da4feb` |
| Console SHA256 | Recorded | `35DAB11E04ECE16A2B93035E65204F4A944A3E00B020D43E54409193379D5EEF` |

Editor data lives beside the portable binary:

- `D:\Tools\Godot-4.7.1\editor_data\` (cache, export_templates dir, keystores dir, settings, etc.)
- Because `_sc_` exists, export templates are expected under  
  `D:\Tools\Godot-4.7.1\editor_data\export_templates\<version>\`  
  **not** under `%APPDATA%\Godot\export_templates\`.

---

## 3. Export templates search (D: + common user paths)

### Installed templates (what Godot uses for export)

| Location | Exists | Usable content |
|---|---|---|
| `D:\Tools\Godot-4.7.1\editor_data\export_templates\` | **Yes (empty dir)** | **0 children** — **not installed** |
| `...\export_templates\4.7.1.stable` | **No** | Required for this editor |
| `%APPDATA%\Godot\export_templates` | **No** | N/A for portable `_sc_` |
| `%LOCALAPPDATA%\Godot\export_templates` | **No** | N/A |
| `D:\Godot\export_templates`, `D:\export_templates`, `C:\Godot\export_templates` | **No** | — |

### Official template archive on D: (downloaded, not installed)

| Path | Status |
|---|---|
| `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz` | **Present** |
| Size | `1280486955` bytes (~1.19 GiB) |
| SHA256 | `86409DB6200B6F8FD3230989C2D2002851F3DD18ACF11D7BDBAFDDF5A0DD0F72` |
| Zip open | **OK** (35 entries under `templates/`) |
| `templates/version.txt` | `4.7.1.stable` (matches editor) |
| Windows release x86_64 | `templates/windows_release_x86_64.exe` (109212160 bytes) + `windows_release_x86_64_console.exe` (188928) |
| Windows debug x86_64 | Present |
| Other platforms | Full standard pack (Android, iOS, Linux, macOS, Web, etc.) |

**Conclusion:** Matching official 4.7.1 templates **exist as a local `.tpz` archive on D:** but are **not installed** into the portable editor’s `export_templates` tree. Godot CLI export will fail until install completes. An empty `export_templates` folder is not a substitute for `4.7.1.stable` contents.

No other completed template installs or Windows release template binaries were found under the searched AppData/Godot or shallow `D:\` layout paths.

---

## 4. Phase 6 requirements vs current disk

From `phase-06-windows-export-docs-and-completion-audit.md`:

| Success criterion | Current state |
|---|---|
| Matching official template + reproducible preset | Template **archive** only; **no install**, **no preset** |
| Ignored `.exe` launches to production menu | **Not started** — no build artifact |
| Post-export suite / docs / secret scan / audit | N/A until export smoke exists |
| Plan/PDR/roadmap match evidence | Phase 6 remains **pending**; docs already say export untested |

README (source-only contract) remains accurate:

- No `export_presets.cfg`, exported executable, or bundled Godot binary in the repo.
- Docker image is a headless suite packaging surface, not a shipped game binary.
- Export section: install matching templates, create platform preset locally, keep packages out of Git, treat as unverified until target-platform tested.

---

## 5. Why export was not attempted

Blockers (any one is enough to refuse a smoke claim):

1. **Templates not installed** for portable Godot (`editor_data\export_templates` empty).
2. **`export_presets.cfg` missing** — CLI `--export-release "<preset>"` has no named preset.
3. Honesty rule: do not invent successful `.exe` launch or commit binaries.

After install + preset creation, export output must stay under gitignored paths such as:

- `.artifacts/builds/room407-windows-x86_64/` (Phase 6 preferred)
- and/or local `exports/` / `builds/` (also ignored)

---

## 6. Draft commands for the lead (do not treat as already run)

These are **recommended next steps only**. They were **not** executed in this assessment.

### 6.1 Install templates into portable Godot (pick one)

**A — Editor UI (safest):**

1. Launch `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe`
2. **Editor → Manage Export Templates… → Install from File**
3. Select `D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz`
4. Confirm folder appears:  
   `D:\Tools\Godot-4.7.1\editor_data\export_templates\4.7.1.stable\`  
   with at least `windows_release_x86_64.exe` and `version.txt` reading `4.7.1.stable`

**B — Manual extract (portable layout):**

```powershell
$godotRoot = "D:\Tools\Godot-4.7.1"
$tpz = Join-Path $godotRoot "Godot_v4.7.1-stable_export_templates.tpz"
$dest = Join-Path $godotRoot "editor_data\export_templates\4.7.1.stable"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
# .tpz is a zip whose top folder is templates/; extract entries into 4.7.1.stable
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($tpz)
foreach ($entry in $zip.Entries) {
  if (-not $entry.FullName.StartsWith("templates/")) { continue }
  $rel = $entry.FullName.Substring("templates/".Length)
  if ([string]::IsNullOrWhiteSpace($rel)) { continue }
  $out = Join-Path $dest $rel
  if ($entry.FullName.EndsWith("/")) {
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    continue
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $out -Parent) | Out-Null
  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $out, $true)
}
$zip.Dispose()
Get-Content (Join-Path $dest "version.txt")
Test-Path (Join-Path $dest "windows_release_x86_64.exe")
```

### 6.2 Create credential-free Windows preset

1. Open project `D:\Horror_Game\project.godot` in Godot 4.7.1.
2. **Project → Export → Add… → Windows Desktop**.
3. Preset name suggestion: `Windows Desktop` (or `windows-x86_64`).
4. Export path suggestion (gitignored):  
   `res://.artifacts/builds/room407-windows-x86_64/Room407.exe`  
   or absolute  
   `D:\Horror_Game\.artifacts\builds\room407-windows-x86_64\Room407.exe`
5. Architecture: **x86_64**.
6. Do **not** embed or commit keystores/passwords; leave codesign/custom options empty for smoke.
7. Save so `export_presets.cfg` appears at repo root.
8. Phase 6 docs intend to **stop ignoring** a credential-free `export_presets.cfg` while still ignoring templates/builds/`.exe` — do that ignore edit only after inspecting the file for secrets.

### 6.3 CLI export + honest smoke (only after 6.1 + 6.2)

```powershell
Set-Location D:\Horror_Game
$Godot = "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
$OutDir = ".\.artifacts\builds\room407-windows-x86_64"
$Exe = Join-Path $OutDir "Room407.exe"
$Log = ".\.artifacts\builds\room407-windows-x86_64\export.log"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Preset name MUST match export_presets.cfg exactly
& $Godot --headless --path . --export-release "Windows Desktop" $Exe 2>&1 |
  Tee-Object -FilePath $Log
$exportExit = $LASTEXITCODE

if (-not (Test-Path $Exe)) {
  Write-Error "Export failed: no exe (exit=$exportExit). See $Log"
  exit 1
}

Get-Item $Exe | Format-List FullName, Length, LastWriteTime
Get-FileHash $Exe -Algorithm SHA256 | Format-List

# Smoke: launch menu, human verifies boot menu, clean exit — do not claim success without that observation
# & $Exe
```

Post-export (Phase 6):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-headless-tests.ps1 `
  -Godot "D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
```

Record: export log, exe size, SHA256, human menu launch notes, suite result. Do **not** `git add` `.exe`, `.pck`, templates, or `.tpz`.

---

## 7. Fallback gate (honest status)

Until templates are installed **and** a verified preset exists **and** a real `.exe` menu smoke is observed:

- Phase 6 Windows delivery evidence row stays **open**.
- Docs may continue to state: no export preset committed or release-tested (unless/until preset is intentionally tracked and export is proven).
- **No** success language for binary packaging, store builds, or redistribution notice automation.

Scratch fallback companion:  
`C:\Users\Admin\AppData\Local\Temp\grok-goal-7f218f885663\implementer\export-gate-fallback.txt`  
(also reflected in `physical-gate-fallback.txt` Phase 6 section).

---

## 8. Inventory snapshot (machine-local, not repo evidence of export success)

```text
Godot_dir=D:\Tools\Godot-4.7.1
godot_version=4.7.1.stable.official.a13da4feb
console_sha256=35DAB11E04ECE16A2B93035E65204F4A944A3E00B020D43E54409193379D5EEF
export_presets.cfg=MISSING
export_templates_dir=EMPTY (0 children)
tpz=D:\Tools\Godot-4.7.1\Godot_v4.7.1-stable_export_templates.tpz
tpz_size=1280486955
tpz_sha256=86409DB6200B6F8FD3230989C2D2002851F3DD18ACF11D7BDBAFDDF5A0DD0F72
tpz_version.txt=4.7.1.stable
tpz_windows_release_x86_64=present_in_archive_not_installed
export_can_run_now=NO
exe_built=NO
exe_menu_smoke=NO
```

---

## Status

**DONE** — readiness assessed honestly; export smoke blocked.

**Export can run now: no**
