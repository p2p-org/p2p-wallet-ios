import BEPureLayout
import KeyAppUI
import UIKit

class LockView: BECompositionView {
    override func build() -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) { UIView().setup {
                $0.backgroundColor = Asset.Colors.lime.color
            }}
            BEZStackPosition(mode: .center) { UIImageView().setup {
                $0.image = .keyappLogo
                $0.tintColor = .black
            }}
        }
    }
}
