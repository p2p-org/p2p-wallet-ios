import KeyAppNetworking
import Send
import XCTest

final class SendServiceDecodingTests: XCTestCase {
    func testDecodeSendNativeSOL() throws {
        let string =
            #"{"jsonrpc":"2.0","result":{"transaction":"AuIJPXVfWmPskDfpkUAYvK2zZCpJkm5fwZzGHX1uqApsOoC4oDd081OgbCN93ogVB9EdgHOJx58PnKPV9MfQbw0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAIAAQR90Nyx8Am1DqD8h95IrLRdA/EOx9xZ0+aoK4Ubo9i3rjXMoULHbQPaQXtf+MQyHT2yBirIGtomTUNawXBpR9CQ+t0H9VtWSOXB+PGSGvN8EFyeoKN9mPjNV0IuOz6a/1sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHIa/xnWYFgO8Fv9uxHNSVA5j2CYnfpcblQsprOJJRlvAQMCAQIMAgAAAKCGAQAAAAAAAA==","blockhash":"8gRMVkppfRMbnh7K8ibAdcmtjmWfAVFU8BGLhWy3ShVp","expires_at":1705496596,"signature":"5X7YKgB56ft7rR7Mfp8hAUaZ35LqZ2dwgYNBktnxeB9zPvamWj1hnxD4XU4J6bqsYVFnbbukMoRhajJjvtCwUay2","recipient_gets_amount":{"amount":"100000","usd_amount":"0.010129673906569876","address":"So11111111111111111111111111111111111111112","symbol":"SOL","name":"Solana","decimals":9,"logo_url":"https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","coingecko_id":"solana","price":{"usd":"101.29673906569876"}},"total_amount":{"amount":"100000","usd_amount":"0.010129673906569876","address":"So11111111111111111111111111111111111111112","symbol":"SOL","name":"Solana","decimals":9,"logo_url":"https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","coingecko_id":"solana","price":{"usd":"101.29673906569876"}},"network_fee":{"source":"ServiceCoverage","amount":{"amount":"10000","usd_amount":"0.0010129673906569876","address":"So11111111111111111111111111111111111111112","symbol":"SOL","name":"Solana","decimals":9,"logo_url":"https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","coingecko_id":"solana","price":{"usd":"101.29673906569876"}}}},"id":"395B32BA-C235-4C34-8F47-D73AA5D3C9E7"}"#

        try JSONDecoder().decode(
            JSONRPCResponseDto<SendServiceTransferResponse>.self,
            from: string.data(using: .utf8)!
        )
    }
}
