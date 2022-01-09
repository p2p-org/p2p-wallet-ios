//
// Created by Giang Long Tran on 03.01.22.
//

import UIKit

class LockView: BECompositionView {
    override func build() -> UIView {
        BEZStack {
            UIImageView(image: .lockBackground).withTag(1)
            UIImageView(image: .pLogo).withTag(2)
        }.setup { view in
            if let background = view.viewWithTag(1) {
                background.autoPinEdgesToSuperviewEdges()
            }
            if let logo = view.viewWithTag(2) {
                logo.autoCenterInSuperView(leftInset: 79, rightInset: 79)
            }
        }
    }
}
