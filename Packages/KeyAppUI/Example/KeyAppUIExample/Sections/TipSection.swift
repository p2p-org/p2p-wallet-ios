import UIKit
import BEPureLayout
import KeyAppUI

final class TipSection: BECompositionView {

    override func build() -> UIView {
        BEVStack(spacing: 15) {
            UILabel(text: "Tip", textSize: 22).padding(.init(only: .top, inset: 20))
            TextButton(
                title: "Open Tip",
                style: .primary,
                size: .large
            )
        }
    }
}
