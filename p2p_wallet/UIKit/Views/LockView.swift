//
// Created by Giang Long Tran on 03.01.22.
//

import UIKit

class LockView: BECompositionView {
    override func build() -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) { UIImageView(image: .lockBackground).withTag(1) }
            BEZStackPosition(mode: .center) { UIImageView(width: 217, height: 164, image: .pLogo, tintColor: .white) }
        }
    }
}
