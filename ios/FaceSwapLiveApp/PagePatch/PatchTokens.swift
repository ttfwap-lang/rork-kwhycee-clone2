import Foundation

/// Bake placeholders. Names are load-bearing for `patchScript` and the page-side
/// `Symbol.for` guard. Do not rename without updating `PatchAssembler.bake` and tests.
nonisolated enum PatchTokens {
    static let np = "__FSL_NP__"
    static let hard = "__FSL_HARD__"
    static let mask = "__FSL_MASK__"
    static let capMode = "__FSL_CAPMODE__"
    static let key = "__FSL_KEY__"
    static let token = "__FSL_TOKEN__"
}
