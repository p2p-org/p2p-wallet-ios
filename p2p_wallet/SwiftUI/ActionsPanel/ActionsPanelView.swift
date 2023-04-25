//
//  ActionsPanelView.swift
//  p2p_wallet
//
//  Created by Ivan on 31.10.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct ActionsPanelView: View {
    let actions: [WalletActionType]
    let balance: String
    let usdAmount: String
    let action: (WalletActionType) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if !balance.isEmpty {
                Text(balance)
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.top, 24)
                    .padding(.bottom, usdAmount.isEmpty ? 32 : 12)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .padding(.top, 24)
            }
            if !usdAmount.isEmpty {
                Text(usdAmount)
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.bottom, 32)
            }
            HStack(spacing: 32) {
                ForEach(actions, id: \.text) { actionType in
                    tokenOperation(title: actionType.text, image: actionType.icon) {
                        action(actionType)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
        .background(Color(Asset.Colors.smoke.color))
    }

    private func tokenOperation(title: String, image: UIImage, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 4) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    Text(title)
                        .font(uiFont: .font(of: .label2, weight: .semibold))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(width: 56, height: 68)
            }
        )
    }
}
