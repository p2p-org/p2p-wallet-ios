//
//  ConfirmReceivingBitcoin.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import RxCocoa

protocol ConfirmReceivingBitcoinViewModelType {
    var outputDriver: Driver<ConfirmReceivingBitcoin.Output> { get }
}

extension ConfirmReceivingBitcoin {
    class ViewModel {
        // MARK: - Dependencies

        // MARK: - Subject

        private let outputSubject = BehaviorRelay<Output>(value: .init())

        // MARK: - Initializer

        init() {
            reload()
        }

        // MARK: - Methods

        private func reload() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                guard let self = self else { return }
                var currentState = self.outputSubject.value
                currentState.accountStatus = .payingWalletAvailable
                currentState.isLoading = false
                self.outputSubject.accept(currentState)
            }
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var outputDriver: Driver<ConfirmReceivingBitcoin.Output> {
        outputSubject.asDriver()
    }
}
