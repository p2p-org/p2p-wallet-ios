//
// Created by Giang Long Tran on 18.03.2022.
//

import Foundation
import LocalAuthentication
import RxSwift
import RxCocoa

extension Authentication {
    class BiometricButton: BECompositionView {
        var onTapCallback: BEVoidCallback?
        var button = BERef<UIButton>()
        
        override func build() -> UIView {
            UIButton(frame: .zero)
                .bind(button)
                .setupWithType(UIButton.self) { button in
                    button.tintColor = .textBlack
                    button.contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
                }
        }
        
        func setBiometricType(type: LABiometryType) {
            guard let icon = type.icon?.withRenderingMode(.alwaysTemplate) else { return }
            button.view?.setImage(icon, for: .normal)
            button.view?.addTarget(self, action: #selector(tapHandler), for: .touchUpInside)
        }
        
        @objc private func tapHandler() {
            onTapCallback?()
        }
        
        func onClick(callback: @escaping BEVoidCallback) -> Self {
            onTapCallback = callback
            return self
        }
    }
}