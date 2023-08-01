import BankTransfer
import Combine
import Foundation
import Resolver
import UIKit
import Onboarding

final class IBANDetailsInfoViewModel: BaseViewModel, ObservableObject {
    @Published var isChecked = false

    override init() {
        super.init()
    }
}
