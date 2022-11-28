//
//  RecipientSearchView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.2022.
//

import KeyAppUI
import SwiftUI

struct RecipientSearchField: View {
    @Binding var text: String
    @Binding var isLoading: Bool

    let past: () -> Void
    let scan: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack {
                TextField(L10n.usernameOrAddress, text: $text)
                    .padding(.vertical, 12)
                    .autocapitalization(.none)

                if isLoading {
                    Spinner()
                        .frame(width: 12, height: 12)
                } else if text.isEmpty {
                    Button { past() }
                    label: {
                            Image(uiImage: Asset.Icons.past.image)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                } else {
                    Button { text = "" }
                    label: {
                            Image(uiImage: .crossIcon)
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                }
            }
            .padding(.horizontal, 18)
            .background(
                Color(Asset.Colors.rain.color)
                    .cornerRadius(radius: 12, corners: .allCorners)
            )

            Button { scan() } label: {
                Image(uiImage: Asset.Icons.qr.image)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

struct RecipientSearchField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientSearchField(text: .constant("Hello"), isLoading: .constant(false)) {} scan: {}
    }
}
