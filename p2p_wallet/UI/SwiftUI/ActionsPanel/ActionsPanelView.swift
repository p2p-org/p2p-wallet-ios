//
//  ActionsPanelView.swift
//  p2p_wallet
//
//  Created by Ivan on 31.10.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct ActionsPanelBridgeView: View {
    let actionsPublisher: AnyPublisher<[WalletActionType], Never>
    let balancePublisher: AnyPublisher<String, Never>
    let usdAmountPublisher: AnyPublisher<String, Never>
    let action: (WalletActionType) -> Void

    @State private var actions = [WalletActionType]()
    @State private var balance = ""
    @State private var usdAmount = ""

    init(
        actionsPublisher: AnyPublisher<[WalletActionType], Never>,
        balancePublisher: AnyPublisher<String, Never>,
        usdAmountPublisher: AnyPublisher<String, Never>? = nil,
        action: @escaping (WalletActionType) -> Void
    ) {
        self.actionsPublisher = actionsPublisher
        self.balancePublisher = balancePublisher
        self.usdAmountPublisher = usdAmountPublisher ?? Empty().eraseToAnyPublisher()
        self.action = action
    }

    var body: some View {
        ActionsPanelView(
            actions: actions,
            balance: balance,
            usdAmount: usdAmount,
            action: action
        )
        .onReceive(balancePublisher) { balance in
            self.balance = balance
        }
        .onReceive(usdAmountPublisher) { usdAmount in
            self.usdAmount = usdAmount
        }
        .onReceive(actionsPublisher) { actions in
            self.actions = actions
        }
    }
}

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
                    .padding(.bottom, usdAmount.isEmpty ? 46 : 12)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .padding(.top, 24)
            }
            if !usdAmount.isEmpty {
                Text(usdAmount)
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.bottom, 46)
            }
            HStack(spacing: 32) {
                ForEach(actions, id: \.text) { actionType in
                    tokenOperation(title: actionType.text, image: actionType.icon) {
                        action(actionType)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
        }
        .background(Color(Asset.Colors.smoke.color))
    }

    private func tokenOperation(title: String, image: ImageResource, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 4) {
                    Image(image)
                        .resizable()
                        .frame(width: 53, height: 53)
                        .scaledToFit()
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .label2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            }
        )
    }
}
