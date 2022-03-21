//
//  Home.BalanceView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import BECollectionView
import Charts
import Foundation
import RxCocoa
import RxSwift

extension Home {
    class BalanceView: BECompositionView {
        private let viewModel: HomeViewModelType
        private let disposeBag = DisposeBag()

        init(viewModel: HomeViewModelType) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BEVStack(alignment: .center) {
                UILabel(text: L10n.balance, textSize: 13, textColor: .secondaryLabel)
                UIView(height: 4)
                UILabel(text: "", textSize: 28, weight: .bold).setupWithType(UILabel.self) { view in
                    viewModel
                        .balance
                        .drive(view.rx.text)
                        .disposed(by: disposeBag)
                }
            }
        }
    }
}

private extension HomeViewModelType {
    var isLoading: Driver<Bool> {
        walletsRepository
            .stateObservable
            .map { state in state != .loaded }
            .distinctUntilChanged { $0 }
            .asDriver(onErrorJustReturn: false)
    }

    var balance: Driver<String> {
        Observable
            .zip(
                walletsRepository.dataObservable,
                walletsRepository.stateObservable
            )
            .asDriver(onErrorJustReturn: ([], .loaded))
            .map { data, state in
                let data = data ?? []

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
            .asDriver()
    }
}
