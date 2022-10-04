//
//  AboutSolendView.swift
//  p2p_wallet
//
//  Created by Ivan on 03.10.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct AboutSolendView: View {
    private let cancelSubject = PassthroughSubject<Void, Never>()
    var cancel: AnyPublisher<Void, Never> { cancelSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 14) {
            Image(uiImage: .aboutSolendLock)
            Text(L10n.LikeADepositButWithCrypto.lowRisksAllYourFundsAreInsured)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2))
            Spacer()
            Button(
                action: {
                    cancelSubject.send()
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
        }
        .padding(.top, 15)
        .padding(.bottom, 16)
        .sheetHeader(title: L10n.whatIsSolend) {
            cancelSubject.send()
        }
    }
}

// MARK: - View Height

extension AboutSolendView {
    var viewHeight: CGFloat { 487 }
}
