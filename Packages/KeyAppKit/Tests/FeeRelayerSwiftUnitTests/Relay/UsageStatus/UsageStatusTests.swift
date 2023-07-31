import XCTest
import FeeRelayerSwift
import SolanaSwift

final class UsageStatusTests: XCTestCase {
    let maxUsage = 100
    let maxAmount: Lamports = 10_000_000
    
    func testFreeTransactionFeeAvailable() {
        let transactionFee: Lamports = .random(in: 0..<minimumTokenAccountBalance)
        
        let usageStatus = UsageStatus(
            maxUsage: maxUsage,
            currentUsage: .random(in: 0..<maxUsage), // less than maxUsage
            maxAmount: maxAmount,
            amountUsed: .random(in: 0..<(maxAmount - transactionFee)),
            reachedLimitLinkCreation: false
        )
        
        XCTAssertEqual(
            usageStatus.isFreeTransactionFeeAvailable(transactionFee: transactionFee),
            true
        )
    }
    
    func testFreeTransactionFeeIsNotAvailableBecauseOfExceedingMaxUsage() {
        let transactionFee: Lamports = .random(in: 0..<minimumTokenAccountBalance)
        
        let usageStatus = UsageStatus(
            maxUsage: maxUsage,
            currentUsage: .random(in: maxUsage..<maxUsage+100), // more than maxUsage
            maxAmount: maxAmount,
            amountUsed: .random(in: 0..<(maxAmount - transactionFee)), // amountUsed + transactionFee is less than maxAmount
            reachedLimitLinkCreation: true
        )
        
        XCTAssertEqual(
            usageStatus.isFreeTransactionFeeAvailable(transactionFee: transactionFee),
            false
        )
    }
    
    func testFreeTransactionFeeIsNotAvailableBecauseOfExceedingMaxAmount() {
        let transactionFee: Lamports = .random(in: 0..<minimumTokenAccountBalance)
        
        let usageStatus = UsageStatus(
            maxUsage: maxUsage,
            currentUsage: .random(in: 0..<maxUsage), // less than maxUsage
            maxAmount: maxAmount,
            amountUsed: .random(in: maxAmount..<(maxAmount + transactionFee)), // amountUsed + transactionFee is more than maxAmount
            reachedLimitLinkCreation: true
        )
        
        XCTAssertEqual(
            usageStatus.isFreeTransactionFeeAvailable(transactionFee: transactionFee),
            false
        )
    }
}
