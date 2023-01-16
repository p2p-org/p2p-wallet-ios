import KeyAppUI
import SwiftUI

struct SendTransactionStatusViewAppearance {
    let image: UIImage
    let imageSize: CGSize
    let backgroundColor: Color
    let circleColor: Color
    let imageColor: Color

    init(state: SendTransactionStatusViewModel.State) {
        switch state {
        case .loading:
            image = .lightningFilled
            imageSize = CGSize(width: 24, height: 24)
            backgroundColor = Color(Asset.Colors.cloud.color)
            circleColor = Color(Asset.Colors.smoke.color)
            imageColor = Color(Asset.Colors.mountain.color)
        case .succeed:
            image = .lightningFilled
            imageSize = CGSize(width: 24, height: 24)
            backgroundColor = Color(.cdf6cd).opacity(0.3)
            circleColor = Color(.cdf6cd)
            imageColor = Color(.h04d004)
        case .error:
            image = .solendSubtract
            imageSize = CGSize(width: 20, height: 18)
            backgroundColor = Color(.ffdce9).opacity(0.3)
            circleColor = Color(.ffdce9)
            imageColor = Color(Asset.Colors.rose.color)
        }
    }
}
