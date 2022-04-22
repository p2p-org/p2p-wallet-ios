//
//  ConfirmReceivingBitcoin.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import RxCocoa
import RxSwift

protocol ConfirmReceivingBitcoinViewModelType {
    var isLoadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var accountStatusDriver: Driver<ConfirmReceivingBitcoin.RenBTCAccountStatus?> { get }

    func reload()
}

extension ConfirmReceivingBitcoin {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var renBTCStatusService: RenBTCStatusServiceType

        // MARK: - Properties

        private let disposeBag = DisposeBag()

        // MARK: - Subject

        private let isLoadingSubject = BehaviorRelay<Bool>(value: true)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let accountStatusSubject = BehaviorRelay<RenBTCAccountStatus?>(value: nil)
        private let payableWalletsSubject = BehaviorRelay<[Wallet]>(value: [])

        private let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)

        // MARK: - Initializer

        init() {
            reload()
        }

        // MARK: - Methods

        func reload() {
            isLoadingSubject.accept(true)
            errorSubject.accept(nil)
            accountStatusSubject.accept(nil)
            payableWalletsSubject.accept([])
            payingWalletSubject.accept(nil)

            renBTCStatusService.load()
                .andThen(renBTCStatusService.getPayableWallets())
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] payableWallets in
                    guard let self = self else { return }
                    self.isLoadingSubject.accept(false)
                    self.errorSubject.accept(nil)
                    self.accountStatusSubject.accept(!payableWallets.isEmpty ? .payingWalletAvailable : .topUpRequired)
                    self.payableWalletsSubject.accept(payableWallets)
                    self.payingWalletSubject.accept(payableWallets.first)
                }, onFailure: { [weak self] error in
                    guard let self = self else { return }
                    self.isLoadingSubject.accept(false)
                    self.errorSubject.accept(error.readableDescription)
                    self.accountStatusSubject.accept(nil)
                    self.payableWalletsSubject.accept([])
                    self.payingWalletSubject.accept(nil)
                })
                .disposed(by: disposeBag)
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }

    var accountStatusDriver: Driver<ConfirmReceivingBitcoin.RenBTCAccountStatus?> {
        accountStatusSubject.asDriver()
    }
}
