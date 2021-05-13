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
    let pricesRepository: PricesRepository
    lazy var processTransactionViewModel: ProcessTransactionViewModel = {
        let viewModel = ProcessTransactionViewModel(transactionsManager: transactionManager, pricesRepository: pricesRepository)
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
    let isFiatMode = BehaviorRelay<Bool>(value: false)
    lazy var fee = LazySubject<Double>(
        request: solanaSDK.getFees()
            .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
            .map { [weak self] in
                let decimals = self?.solanaSDK.solDecimals
                return $0.convertToBalance(decimals: decimals)
            }
    )
    let errorSubject = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Input
    let amountInput = BehaviorRelay<String?>(value: nil)
    let destinationAddressInput = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initializers
    init(
        solanaSDK: SolanaSDK,
        walletsRepository: WalletsRepository,
        transactionManager: TransactionsManager,
        pricesRepository: PricesRepository,
        activeWallet: Wallet? = nil,
        destinationAddress: String? = nil
    ) {
        self.solanaSDK = solanaSDK
        self.walletsRepository = walletsRepository
        self.transactionManager = transactionManager
        self.pricesRepository = pricesRepository
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
            isFiatMode.distinctUntilChanged(),
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
            isFiatMode.distinctUntilChanged(),
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
           let priceInCurrentFiat = wallet.priceInCurrentFiat
        {
            if isFiatMode.value {
                fee = fee * priceInCurrentFiat
                amount = wallet.amountInCurrentFiat
            }
            if wallet.token.symbol == "SOL" {
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
        isFiatMode.accept(!isFiatMode.value)
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
              let price = currentWallet.priceInCurrentFiat,
              price > 0,
              var amount = amountInput.value.double
        else {
            return
        }
        
        let decimals = currentWallet.token.decimals
        
        let isFiatMode = self.isFiatMode.value
        
        if isFiatMode { amount = amount / price }
        
        if showScene {
            navigationSubject.onNext(.processTransaction)
        }
        
        var transaction = Transaction(
            signatureInfo: nil,
            type: .send,
            amount: -amount,
            symbol: currentWallet.token.symbol,
            status: .processing
        )
        
        // Verify address
        if !NSRegularExpression.publicKey.matches(receiver)
        {
            self.processTransactionViewModel.transactionInfo.accept(
                .init(
                    transaction: transaction,
                    error: SolanaSDK.Error.other(L10n.wrongWalletAddress)
                )
            )
            return
        } else {
            self.processTransactionViewModel.transactionInfo.accept(
                TransactionInfo(transaction: transaction)
            )
        }
        
        // prepare amount
        let lamport = amount.toLamport(decimals: decimals)
        
        // define token
        var request: Single<String>!
        let isSendingSOL = currentWallet.token.symbol == "SOL"
        if isSendingSOL {
            // SOLANA
            request = solanaSDK.sendSOL(to: receiver, amount: lamport)
        } else {
            // other tokens
            request = solanaSDK.sendSPLTokens(
                mintAddress: currentWallet.mintAddress,
                decimals: currentWallet.token.decimals,
                from: sender,
                to: receiver,
                amount: lamport
            )
        }
        
        request
            .subscribe(onSuccess: { signature in
                transaction.signatureInfo = .init(signature: signature)
                self.processTransactionViewModel.transactionInfo.accept(
                    TransactionInfo(transaction: transaction)
                )
                if !isSendingSOL {
                    self.transactionManager.process(transaction)
                }
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
            if amount.rounded(decimals: Int(wallet?.token.decimals ?? 0)) > amountToCompare.rounded(decimals: Int(wallet?.token.decimals ?? 0))
            {
                return L10n.insufficientFunds
            }
        }
        
        return nil
    }
}
