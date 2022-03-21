//
// Created by Giang Long Tran on 08.11.21.
//

import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        let removedSubviews = arrangedSubviews.reduce([]) { allSubviews, subview -> [UIView] in
            removeArrangedSubview(subview)
            return allSubviews + [subview]
        }

        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap(\.constraints))

        // Remove the views from self
        removedSubviews.forEach { $0.removeFromSuperview() }
    }
}
