import Foundation

/// Bake rules copied from HEAD `StyleSheetProvider.patchScript`.
/// Pre-bake JS still lives on `StyleSheetProvider.patchScriptBody` until Stage 1 C1
/// routes that function through `bake`. There is no second copy of the literal here.
nonisolated enum PatchAssembler {
    nonisolated static func bake(
        _ body: String,
        stealth: StyleSheetProvider.StealthOptions,
        key: String,
        token: String
    ) -> String {
        body
            .replacingOccurrences(of: PatchTokens.np, with: stealth.nativePickerMode ? "true" : "false")
            .replacingOccurrences(of: PatchTokens.hard, with: stealth.accessorHardening ? "true" : "false")
            .replacingOccurrences(of: PatchTokens.mask, with: stealth.maskWrappersAsNative ? "true" : "false")
            .replacingOccurrences(of: PatchTokens.capMode, with: stealth.captureButtonPolicy)
            .replacingOccurrences(of: PatchTokens.key, with: key)
            .replacingOccurrences(of: PatchTokens.token, with: token)
    }
}
