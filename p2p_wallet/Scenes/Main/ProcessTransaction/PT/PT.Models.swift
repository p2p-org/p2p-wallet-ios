//
//  PT.Models.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import SolanaSwift

// MARK: - APIClient
protocol ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double>
    func getSignatureStatus(signature: String, configs: SolanaSDK.RequestConfiguration?) -> Single<SolanaSDK.SignatureStatus>
}
extension SolanaSDK: ProcessTransactionAPIClient {
    func getReimbursedAmountForClosingToken() -> Single<Double> {
        getCreatingTokenAccountFee().map {$0.convertToBalance(decimals: 9)}
    }
}

// MARK: - Transaction type
protocol ProcessingTransactionType {
    func createRequest() -> Single<String>
    var mainDescription: String {get}
}

extension ProcessingTransactionType {
    var isSwap: Bool {
        self is PT.OrcaSwapTransaction || self is PT.SwapTransaction
    }
}

extension PT {
    struct SwapTransaction: ProcessingTransactionType {
        var mainDescription: String {
            fatalError()
        }
        
        func createRequest() -> Single<String> {
            fatalError()
        }
    }
    
    struct OrcaSwapTransaction: ProcessingTransactionType {
        let swapService: SwapServiceType
        let sourceWallet: Wallet
        let destinationWallet: Wallet
        let payingWallet: Wallet?
        let poolsPair: Swap.PoolsPair
        let amount: Double
        let estimatedAmount: Double
        let slippage: Double
        let fees: [PayingFee]
        
        var mainDescription: String {
            amount.toString(maximumFractionDigits: 9) + " " + sourceWallet.token.symbol +
                " → " +
                estimatedAmount.toString(maximumFractionDigits: 9) + " " + destinationWallet.token.symbol
        }
        
        func createRequest() -> Single<String> {
            // check if payingWallet has enough balance to cover fee
            let checkRequest: Completable
            if let fees = fees.networkFees,
               let payingWallet = payingWallet
            {
                checkRequest = swapService.calculateNetworkFeeInPayingToken(networkFee: fees, payingTokenMint: payingWallet.mintAddress)
                    .map { amount -> Bool in
                        if let amount = amount?.total,
                            let currentAmount = payingWallet.lamports,
                            amount > currentAmount
                        {
                            throw SolanaSDK.Error.other(
                                L10n.yourAccountDoesNotHaveEnoughToCoverFees(payingWallet.token.symbol)
                                + ". "
                                + L10n.needsAtLeast("\(amount.convertToBalance(decimals: payingWallet.token.decimals)) \(payingWallet.token.symbol)")
                                + ". "
                                + L10n.pleaseChooseAnotherTokenAndTryAgain
                            )
                        }
                        return true
                    }
                    .asCompletable()
            } else {
                checkRequest = .empty()
            }
            
            let request = checkRequest
                .andThen(
                    swapService.swap(
                        sourceAddress: sourceWallet.pubkey!,
                        sourceTokenMint: sourceWallet.mintAddress,
                        destinationAddress: destinationWallet.pubkey,
                        destinationTokenMint: destinationWallet.mintAddress,
                        payingTokenAddress: payingWallet?.pubkey,
                        payingTokenMint: payingWallet?.mintAddress,
                        poolsPair: poolsPair,
                        amount: amount.toLamport(decimals: sourceWallet.token.decimals),
                        slippage: slippage
                    ).map { $0.first ?? ""}
                )
            
            return request
        }
    }
    
    struct CloseTransaction: ProcessingTransactionType {
        let solanaSDK: SolanaSDK
        let closingWallet: Wallet
        let reimbursedAmount: UInt64
        
        var mainDescription: String {
            L10n.closeAccount(closingWallet.token.symbol)
        }
        
        func createRequest() -> Single<String> {
            guard let pubkey = closingWallet.pubkey else {
                return .error(SolanaSDK.Error.unknown)
            }
            return solanaSDK.closeTokenAccount(tokenPubkey: pubkey)
        }
    }
    
    struct SendTransaction: ProcessingTransactionType {
        let sendService: SendServiceType
        let network: SendToken.Network
        let sender: Wallet
        let receiver: SendToken.Recipient
        let amount: SolanaSDK.Lamports
        let payingFeeWallet: Wallet?
        let isSimulation: Bool
        
        var mainDescription: String {
            amount.convertToBalance(decimals: sender.token.decimals)
                .toString(maximumFractionDigits: 9) +
            " " +
            sender.token.symbol + " → " + (receiver.name ?? receiver.address.truncatingMiddle(numOfSymbolsRevealed: 4))
        }
        
        func createRequest() -> Single<String> {
            sendService.send(
                from: sender,
                receiver: receiver.address,
                amount: amount.convertToBalance(decimals: sender.token.decimals),
                network: network,
                payingFeeWallet: payingFeeWallet
            )
        }
    }
}

// MARK: - Transaction status
extension PT {
    struct TransactionInfo {
        enum TransactionStatus {
            static let maxConfirmed = 31
            
            case sending
            case confirmed(_ numberOfConfirmed: Int)
            case finalized
            case error(_ error: Swift.Error)
            
            var progress: Float {
                switch self {
                case .sending:
                    return 0
                case .confirmed(var numberOfConfirmed):
                    // treat all number of confirmed as unfinalized
                    if numberOfConfirmed >= Self.maxConfirmed {
                        numberOfConfirmed = Self.maxConfirmed - 1
                    }
                    // return
                    return Float(numberOfConfirmed) / Float(Self.maxConfirmed)
                case .finalized, .error:
                    return 1
                }
            }
            
            var error: Swift.Error? {
                switch self {
                case .error(let error):
                    return error
                default:
                    return nil
                }
            }
        }
        
        var transactionId: String?
        var status: TransactionStatus
    }
    
    enum Error: Swift.Error {
        case notEnoughNumberOfConfirmations
    }
}
