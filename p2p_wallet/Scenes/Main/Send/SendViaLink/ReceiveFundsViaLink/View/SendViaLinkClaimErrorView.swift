//
//  SendViaLinkClaimErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 29.03.2023.
//

import SwiftUI
import KeyAppUI

struct SendViaLinkClaimErrorView: View {
    
    @Binding var isLoading: Bool
    let reloadClicked: () -> Void
    let cancelClicked: () -> Void
    
    var body: some View {
        VStack(spacing: 39) {
            Text(L10n.refreshThePageOrCheckBackLater)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text3))
            Spacer()
            Image(uiImage: .sendViaLinkClaimError)
            VStack(spacing: 12) {
                Button(
                    action: {
                        reloadClicked()
                    },
                    label: {
                        HStack(spacing: 8) {
                            Text(L10n.reload)
                                .foregroundColor(Color(Asset.Colors.snow.color))
                                .font(uiFont: .font(of: .text2, weight: .semibold))
                            if isLoading {
                                CircularProgressIndicatorView(
                                    backgroundColor: Asset.Colors.snow.color.withAlphaComponent(0.6),
                                    foregroundColor: Asset.Colors.snow.color
                                )
                                .frame(width: 16, height: 16)
                            }
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                    }
                )
                Button(
                    action: {
                        cancelClicked()
                    },
                    label: {
                        Text(L10n.cancel)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text2, weight: .semibold))
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .sheetHeader(title: L10n.failedToGetData, withSeparator: false, bottomPadding: 4)
    }
}
