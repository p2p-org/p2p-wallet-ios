//
// Created by Giang Long Tran on 20.04.2022.
//

import Foundation
import RxCocoa
import RxSwift

extension ReceiveToken {
    class NetworkCell: BECompositionView {
        let networkName: String
        let networkDescription: String
        let icon: UIImage

        var isSelected: Bool {
            didSet {
                selectionView.view?.hidden(!isSelected)
            }
        }

        let selectionView = BERef<UIImageView>()

        init(networkName: String, networkDescription: String, icon: UIImage, isSelected: Bool = false) {
            self.networkName = networkName
            self.networkDescription = networkDescription
            self.icon = icon
            self.isSelected = isSelected
            super.init()
        }

        override func build() -> UIView {
            UIStackView(axis: .horizontal, alignment: .top) {
                // Icon
                UIImageView(width: 44, height: 44, image: icon)

                // Text description
                UIStackView(axis: .vertical, spacing: 4, alignment: .leading) {
                    UILabel(text: L10n.network(networkName).onlyUppercaseFirst(), textSize: 17, weight: .semibold)
                    UILabel(
                        textColor: .secondaryLabel,
                        numberOfLines: 3
                    ).setAttributeString(networkDescription.asMarkdown(
                        textColor: .secondaryLabel
                    ))
                }.padding(.init(only: .left, inset: 12))

                // Check box
                UIImageView(width: 22, height: 22, image: .checkBoxIOS)
                    .bind(selectionView)
            }
        }
    }
}

extension Reactive where Base: ReceiveToken.NetworkCell {
    /// Bindable sink for `text` property.
    var isSelected: Binder<Bool> {
        Binder(base) { view, value in
            view.isSelected = value
        }
    }
}
