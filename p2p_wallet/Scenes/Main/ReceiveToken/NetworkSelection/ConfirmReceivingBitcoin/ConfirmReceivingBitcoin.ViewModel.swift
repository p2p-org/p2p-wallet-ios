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

        private let outputSubject = BehaviorRelay<Output>(value: .init(isLoading: false))
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var outputDriver: Driver<ConfirmReceivingBitcoin.Output> {
        outputSubject.asDriver()
    }
}
