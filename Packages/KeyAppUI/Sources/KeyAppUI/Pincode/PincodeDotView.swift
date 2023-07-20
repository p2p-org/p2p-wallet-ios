// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import UIKit

class PinCodeDotsView: BEView {
    // MARK: - Constants

    private let dotSize: CGFloat = 12.adaptiveHeight
    private let cornerRadius: CGFloat = 12.adaptiveHeight
    private let padding: UIEdgeInsets = .init(x: 13.adaptiveHeight, y: 8.adaptiveHeight)
    
    /// Default color for dots
    private let defaultColor = Asset.Colors.night.color.withAlphaComponent(0.3)
    /// Color for highlight state
    private let highlightColor = Asset.Colors.night.color
    /// Color for error state
    private let errorColor = Asset.Colors.rose.color
    /// Color for success state
    private let successColor = Asset.Colors.mint.color

    // MARK: - Properties

    private var indicatorViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Subviews

    private lazy var dots: [UIView] = {
        var views = [UIView]()
        for index in 0 ..< pincodeLength {
            let dot = UIView(width: dotSize, height: dotSize, backgroundColor: defaultColor, cornerRadius: dotSize / 2)
            views.append(dot)
        }
        return views
    }()

    private lazy var indicatorView = UIView()

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        // background indicator
        indicatorViewHeightConstraint = indicatorView.autoSetDimension(.width, toSize: 0)
        addSubview(indicatorView)
        indicatorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)

        // dots stack view
        let stackView = UIStackView(axis: .horizontal, spacing: padding.left, alignment: .fill, distribution: .fill)
        stackView.addArrangedSubviews(dots)
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }

    // MARK: - Actions

    func pincodeEntered(numberOfDigits: Int) {
        guard numberOfDigits <= pincodeLength else { return }
        indicatorViewHeightConstraint.constant = (dotSize + (padding.left * 2)) * CGFloat(numberOfDigits)
        indicatorView.backgroundColor = .clear
        for i in 0 ..< dots.count {
            if i < numberOfDigits {
                dots[i].backgroundColor = highlightColor
            } else {
                dots[i].backgroundColor = defaultColor
            }
        }
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }

    func pincodeFailed() {
        indicatorView.backgroundColor = .clear
        dots.forEach { $0.backgroundColor = errorColor }
    }

    func pincodeSuccess() {
        indicatorView.backgroundColor = .clear
        dots.forEach { $0.backgroundColor = successColor }
    }
}
