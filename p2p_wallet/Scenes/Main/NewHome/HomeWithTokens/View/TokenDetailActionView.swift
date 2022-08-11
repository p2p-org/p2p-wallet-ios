//
//  TokenDetailActionView.swift
//  p2p_wallet
//
//  Created by Ivan on 10.08.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct TokenDetailActionView: View {
    private let actionSubject = PassthroughSubject<Action, Never>()
    var action: AnyPublisher<Action, Never> { actionSubject.eraseToAnyPublisher() }

//    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 28) {
            Text(L10n.actions)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text1, weight: .bold))
            VStack(spacing: 42) {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        actionView(
                            image: .homeBuyAction,
                            title: L10n.buy,
                            subtitle: L10n.usingApplePayOrBankCard,
                            action: {
                                actionSubject.send(.buy)
                            }
                        )
                        actionView(
                            image: .homeReceiveAction,
                            title: L10n.receive,
                            subtitle: L10n.fromAnotherWalletOrExchange,
                            action: {
                                actionSubject.send(.receive)
                            }
                        )
                    }
                    HStack(spacing: 16) {
                        actionView(
                            image: .homeTradeAction,
                            title: L10n.trade,
                            subtitle: L10n.oneCryptoForAnother,
                            action: {
                                actionSubject.send(.trade)
                            }
                        )
                        actionView(
                            image: .homeSendAction,
                            title: L10n.send,
                            subtitle: L10n.toPhoneNumberUsernameOrAddress,
                            action: {
                                actionSubject.send(.send)
                            }
                        )
                    }
                }
            }
            Button(
                action: {
                    //                    presentationMode.wrappedValue.dismiss()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .bold))
                }
            )
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(Asset.Colors.rain.color))
                .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }

    func actionView(
        image: UIImage,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                VStack(alignment: .leading, spacing: 12) {
                    Image(uiImage: image)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text1, weight: .bold))
                        Text(subtitle)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .font(uiFont: .font(of: .label1, weight: .regular))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(Asset.Colors.snow.color))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                )
            }
        )
    }
}

extension TokenDetailActionView {
    enum Action {
        case buy
        case receive
        case trade
        case send
    }
}
