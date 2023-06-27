//
//  StrigaDocumentVerificationBannerView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26/06/2023.
//

import KeyAppUI
import SwiftUI

struct StrigaDocumentVerificationBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: UIImage.clock)
            VStack(alignment: .leading, spacing: 4) {
                Text("Documents verification is pending")
                    .fontWeight(.semibold)
                    .apply(style: .text4)
                Text("Usually it takes a few hours")
                    .apply(style: .label2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                .foregroundColor(Color(Asset.Colors.mountain.color))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct StrigaDocumentVerificationBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.mountain.color)
                .ignoresSafeArea()
            StrigaDocumentVerificationBannerView()
                
        }
        
    }
}
