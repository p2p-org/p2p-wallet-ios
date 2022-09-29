import Combine
import SwiftUI
import UIKit

final class SolendTutorialViewModel: BaseViewModel {
    @Published var currentDataIndex: Int = .zero
    let data: [SolendTutorialContentData]

    var isLastPage: Bool {
        currentDataIndex == data.count - 1
    }

    override init() {
        data = [
            SolendTutorialContentData(
                image: .solendTutorial1,
                title: L10n.letYourCryptoWorkForYou,
                subtitle: L10n.growYourPortfolioByReceivingRewardsUpTo("15")
            ),
            SolendTutorialContentData(
                image: .solendTutorial2,
                title: L10n.noLockUpPeriods,
                subtitle: L10n.withdrawYourFundsWithAllRewardsAtAnyTime
            ),
            SolendTutorialContentData(
                image: .solendTutorial3,
                title: L10n.superheroProtection,
                subtitle: L10n.asAllYourFundsAreInsuredYouDonTNeedToWorryAnymore
            ),
        ]

        super.init()
    }

    func next() {
        guard currentDataIndex < data.count - 1 else {
            currentDataIndex = 0
            return
        }
        currentDataIndex += 1
    }
}
