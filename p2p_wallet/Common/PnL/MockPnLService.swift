import Foundation
import PnLService
import SolanaSwift

struct MockPnLModel: PnLModel {
    let total: Double
    let pnlByMint: [String: Double]
}

class MockPnLService: PnLService {
    func getPNL() async throws -> MockPnLModel {
        try await Task.sleep(nanoseconds: 300_000_000)
        return .init(
            total: 1.2,
            pnlByMint: [
                PublicKey.wrappedSOLMint.base58EncodedString: 4,
                "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263": -5,
                "EjChnoTPcQ9DxKZkBM7g1M4DBF4J2Mx75CYTPoDZyYXB": -2.2,
                "7SdFACfxmg2eetZEhEYZhsNMVAu84USVtfJ64jFDCg9Y": 3,
                "98eKvPL8rJeFPVLft3JMfsCn1Yi9UN7MmG2htMQ4t4FS": 3.4,
                "EchesyfXePKdLtoiZSL8pBe8Myagyy8ZRqsACNCFGnvp": -2.3,
                "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB": 2.1,
                "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": 1,
                "JET6zMJWkCN9tpRT2v2jfAmm5VnQFDpUBCyaKojmGtz": 3.7,
                "3NZ9JMVBmGAqocybic2c7LQCJScmgsAZ6vQqTDzcqmJh": 2.3,
                "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk": -1.8,
            ]
        )
    }
}
