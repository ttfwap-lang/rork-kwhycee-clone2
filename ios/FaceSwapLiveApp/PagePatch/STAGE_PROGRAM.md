# Kwhycee PagePatch / Browser program

Source of truth for stages 1–6. Ceiling is parked, not scheduled.
Branch work starts on `stage1/page-patch-assembler`. Do not implement a later stage until the previous close checklist is green.

Target repo: `ttfwap-lang/rork-kwhycee-clone2`  
HEAD absorbed: `fc1df3c`  
PR: https://github.com/ttfwap-lang/rork-kwhycee-clone2/pull/1

---

## Stage map

| Stage | Name | Behaviour change? | Starts when |
|---|---|---|---|
| 1 | ABI + bake façade | No | now — close via `STAGE1_CLOSURE.md` |
| 2 | FSLWebView / config / bridges | Cut-over only | C6 closed |
| 3 | Dual-source product (PLAN UI + routing choice) | Maybe (routing) | Stage 2 smoke green |
| 4 | Contract tests | No | can parallel 2 after C6 |
| 5 | FacePoseSink | No (native only) | C6 closed |
| 6 | Diagnostics wiring (ConstraintLog + ObservedHUD) | UI only | Stage 2 green |
| — | Ceiling | Experimental | never on this sequence |

---

## Stage 1 — close

Full steps C1–C6 including C6 verification tables: `STAGE1_CLOSURE.md`.

Done when C6.1–C6.7 checked and C6.8 all false.

---

## Stage 2 — native WKWebView structure

**File today:** `Views/BrowserWebContainer.swift` (301 lines, no `WKProcessPool`).

**Invariant:** 3 user scripts, 2 schemes, 2 message names, same `viewModel.schemeHandler` instance.

### ABI

- `fslvideo` / `fslimage`
- `fslPrompt` / `fslStatus`
- `StyleSheetProvider.patchScript` / `constraintLoggingScript` / `behaviorApplyScript`
- `StyleSheetProvider.safariUserAgent(for:)`
- Coordinator remains the object passed to `add(_:name:)`

### Commits

| # | Change | Behaviour? |
|---|---|---|
| 2.A | Empty `Browser/` types + inventory comments | No |
| 2.B | `FSLProcessPool` + `FSLWebConfiguration.make` unused | No |
| 2.C | `makeUIView` uses `FSLWebConfiguration.make` | One cut |
| 2.D | Coordinator forwards to script / download / nav bridges | No if verbatim |
| 2.E | `FSLWebView` type | No |
| 2.F | Config unit tests | No |

`make()` order must match HEAD: schemes, message handlers, patch script, constraint script, behavior script, UA. Do not add `WKContentWorld.page`.

### Stage 2 checklist

**Gate**

- [ ] Stage 1 C6 closed
- [ ] `livePatchScriptStillHasInjectionPipeline` green

**2.A**

- [ ] Every Coordinator `func` listed with the VM method it calls
- [ ] Comments on empty `FSLScriptBridge` / `FSLDownloadBridge` / `FSLNavigationSink`
- [ ] No method bodies moved

**2.B**

- [ ] `ios/FaceSwapLiveApp/Browser/FSLProcessPool.swift`
- [ ] `FSLWebConfiguration.swift`
- [ ] Empty bridge files
- [ ] `makeUIView` still inline
- [ ] Compiles

**2.C**

- [ ] `makeUIView` calls `FSLWebConfiguration.make`
- [ ] Passes `viewModel.schemeHandler` (not a new `LocalResourceHandler()`)
- [ ] Test: `userScripts.count == 3`
- [ ] Test: schemes `fslvideo` and `fslimage` registered
- [ ] Test: UA == `safariUserAgent(for: audit)`
- [ ] Grep: each of the three script sources still appears once
- [ ] Stage 1 tests green

**2.D**

- [ ] Coordinator still registered for `fslPrompt` and `fslStatus`
- [ ] Bodies moved verbatim
- [ ] Downloads still reach `DownloadService`
- [ ] Prompts still reach `BrowserViewModel` prompt handler

**2.E**

- [ ] No new `WKWebsiteDataStore`
- [ ] `dismantleUIView` still clears handlers as HEAD does

**Verify (every Stage 2 commit)**

```bash
rg -n "patchScript|constraintLoggingScript|behaviorApplyScript|fslPrompt|fslStatus|fslvideo|fslimage" \
  ios/FaceSwapLiveApp/Views/BrowserWebContainer.swift \
  ios/FaceSwapLiveApp/Browser
xcodebuild -scheme FaceSwapLiveApp -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Smoke: Stage 1 rows 1–6 plus

7. Navigate in-page, then getUserMedia still resolves  
8. Download path still hits `DownloadService` if triggerable  
9. Leave Browser tab and return — front still URL still serves

**Reject Stage 2 if** `LocalResourceHandler`, `patchScriptBody` JS, `MediaBehaviorSettings.default`, or ARKit files changed, or the three scripts were merged.

---

## Stage 3 — dual-source product

PLAN.md says two things that fight:

1. `fslvideo://front` and `fslvideo://back` are different files.
2. “Backward compatible — if only one video is loaded, it serves for both cameras like today.”

HEAD `LocalResourceHandler` already does (2): `front ?? back`, `back ?? front`, and the `front2`/`back2` chains.

**Do not implement strict 404s unless product explicitly accepts breaking (2).** Default Stage 3 is PLAN-faithful **compat + UI**, not the earlier strict-404 draft.

### 3-compat (default)

Keep fallback. Ship the PLAN UI that HEAD only partially has:

- Overlay sheet: two clear sections Front / Back
- Saved-video one-tap assign front-transcode → front, back-transcode → back
- Toolbar badges: cyan front loaded, green back loaded
- File-input capture already should respect facing — verify, do not rewrite JS

### 3-strict (opt-in only)

Remove cross-facing `??`. Missing path → `URLError.fileDoesNotExist`. Requires a written accept that single-slot dual-facing sites will fail.

### Commits

| # | Change | Behaviour? |
|---|---|---|
| 3.A | Extract `resolveVideoFileURL` / image resolve with **current** `??` chains + tests that document fallback | No |
| 3.B | PLAN overlay split + badges + quick-assign | UI |
| 3.C | **Only if accepted:** drop cross-facing `??`, flip tests | Yes |

Do not change Range / MIME / CORS / EXIF in any 3.x commit.

### Stage 3 checklist

**Gate**

- [ ] Stage 2 smoke 1–9 green
- [ ] Written choice: `compat` (default) or `strict`

**3.A**

- [ ] Helper extracted; `start` / `handleImageRequest` call it
- [ ] Tests: front-only + path `back` → front URL (HEAD)
- [ ] Tests: back-only + path `front` → back URL (HEAD)
- [ ] Tests: both set → own files
- [ ] Tests: none set → nil
- [ ] Same matrix for `front2` / `back2` and images

**3.B**

- [ ] Camera controls sheet has two sections
- [ ] Quick-assign from `SavedVideo` sets both slots from variants
- [ ] Toolbar dots match loaded slots
- [ ] No scheme-handler edit in this commit

**3.C only if strict accepted**

- [ ] Cross-facing `??` gone
- [ ] Tests flipped to nil / `fileDoesNotExist`
- [ ] Smoke: front-only + environment ask does **not** show the selfie
- [ ] Smoke: both loaded → correct files

**Verify**

```bash
rg -n "frontVideoFileURL \?\? backVideoFileURL|backVideoFileURL \?\? frontVideoFileURL" \
  ios/FaceSwapLiveApp/Services/LocalResourceHandler.swift
```

compat: those `??` still present after 3.B.  
strict: those `??` gone after 3.C.

**Reject** if MIME/Range/CORS/EXIF rewritten, scheme names changed, or JS compositor taught to retry the other camera.

---

## Stage 4 — contract tests

No product behaviour. Extends `FaceSwapLiveAppTests`.

### Tests to add

| Test | Pins |
|---|---|
| Gate matrix | `FaceTrackingController.isAllowedToRun == enabled && stillOnActiveFeed && isForeground && !isCameraNeededElsewhere` (line 81–82 today) |
| Recap honesty | `RecapEvent` asked* vs sent* fields only; no invented success |
| Conversion clamp | `MediaConversionSpec.clamp*` vs `DeviceProfile` |
| Prompt timeout | documented `prsec * 1000 + 2500` still in patch source |
| Three-script invariant | configuration built by `FSLWebConfiguration` (after 2.C) or skipped until 2.C |
| Recap / HUD models | `ObservedFeedSnapshot` remains HUD source of truth (comment on `InjectSession`) |

### Stage 4 checklist

- [ ] New test files only under `ios/FaceSwapLiveAppTests/`
- [ ] No production file edits in Stage 4 commits
- [ ] Gate test covers: all true → allowed; each flag flipped alone → not allowed
- [ ] Recap test builds a `RecapEvent` and asserts askedFacing can differ from sentFacing without coercion
- [ ] Prompt-timeout test string-searches the **pre-bake** body or baked script for `+2500` / `prsec`
- [ ] `xcodebuild test` green
- [ ] Stage 1 pipeline test still present

**Verify:** `git show --stat` on Stage 4 commits lists test files only.

---

## Stage 5 — FacePoseSink

Native-only. Do **not** push 61 floats into the page at 30 Hz.

Today: `ARKitFaceSource` → `ARKitFaceRelay` → `FaceSourceEvent` → `FaceTrackingController` (smooth / calibrate / 30 Hz mix) → `outputPose`.

Gate already: `isAllowedToRun` and Preview `isCameraNeededElsewhere`.

### Work

- Protocol `FacePoseSink` with `pose` / `searching` / `interrupted` / `failed` / `cameraDenied` matching `FaceSourceEvent` cases the controller already understands
- `FaceTrackingController` publishes `outputPose` through the sink
- Browser / future compositor subscribe without importing ARKit
- No `evaluateJavaScript` of pose ticks

### Stage 5 checklist

- [ ] `FacePoseSink` in `Models/` or `Services/`
- [ ] Controller still the only owner of `ARSession`
- [ ] Preview-tab exclusion still via `isCameraNeededElsewhere`
- [ ] Existing `FaceTrackingGateTests` green; extend them rather than replacing
- [ ] Grep `evaluateJavaScript` + `outputPose` together → zero hits
- [ ] Smoke row 5 (Preview gate) still passes

**Reject** if any file under `PagePatch/` or `StyleSheetProvider` JS changes, or if a timer in `BrowserViewModel` dumps pose JSON to the page.

---

## Stage 6 — diagnostics wiring

PLAN wants constraint requested-vs-actual and a self-test panel. Data already exists:

- `ConstraintLogService` + `ConstraintLogView`
- `ObservedFeedSnapshot` + `ObservedHUDView` (“HUD source of truth”)
- `SequenceRecap` + `SequenceRecapView`
- `DiagnosticsService` / `DiagnosticsView`
- `FingerprintService` (lab WebView **without** the patch — do not claim it certifies the patched page)

### Work

- One diagnostics surface that shows ConstraintLog + ObservedHUD + Recap together for the current host
- Export bundle already sketched in PLAN / `ExportBundleService` — wire what exists, do not invent new telemetry
- Label fingerprint results as unpatched-lab

### Stage 6 checklist

- [ ] No new page JS
- [ ] HUD still reads `ObservedFeedSnapshot`, not a second ad-hoc struct
- [ ] Constraint log still capped at 200 (`ConstraintLogService`)
- [ ] Recap events remain asked-vs-sent only
- [ ] Fingerprint panel copy says lab / unpatched if shown beside inject recap
- [ ] Export bundle includes constraint log + recap when those arrays are non-empty
- [ ] Stage 1 pipeline test + Stage 2 smoke still green

**Verify:** open Diagnostics tab on a session that asked for camera; requested constraints appear in ConstraintLog; HUD facing/size match recap sent* fields.

---

## Ceiling (parked)

Not on this sequence:

- Native Metal / CI compositor driven by `outputPose`
- `WKContentWorld` isolation of helpers
- Forked WebKit capture device
- Live Link as default face source while injecting
- Pre-rendered H.264 for the back slot
- IMU / rPPG / visibility synthesis

Kill-experiments stay in the original Max Ceiling write-up. Do not open a Stage 7 for them without a separate accept.

---

## Global reject list (any stage)

- Edits inside `patchScriptBody` JS
- Merging the three `WKUserScript`s
- New `LocalResourceHandler` instance in `makeUIView`
- Renaming `fslPrompt` / `fslStatus` / `fslvideo` / `fslimage`
- 30 Hz pose → JS
- Detector-oracle countermeasures

## Stop rule

Revert the last commit if:

- Stage 1 pipeline test goes red
- `fslPrompt` hangs
- `fslvideo://front` 404s while a front file **is** set
- After an accepted 3-strict flip, `fslvideo://back` still returns the front file
