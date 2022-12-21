//
//  SendNotFoundView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.11.2022.
//

import SwiftUI

struct SendNotFoundView: View {
    let text: String

    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: .womanNotFound)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220)
            Text(text)
                .apply(style: .text1)
        }
    }
}

struct SendNotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        SendNotFoundView(text: L10n.AddressNotFound.tryAnotherOne)
    }
}
