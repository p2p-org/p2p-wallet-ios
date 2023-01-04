//
//  SendInputDebugView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.01.2023.
//

import Send
import SolanaSwift
import SwiftUI

struct SendInputDebugView: View {
    let state: SendInputState

    var body: some View {
        List {
            Section(header: Text("General")) {
                Row(key: "Status", value: String(reflecting: state.status))
                Row(key: "Auto selection fee token", value: String(reflecting: state.autoSelectionTokenFee))
                Row(key: "Token for paying fee", value: String(reflecting: state.token.symbol))
                // Row(key: "Enviroments", value: String(reflecting: state.userWalletEnvironments))
            }

            Section(header: Text("Recipient")) {
                Row(key: "Recipient", value: String(reflecting: state.recipient))
                Row(key: "Recipient SOL wallet exists", value: String(reflecting: state.recipientAdditionalInfo.walletAccount != nil))
                Row(key: "Detected recipients spl accounts", value: String(reflecting: state.recipientAdditionalInfo.splAccounts.count))
            }

            Section(header: Text("Input")) {
                Row(key: "Transfer token symbol", value: String(reflecting: state.token.symbol))
                Row(key: "Transfer token address", value: String(reflecting: state.token.address))
                Row(key: "Exact transfer amount (Token)", value: String(reflecting: state.amountInToken))
                Row(key: "Exact transfer amount (Fiat)", value: String(reflecting: state.amountInFiat))
            }

            Section(header: Text("Fee (SOL)")) {
                FeeView(fee: state.fee, decimals: Token.nativeSolana.decimals)
            }

            Section(header: Text("Fee (\(state.tokenFee.symbol)")) {
                FeeView(fee: state.fee, decimals: state.tokenFee.decimals)
            }

            Section(header: Text("Potential wallets for paying fee")) {
                ForEach(state.walletsForPayingFee, id: \.wallet.mintAddress) { walletForPayingFee in
                    VStack {
                        Row(key: "Token", value: String(reflecting: walletForPayingFee.wallet.token.symbol))
                        Row(key: "Fee in SOL", value: "")
                        FeeView(fee: walletForPayingFee.fee, decimals: Token.nativeSolana.decimals)
                        Row(key: "Fee in Token", value: "")
                        FeeView(fee: walletForPayingFee.feeInToken, decimals: walletForPayingFee.wallet.token.decimals)
                    }
                }
            }

            Section(header: Text("Fee relayer context")) {
                Row(key: "Status", value: String(reflecting: state.feeRelayerContext?.usageStatus))
                Row(key: "Relay account status", value: String(reflecting: state.feeRelayerContext?.relayAccountStatus))
                Row(key: "Fee payer address", value: String(reflecting: state.feeRelayerContext?.feePayerAddress.base58EncodedString))
            }
        }
    }
}

private struct FeeView: View {
    let fee: FeeAmount
    let decimals: UInt8

    var body: some View {
        VStack {
            Row(key: "Transaction", value: String(reflecting: fee.transaction.convertToBalance(decimals: decimals)))
            Row(key: "Account creation", value: String(reflecting: fee.accountBalances.convertToBalance(decimals: decimals)))
            Row(key: "Total", value: String(reflecting: fee.total.convertToBalance(decimals: decimals)))
        }
    }
}

private struct Row: View {
    let key: String
    let value: String

    var body: some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .lineLimit(3)
        }
    }
}
