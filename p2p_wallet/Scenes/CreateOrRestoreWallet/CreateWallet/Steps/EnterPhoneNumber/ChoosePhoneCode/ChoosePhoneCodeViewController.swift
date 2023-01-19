// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BECollectionView_Combine
import BEPureLayout
import Combine
import Foundation
import KeyAppUI
import UIKit

final class ChoosePhoneCodeViewController: BaseViewController {
    // MARK: - Properties

    private let viewModel: ChoosePhoneCodeViewModel
    private let searchBar = BERef<BESearchBar>()

    private var cancellables = Set<AnyCancellable>()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = searchBar.view?.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _ = searchBar.view?.resignFirstResponder()
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
                    searchBar.delegate = self
                }
                .bind(searchBar)
                .padding(.init(top: 0, left: 16, bottom: 12, right: 16))
            BEStaticSectionsCollectionView(
                sections: [
                    .init(
                        index: 0,
                        layout: .init(
                            cellType: PhoneCodeCell.self,
                            separator: .init(
                                viewClass: PhoneCodeCellSeparatorView.self,
                                heightDimension: .absolute(1)
                            )
                        ),
                        viewModel: viewModel
                    ),
                ]
            ).setup { collectionView in
                collectionView.canRefresh = false
                collectionView.delegate = self
                collectionView.collectionView.didScrollPublisher
                    .sink(receiveValue: { [weak view] _ in
                        view?.endEditing(true)
                    })
                    .store(in: &cancellables)
            }
            TextButton(title: L10n.ok.uppercased(), style: .primary, size: .large)
                .onPressed { [weak self] _ in
                    self?.doneButtonDidTouch()
                }
                .padding(UIEdgeInsets(top: .zero, left: 20, bottom: 34, right: 20))
        }
    }

    @objc private func doneButtonDidTouch() {
        dismiss(animated: true) { [unowned self] in
            self.viewModel.didClose.send()
        }
    }
}

// MARK: - BECollectionViewDelegate

extension ChoosePhoneCodeViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let selectedCountry = item as? SelectableCountry, !selectedCountry.isSelected,
              !selectedCountry.isEmpty else { return }
        viewModel.selectedDialCode = selectedCountry.value.dialCode
        viewModel.selectedCountryCode = selectedCountry.value.code
        collectionView.updateWithoutAnimations {
            viewModel.batchUpdate { countries in
                var countries = countries
                for i in 0 ..< countries.count {
                    if countries[i].value.dialCode == selectedCountry.value.dialCode,
                       countries[i].value.code == selectedCountry.value.code
                    {
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

// MARK: - BESearchBarDelegate

extension ChoosePhoneCodeViewController: BESearchBarDelegate {
    func beSearchBar(_: BESearchBar, searchWithKeyword keyword: String) {
        viewModel.keyword = keyword
    }

    func beSearchBarDidBeginSearching(_: BESearchBar) {}

    func beSearchBarDidEndSearching(_: BESearchBar) {}

    func beSearchBarDidCancelSearching(_: BESearchBar) {}
}
