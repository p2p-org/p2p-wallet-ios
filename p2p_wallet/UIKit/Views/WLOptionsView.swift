//
//  WLOptionsView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import Foundation
import UIKit

protocol OptionViewType: BEView {
    func setSelected(_ selected: Bool)
}

protocol SelectOptionViewDelegate: AnyObject {
    func selectOptionView<Option>(_ view: SelectOptionView<Option>, didChangeSelectedIndexTo selectedIndex: Int)
}

class SelectOptionView<Option>: BEView {
    // MARK: - Properties

    var options: [Option] {
        didSet {
            rebuild()
        }
    }

    var selectedIndex: Int {
        didSet {
            reloadData()
        }
    }

    private let cellBuilder: (Option, Bool) -> OptionViewType
    var completion: ((Option) -> Void)?
    weak var delegate: SelectOptionViewDelegate?

    // MARK: - Subviews

    private lazy var stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)

    // MARK: - Initializer

    init(options: [Option], selectedIndex: Int, cellBuilder: @escaping ((Option, Bool) -> OptionViewType)) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.cellBuilder = cellBuilder
        super.init(frame: .zero)
        layout()
        reloadData()
    }

    // MARK: - Methods

    func layout() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        rebuild()
    }

    private func rebuild() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let optionViews: [OptionViewType] = options.enumerated().map { index, option in
            let cell = cellBuilder(option, false)
            let gesture = TapGesture(target: self, action: #selector(cellDidTap(_:)))
            gesture.index = index
            cell.addGestureRecognizer(gesture)
            return cell
        }
        stackView.addArrangedSubviews(optionViews)

        reloadData()
    }

    private func reloadData() {
        guard selectedIndex < options.count else {
            selectedIndex = 0
            return
        }

        for (index, cell) in stackView.arrangedSubviews.enumerated() {
            (cell as? OptionViewType)?.setSelected(index == selectedIndex)
        }
    }

    @objc private func cellDidTap(_ gesture: TapGesture) {
        guard let index = gesture.index,
              index != selectedIndex
        else { return }
        selectedIndex = index
        delegate?.selectOptionView(self, didChangeSelectedIndexTo: selectedIndex)
    }
}

private class TapGesture: UITapGestureRecognizer {
    var index: Int?
}
