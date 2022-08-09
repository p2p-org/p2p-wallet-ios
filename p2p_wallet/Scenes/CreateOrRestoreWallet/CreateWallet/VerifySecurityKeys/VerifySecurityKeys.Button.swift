//
// Created by Giang Long Tran on 11.11.21.
//

import Foundation
import UIKit

extension VerifySecurityKeys {
    class NextButton: BEView {
        enum Style {
            case choose
            case save
        }

        var style: Style = .choose {
            didSet {
                update()
            }
        }

        var text: String? {
            didSet {
                button.text = text
            }
        }

        var image: UIImage? {
            didSet {
                button.image = image
            }
        }

        var ready: Bool = false {
            didSet {
                style = ready ? .save : .choose
            }
        }

        var button: WLStepButton = WLStepButton.main(text: "")

        override func commonInit() {
            super.commonInit()
            layout()
            update()
        }

        private func layout() {
            addSubview(button)
            button.autoPinEdgesToSuperviewEdges()
        }

        func update() {
            switch style {
            case .choose:
                button.isEnabled = false
                isUserInteractionEnabled = false
            case .save:
                button.isEnabled = true
                isUserInteractionEnabled = true
            }
        }
    }
}
