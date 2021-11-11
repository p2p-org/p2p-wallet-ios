//
// Created by Giang Long Tran on 11.11.21.
//

import Foundation
import UIKit
import RxSwift

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
        }
        
        private func layout() {
            addSubview(button)
            button.autoPinEdgesToSuperviewEdges()
        }
        
        func update() {
            button.isEnabled = style == .save
            switch style {
            case .choose:
                button.isEnabled = false
            case .save:
                button.isEnabled = true
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
