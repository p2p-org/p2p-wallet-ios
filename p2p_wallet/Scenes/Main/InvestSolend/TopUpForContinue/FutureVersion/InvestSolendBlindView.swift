//
//  InvestSolendBlindView.swift
//  p2p_wallet
//
//  Created by Ivan on 27.09.2022.
//

import KeyAppUI
import SwiftUI

struct InvestSolendBlindView: View {
    var viewModel: SolendTopUpForContinueViewModel

    var body: some View {
        VStack(spacing: 0) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 3)
            headerView
            Color(Asset.Colors.rain.color)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, 25)
            middleView
            actionsView
        }
        .padding(.bottom, 16)
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            if let url = viewModel.imageUrl {
                ImageView(withURL: url)
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.symbol)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2))
                Text(viewModel.name)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .label1))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(viewModel.apy)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                Text("APY")
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .label1))
            }
        }
        .padding(.top, 22)
        .padding(.leading, 28)
        .padding(.trailing, 40)
    }

    private var middleView: some View {
        VStack(spacing: 24) {
            Text("You have 0 \(viewModel.symbol)")
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title1, weight: .bold))
            switch viewModel.model.strategy {
            case .withoutAnyTokens:
                Text("To earn rewards, you need to\nexchange some token for \(viewModel.symbol)")
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title3))
            case .withoutOnlyTokenForDeposit:
                if viewModel.usdcOrSol {
                    Text("To earn rewards, you need to\ntrade for USDC or buy \(viewModel.symbol)")
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .title3))
                } else {
                    Text("To earn rewards, you need to\nexchange some token for \(viewModel.symbol)")
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .title3))
                }
            }
            coinsView
                .padding(.top, 24)
        }
        .padding(.top, 40)
    }

    private var coinsView: some View {
        HStack(spacing: 32) {
            switch viewModel.model.strategy {
            case .withoutAnyTokens:
                HStack(spacing: -24) {
                    Image(uiImage: .solendUsd)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                    Image(uiImage: .solendEur)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                    Image(uiImage: .solendGbp)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                }
            case .withoutOnlyTokenForDeposit:
                Image(uiImage: .solendBlindQuestion)
            }
            Image(uiImage: .arrowForward)
                .frame(width: 24, height: 24)
            if let url = viewModel.imageUrl {
                ImageView(withURL: url)
                    .frame(width: 64, height: 64)
            }
        }
    }

    private var actionsView: some View {
        VStack(spacing: 16) {
            Button(
                action: {},
                label: {
                    Text(viewModel.firstActionTitle)
                        .foregroundColor(Color(Asset.Colors.lime.color))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                }
            )
            if viewModel.usdcOrSol && viewModel.model.strategy == .withoutOnlyTokenForDeposit {
                Button(
                    action: {},
                    label: {
                        Text("\(L10n.buy) \(viewModel.symbol)")
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.rain.color))
                            .cornerRadius(12)
                    }
                )
            }
        }
        .font(uiFont: .font(of: .text2, weight: .semibold))
        .padding(.top, 52)
        .padding(.horizontal, 24)
    }
}

// MARK: - View Height

extension InvestSolendBlindView {
    var viewHeight: CGFloat {
        591
    }
}
