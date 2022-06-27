//
//  Settings.Helpers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation
import OrderedCollections

extension Settings {
    class BaseViewController: BaseVC {
        // MARK: - Subviews

        lazy var stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
            UIView.defaultSeparator()
        }

        override func setUp() {
            super.setUp()
            view.backgroundColor = .listBackground
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewSafeArea()
        }
    }

    class SingleSelectionViewController<T: Hashable>: BaseViewController {
        // MARK: - Data

        var data = OrderedDictionary<T, Bool>()
        var cells: [Cell<T>] { innerStackView.arrangedSubviews.filter { $0 is Cell<T> } as! [Cell<T>] }
        var selectedItem: T? { data.first(where: { $0.value })?.key }

        // MARK: - Subviews

        private lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: .zero)
        private lazy var innerStackView = UIStackView(
            axis: .vertical,
            spacing: 1,
            alignment: .fill,
            distribution: .fill
        )

        // MARK: - Dependencies

        let viewModel: SettingsViewModelType

        // MARK: - Initializers

        init(viewModel: SettingsViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func setUp() {
            super.setUp()
            stackView.setCustomSpacing(10, after: stackView.arrangedSubviews[0]) // after separator
            stackView.addArrangedSubview(scrollView)

            // stackView
            scrollView.contentView.addSubview(innerStackView)
            innerStackView.autoPinEdgesToSuperviewEdges()

            // views
            let subviews = data.map(\.0).map { self.createCell(item: $0) }
            innerStackView.addArrangedSubviews(subviews)

            // reload
            reloadData()
        }

        func reloadData() {
            for cell in cells {
                guard let item = cell.item else { continue }
                cell.radioButton.isSelected = data[item] ?? false
            }
        }

        func createCell(item: T) -> Cell<T> {
            let cell = Cell<T>(height: 66)
            cell.item = item
            cell.onTap(self, action: #selector(rowDidSelect(_:)))
            return cell
        }

        @objc private func rowDidSelect(_ gesture: UIGestureRecognizer) {
            guard let cell = gesture.view as? Cell<T>,
                  let item = cell.item,
                  let isCellSelected = data[item],
                  isCellSelected == false
            else { return }
            itemDidSelect(item)
        }

        func itemDidSelect(_ item: T) {
            data[item] = true

            // deselect all other networks
            data.keys.filter { $0 != item }.forEach { data[$0] = false }

            reloadData()
        }
    }
}

extension Settings.SingleSelectionViewController {
    class Cell<T>: BEView {
        var item: T?

        lazy var label = UILabel(text: nil)

        lazy var radioButton: WLRadioButton = {
            let checkBox = WLRadioButton()
            checkBox.isUserInteractionEnabled = false
            return checkBox
        }()

        override func commonInit() {
            super.commonInit()
            backgroundColor = .contentBackground
            let stackView = UIStackView(
                axis: .horizontal,
                spacing: 16,
                alignment: .center,
                distribution: .fill,
                arrangedSubviews: [
                    radioButton, label,
                ]
            )
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 20))
        }
    }
}
