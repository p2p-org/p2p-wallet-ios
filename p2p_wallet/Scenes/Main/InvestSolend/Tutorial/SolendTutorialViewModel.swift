import Combine
import SwiftUI
import UIKit

final class SolendTutorialViewModel: BaseViewModel {
    @Published var currentDataIndex: Int = .zero
    let data: [SolendTutorialContentData]

    let skipDidTap = PassthroughSubject<Void, Never>()
    let nextDidTap = PassthroughSubject<Void, Never>()
    let continueDidTap = PassthroughSubject<Void, Never>()

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
        
        bind()
    }
    
    private func bind() {
        nextDidTap
            .sink { [weak self] _ in
                self?.goNext()
            }
            .store(in: &subscriptions)
    }
    
    private func goNext() {
        guard currentDataIndex < data.count - 1 else {
            currentDataIndex = 0
            return
        }
        currentDataIndex += 1
    }
}
