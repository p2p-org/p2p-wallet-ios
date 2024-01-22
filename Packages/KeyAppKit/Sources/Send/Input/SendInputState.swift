import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift

public enum Amount: Equatable {
    case fiat(value: Double, currency: String)
    case token(lamport: UInt64, mint: String, decimals: Int)
}

public enum SendInputAction: Equatable {
    case initialize

    case update

    case changeAmountInFiat(Double)
    case changeAmountInToken(Double)
    case changeUserToken(SolanaAccount)
    case changeFeeToken(SolanaAccount)
}

public struct SendInputServices {
    let orcaSwap: OrcaSwapType
    let feeService: SendFeeCalculator
    let solanaAPIClient: SolanaAPIClient
    let rpcService: SendRPCService

    public init(
        orcaSwap: OrcaSwapType,
        feeService: SendFeeCalculator,
        solanaAPIClient: SolanaAPIClient,
        rpcService: SendRPCService
    ) {
        self.orcaSwap = orcaSwap
        self.feeService = feeService
        self.solanaAPIClient = solanaAPIClient
        self.rpcService = rpcService
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
        public let splAccounts: [SolanaSwift.TokenAccount<SPLTokenAccountState>]

        public init(
            walletAccount: BufferInfo<SolanaAddressInfo>?,
            splAccounts: [SolanaSwift.TokenAccount<SPLTokenAccountState>]
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
    public let token: SolanaAccount
    public let userWalletEnvironments: UserWalletEnvironments

    public let amountInFiat: Double
    public let amountInToken: Double

    /// Amount fee in SOL
    public let fee: FeeAmount

    /// Selected fee token
    public let tokenFee: SolanaAccount

    /// Amount fee in Token (Converted from amount fee in SOL)
    public let feeInToken: FeeAmount

    /// The list of tokens' mint that can be used to pay fee
    public let feePayableTokenMints: [String]

    /// Lamports per signature
    public let lamportsPerSignature: UInt64

    /// Minimum relay account balance
    public let minimumRelayAccountBalance: UInt64

    /// Limit for free transactions
    public let limit: SendServiceLimitResponse

    /// Send via link
    public let sendViaLinkSeed: String?
    public var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }

    public init(
        status: Status,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo,
        token: SolanaAccount,
        userWalletEnvironments: UserWalletEnvironments,
        amountInFiat: Double,
        amountInToken: Double,
        fee: FeeAmount,
        tokenFee: SolanaAccount,
        feeInToken: FeeAmount,
        feePayableTokenMints: [String],
        lamportsPerSignature: UInt64,
        minimumRelayAccountBalance: UInt64,
        limit: SendServiceLimitResponse,
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
        self.feePayableTokenMints = feePayableTokenMints
        self.lamportsPerSignature = lamportsPerSignature
        self.minimumRelayAccountBalance = minimumRelayAccountBalance
        self.limit = limit
        self.sendViaLinkSeed = sendViaLinkSeed
    }

    public static func zero(
        status: Status = .requiredInitialize,
        recipient: Recipient,
        recipientAdditionalInfo: RecipientAdditionalInfo = .zero,
        token: SolanaAccount,
        feeToken: SolanaAccount,
        userWalletState: UserWalletEnvironments,
        feePayableTokenMints: [String] = [],
        feeRelayerContext _: RelayContext? = nil,
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
            feePayableTokenMints: feePayableTokenMints,
            lamportsPerSignature: 5000,
            minimumRelayAccountBalance: 890_880,
            limit: .init(
                networkFee: .init(
                    remainingAmount: .max,
                    remainingTransactions: .max
                ),
                tokenAccountRent: .init(remainingAmount: 0, remainingTransactions: 0)
            ),
            sendViaLinkSeed: sendViaLinkSeed
        )
    }

    func copy(
        status: Status? = nil,
        recipient: Recipient? = nil,
        recipientAdditionalInfo: RecipientAdditionalInfo? = nil,
        token: SolanaAccount? = nil,
        userWalletEnvironments: UserWalletEnvironments? = nil,
        amountInFiat: Double? = nil,
        amountInToken: Double? = nil,
        fee: FeeAmount? = nil,
        tokenFee: SolanaAccount? = nil,
        feeInToken: FeeAmount? = nil,
        feePayableTokenMints: [String]? = nil,
        lamportsPerSignature: UInt64? = nil,
        minimumRelayAccountBalance: UInt64? = nil,
        limit: SendServiceLimitResponse? = nil,
        sendViaLinkSeed: String?? = nil
    ) -> SendInputState {
        .init(
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
            feePayableTokenMints: feePayableTokenMints ?? self.feePayableTokenMints,
            lamportsPerSignature: lamportsPerSignature ?? self.lamportsPerSignature,
            minimumRelayAccountBalance: minimumRelayAccountBalance ?? self.minimumRelayAccountBalance,
            limit: limit ?? self.limit,
            sendViaLinkSeed: sendViaLinkSeed ?? self.sendViaLinkSeed
        )
    }
}

public extension SendInputState {
    var maxAmountInputInToken: Double {
        var balance: Lamports = userWalletEnvironments.wallets
            .first(where: { $0.token.mintAddress == token.mintAddress })?
            .lamports ?? 0

        if token.mintAddress == tokenFee.mintAddress {
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

        guard token.isNative,
              maxAmountInToken >= minimumRelayAccountBalance
        else { return .zero }

        maxAmountInToken = maxAmountInToken - minimumRelayAccountBalance
        return Double(maxAmountInToken) / pow(10, Double(token.decimals))
    }

    var sourceWallet: SolanaAccount? {
        userWalletEnvironments.wallets.first { (wallet: SolanaAccount) -> Bool in
            wallet.token.mintAddress == token.mintAddress
        }
    }

    var feeWallet: SolanaAccount? {
        userWalletEnvironments.wallets.first { (wallet: SolanaAccount) -> Bool in
            wallet.token.mintAddress == tokenFee.mintAddress
        }
    }
}
