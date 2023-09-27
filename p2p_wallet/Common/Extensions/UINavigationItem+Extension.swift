import Foundation
import UIKit

extension UINavigationItem {
    func setTitle(_ title: String, subtitle: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.font(of: .text3, weight: .semibold)
        titleLabel.textColor = .init(resource: .night)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.font(of: .label1, weight: .regular)
        subtitleLabel.textColor = .init(resource: .mountain)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.layoutSubviews()

        titleView = stackView
    }
}
