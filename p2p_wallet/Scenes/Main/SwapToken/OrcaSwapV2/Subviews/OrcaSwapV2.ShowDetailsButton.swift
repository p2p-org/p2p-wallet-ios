//
//  OrcaSwapV2.ShowDetailsButton.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 03.12.2021.
//

import UIKit
import PureLayout
import RxSwift

extension OrcaSwapV2 {
    final class ShowDetailsButton: UIButton {
        private let textLabel = UILabel(textSize: 15, weight: .regular)
        private let arrowView = UIImageView(width: 16, height: 16)

        init() {
            super.init(frame: .zero)

            layout()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        fileprivate func setState(isShown: Bool) {
            textLabel.text = isShown ? L10n.hideDetails : L10n.showDetails
            arrowView.image = isShown ? .chevronUp : .chevronDown
        }

        private func layout() {
            let stackView = UIStackView(axis: .horizontal, spacing: 4) {
                textLabel
                arrowView
            }

            stackView.isUserInteractionEnabled = false

            addSubview(stackView)

            stackView.autoAlignAxis(toSuperviewAxis: .vertical)
            stackView.autoAlignAxis(toSuperviewAxis: .horizontal)
        }
    }
}

extension Reactive where Base == OrcaSwapV2.ShowDetailsButton {
    var isShown: Binder<Bool> {
        Binder(base) { view, isShown in
            view.setState(isShown: isShown)
        }
    }
}
