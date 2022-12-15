//
//  RecipientNotFoundView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.11.2022.
//

import SwiftUI

struct RecipientNotFoundView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: .notFoundIllustration)
            Text(L10n.AddressNotFound.tryAnotherOne)
                .apply(style: .text1)
        }
    }
}

struct RecipientNotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        RecipientNotFoundView()
    }
}
