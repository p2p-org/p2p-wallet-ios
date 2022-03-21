//
// Created by Giang Long Tran on 11.11.21.
//

import Foundation
import RxSwift
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

extension Reactive where Base: VerifySecurityKeys.NextButton {
    var ready: Binder<Bool> {
        Binder(base) { view, ready in
            view.style = ready ? .save : .choose
        }
    }

    var text: Binder<String?> {
        base.button.rx.text
    }

    var image: Binder<UIImage?> {
        base.button.rx.image
    }
}
