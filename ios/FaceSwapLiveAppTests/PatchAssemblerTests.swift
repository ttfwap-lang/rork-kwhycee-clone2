import Foundation
import Testing
@testable import FaceSwapLiveApp

/// Stage 1: the assembler must emit the historical document-start script.
/// Compares against a HEAD fixture so a JS edit cannot slip in as a "refactor".
struct PatchAssemblerTests {
    private func fixtureBody() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/patchScriptBody.head.txt")
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test func rawBodyMatchesHeadFixture() throws {
        let expected = try fixtureBody()
        #expect(PatchAssembler.rawBody == expected)
    }

    @Test func placeholdersSurviveJoin() throws {
        let body = PatchAssembler.body()
        for token in [
            PatchTokens.np, PatchTokens.hard, PatchTokens.mask,
            PatchTokens.capMode, PatchTokens.key, PatchTokens.token,
        ] {
            #expect(body.contains(token), "missing \(token)")
        }
    }

    @Test func loadBearingSurfacesPresent() {
        let body = PatchAssembler.body()
        #expect(body.contains("captureStream"))
        #expect(body.contains("MediaDevices.prototype.getUserMedia"))
        #expect(body.contains("MediaDevices.prototype.enumerateDevices"))
        #expect(body.contains("HTMLInputElement.prototype.click"))
        #expect(body.contains("function toString()"))
        #expect(body.contains("_nat.has(this)"))
        #expect(body.contains("webkit.messageHandlers.fslPrompt"))
        #expect(body.contains("fslvideo://"))
    }

    @Test func patchScriptAndConstraintLogRemainDistinct() {
        #expect(StyleSheetProvider.patchScript(stealth: .default) != StyleSheetProvider.constraintLoggingScript)
        #expect(StyleSheetProvider.constraintLoggingScript.contains("_constraintLog"))
    }

    @Test func bakeReplacesAllPlaceholdersAndKeepsPipeline() {
        let baked = PatchAssembler.bake(
            PatchAssembler.body(),
            stealth: .default,
            key: "KEYKEYKEYKEYKEYK",
            token: "TOKENTOKENTOKENTOKENTOKE"
        )
        #expect(!baked.contains("__FSL_"))
        #expect(baked.contains("KEYKEYKEYKEYKEYK"))
        #expect(baked.contains("TOKENTOKENTOKENTOKENTOKE"))
        #expect(baked.contains("captureStream"))
        #expect(baked.contains("MediaDevices.prototype.getUserMedia"))
    }

    @Test func facadeBakeMatchesAssembler() {
        let a = PatchAssembler.patchScript(
            stealth: .default,
            key: StyleSheetProvider.fslStateKeySuffix,
            token: StyleSheetProvider.fslStateToken
        )
        let b = StyleSheetProvider.patchScript(stealth: .default)
        #expect(a == b)
    }
}
