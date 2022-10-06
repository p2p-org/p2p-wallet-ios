//
//  SolendBalanceBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import KeyAppUI
import SwiftUI

struct SolendBalanceBannerView: View {
    let balance: Double
    @State var delta: Double
    
    let depositUrls: [URL]
    let rewards: Double
    let lastUpdateDate: Date
    
    let showDeposits: () -> Void
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.earnBalance)
                .font(uiFont: .font(of: .text3))
            SolendAnimatableNumberView(number: realTimeBalance(delta))
            Button(
                action: { showDeposits() },
                label: {
                    HStack(spacing: 4) {
                        Text(depositUrls.count > 1 ? L10n.showDeposits : L10n.showDeposit)
                            .font(uiFont: .font(of: .text3, weight: .semibold))
                        Spacer()
                        HStack(spacing: -8) {
                            ForEach(depositUrls.indices, id: \.self) { index in
                                ImageView(withURL: depositUrls[index])
                                    .frame(width: 16, height: 16)
                                    .cornerRadius(4)
                                    .zIndex(Double(depositUrls.count - index))
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
        .modifier(SolendBannerViewModifier(backgroundColor: Color(Asset.Colors.rain.color)))
        .onReceive(timer) { _ in
            withAnimation(Animation.linear(duration: 0.5)) {
                delta = Date().timeIntervalSince(lastUpdateDate)
            }
        }
    }
    
    func realTimeBalance(_ delta: Double) -> Double {
        return balance + (rewards * delta)
    }
}

struct SolendBalanceBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendBalanceBannerView(
            balance: 12.32219382,
            delta: 0,
            depositUrls: [
                URL(
                    string: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png"
                )!,
            ],
            rewards: 0.00001231,
            lastUpdateDate: Date()
        ) {}
        .padding(.all, 16)
    }
}
