//
//  SendTokenViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/02/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LazySubject

class SendTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let wallets: [Wallet]
    let disposeBag = DisposeBag()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<Navigation>()
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
        Observable.combineLatest(currentWallet, isUSDMode, fee.observable)
            .subscribe(onNext: {[weak self] _ in
                self?.bindAvailableAmount()
            })
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
        let vc = ChooseWalletVC()
        vc.completion = {wallet in
            guard let wallet = WalletsVM.ofCurrentUser.data.first(where: {$0.pubkey == wallet.pubkey}) else {return}
            vc.back()
            self.currentWallet.accept(wallet)
        }
        navigationSubject.onNext(.present(vc))
    }
    
    @objc func switchMode() {
        isUSDMode.accept(!isUSDMode.value)
    }
    
    @objc func scanQrCode() {
        let vc = QrCodeScannerVC()
        vc.callback = { code in
            if NSRegularExpression.publicKey.matches(code) {
                self.destinationAddressInput.accept(code)
                return true
            }
            return false
        }
        vc.modalPresentationStyle = .custom
        navigationSubject.onNext(.present(vc))
    }
}
