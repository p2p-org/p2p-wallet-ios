import Foundation
import SolanaSwift

struct MockTokensRepository: TokenRepository {
    func get(address: String) async throws -> TokenMetadata? {
        (try await tokensList)
            .first { token in
                token.address == address
            }
    }

    func get(addresses: [String]) async throws -> [String: TokenMetadata] {
        let result = (try await tokensList)
            .filter { tokenMetadata in
                addresses.contains(tokenMetadata.address)
            }
            .map { tokenMetadata in
                (tokenMetadata.address, tokenMetadata)
            }

        return Dictionary(result) { lhs, _ in
            lhs
        }
    }

    func all() async throws -> Set<TokenMetadata> {
        try await tokensList
    }

    func reset() async throws {}

    var tokensList: Set<TokenMetadata> {
        get async throws {
            let string =
                #"[{"chainId":101,"address":"2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk","symbol":"soETH","name":"Wrapped Ethereum (Sollet)","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk/logo.png","tags":["wrapped-sollet","ethereum"],"extensions":{"bridgeContract":"https://etherscan.io/address/0xeae57ce9cc1984f202e15e038b964bb8bdf7229a","coingeckoId":"ethereum","serumV3Usdc":"4tSvZvnbyzHXLMTiFonMyxZoHmFqau1XArcRCVHLZ5gX","serumV3Usdt":"7dLVkUfBVfCGkFhSXDCq1ukM9usathSgS716t643iFGF"}},{"chainId":101,"address":"BLwTnYKqf7u4qjgZrrsKeNs2EzWkMLqVCu6j8iHyrNA3","symbol":"BOP","name":"Boring Protocol","decimals":8,"logoURI":"https://raw.githubusercontent.com/boringprotocol/brand-assets/main/boplogo.png","tags":["security-token","utility-token"],"extensions":{"coingeckoId":"boring-protocol","serumV3Usdc":"7MmPwD1K56DthW14P1PnWZ4zPCbPWemGs3YggcT1KzsM","twitter":"https://twitter.com/BoringProtocol","website":"https://boringprotocol.io"}},{"chainId":101,"address":"SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt","symbol":"SRM","name":"Serum","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt/logo.png","extensions":{"coingeckoId":"serum","serumV3Usdc":"ByRys5tuUWDgL73G8JBAEfkdFf8JWBzPBDHsBVQ5vbQA","serumV3Usdt":"AtNnsY1AyRERWJ8xCskfz38YdvruWVJQUVXgScC1iPb","waterfallbot":"https://bit.ly/SRMwaterfall","website":"https://projectserum.com/"}},{"chainId":101,"address":"So11111111111111111111111111111111111111112","symbol":"SOL","name":"Wrapped SOL","decimals":9,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png","extensions":{"coingeckoId":"solana","serumV3Usdc":"9wFFyRfZBsuAha4YcuxcXLKwMxJR43S7fPfQLusDBzvT","serumV3Usdt":"HWHvQhFmJB3NUcu1aihKmrKegfVxBEHzwVX6yZCKEsi1","website":"https://solana.com/"}},{"chainId":101,"address":"xxxxa1sKNGwFtw2kFn8XauW9xq8hBZ5kVtcSesTT9fW","symbol":"SLIM","name":"Solanium","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/xxxxa1sKNGwFtw2kFn8XauW9xq8hBZ5kVtcSesTT9fW/logo.png","extensions":{"coingeckoId":"solanium","telegram":"https://t.me/solanium_io","twitter":"https://twitter.com/solanium_io","website":"https://www.solanium.io/"}},{"chainId":101,"address":"kinXdEcpDQeHPEuQnqmUgtYykqKGVFq6CeVX5iAHJq6","symbol":"KIN","name":"KIN","decimals":5,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/kinXdEcpDQeHPEuQnqmUgtYykqKGVFq6CeVX5iAHJq6/logo.png","extensions":{"coingeckoId":"kin","serumV3Usdc":"Bn6NPyr6UzrFAwC4WmvPvDr2Vm8XSUnFykM2aQroedgn","serumV3Usdt":"4nCFQr8sahhhL4XJ7kngGFBmpkmyf3xLzemuMhn6mWTm","waterfallbot":"https://bit.ly/KINwaterfall"}},{"chainId":101,"address":"BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4","symbol":"soUSDT","name":"Wrapped USDT (Sollet)","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4/logo.png","tags":["stablecoin","wrapped-sollet","ethereum"],"extensions":{"bridgeContract":"https://etherscan.io/address/0xeae57ce9cc1984f202e15e038b964bb8bdf7229a","coingeckoId":"tether"}},{"chainId":101,"address":"MAPS41MDahZ9QdKXhVa4dWB9RuyfV4XqhyAZ8XcYepb","symbol":"MAPS","name":"MAPS","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/MAPS41MDahZ9QdKXhVa4dWB9RuyfV4XqhyAZ8XcYepb/logo.svg","extensions":{"coingeckoId":"maps","serumV3Usdc":"3A8XQRWXC7BjLpgLDDBhQJLT5yPCzS16cGYRKHkKxvYo","serumV3Usdt":"7cknqHAuGpfVXPtFoJpFvUjJ8wkmyEfbFusmwMfNy3FE","website":"https://maps.me/"}},{"chainId":101,"address":"4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R","symbol":"RAY","name":"Raydium","decimals":6,"logoURI":"https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R/logo.png","extensions":{"coingeckoId":"raydium","serumV3Usdc":"2xiv8A5xrJ7RnGdxXB42uFEkYHJjszEhaJyKKt4WaLep","serumV3Usdt":"teE55QrL4a4QSfydR9dnHF97jgCfptpuigbb53Lo95g","waterfallbot":"https://bit.ly/RAYwaterfall","website":"https://raydium.io/"}}]"#
            let array = try! JSONDecoder().decode([Token].self, from: string.data(using: .utf8)!)
            return Set<Token>(array)
        }
    }
}
