//
//  RecipientErrorView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.01.2023.
//

import KeyAppUI
import SwiftUI

struct RecipientErrorView: View {
    let reload: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("!")
                .font(.system(size: 50))
                .fontWeight(.medium)
                .padding(.bottom, 64)
            
            Text(L10n.error.uppercaseFirst)
                .font(.system(size: 17))
            Text(L10n.somethingWentWrongPleaseTryAgainLater)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(UIColor.textSecondary))
                .frame(width: .infinity)
            
            TextButtonView(title: L10n.tryAgain, style: .primary, size: .medium) {
                Task { reload() }
            }
            .frame(width: 120, height: TextButton.Size.medium.height)
            .padding(.top, 30)
        }
    }
}

struct RecipientErrorView_Previews: PreviewProvider {
    static var previews: some View {
        RecipientErrorView {}
    }
}
