import Foundation
import KeyAppKitCore
import Send

struct SendInputFeeDataAggregator: DataAggregator {
    typealias Input = NSendInputState

    typealias Output = SendInputFeeData

    func transform(input state: Input) -> Output {
        switch state {
        case .initialising:
            return SendInputFeeData(loading: true, title: L10n.fees(""))

        case let .calculating:
            return SendInputFeeData(loading: true, title: L10n.fees(""))

        case let .ready(_, output):
            return SendInputFeeData(loading: false, title: calculateTotalFeeAmount(output: output))

        case let .error(_, output, _):
            if let output {
                return SendInputFeeData(loading: false, title: L10n.fees(calculateTotalFeeAmount(output: output)))
            } else {
                return SendInputFeeData(loading: false, title: L10n.fees(""))
            }
        }
    }

    func calculateTotalFeeAmount(output: NSendOutput) -> String {
        do {
            let fees = [output.fees.networkFee, output.fees.tokenAccountRent]

            let totalCryptoAmount = try fees
                .compactMap { fee in
                    guard let fee else { return nil }
                    if fee.source == .serviceCoverage {
                        return nil
                    } else {
                        return fee
                    }
                }
                .reduce<CryptoAmount?>(nil) { (partialResult: CryptoAmount?, fee: Fee) in
                    if let partialResult {
                        return partialResult + fee.amount.asCryptoAmount
                    } else {
                        return fee.amount.asCryptoAmount
                    }
                }

            if let totalCryptoAmount {
                let cryptoFormatter = CryptoFormatter()
                return cryptoFormatter.string(amount: totalCryptoAmount)
            } else {
                return L10n.enjoyFreeTransactions
            }
        } catch {
            return L10n.fees("Calculating failure")
        }
    }
}
