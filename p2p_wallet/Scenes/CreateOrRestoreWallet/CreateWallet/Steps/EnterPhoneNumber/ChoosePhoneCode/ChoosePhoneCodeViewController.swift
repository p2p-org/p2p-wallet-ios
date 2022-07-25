// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BECollectionView_Combine
import BEPureLayout
import Foundation
import KeyAppUI

final class ChoosePhoneCodeViewController: BaseViewController {
    // MARK: - Properties

    private let viewModel: ChoosePhoneCodeViewModel

    init(viewModel: ChoosePhoneCodeViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func setUp() {
        super.setUp()
        title = L10n.countryCode
        navigationItem.rightBarButtonItem = .init(
            title: L10n.done,
            style: .done,
            target: self,
            action: #selector(doneButtonDidTouch)
        )
        viewModel.reload()
    }

    override func build() -> UIView {
        BEVStack {
            BESearchBar(fixedHeight: 38, cornerRadius: 10)
                .setup { searchBar in
                    searchBar.textFieldBgColor = Asset.Colors.searchBarBgColor.color
                    searchBar.cancelButton.setTitleColor(.h5887ff, for: .normal)
                    searchBar.magnifyingIconImageView.image = Asset.MaterialIcon.magnifyingGlass.image
                        .withRenderingMode(.alwaysOriginal)
                    searchBar.magnifyingIconSize = 15.63
                }
                .padding(.init(top: 0, left: 16, bottom: 12, right: 16))
            BEStaticSectionsCollectionView(
                sections: [
                    .init(
                        index: 0,
                        layout: .init(
                            cellType: PhoneCodeCell.self,
                            numberOfLoadingCells: 2,
                            separator: .init(
                                viewClass: PhoneCodeCellSeparatorView.self,
                                heightDimension: .absolute(1)
                            )
                        ),
                        viewModel: viewModel
                    ),
                ]
            )
                .setup { collectionView in
                    collectionView.delegate = self
                }
        }
    }

    @objc private func doneButtonDidTouch() {
        dismiss(animated: true) { [unowned self] in
            self.viewModel.didClose.send()
        }
    }
}

extension ChoosePhoneCodeViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let selectedCountry = item as? SelectableCountry, !selectedCountry.isSelected else { return }
        collectionView.updateWithoutAnimations {
            viewModel.batchUpdate { countries in
                var countries = countries
                for i in 0 ..< countries.count {
                    if countries[i].country.code == selectedCountry.country.code {
                        countries[i].isSelected = true
                    } else {
                        countries[i].isSelected = false
                    }
                }
                return countries
            }
        }
    }
}
