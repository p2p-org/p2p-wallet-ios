import Combine
import Foundation
import SolanaSwift

/// Default implementation for RelayContextManager
public class RelayContextManagerImpl: RelayContextManager {
    // MARK: - Dependencies

    /// Solana account storage
    private let accountStorage: SolanaAccountStorage

    /// Solana APIClient
    private let solanaAPIClient: SolanaAPIClient

    /// FeeRelayerAPIClient
    private let feeRelayerAPIClient: FeeRelayerAPIClient

    // MARK: - Properties

    /// Subject to handle context data flow
    private let contextSubject = CurrentValueSubject<RelayContext?, Never>(nil)

    /// Current RelayContext
    public var currentContext: RelayContext? { contextSubject.value }

    /// Publisher for current RelayContext
    public var contextPublisher: AnyPublisher<RelayContext?, Never> { contextSubject.eraseToAnyPublisher() }

    /// Updating task
    private var updatingTask: Task<RelayContext, Error>?

    // MARK: - Initializer

    public init(
        accountStorage: SolanaAccountStorage,
        solanaAPIClient: SolanaAPIClient,
        feeRelayerAPIClient: FeeRelayerAPIClient
    ) {
        self.accountStorage = accountStorage
        self.solanaAPIClient = solanaAPIClient
        self.feeRelayerAPIClient = feeRelayerAPIClient
    }

    // MARK: - Methods

    /// Update current context
    @discardableResult
    public func update() async throws -> RelayContext {
        // cancel current task
        updatingTask?.cancel()

        // assign task
        updatingTask = Task { [unowned self] () -> RelayContext in
            // assertion
            guard let account = accountStorage.account
            else { throw RelayContextManagerError.invalidContext }

            // retrieve RelayContext
            async let minimumRelayAccountBalance = solanaAPIClient
                .getMinimumBalanceForRentExemption(span: 0)
            async let lamportsPerSignature = solanaAPIClient
                .getFees(commitment: nil).feeCalculator?
                .lamportsPerSignature
            async let feePayerAddress = feeRelayerAPIClient.getFeePayerPubkey()
            async let relayAccountStatus = solanaAPIClient
                .getRelayAccountStatus(
                    RelayProgram
                        .getUserRelayAddress(
                            user: account.publicKey,
                            network: solanaAPIClient.endpoint.network
                        )
                        .base58EncodedString
                )
            async let usageStatus = feeRelayerAPIClient
                .getFreeFeeLimits(for: account.publicKey.base58EncodedString)
                .asUsageStatus()

            return try await RelayContext(
                minimumRelayAccountBalance: minimumRelayAccountBalance,
                feePayerAddress: PublicKey(string: feePayerAddress),
                lamportsPerSignature: lamportsPerSignature ?? 5000,
                relayAccountStatus: relayAccountStatus,
                usageStatus: usageStatus
            )
        }

        // execute task
        guard let result = try await updatingTask?.value else {
            throw RelayContextManagerError.invalidContext
        }

        // mark as completed
        contextSubject.send(result)
        return result
    }

    /// Modify context locally
    public func replaceContext(by context: RelayContext) {
        contextSubject.send(context)
    }
}

extension FeeLimitForAuthorityResponse {
    func asUsageStatus() -> UsageStatus {
        UsageStatus(
            maxUsage: limits.maxFeeCount,
            currentUsage: processedFee.feeCount,
            maxAmount: limits.maxFeeAmount,
            amountUsed: processedFee.totalFeeAmount,
            reachedLimitLinkCreation: processedFee.rentCount >= limits.maxTokenAccountCreationCount || processedFee
                .feeCount >= limits.maxFeeCount
        )
    }
}
