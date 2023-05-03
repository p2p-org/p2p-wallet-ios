//
//  SendViaLinkClaimErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 29.03.2023.
//

import SwiftUI
import KeyAppUI

struct SendViaLinkClaimErrorView: View {
    
    let title: String
    let subtitle: String?
    let image: UIImage
    @Binding var isLoading: Bool
    let reloadClicked: () -> Void
    let cancelClicked: () -> Void
    
    var body: some View {
        VStack(spacing: 39) {
            if let subtitle {
                Text(subtitle)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .text3))
            }
            Spacer()
            Image(uiImage: image)
            VStack(spacing: 12) {
                NewTextButton(
                    title: L10n.tryAgain,
                    style: .primaryWhite,
                    isLoading: isLoading,
                    action: {
                        reloadClicked()
                    }
                )
                NewTextButton(
                    title: L10n.cancel,
                    style: .inverted,
                    action: {
                        cancelClicked()
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .sheetHeader(title: title, withSeparator: false, bottomPadding: 4)
    }
}
