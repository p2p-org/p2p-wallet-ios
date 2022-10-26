//
//  TokenToDeposit.swift
//  p2p_wallet
//
//  Created by Ivan on 28.09.2022.
//

import Combine
import KeyAppUI
import SwiftSVG
import SwiftUI

struct TokenToDepositView: View {
    let models: [Model]

    private let closeSubject = PassthroughSubject<Void, Never>()
    private let symbolSubject = PassthroughSubject<String, Never>()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                ForEach(models) { model in
                    token(model: model)
                }
            }
            .padding(.top, 16)
            Button(
                action: {
                    closeSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            )
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .padding(.top, 6)
        .sheetHeader(title: L10n.tokenToDeposit) { closeSubject.send() }
    }

    private func token(model: Model) -> some View {
        Button(
            action: {
                symbolSubject.send(model.symbol)
            },
            label: {
                tokenView(model: model)
            }
        )
    }

    private func tokenView(model: Model) -> some View {
        HStack(spacing: 12) {
            if let url = model.imageUrl {
                CoinLogoView(
                    size: 48,
                    cornerRadius: 24,
                    urlString: url.absoluteString
                )
                .frame(width: 48, height: 48)
                .cornerRadius(24)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(model.amount != nil ? model.amount?.tokenAmount(symbol: model.symbol) ?? "" : model.symbol)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2))
                Text(model.name)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .label1))
            }
            Spacer()
            if let apy = model.apy {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(apy.percentFormat())
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                    Text(L10n.apy)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .font(uiFont: .font(of: .label1))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - SolendSelectTokenView

extension TokenToDepositView: SolendSelectTokenView {
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var symbol: AnyPublisher<String, Never> { symbolSubject.eraseToAnyPublisher() }
    var viewHeight: CGFloat { CGFloat(models.count * 64 + (models.count - 1) * 8 + 224) }
}

// MARK: - Model

extension TokenToDepositView {
    struct Model: Swift.Identifiable {
        let amount: Double?
        let imageUrl: URL?
        let symbol: String
        let name: String
        let apy: Double?

        var id: String { symbol }
    }
}

// MARK: - Preview

struct TokenToDepositView_Previews: PreviewProvider {
    static var view: some View {
        ZStack {
            Color(.gray)
            VStack {
                Spacer()
                TokenToDepositView(
                    models: [
                        .init(
                            amount: 50,
                            imageUrl: URL(string: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png")!,
                            symbol: "SOL",
                            name: "Solana",
                            apy: 3.142312
                        )
                    ]
                )
            }
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
