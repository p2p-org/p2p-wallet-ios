import BECollectionView_Combine
import BEPureLayout
import Foundation
import KeyAppUI
import UIKit

final class PhoneCodeCell: BaseCollectionViewCell, BECollectionViewCell {
    override var padding: UIEdgeInsets {
        .init(all: 14)
    }

    // MARK: - Subviews

    private let flagEmojiLabel = BERef<UILabel>()
    private let countryNameLabel = BERef<UILabel>()
    private let phoneCodeLabel = BERef<UILabel>()
    private let checkMark = BERef<UIImageView>()

    override func commonInit() {
        super.commonInit()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.addArrangedSubviews {
            UILabel(text: "<placeholder>", textSize: 28, weight: .bold)
                .bind(flagEmojiLabel)
                .frame(width: 28, height: 32)
            BEVStack(spacing: 4) {
                UILabel(text: "<placeholder>", textSize: 16, numberOfLines: 2)
                    .bind(countryNameLabel)
                UILabel(text: "<placeholder>", textSize: 12, textColor: .textSecondary)
                    .bind(phoneCodeLabel)
            }
            UIImageView(
                width: 14.3,
                height: 14.19,
                image: Asset.MaterialIcon.checkmark.image.withRenderingMode(.alwaysOriginal)
            )
                .bind(checkMark)
        }
    }

    func setUp(with item: AnyHashable?) {
        guard let item = item as? SelectableCountry else { return }
        flagEmojiLabel.text = item.value.emoji
        countryNameLabel.text = item.value.name
        phoneCodeLabel.text = item.value.dialCode
        checkMark.isHidden = !item.isSelected
    }
}
