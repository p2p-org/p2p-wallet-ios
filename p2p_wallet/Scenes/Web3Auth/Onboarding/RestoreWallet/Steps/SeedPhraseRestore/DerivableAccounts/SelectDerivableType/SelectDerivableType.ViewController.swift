import Foundation
import SolanaSwift
import UIKit

extension SelectDerivableType {
    typealias Callback = (DerivablePath.DerivableType) -> Void

    class ViewController: WLBottomSheet {
        // MARK: - Properties

        private let initType: DerivablePath.DerivableType
        private let onSelect: Callback?

        override var margin: UIEdgeInsets {
            .init(x: 10, y: 0)
        }

        // MARK: - Initializers

        init(currentType: DerivablePath.DerivableType, onSelect: Callback?) {
            initType = currentType
            self.onSelect = onSelect
            super.init()
            modalPresentationStyle = .custom
            transitioningDelegate = self
        }

        override func setUp() {
            super.setUp()

            view.backgroundColor = .clear

            stackView.addArrangedSubviews {
                // Actions
                UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
                    // Header
                    UILabel(
                        text: L10n.derivationPath,
                        textSize: 13,
                        weight: .semibold,
                        textColor: .init(resource: .textSecondary),
                        textAlignment: .center
                    ).padding(.init(x: 0, y: 15))
                    UIView.separator(height: 1, color: .separator)

                    // Derivable paths
                    DerivablePath.DerivableType
                        .allCases
                        .map { DerivablePath(type: $0, walletIndex: 0, accountIndex: 0) }
                        .enumerated()
                        .map { index, path -> UIView in
                            let selected = path.type == initType

                            return UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
                                UIStackView(axis: .horizontal, alignment: .center) {
                                    UILabel(text: path.title, textSize: 17, weight: selected ? .semibold : .regular)
                                    UIView.spacer
                                    selected ? UIImageView(width: 22, height: 22, image: .init(resource: .checkBoxIOS)) : UIView()
                                }.padding(.init(top: 0, left: 20, bottom: 0, right: 24))
                                UIView.separator(height: 1, color: .separator)
                            }.withTag(index)
                                .frame(height: 55)
                                .onTap(self, action: #selector(onPathSelect))
                        }
                }.padding(.zero, backgroundColor: .init(resource: .background), cornerRadius: 14)

                // Cancel
                WLButton.stepButton(
                    type: .white,
                    label: L10n.cancel,
                    labelColor: .init(resource: .night)
                ).onTap(self, action: #selector(back))
            }
        }

        @objc func onPathSelect(gesture: UITapGestureRecognizer) {
            dismiss(animated: true)

            guard let tag = gesture.view?.tag else { return }
            let pathType = DerivablePath.DerivableType.allCases[tag]
            onSelect?(pathType)
        }
    }
}
