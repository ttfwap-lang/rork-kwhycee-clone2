import Foundation
import Testing
@testable import FaceSwapLiveApp

/// Stage 1 gates: bake is byte-stable, and the live injection script still
/// contains the pipeline the page depends on. Does not require a relocated body.
struct PatchAssemblerTests {
    @Test func bakeReplacesPlaceholdersOnly() {
        let sample = "np=__FSL_NP__ hard=__FSL_HARD__ mask=__FSL_MASK__ mode=__FSL_CAPMODE__ key=__FSL_KEY__ tok=__FSL_TOKEN__ keep=captureStream"
        let baked = PatchAssembler.bake(
            sample,
            stealth: .default,
            key: "KEYKEYKEYKEYKEYK",
            token: "TOKENTOKENTOKENTOKENTOKE"
        )
        #expect(baked == "np=false hard=false mask=false mode=auto key=KEYKEYKEYKEYKEYK tok=TOKENTOKENTOKENTOKENTOKE keep=captureStream")
        #expect(!baked.contains("__FSL_"))
    }

    @Test func livePatchScriptStillHasInjectionPipeline() {
        let script = StyleSheetProvider.patchScript(stealth: .default)
        #expect(script.contains("captureStream"))
        #expect(script.contains("MediaDevices.prototype.getUserMedia"))
        #expect(script.contains("MediaDevices.prototype.enumerateDevices"))
        #expect(script.contains("HTMLInputElement.prototype.click"))
        #expect(script.contains("function toString()"))
        #expect(script.contains("_nat.has(this)"))
        #expect(script.contains("webkit.messageHandlers.fslPrompt"))
        #expect(script.contains("fslvideo://"))
        #expect(!script.contains("__FSL_KEY__"))
        #expect(!script.contains("__FSL_TOKEN__"))
        #expect(script.contains(StyleSheetProvider.fslStateKeySuffix))
        #expect(script.contains(StyleSheetProvider.fslStateToken))
    }

    @Test func constraintLogRemainsASecondUserScript() {
        let patch = StyleSheetProvider.patchScript(stealth: .default)
        let log = StyleSheetProvider.constraintLoggingScript
        #expect(patch != log)
        #expect(log.contains("_constraintLog"))
    }

    @Test func bakeDefaultStealthMatchesHistoricalBooleans() {
        // HEAD defaults: nativePicker off, hardening off, mask off, policy auto.
        let baked = PatchAssembler.bake(
            "__FSL_NP__|__FSL_HARD__|__FSL_MASK__|__FSL_CAPMODE__",
            stealth: .default,
            key: "k",
            token: "t"
        )
        #expect(baked == "false|false|false|auto")
    }
}
