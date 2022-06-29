//
//  Settings.Helpers.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/10/2021.
//

import Foundation

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

        var data = [(item: T, selected: Bool)]()
        var cells: [Cell<T>] { innerStackView.arrangedSubviews.filter { $0 is Cell<T> } as! [Cell<T>] }
        var selectedItem: T? { data.first { $0.selected }?.item }

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
            cells.enumerated().forEach { index, cell in
                cell.radioButton.isSelected = data[index].selected
            }
        }

        func createCell(item: T) -> Cell<T> {
            let cell = Cell<T>(height: 66)
            cell.item = item
            cell.onTap(self, action: #selector(rowDidSelect(_:)))
            return cell
        }

        @objc private func rowDidSelect(_ gesture: UIGestureRecognizer) {
            guard
                let cell = gesture.view as? Cell<T>,
                let index = cells.firstIndex(of: cell),
                !data[index].selected
            else { return }
            itemDidSelect(at: index)
        }

        func itemDidSelect(at index: Int) {
            data[index].selected = true

            data.indices
                .filter { $0 != index }
                .forEach { data[$0].selected = false }

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
