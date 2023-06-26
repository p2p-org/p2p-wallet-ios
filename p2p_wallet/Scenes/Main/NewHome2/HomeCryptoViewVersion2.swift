//
//  HomeCryptoViewVersion2.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25/06/2023.
//

import SwiftUI
import KeyAppUI

struct HomeCryptoViewVersion2: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 24) {
                    Button {} label: {
                        Text("Cash")
                            .fontWeight(.bold)
                            .apply(style: .largeTitle)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .opacity(0.3)
                    }
                    Button {} label: {
                        Text("Crypto")
                            .fontWeight(.bold)
                            .apply(style: .largeTitle)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            
                    }
                }
                .padding(.top, 20)
                .padding(.leading, 21)
                
            }
        }
        .background(Color(Asset.Colors.smoke.color).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeCryptoViewVersion2_Previews: PreviewProvider {
    static var previews: some View {
        HomeCryptoViewVersion2()
    }
}
