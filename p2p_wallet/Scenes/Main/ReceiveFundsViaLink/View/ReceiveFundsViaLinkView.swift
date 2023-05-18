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
                .sheetHeader(title: L10n.receiveMoney, withSeparator: false, bottomPadding: 4)
        case let .loaded(model):
            confirmView(
                token: model.token,
                cryptoAmount: model.cryptoAmount
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .sheetHeader(title: L10n.receiveMoney, withSeparator: false, bottomPadding: 4)
        case let .confirmed(cryptoAmount):
            youReceivedToken(cryptoAmount: cryptoAmount)
                .sheetHeader(title: nil, withSeparator: false)
        case let .failure(title, subtitle, image):
            SendViaLinkClaimErrorView(
                title: title,
                subtitle: subtitle,
                image: image,
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
    
    private func confirmView(token: Token, cryptoAmount: String) -> some View {
        VStack(spacing: 52) {
            topPart(token: token, cryptoAmount: cryptoAmount)
            bottomPart
        }
    }
    
   private func topPart(token: Token, cryptoAmount: String) -> some View {
        VStack(spacing: 16) {
            CoinLogoImageViewRepresentable(size: 66, args: .token(token))
                .frame(width: 64, height: 64)
                .cornerRadius(32)
            Text(cryptoAmount)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .largeTitle, weight: .bold))
        }
    }
    
    @ViewBuilder
    private var bottomPart: some View {
        if !viewModel.processingVisible {
            HStack {
                TextButtonView(
                    title: L10n.confirm,
                    style: .primaryWhite,
                    size: .large,
                    onPressed: {
                        viewModel.confirmClicked()
                    }
                )
                .frame(height: 56)
                
                #if !RELEASE
                Toggle(isOn: $viewModel.isFakeSendingTransaction) {
                    Text("Fake")
                }
                .fixedSize(horizontal: true, vertical: false)
                
                if viewModel.isFakeSendingTransaction {
                    Picker("Error Type", selection: $viewModel.fakeTransactionErrorType) {
                        ForEach(ClaimSentViaLinkTransaction.FakeTransactionErrorType.allCases) { errorType in
                            Text(errorType.rawValue.capitalized).tag(errorType)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                #endif
            }
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
            errorMessageTapAction: {}
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
        ZStack {
            VStack(spacing: 32) {
                Spacer()
                Image(uiImage: .accountCreationFeeHand)
                VStack(spacing: 8) {
                    Text("\(L10n.youVeGot) \(cryptoAmount)!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .largeTitle, weight: .bold))
                }
                Spacer()
                Button(
                    action: {
                        viewModel.gotItClicked()
                    },
                    label: {
                        Text("\(L10n.gotIt) 👍")
                            .foregroundColor(Color(Asset.Colors.lime.color))
                            .font(uiFont: .font(of: .text2, weight: .semibold))
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.night.color))
                            .cornerRadius(12)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            LottieView(
                lottieFile: "ApplauseAnimation",
                loopMode: .playOnce,
                contentMode: .scaleAspectFill
            )
            .allowsHitTesting(false)
            .ignoresSafeArea(.all)
        }
    }
}
