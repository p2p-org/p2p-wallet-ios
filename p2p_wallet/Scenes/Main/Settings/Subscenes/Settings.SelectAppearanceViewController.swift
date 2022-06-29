//
//  Settings.SelectAppearanceViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

extension Settings {
    class SelectAppearanceViewController: SingleSelectionViewController<UIUserInterfaceStyle> {
        var interfaceStyle: UIUserInterfaceStyle {
            AppDelegate.shared.window?.overrideUserInterfaceStyle ?? .unspecified
        }

        override init(viewModel: SettingsViewModelType) {
            super.init(viewModel: viewModel)
            data = [
                (.dark, interfaceStyle == .dark),
                (.light, interfaceStyle == .light),
                (.unspecified, interfaceStyle == .unspecified),
            ]
        }

        override func setUp() {
            super.setUp()
            navigationItem.title = L10n.appearance
        }

        override func createCell(item: UIUserInterfaceStyle) -> Cell<UIUserInterfaceStyle> {
            let cell = super.createCell(item: item)
            cell.label.text = item.localizedString
            return cell
        }

        override func itemDidSelect(at index: Int) {
            super.itemDidSelect(at: index)
            viewModel.setTheme(data[index].item)
        }
    }
}
