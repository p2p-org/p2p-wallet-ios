import SolanaSwift

public struct OnboardingWallet: Codable, Equatable {
    public let seedPhrase: String
    public let derivablePath: DerivablePath

    init(seedPhrase: String, derivablePath: DerivablePath? = nil) {
        self.seedPhrase = seedPhrase
        self.derivablePath = derivablePath ?? .default
    }
}
