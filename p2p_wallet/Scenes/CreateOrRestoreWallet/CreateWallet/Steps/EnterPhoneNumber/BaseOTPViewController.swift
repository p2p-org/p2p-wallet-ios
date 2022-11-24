import Foundation
import KeyAppUI
import Resolver

class BaseOTPViewController: BaseViewController {
    @Injected private var notificationService: NotificationService

    override func bind() {
        super.bind()
    }

    func showError(error: String?) {
        notificationService.showToast(title: nil, text: error)
    }
}
