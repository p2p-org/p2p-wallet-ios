//
//  SolendProcessingBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import KeyAppUI
import SwiftUI

struct SolendProcessingBanner: View {
    @State var xOffset: Double = -UIScreen.main.bounds.size.width / 2 - 50

    var repeatingAnimation: Animation {
        Animation
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: false)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Image(uiImage: .rocket)
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
                .background(Color(Asset.Colors.snow.color))
                .cornerRadius(12)
        }
        .modifier(SolendBanner(backgroundColor: Color(Asset.Colors.rain.color)))
        .onAppear {
            withAnimation(repeatingAnimation) {
                xOffset = UIScreen.main.bounds.size.width / 2 + 50
            }
        }
    }
}

struct SolendProcessingBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendProcessingBanner()
    }
}
