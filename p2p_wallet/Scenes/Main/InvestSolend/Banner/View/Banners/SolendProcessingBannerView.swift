//
//  SolendProcessingBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import SwiftUI

struct SolendProcessingBannerView: View {
    @State var xOffset: Double = -UIScreen.main.bounds.size.width / 2 - 50

    var repeatingAnimation: Animation {
        Animation
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: false)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Image(.rocket)
                    .offset(x: xOffset, y: 0)
            }
            Spacer()
            HStack {
                Text(L10n.🕑SendingYourDeposit)
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                    .padding(.horizontal, 16)
                Spacer()
            }.frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(.snow))
                .cornerRadius(12)
        }
        .modifier(SolendBannerViewModifier(backgroundColor: Color(.rain)))
        .onAppear {
            withAnimation(repeatingAnimation) {
                xOffset = UIScreen.main.bounds.size.width / 2 + 50
            }
        }
    }
}

struct SolendProcessingBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendProcessingBannerView()
    }
}
