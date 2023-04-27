// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import FeeRelayerSwift
import Foundation
import SolanaSwift

public enum Amount: Equatable {
    case fiat(value: Double, currency: String)
    case token(lamport: UInt64, mint: String, decimals: Int)
}

public struct SendInputActionInitializeParams: Equatable {
    let feeRelayerContext: () async throws -> RelayContext

    public init(feeRelayerContext: @escaping () async throws -> RelayContext) {
        self.feeRelayerContext = feeRelayerContext
    }

    public init(feeRelayerContext: RelayContext) {
        self.feeRelayerContext = { feeRelayerContext }
    }

    public static func == (
        _: SendInputActionInitializeParams,
        _: SendInputActionInitializeParams
    ) -> Bool { true }
}

public enum SendInputAction: Equatable {
    case initialize(SendInputActionInitializeParams)

    case update

    case changeAmountInFiat(Double)
    case changeAmountInToken(Double)
    case changeUserToken(Token)
    case changeFeeToken(Token)
}

public struct SendInputServices {
    let swapService: SwapService
    let feeService: SendFeeCalculator
    let solanaAPIClient: SolanaAPIClient

    public init(swapService: SwapService, feeService: SendFeeCalculator, solanaAPIClient: SolanaAPIClient) {
        self.swapService = swapService
        self.feeService = feeService
        self.solanaAPIClient = solanaAPIClient
    }
}

public struct SendInputState: Equatable {
    public enum ErrorReason: Equatable {
        case networkConnectionError(NSError)

        case inputTooHigh(Double)
        case inputTooLow(Double)
        case insufficientFunds
        case insufficientAmountToCoverFee

        case feeCalculationFailed

        case requiredInitialize
        case missingFeeRelayer
        case initializeFailed(NSError)
        
        case unknown(NSError)
    }

    public enum Status: Equatable {
        case requiredInitialize
        case ready
        case error(reason: ErrorReason)
    }

    public struct RecipientAdditionalInfo: Equatable {
        /// Destination wallet
        public let walletAccount: BufferInfo<SolanaAddressInfo>?

        ///  Usable when recipient category is ``Recipient.Category.solanaAddress``
        public let splAccounts: [SolanaSwift.TokenAccount<AccountInfo>]

        public init(
            walletAccount: BufferInfo<SolanaAddressInfo>?,
            splAccounts: [SolanaSwift.TokenAccount<AccountInfo>]
        ) {
            self.walletAccount = walletAccount
            self.splAccounts = splAccounts
        }

        public static let zero: RecipientAdditionalInfo = .init(
            walletAccount: nil,
            splAccounts: []
        )
    }

    public let status: Status

    public let recipient: Recipient
    public let recipientAdditionalInfo: RecipientAdditionalInfo
    public let token: Token
    public let userWalletEnvironments: UserWalletEnvironments

    public let amountInFiat: Double
    public let amountInToken: Double

    /// Amount fee in SOL
    public let fee: FeeAmount

    /// Selected fee token
    public let tokenFee: Token

    /// Amount fee in Token (Converted from amount fee in SOL)
    public let feeInToken: FeeAmount

    public let minAmount: UInt64

    /// Fee relayer context
    ///
    /// Current state for free transactions
    public let feeRelayerContext: RelayContext?
    
    /// Send via link
    public let sendViaLinkSeed: String?
    public var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }

    public init(
        status: Status,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo,
        token: Token,
        userWalletEnvironments: UserWalletEnvironments,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount,
        tokenFee: Token,
        feeInToken: FeeAmount,
        feeRelayerContext: RelayContext?,
        minAmount: UInt64
        sendViaLinkSeed: String?
    ) {
        self.status = status
        self.recipient = recipient
        self.recipientAdditionalInfo = recipientAdditionalInfo
        self.token = token
        self.userWalletEnvironments = userWalletEnvironments
        self.amountInFiat = amountInFiat
        self.amountInToken = amountInToken
        self.fee = fee
        self.tokenFee = tokenFee
        self.feeInToken = feeInToken
        self.feeRelayerContext = feeRelayerContext
        self.minAmount = minAmount
        self.sendViaLinkSeed = sendViaLinkSeed
    }

    public static func zero(
        status: Status = .requiredInitialize,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo = .zero,
        token: Token,
        feeToken: Token,
        userWalletState: UserWalletEnvironments,
        feeRelayerContext: RelayContext? = nil,
        sendViaLinkSeed: String?
    ) -> SendInputState {
        .init(
            status: status,
            recipient: recipient,
            recipientAdditionalInfo: recipientAdditionalInfo,
            token: token,
            userWalletEnvironments: userWalletState,
            amountInFiat: 0,
            amountInToken: 0,
            fee: .zero,
            tokenFee: feeToken,
            feeInToken: .zero,
            feeRelayerContext: feeRelayerContext,
            minAmount: .zero
            sendViaLinkSeed: sendViaLinkSeed
        )
    }

    func copy(
        status: Status? = nil,
        recipient: Recipient? = nil,
        recipientAdditionalInfo: RecipientAdditionalInfo? = nil,
        token: Token? = nil,
        userWalletEnvironments: UserWalletEnvironments? = nil,
        amountInFiat: Double? = nil,
        amountInToken: Double? = nil,
        fee: FeeAmount? = nil,
        tokenFee: Token? = nil,
        feeInToken: FeeAmount? = nil,
        feeRelayerContext: RelayContext? = nil,
        minAmount: UInt64? = nil,
        sendViaLinkSeed: String?? = nil
    ) -> SendInputState {
        return .init(
            status: status ?? self.status,
            recipient: recipient ?? self.recipient,
            recipientAdditionalInfo: recipientAdditionalInfo ?? self.recipientAdditionalInfo,
            token: token ?? self.token,
            userWalletEnvironments: userWalletEnvironments ?? self.userWalletEnvironments,
            amountInFiat: amountInFiat ?? self.amountInFiat,
            amountInToken: amountInToken ?? self.amountInToken,
            fee: fee ?? self.fee,
            tokenFee: tokenFee ?? self.tokenFee,
            feeInToken: feeInToken ?? self.feeInToken,
            feeRelayerContext: feeRelayerContext ?? self.feeRelayerContext,
            minAmount: minAmount ?? self.minAmount
            sendViaLinkSeed: sendViaLinkSeed ?? self.sendViaLinkSeed
        )
    }
}

public extension SendInputState {
    var maxAmountInputInToken: Double {
        var balance: Lamports = userWalletEnvironments.wallets.first(where: { $0.token.address == token.address })?
            .lamports ?? 0

        if token.address == tokenFee.address {
            if balance >= feeInToken.total {
                balance = balance - feeInToken.total
            } else {
                return 0
            }
        }

        return Double(balance) / pow(10, Double(token.decimals))
    }

    var maxAmountInputInSOLWithLeftAmount: Double {
        var maxAmountInToken = maxAmountInputInToken.toLamport(decimals: token.decimals)

        guard
            let context = feeRelayerContext, token.isNativeSOL,
            maxAmountInToken >= context.minimumRelayAccountBalance
        else { return .zero }

        maxAmountInToken = maxAmountInToken - context.minimumRelayAccountBalance
        return Double(maxAmountInToken) / pow(10, Double(token.decimals))
    }

    var sourceWallet: Wallet? {
        userWalletEnvironments.wallets.first { (wallet: Wallet) -> Bool in
            wallet.token.address == token.address
        }
    }

    var feeWallet: Wallet? {
        userWalletEnvironments.wallets.first { (wallet: Wallet) -> Bool in
            wallet.token.address == tokenFee.address
        }
    }
}
