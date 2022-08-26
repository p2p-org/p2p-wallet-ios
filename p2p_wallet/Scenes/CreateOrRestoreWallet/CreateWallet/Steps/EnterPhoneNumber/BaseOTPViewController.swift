import Foundation
import KeyAppUI

class BaseOTPViewController: BaseViewController {
    override func bind() {
        super.bind()
    }

    func showError(error: String?) {
        guard let error = error, let window = UIApplication.shared.kWindow else { return }
        let bar = SnackBar(text: error)
        bar.show(in: window)
    }
}
