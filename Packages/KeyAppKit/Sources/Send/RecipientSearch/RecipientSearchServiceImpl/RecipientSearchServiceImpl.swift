import Foundation
import NameService
import OrcaSwapSwift
import SolanaSwift
import Wormhole

public class RecipientSearchServiceImpl: RecipientSearchService {
    let nameService: NameService
    let solanaClient: SolanaAPIClient
    let feeCalculator: SendFeeCalculator
    let orcaSwap: OrcaSwapType

    public init(
        nameService: NameService,
        solanaClient: SolanaAPIClient,
        feeCalculator: SendFeeCalculator,
        orcaSwap: OrcaSwapType
    ) {
        self.nameService = nameService
        self.solanaClient = solanaClient
        self.feeCalculator = feeCalculator
        self.orcaSwap = orcaSwap
    }

    public func search(
        input: String,
        config: RecipientSearchConfig,
        preChosenToken: TokenMetadata?
    ) async -> RecipientSearchResult {
        // Assertion
        guard !input.isEmpty else {
            return .ok([])
        }

        // Validate ethereum address.
        if config.ethereumSearch, EthereumAddressValidation.validate(input) {
            // Check self-sending
            if config.ethereumAccount == input.lowercased() {
                return .selfSendingError(
                    recipient: .init(address: input, category: .ethereumAddress, attributes: [])
                )
            }

            // Ok
            return .ok([
                .init(address: input, category: .ethereumAddress, attributes: []),
            ])
        }

        // Search by solana address
        if !input.contains(" "), let address = try? PublicKey(string: input), !address.bytes.isEmpty {
            return await searchBySolanaAddress(address, config: config, preChosenToken: preChosenToken)
        }

        // Search by name
        return await searchByName(input, config: config)
    }
}
