import BEPureLayout
import Foundation
import SwiftUI

class BottomPanel: BECompositionView {
    let child: UIView

    override init() {
        child = UIView()
        super.init(frame: .zero)
    }

    required init(@BEViewBuilder builder: Builder) {
        child = builder().build()
        super.init(frame: .zero)
    }

    override func build() -> UIView {
        BEContainer {
            child
        }
        .backgroundColor(color: .init(resource: .night))
        .roundCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 24)
    }
}
