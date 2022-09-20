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
                image: .coins,
                title: L10n.welcomeToKeyApp,
                subtitle: L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos
            ),
            SolendTutorialContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 2",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 2"
            ),
            SolendTutorialContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 3",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 3"
            ),
            SolendTutorialContentData(
                image: .coins,
                title: "\(L10n.welcomeToKeyApp) 4",
                subtitle: "\(L10n.useOurAdvancedSecurityToBuySellAndHoldCryptos) 4"
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
