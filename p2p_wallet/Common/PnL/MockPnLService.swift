import Foundation
import PnLService
import SolanaSwift

struct MockPnLModel: PnLModel {
    let total: RPCPnLResponseDetail?
    let pnlByMint: [String: RPCPnLResponseDetail]
}

class MockPnLService: PnLService {
    func getPNL(userWallet _: String, mints _: [String]) async throws -> MockPnLModel {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return .init(
            total: .init(usdAmount: "+1.23", percent: "-1.2"),
            pnlByMint: [
                "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263": .init(usdAmount: "-5", percent: "-5"),
                "EjChnoTPcQ9DxKZkBM7g1M4DBF4J2Mx75CYTPoDZyYXB": .init(usdAmount: "-2.2", percent: "-2.2"),
                "7SdFACfxmg2eetZEhEYZhsNMVAu84USVtfJ64jFDCg9Y": .init(usdAmount: "-1.1", percent: "-1.1"),
                "98eKvPL8rJeFPVLft3JMfsCn1Yi9UN7MmG2htMQ4t4FS": .init(usdAmount: "-3.3", percent: "-3.3"),
                "EchesyfXePKdLtoiZSL8pBe8Myagyy8ZRqsACNCFGnvp": .init(usdAmount: "+4.4", percent: "+4.4"),
                "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB": .init(usdAmount: "-6.6", percent: "-6.6"),
                "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": .init(usdAmount: "+7.7", percent: "+7.7"),
                "JET6zMJWkCN9tpRT2v2jfAmm5VnQFDpUBCyaKojmGtz": .init(usdAmount: "-8.8", percent: "-8.8"),
                "3NZ9JMVBmGAqocybic2c7LQCJScmgsAZ6vQqTDzcqmJh": .init(usdAmount: "-9.9", percent: "-9.9"),
                "2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk": .init(usdAmount: "-10.1", percent: "-10.1"),
            ]
        )
    }
}
