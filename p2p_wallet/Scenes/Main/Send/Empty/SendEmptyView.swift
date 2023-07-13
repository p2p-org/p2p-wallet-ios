//
//  SendEmptyView.swift
//  p2p_wallet
//
//  Created by Ivan on 06.12.2022.
//
import KeyAppUI
import SwiftUI

struct SendEmptyView: View {
    let buyCrypto: () -> Void
    let receive: () -> Void

    var body: some View {
        ZStack {
            Color(.smoke)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                Image(.emptySend)
                    .frame(maxWidth: .infinity)
                Text(L10n.sendingTokensHasNeverBeenEASIER)
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .title2, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                    .accessibilityIdentifier("SendEmptyView.title")
                VStack(alignment: .leading, spacing: 32) {
                    SendEmptyRowView(
                        image: .lightningFilled,
                        text: L10n.sendCryptoInTheSolanaNetworkInstantlyAndWithoutFees,
                        textAccessibilityIdentifier: "SendEmptyView.desc1"
                    )
                    SendEmptyRowView(
                        image: .user,
                        text: L10n.effortlesslySendTokensWithUsernamesInsteadOfLongAddresses,
                        textAccessibilityIdentifier: "SendEmptyView.desc2"
                    )
                }
                .padding(.leading, 16)
                .padding(.bottom, 20)
                BottomActionContainer {
                    VStack(spacing: 12) {
                        TextButtonView(
                            title: L10n.buyCrypto,
                            style: .inverted,
                            size: .large,
                            onPressed: buyCrypto
                        )
                        .frame(height: 56)
                        .accessibilityIdentifier("SendEmptyView.button1")
                        TextButtonView(
                            title: L10n.receive,
                            style: .inverted,
                            size: .large,
                            onPressed: receive
                        )
                        .frame(height: 56)
                        .accessibilityIdentifier("SendEmptyView.button2")
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

struct SendEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        SendEmptyView(buyCrypto: {}, receive: {})
    }
}
