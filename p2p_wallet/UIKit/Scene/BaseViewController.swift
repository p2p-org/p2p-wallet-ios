//
// Created by Giang Long Tran on 13.12.21.
//

import BEPureLayout
import RxSwift
import UIKit

class BaseViewController: BaseVC {
    override func setUp() {
        super.setUp()

        let child = build()
        view.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()

        layout()
    }

    func layout() {}

    func build() -> UIView {
        fatalError("build method is not implemented")
    }
}
