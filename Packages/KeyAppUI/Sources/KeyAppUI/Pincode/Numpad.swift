// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Foundation

public class NumpadView: BEView {
    // MARK: - Constants

    private let buttonSize: CGFloat = 68
    private let spacing = 42.adaptiveHeight
    private let vSpacing = 12.adaptiveHeight
    private let deleteButtonColor = PincodeStateColor(normal: Asset.Colors.night.color, tapped: Asset.Colors.night.color.withAlphaComponent(0.65))

    // MARK: - Callback

    public var didChooseNumber: ((Int) -> Void)?
    public var didTapDelete: (() -> Void)?

    // MARK: - Subviews

    private let bottomLeftButton: UIView?
    private lazy var numButtons: [NumpadButton] = {
        var views = [NumpadButton]()
        for index in 0 ..< 10 {
            let view = NumpadButton(width: buttonSize, height: buttonSize, cornerRadius: 20)
            view.label.text = "\(index)"
            view.tag = index
            view.onLongTap(self, action: #selector(numButtonDidTap(_:)), minimumPressDuration: 0)
            views.append(view)
        }
        return views
    }()

    private lazy var deleteButton = UIImageView(
        width: buttonSize,
        height: buttonSize,
        image: Asset.Icons.remove.image,
        contentMode: .center,
        tintColor: deleteButtonColor.normal
    )
    .onLongTap(self, action: #selector(deleteButtonDidTap), minimumPressDuration: 0)

    public init(bottomLeftButton: UIView? = nil) {
        self.bottomLeftButton = bottomLeftButton
        super.init(frame: .zero)
        configureForAutoLayout()
    }

    // MARK: - Methods

    override public func commonInit() {
        super.commonInit()
        let stackView = UIStackView(axis: .vertical, spacing: vSpacing, alignment: .fill, distribution: .equalSpacing)

        stackView.addArrangedSubview(buttons(from: 1, to: 3))
        stackView.addArrangedSubview(buttons(from: 4, to: 6))
        stackView.addArrangedSubview(buttons(from: 7, to: 9))
        stackView.addArrangedSubview(
            UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually) {
                bottomLeftButton ?? UIView.spacer
                numButtons[0]
                deleteButton
            }
        )

        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }

    // MARK: - Actions

    func setDeleteButtonHidden(_ isHidden: Bool) {
        deleteButton.alpha = isHidden ? 0 : 1
        deleteButton.isUserInteractionEnabled = !isHidden
    }

    @objc private func numButtonDidTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? NumpadButton else { return }

        switch gesture.state {
        case .began:
            view.setHighlight(value: true)
        case .ended:
            didChooseNumber?(view.tag)
            view.setHighlight(value: false)
        default:
            return
        }
    }

    @objc private func deleteButtonDidTap(_ gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .began:
            deleteButton.tintColor = deleteButtonColor.tapped
        case .ended:
            didTapDelete?()
            deleteButton.tintColor = deleteButtonColor.normal
        default:
            return
        }
    }

    // MARK: - Helpers

    private func buttons(from: Int, to: Int) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually)
        for i in from ..< to + 1 {
            stackView.addArrangedSubview(numButtons[i])
        }
        return stackView
    }
}

private extension UIView {
    @discardableResult
    func onLongTap(_ target: Any?, action: Selector, minimumPressDuration: TimeInterval) -> Self {
        // clear all old tap gesture
        gestureRecognizers?.removeAll(where: { $0 is UITapGestureRecognizer })

        let tap = UILongPressGestureRecognizer(target: target, action: action)
        tap.minimumPressDuration = minimumPressDuration
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        return self
    }
}
