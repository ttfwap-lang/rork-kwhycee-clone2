import Foundation

/// Stage 1 assembler. Bake rules are copied from HEAD `StyleSheetProvider.patchScript`.
///
/// The historical document-start source still lives on `StyleSheetProvider` so the
/// injection pipeline cannot drift while the body is relocated. `rawBody` is the
/// pre-bake source when a later commit moves the literal; until then tests pin
/// the live `StyleSheetProvider.patchScript` surfaces instead of a second copy.
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

    nonisolated static func patchScript(
        stealth: StyleSheetProvider.StealthOptions,
        key: String,
        token: String,
        body: String
    ) -> String {
        bake(body, stealth: stealth, key: key, token: token)
    }
}
