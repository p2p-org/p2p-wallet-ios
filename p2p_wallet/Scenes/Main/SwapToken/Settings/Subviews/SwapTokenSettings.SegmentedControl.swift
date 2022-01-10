//
//  SwapTokenSettings.SegmentedControl.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 21.12.2021.
//

import UIKit

extension SwapTokenSettings {
    final class SegmentedControl<T: CustomStringConvertible & Equatable>: UISegmentedControl {
        private let items: [T]
        private let changeHandler: (T) -> Void

        init(items: [T], selectedItem: T, changeHandler: @escaping (T) -> Void) {
            self.items = items
            self.changeHandler = changeHandler

            super.init(items: items.map(\.description))

            if let index = items.firstIndex(of: selectedItem) {
                self.selectedSegmentIndex = index
            }

            addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func valueChanged() {
            let value = items[selectedSegmentIndex]
            changeHandler(value)
        }
    }
}
