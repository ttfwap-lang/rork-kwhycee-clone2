# Stage 1 closure

Do this before Stage 2.B. Injection JS stays untouched.

## Why this is still open

Branch `stage1/page-patch-assembler` has:

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
- `patchScriptBody` stays `private` in this file.
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

## Step C3 — grep freeze

Expect:

- StyleSheetProvider `patchScript`: zero remaining `__FSL_*` replacingOccurrences
- StyleSheetProvider: one `PatchAssembler.bake`
- BrowserWebContainer: one `StyleSheetProvider.patchScript` as a WKUserScript source
- BrowserWebContainer: constraint + behavior still separate WKUserScripts

## Step C4 — pipeline string proof

Live baked `patchScript` must still contain `captureStream`, GUM, enumerateDevices,
HTMLInputElement.prototype.click, function toString(), `_nat.has(this)`,
`webkit.messageHandlers.fslPrompt`, `fslvideo://`.
Must not contain leftover `__FSL_KEY__` / `__FSL_TOKEN__`.

If `livePatchScriptStillHasInjectionPipeline` is red, revert C1.

## Step C5 — manual smoke

1. Cold launch — profile gate still first.
2. Browser tab, page that never asks for camera — no patch crash.
3. Arm inject, front still loaded — live feed paints.
4. Back slot document still — file path still fills.
5. Preview tab — ARKit gate still releases browser tracking.
6. If `allOff` is reachable — page without getUserMedia still works.

Any fail → `git revert` the C1 commit. Do not edit JS.

## Step C6 — close the stage (with verification)

Check every box. Record the evidence on the right. Stage 1 is closed only when all are checked **and** the verify column is filled.

### C6.1 Commit identity

- [ ] C1 commit exists on `stage1/page-patch-assembler`
- [ ] SHA recorded: `________________`
- [ ] Message is the façade-switch message (or includes “bake through PatchAssembler”)
- [ ] `git show --stat <SHA>` lists **only** `StyleSheetProvider.swift` plus optional delete of `NEXT_FACADE_SWITCH.txt` / tweak of this file
- [ ] `git show <SHA>` does **not** change any line inside the `patchScriptBody` literal (no JS add/delete)

Verify:

```bash
git log -1 --oneline
git show --stat HEAD
git show HEAD -- ios/FaceSwapLiveApp/Services/StyleSheetProvider.swift | rg -n "patchScriptBody|PatchAssembler.bake|replacingOccurrences|captureStream" | head
```

Expect: bake call present; `private static let patchScriptBody` still in the file; no hunk that rewrites JS inside the triple-quoted string.

### C6.2 Bake equivalence

- [ ] `PatchAssembler.bake` replacement order is still NP, HARD, MASK, CAPMODE, KEY, TOKEN
- [ ] Defaults still bake to `false|false|false|auto` (`bakeDefaultStealthMatchesHistoricalBooleans`)
- [ ] `StyleSheetProvider.patchScript` and `PatchAssembler.bake(patchScriptBody, stealth:default, key:fslStateKeySuffix, token:fslStateToken)` would be equal — proven by C1 calling bake with those exact arguments

Verify: open `PatchAssembler.swift` and confirm six `replacingOccurrences` match HEAD names `__FSL_NP__` `__FSL_HARD__` `__FSL_MASK__` `__FSL_CAPMODE__` `__FSL_KEY__` `__FSL_TOKEN__`.

### C6.3 Automated tests

- [ ] C2 command run on this machine
- [ ] Destination used: `________________`
- [ ] `PatchAssemblerTests` 4/4 pass
- [ ] `FaceTrackingGateTests` pass
- [ ] `PoseMathTests` pass
- [ ] `LiveLinkFacePacketTests` pass
- [ ] No new test failures vs `fc1df3c`

Verify: save the `xcodebuild` last lines (failed/passed counts). Red suite → Stage 1 not closed.

### C6.4 Grep freeze

- [ ] C3 expect-list matches working tree after C1
- [ ] `rg "StyleSheetProvider.patchScript" ios/FaceSwapLiveApp/Views/BrowserWebContainer.swift` → one WKUserScript source
- [ ] `userScripts` still three (patch, constraint, behavior)

Verify commands and expected hits are in C3. Paste output next to this box when closing.

### C6.5 Pipeline strings

- [ ] C4 list still present in **baked** `patchScript` (the test, not a visual skim of the source literal)
- [ ] Baked script contains `fslStateKeySuffix` and `fslStateToken` values, not the placeholders

Verify: passing `livePatchScriptStillHasInjectionPipeline` is the evidence. Do not close C6 if that test was skipped.

### C6.6 Smoke sign-off

| # | Check | Build | Result | Initials |
|---|---|---|---|---|
| 1 | Cold launch / profile gate | | pass / fail | |
| 2 | Inert page, no camera ask | | pass / fail | |
| 3 | Front still inject paints | | pass / fail | |
| 4 | Back file slot fills | | pass / fail | |
| 5 | Preview ARKit gate | | pass / fail | |
| 6 | allOff inert page (if reachable) | | pass / fail / n/a | |

- [ ] All required rows pass (6 may be n/a)
- [ ] Failures reverted C1 (`git revert <C1 SHA>`) instead of editing JS

### C6.7 PR hygiene

- [ ] https://github.com/ttfwap-lang/rork-kwhycee-clone2/pull/1 points at the C1 SHA
- [ ] PR description notes “JS literal unchanged; bake routed”
- [ ] Draft cleared only after C6.3 and C6.6 pass
- [ ] `NEXT_FACADE_SWITCH.txt` deleted or marked consumed in the C1 commit

### C6.8 Hard stop — do not close if

- [ ] `LocalResourceHandler.swift` changed in the closure commits
- [ ] Any ARKit file changed
- [ ] `MediaBehaviorSettings.default` changed
- [ ] `BrowserWebContainer` user-script count changed
- [ ] `xcodebuild test` was not run
- [ ] Smoke row 3 or 4 failed

If any hard-stop box is true, Stage 1 stays open.

## Explicitly not closure

- Moving `patchScriptBody` into `PatchAssembler.rawBody`
- Splitting the IIFE into kernel / compositor files
- `FSLWebView` / process pool (Stage 2)
- Strict `fslvideo://` 404s (Stage 3)
- Any edit inside the JS literal

## Next

Stage 2.B empty types under `ios/FaceSwapLiveApp/Browser/`.
Full program: `STAGE_PROGRAM.md`.
