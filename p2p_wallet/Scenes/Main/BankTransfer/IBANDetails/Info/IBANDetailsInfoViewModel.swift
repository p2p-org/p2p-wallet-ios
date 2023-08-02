import BankTransfer
import Combine
import Foundation
import Resolver
import UIKit
import Onboarding

final class IBANDetailsInfoViewModel: BaseViewModel, ObservableObject {
    @Published var isChecked = false
    let close = PassthroughSubject<Void, Never>()

    @SwiftyUserDefault(keyPath: \.strigaIBANInfoDoNotShow, options: .cached)
    private var strigaIBANInfoDoNotShow: Bool

    override init() {
        super.init()

        isChecked = strigaIBANInfoDoNotShow

        $isChecked
            .assignWeak(to: \.strigaIBANInfoDoNotShow, on: self)
            .store(in: &subscriptions)
    }
}
