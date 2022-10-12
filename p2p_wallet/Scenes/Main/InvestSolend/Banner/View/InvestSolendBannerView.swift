// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SkeletonUI
import Solend
import SwiftUI

enum InvestSolendBannerAction: Equatable {
    case showDeposit
    case retry
}

struct InvestSolendBannerView: View {
    typealias BalanceModel = InvestSolendBannerViewModel.InvestSolendBannerBalanceModel

    @ObservedObject private var viewModel: InvestSolendBannerViewModel
    private let onAction: (InvestSolendBannerAction) -> Void
    
    init(viewModel: InvestSolendBannerViewModel, _ onAction: @escaping (InvestSolendBannerAction) -> Void) {
        self.viewModel = viewModel
        self.onAction = onAction
    }
    
    var body: some View {
        switch viewModel.state {
        case .pending:
            SolendLoadingBannerView()
        case let .failure(title, subtitle):
            SolendErrorBannerView(title: title, subtitle: subtitle) {
                onAction(.retry)
            }
        case .learnMore:
            SolendLearnMoreBannerView()
        case .processingAction:
            SolendProcessingBannerView()
        case let .withBalance(model):
            SolendBalanceBannerView(
                balance: model.balance,
                delta: Date().timeIntervalSince(model.lastUpdate),
                depositUrls: model.depositUrls,
                rewards: model.reward,
                lastUpdateDate: model.lastUpdate
            ) { [onAction] in
                onAction(.showDeposit)
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
            ) { _ in }
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
            ) { _ in }
        }.padding(.horizontal, 8)
    }
}
