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
        switch viewModel.state {
        case .pending:
            SolendLoadingBanner()
        case let .failure(title, subtitle):
            SolendErrorBanner(title: title, subtitle: subtitle) {
                Task { try await viewModel.update() }
            }
        case .learnMore:
            SolendLearnMoreBanner()
        case .processingAction:
            SolendProcessingBanner()
        case let .withBalance(model):
            SolendBalanceBanner(
                balance: model.balance,
                delta: Date().timeIntervalSince(model.lastUpdate),
                depositUrls: model.depositUrls,
                rewards: model.reward,
                lastUpdateDate: model.lastUpdate
            ) { [showDeposits] in
                showDeposits?()
            }
        }
    }
}

struct InvestSolendBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            InvestSolendBannerView(
                viewModel: .init(
                    dataService: SolendDataServiceMock(),
                    actionService: SolendActionServiceMock(currentAction: nil)
                )
            )
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
