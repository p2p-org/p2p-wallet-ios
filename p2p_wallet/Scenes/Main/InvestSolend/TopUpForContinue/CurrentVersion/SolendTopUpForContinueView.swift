//
//  SolendTopUpForContinueView.swift
//  p2p_wallet
//
//  Created by Ivan on 01.10.2022.
//

import Combine
import KeyAppUI
import SwiftUI
import Solend

struct SolendTopUpForContinueView: View {
    let viewModel: SolendTopUpForContinueViewModel

    var body: some View {
        VStack(spacing: 0) {
            cell
                .padding(24)
            actions
        }
        .sheetHeader(title: L10n.topUpBalanceToContinue, withSeparator: false) {
            viewModel.closeClicked()
        }
    }

    private var cell: some View {
        HStack(spacing: 12) {
            if let url = viewModel.imageUrl {
                CoinLogoView(
                    size: 48,
                    cornerRadius: 24,
                    urlString: url.absoluteString
                )
                .frame(width: 48, height: 48)
                .cornerRadius(24)
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
            if let apy = viewModel.apy {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(apy)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                    Text(L10n.apy)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .font(uiFont: .font(of: .label1))
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            Button(
                action: {
                    viewModel.buyClicked()
                },
                label: {
                    Text(viewModel.withoutAnyTokens ? L10n.buy : L10n.buyWithCreditCard)
                        .foregroundColor(Color(Asset.Colors.lime.color))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                }
            )
            Button(
                action: {
                    viewModel.swapOrReceiveClicked()
                },
                label: {
                    Text(viewModel.withoutAnyTokens ? L10n.receive : L10n.swapWithCrypto)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                }
            )
        }
        .font(uiFont: .font(of: .text2, weight: .semibold))
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
    }
}

// MARK: - View Height

extension SolendTopUpForContinueView {
    var viewHeight: CGFloat { 360 }
}

// MARK: - Preview

struct SolendTopUpForContinueView_Previews: PreviewProvider {
    static var view: some View {
        VStack {
            Spacer()
            SolendTopUpForContinueView(
                viewModel: .init(
                    model: .init(
                        asset: .init(
                            name: "Solana",
                            symbol: "SOL",
                            decimals: 8,
                            mintAddress: "12345",
                            logo: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png"
                        ),
                        strategy: .withoutAnyTokens
                    ),
                    dataService: SolendDataServiceMock()
                )
            )
        }
    }
    
    static var previews: some View {
        view
            .previewDevice(.init(rawValue: "iPhone 12"))
            .previewDisplayName("iPhone 12")
        
        view
            .previewDevice(.init(rawValue: "iPhone 8"))
            .previewDisplayName("iPhone 8")
    }
}
