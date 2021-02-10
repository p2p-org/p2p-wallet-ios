//
//  _SendTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LazySubject

enum _SendTokenNavigatableScene {
    case chooseWallet
    case chooseAddress
    case scanQrCode
}

class _SendTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let wallets: [Wallet]
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<_SendTokenNavigatableScene>()
    let currentWallet = BehaviorRelay<Wallet?>(value: nil)
    let availableAmount = BehaviorRelay<Double>(value: 0)
    let isUSDMode = BehaviorRelay<Bool>(value: false)
    let fee = LazySubject<Double>(
        request: SolanaSDK.shared.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .map {
                let decimals = WalletsVM.ofCurrentUser.items.first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    )
    let errorSubject = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input
    let amountInput = BehaviorRelay<Double?>(value: nil)
    let destinationAddressInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(wallets: [Wallet], activeWallet: Wallet? = nil) {
        self.wallets = wallets
        self.currentWallet.accept(activeWallet ?? wallets.first)
        fee.reload()
        bind()
    }
    
    // MARK: - Methods
    private func bind() {
        // available amount
        Observable.combineLatest(
            currentWallet.distinctUntilChanged(),
            isUSDMode.distinctUntilChanged(),
            fee.observable.distinctUntilChanged()
        )
            .subscribe(onNext: {[weak self] _ in
                self?.bindAvailableAmount()
            })
            .disposed(by: disposeBag)
        
        // error
        Observable.combineLatest(
            currentWallet.distinctUntilChanged(),
            amountInput.distinctUntilChanged(),
            destinationAddressInput.distinctUntilChanged(),
            isUSDMode.distinctUntilChanged(),
            fee.observable.distinctUntilChanged()
        )
            .map { (wallet, amountInput, addressInput, _, _) -> String? in
                guard wallet != nil else {
                    return L10n.youMustSelectAWalletToSend
                }
                
                guard let amount = amountInput,
                      amount > 0
                else {
                    return L10n.amountIsNotValid
                }
                
                guard let solWallet = self.wallets.solWallet,
                      (self.fee.value ?? 0) <= (solWallet.amount ?? 0)
                else {
                    return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
                }
                
                let amountToCompare = self.availableAmount.value
                if amount > amountToCompare {
                    return L10n.insufficientFunds
                }
                
                if addressInput == nil || !NSRegularExpression.publicKey.matches(addressInput!)
                {
                    return L10n.theAddressIsNotValid
                }
                return nil
            }
            .bind(to: errorSubject)
            .disposed(by: disposeBag)
    }
    
    private func bindAvailableAmount() {
        // available amount
        if let wallet = currentWallet.value,
           var amount = wallet.amount,
           var fee = fee.value,
           let priceInUSD = wallet.priceInUSD
        {
            if isUSDMode.value {
                fee = fee * priceInUSD
                amount = wallet.amountInUSD
            }
            if wallet.symbol == "SOL" {
                amount -= fee
                if amount < 0 {
                    amount = 0
                }
            }
            availableAmount.accept(amount)
        }
    }
    
    // MARK: - Actions
    @objc func useAllBalance() {
        amountInput.accept(availableAmount.value)
    }
    
    @objc func chooseWallet() {
        navigationSubject.onNext(.chooseWallet)
    }
    
    @objc func switchMode() {
        isUSDMode.accept(!isUSDMode.value)
    }
    
    @objc func scanQrCode() {
        navigationSubject.onNext(.scanQrCode)
    }
    
    @objc func clearDestinationAddress() {
        destinationAddressInput.accept(nil)
    }
    
    @objc func send() {
        
    }
}
