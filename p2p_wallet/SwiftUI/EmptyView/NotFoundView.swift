//
//  NotFoundView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.11.2022.
//

import SwiftUI

struct NotFoundView: View {
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

struct NotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        NotFoundView(text: L10n.AddressNotFound.tryAnotherOne)
    }
}
