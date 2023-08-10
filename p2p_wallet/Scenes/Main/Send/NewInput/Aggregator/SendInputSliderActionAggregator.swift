import Foundation
import KeyAppKitCore
import Send

struct SendInputSliderAggregator: DataAggregator {
    typealias Input = NSendInputState

    typealias Output = SliderActionButtonData

    func transform(input state: Input) -> Output {
        switch state {
        case .initialising:
            return SliderActionButtonData(isEnabled: false, title: L10n.loading)

        case let .ready(_, output):
            let cryptoFormatter = CryptoFormatter()
            let amount = cryptoFormatter.string(amount: output.transferAmounts.recipientGetsAmount.asCryptoAmount)

            let title = "\(L10n.send) \(amount)"

            return SliderActionButtonData(isEnabled: true, title: title)

        case .calculating:
            return SliderActionButtonData(isEnabled: false, title: L10n.loading)

        case let .error(_, _, error):
            switch error {
            case .noAmount:
                return SliderActionButtonData(isEnabled: false, title: L10n.enterAmount)
            case .insufficientAmount:
                return SliderActionButtonData(isEnabled: false, title: L10n.insufficientFunds)
            case .server, .unknown:
                return SliderActionButtonData(isEnabled: false, title: L10n.internalError)
            }
        }
    }
}
