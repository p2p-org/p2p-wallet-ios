//
//  SendEmptyView.swift
//  p2p_wallet
//
//  Created by Ivan on 06.12.2022.
//

import SwiftUI
import KeyAppUI

struct SendEmptyView: View {
    let buyCrypto: (() -> Void)
    let receive: (() -> Void)

    var body: some View {
        ZStack {
            Color(UIColor.f2F5Fa)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                Image(uiImage: .emptySend)
                    .frame(maxWidth: .infinity)
                Text(L10n.sendingTokensHasNeverBeenEASIER)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title2, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                VStack(alignment: .leading, spacing: 32) {
                    rowView(
                        image: .sendEmptyLighting,
                        text: L10n.sendCryptoInTheSolanaNetworkInstantlyAndWithoutFees
                    )
                    rowView(
                        image: .sendEmptyPerson,
                        text: L10n.effortlesslySendTokensWithUsernamesInsteadOfLongAddresses
                    )
                }
                .padding(.leading, 16)
                .padding(.bottom, 20)
                BottomActionContainer {
                    VStack(spacing: 12) {
                        Button(
                            action: {
                                buyCrypto()
                            },
                            label: {
                                Text(L10n.buyCrypto)
                                    .foregroundColor(Color(Asset.Colors.night.color))
                                    .font(uiFont: .font(of: .text3, weight: .semibold))
                                    .frame(height: 56)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(Asset.Colors.snow.color))
                                    .cornerRadius(12)
                            }
                        )
                        Button(
                            action: {
                                receive()
                            },
                            label: {
                                Text(L10n.receive)
                                    .foregroundColor(Color(Asset.Colors.lime.color))
                                    .font(uiFont: .font(of: .text3, weight: .semibold))
                                    .frame(height: 56)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.clear)
                            }
                        )
                    }
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }

    private func rowView(image: UIImage, text: String) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: image)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text3))
        }
    }
}

struct SendEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        SendEmptyView(buyCrypto: {}, receive: {})
    }
}
