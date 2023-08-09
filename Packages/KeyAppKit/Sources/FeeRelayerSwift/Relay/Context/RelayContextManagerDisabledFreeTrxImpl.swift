import Combine
import Foundation
import SolanaSwift

/// Implementation for RelayContextManager for testing disabled free transaction only
public class RelayContextManagerDisabledFreeTrxImpl: RelayContextManagerImpl {
    @discardableResult
    override public func update() async throws -> RelayContext {
        var context = try await super.update()
        context.usageStatus = .init(
            maxUsage: 100,
            currentUsage: 100,
            maxAmount: 1_000_000,
            amountUsed: 1_000_000,
            reachedLimitLinkCreation: true
        )
        return context
    }

    override public func replaceContext(by context: RelayContext) {
        var context = context
        context.usageStatus = .init(
            maxUsage: 100,
            currentUsage: 100,
            maxAmount: 1_000_000,
            amountUsed: 1_000_000,
            reachedLimitLinkCreation: true
        )
        super.replaceContext(by: context)
    }
}
