//
//  TokenToWithdraw.swift
//  p2p_wallet
//
//  Created by Ivan on 28.09.2022.
//

import Combine
import KeyAppUI
import SwiftSVG
import SwiftUI

struct TokenToWithdrawView: View {
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
            ).padding(.top, 32)
        }
        .sheetHeader(title: L10n.tokenToWithdraw) { closeSubject.send() }
        .padding(.top, 6)
        .padding(.bottom, 16)
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
                Text("\(L10n.yielding) \(model.apy.percentFormat()) \(L10n.apy)")
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .label1))
            }
            Spacer()
            Text(model.fiatAmount?.fiatAmount() ?? "")
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - SolendSelectTokenView

extension TokenToWithdrawView: SolendSelectTokenView {
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var symbol: AnyPublisher<String, Never> { symbolSubject.eraseToAnyPublisher() }
    var viewHeight: CGFloat { CGFloat(models.count * 64 + (models.count - 1) * 8 + 224) }
}

// MARK: - Model

extension TokenToWithdrawView {
    struct Model: Swift.Identifiable {
        let amount: Double?
        let imageUrl: URL?
        let symbol: String
        let fiatAmount: Double?
        let apy: Double

        var id: String { symbol }
    }
}
