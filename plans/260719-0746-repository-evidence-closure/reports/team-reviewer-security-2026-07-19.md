# Security review — evidence-closure surface and release tooling

Date: 2026-07-19  
Role: reviewer-security (read-only, evidence-only)  
Scope: physical playthrough evidence, Windows export integrity, secret CI gates, Docker packaging  
Branch: main  

## Method

Static adversarial review of:

- `tests/run-physical-playthrough.ps1`
- `tests/physical-playthrough-evidence-regression.ps1`
- `tests/windows-export-adversarial.ps1`
- `tests/verify-windows-export.ps1`
- `tests/windows-export-transaction.ps1`
- `tests/windows-export-job-runner.cs`
- `tests/scan-secret-patterns.sh`
- `tests/verify-docker-packaging.sh`
- `.github/workflows/ci.yml`
- `.github/workflows/docker-suite.yml`
- `export_presets.cfg`
- `Dockerfile`, `docker-compose.yml`, `.dockerignore`, `.gitignore`

No source files modified. No commits. Findings require file:line evidence.

---

## Findings

### [IMPORTANT] Docker builder downloads Godot with no checksum pin

**Evidence:** `Dockerfile:22-27`

```dockerfile
RUN curl -fsSL -o /tmp/godot.zip "${GODOT_URL}" \
	&& unzip -q /tmp/godot.zip -d /opt/godot \
	&& mv "/opt/godot/${GODOT_BIN}" /opt/godot/godot \
	...
	&& /opt/godot/godot --version
```

Only version string is checked later via `HEALTHCHECK` / runtime (`Dockerfile:74-75`). No SHA-256 of the zip or binary is asserted. Contrast: Windows export pins template archive hash (`tests/verify-windows-export.ps1:11,209-211`) and installed template member hash (`:250-252`).

**Impact:** Compromised GitHub release asset, MITM against a poisoned CA store, or cache poisoning yields a CI image that runs attacker-controlled Godot over the full project tree. CI suite results and published `nguyenson1710/horror-game-suite` tags inherit that binary.

**Recommendation:** Pin `GODOT_ZIP_SHA256` ARG; `sha256sum -c` after download; fail closed on mismatch. Prefer multi-arch pin table matching Godot official digests for `4.7.1-stable`.

---

### [IMPORTANT] `.gitignore` and `.dockerignore` omit dotenv / credential globs

**Evidence:**

- `.gitignore:1-21` — tracks ignore rules for `.godot/`, `.artifacts/`, logs; **no** `.env`, `.env.*`, `*.pem`, `*.key`, `credentials*`.
- `.dockerignore:1-28` — excludes `.git`, plans, artifacts; **no** `.env*`.
- `Dockerfile:58` — `COPY --chown=65532:65532 . /app` copies remaining build context into the image.

**Impact:**

1. Accidental `git add .env` is not blocked by ignore rules (CONTRIBUTING/SECURITY tell humans not to, but tooling does not enforce).
2. Local `.env` / token files present during `docker compose build` / `docker build` are layered into the published suite image if not listed in `.dockerignore`.

**Recommendation:** Add to both files at minimum:

```
.env
.env.*
!.env.example
*.pem
*.key
*credentials*
```

---

### [IMPORTANT] Secret-pattern CI gate has intentional blind spots that hide real leaks

**Evidence:** `tests/scan-secret-patterns.sh:11-20`

```bash
PATTERN='ghp_[...]|github_pat_[...]|sk-[...]|AIza[...]|BEGIN (RSA |OPENSSH )?PRIVATE KEY|DOCKERHUB_TOKEN=...'

if git grep -nIE "$PATTERN" -- . \
	':(exclude)*.md' \
	':(exclude)docs/**' \
	':(exclude)plans/**' \
	':(exclude)CHANGELOG.md' \
	':(exclude).github/**' \
	...
```

Concrete gaps:

| Gap | Why it matters |
|---|---|
| `:(exclude).github/**` | Hardcoded `DOCKERHUB_TOKEN=...` or PAT in a workflow YAML is **not** scanned; only packaging contract checks for `${{ secrets.* }}` shape in one file. |
| `:(exclude)*.md` | Token pasted into README/CONTRIBUTING is invisible to the gate. |
| Pattern set | No AWS keys, generic `password=`, connection strings, `ghp_` in base64 blobs, or high-entropy detectors. |

Wired as the only secret job in `.github/workflows/ci.yml:50-58`.

**Impact:** CI green does not mean the tree is free of credentials. The gate is narrower than SECURITY.md claims (“repository must not contain secrets”).

**Recommendation:** Drop `.github/**` and `*.md` exclusions for secret shapes (keep excluding only the scanner file itself). Add Gitleaks or equivalent as a second CI job; treat this script as a cheap fail-fast only.

---

### [IMPORTANT] Legacy export manifest binds only exe hash+size, not full payload set

**Evidence:** `tests/windows-export-transaction.ps1:134-143`

```powershell
$legacyPattern = '\AWINDOWS_EXPORT_SHA256=(?<hash>[0-9a-f]{64})\r\nWINDOWS_EXPORT_SIZE_BYTES=(?<size>[1-9][0-9]*)\r\nWINDOWS_EXPORT_PE=x86_64\r\nWINDOWS_EXPORTED_PROCESS_SMOKE_OK\r\n\z'
...
if ($legacyMatch.Groups['hash'].Value -cne $exeRecord.Hash -or [int64]$legacyMatch.Groups['size'].Value -ne $exeRecord.Size) {
    throw "Legacy Windows export completion manifest does not match its executable"
}
$format = "Legacy"
```

V1 path (`:116-132`) rebinds every payload via `New-BundleManifestText` (FILE lines + `BUNDLE_SHA256`). Legacy path does **not** rebind `LICENSE`, `THIRD_PARTY_NOTICES.md`, export/smoke logs, preset hash, or template hash. Copyright file is still hash-pinned (`:106-109`).

`Recover-PreviousWindowsExport` (`:212-245`) treats any `Get-VerifiedBundleIdentity` success (including Legacy) as a restorable verified previous bundle.

**Impact:** On a machine where `.artifacts/builds/...` is writable by a less-trusted process, a crafted Legacy bundle can pass “verified identity” with substituted notices/logs while keeping a matching PE hash/size. Rollback/recovery then re-promotes that bundle as trusted.

**Recommendation:** Reject Legacy for recovery/activation after a cutover date, or require Legacy manifests to include the same FILE| hash list as V1. Prefer fail-closed: only V1 is identity-grade.

---

### [IMPORTANT] Physical evidence “ready” gate is operator-asserted, not cryptographically bound

**Evidence:**

- `tests/run-physical-playthrough.ps1:462-476` — `Test-EvidencePackageReady` requires `$PhysicalInputConfirmed` and `$CaptureProvided` as booleans only.
- `:626` — `$captureProvided = -not [string]::IsNullOrWhiteSpace($CaptureReference)` (any non-empty string).
- `:640-641` — readiness uses `([bool]$ConfirmPhysicalInput)` and `$captureProvided`.
- `:659-660` — summary stores the free-form `capture_reference` string with no path existence, hash, or reparse check.
- `:676` — `review_required = $true` always (good partial mitigation).

**Impact:** A scripted call with `-ConfirmPhysicalInput -CaptureReference "x"` after a non-physical ProjectRun can print `EVIDENCE_PACKAGE_READY=True` (`:685`) without proving keyboard/mouse input or a real recording. Side-channel/pacing checks harden log freshness; they do not prove human control. Closing PDR-07 on `evidence_package_ready` alone is unsafe.

**Recommendation:** Keep `review_required=true` as hard release policy (already present). Require capture path to exist as a regular non-reparse file with min size + SHA-256 recorded in summary. Document that `EVIDENCE_PACKAGE_READY` is a package completeness flag, not human-approval.

---

### [MODERATE] `EvidenceRoot` / `AnalyzeLog` lack the reparse/containment controls used for APPDATA harvest

**Evidence:**

- `tests/run-physical-playthrough.ps1:30-34` — absolute `EvidenceRoot` accepted without requiring under-repo or under-`.artifacts`.
- `:540-541` — `New-Item` creates `$EvidenceRoot\$runId` with **no** `Assert-RegularEvidenceDirectory` / reparse walk on ancestors.
- `:608-614` — `AnalyzeLog` resolved via `Resolve-Path` only; no `Assert-RegularEvidenceFile` (reparse rejection exists for side-channel sources at `:99-107` but not here).

APPDATA discovery **does** refuse reparse points (`:44-51`, `:64-74`, regression at `physical-playthrough-evidence-regression.ps1:269-308`).

**Impact:** Junctioned `EvidenceRoot` or `AnalyzeLog` can redirect writes/reads outside the intended evidence tree. Same threat class the side-channel hardening already treats as in-scope for local multi-writer Windows profiles.

**Recommendation:** Resolve full paths; require `EvidenceRoot` under `$repositoryRoot\.artifacts\`; apply `Assert-RegularEvidenceDirectory` to every ancestor; apply `Assert-RegularEvidenceFile` to `AnalyzeLog` before parse.

---

### [MODERATE] Regression harness executes runner function bodies via `Invoke-Expression`

**Evidence:** `tests/physical-playthrough-evidence-regression.ps1:50-55`

```powershell
$scopedDefinition = [regex]::Replace($definitions[$name], $functionPattern, "function script:$name", 1)
Invoke-Expression $scopedDefinition
```

`RunnerPath` is a caller parameter (`:3`, default local runner).

**Impact:** Pointing `-RunnerPath` at a hostile `.ps1` executes attacker-chosen function bodies in the test process. Local-only; not CI-default. Still a code-execution footgun if automation ever passes untrusted paths.

**Recommendation:** Constrain `RunnerPath` to under `$PSScriptRoot` after `GetFullPath`, refuse reparse, and/or dot-source a filtered extract without `Invoke-Expression` on arbitrary file text.

---

### [MODERATE] GitHub Actions workflows grant default `GITHUB_TOKEN` permissions

**Evidence:**

- `.github/workflows/ci.yml` — no top-level or job-level `permissions:` block.
- `.github/workflows/docker-suite.yml` — same; publish step uses only Docker Hub secrets (`:27-38`) but job still inherits default token scope.

**Impact:** On repositories with permissive default GITHUB_TOKEN (contents write, packages, etc.), a compromised workflow step or supply-chain action has broader write access than this pipeline needs (checkout + bash + docker).

**Recommendation:**

```yaml
permissions:
  contents: read
```

at workflow top; grant nothing else unless required.

---

### [MODERATE] Docker Hub login pipes token via stdin (correct) but publish is unconditional on secret presence without environment protection

**Evidence:** `docker-suite.yml:25-38` — `if: github.ref == 'refs/heads/main' && github.event_name == 'push'`; secrets step-scoped; skip when empty; `password-stdin` used.

**Non-issue portion:** Token not echoed; not used in `if:` expressions (packaging contract enforces this — `verify-docker-packaging.sh:68-72`).

**Residual risk:** Any push to `main` with configured secrets publishes `:latest` and `:$SHA` with no environment approval / manual gate. Compromised `main` push ⇒ immediate Hub overwrite.

**Recommendation:** Bind publish to a GitHub Environment with required reviewers, or tag-only publish (`v*`) instead of every main push.

---

## Non-issues (checked and cleared)

| Area | Result |
|---|---|
| `export_presets.cfg` credentials | `custom_template/*=""`, `codesign/*` empty/disabled, `ssh_remote_deploy/enabled=false` and empty host/scripts (`export_presets.cfg:23-56`). Verifier rejects non-empty credential-like values (`verify-windows-export.ps1:205-207`) and non-empty custom templates (`:203`). |
| Output path escape for Windows export | `outputRoot` must start with repo `.artifacts\` (`verify-windows-export.ps1:16-17,137-139`); adversarial probe expects refusal (`windows-export-adversarial.ps1:221-225`). |
| Export process tree kill | Job Object `KILL_ON_CLOSE` + `TerminateJobObject` (`windows-export-job-runner.cs:9,216-232,381-392`); adversarial grandchild survival probe (`windows-export-adversarial.ps1:105-142`). |
| V1 bundle tamper (BOM, extra line, dependency hash) | Explicit fail-closed tests (`windows-export-adversarial.ps1:150-162`). |
| Exclusive export lock | `FileShare.None` + `DeleteOnClose` (`verify-windows-export.ps1:277-284`); concurrent run rejected. |
| Side-channel reparse (APPDATA / project candidate) | Fail-closed helpers + regression (`run-physical-playthrough.ps1:44-51`; regression `:282-308`). |
| Side-channel freshness / baseline hash | Strict `last_write > launch` and baseline hash exclusion (`run-physical-playthrough.ps1:352-357`); regression covers stale, exact boundary, same-hash (`physical-playthrough-evidence-regression.ps1:181-203`). |
| Snapshot TOCTOU identity + destination verify | Pre/post identity + size/hash verify; rejected destinations deleted (`run-physical-playthrough.ps1:171-246`); swap/corrupt hooks tested (`:216-267`). |
| Analyze-only path cannot mark package ready | `enginePassed` requires `$launchPerformed` (`:629`); `AnalyzeLog` sets `launchPerformed=false` (`:545`). |
| Docker non-root | `USER 65532:65532` and compose `user: "65532:65532"` (`Dockerfile:64`, `docker-compose.yml:15`). |
| Docker Hub secret in `if:` | Absent; packaging forbids it. |
| Hardcoded secrets in reviewed scripts | None observed; pattern literals only in scanner. |

---

## Severity summary

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| IMPORTANT | 5 |
| MODERATE | 4 |

## Recommended fix order

1. Pin Godot zip/binary SHA-256 in `Dockerfile` builder stage.
2. Add `.env*` / key material globs to `.gitignore` and `.dockerignore`.
3. Close secret-scan exclusions for `.github/**` and `*.md`; add Gitleaks.
4. Drop or harden Legacy export identity for recovery.
5. Contain `EvidenceRoot`/`AnalyzeLog` with reparse + `.artifacts` root checks.
6. Set workflow `permissions: contents: read`; optional Environment gate for Hub publish.
7. Tighten capture-reference existence/hash if `EVIDENCE_PACKAGE_READY` is used as a release signal.

## Unresolved questions

- Is Legacy manifest support still required for on-disk bundles produced before V1, or can recovery fail closed on V1-only?
- Is Hub publish-on-every-main-push intentional product policy for this solo repo?

---

Status: DONE  
Summary: No CRITICAL remote RCE; five IMPORTANT issues (Docker supply-chain pin, ignore-file secret gaps, secret-scan blind spots, Legacy export identity weakness, operator-asserted physical-ready gate) plus four MODERATE path/CI/process findings. Export V1 + side-channel reparse/freshness controls are solid within stated maintainer threat model.  
Concerns: Closing PDR-07 or publishing suite images without Dockerfile checksum pin and ignore-file fixes leaves residual supply-chain and secret-leak paths that CI currently will not catch.
