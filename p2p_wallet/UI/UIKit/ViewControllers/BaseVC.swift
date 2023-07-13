import Foundation
import UIKit
import BEPureLayout

class BaseVC: BEViewController {

    deinit {
        debugPrint("\(String(describing: self)) deinited")
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .init(resource: .background)
    }

    // TODO: - For re-overriding navigationController settings
    override func viewWillAppear(_: Bool) {}
}
