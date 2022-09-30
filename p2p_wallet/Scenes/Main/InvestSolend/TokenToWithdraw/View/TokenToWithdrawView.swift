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
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 0) {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
            HStack(alignment: .bottom, spacing: 0) {
                Spacer()
                Text(L10n.tokenToWithdraw)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title3, weight: .semibold))
                    .padding(.top, 18)
                Spacer()
                Button(
                    action: {
                        closeSubject.send()
                    },
                    label: {
                        Image(uiImage: .closeAction)
                    }
                )
            }
            .padding(.trailing, 16)
            .padding(.leading, 32)
            Color(Asset.Colors.rain.color)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
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
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    private func token(model: Model) -> some View {
        HStack(spacing: 12) {
            if let url = model.imageUrl {
                ImageView(withURL: url)
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

extension TokenToWithdrawView {
    var viewHeight: CGFloat { CGFloat(models.count * 64 + (models.count - 1) * 8 + 224) }
}
