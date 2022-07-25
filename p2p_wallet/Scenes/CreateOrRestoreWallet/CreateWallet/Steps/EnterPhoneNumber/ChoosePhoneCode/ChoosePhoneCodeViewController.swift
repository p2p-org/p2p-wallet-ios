// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BECollectionView_Combine
import BEPureLayout
import Foundation

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
            BEStaticSectionsCollectionView(
                sections: [
                    .init(
                        index: 0,
                        layout: .init(
                            cellType: PhoneCodeCell.self,
                            numberOfLoadingCells: 2
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
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let selectedCountry = item as? SelectableCountry, !selectedCountry.isSelected else { return }
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
