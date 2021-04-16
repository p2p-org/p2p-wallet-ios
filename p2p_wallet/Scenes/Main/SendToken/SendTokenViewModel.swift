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
import Action

enum SendTokenNavigatableScene {
    case chooseWallet
    case chooseAddress
    case scanQrCode
    case processTransaction
}

class SendTokenViewModel {
    // MARK: - Constants
    
    // MARK: - Properties
    let walletsRepository: WalletsRepository
    let disposeBag = DisposeBag()
    let solanaSDK: SolanaSDK
    let transactionManager: TransactionsManager
    lazy var processTransactionViewModel: ProcessTransactionViewModel = {
        let viewModel = ProcessTransactionViewModel(transactionsManager: transactionManager)
        viewModel.tryAgainAction = CocoaAction {
            self.send()
            return .just(())
        }
        return viewModel
    }()
    
    // MARK: - Subjects
    let navigationSubject = PublishSubject<SendTokenNavigatableScene>()
    let currentWallet = BehaviorRelay<Wallet?>(value: nil)
    let availableAmount = BehaviorRelay<Double>(value: 0)
    let isUSDMode = BehaviorRelay<Bool>(value: false)
    lazy var fee = LazySubject<Double>(
        request: solanaSDK.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .map {
                let decimals = self.walletsRepository.getWallets().first(where: {$0.symbol == "SOL"})?.decimals ?? 9
                return Double($0) * pow(Double(10), -Double(decimals))
            }
    )
    let errorSubject = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input
    let amountInput = BehaviorRelay<String?>(value: nil)
    let destinationAddressInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(solanaSDK: SolanaSDK, walletsRepository: WalletsRepository, transactionManager: TransactionsManager, activeWallet: Wallet? = nil, destinationAddress: String? = nil) {
        self.solanaSDK = solanaSDK
        self.walletsRepository = walletsRepository
        self.transactionManager = transactionManager
        self.currentWallet.accept(activeWallet ?? walletsRepository.getWallets().first)
        self.destinationAddressInput.accept(destinationAddress)
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
            .map {_ in self.verifyError()}
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
    
    func isDestinationWalletValid() -> Bool {
        guard let input = destinationAddressInput.value else {return false}
        return NSRegularExpression.publicKey.matches(input)
    }
    
    // MARK: - Actions
    @objc func useAllBalance() {
        amountInput.accept(availableAmount.value.toString(maximumFractionDigits: 9, groupingSeparator: nil))
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
    
    @objc func sendAndShowProcessTransactionScene() {
        send(showScene: true)
    }
    
    private func send(showScene: Bool = false) {
        guard errorSubject.value == nil,
              let currentWallet = currentWallet.value,
              let sender = currentWallet.pubkey,
              let receiver = destinationAddressInput.value,
              let price = currentWallet.priceInUSD,
              price > 0,
              var amount = amountInput.value.double,
              let decimals = currentWallet.decimals
        else {
            return
        }
        let isUSDMode = self.isUSDMode.value
        
        if isUSDMode { amount = amount / price }
        
        if showScene {
            navigationSubject.onNext(.processTransaction)
        }
        
        // prepare amount
        let lamport = amount.toLamport(decimals: decimals)
        
        // define token
        var request: Single<String>!
        if currentWallet.symbol == "SOL" {
            // SOLANA
            request = solanaSDK.sendSOL(to: receiver, amount: lamport)
        } else {
            // other tokens
            request = solanaSDK.sendSPLTokens(mintAddress: currentWallet.mintAddress, from: sender, to: receiver, amount: lamport)
        }
        
        var transaction = Transaction(
            signatureInfo: nil,
            type: .send,
            amount: -amount,
            symbol: currentWallet.symbol,
            status: .processing
        )
        
        self.processTransactionViewModel.transactionInfo.accept(
            TransactionInfo(transaction: transaction)
        )
        
        request
            .subscribe(onSuccess: { signature in
                transaction.signatureInfo = .init(signature: signature)
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction)
                )
                self.transactionManager.process(transaction)
            }, onFailure: {error in
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction, error: error)
                )
            })
            .disposed(by: disposeBag)
    }
    
    /// Verify current context
    /// - Returns: Error string, nil if no error appear
    private func verifyError() -> String? {
        let wallet = self.currentWallet.value
        let amountInput = self.amountInput.value
        let addressInput = self.destinationAddressInput.value
        let fee = self.fee.value
        
        // Verify wallet
        guard wallet != nil else {
            return L10n.youMustSelectAWalletToSend
        }
        
        // Verify amount if it has been entered
        if let amountInput = amountInput,
           let amount = amountInput.double
        {
            // Amount is not valid
            if amount <= 0 {
                return L10n.amountIsNotValid
            }
            
            // Verify with fee
            if let fee = fee,
               let solAmount = self.walletsRepository.solWallet?.amount,
               fee > solAmount
            {
                return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
            }
            
            // Verify amount
            let amountToCompare = self.availableAmount.value
            if amount.rounded(decimals: wallet?.decimals) > amountToCompare.rounded(decimals: wallet?.decimals)
            {
                return L10n.insufficientFunds
            }
        }
        
        // Verify address if it has been entered
        if let addressInput = addressInput,
           addressInput.isEmpty
        {
            return L10n.theAddressIsNotValid
        }
        
        return nil
    }
}
