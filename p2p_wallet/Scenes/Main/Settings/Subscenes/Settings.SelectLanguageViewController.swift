//
//  Settings.SelectLanguageViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

extension Settings {
    class SelectLanguageViewController: SingleSelectionViewController<LocalizedLanguage> {
        override init(viewModel: SettingsViewModelType) {
            super.init(viewModel: viewModel)

            setSelectableLanguages()
        }

        override func setUp() {
            super.setUp()
            navigationItem.title = L10n.language
        }

        override func createCell(item: LocalizedLanguage) -> Cell<LocalizedLanguage> {
            let cell = super.createCell(item: item)
            cell.label.text = item.originalName?.uppercaseFirst
            return cell
        }

        override func itemDidSelect(_ item: LocalizedLanguage) {
            let originalSelectedItem = selectedItem
            super.itemDidSelect(item)
            showAlert(
                title: L10n.switchLanguage,
                message: L10n.doYouReallyWantToSwitchTo + " " + selectedItem?.localizedName?.uppercaseFirst + "?",
                buttonTitles: [L10n.ok, L10n.cancel],
                highlightedButtonIndex: 0
            ) { [weak self] index in
                guard index == 0, let language = self?.selectedItem
                else {
                    self?.reverseSelectedItem(originalSelectedItem: originalSelectedItem)
                    return
                }
                self?.viewModel.setLanguage(language)
            }
        }

        private func reverseSelectedItem(originalSelectedItem: LocalizedLanguage?) {
            guard let item = originalSelectedItem else { return }
            super.itemDidSelect(item)
        }

        private func setSelectableLanguages() {
            data = viewModel.selectableLanguages
        }
    }
}
