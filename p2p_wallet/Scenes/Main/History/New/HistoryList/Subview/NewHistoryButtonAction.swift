//
//  NewHistoryButtonAction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 10.02.2023.
//

import KeyAppUI
import SwiftUI

struct NewHistoryButtonAction: View {
    let title: String
    let image: UIImage
    let onPressed: () -> Void

    var body: some View {
        Button {
            onPressed()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(Asset.Colors.night.color))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                    )
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .label2)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

struct NewHistoryButtonAction_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryButtonAction(title: "Share", image: .share2) {}
    }
}
