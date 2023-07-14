//
//  SolendLoadingBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.10.2022.
//

import SwiftUI

struct SolendLoadingBannerView: View {
    var body: some View {
        VStack(spacing: 12) {
            Color.blue
                .skeleton(with: true)
                .frame(height: 32)
                .padding(.horizontal, 87)
            Color.blue
                .skeleton(with: true)
                .frame(height: 28)
                .padding(.horizontal, 123)
            Spacer()
        }
        .padding(.top, 10)
        .modifier(SolendBannerViewModifier(backgroundColor: Color(.rain)))
    }
}

struct SolendLoadingBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendLoadingBannerView()
    }
}
