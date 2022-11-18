//
//  ActionsPanelView.swift
//  p2p_wallet
//
//  Created by Ivan on 31.10.2022.
//

import Combine
import SwiftUI
import KeyAppUI

struct ActionsPanelView: View {
    private var actionsPublisher: AnyPublisher<[WalletActionType], Never>
    private var balancePublisher: AnyPublisher<String, Never>
    private var usdAmountPublisher: AnyPublisher<String, Never>
    private var action: (WalletActionType) -> Void

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
        actionsView
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

    private var actionsView: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(balance)
                .font(uiFont: .font(of: .largeTitle, weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 24)
                .padding(.bottom, usdAmount.isEmpty ? 32 : 12)
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
//        .buttonStyle(PlainButtonStyle()) // prevent getting called on tapping cell
    }
}
