//
// Created by Giang Long Tran on 04.11.21.
//

import Foundation
import RxCocoa
import RxSwift

extension CreateSecurityKeys {
    class KeysView: BEView {
        var keys: [String] = [] {
            didSet {
                update()
            }
        }

        private let numberOfColumns: Int = 3
        private let spacing: CGFloat = 8
        private let runSpacing: CGFloat = 8
        private let keyHeight: CGFloat = 37

        private lazy var content = UIStackView(
            axis: .vertical,
            spacing: runSpacing,
            alignment: .fill,
            distribution: .fillEqually
        )

        override func commonInit() {
            super.commonInit()
            layout()
            update()
        }

        func layout() {
            addSubview(content)
            content.autoPinEdgesToSuperviewEdges()
            content.backgroundColor = .background
        }

        func update() {
            content.removeAllArrangedSubviews()
            keys.chunked(into: numberOfColumns).enumerated().forEach { section, chunk in
                let row = UIStackView(axis: .horizontal, spacing: spacing, alignment: .fill, distribution: .fillEqually)
                row.heightAnchor.constraint(equalToConstant: keyHeight).isActive = true
                row.addArrangedSubviews(chunk.enumerated().map { index, key in
                    KeyView(index: section * numberOfColumns + index + 1, key: key)
                })
                content.addArrangedSubview(row)
            }
        }
    }

    class KeysViewActions: BEView {
        private lazy var content = UIStackView(axis: .horizontal, alignment: .fill, distribution: .fillEqually)

        fileprivate let copyButton: UIButton = UIButton.text(text: L10n.copy, image: .copyIcon, tintColor: .h5887ff)
        fileprivate let saveButton: UIButton = UIButton.text(text: L10n.save, image: .imageIcon, tintColor: .h5887ff)
        fileprivate let refreshButton: UIButton = UIButton.text(
            text: L10n.renew,
            image: .refreshIcon,
            tintColor: .h5887ff
        )

        override func commonInit() {
            super.commonInit()
            layout()
        }

        func layout() {
            addSubview(content)
            content.addArrangedSubviews {
                copyButton
                saveButton
                refreshButton
            }
            content.autoPinEdgesToSuperviewEdges()
            content.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
}

extension Reactive where Base: CreateSecurityKeys.KeysView {
    var keys: Binder<[String]> {
        Binder(base) { view, keys in
            view.keys = keys
        }
    }
}

extension Reactive where Base: CreateSecurityKeys.KeysViewActions {
    var onCopy: ControlEvent<Void> {
        base.copyButton.rx.tap
    }

    var onSave: ControlEvent<Void> {
        base.saveButton.rx.tap
    }

    var onRefresh: ControlEvent<Void> {
        base.refreshButton.rx.tap
    }
}
