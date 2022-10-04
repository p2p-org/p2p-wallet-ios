// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SkeletonUI
import Solend
import SwiftUI

struct InvestSolendBannerView: View {
    typealias BalanceModel = InvestSolendBannerViewModel.InvestSolendBannerBalanceModel

    @ObservedObject private var viewModel: InvestSolendBannerViewModel
    private let showDeposits: (() -> Void)?

    init(viewModel: InvestSolendBannerViewModel, showDeposits: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.showDeposits = showDeposits
    }

    var body: some View {
        ZStack {
            Color(viewModel.state.notLearnMode ? Asset.Colors.rain.color : Asset.Colors.lime.color)
            switch viewModel.state {
            case .pending:
                pending
            case let .failure(title, subtitle):
                single(title: title, subtitle: subtitle, failure: true)
            case .learnMore:
                single(
                    title: L10n.depositYourTokensAndEarn,
                    subtitle: L10n.AllYourFundsAreInsured.withdrawYourDepositWithAllRewardsAtAnyTime,
                    failure: false
                )
            case .processingAction:
                processingAction()
            case let .withBalance(model):
                withBalance(model: model)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .cornerRadius(28)
    }

    private var pending: some View {
        VStack(spacing: 12) {
            Color.blue
                .skeleton(with: true)
                .frame(height: 32)
                .padding(.horizontal, 87)
            Color.blue
                .skeleton(with: true)
                .frame(height: 28)
                .padding(.horizontal, 123)
            Spacer()
        }
        .padding(.top, 30)
    }

    private func single(title: String, subtitle: String, failure: Bool) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(uiFont: .font(of: .title3, weight: .semibold))
            Text(subtitle)
                .font(uiFont: .font(of: .text4))
                .multilineTextAlignment(.center)
            Button(
                action: {
                    if failure == true {
                        Task { try await viewModel.update() }
                    }
                },
                label: {
                    Text(failure ? L10n.tryAgain : L10n.learnMore)
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.snow.color))
                        .cornerRadius(12)
                        .padding(.top, 8)
                }
            )
        }
        .foregroundColor(Color(Asset.Colors.night.color))
        .padding(.top, 24)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }

    private func withBalance(model: BalanceModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.earnBalance)
                .font(uiFont: .font(of: .text3))
            Text(model.balance)
                .font(uiFont: .font(of: .title1, weight: .bold))
                .multilineTextAlignment(.center)
            Button(
                action: {
                    showDeposits?()
                },
                label: {
                    HStack(spacing: 4) {
                        Text(model.depositUrls.count > 1 ? L10n.showDeposits : L10n.showDeposit)
                            .font(uiFont: .font(of: .text3, weight: .semibold))
                        Spacer()
                        HStack(spacing: -8) {
                            ForEach(model.depositUrls.indices, id: \.self) { index in
                                ImageView(withURL: model.depositUrls[index])
                                    .frame(width: 16, height: 16)
                                    .cornerRadius(4)
                                    .zIndex(Double(model.depositUrls.count - index))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(12)
                    .padding(.top, 8)
                }
            )
        }
        .foregroundColor(Color(Asset.Colors.night.color))
        .padding(.top, 36)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }

    private func processingAction() -> some View {
        ProcessingAction()
    }
}

private struct ProcessingAction: View {
    @State var xOffset: Double = -UIScreen.main.bounds.size.width / 2 - 50

    var repeatingAnimation: Animation {
        Animation
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: false)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Image(uiImage: .rocket)
                    .frame(width: 48, height: 98)
                    .offset(x: xOffset, y: 0)
            }
            HStack {
                Text(L10n.🕑SendingYourDeposit)
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                    .padding(.horizontal, 16)
                Spacer()
            }.frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(Asset.Colors.snow.color))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }

            .onAppear {
                withAnimation(repeatingAnimation) {
                    xOffset = UIScreen.main.bounds.size.width / 2 + 50
                }
            }
    }
}

struct InvestSolendBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InvestSolendBannerView(
                viewModel: .init(
                    dataService: SolendDataServiceMock(),
                    actionService: SolendActionServiceMock(currentAction: .init(
                        type: .deposit,
                        transactionID: "ae31cd1xcw1w2das21",
                        status: .processing,
                        amount: 5000,
                        symbol: "SOL"
                    ))
                )
            )
        }.padding(.horizontal, 8)
    }
}
