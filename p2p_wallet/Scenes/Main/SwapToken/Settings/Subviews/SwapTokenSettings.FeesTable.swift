//
//  SwapTokenSettings.FeesTable.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.12.2021.
//

import UIKit

extension SwapTokenSettings {
    final class FeesTable: WLFloatingPanelView {
        private var cells: [FeeCell] = []

        override init(contentInset: UIEdgeInsets = .zero) {
            super.init(contentInset: contentInset)

            stackView.spacing = 0
        }

        func setUp(cellsContent: [FeeCellContent]) {
            cells = cellsContent.map(createCell)
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            cells.dropLast().forEach {
                stackView.addArrangedSubview($0)
                stackView.addArrangedSubview(SeparatorView())
            }

            if let last = cells.last {
                stackView.addArrangedSubview(last)
            }
        }

        private func createCell(withContent content: FeeCellContent) -> FeeCell {
            let cell = FeeCell()
            cell.setUp(content: content)
            cell.setIsSelected(content.isSelected)
            cell.onTapHandler = { [weak self, weak cell] in
                self?.cells.forEach {
                    $0.setIsSelected($0 == cell)
                }

                content.onTapHandler()
            }

            return cell
        }
    }
}
