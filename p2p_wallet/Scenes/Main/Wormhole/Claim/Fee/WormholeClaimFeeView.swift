//
//  WormholeClaimFee.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.03.2023.
//

import KeyAppKitCore
import KeyAppUI
import SwiftUI
import Wormhole

struct WormholeClaimFee: View {
    @ObservedObject var viewModel: WormholeClaimFeeViewModel

    var body: some View {
        VStack {
            Image(uiImage: .fee)
                .padding(.top, 33)

            HStack {
                Circle()
                    .fill(Color(Asset.Colors.smoke.color))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(uiImage: .lightningFilled)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 15, height: 21.5)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.enjoyFreeTransactions)
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                    Text(L10n.WithKeyAppTheFirstTransactionIsFree.alsoAllTheTransactionsAbove300AreFree)
                        .apply(style: .text4)
                }
            }
            .padding(.all, 16)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(12)
            .padding(.top, 20)

            VStack(spacing: 24) {
                WormholeFeeView(title: "You will get", subtitle: viewModel.data.receive.crypto, detail: viewModel.data.receive.fiat)

                if let networkFee = viewModel.data.networkFee {
                    WormholeFeeView(title: "Network Fee", subtitle: networkFee.crypto, detail: networkFee.fiat)
                }

                if let accountsFee = viewModel.data.accountCreationFee {
                    WormholeFeeView(title: "Account creation Fee", subtitle: accountsFee.crypto, detail: accountsFee.fiat)
                }

                if let wormholeBridgeAndTrxFee = viewModel.data.wormholeBridgeAndTrxFee {
                    WormholeFeeView(title: "Wormhole Bridge and Transaction Fee", subtitle: wormholeBridgeAndTrxFee.crypto, detail: wormholeBridgeAndTrxFee.fiat)
                }
            }
            .padding(.top, 16)

            TextButtonView(title: L10n.ok, style: .second, size: .large) { viewModel.close() }
                .frame(height: TextButton.Size.large.height)
                .padding(.top, 20)
        }
        .padding(.horizontal, 16)
    }
}

private struct WormholeFeeView: View {
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Text(detail)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
        }
    }
}

struct WormholeClaimFee_Previews: PreviewProvider {
    static var previews: some View {
        WormholeClaimFee(
            viewModel: .init(
                data: .init(
                    receive: ("0.999717252 ETH", "~ $1,215.75", false),
                    networkFee: ("Paid by Key App", "Free", true),
                    accountCreationFee: ("0.999717252 WETH", "~ $1,215.75", false),
                    wormholeBridgeAndTrxFee: ("0.999717252 WETH", "~ $1,215.75", false)
                )
            )
        )
    }
}
