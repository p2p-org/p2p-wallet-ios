import SwiftUI

struct SendTransactionStatusViewAppearance {
    let image: ImageResource
    let imageSize: CGSize
    let backgroundColor: Color
    let circleColor: Color
    let imageColor: Color

    init(state: SendTransactionStatusViewModel.State) {
        switch state {
        case .loading:
            image = .lightningFilled
            imageSize = CGSize(width: 24, height: 24)
            backgroundColor = Color(.cloud)
            circleColor = Color(.smoke)
            imageColor = Color(.mountain)
        case .succeed:
            image = .lightningFilled
            imageSize = CGSize(width: 24, height: 24)
            backgroundColor = Color(.cdf6Cd).opacity(0.3)
            circleColor = Color(.cdf6Cd)
            imageColor = Color(.h04D004)
        case .error:
            image = .solendSubtract
            imageSize = CGSize(width: 20, height: 18)
            backgroundColor = Color(.ffdce9).opacity(0.3)
            circleColor = Color(.ffdce9)
            imageColor = Color(.rose)
        }
    }
}
