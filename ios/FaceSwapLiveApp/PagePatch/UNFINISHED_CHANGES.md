# Unfinished changes — Stage 1 close through Stage 6

Working tree reviewed at `44234ef` on `stage1/page-patch-assembler`.
Injection JS (`patchScriptBody`) was **not** edited. Live path is still
`BrowserWebContainer` → `StyleSheetProvider.patchScript` → private body + inline bake.

Code review repairs already landed:
- Phantom `PatchTokens.partOrder = ["rawBody"]` removed (no `rawBody` exists).
- Unused `PatchAssembler.patchScript(...)` wrapper removed; C1 calls `bake`.
- `bakeHonorsNonDefaultStealth` added (defaults-only tests could hide an inverted ternary).

Do the stages in order. Check every box. Revert the last commit if a verify row fails.

---

## Stage 1 — finish (unfinished)

**Unfinished:** façade switch, `xcodebuild`, smoke, PR undraft.

### Changes left

1. In `StyleSheetProvider.patchScript(stealth:)` replace the six `replacingOccurrences` with:

```swift
return PatchAssembler.bake(
    patchScriptBody,
    stealth: stealth,
    key: fslStateKeySuffix,
    token: fslStateToken
)
```

2. Do not touch the `patchScriptBody` literal.
3. Delete `NEXT_FACADE_SWITCH.txt` in that commit (consumed).

### Checklist

- [ ] C1 commit SHA: `________`
- [ ] `git show --stat` is `StyleSheetProvider.swift` ± that delete
- [ ] `xcodebuild -scheme FaceSwapLiveApp -destination 'platform=iOS Simulator,name=iPhone 16' test`
- [ ] `PatchAssemblerTests` 5/5 (includes `bakeHonorsNonDefaultStealth`)
- [ ] `FaceTrackingGateTests` / `PoseMathTests` / `LiveLinkFacePacketTests` green
- [ ] Grep: zero `__FSL_*` replacingOccurrences in `patchScript`; one `PatchAssembler.bake`
- [ ] Grep: `BrowserWebContainer` still one patch `WKUserScript` + constraint + behavior
- [ ] Smoke 1 cold launch
- [ ] Smoke 2 inert page
- [ ] Smoke 3 front still inject paints
- [ ] Smoke 4 back file slot fills
- [ ] Smoke 5 Preview ARKit gate
- [ ] PR #1 undrafted on C1 SHA

### Verify

Baked `patchScript` still contains `captureStream`, `getUserMedia`, `enumerateDevices`,
`HTMLInputElement.prototype.click`, `function toString()`, `_nat.has(this)`,
`fslPrompt`, `fslvideo://`. Evidence = passing `livePatchScriptStillHasInjectionPipeline`.

Hard stop: any edit inside the JS literal, `LocalResourceHandler`, ARKit, or stealth defaults.

Full C6 table: `STAGE1_CLOSURE.md`.

---

## Stage 2 — FSLWebView structure (unfinished)

**Unfinished:** entire stage. File today: `Views/BrowserWebContainer.swift` (~301 lines, `WKProcessPool` = 0).

### Changes left

- `Browser/FSLProcessPool.swift` — one shared pool
- `Browser/FSLWebConfiguration.swift` — builds config in HEAD order
- `Browser/FSLScriptBridge.swift` / `FSLDownloadBridge.swift` / `FSLNavigationSink.swift`
- `Browser/FSLWebView.swift`
- Point `makeUIView` at `FSLWebConfiguration.make`
- Coordinator stays the `add(_:name:)` object and forwards

HEAD `makeUIView` order to copy: schemes `fslvideo` then `fslimage` → handlers `fslPrompt` then `fslStatus` → user scripts patch, constraint, behavior → `customUserAgent`.

### Checklist

- [ ] Stage 1 C6 closed
- [ ] 2.A inventory comments only
- [ ] 2.B types compile, `makeUIView` still inline
- [ ] 2.C cut-over; `viewModel.schemeHandler` passed through (no new handler instance)
- [ ] Test `userScripts.count == 3`
- [ ] Test schemes registered
- [ ] Test UA == `safariUserAgent(for:)`
- [ ] 2.D bridges verbatim; prompts still reach VM; downloads still reach `DownloadService`
- [ ] 2.E no new `WKWebsiteDataStore`
- [ ] Smoke 1–6 plus navigate-then-GUM, download if triggerable, leave-tab-and-return

### Verify

```bash
rg -n "patchScript|constraintLoggingScript|behaviorApplyScript|fslPrompt|fslStatus|fslvideo|fslimage" \
  ios/FaceSwapLiveApp/Views/BrowserWebContainer.swift ios/FaceSwapLiveApp/Browser
```

Reject if JS literal, `LocalResourceHandler`, stealth defaults, or ARKit changed, or scripts merged.

---

## Stage 3 — dual-source product (unfinished)

**Unfinished:** PLAN overlay/badges/quick-assign. Routing fallback already in HEAD.

PLAN.md conflict: separate `fslvideo://front|back` **and** “one video serves both cameras like today.”
HEAD `LocalResourceHandler` ~118–126: `front ?? back`, `back ?? front`, plus `front2`/`back2` chains. Images ~387–395 similar.

Default = **compat + UI**. Strict 404 only with written accept.

### Changes left

- 3.A extract `resolveVideoFileURL` / image resolve, tests pin current `??`
- 3.B camera sheet two sections, toolbar cyan/green dots, saved-video one-tap variant assign
- 3.C optional: delete cross-facing `??`

Do not touch Range / MIME / CORS / EXIF.

### Checklist

- [ ] Stage 2 smoke 1–9 green
- [ ] Choice recorded: `compat` (default) / `strict`
- [ ] 3.A tests: front-only + path back → front URL; both set → own files; none → nil
- [ ] 3.B UI only (no scheme-handler edit in that commit)
- [ ] If strict: `??` gone; front-only + environment ask does not show selfie

### Verify

```bash
rg -n "frontVideoFileURL \?\? backVideoFileURL|backVideoFileURL \?\? frontVideoFileURL" \
  ios/FaceSwapLiveApp/Services/LocalResourceHandler.swift
```

compat: hits remain after 3.B. strict: hits gone after 3.C.

---

## Stage 4 — contract tests (unfinished)

**Unfinished:** entire stage. Production files off-limits.

### Changes left

New tests only:

- Gate matrix: `isAllowedToRun == enabled && stillOnActiveFeed && isForeground && !isCameraNeededElsewhere` (`FaceTrackingController` 81–82)
- `RecapEvent` asked* vs sent* can differ
- `MediaConversionSpec.clamp*` vs profile
- Prompt timeout string `prsec` / `+2500` still in baked or pre-bake script
- After 2.C: `userScripts.count == 3`

### Checklist

- [ ] Commits touch `FaceSwapLiveAppTests/` only
- [ ] Each flag flipped alone → gate false; all true → true
- [ ] Recap does not coerce sentFacing to askedFacing
- [ ] Pipeline test from Stage 1 still present
- [ ] `xcodebuild test` green

### Verify

`git show --stat` lists test files only.

---

## Stage 5 — FacePoseSink (unfinished)

**Unfinished:** entire stage.

Today: `ARKitFaceSource` → `ARKitFaceRelay` → `FaceSourceEvent` → `FaceTrackingController` → `outputPose`.
Do not `evaluateJavaScript` poses.

### Changes left

- `FacePoseSink` protocol aligned to `FaceSourceEvent`
- Controller publishes `outputPose` through it
- Subscribers must not import ARKit

### Checklist

- [ ] Controller still owns `ARSession`
- [ ] `isCameraNeededElsewhere` still the Preview exclusion
- [ ] `FaceTrackingGateTests` extended, not replaced
- [ ] Grep `evaluateJavaScript` together with `outputPose` → 0 hits
- [ ] Smoke 5 still passes

### Verify

```bash
rg -n "evaluateJavaScript" ios/FaceSwapLiveApp | rg -i "pose|FacePose|outputPose" || true
```

---

## Stage 6 — diagnostics wiring (final scheduled stage)

**Unfinished:** single surface for data that already exists.

Exists: `ConstraintLogService` (cap 200), `ConstraintLogView`, `ObservedFeedSnapshot` + `ObservedHUDView`, `SequenceRecap` + `SequenceRecapView`, `DiagnosticsView`, `ExportBundleService`, `FingerprintService` (unpatched lab WebView).

### Changes left

- One diagnostics screen: log + HUD + recap for current host
- Export bundle includes log + recap when non-empty
- Fingerprint labelled unpatched-lab

### Checklist

- [ ] No new page JS
- [ ] HUD still reads `ObservedFeedSnapshot`
- [ ] Recap still asked-vs-sent only
- [ ] Fingerprint copy says lab / unpatched
- [ ] Stage 1 pipeline test + Stage 2 smoke green

### Verify

Session that asked for camera: ConstraintLog shows requested constraints; HUD facing/size match recap `sent*`.

---

## Parked (not unfinished work on this sequence)

Metal compositor, content worlds, forked WebKit, Live Link default, pre-rendered back-slot H.264, IMU / rPPG / visibility synthesis.

---

## Global reject

- JS inside `patchScriptBody`
- Merge the three `WKUserScript`s
- `LocalResourceHandler()` constructed in `makeUIView`
- Rename `fslPrompt` / `fslStatus` / `fslvideo` / `fslimage`
- 30 Hz pose → page

## Stop / revert

Revert last commit if pipeline test goes red, `fslPrompt` hangs, `fslvideo://front` 404s while front file is set, or (after accepted 3-strict) `fslvideo://back` still returns the front file.
