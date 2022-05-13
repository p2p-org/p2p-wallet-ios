//
//  Settings.SelectFiatViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class SelectFiatViewController: SingleSelectionViewController<Fiat> {
        override init(viewModel: SettingsViewModelType) {
            super.init(viewModel: viewModel)

            // init data
            Fiat.allCases
                .forEach {
                    data[$0] = ($0 == Defaults.fiat)
                }
        }

        override func setUp() {
            super.setUp()
            navigationItem.title = L10n.currency
        }

        override func createCell(item: Fiat) -> Cell<Fiat> {
            let cell = super.createCell(item: item)
            cell.label.text = item.name
            return cell
        }

        override func itemDidSelect(_ item: Fiat) {
            super.itemDidSelect(item)
            viewModel.setFiat(item)
        }
    }
}
