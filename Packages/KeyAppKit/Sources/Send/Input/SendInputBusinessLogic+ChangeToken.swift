import BigDecimal
import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import SendService
import SolanaSwift

extension SendInputBusinessLogic {
    static func changeToken(
        state: SendInputState,
        token: SolanaAccount,
        services: SendInputServices
    ) async -> SendInputState {
        do {
            // Update fee in SOL and source token
            let fee: FeeAmount
            let token2022TransferFeePerOneToken: [String: BigDecimal]?
            if token.tokenProgramId == Token2022Program.id.base58EncodedString {
                if let response = try? await services.rpcService
                    .transfer(
                        userWallet: state.userWalletEnvironments.userWalletAddress ?? "",
                        mint: token.mintAddress,
                        amount: 1.toLamport(decimals: token.decimals),
                        recipient: state.recipient.address,
                        transferMode: .exactIn,
                        networkFeePayer: .userSOL,
                        taRentPayer: .userSOL
                    ),
                    let string = response.token2022_TransferFee?.amount.amount,
                    let transferFee = BigDecimal(string),
                    let recipientGets = BigDecimal(response.recipientGetsAmount.amount),
                    recipientGets != 0
                {
                    var currentValue = state.token2022TransferFeePerReceivingAmountMap
                    currentValue[token.mintAddress] = transferFee / recipientGets
                    token2022TransferFeePerOneToken = currentValue
                } else {
                    token2022TransferFeePerOneToken = nil
                }
            } else {
                token2022TransferFeePerOneToken = nil
            }
            fee = try await services.feeCalculator.getFees(
                from: token,
                recipient: state.recipient,
                recipientAdditionalInfo: state.recipientAdditionalInfo,
                lamportsPerSignature: state.lamportsPerSignature,
                limit: state.limit
            ) ?? .zero

            var state = state.copy(
                token: token,
                fee: fee,
                token2022TransferFeePerOneToken: token2022TransferFeePerOneToken
            )

            let feeInfo = await autoSelectTokenFee(
                userWallets: state.userWalletEnvironments.wallets,
                feeInSol: state.fee,
                token: state.token,
                services: services,
                whitelistMints: state.feePayableTokenMints
            )

            state = state.copy(
                tokenFee: feeInfo.token,
                feeInToken: feeInfo.fee
            )

            state = await sendInputChangeAmountInToken(state: state, amount: state.amountInToken, services: services)
            state = await validateFee(state: state)

            print(state.status)
            return state
        } catch {
            return state.copy(status: .error(reason: .unknown(error as NSError)))
        }
    }

    static func validateFee(state: SendInputState) async -> SendInputState {
        guard state.fee != .zero else { return state }
        guard let wallet: SolanaAccount = state.userWalletEnvironments.wallets
            .first(where: { (wallet: SolanaAccount) in wallet.token.mintAddress == state.tokenFee.mintAddress })
        else {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }

        if state.feeInToken.total > wallet.lamports {
            return state.copy(status: .error(reason: .insufficientAmountToCoverFee))
        }

        return state
    }

    static func autoSelectTokenFee(
        userWallets: [SolanaAccount],
        feeInSol: FeeAmount,
        token: SolanaAccount,
        services: SendInputServices,
        whitelistMints: [String]
    ) async -> (token: SolanaAccount, fee: FeeAmount?) {
        var preferOrder = ["SOL": 2]
        if !preferOrder.keys.contains(token.symbol) {
            preferOrder[token.symbol] = 1
        }

        let sortedWallets = userWallets.sorted { (lhs: SolanaAccount, rhs: SolanaAccount) -> Bool in
            let lhsValue = (preferOrder[lhs.token.symbol] ?? 3)
            let rhsValue = (preferOrder[rhs.token.symbol] ?? 3)

            if lhsValue < rhsValue {
                return true
            } else if lhsValue == rhsValue {
                let lhsCost = lhs.amount ?? 0
                let rhsCost = rhs.amount ?? 0

                return lhsCost < rhsCost
            }

            return false
        }
        .filter { whitelistMints.contains($0.mintAddress) }

        for wallet in sortedWallets {
            do {
                let feeInToken = try (await services.feeCalculator
                    .calculateFeeInPayingToken(
                        feeInSOL: feeInSol,
                        payingFeeTokenMint: PublicKey(string: wallet.token.mintAddress)
                    )) ?? .zero

                if feeInToken.total <= wallet.lamports {
                    return (wallet, feeInToken)
                }
            } catch {
                continue
            }
        }

        return (.nativeSolana(pubkey: nil, lamport: nil), feeInSol)
    }
}
