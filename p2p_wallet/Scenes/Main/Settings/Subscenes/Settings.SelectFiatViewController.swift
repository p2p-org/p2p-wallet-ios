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

            data = Fiat.allCases
                .sorted {
                    if $0 == Defaults.fiat {
                        return true
                    } else if $1 != Defaults.fiat {
                        return false
                    }
                    return false
                }
                .map { ($0, $0 == Defaults.fiat) }
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

        override func itemDidSelect(at index: Int) {
            super.itemDidSelect(at: index)
            viewModel.setFiat(data[index].item)
        }
    }
}
