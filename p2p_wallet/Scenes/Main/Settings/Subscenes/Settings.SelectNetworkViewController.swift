//
//  Settings.SelectNetworkViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation
import SolanaSwift
import SwiftyUserDefaults

extension Settings {
    class SelectNetworkViewController: SingleSelectionViewController<APIEndPoint> {
        override init(viewModel: SettingsViewModelType) {
            super.init(viewModel: viewModel)
            // initial data
            data = APIEndPoint.definedEndpoints
                .sorted {
                    if $0 == Defaults.apiEndPoint {
                        return true
                    } else if $1 != Defaults.apiEndPoint {
                        return false
                    }
                    return false
                }
                .map { ($0, $0 == Defaults.apiEndPoint) }
        }

        override func setUp() {
            super.setUp()
            navigationItem.title = L10n.network
        }

        override func createCell(item: APIEndPoint) -> Cell<APIEndPoint> {
            let cell = super.createCell(item: item)
            cell.label.text = item.address
            return cell
        }

        override func itemDidSelect(at index: Int) {
            let originalSelectedItem = selectedItem
            super.itemDidSelect(at: index)
            showAlert(
                title: L10n.switchNetwork,
                message: L10n.doYouReallyWantToSwitchTo + " \"" + selectedItem?.address + "\"",
                buttonTitles: [L10n.ok, L10n.cancel],
                highlightedButtonIndex: 0
            ) { [weak self] index in
                guard index == 0 else {
                    self?.reverseChange(originalSelectedItem: originalSelectedItem)
                    return
                }

                self?.changeNetworkToSelectedNetwork()
            }
        }

        private func changeNetworkToSelectedNetwork() {
            guard let endpoint = selectedItem else { return }
            viewModel.setApiEndpoint(endpoint)
        }

        private func reverseChange(originalSelectedItem: APIEndPoint?) {
            guard
                let item = originalSelectedItem,
                let index = (data.firstIndex { $0.item == item })
            else { return }
            super.itemDidSelect(at: index)
        }
    }
}
