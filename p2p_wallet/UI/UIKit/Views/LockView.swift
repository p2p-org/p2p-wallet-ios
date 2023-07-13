import KeyAppUI
import UIKit
import BEPureLayout

class LockView: BECompositionView {
    override func build() -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) { UIView().setup {
                $0.backgroundColor = .init(resource: .lime)
            }}
            BEZStackPosition(mode: .center) { UIImageView().setup {
                $0.image = .init(resource: .keyappLogo)
                $0.tintColor = .black
            }}
        }
    }
}
