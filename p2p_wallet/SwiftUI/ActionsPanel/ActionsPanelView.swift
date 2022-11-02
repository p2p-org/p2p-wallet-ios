//
//  ActionsPanelView.swift
//  p2p_wallet
//
//  Created by Ivan on 31.10.2022.
//

import Combine
import SwiftUI
import KeyAppUI

// TODO: - Ivan Babich. PWN-5791
struct ActionsPanelView: View {
    private var balancePublisher: AnyPublisher<String, Never>
    private var usdAmountPublisher: AnyPublisher<String, Never>
    @State private var balance = ""
    @State private var usdAmount = ""

    init(
        balancePublisher: AnyPublisher<String, Never>,
        usdAmountPublisher: AnyPublisher<String, Never>? = nil
    ) {
        self.balancePublisher = balancePublisher
        self.usdAmountPublisher = usdAmountPublisher ?? Empty().eraseToAnyPublisher()
    }

    var body: some View {
        actions
    }

    private var actions: some View {
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
                tokenOperation(title: L10n.buy, image: .homeBuy) {
//                    viewModel.buy()
                }
                tokenOperation(title: L10n.receive, image: .homeReceive) {
//                    viewModel.receive()
                }
                tokenOperation(title: L10n.send, image: .homeSend) {
//                    viewModel.send()
                }
                tokenOperation(title: L10n.swap, image: .homeSwap) {
//                    viewModel.swap()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
        .background(Color(Asset.Colors.smoke.color))
        .onReceive(balancePublisher) { balance in
            self.balance = balance
        }
        .onReceive(usdAmountPublisher) { usdAmount in
            self.usdAmount = usdAmount
        }
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
