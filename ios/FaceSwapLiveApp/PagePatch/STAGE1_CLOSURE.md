# Stage 1 closure

Do this before Stage 2.B. Injection JS stays untouched.

## Why this is still open

Branch `stage1/page-patch-assembler` @ last plan SHA has:

- `PatchTokens.swift` — landed
- `PatchAssembler.bake` — landed
- `PatchAssemblerTests` pinning live `patchScript` surfaces — landed
- `StyleSheetProvider.patchScript(stealth:)` still uses the in-place six `replacingOccurrences`
- `patchScriptBody` still private on `StyleSheetProvider` (correct — do not move it in closure)
- `xcodebuild test` not run in the planning environment
- Manual smoke not run

Closure is the façade switch + proof the live pipeline still exists.

## Step C1 — façade switch (only edit)

File: `ios/FaceSwapLiveApp/Services/StyleSheetProvider.swift`

Replace the body of `static func patchScript(stealth: StealthOptions) -> String` with:

```swift
        return PatchAssembler.bake(
            patchScriptBody,
            stealth: stealth,
            key: fslStateKeySuffix,
            token: fslStateToken
        )
```

Rules:

- Do not edit the `patchScriptBody` literal.
- Do not change `StealthOptions.default`.
- Do not change `fslStateKeySuffix` / `fslStateToken` generation.
- `patchScriptBody` stays `private` in this file (visible to the call above).
- `static var patchScript` stays `{ patchScript(stealth: .default) }`.
- `BrowserWebContainer` stays on `StyleSheetProvider.patchScript`.

Commit message:

```
stage1: route patchScript bake through PatchAssembler

Same six substitutions. JS literal unchanged.
```

## Step C2 — compile + unit tests

```bash
cd ios
xcodebuild -scheme FaceSwapLiveApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Must stay green:

- `PatchAssemblerTests.bakeReplacesPlaceholdersOnly`
- `PatchAssemblerTests.livePatchScriptStillHasInjectionPipeline`
- `PatchAssemblerTests.constraintLogRemainsASecondUserScript`
- `PatchAssemblerTests.bakeDefaultStealthMatchesHistoricalBooleans`
- `FaceTrackingGateTests`
- `PoseMathTests`
- `LiveLinkFacePacketTests`

If the simulator name differs, list devices and substitute. Do not skip the test target.

## Step C3 — grep freeze

```bash
rg -n "replacingOccurrences\(of: \"__FSL_" ios/FaceSwapLiveApp/Services/StyleSheetProvider.swift
rg -n "PatchAssembler.bake" ios/FaceSwapLiveApp/Services/StyleSheetProvider.swift
rg -n "StyleSheetProvider.patchScript" ios/FaceSwapLiveApp/Views/BrowserWebContainer.swift
rg -n "constraintLoggingScript|behaviorApplyScript" ios/FaceSwapLiveApp/Views/BrowserWebContainer.swift
```

Expect:

- StyleSheetProvider: **zero** remaining `__FSL_*` replacingOccurrences in `patchScript`
- StyleSheetProvider: **one** `PatchAssembler.bake`
- BrowserWebContainer: **one** `StyleSheetProvider.patchScript` as a `WKUserScript` source
- BrowserWebContainer: constraint + behavior scripts still separate `WKUserScript`s

## Step C4 — pipeline string proof

After C1, `StyleSheetProvider.patchScript(stealth: .default)` must still contain:

- `captureStream`
- `MediaDevices.prototype.getUserMedia`
- `MediaDevices.prototype.enumerateDevices`
- `HTMLInputElement.prototype.click`
- `function toString()`
- `_nat.has(this)`
- `webkit.messageHandlers.fslPrompt`
- `fslvideo://`

and must **not** contain leftover `__FSL_KEY__` / `__FSL_TOKEN__` (those are replaced with the process UUIDs).

This is what `livePatchScriptStillHasInjectionPipeline` asserts. If that test is red, revert C1.

## Step C5 — manual smoke (device or sim)

Same build as C2.

1. Cold launch — profile gate still first.
2. Browser tab, page that never asks for camera — no patch crash (`MediaDevices` early return still first).
3. Arm inject, front still loaded — live feed paints (`captureStream` path).
4. Back slot document still — file / `files` path still fills.
5. Preview tab — ARKit gate still releases browser tracking.
6. If `allOff` is reachable — page without getUserMedia still works.

Any fail → `git revert` the C1 commit. Do not “fix” JS.

## Step C6 — close the stage

- [ ] C1 committed on `stage1/page-patch-assembler`
- [ ] C2 green
- [ ] C3 grep matches expect
- [ ] C5 smoke 1–6 signed off
- [ ] PR https://github.com/ttfwap-lang/rork-kwhycee-clone2/pull/1 updated (undraft when C2+C5 pass)
- [ ] `NEXT_FACADE_SWITCH.txt` can be deleted in the same PR as C1 (instructions consumed)

Stage 1 is closed only when every box above is checked.

## Explicitly not closure

- Moving `patchScriptBody` into `PatchAssembler.rawBody`
- Splitting the IIFE into kernel / compositor files
- `FSLWebView` / process pool (Stage 2)
- Strict `fslvideo://` 404s (Stage 3)
- Any edit inside the JS literal

## Next

Stage 2.B empty types under `ios/FaceSwapLiveApp/Browser/`.
