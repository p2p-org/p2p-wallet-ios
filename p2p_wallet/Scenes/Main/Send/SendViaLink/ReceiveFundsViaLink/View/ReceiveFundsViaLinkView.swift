//
//  ReceiveFundsViaLinkView.swift
//  p2p_wallet
//
//  Created by Ivan on 23.03.2023.
//

import KeyAppUI
import SwiftUI
import SkeletonUI
import SolanaSwift

struct ReceiveFundsViaLinkView: View {
    
    @ObservedObject var viewModel: ReceiveFundsViaLinkViewModel
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .pending:
            skeleton
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .sheetHeader(title: L10n.receiveFundsViaOneTimeLink, withSeparator: false, bottomPadding: 4)
        case let .loaded(model):
            confirmView(
                date: model.date,
                token: model.token,
                cryptoAmount: model.cryptoAmount
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .sheetHeader(title: L10n.receiveFundsViaOneTimeLink, withSeparator: false, bottomPadding: 4)
        case let .confirmed(cryptoAmount):
            youReceivedToken(cryptoAmount: cryptoAmount)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .sheetHeader(title: nil, withSeparator: false)
        case .failure:
            SendViaLinkClaimErrorView(
                isLoading: $viewModel.isReloading,
                reloadClicked: {
                    viewModel.reloadClicked()
                },
                cancelClicked: {
                    viewModel.closeClicked()
                }
            )
            .padding(.bottom, 32)
        }
    }
    
    private func confirmView(
        date: String,
        token: Token,
        cryptoAmount: String
    ) -> some View {
        VStack(spacing: 52) {
            topPart(date: date, token: token, cryptoAmount: cryptoAmount)
            bottomPart
        }
    }
    
    private func topPart(date: String, token: Token, cryptoAmount: String) -> some View {
        VStack {
            Text(date)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text3))
            Spacer()
            VStack(spacing: 16) {
                CoinLogoImageViewRepresentable(size: 66, token: token)
                    .frame(width: 64, height: 64)
                    .cornerRadius(32)
                Text(cryptoAmount)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
            }
        }
    }
    
    @ViewBuilder
    private var bottomPart: some View {
        if !viewModel.processingVisible {
            TextButtonView(
                title: L10n.confirm,
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    viewModel.confirmClicked()
                }
            )
            .frame(height: 56)
        } else {
            VStack(spacing: 24) {
                statusView
                TextButtonView(
                    title: L10n.close,
                    style: .primaryWhite,
                    size: .large,
                    onPressed: {
                        viewModel.closeClicked()
                    }
                )
                .frame(height: 56)
            }
        }
    }
    
    private var statusView: some View {
        TransactionProcessView(
            state: $viewModel.processingState,
            errorMessageTapAction: {
                viewModel.statusErrorClicked()
            }
        )
    }
    
    private var skeleton: some View {
        VStack {
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 279, height: 20),
                    animated: .default
                )
            Spacer()
            VStack(spacing: 16) {
                Circle()
                    .fill(Color(Asset.Colors.rain.color))
                    .skeleton(with: true)
                    .frame(width: 64, height: 64)
                Text("")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 120, height: 40),
                        animated: .default
                    )
            }
            Spacer()
            Text("")
                .skeleton(
                    with: true,
                    animated: .default
                )
                .frame(height: 56)
        }
    }
    
    private func youReceivedToken(cryptoAmount: String) -> some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(Asset.Colors.rain.color))
                    .frame(width: 128, height: 128)
                Text("💰")
                    .font(.system(size: 64))
            }
            VStack(spacing: 8) {
                Text("\(L10n.youVeGot) \(cryptoAmount)")
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                Text(L10n.spendThemWisely)
                    .foregroundColor(Color(Asset.Colors.silver.color))
                    .font(uiFont: .font(of: .text1))
            }
            Spacer()
            TextButtonView(
                title: "\(L10n.gotIt) 👍",
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    viewModel.closeClicked()
                }
            )
            .frame(height: 56)
        }
    }
}
