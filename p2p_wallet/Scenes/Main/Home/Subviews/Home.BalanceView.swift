//
//  Home.BalanceView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import BECollectionView_Combine
import Charts
import Combine
import Foundation

extension Home {
    class BalanceView: BECompositionView {
        private let viewModel: HomeViewModelType
        private var subscriptions = [AnyCancellable]()

        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BEVStack(alignment: .center) {
                UILabel(text: L10n.balance, textSize: 13, textColor: .secondaryLabel)
                UIView(height: 4)
                UILabel(text: "", textSize: 28, weight: .bold).setup { view in
                    viewModel
                        .balance
                        .assign(to: \.text, on: view)
                        .store(in: &subscriptions)
                }
            }
        }
    }
}

private extension HomeViewModelType {
    var balance: AnyPublisher<String?, Never> {
        Publishers.Zip(
            walletsRepository.dataPublisher,
            walletsRepository.statePublisher
        )
            .replaceError(with: ([], .loaded))
            .map { data, state in
                switch state {
                case .initializing:
                    return ""
                case .loading:
                    return L10n.loading + "..."
                case .loaded:
                    let equityValue = data.reduce(0) { $0 + $1.amountInCurrentFiat }
                    return "\(Defaults.fiat.symbol) \(equityValue.toString(maximumFractionDigits: 2))"
                case .error:
                    return L10n.error.uppercaseFirst
                }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
