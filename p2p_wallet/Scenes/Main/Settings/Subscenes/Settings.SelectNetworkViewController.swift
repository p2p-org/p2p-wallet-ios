//
//  Settings.SelectNetworkViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class SelectNetworkViewController: SingleSelectionViewController<SolanaSDK.APIEndPoint> {
        override init(viewModel: SettingsViewModelType) {
            super.init(viewModel: viewModel)
            // initial data
            SolanaSDK.APIEndPoint.definedEndpoints
                .forEach {
                    data[$0] = ($0 == Defaults.apiEndPoint)
                }
        }

        override func setUp() {
            super.setUp()
            navigationItem.title = L10n.network
        }

        override func createCell(item: SolanaSDK.APIEndPoint) -> Cell<SolanaSDK.APIEndPoint> {
            let cell = super.createCell(item: item)
            cell.label.text = item.address
            return cell
        }

        override func itemDidSelect(_ item: SolanaSDK.APIEndPoint) {
            let originalSelectedItem = selectedItem
            super.itemDidSelect(item)
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

        private func reverseChange(originalSelectedItem: SolanaSDK.APIEndPoint?) {
            guard let item = originalSelectedItem else { return }
            super.itemDidSelect(item)
        }
    }
}
