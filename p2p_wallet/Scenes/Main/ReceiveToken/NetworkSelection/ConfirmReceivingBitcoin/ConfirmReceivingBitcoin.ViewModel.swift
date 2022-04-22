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

        // MARK: - Initializer

        init() {
            reload()
        }

        // MARK: - Methods

        func reload() {
            isLoadingSubject.accept(true)
            errorSubject.accept(nil)
            accountStatusSubject.accept(nil)
            renBTCStatusService.load()
                .andThen(renBTCStatusService.isRenBTCAccountCreatable())
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] isCreatable in
                    guard let self = self else { return }
                    self.isLoadingSubject.accept(false)
                    self.errorSubject.accept(nil)
                    self.accountStatusSubject.accept(isCreatable ? .payingWalletAvailable : .topUpRequired)
                }, onFailure: { [weak self] error in
                    guard let self = self else { return }
                    self.isLoadingSubject.accept(false)
                    self.errorSubject.accept(error.readableDescription)
                    self.accountStatusSubject.accept(nil)
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
