import Foundation
import FeeRelayerSwift
import Resolver
import SolanaSwift

final class FeeRelayerDebugViewModel: BaseViewModel, ObservableObject {
    @Injected private var contextManager: RelayContextManager
    private let feeInSOL: FeeAmount
    private let feeInToken: FeeAmount
    private let payingFeeTokenDecimals: Decimals
    
    @Published var calculationDebugText: String = ""
    
    init(
        feeInSOL: FeeAmount,
        feeInToken: FeeAmount,
        payingFeeTokenDecimals: Decimals
    ) {
        self.feeInSOL = feeInSOL
        self.feeInToken = feeInToken
        self.payingFeeTokenDecimals = payingFeeTokenDecimals
        super.init()
        bind()
    }
    
    private func bind() {
        contextManager.contextPublisher
            .receive(on: RunLoop.main)
            .map { [weak self] in
                guard let self else { return "" }
                return self.getCalculationDebugText(relayContext: $0)
            }
            .assign(to: \.calculationDebugText, on: self)
            .store(in: &subscriptions)
    }
    
    private func getCalculationDebugText(relayContext context: RelayContext?) -> String {
        guard let context else { return "RelayContext missing" }
        let relayAccountStatus = context.relayAccountStatus
        let relayAccountBalance = context.relayAccountStatus.balance ?? 0
        let minRelayAccountBalance = context.minimumRelayAccountBalance
        let feeInSOL = feeInSOL.total
        let feeInToken = feeInToken.total
        let exchangeRate: Double
        
        if feeInSOL != 0 {
            exchangeRate = feeInToken.convertToBalance(decimals: payingFeeTokenDecimals) / feeInSOL.convertToBalance(decimals: 9)
        } else {
            exchangeRate = 0
        }
        
        var mark = "+"
        let remainder = max(relayAccountBalance, minRelayAccountBalance) - min(relayAccountBalance, minRelayAccountBalance)
        if relayAccountBalance < minRelayAccountBalance {
            mark = "-"
        }
        
        let expectedTransactionFee: UInt64
        
        if feeInSOL > 0 {
            if mark == "+" {
                expectedTransactionFee = feeInSOL + remainder
            } else if feeInSOL > remainder {
                expectedTransactionFee = feeInSOL - remainder
            } else {
                expectedTransactionFee = 0
            }
        } else {
            expectedTransactionFee = 0
        }
        var calculationDebugText = ""
        calculationDebugText = relayAccountStatus.description + " (A)\n"
        calculationDebugText += "minRelayAccountBalance = \(minRelayAccountBalance) (B)\n"
        calculationDebugText += "remainder (A - B) = \(mark)\(remainder) (R)\n"
        calculationDebugText += "expected transaction fee in SOL = \(expectedTransactionFee) (E)\n"
        calculationDebugText += "needed topUp amount (real fee) in SOL (E - R) = \(feeInSOL) (S)\n"
        calculationDebugText += "expected transaction fee in Token = \(feeInToken) (T)\n"
        calculationDebugText += "exchange rate (T/S) => 1 SOL = \(exchangeRate) (e)\n"
        return calculationDebugText
    }
}
