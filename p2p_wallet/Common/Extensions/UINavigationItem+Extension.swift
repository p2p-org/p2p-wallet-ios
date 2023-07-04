import Foundation
import KeyAppUI
import UIKit

extension UINavigationItem {
    func setTitle(_ title: String, subtitle: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.font(of: .text3, weight: .semibold)
        titleLabel.textColor = Asset.Colors.night.color

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.font(of: .label1, weight: .regular)
        subtitleLabel.textColor = Asset.Colors.mountain.color

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.layoutSubviews()

        titleView = stackView
    }
}
