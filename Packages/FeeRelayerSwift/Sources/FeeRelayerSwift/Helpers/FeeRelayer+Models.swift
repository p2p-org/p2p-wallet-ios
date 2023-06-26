import Foundation
import SolanaSwift
import OrcaSwapSwift

public protocol FeeRelayerRelaySwapType: Encodable {}

public struct FeeTokenData: Codable, Equatable {
    public let name, code, mint, account: String
    public let exchangeRate: Double

    enum CodingKeys: String, CodingKey {
        case name, code, mint, account
        case exchangeRate = "exchange_rate"
    }
}

public struct FeeLimitForAuthorityResponse: Codable {
    let authority: [Int]
    let limits: Limits
    let processedFee: ProcessedFee

    enum CodingKeys: String, CodingKey {
        case authority, limits
        case processedFee = "processed_fee"
    }

    struct Limits: Codable {
        let useFreeFee: Bool
        let maxFeeAmount: UInt64
        let maxFeeCount: Int
        let maxTokenAccountCreationAmount: UInt64
        let maxTokenAccountCreationCount: Int
        let period: Period
    
        enum CodingKeys: String, CodingKey {
            case useFreeFee = "use_free_fee"
            case maxFeeAmount = "max_fee_amount"
            case maxFeeCount = "max_fee_count"
            case maxTokenAccountCreationAmount = "max_token_account_creation_amount"
            case maxTokenAccountCreationCount = "max_token_account_creation_count"
            case period
        }
    }

    struct Period: Codable {
        let secs, nanos: Int
    }

    struct ProcessedFee: Codable {
        let totalFeeAmount: UInt64
        let feeCount: Int
        let rentCount: Int
        
        enum CodingKeys: String, CodingKey {
            case totalFeeAmount = "total_fee_amount"
            case feeCount = "fee_count"
            case rentCount = "rent_count"
        }
    }
}

// MARK: - Top up
public struct TopUpWithSwapParams: Encodable {
    let userSourceTokenAccount: PublicKey
    let sourceTokenMint: PublicKey
    let userAuthority: PublicKey
    let topUpSwap: SwapData
    let feeAmount:  UInt64
    let signatures: SwapTransactionSignatures
    let blockhash:  String
    let statsInfo: StatsInfo
    
    enum CodingKeys: String, CodingKey {
        case userSourceTokenAccount = "user_source_token_account_pubkey"
        case sourceTokenMint = "source_token_mint_pubkey"
        case userAuthority = "user_authority_pubkey"
        case topUpSwap = "top_up_swap"
        case feeAmount = "fee_amount"
        case signatures = "signatures"
        case blockhash = "blockhash"
        case statsInfo = "info"
    }
    
    init(
        userSourceTokenAccount: PublicKey,
        sourceTokenMint: PublicKey,
        userAuthority: PublicKey,
        topUpSwap: SwapData,
        feeAmount: UInt64,
        signatures: SwapTransactionSignatures,
        blockhash: String,
        deviceType: StatsInfo.DeviceType,
        buildNumber: String?,
        environment: StatsInfo.Environment
    ) {
            self.userSourceTokenAccount = userSourceTokenAccount
            self.sourceTokenMint = sourceTokenMint
            self.userAuthority = userAuthority
            self.topUpSwap = topUpSwap
            self.feeAmount = feeAmount
            self.signatures = signatures
            self.blockhash = blockhash
            self.statsInfo = .init(
                operationType: .topUp,
                deviceType: deviceType,
                currency: sourceTokenMint.base58EncodedString,
                build: buildNumber,
                environment: environment
            )
        }
}

// MARK: - Swap
public struct SwapParams: Encodable {
    let userSourceTokenAccountPubkey: String
    let userDestinationPubkey: String
    let userDestinationAccountOwner: String?
    let sourceTokenMintPubkey: String
    let destinationTokenMintPubkey: String
    let userAuthorityPubkey: String
    let userSwap: SwapData
    let feeAmount: UInt64
    let signatures: SwapTransactionSignatures
    let blockhash: String
    
    enum CodingKeys: String, CodingKey {
        case userSourceTokenAccountPubkey = "user_source_token_account_pubkey"
        case userDestinationPubkey = "user_destination_pubkey"
        case userDestinationAccountOwner = "user_destination_account_owner"
        case sourceTokenMintPubkey = "source_token_mint_pubkey"
        case destinationTokenMintPubkey = "destination_token_mint_pubkey"
        case userAuthorityPubkey = "user_authority_pubkey"
        case userSwap = "user_swap"
        case feeAmount = "fee_amount"
        case signatures = "signatures"
        case blockhash = "blockhash"
    }
}

// MARK: - TransferParam
public struct TransferParam: Codable {
    let senderTokenAccountPubkey, recipientPubkey, tokenMintPubkey, authorityPubkey: String
    let amount, feeAmount: UInt64
    let decimals: UInt8
    let authoritySignature, blockhash: String
    
    enum CodingKeys: String, CodingKey {
        case senderTokenAccountPubkey = "sender_token_account_pubkey"
        case recipientPubkey = "recipient_pubkey"
        case tokenMintPubkey = "token_mint_pubkey"
        case authorityPubkey = "authority_pubkey"
        case amount = "amount"
        case decimals = "decimals"
        case feeAmount = "fee_amount"
        case authoritySignature = "authority_signature"
        case blockhash = "blockhash"
    }
}

// MARK: - RelayTransactionParam
public struct RelayTransactionParam: Codable {
    let instructions: [RequestInstruction]
    let signatures: [String: String]
    let pubkeys: [String]
    let blockhash: String
    let statsInfo: StatsInfo
    
    enum CodingKeys: String, CodingKey {
        case instructions
        case signatures
        case pubkeys
        case blockhash
        case statsInfo = "info"
    }
    
    public init(preparedTransaction: PreparedTransaction, statsInfo: StatsInfo) throws {
        guard let recentBlockhash = preparedTransaction.transaction.recentBlockhash
        else {throw FeeRelayerError.unknown}
        
        let message = try preparedTransaction.transaction.compileMessage()
        pubkeys = message.accountKeys.map {$0.base58EncodedString}
        blockhash = recentBlockhash
        instructions = message.instructions.enumerated().map {index, compiledInstruction -> RequestInstruction in
            let accounts: [RequestAccountMeta] = compiledInstruction.accounts.map { account in
                let pubkey = message.accountKeys[account]
                let meta = preparedTransaction.transaction.instructions[index].keys
                    .first(where: {$0.publicKey == pubkey})
                return .init(
                    pubkeyIndex: UInt8(account),
                    isSigner: meta?.isSigner ?? message.isAccountSigner(index: account),
                    isWritable: meta?.isWritable ?? message.isAccountWritable(index: account)
                )
            }
            
            return.init(
                programIndex: compiledInstruction.programIdIndex,
                accounts: accounts,
                data: compiledInstruction.data
            )
        }
        var signatures = [String: String]()
        for signer in preparedTransaction.signers {
            if let idx = pubkeys.firstIndex(of: signer.publicKey.base58EncodedString) {
                let idxString = "\(idx)"
                let signature = try preparedTransaction.findSignature(publicKey: signer.publicKey)
                signatures[idxString] = signature
            } else {
                throw FeeRelayerError.invalidSignature
            }
        }
        self.signatures = signatures
        self.statsInfo = statsInfo
    }
}

public struct RequestInstruction: Codable {
    let programIndex: UInt8
    let accounts: [RequestAccountMeta]
    let data: [UInt8]
    
    enum CodingKeys: String, CodingKey {
        case programIndex = "program_id"
        case accounts
        case data
    }
}

public struct RequestAccountMeta: Codable {
    let pubkeyIndex: UInt8
    let isSigner: Bool
    let isWritable: Bool
    
    enum CodingKeys: String, CodingKey {
        case pubkeyIndex = "pubkey"
        case isSigner = "is_signer"
        case isWritable = "is_writable"
    }
}

// MARK: - Swap data
public struct SwapData: Encodable {
    public init(_ swap: FeeRelayerRelaySwapType) {
        switch swap {
        case let swap as DirectSwapData:
            self.Spl = swap
            self.SplTransitive = nil
        case let swap as TransitiveSwapData:
            self.Spl = nil
            self.SplTransitive = swap
        default:
            fatalError("unsupported swap type")
        }
    }
    
    public let Spl: DirectSwapData?
    public let SplTransitive: TransitiveSwapData?
}

public struct TransitiveSwapData: FeeRelayerRelaySwapType, Equatable {
    let from: DirectSwapData
    let to: DirectSwapData
    let transitTokenMintPubkey: String
    let needsCreateTransitTokenAccount: Bool
    
    public init(
        from: DirectSwapData,
        to: DirectSwapData,
        transitTokenMintPubkey: String,
        needsCreateTransitTokenAccount: Bool
    ) {
        self.from = from
        self.to = to
        self.transitTokenMintPubkey = transitTokenMintPubkey
        self.needsCreateTransitTokenAccount = needsCreateTransitTokenAccount
    }
    
    enum CodingKeys: String, CodingKey {
        case from, to
        case transitTokenMintPubkey = "transit_token_mint_pubkey"
        case needsCreateTransitTokenAccount = "needs_create_transit_token_account"
    }
}

public struct DirectSwapData: FeeRelayerRelaySwapType, Equatable {
    let programId: String
    let accountPubkey: String
    let authorityPubkey: String
    let transferAuthorityPubkey: String
    let sourcePubkey: String
    let destinationPubkey: String
    let poolTokenMintPubkey: String
    let poolFeeAccountPubkey: String
    let amountIn: UInt64
    let minimumAmountOut: UInt64
    
    public init(programId: String, accountPubkey: String, authorityPubkey: String, transferAuthorityPubkey: String, sourcePubkey: String, destinationPubkey: String, poolTokenMintPubkey: String, poolFeeAccountPubkey: String, amountIn: UInt64, minimumAmountOut: UInt64) {
        self.programId = programId
        self.accountPubkey = accountPubkey
        self.authorityPubkey = authorityPubkey
        self.transferAuthorityPubkey = transferAuthorityPubkey
        self.sourcePubkey = sourcePubkey
        self.destinationPubkey = destinationPubkey
        self.poolTokenMintPubkey = poolTokenMintPubkey
        self.poolFeeAccountPubkey = poolFeeAccountPubkey
        self.amountIn = amountIn
        self.minimumAmountOut = minimumAmountOut
    }
    
    enum CodingKeys: String, CodingKey {
        case programId = "program_id"
        case accountPubkey = "account_pubkey"
        case authorityPubkey = "authority_pubkey"
        case transferAuthorityPubkey = "transfer_authority_pubkey"
        case sourcePubkey = "source_pubkey"
        case destinationPubkey = "destination_pubkey"
        case poolTokenMintPubkey = "pool_token_mint_pubkey"
        case poolFeeAccountPubkey = "pool_fee_account_pubkey"
        case amountIn = "amount_in"
        case minimumAmountOut = "minimum_amount_out"
    }
}

public struct SwapTransactionSignatures: Encodable {
    let userAuthoritySignature: String
    let transferAuthoritySignature: String?
    
    public init(userAuthoritySignature: String, transferAuthoritySignature: String?) {
        self.userAuthoritySignature = userAuthoritySignature
        self.transferAuthoritySignature = transferAuthoritySignature
    }
    
    enum CodingKeys: String, CodingKey {
        case userAuthoritySignature = "user_authority_signature"
        case transferAuthoritySignature = "transfer_authority_signature"
    }
}

// MARK: - Others
public enum RelayAccountStatus: Equatable, Codable, CustomStringConvertible {
    case notYetCreated
    case created(balance: UInt64)
    public var description: String {
        switch self {
        case .notYetCreated:
            return "Relay account is not yet created"
        case .created(let balance):
            return "Relay account is created, balance: \(balance)"
        }
    }
    
    public var balance: UInt64? {
        switch self {
        case .notYetCreated:
            return nil
        case .created(let balance):
            return balance
        }
    }
}

public struct FeesAndPools {
    public let fee: FeeAmount
    public let poolsPair: PoolsPair
}

public struct FeesAndTopUpAmount {
    public let feeInSOL: FeeAmount?
    public let topUpAmountInSOL: UInt64?
    public let feeInPayingToken: FeeAmount?
    public let topUpAmountInPayingToen: UInt64?
}

public struct TransferSolParams: Encodable {
    let sender: String
    let recipient: String
    let amount: Lamports
    var signature: String
    var blockhash: String
    let statsInfo: StatsInfo
    
    public init(
        sender: String,
        recipient: String,
        amount: Lamports,
        signature: String,
        blockhash: String,
        deviceType: StatsInfo.DeviceType,
        buildNumber: String?,
        environment: StatsInfo.Environment
    ) {
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.signature = signature
        self.blockhash = blockhash
        self.statsInfo = .init(
            operationType: .transfer,
            deviceType: deviceType,
            currency: "SOL",
            build: buildNumber,
            environment: environment
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case sender     =   "sender_pubkey"
        case recipient  =   "recipient_pubkey"
        case amount     =   "lamports"
        case signature
        case blockhash
        case statsInfo  =   "info"
    }
}

// MARK: - Transfer SPL Tokens
public struct TransferSPLTokenParams: Encodable {
    let sender: String
    let recipient: String
    let mintAddress: String
    let authority: String
    let amount: Lamports
    let decimals: Decimals
    var signature: String
    var blockhash: String
    let statsInfo: StatsInfo
    
    public init(
        sender: String,
        recipient: String,
        mintAddress: String,
        authority: String,
        amount: Lamports,
        decimals: Decimals,
        signature: String,
        blockhash: String,
        deviceType: StatsInfo.DeviceType,
        buildNumber: String?,
        environment: StatsInfo.Environment
    ) {
        self.sender = sender
        self.recipient = recipient
        self.mintAddress = mintAddress
        self.authority = authority
        self.amount = amount
        self.decimals = decimals
        self.signature = signature
        self.blockhash = blockhash
        self.statsInfo = .init(
            operationType: .transfer,
            deviceType: deviceType,
            currency: mintAddress,
            build: buildNumber,
            environment: environment
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case sender         =   "sender_token_account_pubkey"
        case recipient      =   "recipient_pubkey"
        case mintAddress    =   "token_mint_pubkey"
        case authority      =   "authority_pubkey"
        case amount
        case decimals
        case signature
        case blockhash
        case statsInfo      =   "info"
    }
}
